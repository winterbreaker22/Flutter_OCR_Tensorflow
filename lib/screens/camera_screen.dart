import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/camera_controller.dart';

class CameraScreen extends StatelessWidget {
  final CameraController cameraController = Get.put(CameraController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Document OCR with TensorFlow Lite")),
      body: Column(
        children: [
          Obx(() {
            if (cameraController.isProcessing.value) {
              return CircularProgressIndicator();
            }
            return Container();
          }),
          Expanded(
            child: CameraPreviewWidget(),
          ),
          ElevatedButton(
            onPressed: () async {
              final picker = ImagePicker();
              final imageFile = await picker.pickImage(source: ImageSource.camera);

              if (imageFile != null) {
                final imageBytes = await imageFile.readAsBytes();
                cameraController.processImage(imageBytes);
              }
            },
            child: Text('Capture Image'),
          ),
          Obx(() {
            if (cameraController.recognizedText.isNotEmpty) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: cameraController.recognizedText.length,
                itemBuilder: (context, index) {
                  var box = cameraController.recognizedText[index];
                  return ListTile(
                    title: Text(box.text),
                    subtitle: Text("Bounding box: ${box.box}"),
                  );
                },
              );
            }
            return Container();
          }),
        ],
      ),
    );
  }
}
