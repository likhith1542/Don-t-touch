import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class PatternLockWidget extends StatefulWidget {
  final Function(List<int>) onPatternComplete;
  final bool isSetup;

  const PatternLockWidget({
    super.key,
    required this.onPatternComplete,
    this.isSetup = false,
  });

  @override
  State<PatternLockWidget> createState() => _PatternLockWidgetState();
}

class _PatternLockWidgetState extends State<PatternLockWidget> {
  List<int> _selectedDots = [];
  Offset? _currentPosition;
  bool _isDrawing = false;

  static const int _gridSize = 3;
  static const double _dotRadius = 12.0;
  static const double _hitRadius = 30.0;

  List<Offset> _getDotPositions(Size size) {
    final List<Offset> positions = [];
    final cellW = size.width / _gridSize;
    final cellH = size.height / _gridSize;
    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        positions.add(Offset(
          cellW * col + cellW / 2,
          cellH * row + cellH / 2,
        ));
      }
    }
    return positions;
  }

  int? _hitTest(Offset position, List<Offset> dotPositions) {
    for (int i = 0; i < dotPositions.length; i++) {
      if (!_selectedDots.contains(i)) {
        final dist = (position - dotPositions[i]).distance;
        if (dist < _hitRadius) return i;
      }
    }
    return null;
  }

  void _onPanStart(DragStartDetails details, List<Offset> dotPositions) {
    setState(() {
      _selectedDots = [];
      _isDrawing = true;
      _currentPosition = details.localPosition;
    });

    final hit = _hitTest(details.localPosition, dotPositions);
    if (hit != null) {
      setState(() => _selectedDots.add(hit));
    }
  }

  void _onPanUpdate(DragUpdateDetails details, List<Offset> dotPositions) {
    setState(() => _currentPosition = details.localPosition);

    final hit = _hitTest(details.localPosition, dotPositions);
    if (hit != null && !_selectedDots.contains(hit)) {
      setState(() => _selectedDots.add(hit));
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDrawing = false;
      _currentPosition = null;
    });

    if (_selectedDots.length >= 4) {
      widget.onPatternComplete(List.from(_selectedDots));
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _selectedDots = []);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final dotPositions = _getDotPositions(size);

        return GestureDetector(
          onPanStart: (d) => _onPanStart(d, dotPositions),
          onPanUpdate: (d) => _onPanUpdate(d, dotPositions),
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            painter: _PatternPainter(
              dotPositions: dotPositions,
              selectedDots: _selectedDots,
              currentPosition: _currentPosition,
              isDrawing: _isDrawing,
            ),
            size: size,
          ),
        );
      }),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<Offset> dotPositions;
  final List<int> selectedDots;
  final Offset? currentPosition;
  final bool isDrawing;

  _PatternPainter({
    required this.dotPositions,
    required this.selectedDots,
    this.currentPosition,
    required this.isDrawing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw lines between selected dots
    if (selectedDots.length > 1) {
      final linePaint = Paint()
        ..color = AppTheme.accentRed.withOpacity(0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < selectedDots.length - 1; i++) {
        canvas.drawLine(
          dotPositions[selectedDots[i]],
          dotPositions[selectedDots[i + 1]],
          linePaint,
        );
      }

      // Draw to current position if drawing
      if (isDrawing && currentPosition != null && selectedDots.isNotEmpty) {
        canvas.drawLine(
          dotPositions[selectedDots.last],
          currentPosition!,
          linePaint,
        );
      }
    }

    // Draw dots
    for (int i = 0; i < dotPositions.length; i++) {
      final isSelected = selectedDots.contains(i);

      // Outer ring
      final ringPaint = Paint()
        ..color = isSelected
            ? AppTheme.accentRed.withOpacity(0.4)
            : AppTheme.borderColorBright.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(dotPositions[i], 22, ringPaint);

      // Inner dot
      final dotPaint = Paint()
        ..color = isSelected ? AppTheme.accentRed : AppTheme.borderColorBright
        ..style = PaintingStyle.fill;

      canvas.drawCircle(dotPositions[i], isSelected ? 10 : 7, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.selectedDots != selectedDots ||
      old.currentPosition != currentPosition ||
      old.isDrawing != isDrawing;
}
