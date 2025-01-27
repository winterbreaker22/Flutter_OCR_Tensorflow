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
    tfliteInterpreter = await Interpreter.fromAsset('model.tflite');
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
    capturedImage.value = originalImageFile;

    // Load image using `image` package to get its dimensions
    final img.Image originalImage = img.decodeImage(await originalImageFile.readAsBytes())!;
    final originalWidth = originalImage.width;
    final originalHeight = originalImage.height;

    // Resize and pad image to 512x512 while keeping aspect ratio
    final preprocessResult = _preprocessImage(originalImage, originalWidth, originalHeight);
    final resizedImage = preprocessResult['image'] as img.Image;
    final scaleFactors = preprocessResult['scaleFactors'] as Map<String, double>;
    final paddingOffsets = preprocessResult['paddingOffsets'] as Map<String, int>;

    // Convert resized image to tensor-like data (using `image` package for simplicity)
    final inputData = _convertImageToInputData(resizedImage);

    // Run inference with the model
    final output = _runInference(inputData);

    // Parse detection results
    boundingBoxes.clear();
    extractedTexts.clear();
    for (final detection in output) {
      final adjustedBox = _adjustBoxToOriginalSize(
        detection['box'],
        scaleFactors,
        paddingOffsets,
        originalWidth,
        originalHeight,
      );
      boundingBoxes.add(adjustedBox);

      final classId = detection['classId'] as int;
      final label = labelMap[classId];
      extractedTexts.add('$label (${(detection['confidence'] * 100).toStringAsFixed(2)}%)');
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

    final resizedImage = img.Image(width: targetSize, height: targetSize);

    // Center the resized image onto a 512x512 canvas
    img.compositeImage(resizedImage, originalImage);

    return {
      'image': resizedImage,
      'scaleFactors': {'xScale': scale, 'yScale': scale},
      'paddingOffsets': {'xOffset': xOffset, 'yOffset': yOffset},
    };
  }

  // Convert the resized image into a format suitable for the model
  List<double> _convertImageToInputData(img.Image resizedImage) {
    List<double> inputData = [];
    
    // Loop through every pixel of the resized image
    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        // Get the pixel value at (x, y)
        img.Pixel pixel = resizedImage.getPixel(x, y);
        
        // Explicitly cast the components to int
        int red = pixel.r.toInt();
        int green = pixel.g.toInt();
        int blue = pixel.b.toInt();

        // Normalize to range [-0.5, 0.5]
        inputData.add((red / 255.0) - 0.5);   // Normalize Red
        inputData.add((green / 255.0) - 0.5); // Normalize Green
        inputData.add((blue / 255.0) - 0.5);  // Normalize Blue
      }
    }
    return inputData;
  }

  List<Map<String, dynamic>> _runInference(List<double> inputData) {
    // Create an input tensor with a single image
    final input = [inputData];

    // Create output tensors for the boxes, classes, and scores
    final outputBoxes = List.generate(10, (index) => List.filled(4, 0.0));
    final outputClasses = List.filled(10, 0);
    final outputScores = List.filled(10, 0.0);

    // Run inference
    tfliteInterpreter.runForMultipleInputs([input], {
      0: outputBoxes,
      1: outputClasses,
      2: outputScores,
    });

    // Collect results
    final detections = <Map<String, dynamic>>[];
    for (int i = 0; i < outputScores.length; i++) {
      if (outputScores[i] >= 0.5) {
        detections.add({
          'box': Rect.fromLTRB(
            outputBoxes[i][0], outputBoxes[i][1], outputBoxes[i][2], outputBoxes[i][3]),
          'classId': outputClasses[i],
          'confidence': outputScores[i],
        });
      }
    }

    return detections;
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
