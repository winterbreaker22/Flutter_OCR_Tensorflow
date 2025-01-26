import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ResultController extends GetxController {
  final detectedRegions = <Map<String, dynamic>>[].obs; // Contains bounding boxes and class IDs

  late Interpreter interpreter;

  @override
  void onInit() {
    super.onInit();
    loadModel();
  }

  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('model.tflite');
  }

  Future<void> processImage(Uint8List imageBytes) async {
    final input = imageBytes.buffer.asUint8List();

    final outputBoxes = List.generate(1, (i) => List.filled(4, 0.0));
    final outputScores = List.filled(1, 0.0);

    interpreter.run(input, {'output_boxes': outputBoxes, 'output_scores': outputScores});

    for (var i = 0; i < outputBoxes.length; i++) {
      final box = outputBoxes[i];
      final score = outputScores[i];

      if (score > 0.5) {
        detectedRegions.add({
          'box': box,
          'score': score,
        });
      }
    }
  }
}
