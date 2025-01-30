import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class ResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> arguments = Get.arguments ?? {};
    final img.Image finalImage = arguments['image'];
    final List<String> extractedTexts = arguments['texts'] ?? [];

    final Uint8List imageBytes = Uint8List.fromList(img.encodeJpg(finalImage));

    return Scaffold(
      appBar: AppBar(
        title: Text('Detection Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.memory(imageBytes, height: 300, width: double.infinity, fit: BoxFit.contain),
              ),
              SizedBox(height: 20),
              
              if (extractedTexts.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    extractedTexts.length > 8 ? 8 : extractedTexts.length,
                    (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(extractedTexts[index], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Center(
                  child: Text('No text detected', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
