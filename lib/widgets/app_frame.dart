import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fin cadre bleu nuit autour de tout l'écran, comme dans l'aperçu de l'appli
/// (filet d'environ 1 mm, coins arrondis).
///
/// Il est dessiné par-dessus tous les écrans (voir `MaterialApp.builder` dans
/// main.dart) et ne capte aucun toucher. En bas, il se fond dans le menu de
/// navigation, lui-même bleu nuit ; sur les écrans sans menu, il ferme le cadre.
///
/// Les coins extérieurs au filet arrondi sont remplis de bleu nuit : ainsi, quel
/// que soit l'arrondi réel de l'écran du téléphone, le cadre suit le coin sans
/// laisser de trou.
class AppFrame extends StatelessWidget {
  final Widget child;
  const AppFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(child: child),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _FramePainter()),
          ),
        ),
      ],
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter();

  // 6 unités Flutter ≈ 1 mm à l'écran (1 unité = 1/160 de pouce).
  static const double stroke = 6;
  static const double radius = 40;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    final inner = RRect.fromRectAndRadius(
      outer.deflate(stroke),
      const Radius.circular(radius),
    );
    final frame = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(outer)
      ..addRRect(inner);
    canvas.drawPath(frame, Paint()..color = AppColors.navy);
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) => false;
}
