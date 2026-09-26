import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'add_bird_screen.dart';
import 'bird_detail_screen.dart';
import 'psittacopedie_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final upcoming = appState.agendaItems().take(3).toList();
    final couplesActive = appState.couples.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Bonjour', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: StatCard(label: 'Oiseaux', value: '${appState.birds.length}', dark: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(label: 'Couples actifs', value: '$couplesActive'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Pontes en cours',
                value: '${appState.couples.where((c) => c.stage >= 2 && c.stage < 5).length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Jeunes à sevrer',
                value: '${appState.couples.where((c) => c.stage == 4).length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter un oiseau'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddBirdScreen(appState: appState)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PsittacopedieCard(appState: appState),
        if (upcoming.isNotEmpty) ...[
          const SectionLabel('À venir'),
          for (final item in upcoming)
            InfoCard(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.navy,
                child: Icon(iconFor(item.icon), color: Colors.white, size: 18),
              ),
              title: item.title,
              subtitle: '${item.subtitle} · ${appState.relativeLabel(item.date)}',
              onTap: item.birdRing == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BirdDetailScreen(appState: appState, ring: item.birdRing!),
                      ),
                    ),
            ),
        ],
      ],
    );
  }
}
