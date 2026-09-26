import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Écran d'ouverture : logo en grand sur fond bleu nuit.
///
/// Il prend le relais de l'écran natif d'Android (même fond, même perroquet,
/// même taille, même position : aucune saute visible), puis le perroquet
/// grossit doucement et le nom apparaît en dessous.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  /// Taille du perroquet sur l'écran natif (image 768 px en densité 4x).
  static const double nativeSize = 192;

  /// Agrandissement final du logo.
  static const double endScale = 1.35;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _scale = Tween<double>(begin: 1.0, end: SplashView.endScale).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)),
    );
    _textOpacity = CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: LayoutBuilder(
          builder: (context, box) {
            // Le texte se place sous le logo une fois agrandi.
            final logoHalf = SplashView.nativeSize * SplashView.endScale / 2;
            final textTop = box.maxHeight / 2 + logoHalf + 20;
            return Stack(
              children: [
                Center(
                  child: ScaleTransition(
                    scale: _scale,
                    child: Image.asset(
                      'assets/images/splash_parrot.png',
                      width: SplashView.nativeSize,
                      height: SplashView.nativeSize,
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: textTop,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        Text(
                          'Psittacidocs',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lora(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(width: 64, height: 2, color: AppColors.bronze),
                        const SizedBox(height: 12),
                        Text(
                          'Gestion d’élevage de psittacidés',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.bronze, letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
