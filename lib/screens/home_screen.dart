import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'add_bird_screen.dart';
import 'bird_detail_screen.dart';
import 'incubation_detail_screen.dart';
import 'psittacopedie_screen.dart';

const _days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const _months = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// « Samedi 26 septembre »
String frenchLongDate(DateTime d) {
  final day = _days[d.weekday - 1];
  return '${day[0].toUpperCase()}${day.substring(1)} ${d.day} ${_months[d.month - 1]}';
}

class HomeScreen extends StatelessWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final upcoming = appState.agendaItems().take(3).toList();
    final present = appState.birds.where((b) => !b.isCeded).length;
    final name = appState.settings.elevageName.trim();
    final activeIncubations = appState.incubations.where((i) => i.isActive).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: staggered([
        // En-tête : le nom de l'élevage (ou « Mon élevage ») et la date du jour.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              frenchLongDate(DateTime.now()),
              style: const TextStyle(fontSize: 13, color: AppColors.bronzeDark, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              name.isEmpty ? 'Mon élevage' : name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (name.isEmpty)
              const Text(
                'Donne un nom à ton élevage dans Plus → Paramètres.',
                style: TextStyle(fontSize: 12, color: AppColors.mute),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: StatCard(label: 'Oiseaux', count: present, dark: true)),
            const SizedBox(width: 10),
            Expanded(child: StatCard(label: 'Couples actifs', count: appState.couples.length)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: StatCard(label: 'Incubations en cours', count: activeIncubations)),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Jeunes à sevrer',
                count: appState.couples.where((c) => c.stage == 4).length,
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
              onTap: item.birdRing != null
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BirdDetailScreen(appState: appState, ring: item.birdRing!),
                      ),
                    )
                  : item.incubationId != null
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => IncubationDetailScreen(appState: appState, incubationId: item.incubationId!),
                          ),
                        )
                      : null,
            ),
        ],
      ]),
    );
  }
}
