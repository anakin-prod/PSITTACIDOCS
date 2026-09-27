import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/format.dart';
import '../theme/app_theme.dart';

/// Une part d'un graphique en anneau.
class ChartSlice {
  final String label;
  final double value;
  final Color color;
  const ChartSlice(this.label, this.value, this.color);
}

/// Graphique en anneau animé (les parts se dessinent en tournant), avec une
/// valeur au centre et une légende.
class DonutChart extends StatelessWidget {
  final List<ChartSlice> slices;
  final String centerValue;
  final String centerLabel;
  final double size;

  const DonutChart({
    super.key,
    required this.slices,
    required this.centerValue,
    required this.centerLabel,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: Size(size, size), painter: _DonutPainter(slices, total, t)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(centerValue, style: GoogleFonts.lora(fontSize: size * 0.2, fontWeight: FontWeight.w600, color: AppColors.navy, height: 1.1)),
                    Text(centerLabel, style: const TextStyle(fontSize: 11, color: AppColors.mute), textAlign: TextAlign.center),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s.label, style: const TextStyle(fontSize: 12.5, color: AppColors.navy))),
                      Text(
                        formatNumber(s.value),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<ChartSlice> slices;
  final double total;
  final double progress;
  _DonutPainter(this.slices, this.total, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.14;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = AppColors.neutralBg
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (total <= 0) return;
    var start = -math.pi / 2;
    final visible = slices.where((s) => s.value > 0).length;
    final gap = visible > 1 ? 0.03 : 0.0;
    for (final s in slices) {
      if (s.value <= 0) continue;
      final sweep = 2 * math.pi * (s.value / total) * progress;
      final drawn = (sweep - gap).clamp(0.0, 2 * math.pi).toDouble();
      canvas.drawArc(
        rect,
        start,
        drawn,
        false,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.progress != progress || old.total != total;
}

/// Une barre d'un graphique en barres horizontales.
class BarItem {
  final String label;
  final double value;
  final Color? color;
  final bool highlight;
  const BarItem(this.label, this.value, {this.color, this.highlight = false});
}

/// Barres horizontales animées : libellé, barre, valeur. Une barre peut être
/// mise en avant (par exemple les perroquets parmi d'autres groupes).
class HBarChart extends StatelessWidget {
  final List<BarItem> items;
  final String unit;
  final double? maxValue;

  const HBarChart({super.key, required this.items, this.unit = '', this.maxValue});

  @override
  Widget build(BuildContext context) {
    final max = maxValue ?? items.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  child: Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.navy,
                      fontWeight: items[i].highlight ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: max <= 0 ? 0.0 : (items[i].value / max).clamp(0.0, 1.0).toDouble()),
                    duration: Duration(milliseconds: 700 + 90 * i),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Container(
                      height: 14,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(color: AppColors.neutralBg, borderRadius: BorderRadius.circular(999)),
                      child: FractionallySizedBox(
                        widthFactor: v,
                        heightFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: items[i].color ?? (items[i].highlight ? AppColors.bronze : const Color(0xFF9AA4C8)),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 52,
                  child: Text(
                    '${formatNumber(items[i].value)}${unit.isEmpty ? '' : ' $unit'}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: items[i].highlight ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
