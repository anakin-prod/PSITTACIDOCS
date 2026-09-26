import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Délai d'apparition en cascade : les premiers éléments d'une liste arrivent
/// les uns après les autres ; au-delà, sans attente (pour le défilement).
Duration staggerDelay(int index, {int stepMs = 55}) =>
    index < 10 ? Duration(milliseconds: index * stepMs) : Duration.zero;

/// Enveloppe chaque élément d'une liste dans une apparition en cascade.
List<Widget> staggered(List<Widget> children) => [
  for (var i = 0; i < children.length; i++) FadeSlideIn(delay: staggerDelay(i), child: children[i]),
];

/// Apparition en fondu avec un léger glissement vers le haut.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.12),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(
      position: Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(_curve),
      child: widget.child,
    ),
  );
}

/// Nombre qui défile jusqu'à sa valeur (et se met à jour en douceur).
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: value.toDouble()),
    duration: duration,
    curve: Curves.easeOutCubic,
    builder: (context, v, _) => Text(v.round().toString(), style: style),
  );
}

/// Barre de progression qui se remplit en douceur (valeur de 0 à 1).
class AnimatedBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color background;
  final double height;

  const AnimatedBar({
    super.key,
    required this.value,
    this.color = AppColors.bronze,
    this.background = AppColors.line,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    builder: (context, v, _) => ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: v,
        minHeight: height,
        backgroundColor: background,
        color: color,
      ),
    ),
  );
}

/// Barre des étapes de reproduction : les segments se remplissent l'un après
/// l'autre jusqu'à l'étape en cours.
class StageBar extends StatelessWidget {
  final int stage; // 0 à total-1
  final int total;
  final double height;

  const StageBar({super.key, required this.stage, this.total = 6, this.height = 6});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: (stage + 1).toDouble()),
    duration: Duration(milliseconds: 250 + 150 * (stage + 1)),
    curve: Curves.easeOutCubic,
    builder: (context, t, _) => Row(
      children: List.generate(total, (i) {
        final fill = (t - i).clamp(0.0, 1.0).toDouble();
        return Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fill,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bronze,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

/// Léger enfoncement quand on appuie : rend les éléments cliquables plus
/// tactiles, sans rien changer à leur comportement.
class PressableScale extends StatefulWidget {
  final Widget child;
  const PressableScale({super.key, required this.child});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}
