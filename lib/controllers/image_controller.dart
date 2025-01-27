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
      print('Model successfully loaded.');
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
    final rawBoxes = List.generate(81840, (_) => List.filled(4, 0.0)); 
    final multiclassScores = List.generate(100, (_) => List.filled(9, 0.0)); 
    final outputClasses = List.filled(100, 0); 
    final outputBoxes = List.generate(100, (_) => List.filled(4, 0.0)); 
    final rawScores = List.generate(81840, (_) => List.filled(4, 0.0)); 
    final numDetections = List.filled(1, 0.0); // Shape: (1)
    final anchorIndices = List.filled(100, 0.0);
    final outputScores = List.filled(100, 0.0);

    try {
      tfliteInterpreter.runForMultipleInputs([inputTensor], {
        0: rawBoxes,
        1: multiclassScores,
        2: outputClasses,
        3: outputBoxes,
        4: rawScores,
        5: numDetections,
        6: anchorIndices,
        7: outputScores,
      });
    } catch (e) {
      print("Error during inference: $e");
      return;
    }

    final inputTensorTemp = tfliteInterpreter.getInputTensor(0);
    print('Input tensor: Shape: ${inputTensorTemp.shape}, Type: ${inputTensorTemp.type}');

    for (int i = 0; i < tfliteInterpreter.getOutputTensors().length; i++) {
      final outputTensor = tfliteInterpreter.getOutputTensor(i);
      print('Output tensor $i: Shape: ${outputTensor.shape}, Type: ${outputTensor.type}');
    }

    
    boundingBoxes.clear();
    extractedTexts.clear();
    for (int i = 0; i < outputScores.length; i++) {
      if (outputScores[i] >= 0.12) { 
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

  Uint8List _convertImageToInputTensor(img.Image paddedImage) {
    final width = paddedImage.width;
    final height = paddedImage.height;

    final inputTensor = Uint8List(1 * width * height * 3);
    int index = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = paddedImage.getPixel(x, y); 
        inputTensor[index++] = pixel.r.toInt(); 
        inputTensor[index++] = pixel.g.toInt();
        inputTensor[index++] = pixel.b.toInt();  
      }
    }

    return inputTensor;
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
