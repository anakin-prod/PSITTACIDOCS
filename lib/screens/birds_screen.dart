import 'package:flutter/material.dart';

import '../logic/text_search.dart';
import '../models/bird.dart';
import '../models/species.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import 'add_bird_screen.dart';
import 'bird_detail_screen.dart';

/// Pastille de statut d'un oiseau, colorée selon sa signification.
Widget statusTag(Bird b) {
  if (b.isCeded) return const Tag('Cédé', tone: TagTone.rose);
  if (b.isQuarantined) {
    final until = b.quarantineUntil == null ? null : DateTime.tryParse(b.quarantineUntil!);
    if (until != null) {
      final now = DateTime.now();
      final days = DateTime(until.year, until.month, until.day).difference(DateTime(now.year, now.month, now.day)).inDays;
      return Tag(days > 0 ? 'Quarantaine · $days j' : 'Fin de quarantaine', tone: TagTone.warning);
    }
    return const Tag('Quarantaine', tone: TagTone.warning);
  }
  return Tag(b.status.isEmpty ? '—' : b.status);
}

/// Carte d'un oiseau : avatar, bague, protection, pastilles.
class BirdCard extends StatelessWidget {
  final Bird bird;
  final Species? species;
  final VoidCallback onTap;
  final bool showSpecies;
  const BirdCard({super.key, required this.bird, required this.species, required this.onTap, this.showSpecies = false});

  @override
  Widget build(BuildContext context) {
    final showMutation = bird.mutation.isNotEmpty && bird.mutation.toLowerCase() != 'ancestral';
    return PressableScale(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: AppDecor.card(radius: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  BirdAvatar(bird: bird, species: species, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                bird.ring,
                                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.navy),
                              ),
                            ),
                            if (species != null) ProtectionBadge(species: species!),
                          ],
                        ),
                        if (showSpecies)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(species?.label ?? bird.sci, style: const TextStyle(fontSize: 12.5, color: AppColors.mute)),
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            sexTag(bird.sex),
                            statusTag(bird),
                            if (showMutation) Tag(bird.mutation, tone: TagTone.bronze),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.chevron, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BirdsScreen extends StatefulWidget {
  final AppState appState;
  const BirdsScreen({super.key, required this.appState});

  @override
  State<BirdsScreen> createState() => _BirdsScreenState();
}

class _BirdsScreenState extends State<BirdsScreen> {
  String _filter = 'Tous';
  final _searchCtrl = TextEditingController();

  static const _filters = ['Tous', 'Mâles', 'Femelles', 'Quarantaine', 'Cédés'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final q = normalizeText(_searchCtrl.text.trim());

    final present = appState.birds.where((b) => !b.isCeded).toList();
    var list = appState.birds.where((b) {
      switch (_filter) {
        case 'Mâles':
          return b.sex == 'M' && !b.isCeded;
        case 'Femelles':
          return b.sex == 'F' && !b.isCeded;
        case 'Quarantaine':
          return b.isQuarantined;
        case 'Cédés':
          return b.isCeded;
        default:
          return !b.isCeded;
      }
    }).toList();
    if (q.isNotEmpty) {
      list = list
          .where((b) => matchesAny(q, [b.ring, appState.speciesBySci(b.sci)?.label, b.sci, b.mutation, b.status, b.location]))
          .toList();
    }

    // Regroupement par espèce, groupes et oiseaux triés.
    final groups = <String, List<Bird>>{};
    for (final b in list) {
      groups.putIfAbsent(appState.speciesBySci(b.sci)?.label ?? b.sci, () => []).add(b);
    }
    final names = groups.keys.toList()..sort();
    for (final n in names) {
      groups[n]!.sort((a, b) => a.ring.compareTo(b.ring));
    }

    final speciesCount = present.map((b) => b.sci).toSet().length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
      children: staggered([
        ScreenHeader(
          title: 'Mes oiseaux',
          subtitle: '${present.length} oiseau${present.length > 1 ? 'x' : ''} · $speciesCount espèce${speciesCount > 1 ? 's' : ''}',
          trailing: AddButton(
            tooltip: 'Ajouter un oiseau',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddBirdScreen(appState: appState)),
            ),
          ),
        ),
        SearchField(
          controller: _searchCtrl,
          hint: 'Bague, espèce, mutation…',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => PillChoice(
              label: Text(_filters[i]),
              selected: _filters[i] == _filter,
              onSelected: (_) => setState(() => _filter = _filters[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (list.isEmpty) const EmptyHint('Aucun oiseau ne correspond.'),
        for (final n in names) ...[
          GroupLabel('$n · ${groups[n]!.length}'),
          for (final b in groups[n]!)
            BirdCard(
              bird: b,
              species: appState.speciesBySci(b.sci),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BirdDetailScreen(appState: appState, ring: b.ring)),
              ),
            ),
        ],
      ]),
    );
  }
}
