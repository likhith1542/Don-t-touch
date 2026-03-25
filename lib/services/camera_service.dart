import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  bool _isInitialized = false;

  Future<bool> initialize() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return false;

    try {
      final cameras = await availableCameras();
      // Find front camera
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  Future<String?> captureIntruderPhoto() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return null;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final intruderDir = Directory('${directory.path}/intruder_logs');
      if (!await intruderDir.exists()) {
        await intruderDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${intruderDir.path}/intruder_$timestamp.jpg';

      final file = await _controller!.takePicture();
      await File(file.path).copy(path);

      return path;
    } catch (e) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
}
