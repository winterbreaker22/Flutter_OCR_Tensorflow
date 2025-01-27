import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controllers/image_controller.dart';
import 'package:permission_handler/permission_handler.dart';

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
    // Request camera permission if it's not already granted
    final status = await Permission.camera.request();
    if (status.isDenied) {
      // Handle the case when permission is denied
      return;
    }

    _cameras = await availableCameras();

    _cameraController = CameraController(
      _cameras[1], // Use 0 for back camera
      ResolutionPreset.medium,
    );

    await _cameraController?.initialize();

    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if the camera controller is initialized
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Camera Preview")),
      body: Stack(
        children: [
          // Display the camera preview
          CameraPreview(_cameraController!),

          // Capture button
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final image = await _cameraController!.takePicture();
                  Get.find<ImageController>().processImage(image);
                },
                child: const Text("Capture"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
