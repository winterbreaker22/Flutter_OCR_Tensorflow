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
        child: SingleChildScrollView( // Wrap everything in a SingleChildScrollView to make it scrollable
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the processed image
              Center(
                child: Image.memory(imageBytes, height: 300, width: double.infinity, fit: BoxFit.contain),
              ),
              SizedBox(height: 20),
              
              // Display the extracted texts with a maximum of 8 lines visible
              if (extractedTexts.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    extractedTexts.length > 8 ? 8 : extractedTexts.length, // Limit to 8 lines
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
              
              // If there are more than 8 lines, show a "See More" button to reveal all text
              if (extractedTexts.length > 8)
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.snackbar(
                        'All Text Detected', 
                        extractedTexts.join('\n'), 
                        snackPosition: SnackPosition.BOTTOM,
                        duration: Duration(seconds: 5),
                      );
                    },
                    child: Text('See More'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
