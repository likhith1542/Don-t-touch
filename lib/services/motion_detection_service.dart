import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum MotionState { idle, armed, triggered }

class MotionDetectionService {
  static final MotionDetectionService _instance = MotionDetectionService._internal();
  factory MotionDetectionService() => _instance;
  MotionDetectionService._internal();

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  final _motionController = StreamController<double>.broadcast();
  Stream<double> get motionStream => _motionController.stream;

  double _threshold = 12.0;
  bool _isArmed = false;
  bool _isTriggered = false;

  // Baseline calibration
  double _baseX = 0, _baseY = 0, _baseZ = 9.8;
  bool _isCalibrated = false;
  int _calibrationSamples = 0;
  static const int _calibrationCount = 10;

  // Debounce
  DateTime? _lastTrigger;
  static const Duration _debounceDuration = Duration(seconds: 2);

  // Smoothing
  final List<double> _magnitudeBuffer = [];
  static const int _bufferSize = 5;

  void setThreshold(double threshold) {
    _threshold = threshold;
  }

  void startCalibration() {
    _isCalibrated = false;
    _calibrationSamples = 0;
    _baseX = 0;
    _baseY = 0;
    _baseZ = 0;

    double sumX = 0, sumY = 0, sumZ = 0;

    StreamSubscription<AccelerometerEvent>? calSub;
    calSub = accelerometerEventStream().listen((event) {
      sumX += event.x;
      sumY += event.y;
      sumZ += event.z;
      _calibrationSamples++;

      if (_calibrationSamples >= _calibrationCount) {
        _baseX = sumX / _calibrationCount;
        _baseY = sumY / _calibrationCount;
        _baseZ = sumZ / _calibrationCount;
        _isCalibrated = true;
        calSub?.cancel();
      }
    });
  }

  void arm() {
    if (_isArmed) return;
    _isArmed = true;
    _isTriggered = false;
    _magnitudeBuffer.clear();

    if (!_isCalibrated) {
      startCalibration();
      // Wait a bit for calibration
      Future.delayed(const Duration(milliseconds: 500), _startListening);
    } else {
      _startListening();
    }
  }

  void _startListening() {
    _accelSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen(_onAccelerometerEvent);

    _gyroSubscription = gyroscopeEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen(_onGyroscopeEvent);
  }

  void disarm() {
    _isArmed = false;
    _isTriggered = false;
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription = null;
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_isArmed || _isTriggered) return;

    final dx = event.x - _baseX;
    final dy = event.y - _baseY;
    final dz = event.z - _baseZ;
    final magnitude = sqrt(dx * dx + dy * dy + dz * dz);

    // Smooth the reading
    _magnitudeBuffer.add(magnitude);
    if (_magnitudeBuffer.length > _bufferSize) {
      _magnitudeBuffer.removeAt(0);
    }

    final smoothed = _magnitudeBuffer.reduce((a, b) => a + b) / _magnitudeBuffer.length;

    _motionController.add(smoothed);

    if (smoothed > _threshold) {
      _checkTrigger(smoothed);
    }
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    if (!_isArmed || _isTriggered) return;

    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // High rotation = pickup/significant movement
    if (magnitude > 2.5) {
      _checkTrigger(magnitude * 5, isRotation: true);
    }
  }

  void _checkTrigger(double magnitude, {bool isRotation = false}) {
    final now = DateTime.now();
    if (_lastTrigger != null &&
        now.difference(_lastTrigger!) < _debounceDuration) {
      return;
    }
    _lastTrigger = now;
    _isTriggered = true;
    _onTrigger?.call(magnitude, isRotation ? 'pickup' : 'motion');
  }

  Function(double magnitude, String type)? _onTrigger;

  void setTriggerCallback(Function(double magnitude, String type) callback) {
    _onTrigger = callback;
  }

  void reset() {
    _isTriggered = false;
  }

  bool get isArmed => _isArmed;
  bool get isTriggered => _isTriggered;

  void dispose() {
    disarm();
    _motionController.close();
  }
}
