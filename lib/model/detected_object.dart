import 'package:flutter/widgets.dart';

class DetectedObject {
  int id;
  Rect rect;
  num score;
  String label;
  DetectedObject({
    required this.id,
    required this.rect,
    required this.score,
    required this.label,
  });

  @override
  String toString() {
    return 'DetectedObject(id: $id, rect: $rect, score: $score, label: $label)';
  }
}