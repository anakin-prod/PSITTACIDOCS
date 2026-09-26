import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/agenda_screen.dart';
import 'screens/birds_screen.dart';
import 'screens/couples_screen.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/splash_view.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/app_frame.dart';

void main() {
  runApp(const PsittacidocsApp());
}

class PsittacidocsApp extends StatefulWidget {
  const PsittacidocsApp({super.key});

  @override
  State<PsittacidocsApp> createState() => _PsittacidocsAppState();
}

class _PsittacidocsAppState extends State<PsittacidocsApp> {
  final AppState appState = AppState();

  /// Durée minimale d'affichage du logo à l'ouverture.
  static const _minSplash = Duration(milliseconds: 1800);
  bool _splashTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    appState.load();
    Future.delayed(_minSplash, () {
      if (mounted) setState(() => _splashTimeElapsed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Psittacidocs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Fin cadre bleu nuit autour de tous les écrans, comme dans l'aperçu.
      builder: (context, child) => AppFrame(child: child ?? const SizedBox.shrink()),
      home: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final ready = appState.loaded && _splashTimeElapsed;
          // Fondu entre l'écran du logo et l'appli.
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: ready
                ? HomeShell(key: const ValueKey('home'), appState: appState)
                : const SplashView(key: ValueKey('splash')),
          );
        },
      ),
    );
  }
}

/// La coquille principale : en-tête avec le logo et la cloche de
/// notifications, contenu de l'onglet actif, et la barre de navigation du
/// bas à 5 onglets.
class HomeShell extends StatefulWidget {
  final AppState appState;
  const HomeShell({super.key, required this.appState});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _select(int i) {
    if (i != _tab) HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final screens = [
      HomeScreen(appState: appState),
      BirdsScreen(appState: appState),
      CouplesScreen(appState: appState),
      AgendaScreen(appState: appState),
      MoreScreen(appState: appState),
    ];

    return Scaffold(
      // Le contenu défile sous le menu flottant.
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _tab, children: screens),
      ),
      bottomNavigationBar: FloatingNavBar(current: _tab, onSelect: _select),
    );
  }
}

/// Menu du bas flottant : une barre bleu nuit arrondie ; l'onglet actif
/// affiche son nom dans une pastille bronze, les autres leur seule icône.
class FloatingNavBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;
  const FloatingNavBar({super.key, required this.current, required this.onSelect});

  static const _labels = ['Accueil', 'Oiseaux', 'Couples', 'Agenda', 'Plus'];

  Widget _icon(int i, Color color) {
    switch (i) {
      case 0:
        return Icon(Icons.grid_view_rounded, color: color, size: 22);
      case 1:
        return ImageIcon(const AssetImage('assets/images/nav_parrot.png'), color: color, size: 24);
      case 2:
        return Icon(Icons.favorite_border_rounded, color: color, size: 22);
      case 3:
        return Icon(Icons.calendar_today_outlined, color: color, size: 21);
      default:
        return Icon(Icons.menu_rounded, color: color, size: 23);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppDecor.shadowStrong,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < _labels.length; i++)
              Semantics(
                button: true,
                selected: i == current,
                label: _labels[i],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    height: 46,
                    padding: EdgeInsets.symmetric(horizontal: i == current ? 16 : 12),
                    decoration: BoxDecoration(
                      color: i == current ? AppColors.bronze.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _icon(i, i == current ? AppColors.bronzeOnNavy : AppColors.navInactive),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          child: i == current
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    _labels[i],
                                    style: const TextStyle(
                                      color: AppColors.bronzeOnNavy,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
