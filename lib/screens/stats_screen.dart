import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/animations.dart';

class StatsScreen extends StatelessWidget {
  final AppState appState;
  const StatsScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final total = appState.birds.length;
    final bySpecies = <String, int>{};
    for (final b in appState.birds) {
      bySpecies[b.sci] = (bySpecies[b.sci] ?? 0) + 1;
    }
    final speciesCount = bySpecies.length;
    final sexM = appState.birds.where((b) => b.sex == 'M').length;
    final sexF = appState.birds.where((b) => b.sex == 'F').length;
    final sexU = total - sexM - sexF;
    final sevrages = appState.couples.fold<int>(0, (n, c) => n + c.history.length);
    final chicksNow = appState.couples
        .where((c) => c.stage >= 4)
        .fold<int>(0, (n, c) => n + c.chicks);
    final cessionsCount = appState.cededBirds.length;
    final top = bySpecies.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    double pct(int n) => total == 0 ? 0 : n / total;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: staggered([
          Row(
            children: [
              Expanded(child: StatCard(label: 'Oiseaux', count: total, dark: true)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(label: 'Espèces', count: speciesCount)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Couples actifs', count: appState.couples.length)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(label: 'Cessions', count: cessionsCount)),
            ],
          ),
          const SectionLabel('Répartition par sexe'),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (sexM > 0) Expanded(flex: sexM, child: Container(color: const Color(0xFF1F4BA8))),
                  if (sexF > 0) Expanded(flex: sexF, child: Container(color: const Color(0xFFB5646E))),
                  if (sexU > 0) Expanded(flex: sexU, child: Container(color: const Color(0xFFE6CFCC))),
                  if (total == 0) Expanded(child: Container(color: AppColors.line)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('♂ Mâles · $sexM', style: const TextStyle(fontSize: 12, color: AppColors.mute)),
              Text('♀ Femelles · $sexF', style: const TextStyle(fontSize: 12, color: AppColors.mute)),
              Text('? Inconnu · $sexU', style: const TextStyle(fontSize: 12, color: AppColors.mute)),
            ],
          ),
          const SectionLabel('Espèces les plus présentes'),
          for (final e in top.take(6))
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(appState.speciesBySci(e.key)?.label ?? e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${e.value}', style: const TextStyle(fontSize: 12, color: AppColors.mute)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedBar(value: pct(e.value)),
                ],
              ),
            ),
          if (top.length > 6)
            Text('+ ${top.length - 6} autre${top.length - 6 > 1 ? 's' : ''} espèce${top.length - 6 > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.mute)),
          const SectionLabel('Reproduction'),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Sevrages enregistrés', count: sevrages)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(label: 'Poussins en cours', count: chicksNow)),
            ],
          ),
        ]),
      ),
    );
  }
}
