import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class ResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the passed arguments (both image and texts)
    final Map<String, dynamic> arguments = Get.arguments ?? {};
    final img.Image finalImage = arguments['image'];
    final List<String> extractedTexts = arguments['texts'] ?? [];

    // Convert img.Image to Uint8List for displaying with Image.memory
    final Uint8List imageBytes = Uint8List.fromList(img.encodeJpg(finalImage));

    return Scaffold(
      appBar: AppBar(
        title: Text('Detection Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the processed image
            Center(
              child: Image.memory(imageBytes),
            ),
            SizedBox(height: 20),
            // Display the extracted texts
            if (extractedTexts.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: extractedTexts.map((text) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(text),
                    ),
                  );
                }).toList(),
              )
            else
              Center(
                child: Text('No text detected'),
              ),
          ],
        ),
      ),
    );
  }
}
