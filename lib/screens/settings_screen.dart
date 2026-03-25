import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../services/alarm_service.dart';
import '../services/permissions_service.dart';
import '../services/protection_controller.dart';
import '../utils/app_theme.dart';
import '../widgets/pin_entry_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = ProtectionController();

  AppSettings get _settings => _controller.settings;

  void _updateSettings(AppSettings newSettings) {
    _controller.saveSettings(newSettings);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel(label: 'DETECTION'),
          const SizedBox(height: 12),
          _sensitivityCard(),
          const SizedBox(height: 24),

          _SectionLabel(label: 'ALARM'),
          const SizedBox(height: 12),
          _alarmToneCard(),
          const SizedBox(height: 12),
          _toggleCard(
            icon: '📳',
            title: 'Vibration',
            subtitle: 'Vibrate when alarm triggers',
            value: _settings.vibrationEnabled,
            onChanged: (v) => _updateSettings(_settings.copyWith(vibrationEnabled: v)),
          ),
          const SizedBox(height: 8),
          _toggleCard(
            icon: '🔦',
            title: 'Flashlight',
            subtitle: 'Flash light when alarm triggers',
            value: _settings.flashlightEnabled,
            onChanged: (v) => _updateSettings(_settings.copyWith(flashlightEnabled: v)),
          ),
          const SizedBox(height: 24),

          _SectionLabel(label: 'ACTIVATION'),
          const SizedBox(height: 12),
          _delayCard(),
          const SizedBox(height: 24),

          _SectionLabel(label: 'SECURITY'),
          const SizedBox(height: 12),
          _toggleCard(
            icon: '📸',
            title: 'Intruder Selfie',
            subtitle: 'Capture photo when triggered',
            value: _settings.intruderSelfieEnabled,
            onChanged: (v) async {
              if (v) {
                final hasPermission = await PermissionsService.requestCameraPermission();
                if (!hasPermission) return;
              }
              _updateSettings(_settings.copyWith(intruderSelfieEnabled: v));
            },
          ),
          const SizedBox(height: 8),
          _toggleCard(
            icon: '👆',
            title: 'Biometric Auth',
            subtitle: 'Use fingerprint to stop alarm',
            value: _settings.biometricEnabled,
            onChanged: (v) async {
              if (v) {
                final available = await PermissionsService.hasBiometrics();
                if (!available) {
                  _showSnack('Biometrics not available on this device');
                  return;
                }
              }
              _updateSettings(_settings.copyWith(biometricEnabled: v));
            },
          ),
          const SizedBox(height: 8),
          _changePinCard(),
          const SizedBox(height: 24),

          _SectionLabel(label: 'ALARM TEST'),
          const SizedBox(height: 12),
          _testAlarmCard(),
          const SizedBox(height: 40),
        ].animate(interval: 40.ms).fadeIn(duration: 300.ms).slideY(
              begin: 0.05,
              end: 0,
            ),
      ),
    );
  }

  Widget _sensitivityCard() {
    const options = ['low', 'medium', 'high'];
    const labels = ['Low', 'Medium', 'High'];
    const descs = ['Less sensitive', 'Balanced', 'Very sensitive'];

    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🎚️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text('Motion Sensitivity',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ]),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (i) {
              final isSelected = _settings.sensitivity == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => _updateSettings(
                      _settings.copyWith(sensitivity: options[i])),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentRed.withOpacity(0.15)
                          : AppTheme.bgCardAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentRed.withOpacity(0.5)
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          labels[i],
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppTheme.accentRed
                                : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          descs[i],
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _alarmToneCard() {
    const tones = [
      ('siren', '🚨', 'Siren'),
      ('beep', '🔔', 'Beep'),
      ('scream', '😱', 'Scream'),
      ('horn', '📯', 'Horn'),
    ];

    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🔊', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text('Alarm Tone',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tones.map((t) {
              final isSelected = _settings.alarmTone == t.$1;
              return GestureDetector(
                onTap: () async {
                  _updateSettings(_settings.copyWith(alarmTone: t.$1));
                  await AlarmService().playTestBeep();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentBlue.withOpacity(0.15)
                        : AppTheme.bgCardAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentBlue.withOpacity(0.5)
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.$2, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        t.$3,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.accentBlue
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _delayCard() {
    const delays = [5, 10, 15, 30];

    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('⏱️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text('Activation Delay',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ]),
          const SizedBox(height: 4),
          Text('Time before alarm arms after activation',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 12, color: AppTheme.textTertiary)),
          const SizedBox(height: 16),
          Row(
            children: delays.map((d) {
              final isSelected = _settings.activationDelay == d;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _updateSettings(_settings.copyWith(activationDelay: d)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentGreen.withOpacity(0.12)
                          : AppTheme.bgCardAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentGreen.withOpacity(0.5)
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Text(
                      '${d}s',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppTheme.accentGreen
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _toggleCard({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return _SettingsCard(
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(subtitle,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 12, color: AppTheme.textTertiary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentRed,
            activeTrackColor: AppTheme.accentRedDim,
            inactiveThumbColor: AppTheme.textTertiary,
            inactiveTrackColor: AppTheme.bgCardAlt,
          ),
        ],
      ),
    );
  }

  Widget _changePinCard() {
    return GestureDetector(
      onTap: () => _showChangePinDialog(),
      child: _SettingsCard(
        child: Row(
          children: [
            const Text('🔑', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Change PIN',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text('Update your security PIN',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 12, color: AppTheme.textTertiary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _testAlarmCard() {
    return GestureDetector(
      onTap: () async {
        await AlarmService().playTestBeep();
        _showSnack('Test beep played!');
      },
      child: _SettingsCard(
        child: Row(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test Alarm',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text('Play a test beep to verify sound',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 12, color: AppTheme.textTertiary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentBlueDim,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
              ),
              child: Text(
                'Test',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChangePinSheet(
        onPinChanged: (newPin) {
          _updateSettings(_settings.copyWith(pin: newPin));
          Navigator.pop(context);
          _showSnack('PIN updated successfully!');
        },
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.spaceGrotesk()),
        backgroundColor: AppTheme.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _ChangePinSheet extends StatefulWidget {
  final Function(String) onPinChanged;

  const _ChangePinSheet({required this.onPinChanged});

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  int _step = 0; // 0=current, 1=new, 2=confirm
  String _newPin = '';
  bool _isError = false;
  final _controller = ProtectionController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColorBright,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _step == 0
                ? 'Enter Current PIN'
                : _step == 1
                    ? 'Enter New PIN'
                    : 'Confirm New PIN',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          if (_isError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _step == 0 ? 'Incorrect PIN' : "PINs don't match",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: AppTheme.accentRed,
                ),
              ),
            ),
          const SizedBox(height: 24),
          PinEntryWidget(
            onPinComplete: _handlePin,
            showForgotPin: false,
            isError: _isError,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _handlePin(String pin) {
    if (_step == 0) {
      if (pin == _controller.settings.pin) {
        setState(() {
          _step = 1;
          _isError = false;
        });
      } else {
        setState(() => _isError = true);
        Future.delayed(const Duration(milliseconds: 800),
            () => setState(() => _isError = false));
      }
    } else if (_step == 1) {
      _newPin = pin;
      setState(() => _step = 2);
    } else {
      if (pin == _newPin) {
        widget.onPinChanged(_newPin);
      } else {
        setState(() {
          _isError = true;
          _step = 1;
          _newPin = '';
        });
        Future.delayed(const Duration(milliseconds: 800),
            () => setState(() => _isError = false));
      }
    }
  }
}
