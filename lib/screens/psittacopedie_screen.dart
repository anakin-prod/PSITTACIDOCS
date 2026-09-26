import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/text_search.dart';
import '../models/parrot_fact.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import 'species_detail_screen.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';

/// Petite étiquette de thème (« Anatomie », « Reproduction »…).
class _ThemeTag extends StatelessWidget {
  final String theme;
  const _ThemeTag(this.theme);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: AppColors.chipBg, borderRadius: BorderRadius.circular(999)),
    child: Text(theme, style: const TextStyle(fontSize: 11, color: AppColors.chipText)),
  );
}

/// Carte « Psittacopédie » de l'écran d'Accueil : une information sur les
/// perroquets, différente à chaque ouverture de l'appli.
class PsittacopedieCard extends StatelessWidget {
  final AppState appState;
  const PsittacopedieCard({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final fact = appState.currentFact;
    if (fact == null) return const SizedBox.shrink();
    final sp = fact.sci == null ? null : appState.speciesBySci(fact.sci!);

    return PressableScale(
      child: Container(
        decoration: AppDecor.card(radius: 22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PsittacopedieScreen(appState: appState)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(iconFor('idea'), color: AppColors.bronzeDark, size: 19),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'PSITTACOPÉDIE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: AppColors.bronzeDark),
                        ),
                      ),
                      _ThemeTag(fact.theme),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey(fact.id),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fact.text,
                          style: GoogleFonts.lora(fontSize: 16.5, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.navy),
                        ),
                        const SizedBox(height: 10),
                        Text('Source : ${fact.source}', style: const TextStyle(fontSize: 11, color: AppColors.mute)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (sp != null)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SpeciesDetailScreen(appState: appState, sci: sp.sci)),
                            ),
                            child: Text(
                              'Fiche : ${sp.label}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.bronzeDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      PressableScale(
                        child: Material(
                          color: AppColors.bronzeBg,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: appState.nextFact,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 16, color: AppColors.bronzeDark),
                                  SizedBox(width: 6),
                                  Text('Une autre', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.bronzeDark)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Toutes les informations de la Psittacopédie, par thème, avec recherche.
class PsittacopedieScreen extends StatefulWidget {
  final AppState appState;
  final String? initialQuery; // recherche pré-remplie (depuis la recherche globale)
  const PsittacopedieScreen({super.key, required this.appState, this.initialQuery});

  @override
  State<PsittacopedieScreen> createState() => _PsittacopedieScreenState();
}

class _PsittacopedieScreenState extends State<PsittacopedieScreen> {
  final _ctrl = TextEditingController();
  String _theme = 'Tous';

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialQuery ?? '';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final themes = ['Tous', ...{for (final f in appState.facts) f.theme}];
    final q = normalizeText(_ctrl.text.trim());
    final list = appState.facts.where((f) {
      if (_theme != 'Tous' && f.theme != _theme) return false;
      if (q.isEmpty) return true;
      final sp = f.sci == null ? null : appState.speciesBySci(f.sci!);
      return matchesAny(q, [f.text, f.theme, sp?.label]);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Psittacopédie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: staggered([
          TextField(
            controller: _ctrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Rechercher (ex. kakapo, nid, CITES…)',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: themes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => PillChoice(
                label: Text(themes[i]),
                selected: _theme == themes[i],
                onSelected: (_) => setState(() => _theme = themes[i]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${list.length} information${list.length > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.mute),
          ),
          const SizedBox(height: 8),
          for (final f in list) _FactTile(appState: appState, fact: f),
        ]),
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  final AppState appState;
  final ParrotFact fact;
  const _FactTile({required this.appState, required this.fact});

  @override
  Widget build(BuildContext context) {
    final sp = fact.sci == null ? null : appState.speciesBySci(fact.sci!);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThemeTag(fact.theme),
          const SizedBox(height: 8),
          Text(fact.text, style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 8),
          Text('Source : ${fact.source}', style: const TextStyle(fontSize: 11, color: AppColors.mute)),
          if (sp != null)
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SpeciesDetailScreen(appState: appState, sci: sp.sci)),
              ),
              child: Text('Fiche : ${sp.label}'),
            ),
        ],
      ),
    );
  }
}
