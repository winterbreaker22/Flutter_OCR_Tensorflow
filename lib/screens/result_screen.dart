import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/result_controller.dart';

class ResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Uint8List? preprocessedImage = Get.arguments as Uint8List?;
    final ResultController resultController = Get.put(ResultController());

    if (preprocessedImage != null) {
      resultController.processImage(preprocessedImage);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detection Results')),
      body: Obx(() {
        return Stack(
          children: [
            if (preprocessedImage != null)
              Image.memory(preprocessedImage, width: double.infinity, fit: BoxFit.contain),
            ...resultController.detectedRegions.map((region) {
              final box = region['box'];
              return Positioned(
                left: box[0],
                top: box[1],
                width: box[2] - box[0],
                height: box[3] - box[1],
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.red, width: 2)),
                ),
              );
            }).toList(),
          ],
        );
      }),
    );
  }
}
