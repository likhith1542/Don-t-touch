import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/protection_controller.dart';
import '../utils/app_theme.dart';
import '../widgets/status_orb.dart';
import '../widgets/motion_wave_painter.dart';
import 'alarm_screen.dart';
import 'settings_screen.dart';
import 'intruder_logs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _controller = ProtectionController();
  late AnimationController _pulseController;
  late AnimationController _waveController;

  List<double> _motionHistory = List.filled(30, 0.0);
  StreamSubscription<double>? _motionSub;

  // FIX: prevent double-navigation to AlarmScreen
  bool _alarmNavigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _controller.addListener(_onStateChange);
    _motionSub = _controller.motionStream.listen(_onMotion);
  }

  void _onStateChange() {
    if (!mounted) return;
    setState(() {});
    if (_controller.status == ProtectionStatus.triggered && !_alarmNavigated) {
      _alarmNavigated = true;
      _navigateToAlarm();
    }
    if (_controller.status == ProtectionStatus.idle) {
      _alarmNavigated = false;
    }
  }

  void _onMotion(double value) {
    if (!mounted) return;
    setState(() {
      _motionHistory = [..._motionHistory.skip(1), value.clamp(0, 30).toDouble()];
    });
  }

  Future<void> _navigateToAlarm() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, b) => const AlarmScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _motionSub?.cancel();
    _controller.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildBody()),
                _buildBottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final status = _controller.status;
    Color glowColor;
    switch (status) {
      case ProtectionStatus.protected:
        glowColor = AppTheme.accentGreen;
        break;
      case ProtectionStatus.triggered:
        glowColor = AppTheme.accentRed;
        break;
      case ProtectionStatus.arming:
        glowColor = AppTheme.accentOrange;
        break;
      default:
        glowColor = AppTheme.accentBlue;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.8,
          colors: [glowColor.withOpacity(0.06), AppTheme.bgPrimary],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Don't Touch",
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5),
              ),
              Text(
                'My Phone',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentRed,
                    letterSpacing: -0.5),
              ),
            ],
          ),
          Row(
            children: [
              _NavIconButton(
                icon: Icons.history_rounded,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const IntruderLogsScreen())),
              ),
              const SizedBox(width: 8),
              _NavIconButton(
                icon: Icons.settings_rounded,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildStatusOrb(),
          const SizedBox(height: 32),
          _buildStatusLabel(),
          const SizedBox(height: 40),
          _buildMainButton(),
          const SizedBox(height: 32),
          _buildMotionGraph(),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusOrb() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => StatusOrb(
        status: _controller.status,
        pulseValue: _pulseController.value,
        countdownSeconds: _controller.countdownSeconds,
      ),
    );
  }

  Widget _buildStatusLabel() {
    String label;
    String sublabel;
    Color color;

    switch (_controller.status) {
      case ProtectionStatus.protected:
        label = '🟢 PROTECTED';
        sublabel = 'Phone is secured • Monitoring active';
        color = AppTheme.accentGreen;
        break;
      case ProtectionStatus.triggered:
        label = '🔴 ALARM TRIGGERED';
        sublabel = 'Unauthorized access detected!';
        color = AppTheme.accentRed;
        break;
      case ProtectionStatus.arming:
        label = '⏳ ARMING...';
        sublabel = 'Put down your phone and step away';
        color = AppTheme.accentOrange;
        break;
      default:
        label = '⚪ UNPROTECTED';
        sublabel = 'Tap to enable protection';
        color = AppTheme.textSecondary;
    }

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.5),
        ).animate(key: ValueKey(_controller.status)).fadeIn().scale(
            begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
        const SizedBox(height: 6),
        Text(
          sublabel,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMainButton() {
    final status = _controller.status;
    final isIdle = status == ProtectionStatus.idle;
    final isArming = status == ProtectionStatus.arming;

    if (isArming) {
      return _ArmingButton(
        countdown: _controller.countdownSeconds,
        onCancel: _controller.cancelArming,
      );
    }

    return GestureDetector(
      onTap: isIdle ? _controller.startProtection : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: 72,
        decoration: BoxDecoration(
          gradient: isIdle
              ? const LinearGradient(
                  colors: [AppTheme.accentRed, Color(0xFFFF6B8A)])
              : LinearGradient(colors: [
                  AppTheme.accentGreen.withOpacity(0.2),
                  AppTheme.accentGreen.withOpacity(0.1)
                ]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isIdle
                ? Colors.transparent
                : AppTheme.accentGreen.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: isIdle
              ? [
                  BoxShadow(
                      color: AppTheme.accentRed.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIdle ? Icons.shield_rounded : Icons.shield_outlined,
              color: isIdle ? Colors.white : AppTheme.accentGreen,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              isIdle ? 'Start Protection' : 'Protection Active',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isIdle ? Colors.white : AppTheme.accentGreen,
                  letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotionGraph() {
    if (_controller.status == ProtectionStatus.idle) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Motion Activity',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: CustomPaint(
              painter: MotionWavePainter(
                data: _motionHistory,
                color: _controller.status == ProtectionStatus.protected
                    ? AppTheme.accentGreen
                    : AppTheme.accentRed,
                threshold: _controller.settings.sensitivityThreshold,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildQuickStats() {
    final logs = _controller.intruderLogs;
    final now = DateTime.now();
    final todayLogs = logs.where((l) =>
        l.timestamp.day == now.day &&
        l.timestamp.month == now.month &&
        l.timestamp.year == now.year).length;

    return Row(
      children: [
        Expanded(
            child: _StatCard(
                icon: '🚨',
                value: todayLogs.toString(),
                label: "Today's Alerts",
                color: AppTheme.accentRed)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                icon: '📊',
                value: logs.length.toString(),
                label: 'Total Logs',
                color: AppTheme.accentBlue)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                icon: '🎚️',
                value: _controller.settings.sensitivity.capitalize(),
                label: 'Sensitivity',
                color: AppTheme.accentOrange)),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(icon: Icons.home_rounded, label: 'Home', isActive: true, onTap: () {}),
          _BottomNavItem(
              icon: Icons.history_rounded,
              label: 'Logs',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const IntruderLogsScreen()))),
          _BottomNavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor)),
        child: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }
}

class _ArmingButton extends StatelessWidget {
  final int countdown;
  final VoidCallback onCancel;
  const _ArmingButton({required this.countdown, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: AppTheme.accentOrange.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$countdown',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accentOrange)),
          const SizedBox(width: 12),
          Text('Arming...',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentOrange)),
          const Spacer(),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('Cancel',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5)),
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: AppTheme.textTertiary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _BottomNavItem(
      {required this.icon,
      required this.label,
      this.isActive = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isActive ? AppTheme.accentRed : AppTheme.textTertiary,
              size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: isActive ? AppTheme.accentRed : AppTheme.textTertiary,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}
