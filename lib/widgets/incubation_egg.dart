import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

Path eggPath(Size s) {
  final w = s.width;
  final h = s.height;
  return Path()
    ..moveTo(w / 2, 0)
    ..cubicTo(w * 0.88, 0, w, h * 0.5, w, h * 0.64)
    ..cubicTo(w, h * 0.88, w * 0.78, h, w / 2, h)
    ..cubicTo(w * 0.22, h, 0, h * 0.88, 0, h * 0.64)
    ..cubicTo(0, h * 0.5, w * 0.12, 0, w / 2, 0)
    ..close();
}

/// Œuf d'incubation animé.
///
/// - Il se remplit d'une couleur chaude selon l'avancement de l'incubation.
/// - À l'approche de l'éclosion ([wobble]), il tremble par petites secousses.
/// - Une fois éclos ([hatched]), il apparaît fêlé.
class IncubationEgg extends StatefulWidget {
  final double progress; // 0 à 1
  final double width;
  final bool wobble;
  final bool hatched;
  final bool dimmed; // œuf non éclos d'une incubation terminée
  final bool interactive; // un toucher fait tressaillir l'œuf

  const IncubationEgg({
    super.key,
    required this.progress,
    this.width = 40,
    this.wobble = false,
    this.hatched = false,
    this.dimmed = false,
    this.interactive = false,
  });

  @override
  State<IncubationEgg> createState() => _IncubationEggState();
}

class _IncubationEggState extends State<IncubationEgg> with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    if (widget.wobble) _shake.repeat();
  }

  @override
  void didUpdateWidget(covariant IncubationEgg old) {
    super.didUpdateWidget(old);
    if (widget.wobble && !_shake.isAnimating) _shake.repeat();
    if (!widget.wobble && _shake.isAnimating) {
      _shake.stop();
      _shake.value = 0;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _poke() {
    HapticFeedback.lightImpact();
    if (!widget.wobble) _shake.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width * 1.28;
    final egg = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0).toDouble()),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (context, fill, _) => AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          // Secousse brève au début de chaque cycle, puis repos.
          final t = _shake.value;
          final envelope = t < 0.3 ? math.sin(t / 0.3 * math.pi) : 0.0;
          final shaking = widget.wobble || _shake.isAnimating;
          final angle = shaking ? math.sin(t * 2 * math.pi * 9) * 0.12 * envelope : 0.0;
          return Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: child,
          );
        },
        child: SizedBox(
          width: widget.width,
          height: height,
          child: CustomPaint(
            painter: _EggPainter(
              fill: widget.hatched ? 1.0 : fill,
              hatched: widget.hatched,
              dimmed: widget.dimmed,
            ),
          ),
        ),
      ),
    );
    if (!widget.interactive) return egg;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: _poke, child: egg);
  }
}

class _EggPainter extends CustomPainter {
  final double fill;
  final bool hatched;
  final bool dimmed;
  _EggPainter({required this.fill, required this.hatched, required this.dimmed});

  @override
  void paint(Canvas canvas, Size size) {
    final egg = eggPath(size);
    canvas.drawPath(egg, Paint()..color = dimmed ? const Color(0xFFEDEFF5) : const Color(0xFFFFF8F1));
    if (!dimmed) {
      canvas.save();
      canvas.clipPath(egg);
      final top = size.height * (1 - fill);
      final rect = Rect.fromLTRB(0, top, size.width, size.height);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFFE8963C), Color(0xFFF3C27A)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
      // Reflet
      canvas.drawOval(
        Rect.fromLTWH(size.width * 0.22, size.height * 0.16, size.width * 0.18, size.height * 0.22),
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
      canvas.restore();
    }
    canvas.drawPath(
      egg,
      Paint()
        ..color = dimmed ? AppColors.mute.withValues(alpha: 0.5) : AppColors.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, size.width * 0.045),
    );
    if (hatched) {
      final y = size.height * 0.5;
      final crack = Path()..moveTo(size.width * 0.06, y);
      const steps = 6;
      for (var i = 1; i <= steps; i++) {
        final x = size.width * (0.06 + 0.88 * i / steps);
        crack.lineTo(x, y + (i.isOdd ? -1 : 1) * size.height * 0.07);
      }
      canvas.drawPath(
        crack,
        Paint()
          ..color = AppColors.navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.4, size.width * 0.045)
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EggPainter old) =>
      old.fill != fill || old.hatched != hatched || old.dimmed != dimmed;
}

/// Rangée d'œufs : un par œuf de la couvée. Une fois l'incubation terminée,
/// les œufs éclos apparaissent fêlés, les autres grisés.
class EggRow extends StatelessWidget {
  final int eggs;
  final double progress;
  final bool finished;
  final int hatched;

  const EggRow({super.key, required this.eggs, required this.progress, this.finished = false, this.hatched = 0});

  @override
  Widget build(BuildContext context) {
    if (eggs <= 0) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < eggs; i++)
          IncubationEgg(
            width: 20,
            progress: progress,
            hatched: finished && i < hatched,
            dimmed: finished && i >= hatched,
          ),
      ],
    );
  }
}
