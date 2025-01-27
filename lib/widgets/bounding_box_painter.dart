import 'package:flutter/material.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Rect> boundingBoxes;

  BoundingBoxPainter(this.boundingBoxes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final rect in boundingBoxes) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
