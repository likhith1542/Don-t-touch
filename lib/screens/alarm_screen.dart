import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

import '../services/protection_controller.dart';
import '../utils/app_theme.dart';
import '../widgets/pin_entry_widget.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with TickerProviderStateMixin {
  final _controller = ProtectionController();
  late AnimationController _flashController;

  bool _showPinEntry = false;
  String? _errorMessage;
  int _failedAttempts = 0;

  // Single processing guard — reset explicitly in all paths
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final auth = LocalAuthentication();
      final result = await auth.authenticate(
        localizedReason: 'Authenticate to stop the alarm',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (result) {
        await _controller.stopProtection();
        if (mounted) Navigator.of(context).pop();
      } else {
        if (mounted) setState(() => _isProcessing = false);
      }
    } catch (_) {
      if (mounted) setState(() {
        _errorMessage = 'Biometric not available';
        _isProcessing = false;
      });
    }
  }

  Future<void> _onPinEntered(String pin) async {
    // PinEntryWidget already has its own submit guard — this is a safety net
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final success = await _controller.stopAlarmWithPin(pin);

    if (!mounted) return;

    if (success) {
      // stopProtection already called inside stopAlarmWithPin
      Navigator.of(context).pop();
      // _isProcessing intentionally not reset — screen is gone
    } else {
      _failedAttempts++;
      setState(() {
        _errorMessage = _failedAttempts >= 3
            ? 'Too many attempts! Photo captured.'
            : 'Wrong PIN. Try again.';
        _isProcessing = false; // allow retry
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _errorMessage = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // replaces deprecated WillPopScope
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  AppTheme.accentRed.withOpacity(0.1 + _flashController.value * 0.25),
                  Colors.black,
                ],
              ),
            ),
            child: child,
          ),
          child: SafeArea(
            child: _showPinEntry ? _buildPinEntry() : _buildAlarmView(),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmView() {
    return Column(
      children: [
        const Spacer(),
        AnimatedBuilder(
          animation: _flashController,
          builder: (ctx, _) => Transform.scale(
            scale: 1.0 + _flashController.value * 0.12,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentRed.withOpacity(0.12),
                border: Border.all(
                  color: AppTheme.accentRed
                      .withOpacity(0.3 + _flashController.value * 0.5),
                  width: 2,
                ),
              ),
              child: const Center(child: Text('🚨', style: TextStyle(fontSize: 64))),
            ),
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
        const SizedBox(height: 32),
        Text(
          'ALARM!',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 56, fontWeight: FontWeight.w900,
              color: AppTheme.accentRed, letterSpacing: 4),
        ).animate().fadeIn().shake(duration: 600.ms, hz: 4),
        const SizedBox(height: 8),
        Text(
          'UNAUTHORIZED ACCESS DETECTED',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary, letterSpacing: 2),
        ).animate().fadeIn(delay: 200.ms),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showPinEntry = true),
                child: Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.accentRed.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_open_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text('Enter PIN to Stop',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 18, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ).animate().slideY(begin: 1, end: 0, duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 12),
              if (_controller.settings.biometricEnabled)
                GestureDetector(
                  onTap: _tryBiometric,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColorBright)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fingerprint_rounded,
                            color: AppTheme.textSecondary, size: 22),
                        const SizedBox(width: 10),
                        Text('Use Biometrics',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 16, fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 1, end: 0, duration: 400.ms, delay: 300.ms),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildPinEntry() {
    return Column(
      children: [
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () => setState(() {
            _showPinEntry = false;
            _errorMessage = null;
            _isProcessing = false;
          }),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: AppTheme.textSecondary, size: 20),
          ),
        ),
        const Spacer(),
        const Text('🔐', style: TextStyle(fontSize: 48))
            .animate()
            .scale(duration: 300.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        Text(
          'Enter PIN',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 32, fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: _errorMessage != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            _errorMessage ?? '',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 14, color: AppTheme.accentRed,
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 32),
        // KEY FIX: use a ValueKey tied to _failedAttempts so widget
        // fully rebuilds on each wrong attempt, resetting its internal state
        PinEntryWidget(
          key: ValueKey('pin_$_failedAttempts'),
          onPinComplete: _onPinEntered,
          showForgotPin: false,
          isError: _errorMessage != null,
        ),
        const Spacer(),
      ],
    );
  }
}
