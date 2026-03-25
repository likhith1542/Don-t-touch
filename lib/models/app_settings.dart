import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  String pin;

  @HiveField(1)
  String sensitivity; // 'low', 'medium', 'high'

  @HiveField(2)
  String alarmTone; // 'siren', 'beep', 'scream', 'horn'

  @HiveField(3)
  bool vibrationEnabled;

  @HiveField(4)
  bool flashlightEnabled;

  @HiveField(5)
  bool intruderSelfieEnabled;

  @HiveField(6)
  int activationDelay; // seconds: 5, 10, 15, 30

  @HiveField(7)
  bool biometricEnabled;

  @HiveField(8)
  String? patternHash;

  @HiveField(9)
  int wrongPinAttempts;

  @HiveField(10)
  bool isFirstLaunch;

  AppSettings({
    required this.pin,
    this.sensitivity = 'medium',
    this.alarmTone = 'siren',
    this.vibrationEnabled = true,
    this.flashlightEnabled = true,
    this.intruderSelfieEnabled = true,
    this.activationDelay = 5,
    this.biometricEnabled = false,
    this.patternHash,
    this.wrongPinAttempts = 0,
    this.isFirstLaunch = true,
  });

  double get sensitivityThreshold {
    switch (sensitivity) {
      case 'low':
        return 18.0;
      case 'medium':
        return 12.0;
      case 'high':
        return 7.0;
      default:
        return 12.0;
    }
  }

  AppSettings copyWith({
    String? pin,
    String? sensitivity,
    String? alarmTone,
    bool? vibrationEnabled,
    bool? flashlightEnabled,
    bool? intruderSelfieEnabled,
    int? activationDelay,
    bool? biometricEnabled,
    String? patternHash,
    int? wrongPinAttempts,
    bool? isFirstLaunch,
  }) {
    return AppSettings(
      pin: pin ?? this.pin,
      sensitivity: sensitivity ?? this.sensitivity,
      alarmTone: alarmTone ?? this.alarmTone,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      flashlightEnabled: flashlightEnabled ?? this.flashlightEnabled,
      intruderSelfieEnabled: intruderSelfieEnabled ?? this.intruderSelfieEnabled,
      activationDelay: activationDelay ?? this.activationDelay,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      patternHash: patternHash ?? this.patternHash,
      wrongPinAttempts: wrongPinAttempts ?? this.wrongPinAttempts,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
    );
  }
}
