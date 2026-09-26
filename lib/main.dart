import 'package:flutter/material.dart';

import 'screens/agenda_screen.dart';
import 'screens/birds_screen.dart';
import 'screens/couples_screen.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/notifications_screen.dart';
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

  static const _titles = [
    'Tableau de bord',
    'Mes oiseaux',
    'Couples et reproduction',
    'Agenda',
    'Plus',
  ];

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
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/icon.png',
                width: 36,
                height: 36,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Psittacidocs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  _titles[_tab],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.bronzeDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NotificationsScreen(appState: appState),
                  ),
                ),
              ),
              if (appState.unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appState.unreadCount > 9 ? '9+' : '${appState.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flutter_dash),
            label: 'Oiseaux',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Couples',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_rounded),
            label: 'Plus',
          ),
        ],
      ),
    );
  }
}
