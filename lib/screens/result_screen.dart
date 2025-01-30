import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import '../controllers/image_controller.dart';
import 'dart:typed_data';

class ResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Result')),
      body: Center(
        child: GetBuilder<ImageController>(
          builder: (controller) {
            return Image.memory(Uint8List.fromList(img.encodeJpg(controller.capturedImage.value)));
          },
        ),
      ),
    );
  }
}
