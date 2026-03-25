import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/protection_controller.dart';
import '../utils/app_theme.dart';

class StatusOrb extends StatelessWidget {
  final ProtectionStatus status;
  final double pulseValue;
  final int countdownSeconds;

  const StatusOrb({
    super.key,
    required this.status,
    required this.pulseValue,
    required this.countdownSeconds,
  });

  Color get _primaryColor {
    switch (status) {
      case ProtectionStatus.protected:
        return AppTheme.accentGreen;
      case ProtectionStatus.triggered:
        return AppTheme.accentRed;
      case ProtectionStatus.arming:
        return AppTheme.accentOrange;
      default:
        return AppTheme.accentBlue;
    }
  }

  String get _centerIcon {
    switch (status) {
      case ProtectionStatus.protected:
        return '🛡️';
      case ProtectionStatus.triggered:
        return '🚨';
      case ProtectionStatus.arming:
        return '⏳';
      default:
        return '🔓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _primaryColor;
    final rings = status == ProtectionStatus.idle ? 1 : 3;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rings
          for (int i = 0; i < rings; i++)
            Opacity(
              opacity: (0.08 + pulseValue * 0.12) * (1 - i * 0.25),
              child: Container(
                width: 180 + i * 30.0 + pulseValue * 20,
                height: 180 + i * 30.0 + pulseValue * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: 1.5 - i * 0.3,
                  ),
                ),
              ),
            ),

          // Main orb
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.25 + pulseValue * 0.1),
                  color.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(0.5 + pulseValue * 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2 + pulseValue * 0.15),
                  blurRadius: 40 + pulseValue * 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Inner glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.15 + pulseValue * 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Center content
          if (status == ProtectionStatus.arming)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$countdownSeconds',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accentOrange,
                    letterSpacing: -2,
                  ),
                ),
                Text(
                  'sec',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: AppTheme.accentOrange.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            Text(
              _centerIcon,
              style: const TextStyle(fontSize: 52),
            ),

          // Scan line effect when protected
          if (status == ProtectionStatus.protected)
            _ScanLine(color: color, pulseValue: pulseValue),
        ],
      ),
    );
  }
}

class _ScanLine extends StatelessWidget {
  final Color color;
  final double pulseValue;

  const _ScanLine({required this.color, required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 160,
        height: 160,
        child: CustomPaint(
          painter: _ScanLinePainter(color: color, progress: pulseValue),
        ),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final Color color;
  final double progress;

  _ScanLinePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40));

    canvas.drawRect(
      Rect.fromLTWH(0, y - 20, size.width, 40),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
