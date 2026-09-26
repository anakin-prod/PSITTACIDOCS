import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/parrot_fact.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import 'species_detail_screen.dart';

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconFor('idea'), color: AppColors.bronze, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Psittacopédie',
                  style: GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.navy),
                ),
              ),
              _ThemeTag(fact.theme),
            ],
          ),
          const SizedBox(height: 10),
          Text(fact.text, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.navy)),
          const SizedBox(height: 8),
          Text('Source : ${fact.source}', style: const TextStyle(fontSize: 11, color: AppColors.mute)),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Une autre'),
                onPressed: appState.nextFact,
              ),
              if (sp != null)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SpeciesDetailScreen(appState: appState, sci: sp.sci)),
                  ),
                  child: Text('Fiche : ${sp.label}'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PsittacopedieScreen(appState: appState)),
                ),
                child: const Text('Tout voir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Toutes les informations de la Psittacopédie, par thème, avec recherche.
class PsittacopedieScreen extends StatefulWidget {
  final AppState appState;
  const PsittacopedieScreen({super.key, required this.appState});

  @override
  State<PsittacopedieScreen> createState() => _PsittacopedieScreenState();
}

class _PsittacopedieScreenState extends State<PsittacopedieScreen> {
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
      appBar: AppBar(title: const Text('Psittacopédie')),
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
          for (final f in list) _FactTile(appState: appState, fact: f),
        ],
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
              child: Text('Fiche : ${sp.label}'),
            ),
        ],
      ),
    );
  }
}
