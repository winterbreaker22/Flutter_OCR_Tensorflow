import 'package:flutter/material.dart';
import 'dart:io';

class ResultScreen extends StatelessWidget {
  final List? results;
  final String imagePath;

  const ResultScreen({super.key, required this.results, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Extracted Information')),
      body: Column(
        children: [
          Image.file(File(imagePath), height: 250),
          Expanded(
            child: ListView.builder(
              itemCount: results?.length ?? 0,
              itemBuilder: (context, index) {
                var result = results![index];
                return ListTile(
                  title: Text('${result['label']}'),
                  subtitle: Text('Confidence: ${(result['confidence'] * 100).toStringAsFixed(2)}%'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
