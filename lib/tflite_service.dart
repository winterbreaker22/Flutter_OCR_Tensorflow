import 'package:tflite/tflite.dart';

class TFLiteService {
  static Future<void> loadModel() async {
    String? res = await Tflite.loadModel(
      model: 'assets/model.tflite',
      // labels: 'assets/labels.txt', // Optional, if you have label file
    );
    print("Model loaded: $res");
  }

  static Future<List?> runModelOnImage(String imagePath) async {
    var output = await Tflite.runModelOnImage(
      path: imagePath,
      numResults: 5,
      threshold: 0.1,
    );
    return output;
  }

  static Future<void> close() async {
    await Tflite.close();
  }
}
