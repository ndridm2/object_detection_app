import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../model/detected_object.dart';

class ObjectDetectorPainter extends CustomPainter {
  final List<DetectedObject> objects;

  ObjectDetectorPainter(
    this.objects,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()
      ..strokeWidth = 5.0
      ..color = Colors.red;

    for (var object in objects) {
      var rect = object.rect;
      final score = object.score;
      final label = object.label;
      final text = "$label: ${(score * 100).toStringAsFixed(1)}%";

      final left = _translateX(rect.left, size);
      final top = _translateY(rect.top, size);
      final width = _translateX(rect.width, size);
      final height = _translateY(rect.height, size);
      rect = Rect.fromLTWH(left, top, width, height);

      canvas.drawRect(
        rect,
        paint1..style = PaintingStyle.stroke,
      );

      final paragraphStyle = ui.ParagraphStyle(
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      final textStyle = ui.TextStyle(
        color: Colors.white,
        background: paint1..style = PaintingStyle.fill,
        fontSize: 12,
      );
      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(text);
      final paragraphConstraints = ui.ParagraphConstraints(
        width: (rect.right - rect.left).abs(),
      );
      final paragraph = paragraphBuilder.build()..layout(paragraphConstraints);

      canvas.drawParagraph(
        paragraph,
        Offset(rect.left, rect.top),
      );
    }
  }

  double _translateX(double x, Size canvasSize) => x * canvasSize.width / 300;

  double _translateY(double y, Size canvasSize) => y * canvasSize.height / 300;

  @override
  bool shouldRepaint(ObjectDetectorPainter oldDelegate) {
    return oldDelegate.objects != objects;
  }
}