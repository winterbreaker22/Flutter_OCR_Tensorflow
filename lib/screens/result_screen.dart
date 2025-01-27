import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/image_controller.dart';
import '../widgets/bounding_box_painter.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ImageController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Result")),
      body: Obx(() {
        final imageFile = controller.capturedImage.value;
        if (imageFile == null) return const Text("No Image Captured");

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Image.file(imageFile),
                  CustomPaint(
                    painter: BoundingBoxPainter(controller.boundingBoxes),
                    child: Container(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: controller.extractedTexts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.text_snippet),
                    title: Text(controller.extractedTexts[index]),
                  );
                },
              ),
            )
          ],
        );
      }),
    );
  }
}
