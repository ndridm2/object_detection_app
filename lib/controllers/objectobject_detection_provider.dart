import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import '../model/detected_object.dart';
import '../services/object_detection_service.dart';


class ObjectDetectionViewmodel extends ChangeNotifier {
  final ObjectDetectionService _service;

  ObjectDetectionViewmodel(this._service) {
    _service.initHelper();
  }

  List<DetectedObject> _detectedObjects = [];

  List<DetectedObject> get detectedObjects =>
      _detectedObjects.where((e) => e.score >= 0.5).toList();

  Future<void> runDetection(CameraImage camera) async {
    _detectedObjects = await _service.inferenceCameraFrame(camera);
    notifyListeners();
  }

  Future<void> close() async {
    await _service.close();
  }
}