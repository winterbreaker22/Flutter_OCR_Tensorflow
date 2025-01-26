import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;

class TextRecognitionService {
  final textRecognizer = GoogleMlKit.vision.textRecognizer();

  // Extract text from the detected box region in the image
  Future<String> extractText(img.Image image, int xmin, int ymin, int xmax, int ymax) async {
    try {
      final byteList = Uint8List.fromList(image.getBytes());
      final inputImage = InputImage.fromBytes(byteList, InputImageData(size: Size(image.width.toDouble(), image.height.toDouble()), rotation: ImageRotation.rotation0));

      final recognizedText = await textRecognizer.processImage(inputImage);

      // Filter and return text from the bounding box
      String text = "";
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            text += element.text + " ";
          }
        }
      }

      return text;
    } catch (e) {
      print("Error extracting text: $e");
      return "";
    }
  }
}
