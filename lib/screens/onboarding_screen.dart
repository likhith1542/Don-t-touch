import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_settings.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import '../widgets/pin_entry_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String _pin = '';
  String _confirmPin = '';
  bool _pinMismatch = false;
  bool _isSettingConfirm = false;

  final List<_OnboardingStep> _steps = [
    _OnboardingStep(
      icon: '🛡️',
      title: "Secure Your\nPhone",
      subtitle: "Instant alarm when someone\ntouches your device",
      color: AppTheme.accentRed,
    ),
    _OnboardingStep(
      icon: '📳',
      title: "Motion\nDetection",
      subtitle: "Advanced sensors detect even\nthe slightest movement",
      color: AppTheme.accentBlue,
    ),
    _OnboardingStep(
      icon: '📸',
      title: "Intruder\nCapture",
      subtitle: "Automatically photographs\nanyone who picks up your phone",
      color: AppTheme.accentOrange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: _step < 3
            ? _buildIntroSlides()
            : _step == 3
                ? _buildPermissionsStep()
                : _buildPinSetup(),
      ),
    );
  }

  Widget _buildIntroSlides() {
    final step = _steps[_step];
    return Column(
      children: [
        const SizedBox(height: 60),
        // Step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _step ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _step ? step.color : AppTheme.borderColorBright,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 60),

        // Icon
        Text(
          step.icon,
          style: const TextStyle(fontSize: 80),
        ).animate(key: ValueKey(_step)).scale(
              duration: 400.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 40),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            step.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
        ).animate(key: ValueKey('title_$_step')).fadeIn(duration: 400.ms).slideY(
              begin: 0.2,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOut,
            ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            step.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 17,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ).animate(key: ValueKey('sub_$_step')).fadeIn(
              delay: 100.ms,
              duration: 400.ms,
            ),

        const Spacer(),

        // Next button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: GestureDetector(
            onTap: () => setState(() => _step++),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: step.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: step.color.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _step == 2 ? 'Get Started' : 'Next',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Allow\nPermissions',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'Required for full protection',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 40),
          ..._permissionItems
              .asMap()
              .entries
              .map((e) => _PermissionTile(
                    item: e.value,
                    delay: e.key * 80,
                  ))
              .toList(),
          const Spacer(),
          GestureDetector(
            onTap: _requestPermissions,
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accentRed,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentRed.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Grant Permissions',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _step = 4),
            child: Center(
              child: Text(
                'Skip for now',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static const List<_PermissionItem> _permissionItems = [
    _PermissionItem(icon: '📷', title: 'Camera', desc: 'Capture intruder photos'),
    _PermissionItem(icon: '🔔', title: 'Notifications', desc: 'Alert you of intrusions'),
    _PermissionItem(icon: '🔋', title: 'Battery Optimization', desc: 'Run in background'),
    _PermissionItem(icon: '📳', title: 'Motion Sensors', desc: 'Detect phone movement'),
  ];

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    ].request();
    setState(() => _step = 4);
  }

  Widget _buildPinSetup() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            _isSettingConfirm ? 'Confirm\nYour PIN' : 'Set Your\nSecret PIN',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 12),
          Text(
            _pinMismatch
                ? "PINs don't match. Try again."
                : _isSettingConfirm
                    ? 'Enter your PIN again to confirm'
                    : 'This PIN will stop the alarm',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: _pinMismatch ? AppTheme.accentRed : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 48),
          PinEntryWidget(
            onPinComplete: _handlePinEntry,
            showForgotPin: false,
          ),
        ],
      ),
    );
  }

  void _handlePinEntry(String pin) {
    if (!_isSettingConfirm) {
      setState(() {
        _pin = pin;
        _isSettingConfirm = true;
      });
    } else {
      if (pin == _pin) {
        _saveSettingsAndNavigate(pin);
      } else {
        setState(() {
          _pinMismatch = true;
          _isSettingConfirm = false;
          _pin = '';
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _pinMismatch = false);
        });
      }
    }
  }

  Future<void> _saveSettingsAndNavigate(String pin) async {
    final settings = AppSettings(
      pin: pin,
      isFirstLaunch: false,
    );
    final box = Hive.box<AppSettings>('settings');
    await box.put('main', settings);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}

class _OnboardingStep {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _PermissionItem {
  final String icon;
  final String title;
  final String desc;
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

class _PermissionTile extends StatelessWidget {
  final _PermissionItem item;
  final int delay;

  const _PermissionTile({required this.item, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                item.desc,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(
          begin: -0.1,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 300.ms,
        );
  }
}
