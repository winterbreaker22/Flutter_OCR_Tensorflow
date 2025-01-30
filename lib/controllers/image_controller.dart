import 'package:get/get.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class Detection {
  final String label;
  final double score;
  final List<double> box;

  Detection({
    required this.label,
    required this.score,
    required this.box,
  });
}

class ImageController extends GetxController {
  static const double detectionThreshold = 0.1;
  final RxList<Rect> boundingBoxes = RxList<Rect>();
  final RxList<String> extractedTexts = RxList<String>();

  final int targetSize = 512;
  late List<String> labelMap;
  static const platform = MethodChannel('com.example.ocr_tf/tflite');

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() async {
      await _loadModel();
      await _loadLabelMap();
    });
  }

  Future<void> _loadModel() async {
    final String result = await platform.invokeMethod('loadInterpreter');
    print("Interpreter load result: $result");
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

  Future<void> processImage(img.Image image) async {
    final img.Image originalImage = image;

    final preprocessResult = _preprocessImage(originalImage);
    final paddedImage = preprocessResult['image'] as img.Image;
    final scaleFactors = preprocessResult['scaleFactors'] as Map<String, double>;
    final paddingOffsets = preprocessResult['paddingOffsets'] as Map<String, int>;

    final inputTensor = _convertImageToInputTensor(paddedImage);

    try {
      final Map<dynamic, dynamic> results = await platform.invokeMethod(
        'runModel',
        {"inputTensor": inputTensor},
      );

      final List<List<double>> detectionBoxes = List<List<double>>.from(results['detectionBoxes'].map((e) => List<double>.from(e)));
      final List<dynamic> detectionClassesRaw = results['detectionClasses'];
      final List<int> detectionClasses = detectionClassesRaw.map((e) => (e is double) ? e.toInt() : e as int).toList();
      final List<List<double>> detectionMultiClassScores = List<List<double>>.from(results['detectionMulticlassScores'].map((e) => List<double>.from(e)));

      boundingBoxes.clear();
      extractedTexts.clear();

      final Map<String, Detection?> highestDetections = {};

      for (int i = 0; i < detectionClasses.length; i++) {
        final int classIndex = detectionClasses[i];
        final String label = labelMap[classIndex - 1];

        final double classScore = detectionMultiClassScores[i][classIndex];

        if (classScore >= detectionThreshold) {
          final detection = Detection(
            label: label,
            score: classScore,
            box: detectionBoxes[i],
          );

          if (highestDetections[label] == null || classScore > highestDetections[label]!.score) {
            highestDetections[label] = detection;
          }
        }
      }

      img.Image finalImage = originalImage.clone();
      for (final detection in highestDetections.values) {
        if (detection != null) {
          final adjustedBox = _adjustBoxToOriginalSize(
            Rect.fromLTRB(
              detection.box[1], detection.box[0], detection.box[3], detection.box[2]
            ),
            scaleFactors,
            paddingOffsets,
            originalImage.width,
            originalImage.height,
          );

          _drawBoundingBox(finalImage, adjustedBox);

          final extractedText = await _extractTextFromBox(originalImage, adjustedBox);
          extractedTexts.add('${detection.label}: $extractedText');
        }
      }

      Get.toNamed('/result', arguments: {'image': finalImage, 'texts': extractedTexts});

    } catch (e) {
      print("Error running model: $e");
    }
  }

  Future<String> _extractTextFromBox(img.Image image, Rect box) async {
    try {
      final croppedImage = img.copyCrop(
        image,
        x: box.left.round(),
        y: box.top.round(),
        width: box.width.round(),
        height: box.height.round(),
      );

      img.Image expandedImage = croppedImage;
      if (croppedImage.width < 64 || croppedImage.height < 64) {
        double scaleX = croppedImage.width < 64 ? 64 / croppedImage.width : 1.0;
        double scaleY = croppedImage.height < 64 ? 64 / croppedImage.height : 1.0;

        double scale = scaleX > scaleY ? scaleX : scaleY;

        expandedImage = img.copyResize(
          croppedImage,
          width: (croppedImage.width * scale).round(),
          height: (croppedImage.height * scale).round(),
        );
      }

      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/expanded_image.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(expandedImage));

      final inputImage = InputImage.fromFile(tempFile);

      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      String resultText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          resultText += "${line.text}, ";
        }
      }

      return resultText.trim();
    } catch (e) {
      print('Error in _extractTextFromBox: $e');
      return '';
    }
  }

  void _drawBoundingBox(img.Image image, Rect box) {
    final color = img.ColorRgb8(255, 0, 0);  
    final thickness = 2;

    for (int x = box.left.round(); x < box.right.round(); x++) {
      image.setPixel(x, box.top.round(), color);
      image.setPixel(x, box.top.round() + thickness - 1, color);
    }

    for (int x = box.left.round(); x < box.right.round(); x++) {
      image.setPixel(x, box.bottom.round(), color);
      image.setPixel(x, box.bottom.round() - thickness + 1, color);
    }

    for (int y = box.top.round(); y < box.bottom.round(); y++) {
      image.setPixel(box.left.round(), y, color);
      image.setPixel(box.left.round() + thickness - 1, y, color);
    }

    for (int y = box.top.round(); y < box.bottom.round(); y++) {
      image.setPixel(box.right.round(), y, color);
      image.setPixel(box.right.round() - thickness + 1, y, color);
    }
  }

  Map<String, dynamic> _preprocessImage(img.Image originalImage) {
    final double scale = targetSize / originalImage.width < targetSize / originalImage.height
        ? targetSize / originalImage.width
        : targetSize / originalImage.height;

    final newWidth = (originalImage.width * scale).toInt();
    final newHeight = (originalImage.height * scale).toInt();
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

    final double xmin = box.left * targetSize;  
    final double ymin = box.top * targetSize; 
    final double xmax = box.right * targetSize; 
    final double ymax = box.bottom * targetSize; 

    final double adjustedXmin = (xmin - xOffset) / xScale;
    final double adjustedYmin = (ymin - yOffset) / yScale;
    final double adjustedXmax = (xmax - xOffset) / xScale;
    final double adjustedYmax = (ymax - yOffset) / yScale;

    final adjustedLeft = adjustedXmin.clamp(0.0, originalWidth.toDouble());
    final adjustedTop = adjustedYmin.clamp(0.0, originalHeight.toDouble());
    final adjustedRight = adjustedXmax.clamp(0.0, originalWidth.toDouble());
    final adjustedBottom = adjustedYmax.clamp(0.0, originalHeight.toDouble());

    return Rect.fromLTRB(
      adjustedLeft,
      adjustedTop,
      adjustedRight,
      adjustedBottom,
    );
  }
}
