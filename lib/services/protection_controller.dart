import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/intruder_log.dart';
import 'motion_detection_service.dart';
import 'alarm_service.dart';
import 'camera_service.dart';

enum ProtectionStatus { idle, arming, protected, triggered }

class ProtectionController extends ChangeNotifier {
  static final ProtectionController _instance = ProtectionController._internal();
  factory ProtectionController() => _instance;
  ProtectionController._internal();

  ProtectionStatus _status = ProtectionStatus.idle;
  ProtectionStatus get status => _status;

  int _countdownSeconds = 0;
  int get countdownSeconds => _countdownSeconds;

  Timer? _countdownTimer;

  final MotionDetectionService motionDetectionService = MotionDetectionService();
  final AlarmService alarmServiceInstance = AlarmService();
  final CameraService cameraService = CameraService();

  AppSettings get settings {
    final box = Hive.box<AppSettings>('settings');
    return box.get('main') ?? AppSettings(pin: '0000');
  }

  List<IntruderLog> get intruderLogs {
    final box = Hive.box<IntruderLog>('intruder_logs');
    final logs = box.values.toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  Stream<double> get motionStream => motionDetectionService.motionStream;
  bool get isAlarmPlaying => alarmServiceInstance.isPlaying;

  Future<void> startProtection() async {
    if (_status == ProtectionStatus.protected ||
        _status == ProtectionStatus.arming) return;

    final delay = settings.activationDelay;
    _status = ProtectionStatus.arming;
    _countdownSeconds = delay;
    notifyListeners();

    // Play first tick immediately
    alarmServiceInstance.playTick();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      notifyListeners();

      if (_countdownSeconds > 0) {
        // Tick gets faster on last 3 seconds
        alarmServiceInstance.playTick();
      }

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _activateProtection();
      }
    });
  }

  Future<void> _activateProtection() async {
    _status = ProtectionStatus.protected;
    notifyListeners();

    motionDetectionService.setThreshold(settings.sensitivityThreshold);
    motionDetectionService.setTriggerCallback(_onMotionTriggered);
    motionDetectionService.startCalibration();
    motionDetectionService.arm();
  }

  Future<void> _onMotionTriggered(double magnitude, String type) async {
    if (_status != ProtectionStatus.protected) return;

    _status = ProtectionStatus.triggered;
    notifyListeners();

    await alarmServiceInstance.startAlarm(
      tone: settings.alarmTone,
      vibration: settings.vibrationEnabled,
      flashlight: settings.flashlightEnabled,
    );

    String? photoPath;
    if (settings.intruderSelfieEnabled) {
      photoPath = await cameraService.captureIntruderPhoto();
    }

    final log = IntruderLog(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      photoPath: photoPath,
      triggerType: type,
      accelerometerMagnitude: magnitude,
      wasDisarmed: false,
    );

    final box = Hive.box<IntruderLog>('intruder_logs');
    await box.put(log.id, log);
    notifyListeners();
  }

  Future<bool> stopAlarmWithPin(String enteredPin) async {
    if (enteredPin == settings.pin) {
      await alarmServiceInstance.playSuccess();
      await stopProtection();
      return true;
    }

    // Wrong PIN — play error, take photo, log
    await alarmServiceInstance.playError();

    String? photoPath;
    if (settings.intruderSelfieEnabled) {
      photoPath = await cameraService.captureIntruderPhoto();
    }

    final log = IntruderLog(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      photoPath: photoPath,
      triggerType: 'wrong_pin',
      wasDisarmed: false,
    );
    final box = Hive.box<IntruderLog>('intruder_logs');
    await box.put(log.id, log);

    final s = settings;
    final settingsBox = Hive.box<AppSettings>('settings');
    await settingsBox.put('main', s.copyWith(wrongPinAttempts: s.wrongPinAttempts + 1));
    notifyListeners();
    return false;
  }

  Future<void> stopProtection() async {
    _countdownTimer?.cancel();
    motionDetectionService.disarm();
    await alarmServiceInstance.stopAlarm();
    setStatusIdle();
  }

  void setStatusIdle() {
    _status = ProtectionStatus.idle;
    _countdownSeconds = 0;
    notifyListeners();
  }

  Future<void> cancelArming() async {
    _countdownTimer?.cancel();
    _status = ProtectionStatus.idle;
    _countdownSeconds = 0;
    notifyListeners();
  }

  void saveSettings(AppSettings newSettings) {
    final box = Hive.box<AppSettings>('settings');
    box.put('main', newSettings);
    notifyListeners();
  }

  Future<void> clearLogs() async {
    final box = Hive.box<IntruderLog>('intruder_logs');
    await box.clear();
    notifyListeners();
  }
}
