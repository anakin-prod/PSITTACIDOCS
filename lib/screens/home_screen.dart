import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import 'add_bird_screen.dart';
import 'bird_detail_screen.dart';
import 'env_readings_screen.dart';
import 'global_search_screen.dart';
import 'incubation_detail_screen.dart';
import 'incubations_screen.dart';
import 'new_couple_screen.dart';
import 'notifications_screen.dart';
import 'psittacopedie_screen.dart';

const _days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const _months = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];
const _monthsShort = ['JANV', 'FÉVR', 'MARS', 'AVR', 'MAI', 'JUIN', 'JUIL', 'AOÛT', 'SEPT', 'OCT', 'NOV', 'DÉC'];

/// « Samedi 26 septembre »
String frenchLongDate(DateTime d) {
  final day = _days[d.weekday - 1];
  return '${day[0].toUpperCase()}${day.substring(1)} ${d.day} ${_months[d.month - 1]}';
}

/// « SEPT »
String frenchShortMonth(int month) => _monthsShort[month - 1];

class HomeScreen extends StatelessWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final upcoming = appState.agendaItems().take(3).toList();
    final present = appState.birds.where((b) => !b.isCeded).toList();
    final speciesCount = present.map((b) => b.sci).toSet().length;
    final name = appState.settings.elevageName.trim();
    final activeIncubations = appState.incubations.where((i) => i.isActive).length;
    final toWean = appState.couples.where((c) => c.stage == 4).fold<int>(0, (n, c) => n + c.chicks);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
      children: staggered([
        // Barre du haut : logo, nom de l'appli, recherche et notifications.
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset('assets/images/icon.png', width: 36, height: 36),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Psittacidocs', style: GoogleFonts.lora(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.navy)),
            ),
            CircleIconButton(
              icon: Icons.search_rounded,
              tooltip: 'Rechercher',
              onPressed: () => _open(context, GlobalSearchScreen(appState: appState)),
            ),
            const SizedBox(width: 10),
            CircleIconButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              showDot: appState.unreadCount > 0,
              onPressed: () => _open(context, NotificationsScreen(appState: appState)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Hero(
          date: frenchLongDate(DateTime.now()),
          name: name.isEmpty ? 'Mon élevage' : name,
          birds: present.length,
          species: speciesCount,
          couples: appState.couples.length,
          incubations: activeIncubations,
          toWean: toWean,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _QuickAction(label: 'Oiseau', kind: 'parrot', onTap: () => _open(context, AddBirdScreen(appState: appState)))),
            const SizedBox(width: 10),
            Expanded(child: _QuickAction(label: 'Couple', kind: 'couple', onTap: () => _open(context, NewCoupleScreen(appState: appState)))),
            const SizedBox(width: 10),
            Expanded(child: _QuickAction(label: 'Relevé', kind: 'thermo', onTap: () => _open(context, NewEnvReadingScreen(appState: appState)))),
            const SizedBox(width: 10),
            Expanded(child: _QuickAction(label: 'Incubation', kind: 'egg', onTap: () => _open(context, NewIncubationScreen(appState: appState)))),
          ],
        ),
        if (upcoming.isNotEmpty) ...[
          const SectionLabel('À venir'),
          for (final item in upcoming)
            _UpcomingCard(
              item: item,
              relative: appState.relativeLabel(item.date),
              onTap: item.birdRing != null
                  ? () => _open(context, BirdDetailScreen(appState: appState, ring: item.birdRing!))
                  : item.incubationId != null
                      ? () => _open(context, IncubationDetailScreen(appState: appState, incubationId: item.incubationId!))
                      : null,
            ),
        ],
        const SizedBox(height: 14),
        PsittacopedieCard(appState: appState),
      ]),
    );
  }
}

/// Bandeau bleu nuit : date, nom de l'élevage, chiffres clés, perroquet en filigrane.
class _Hero extends StatelessWidget {
  final String date;
  final String name;
  final int birds;
  final int species;
  final int couples;
  final int incubations;
  final int toWean;

  const _Hero({
    required this.date,
    required this.name,
    required this.birds,
    required this.species,
    required this.couples,
    required this.incubations,
    required this.toWean,
  });

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
              child: Image.asset('assets/images/parrot_silhouette.png', width: 190, height: 190),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date.toUpperCase(),
                style: const TextStyle(fontSize: 12, letterSpacing: 1, color: AppColors.bronzeOnNavy, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(name, style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedCount(
                    value: birds,
                    style: GoogleFonts.lora(fontSize: 52, fontWeight: FontWeight.w600, color: Colors.white, height: 1),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'oiseau${birds > 1 ? 'x' : ''} présent${birds > 1 ? 's' : ''} · $species espèce${species > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 14, color: AppColors.onNavyMuted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _mini(couples, 'couple${couples > 1 ? 's' : ''} actif${couples > 1 ? 's' : ''}'),
                  _mini(incubations, 'incubation${incubations > 1 ? 's' : ''}'),
                  _mini(toWean, 'jeune${toWean > 1 ? 's' : ''} à sevrer'),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Raccourci : pictogramme teinté et libellé, dans une carte blanche.
class _QuickAction extends StatelessWidget {
  final String label;
  final String kind; // 'parrot' ou un nom d'icône
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.kind, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Widget glyph;
    if (kind == 'parrot') {
      final (bg, fg) = iconTint('tree');
      glyph = Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
        child: ImageIcon(const AssetImage('assets/images/nav_parrot.png'), color: fg, size: 21),
      );
    } else {
      glyph = IconTile(name: kind, size: 34);
    }
    return PressableScale(
      child: Container(
        height: 80,
        decoration: AppDecor.card(radius: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                glyph,
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.navy)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rendez-vous : la date en évidence dans un bloc teinté, et l'échéance.
class _UpcomingCard extends StatelessWidget {
  final AgendaItem item;
  final String relative;
  final VoidCallback? onTap;
  const _UpcomingCard({required this.item, required this.relative, this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(item.date) ?? DateTime.now();
    final (bg, fg) = iconTint(item.icon);
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 52,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${d.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fg, height: 1.1)),
                Text(frenchShortMonth(d.month), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.6)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.mute),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
            child: Text(relative, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
          ),
        ],
      ),
    );
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDecor.card(radius: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: content),
      ),
    );
    return onTap == null ? card : PressableScale(child: card);
  }
}
