import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import '../controllers/image_controller.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> _cameras;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[1], 
      ResolutionPreset.high,
    );

    await _cameraController?.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    final image = await _cameraController!.takePicture();
    final file = File(image.path);

    final capturedImage = img.decodeImage(file.readAsBytesSync())!;

    final cropHeight = (capturedImage.height / 3).round();
    final cropY = ((capturedImage.height - cropHeight) / 2).round(); 

    final croppedImage = img.copyCrop(
      capturedImage,
      x: 0,
      y: cropY,
      width: capturedImage.width,
      height: cropHeight,
    );

    final verticalFlippedImage = img.flipVertical(croppedImage);
    // final flippedImage = img.flipHorizontal(verticalFlippedImage);

    Get.find<ImageController>().processImage(verticalFlippedImage);
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Camera Preview")),
      body: Center(
        child: CameraPreview(_cameraController!),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _captureImage,
          child: const Text("Capture"),
        ),
      ),
    );
  }
}
