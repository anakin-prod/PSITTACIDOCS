import 'dart:math';

import 'package:flutter/material.dart';

import '../models/parrot_fact.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import 'species_detail_screen.dart';

final Random _random = Random();

/// Tire une information au hasard, différente de [exceptId] si possible.
ParrotFact? randomFact(AppState appState, {String? exceptId}) {
  final pool = appState.facts.where((f) => f.id != exceptId).toList();
  if (pool.isEmpty) return appState.facts.isEmpty ? null : appState.facts.first;
  return pool[_random.nextInt(pool.length)];
}

/// Fenêtre « Le saviez-vous ? » affichée à l'ouverture de l'appli.
Future<void> showFactDialog(BuildContext context, AppState appState) async {
  var fact = randomFact(appState);
  if (fact == null) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final f = fact!;
        final sp = f.sci == null ? null : appState.speciesBySci(f.sci!);
        return AlertDialog(
          title: Row(
            children: [
              Icon(iconFor('idea'), color: AppColors.bronze),
              const SizedBox(width: 8),
              const Expanded(child: Text('Le saviez-vous ?')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ThemeTag(f.theme),
                const SizedBox(height: 10),
                Text(f.text, style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 10),
                Text('Source : ${f.source}', style: const TextStyle(fontSize: 11, color: AppColors.mute)),
                if (sp != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SpeciesDetailScreen(appState: appState, sci: sp.sci)),
                        );
                      },
                      child: Text('Voir la fiche : ${sp.label}'),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                appState.settings.showFactOnLaunch = false;
                appState.saveSettings();
                Navigator.pop(ctx);
              },
              child: const Text('Ne plus afficher'),
            ),
            TextButton(
              onPressed: () => setDialogState(() => fact = randomFact(appState, exceptId: f.id)),
              child: const Text('Une autre'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          ],
        );
      },
    ),
  );
}

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

/// Toutes les informations « Le saviez-vous ? », par thème, avec recherche.
class FactsScreen extends StatefulWidget {
  final AppState appState;
  const FactsScreen({super.key, required this.appState});

  @override
  State<FactsScreen> createState() => _FactsScreenState();
}

class _FactsScreenState extends State<FactsScreen> {
  final _ctrl = TextEditingController();
  String _theme = 'Tous';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final themes = ['Tous', ...{for (final f in appState.facts) f.theme}];
    final q = _ctrl.text.trim().toLowerCase();
    final list = appState.facts.where((f) {
      if (_theme != 'Tous' && f.theme != _theme) return false;
      if (q.isEmpty) return true;
      final sp = f.sci == null ? null : appState.speciesBySci(f.sci!);
      return f.text.toLowerCase().contains(q) || (sp?.label.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Le saviez-vous ?')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              itemBuilder: (context, i) => ChoiceChip(
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
          for (final f in list) _FactCard(appState: appState, fact: f),
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  final AppState appState;
  final ParrotFact fact;
  const _FactCard({required this.appState, required this.fact});

  @override
  Widget build(BuildContext context) {
    final sp = fact.sci == null ? null : appState.speciesBySci(fact.sci!);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
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
              child: Text('Voir la fiche : ${sp.label}'),
            ),
        ],
      ),
    );
  }
}
