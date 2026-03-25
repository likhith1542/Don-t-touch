import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/intruder_log.dart';
import '../services/protection_controller.dart';
import '../utils/app_theme.dart';

class IntruderLogsScreen extends StatefulWidget {
  const IntruderLogsScreen({super.key});

  @override
  State<IntruderLogsScreen> createState() => _IntruderLogsScreenState();
}

class _IntruderLogsScreenState extends State<IntruderLogsScreen> {
  final _controller = ProtectionController();

  @override
  Widget build(BuildContext context) {
    final logs = _controller.intruderLogs;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Intruder Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (logs.isNotEmpty)
            TextButton(
              onPressed: _confirmClear,
              child: Text(
                'Clear All',
                style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.accentRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: logs.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: logs.length,
              itemBuilder: (ctx, i) => _LogCard(log: logs[i])
                  .animate(delay: Duration(milliseconds: i * 50))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.1, end: 0),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🕵️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No Intrusions Yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your phone is safe!\nIntruder alerts will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
          ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear All Logs?',
          style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        content: Text(
          'This will permanently delete all intruder photos and records.',
          style: GoogleFonts.spaceGrotesk(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.spaceGrotesk(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await _controller.clearLogs();
              Navigator.pop(context);
              setState(() {});
            },
            child: Text('Clear',
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.accentRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final IntruderLog log;

  const _LogCard({required this.log});

  Color get _triggerColor {
    switch (log.triggerType) {
      case 'wrong_pin':
        return AppTheme.accentOrange;
      case 'pickup':
        return AppTheme.accentBlue;
      default:
        return AppTheme.accentRed;
    }
  }

  String get _triggerEmoji {
    switch (log.triggerType) {
      case 'wrong_pin':
        return '🔑';
      case 'pickup':
        return '📱';
      default:
        return '📳';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _triggerColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _triggerColor.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(_triggerEmoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.triggerLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${log.formattedDate} at ${log.formattedTime}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _triggerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log.triggerType == 'wrong_pin'
                        ? 'PIN'
                        : log.triggerType.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _triggerColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Photo if available
          if (log.photoPath != null)
            _buildPhoto(log.photoPath!),
        ],
      ),
    );
  }

  Widget _buildPhoto(String path) {
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Could open full screen photo view
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
        child: Stack(
          children: [
            Image.file(
              file,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📸 INTRUDER',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
