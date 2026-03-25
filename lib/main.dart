import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'models/intruder_log.dart';
import 'models/app_settings.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/background_service.dart';
import 'utils/app_theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(IntruderLogAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  await Hive.openBox<IntruderLog>('intruder_logs');
  await Hive.openBox<AppSettings>('settings');

  // Init notifications
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Init background service
  await initializeBackgroundService();

  runApp(const DontTouchMyPhoneApp());
}

class DontTouchMyPhoneApp extends StatelessWidget {
  const DontTouchMyPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Don't Touch My Phone",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _isFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  void _checkFirstLaunch() {
    final settingsBox = Hive.box<AppSettings>('settings');
    final settings = settingsBox.get('main');
    setState(() {
      _isFirstLaunch = settings == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isFirstLaunch ? const OnboardingScreen() : const HomeScreen();
  }
}
