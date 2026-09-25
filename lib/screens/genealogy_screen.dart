import 'package:flutter/material.dart';

import '../logic/inbreeding.dart';
import '../models/bird.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class GenealogyScreen extends StatelessWidget {
  final AppState appState;
  final String ring;
  const GenealogyScreen({super.key, required this.appState, required this.ring});

  @override
  Widget build(BuildContext context) {
    final bird = appState.findBird(ring);
    if (bird == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Généalogie')),
        body: const Center(child: Text('Cet oiseau n’existe plus.')),
      );
    }
    final father = appState.findBird(bird.fatherRing);
    final mother = appState.findBird(bird.motherRing);
    final paternalGF = appState.findBird(father?.fatherRing);
    final paternalGM = appState.findBird(father?.motherRing);
    final maternalGF = appState.findBird(mother?.fatherRing);
    final maternalGM = appState.findBird(mother?.motherRing);
    final children = appState.childrenOf(ring);
    final sp = appState.speciesBySci(bird.sci);

    return Scaffold(
      appBar: AppBar(title: const Text('Généalogie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${bird.ring} · ${sp?.label ?? bird.sci}', style: const TextStyle(color: AppColors.mute)),
          if (bird.hasParents)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Consanguinité : ${formatPercent(appState.inbreedingOf(bird))} — '
                '${inbreedingLevel(appState.inbreedingOf(bird))}',
                style: const TextStyle(fontSize: 12, color: AppColors.bronzeDark),
              ),
            ),
          const SectionLabel('Grands-parents'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _node(context, paternalGF, bird.fatherRing == null ? null : father?.fatherRing),
              _node(context, paternalGM, bird.fatherRing == null ? null : father?.motherRing),
              _node(context, maternalGF, bird.motherRing == null ? null : mother?.fatherRing),
              _node(context, maternalGM, bird.motherRing == null ? null : mother?.motherRing),
            ],
          ),
          const SectionLabel('Parents'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _node(context, father, bird.fatherRing, big: true),
              _node(context, mother, bird.motherRing, big: true),
            ],
          ),
          const SectionLabel('Cet oiseau'),
          _node(context, bird, bird.ring, big: true, self: true),
          const SectionLabel('Descendance'),
          if (children.isEmpty)
            const EmptyHint('Pas encore de descendance enregistrée.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final c in children) _node(context, c, c.ring, big: true)],
            ),
        ],
      ),
    );
  }

  Widget _node(BuildContext context, Bird? b, String? fallbackRing, {bool big = false, bool self = false}) {
    final size = big ? 84.0 : 72.0;
    if (b == null) {
      return SizedBox(
        width: size,
        child: Column(
          children: [
            CircleAvatar(
              radius: big ? 26 : 20,
              backgroundColor: const Color(0xFFF3E3E1),
              child: const Text('?', style: TextStyle(color: Color(0xFFB98A8E))),
            ),
            const SizedBox(height: 4),
            Text(
              fallbackRing ?? 'Inconnu',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.mute),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    final sp = appState.speciesBySci(b.sci);
    final content = SizedBox(
      width: size,
      child: Column(
        children: [
          BirdAvatar(bird: b, species: sp, size: big ? 52 : 40),
          const SizedBox(height: 4),
          Text(b.ring, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(
            sp?.label ?? b.sci,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.mute),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    if (self) return content;
    return InkWell(
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GenealogyScreen(appState: appState, ring: b.ring)),
      ),
      child: content,
    );
  }
}
