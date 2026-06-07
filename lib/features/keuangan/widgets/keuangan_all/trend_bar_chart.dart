import 'dart:math' as math;
import 'package:flutter/material.dart';

class TrendBarChart extends StatelessWidget {
  final List<double> values;

  const TrendBarChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: TrendBarPainter(values), child: Container());
  }
}

class TrendBarPainter extends CustomPainter {
  final List<double> values;

  TrendBarPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE5E7EB);
    final barPaint = Paint()..color = const Color(0xFF4F46E5);
    final linePaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    if (values.isEmpty) return;
    final maxValue = values.reduce(math.max);
    if (maxValue <= 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - 2, size.width, 2),
        bgPaint,
      );
      return;
    }

    final spacing = 3.0;
    final barWidth = math.max(
      2.0,
      (size.width - (values.length - 1) * spacing) / values.length,
    );

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final ratio = (value / maxValue).clamp(0, 1);
      final barHeight = size.height * ratio;
      final left = i * (barWidth + spacing);
      final top = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TrendBarPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}
