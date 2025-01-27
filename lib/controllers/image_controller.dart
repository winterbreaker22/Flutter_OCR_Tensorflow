import 'dart:typed_data';
import 'dart:io';
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';

class ImageController extends GetxController {
  final Rx<File?> capturedImage = Rx<File?>(null);
  final RxList<Rect> boundingBoxes = RxList<Rect>();
  final RxList<String> extractedTexts = RxList<String>();

  final int targetSize = 512;
  late Interpreter tfliteInterpreter;
  late List<String> labelMap;

  @override
  void onInit() {
    super.onInit();
    _loadModel();
    _loadLabelMap();
  }

  Future<void> _loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions();
      tfliteInterpreter = await Interpreter.fromAsset(
        'assets/model.tflite',
        options: interpreterOptions,
      );
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  Future<void> _loadLabelMap() async {
    final labelData = await rootBundle.loadString('assets/label_map.pbtxt');
    labelMap = _parseLabelMap(labelData);
  }

  List<String> _parseLabelMap(String labelMapData) {
    final lines = labelMapData.split('\n');
    final List<String> labels = [];
    for (final line in lines) {
      if (line.contains('name')) {
        final label = line.split(':')[1].replaceAll('"', '').trim();
        labels.add(label);
      }
    }
    return labels;
  }

  Future<void> processImage(XFile image) async {
    final originalImageFile = File(image.path);
    final img.Image originalImage = img.decodeImage(await originalImageFile.readAsBytes())!;
    final originalWidth = originalImage.width;
    final originalHeight = originalImage.height;

    final preprocessResult = _preprocessImage(originalImage, originalWidth, originalHeight);
    final paddedImage = preprocessResult['image'] as img.Image;
    final scaleFactors = preprocessResult['scaleFactors'] as Map<String, double>;
    final paddingOffsets = preprocessResult['paddingOffsets'] as Map<String, int>;

    final inputTensor = _convertImageToInputTensor(paddedImage);

    // Output buffers with correct shapes and data types
    final outputBoxes = List.generate(10, (_) => List.filled(4, 0.0)); 
    final outputClasses = List.filled(10, 0); 
    final outputScores = List.filled(10, 0.0);

    try {
      tfliteInterpreter.runForMultipleInputs([inputTensor], {
        0: outputBoxes,
        1: outputClasses,
        2: outputScores,
      });
    } catch (e) {
      print("Error during inference: $e");
      return;
    }
    
    // Parse the results
    boundingBoxes.clear();
    extractedTexts.clear();
    for (int i = 0; i < outputScores.length; i++) {
      if (outputScores[i] >= 0.12) { // Confidence threshold
        final adjustedBox = _adjustBoxToOriginalSize(
          Rect.fromLTRB(
            outputBoxes[i][1], outputBoxes[i][0], outputBoxes[i][3], outputBoxes[i][2]
          ),
          scaleFactors,
          paddingOffsets,
          originalWidth,
          originalHeight,
        );
        boundingBoxes.add(adjustedBox);

        final classId = outputClasses[i];
        final label = labelMap[classId];
        extractedTexts.add('$label (${(outputScores[i] * 100).toStringAsFixed(2)}%)');
      }
    }

    Get.toNamed('/result');
  }

  Map<String, dynamic> _preprocessImage(img.Image originalImage, int originalWidth, int originalHeight) {
    final double scale = targetSize / originalWidth < targetSize / originalHeight
        ? targetSize / originalWidth
        : targetSize / originalHeight;

    final newWidth = (originalWidth * scale).toInt();
    final newHeight = (originalHeight * scale).toInt();
    final xOffset = (targetSize - newWidth) ~/ 2;
    final yOffset = (targetSize - newHeight) ~/ 2;

    final resizedImage = img.copyResize(originalImage, width: newWidth, height: newHeight);
    final paddedImage = img.Image(width: targetSize, height: targetSize);
    img.fill(paddedImage, color: img.ColorRgb8(0, 0, 0)); // Black padding
    img.compositeImage(paddedImage, resizedImage, dstX: xOffset, dstY: yOffset);

    return {
      'image': paddedImage,
      'scaleFactors': {'xScale': scale, 'yScale': scale},
      'paddingOffsets': {'xOffset': xOffset, 'yOffset': yOffset},
    };
  }

  // Convert the image to the input tensor expected by the model (Uint8List)
  Uint8List _convertImageToInputTensor(img.Image paddedImage) {
    final width = paddedImage.width;
    final height = paddedImage.height;

    // Create Uint8List to hold raw RGB data (flattened format)
    final inputTensor = Uint8List(width * height * 3);
    int index = 0;

    // Populate inputTensor with RGB values
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = paddedImage.getPixel(x, y); // Pixel as 0xAARRGGBB
        inputTensor[index++] = pixel.r.toInt();   // Red channel
        inputTensor[index++] = pixel.g.toInt(); // Green channel
        inputTensor[index++] = pixel.b.toInt();  // Blue channel
      }
    }

    // Debug: Check raw tensor content
    print("Flattened Input Tensor Data : $inputTensor");
    print("Flattened Tensor Length: ${inputTensor.length}");

    // Reshape inputTensor into [1, height, width, 3]
    // TensorFlow Lite expects a Uint8List in this format
    final reshapedTensor = Uint8List(1 * height * width * 3);
    int reshapedIndex = 0;

    for (int i = 0; i < inputTensor.length; i++) {
      reshapedTensor[reshapedIndex++] = inputTensor[i];
    }

    // Debug: Check reshaped tensor content
    print("Reshaped Tensor Length: ${reshapedTensor.length}");
    print("Reshaped Tensor Data (First 100 Bytes): $reshapedTensor");

    return reshapedTensor; // Return tensor in required format
  }

  Rect _adjustBoxToOriginalSize(
    Rect box,
    Map<String, double> scaleFactors,
    Map<String, int> paddingOffsets,
    int originalWidth,
    int originalHeight,
  ) {
    final double xScale = scaleFactors['xScale']!;
    final double yScale = scaleFactors['yScale']!;
    final int xOffset = paddingOffsets['xOffset']!;
    final int yOffset = paddingOffsets['yOffset']!;

    final double xmin = (box.left - xOffset) / xScale;
    final double xmax = (box.right - xOffset) / xScale;
    final double ymin = (box.top - yOffset) / yScale;
    final double ymax = (box.bottom - yOffset) / yScale;

    return Rect.fromLTRB(
      xmin.clamp(0, originalWidth).toDouble(),
      ymin.clamp(0, originalHeight).toDouble(),
      xmax.clamp(0, originalWidth).toDouble(),
      ymax.clamp(0, originalHeight).toDouble(),
    );
  }
}
