import 'package:flutter/material.dart';

import '../logic/text_search.dart';
import '../models/agenda_event.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';
import 'couple_detail_screen.dart';
import 'incubation_detail_screen.dart';
import 'psittacopedie_screen.dart';
import 'species_detail_screen.dart';

/// Recherche dans tout le contenu de l'appli : oiseaux, couples, documents,
/// incubations, agenda, espèces et Psittacopédie.
class GlobalSearchScreen extends StatefulWidget {
  final AppState appState;
  const GlobalSearchScreen({super.key, required this.appState});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _ctrl = TextEditingController();

  static const int _maxSpecies = 8;
  static const int _maxFacts = 8;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _icon(String name) => IconTile(name: name, size: 40);

  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final raw = _ctrl.text.trim();
    final q = normalizeText(raw);
    final searching = q.length >= 2;

    final sections = <Widget>[];
    var total = 0;

    if (searching) {
      String spName(String sci) => appState.speciesBySci(sci)?.label ?? sci;

      // Oiseaux
      final birds = appState.birds.where((b) => matchesAny(q, [
            b.ring, spName(b.sci), b.sci, b.mutation, b.status, b.location, b.notes, b.cession?.buyer,
          ])).toList();
      if (birds.isNotEmpty) {
        total += birds.length;
        sections
          ..add(SectionLabel('Oiseaux (${birds.length})'))
          ..addAll(birds.map((b) => InfoCard(
                leading: BirdAvatar(bird: b, species: appState.speciesBySci(b.sci)),
                title: b.ring,
                subtitle: '${spName(b.sci)} · ${b.mutation}${b.status.isNotEmpty ? ' · ${b.status}' : ''}',
                onTap: () => _open(BirdDetailScreen(appState: appState, ring: b.ring)),
              )));
      }

      // Couples
      final couples = appState.couples.where((c) => matchesAny(q, [
            c.id, spName(c.sci), c.maleRing, c.femaleRing, c.maleLabel, c.femaleLabel,
          ])).toList();
      if (couples.isNotEmpty) {
        total += couples.length;
        sections
          ..add(SectionLabel('Couples (${couples.length})'))
          ..addAll(couples.map((c) => InfoCard(
                leading: _icon('couple'),
                title: '${c.id} · ${spName(c.sci)}',
                subtitle: '${c.maleRing ?? c.maleLabel ?? '?'} × ${c.femaleRing ?? c.femaleLabel ?? '?'} · ${c.stageName}',
                onTap: () => _open(CoupleDetailScreen(appState: appState, coupleId: c.id)),
              )));
      }

      // Documents
      final docs = appState.allDocuments
          .where((e) => matchesAny(q, [e.value.type, e.value.fileName, e.key.ring, spName(e.key.sci)]))
          .toList();
      if (docs.isNotEmpty) {
        total += docs.length;
        sections
          ..add(SectionLabel('Documents (${docs.length})'))
          ..addAll(docs.map((e) => InfoCard(
                leading: _icon('doc'),
                title: e.value.type,
                subtitle: '${e.key.ring} · ${e.value.fileName}',
                onTap: () => _open(BirdDetailScreen(appState: appState, ring: e.key.ring)),
              )));
      }

      // Incubations
      final incs = appState.incubations
          .where((i) => matchesAny(q, [i.label, i.notes, i.sci.isEmpty ? null : spName(i.sci), i.coupleId]))
          .toList();
      if (incs.isNotEmpty) {
        total += incs.length;
        sections
          ..add(SectionLabel('Incubations (${incs.length})'))
          ..addAll(incs.map((i) => InfoCard(
                leading: _icon('egg'),
                title: i.label,
                subtitle: i.isActive ? 'En cours · jour ${i.dayNumber} sur ${i.incubationDays}' : 'Terminée',
                onTap: () => _open(IncubationDetailScreen(appState: appState, incubationId: i.id)),
              )));
      }

      // Agenda (événements saisis)
      final events = appState.events.where((e) => matchesAny(q, [e.title, e.type, e.notes])).toList();
      if (events.isNotEmpty) {
        total += events.length;
        sections
          ..add(SectionLabel('Agenda (${events.length})'))
          ..addAll(events.map((e) => InfoCard(
                leading: _icon(kEventTypeIcons[e.type] ?? 'doc'),
                title: e.title,
                subtitle: '${e.type} · ${appState.relativeLabel(e.date)}',
              )));
      }

      // Espèces
      final species = appState.species
          .where((s) => matchesAny(q, [s.label, s.sci, ...s.altNames]))
          .toList();
      if (species.isNotEmpty) {
        total += species.length;
        sections.add(SectionLabel('Espèces (${species.length})'));
        sections.addAll(species.take(_maxSpecies).map((s) => InfoCard(
              leading: const CircleAvatar(radius: 4, backgroundColor: AppColors.bronze),
              title: s.label,
              subtitle: s.sci,
              trailing: ProtectionBadge(species: s),
              onTap: () => _open(SpeciesDetailScreen(appState: appState, sci: s.sci)),
            )));
        if (species.length > _maxSpecies) {
          sections.add(EmptyHint('+ ${species.length - _maxSpecies} autres espèces : précise ta recherche.'));
        }
      }

      // Psittacopédie
      final facts = appState.facts.where((f) => matchesAny(q, [
            f.text, f.theme, f.sci == null ? null : spName(f.sci!),
          ])).toList();
      if (facts.isNotEmpty) {
        total += facts.length;
        sections.add(SectionLabel('Psittacopédie (${facts.length})'));
        sections.addAll(facts.take(_maxFacts).map((f) => InfoCard(
              leading: _icon('idea'),
              title: f.theme,
              subtitle: f.text,
              onTap: () => _open(PsittacopedieScreen(appState: appState, initialQuery: raw)),
            )));
        if (facts.length > _maxFacts) {
          sections.add(Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _open(PsittacopedieScreen(appState: appState, initialQuery: raw)),
              child: Text('Voir les ${facts.length} informations'),
            ),
          ));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Bague, espèce, couple, document…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: raw.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(_ctrl.clear),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          if (!searching)
            const EmptyHint('Tape au moins 2 caractères. La recherche ignore les accents et les majuscules.')
          else if (total == 0)
            EmptyHint('Aucun résultat pour « $raw ».')
          else
            ...sections,
        ],
      ),
    );
  }
}
