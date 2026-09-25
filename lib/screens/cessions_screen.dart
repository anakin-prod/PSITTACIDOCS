import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';
import 'new_cession_screen.dart';

class CessionsScreen extends StatefulWidget {
  final AppState appState;
  const CessionsScreen({super.key, required this.appState});

  @override
  State<CessionsScreen> createState() => _CessionsScreenState();
}

class _CessionsScreenState extends State<CessionsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final ceded = appState.cededBirds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cessions'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Enregistrer'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => NewCessionScreen(appState: appState)),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${ceded.length} oiseau${ceded.length > 1 ? 'x' : ''} cédé${ceded.length > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.mute),
          ),
          const SizedBox(height: 8),
          if (ceded.isEmpty) const EmptyHint('Aucune cession enregistrée pour l’instant.'),
          for (final b in ceded)
            InfoCard(
              leading: BirdAvatar(bird: b, species: appState.speciesBySci(b.sci)),
              title: '${b.ring} · ${b.cession!.buyer}',
              subtitle: '${appState.speciesBySci(b.sci)?.label ?? b.sci}'
                  '${b.cession!.date.isNotEmpty ? ' · ${formatIsoShort(b.cession!.date)}' : ''}'
                  '${b.cession!.price.isNotEmpty ? ' · ${b.cession!.price}' : ''}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BirdDetailScreen(appState: appState, ring: b.ring)),
              ),
            ),
        ],
      ),
    );
  }
}

String formatIsoShort(String iso) {
  try {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return iso;
  }
}
