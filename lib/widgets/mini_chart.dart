import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../theme/app_theme.dart';

/// Petit graphique en courbe, avec en option une zone cible colorée
/// (par exemple la plage de température souhaitée dans l'incubateur).
class MiniLineChart extends StatelessWidget {
  final String title;
  final String unit;
  final List<double> values;
  final double? targetMin;
  final double? targetMax;

  const MiniLineChart({
    super.key,
    required this.title,
    required this.unit,
    required this.values,
    this.targetMin,
    this.targetMax,
  });

  @override
  Widget build(BuildContext context) {
    final last = values.isEmpty ? null : values.last;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: AppDecor.card(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.mute)),
              ),
              if (last != null)
                Text(
                  '${formatNumber(last)} $unit',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 70,
            width: double.infinity,
            child: values.length < 2
                ? const Center(
                    child: Text(
                      'Au moins deux relevés sont nécessaires pour tracer la courbe.',
                      style: TextStyle(fontSize: 11, color: AppColors.mute),
                      textAlign: TextAlign.center,
                    ),
                  )
                : CustomPaint(painter: _LinePainter(values, targetMin, targetMax)),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final double? targetMin;
  final double? targetMax;
  _LinePainter(this.values, this.targetMin, this.targetMax);

  @override
  void paint(Canvas canvas, Size size) {
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    if (targetMin != null && targetMin! < lo) lo = targetMin!;
    if (targetMax != null && targetMax! > hi) hi = targetMax!;
    if (hi == lo) {
      hi += 1;
      lo -= 1;
    }
    const pad = 5.0;
    double yOf(double v) => size.height - pad - (v - lo) / (hi - lo) * (size.height - 2 * pad);
    final stepX = (size.width - 2 * pad) / (values.length - 1);

    if (targetMin != null || targetMax != null) {
      final top = yOf(targetMax ?? hi);
      final bottom = yOf(targetMin ?? lo);
      canvas.drawRect(
        Rect.fromLTRB(0, top, size.width, bottom),
        Paint()..color = const Color(0x221F4BA8),
      );
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(pad + stepX * i, yOf(values[i]));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.bronze
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    final dot = Paint()..color = AppColors.navy;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(Offset(pad + stepX * i, yOf(values[i])), 2.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values || old.targetMin != targetMin || old.targetMax != targetMax;
}
