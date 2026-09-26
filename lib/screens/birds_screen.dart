import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import 'add_bird_screen.dart';
import 'bird_detail_screen.dart';

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
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final q = _searchCtrl.text.trim().toLowerCase();

    var list = appState.birds.where((b) {
      switch (_filter) {
        case 'Mâles':
          return b.sex == 'M';
        case 'Femelles':
          return b.sex == 'F';
        case 'Quarantaine':
          return b.isQuarantined;
        case 'Cédés':
          return b.isCeded;
        default:
          return true;
      }
    }).toList();

    if (q.isNotEmpty) {
      list = list.where((b) {
        final sp = appState.speciesBySci(b.sci);
        final label = sp?.label ?? b.sci;
        return b.ring.toLowerCase().contains(q) || label.toLowerCase().contains(q);
      }).toList();
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: staggered([
          Row(
            children: [
              Expanded(
                child: Text('Mes oiseaux', style: Theme.of(context).textTheme.headlineSmall),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddBirdScreen(appState: appState)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Bague ou espèce',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final selected = f == _filter;
                return ChoiceChip(
                  label: Text(f),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty) const EmptyHint('Aucun oiseau ne correspond.'),
          for (final b in list)
            InfoCard(
              leading: BirdAvatar(bird: b, species: appState.speciesBySci(b.sci)),
              title: b.ring,
              subtitle:
                  '${appState.speciesBySci(b.sci)?.label ?? b.sci} · ${b.mutation}',
              trailing: Icon(
                b.sex == 'M'
                    ? Icons.male
                    : b.sex == 'F'
                        ? Icons.female
                        : Icons.help_outline,
                color: b.sex == 'M'
                    ? Colors.blue
                    : b.sex == 'F'
                        ? Colors.pink
                        : Colors.grey,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BirdDetailScreen(appState: appState, ring: b.ring),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
