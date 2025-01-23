import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

Future<Uint8List> preprocessImage(String imagePath, int targetWidth, int targetHeight) async {
  final imageFile = File(imagePath);
  final imageBytes = await imageFile.readAsBytes();
  final originalImage = img.decodeImage(imageBytes);

  if (originalImage == null) {
    throw Exception('Unable to decode image');
  }

  final aspectRatio = originalImage.width / originalImage.height;
  int newWidth, newHeight;

  if (aspectRatio > 1) {
    newWidth = targetWidth;
    newHeight = (targetWidth / aspectRatio).round();
  } else {
    newHeight = targetHeight;
    newWidth = (targetHeight * aspectRatio).round();
  }

  final resizedImage = img.copyResize(originalImage, width: newWidth, height: newHeight);

  final paddedImage = img.Image(width: targetWidth, height: targetHeight);
  final xOffset = ((targetWidth - newWidth) / 2).round();
  final yOffset = ((targetHeight - newHeight) / 2).round();

  img.copyInto(paddedImage, resizedImage, dstX: xOffset, dstY: yOffset);

  return Uint8List.fromList(img.encodePng(paddedImage));
}
