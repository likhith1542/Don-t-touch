import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/alarm_service.dart';
import '../utils/app_theme.dart';

class PinEntryWidget extends StatefulWidget {
  final Function(String) onPinComplete;
  final bool showForgotPin;
  final bool isError;
  final int pinLength;

  const PinEntryWidget({
    super.key,
    required this.onPinComplete,
    this.showForgotPin = false,
    this.isError = false,
    this.pinLength = 4,
  });

  @override
  State<PinEntryWidget> createState() => _PinEntryWidgetState();
}

class _PinEntryWidgetState extends State<PinEntryWidget>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _submitted = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final _sfx = AlarmService();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(PinEntryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isError && !oldWidget.isError) {
      _triggerShake();
    }
  }

  void _triggerShake() async {
    _sfx.playError();
    _pin = '';
    _submitted = false;
    setState(() {});
    await _shakeController.forward();
    _shakeController.reset();
  }

  void _onKeyTap(String key) {
    if (key == '⌫') {
      if (_pin.isNotEmpty) {
        _sfx.playKeyTap();
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }

    if (_submitted || _pin.length >= widget.pinLength) return;

    _sfx.playKeyTap();
    setState(() => _pin += key);

    if (_pin.length == widget.pinLength) {
      _submitted = true;
      final entered = _pin;
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        setState(() {
          _pin = '';
          _submitted = false;
        });
        widget.onPinComplete(entered);
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PIN dots with shake
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final shake = _shakeAnimation.value;
            return Transform.translate(
              offset: Offset(shake > 0 ? 8 * (1 - shake * 2).clamp(-1.0, 1.0) : 0, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pinLength, (i) {
              final filled = i < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isError
                      ? AppTheme.accentRed
                      : filled
                          ? AppTheme.accentRed
                          : Colors.transparent,
                  border: Border.all(
                    color: widget.isError
                        ? AppTheme.accentRed
                        : filled
                            ? AppTheme.accentRed
                            : AppTheme.borderColorBright,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 40),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              _buildRow(['1', '2', '3']),
              const SizedBox(height: 12),
              _buildRow(['4', '5', '6']),
              const SizedBox(height: 12),
              _buildRow(['7', '8', '9']),
              const SizedBox(height: 12),
              _buildRow(['', '0', '⌫']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        final isEmpty = key.isEmpty;
        return Expanded(
          child: isEmpty
              ? const SizedBox()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => _onKeyTap(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      height: 68,
                      decoration: BoxDecoration(
                        color: key == '⌫' ? AppTheme.bgCard : AppTheme.bgCardAlt,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Center(
                        child: key == '⌫'
                            ? const Icon(Icons.backspace_outlined,
                                color: AppTheme.textSecondary, size: 22)
                            : Text(
                                key,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
        );
      }).toList(),
    );
  }
}
