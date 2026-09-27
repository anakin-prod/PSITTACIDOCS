import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/inbreeding.dart' show formatPercent;
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';

class StatsScreen extends StatelessWidget {
  final AppState appState;
  const StatsScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final present = appState.birds.where((b) => !b.isCeded).toList();
    final total = present.length;
    final bySpecies = <String, int>{};
    for (final b in present) {
      bySpecies[b.sci] = (bySpecies[b.sci] ?? 0) + 1;
    }
    final top = bySpecies.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final sexM = present.where((b) => b.sex == 'M').length;
    final sexF = present.where((b) => b.sex == 'F').length;
    final sexU = total - sexM - sexF;
    final clutches = appState.couples.fold<int>(0, (n, c) => n + c.history.length);
    final chicksNow = appState.couples.where((c) => c.stage >= 4).fold<int>(0, (n, c) => n + c.chicks);
    final finished = appState.incubations.where((i) => !i.isActive && i.eggs > 0).toList();
    final eggs = finished.fold<int>(0, (n, i) => n + i.eggs);
    final hatched = finished.fold<int>(0, (n, i) => n + i.hatched);
    final hatchRate = eggs == 0 ? null : hatched / eggs;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: staggered([
          _StatsHero(
            birds: total,
            species: bySpecies.length,
            couples: appState.couples.length,
            cessions: appState.cededBirds.length,
          ),
          const SectionLabel('Répartition par sexe'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecor.card(radius: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SexBar(male: sexM, female: sexF, unknown: sexU),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Tag('$sexM mâle${sexM > 1 ? 's' : ''}', tone: TagTone.male),
                    Tag('$sexF femelle${sexF > 1 ? 's' : ''}', tone: TagTone.female),
                    if (sexU > 0) Tag('$sexU sexe inconnu'),
                  ],
                ),
              ],
            ),
          ),
          const SectionLabel('Espèces les plus présentes'),
          if (top.isEmpty) const EmptyHint('Aucun oiseau pour l’instant.'),
          for (final e in top.take(6))
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: AppDecor.card(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          appState.speciesBySci(e.key)?.label ?? e.key,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
                        ),
                      ),
                      if (appState.speciesBySci(e.key) != null) ...[
                        ProtectionBadge(species: appState.speciesBySci(e.key)!),
                        const SizedBox(width: 10),
                      ],
                      Text('${e.value}', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedBar(value: total == 0 ? 0.0 : e.value / total, height: 6),
                ],
              ),
            ),
          if (top.length > 6)
            EmptyHint('+ ${top.length - 6} autre${top.length - 6 > 1 ? 's' : ''} espèce${top.length - 6 > 1 ? 's' : ''}'),
          const SectionLabel('Reproduction'),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Pontes terminées', count: clutches)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(label: 'Poussins en cours', count: chicksNow)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecor.card(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Taux d’éclosion en couveuse', style: TextStyle(fontSize: 12, color: AppColors.mute)),
                const SizedBox(height: 4),
                Text(
                  hatchRate == null ? '—' : formatPercent(hatchRate),
                  style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.navy),
                ),
                const SizedBox(height: 8),
                if (hatchRate != null) AnimatedBar(value: hatchRate, height: 6, color: AppColors.goodFg),
                const SizedBox(height: 6),
                Text(
                  hatchRate == null
                      ? 'Calculé dès qu’une incubation est terminée.'
                      : '$hatched éclos sur $eggs œuf${eggs > 1 ? 's' : ''}, sur ${finished.length} incubation${finished.length > 1 ? 's' : ''} terminée${finished.length > 1 ? 's' : ''}.',
                  style: const TextStyle(fontSize: 12, color: AppColors.mute),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Bandeau bleu nuit des statistiques.
class _StatsHero extends StatelessWidget {
  final int birds;
  final int species;
  final int couples;
  final int cessions;
  const _StatsHero({required this.birds, required this.species, required this.couples, required this.cessions});

  Widget _mini(int value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCount(value: value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onNavyMuted)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: Container(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -54,
            top: -28,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset('assets/images/parrot_silhouette.png', width: 180, height: 180),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VUE D’ENSEMBLE',
                style: TextStyle(fontSize: 12, letterSpacing: 1, color: AppColors.bronzeOnNavy, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedCount(value: birds, style: GoogleFonts.lora(fontSize: 52, fontWeight: FontWeight.w600, color: Colors.white, height: 1)),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'oiseau${birds > 1 ? 'x' : ''} présent${birds > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 14, color: AppColors.onNavyMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _mini(species, 'espèce${species > 1 ? 's' : ''}'),
                  _mini(couples, 'couple${couples > 1 ? 's' : ''} actif${couples > 1 ? 's' : ''}'),
                  _mini(cessions, 'cession${cessions > 1 ? 's' : ''}'),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Barre de répartition mâles / femelles / inconnus, qui se déploie en douceur.
class _SexBar extends StatelessWidget {
  final int male;
  final int female;
  final int unknown;
  const _SexBar({required this.male, required this.female, required this.unknown});

  @override
  Widget build(BuildContext context) {
    final total = male + female + unknown;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 14,
          child: total == 0
              ? Container(color: AppColors.neutralBg)
              : Container(
                  color: AppColors.neutralBg,
                  child: Row(
                    children: [
                      if (male > 0) Flexible(flex: (male * 1000 * t).round() + 1, child: Container(color: AppColors.maleFg)),
                      if (female > 0) Flexible(flex: (female * 1000 * t).round() + 1, child: Container(color: AppColors.femaleFg)),
                      if (unknown > 0) Flexible(flex: (unknown * 1000 * t).round() + 1, child: Container(color: const Color(0xFFCBD0E0))),
                      Flexible(flex: ((total * 1000) * (1 - t)).round() + 1, child: const SizedBox()),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
