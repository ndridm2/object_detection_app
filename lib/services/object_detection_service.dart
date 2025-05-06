import 'dart:developer';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../model/detected_object.dart';
import 'package:tflite_flutter/tflite_flutter.dart';


import 'isolate_inference.dart';

class ObjectDetectionService {
  // todo-01-init-03: change the model static value
  final modelPath = 'assets/ssd_mobilenet.tflite';
  final labelsPath = 'assets/labelmap.txt';

  late final Interpreter interpreter;
  late final List<String> labels;
  late Tensor inputTensor;
  late Tensor outputTensor;
  late final IsolateInference isolateInference;

  Future<void> _loadModel() async {
    final options = InterpreterOptions()
      ..useNnApiForAndroid = true
      ..useMetalDelegateForIOS = true;

    // Load model from assets
    interpreter = await Interpreter.fromAsset(modelPath, options: options);
    // Get tensor input shape [1, 300, 300, 3]
    inputTensor = interpreter.getInputTensors().first;
    // Get tensor output shape [1, 10, 4]
    outputTensor = interpreter.getOutputTensors().first;

    log('Interpreter loaded successfully');
  }

  Future<void> _loadLabels() async {
    final labelTxt = await rootBundle.loadString(labelsPath);
    labels = labelTxt.split('\n');
  }

  Future<void> initHelper() async {
    _loadLabels();
    _loadModel();

    isolateInference = IsolateInference();
    await isolateInference.start();
  }

  // todo-02-inference-06: change the result type
  Future<List<DetectedObject>> inferenceCameraFrame(
      CameraImage cameraImage) async {
    var isolateModel = InferenceModel(cameraImage, interpreter.address, labels,
        inputTensor.shape, outputTensor.shape);

    ReceivePort responsePort = ReceivePort();
    isolateInference.sendPort.send(
      isolateModel..responsePort = responsePort.sendPort,
    );
    // get inference result.
    var results = await responsePort.first;
    return results;
  }

  Future<void> close() async {
    await isolateInference.close();
  }
}