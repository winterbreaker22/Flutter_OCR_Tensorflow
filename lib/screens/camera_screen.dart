import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controllers/camera_controller.dart';

class CameraScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CameraViewController cameraController = Get.put(CameraViewController());

    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: Obx(() {
        if (!cameraController.isInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            CameraPreview(cameraController.cameraController),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  onPressed: () async {
                    await cameraController.capturePhoto();
                    Get.toNamed('/results', arguments: cameraController.processedImage.value);
                  },
                  child: const Icon(Icons.camera),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
