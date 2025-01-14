import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'tflite_service.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> cameras;
  String? imagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _cameraController = CameraController(cameras.first, ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() {});
  }

  Future<void> _captureImage() async {
    final XFile image = await _cameraController.takePicture();
    setState(() {
      imagePath = image.path;
    });

    List? results = await TFLiteService.runModelOnImage(imagePath!);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(results: results, imagePath: imagePath!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) return CircularProgressIndicator();
    return Scaffold(
      appBar: AppBar(title: Text('Scan Document')),
      body: Column(
        children: [
          Expanded(flex: 2, child: CameraPreview(_cameraController)),
          ElevatedButton(
            onPressed: _captureImage,
            child: Text('Capture Document'),
          ),
        ],
      ),
    );
  }
}
