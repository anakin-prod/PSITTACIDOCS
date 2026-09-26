import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../theme/app_theme.dart';

const Color kCold = Color(0xFF2F80ED);
const Color kMild = Color(0xFF27AE60);
const Color kHot = Color(0xFFD7141F);

/// Couleur d'une température ambiante : bleu (froid) → vert (tempéré) → rouge
/// (chaud). Indication visuelle générale, pas une consigne d'élevage.
Color ambientTemperatureColor(double t) {
  if (t <= 10) return kCold;
  if (t < 22) return Color.lerp(kCold, kMild, (t - 10) / 12)!;
  if (t < 32) return Color.lerp(kMild, kHot, (t - 22) / 10)!;
  return kHot;
}

/// Couleur par rapport à une consigne : bleu en dessous, rouge au-dessus,
/// vert dans la plage. Sans consigne : bronze neutre.
Color targetColor(double v, double? min, double? max) {
  if (min == null && max == null) return AppColors.bronze;
  if (min != null && v < min) return kCold;
  if (max != null && v > max) return kHot;
  return kMild;
}

/// Thermomètre animé : le mercure monte jusqu'à la valeur et prend sa couleur.
class ThermometerGauge extends StatelessWidget {
  final double? value;
  final double min;
  final double max;
  final Color Function(double) colorFor;
  final String label;

  const ThermometerGauge({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 40,
    this.colorFor = ambientTemperatureColor,
    this.label = 'Température',
  });

  @override
  Widget build(BuildContext context) {
    final target = (value ?? min).clamp(min, max).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: min, end: target),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final color = value == null ? AppColors.line : colorFor(v);
        return _GaugeFrame(
          label: label,
          valueText: value == null ? '—' : '${formatNumber(value!)} °C',
          color: value == null ? AppColors.mute : color,
          child: CustomPaint(
            painter: _ThermoPainter(fraction: (v - min) / (max - min), color: color),
          ),
        );
      },
    );
  }
}

class _ThermoPainter extends CustomPainter {
  final double fraction;
  final Color color;
  _ThermoPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bulbR = size.width * 0.28;
    final tubeW = bulbR * 0.9;
    final bulbC = Offset(cx, size.height - bulbR - 2);
    final tubeTop = 4.0;
    final tubeBottom = bulbC.dy;
    final tube = RRect.fromLTRBR(cx - tubeW / 2, tubeTop, cx + tubeW / 2, tubeBottom, Radius.circular(tubeW / 2));

    final glass = Paint()..color = const Color(0xFFF6EEEC);
    canvas.drawRRect(tube, glass);
    canvas.drawCircle(bulbC, bulbR, glass);

    // Mercure
    final fill = Paint()..color = color;
    final innerW = tubeW * 0.55;
    final level = tubeBottom - (tubeBottom - tubeTop - innerW) * fraction.clamp(0.0, 1.0).toDouble();
    canvas.drawRRect(
      RRect.fromLTRBR(cx - innerW / 2, level, cx + innerW / 2, tubeBottom, Radius.circular(innerW / 2)),
      fill,
    );
    canvas.drawCircle(bulbC, bulbR * 0.72, fill);

    // Graduations
    final tick = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 1; i < 8; i++) {
      final y = tubeTop + (tubeBottom - tubeTop) * i / 8;
      canvas.drawLine(Offset(cx + tubeW / 2 + 3, y), Offset(cx + tubeW / 2 + 8, y), tick);
    }

    final outline = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(tube, outline);
    canvas.drawCircle(bulbC, bulbR, outline);
  }

  @override
  bool shouldRepaint(covariant _ThermoPainter old) => old.fraction != fraction || old.color != color;
}

/// Goutte qui se remplit selon l'humidité relative (0 à 100 %).
class HumidityGauge extends StatelessWidget {
  final double? value;
  final Color Function(double)? colorFor;
  final String label;

  const HumidityGauge({super.key, required this.value, this.colorFor, this.label = 'Humidité'});

  @override
  Widget build(BuildContext context) {
    final target = (value ?? 0).clamp(0.0, 100.0).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final color = colorFor == null ? const Color(0xFF2F80ED) : colorFor!(v);
        return _GaugeFrame(
          label: label,
          valueText: value == null ? '—' : '${formatNumber(value!)} %',
          color: value == null ? AppColors.mute : color,
          child: CustomPaint(painter: _DropPainter(fraction: v / 100, color: color)),
        );
      },
    );
  }
}

class _DropPainter extends CustomPainter {
  final double fraction;
  final Color color;
  _DropPainter({required this.fraction, required this.color});

  Path _drop(Size s) {
    final w = s.width * 0.78;
    final h = s.height * 0.92;
    final left = (s.width - w) / 2;
    final top = (s.height - h) / 2;
    return Path()
      ..moveTo(left + w / 2, top)
      ..cubicTo(left + w * 0.62, top + h * 0.22, left + w, top + h * 0.45, left + w, top + h * 0.66)
      ..cubicTo(left + w, top + h * 0.88, left + w * 0.78, top + h, left + w / 2, top + h)
      ..cubicTo(left + w * 0.22, top + h, left, top + h * 0.88, left, top + h * 0.66)
      ..cubicTo(left, top + h * 0.45, left + w * 0.38, top + h * 0.22, left + w / 2, top)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final drop = _drop(size);
    canvas.drawPath(drop, Paint()..color = const Color(0xFFEAF2FD));
    canvas.save();
    canvas.clipPath(drop);
    final level = size.height * (1 - fraction.clamp(0.0, 1.0).toDouble());
    // Petite vague à la surface
    final wave = Path()..moveTo(0, level);
    for (var x = 0.0; x <= size.width; x += 2) {
      wave.lineTo(x, level + math.sin(x / size.width * 2 * math.pi) * 2);
    }
    wave
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wave, Paint()..color = color.withValues(alpha: 0.85));
    canvas.restore();
    canvas.drawPath(
      drop,
      Paint()
        ..color = AppColors.navy.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _DropPainter old) => old.fraction != fraction || old.color != color;
}

/// Soleil dont l'arc se remplit selon la durée d'éclairage (0 à 24 h).
class LightGauge extends StatelessWidget {
  final double? hours;
  const LightGauge({super.key, required this.hours});

  @override
  Widget build(BuildContext context) {
    final target = (hours ?? 0).clamp(0.0, 24.0).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => _GaugeFrame(
        label: 'Éclairage',
        valueText: hours == null ? '—' : '${formatNumber(hours!)} h',
        color: hours == null ? AppColors.mute : const Color(0xFFE0A100),
        child: CustomPaint(painter: _SunPainter(fraction: v / 24)),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  final double fraction;
  _SunPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 4;
    final track = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);
    final arc = Paint()
      ..color = const Color(0xFFE0A100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * fraction.clamp(0.0, 1.0).toDouble(), false, arc);
    // Soleil au centre, rayons proportionnels à l'éclairage
    final sun = Paint()..color = Color.lerp(const Color(0xFFF3E3B0), const Color(0xFFE0A100), fraction.clamp(0.0, 1.0).toDouble())!;
    canvas.drawCircle(c, r * 0.32, sun);
    final ray = Paint()
      ..color = sun.color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rays = (fraction * 12).round().clamp(0, 12);
    for (var i = 0; i < rays; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 12;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r * 0.45),
        c + Offset(math.cos(a), math.sin(a)) * (r * 0.62),
        ray,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SunPainter old) => old.fraction != fraction;
}

/// Cadre commun des jauges : dessin, valeur en couleur, libellé.
class _GaugeFrame extends StatelessWidget {
  final Widget child;
  final String label;
  final String valueText;
  final Color color;

  const _GaugeFrame({required this.child, required this.label, required this.valueText, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(width: 56, height: 80, child: child),
      const SizedBox(height: 6),
      Text(valueText, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mute)),
    ],
  );
}
