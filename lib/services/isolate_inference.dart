import 'dart:io';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as image_lib;
import '../model/detected_object.dart';
import '../utils/image_util.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class IsolateInference {
  static const String _debugName = "TFLITE_INFERENCE";
  final ReceivePort _receivePort = ReceivePort();
  late Isolate _isolate;
  late SendPort _sendPort;
  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: _debugName,
    );
    _sendPort = await _receivePort.first;
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final InferenceModel isolateModel in port) {
      final cameraImage = isolateModel.cameraImage!;
      final inputShape = isolateModel.inputShape;
      final imageMatrix = _imagePreProcessing(cameraImage, inputShape);

      final input = [imageMatrix];
      // todo-02-inference-02: change the output format
      final output = {
        0: [List<List<num>>.filled(10, List<num>.filled(4, 0))],
        1: [List<num>.filled(10, 0)],
        2: [List<num>.filled(10, 0)],
        3: [0.0],
      };
      final address = isolateModel.interpreterAddress;

      // todo-02-inference-03: change parameter type and method inference
      final result = _runInference(input, output, address);

      // todo-02-inference-04: change result preperation
      final labels = isolateModel.labels;
      final detectedObjects = _defineDetectedObject(result, labels);

      // todo-02-inference-05: send the detected objects
      isolateModel.responsePort.send(detectedObjects);
    }
  }

  static List<DetectedObject> _defineDetectedObject(
      List<List<Object>> result, List<String> labels) {
    // Location
    final locationsRaw = result.first.first as List<List<double>>;
    final locations = locationsRaw
        .map((list) => list.map((value) => (value * 300)).toList())
        .map((rect) => Rect.fromLTRB(rect[1], rect[0], rect[3], rect[2]))
        .toList();

    // Classes
    final classesRaw = result.elementAt(1).first as List<double>;
    final classes = classesRaw.map((value) => value.toInt()).toList();

    // Scores
    final scores = result.elementAt(2).first as List<double>;

    // Number of detections
    final numberOfDetectionsRaw = result.last.first as double;
    final numberOfDetections = numberOfDetectionsRaw.toInt();

    final List<String> classification = [];
    for (var i = 0; i < numberOfDetections; i++) {
      classification.add(labels[classes[i]]);
    }

    /// Generate recognitions
    List<DetectedObject> recognitions = [];
    for (int i = 0; i < numberOfDetections; i++) {
      // Prediction score
      var score = scores[i];

      // Label string
      var label = classification[i];

      recognitions.add(DetectedObject(
        id: i,
        label: label,
        score: score,
        rect: locations[i],
      ));
    }

    return recognitions;
    // locations: Rect location
    // numberOfDetections: iteration number
    // scores: confidence score
    // classication: label
  }

  Future<void> close() async {
    _isolate.kill();
    _receivePort.close();
  }

  static List<List<List<num>>> _imagePreProcessing(
    CameraImage cameraImage,
    List<int> inputShape,
  ) {
    image_lib.Image? img;
    img = ImageUtils.convertCameraImage(cameraImage);

    // resize original image to match model shape.
    image_lib.Image imageInput = image_lib.copyResize(
      img!,
      width: inputShape[1],
      height: inputShape[2],
    );

    if (Platform.isAndroid) {
      imageInput = image_lib.copyRotate(imageInput, angle: 90);
    }

    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );
    return imageMatrix;
  }

  static List<List<Object>> _runInference(
    List<List<List<List<num>>>> input,
    Map<int, List<Object>> output,
    int interpreterAddress,
  ) {
    Interpreter interpreter = Interpreter.fromAddress(interpreterAddress);
    interpreter.runForMultipleInputs([input], output);
    // Get output tensor
    final result = output.values.toList();
    return result;
  }
}

class InferenceModel {
  CameraImage? cameraImage;
  int interpreterAddress;
  List<String> labels;
  List<int> inputShape;
  List<int> outputShape;
  late SendPort responsePort;

  InferenceModel(this.cameraImage, this.interpreterAddress, this.labels,
      this.inputShape, this.outputShape);
}