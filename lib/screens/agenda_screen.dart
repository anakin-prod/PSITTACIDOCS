import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';
import 'new_event_screen.dart';

class AgendaScreen extends StatelessWidget {
  final AppState appState;
  const AgendaScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final items = appState.agendaItems();
    final todayIdx = (DateTime.now().weekday - 1) % 7; // 0 = lundi

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Agenda', style: Theme.of(context).textTheme.headlineSmall),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => NewEventScreen(appState: appState)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (i) {
              const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
              final isToday = i == todayIdx;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.navy : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday ? null : Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday ? Colors.white : AppColors.mute,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SectionLabel('À venir'),
          if (items.isEmpty)
            const EmptyHint('Aucun événement à venir. Ajoutez un rendez-vous ou une tâche.'),
          for (final item in items)
            InfoCard(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.navy,
                child: Icon(iconFor(item.icon), color: Colors.white, size: 18),
              ),
              title: item.title,
              subtitle: item.subtitle,
              onTap: item.birdRing != null
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BirdDetailScreen(appState: appState, ring: item.birdRing!),
                      ),
                    )
                  : null,
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    appState.relativeLabel(item.date),
                    style: const TextStyle(fontSize: 11, color: AppColors.mute),
                  ),
                  if (!item.auto)
                    InkWell(
                      onTap: () => appState.deleteEvent(item.deleteId!),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.close, size: 16, color: AppColors.mute),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
