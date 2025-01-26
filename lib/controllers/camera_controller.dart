import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../services/tensorflow_service.dart';
import '../services/text_recognition_service.dart';
import '../models/bounding_box.dart';

class CameraController extends GetxController {
  var isProcessing = false.obs;
  var recognizedText = [].obs;
  late img.Image originalImage;
  late Size originalSize;
  late Offset paddingOffsets;

  final TensorFlowService _tensorflowService = TensorFlowService();
  final TextRecognitionService _textRecognitionService = TextRecognitionService();

  @override
  void onInit() {
    super.onInit();
    _tensorflowService.loadModel();
  }

  // Preprocess the image: Resize and apply padding
  img.Image preprocessImage(img.Image image) {
    final targetSize = 512;
    final originalWidth = image.width;
    final originalHeight = image.height;

    final scale = (targetSize / originalWidth < targetSize / originalHeight)
        ? targetSize / originalWidth
        : targetSize / originalHeight;

    final newWidth = (originalWidth * scale).toInt();
    final newHeight = (originalHeight * scale).toInt();

    // Resize the image
    img.Image resizedImage = img.copyResize(image, width: newWidth, height: newHeight);

    // Create a padded image
    img.Image paddedImage = img.Image(targetSize, targetSize);
    paddedImage.fillColor(0xFFFFFFFF); // Fill with white background

    int xOffset = (targetSize - newWidth) ~/ 2;
    int yOffset = (targetSize - newHeight) ~/ 2;

    img.copyInto(paddedImage, resizedImage, dstX: xOffset, dstY: yOffset);

    // Save the original image size and padding offsets for later use
    originalSize = Size(originalWidth.toDouble(), originalHeight.toDouble());
    paddingOffsets = Offset(xOffset.toDouble(), yOffset.toDouble());

    return paddedImage;
  }

  // Process the image for object detection and text recognition
  Future<void> processImage(Uint8List imageBytes) async {
    try {
      isProcessing.value = true;

      originalImage = img.decodeImage(imageBytes)!;
      img.Image paddedImage = preprocessImage(originalImage);

      // Run the model to get detections
      var output = await _tensorflowService.detectObjects(paddedImage);

      // Extract text from detected boxes
      await _processDetections(output);

      isProcessing.value = false;
    } catch (e) {
      print("Error processing image: $e");
      isProcessing.value = false;
    }
  }

  Future<void> _processDetections(List<dynamic> detections) async {
    for (var detection in detections) {
      double ymin = detection['rect']['y'] * 512;
      double xmin = detection['rect']['x'] * 512;
      double
