import 'package:hive/hive.dart';

part 'intruder_log.g.dart';

@HiveType(typeId: 0)
class IntruderLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  String? photoPath;

  @HiveField(3)
  String triggerType; // 'motion', 'pickup', 'wrong_pin'

  @HiveField(4)
  double? accelerometerMagnitude;

  @HiveField(5)
  bool wasDisarmed;

  IntruderLog({
    required this.id,
    required this.timestamp,
    this.photoPath,
    required this.triggerType,
    this.accelerometerMagnitude,
    this.wasDisarmed = false,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
  }

  String get triggerLabel {
    switch (triggerType) {
      case 'motion':
        return 'Motion Detected';
      case 'pickup':
        return 'Phone Picked Up';
      case 'wrong_pin':
        return 'Wrong PIN Entered';
      default:
        return 'Alert Triggered';
    }
  }
}
