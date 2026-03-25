import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

import '../models/app_settings.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'dont_touch_security',
    'Security Protection',
    description: 'Active security monitoring',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'dont_touch_security',
      initialNotificationTitle: "🔒 Protection Active",
      initialNotificationContent: "Your phone is secured",
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onServiceStart,
    ),
  );
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  await Hive.initFlutter();
  Hive.registerAdapter(_AppSettingsAdapterBg());
  await Hive.openBox<dynamic>('settings');

  double threshold = 12.0;
  try {
    final box = Hive.box<dynamic>('settings');
    final rawSettings = box.get('main');
    if (rawSettings != null) {
      threshold = (rawSettings as dynamic).sensitivityThreshold as double;
    }
  } catch (_) {}

  StreamSubscription<AccelerometerEvent>? sub;
  DateTime? lastTrigger;

  sub = accelerometerEventStream().listen((event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final deviation = (magnitude - 9.8).abs();

    final now = DateTime.now();
    if (deviation > threshold) {
      if (lastTrigger == null ||
          now.difference(lastTrigger!) > const Duration(seconds: 2)) {
        lastTrigger = now;
        service.invoke('motion_detected', {'magnitude': deviation});
      }
    }
  });

  service.on('arm').listen((event) {
    final sens = event?['threshold'] as double? ?? 12.0;
    threshold = sens;
  });

  service.on('disarm').listen((event) {
    sub?.cancel();
    service.stopSelf();
  });
}

// Minimal adapter for background isolate
class _AppSettingsAdapterBg extends TypeAdapter<dynamic> {
  @override
  final int typeId = 1;
  @override
  dynamic read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return _BgSettings(
      sensitivityThreshold: _getSensitivity(fields[1] as String? ?? 'medium'),
    );
  }

  double _getSensitivity(String s) {
    switch (s) {
      case 'low': return 18.0;
      case 'medium': return 12.0;
      case 'high': return 7.0;
      default: return 12.0;
    }
  }

  @override
  void write(BinaryWriter writer, dynamic obj) {}
}

class _BgSettings {
  final double sensitivityThreshold;
  _BgSettings({required this.sensitivityThreshold});
}
