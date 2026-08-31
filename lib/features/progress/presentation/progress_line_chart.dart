import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/gymrat_colors.dart';
import '../domain/training_analytics.dart';

class ProgressLineChart extends StatelessWidget {
  const ProgressLineChart({
    super.key,
    required this.points,
    this.color = GymRatColors.green,
    this.height = 170,
    this.semanticLabel,
  });

  final List<TrainingPoint> points;
  final Color color;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: true,
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _ProgressLinePainter(points, color)),
    ),
  );
}

class _ProgressLinePainter extends CustomPainter {
  const _ProgressLinePainter(this.points, this.color);

  final List<TrainingPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 12.0;
    final chart = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    final grid = Paint()
      ..color = GymRatColors.border.withValues(alpha: .65)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chart.top + chart.height * i / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }
    if (points.isEmpty) return;

    final values = points.map((point) => point.value);
    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    if (minValue == maxValue) {
      minValue = math.max(0, minValue * .92);
      maxValue = maxValue == 0 ? 1 : maxValue * 1.08;
    }
    final path = Path();
    final offsets = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? chart.center.dx
          : chart.left + chart.width * index / (points.length - 1);
      final normalized =
          (points[index].value - minValue) / (maxValue - minValue);
      final point = Offset(x, chart.bottom - chart.height * normalized);
      offsets.add(point);
      index == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }

    if (offsets.length > 1) {
      final fill = Path.from(path)
        ..lineTo(offsets.last.dx, chart.bottom)
        ..lineTo(offsets.first.dx, chart.bottom)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: .28), color.withValues(alpha: 0)],
          ).createShader(chart),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final point in offsets) {
      canvas.drawCircle(point, 4.5, Paint()..color = GymRatColors.black);
      canvas.drawCircle(
        point,
        3.2,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressLinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
