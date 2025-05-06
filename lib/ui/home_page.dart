import 'package:flutter/material.dart';
import '../controllers/objectobject_detection_provider.dart';
import '../services/object_detection_service.dart';
import '../utils/object_detector_painter.dart';
import '../widgets/camera_view.dart';
import 'package:provider/provider.dart';


class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Object Detection App'),
      ),
      body: ColoredBox(
        color: Colors.black,
        child: Center(
          child: MultiProvider(
            providers: [
              Provider(
                create: (context) => ObjectDetectionService(),
              ),
              ChangeNotifierProvider(
                create: (context) => ObjectDetectionViewmodel(
                  context.read<ObjectDetectionService>(),
                ),
              ),
            ],
            child: _HomeBody(),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  late final readViewmodel = context.read<ObjectDetectionViewmodel>();

  @override
  void dispose() {
    Future.microtask(() async => await readViewmodel.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // todo-03-ui-07: change it into Consumer and run the runDetection function
    return Consumer<ObjectDetectionViewmodel>(
      builder: (context, value, child) {
        // todo-03-ui-08: get the state and return the CustomPainter
        final detectedObjects = value.detectedObjects;

        return CustomPaint(
          foregroundPainter: ObjectDetectorPainter(
            detectedObjects,
          ),
          child: child,
        );
      },
      child: CameraView(
        onImage: (cameraImage) async {
          await readViewmodel.runDetection(cameraImage);
        },
      ),
    );
  }
}