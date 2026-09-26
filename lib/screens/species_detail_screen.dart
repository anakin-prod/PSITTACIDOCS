import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';

class SpeciesDetailScreen extends StatelessWidget {
  final AppState appState;
  final String sci;
  const SpeciesDetailScreen({super.key, required this.appState, required this.sci});

  String _explain(String ue) {
    switch (ue) {
      case 'A':
        return 'Protection maximale. Dans l’UE, la vente ou la cession d’un spécimen '
            'nécessite en principe un certificat intracommunautaire (CIC).';
      case 'NI':
        return 'Espèce non couverte par la CITES ni par le règlement européen.';
      default:
        return 'Commerce autorisé dans l’UE à condition de pouvoir prouver l’origine '
            'légale de l’oiseau (certificat de cession, facture, etc.).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = appState.speciesBySci(sci);
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche espèce')),
        body: const Center(child: Text('Espèce introuvable.')),
      );
    }
    final mine = appState.birds.where((b) => b.sci == sci).toList();
    final speciesPlusUrl =
        'https://speciesplus.net/species#/taxon_concepts?taxonomy=cites_eu&taxon_concept_query=${Uri.encodeComponent(sci)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Fiche espèce')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.label, style: Theme.of(context).textTheme.headlineSmall),
          Text(s.sci, style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.mute)),
          if (s.altNames.isNotEmpty) ...[
            const SectionLabel('Autres noms'),
            Text(s.altNames.join(', '), style: const TextStyle(fontSize: 13)),
          ],
          const SectionLabel('Protection réglementaire'),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: s.cites == 'I' ? AppColors.navy : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: s.cites == 'I' ? null : AppDecor.shadowLight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CITES international',
                          style: TextStyle(fontSize: 11, color: s.cites == 'I' ? Colors.white70 : AppColors.mute)),
                      const SizedBox(height: 4),
                      Text(s.citesLabel,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: s.cites == 'I' ? Colors.white : AppColors.navy)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: s.ue == 'A' ? AppColors.navy : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: s.ue == 'A' ? null : AppDecor.shadowLight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Union européenne',
                          style: TextStyle(fontSize: 11, color: s.ue == 'A' ? Colors.white70 : AppColors.mute)),
                      const SizedBox(height: 4),
                      Text(s.ueLabel,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: s.ue == 'A' ? Colors.white : AppColors.navy)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          InfoBanner(_explain(s.ue), warning: s.ue == 'A'),
          if (s.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(s.note, style: const TextStyle(fontSize: 13)),
            ),
          const SectionLabel('Dans votre élevage'),
          if (mine.isEmpty)
            const EmptyHint('Aucun oiseau de cette espèce dans votre élevage pour l’instant.'),
          for (final b in mine)
            InfoCard(
              leading: BirdAvatar(bird: b, species: s),
              title: b.ring,
              subtitle: '${b.mutation}${b.status.isNotEmpty ? ' · ${b.status}' : ''}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BirdDetailScreen(appState: appState, ring: b.ring)),
              ),
            ),
          const SectionLabel('Source officielle'),
          InfoCard(
            leading: IconTile(name: 'shield', size: 40),
            title: 'Vérifier sur Species+',
            subtitle: 'Base officielle CITES et UE (PNUE-WCMC)',
            onTap: () => launchUrl(Uri.parse(speciesPlusUrl), mode: LaunchMode.externalApplication),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Annexes CITES en vigueur depuis le 21/05/2023, inchangées pour les perroquets '
              'à la CoP20 (déc. 2025). Annexes UE : règlement (CE) n° 338/97. '
              'En cas de doute, la DREAL fait foi.',
              style: const TextStyle(fontSize: 11, color: AppColors.mute),
            ),
          ),
        ],
      ),
    );
  }
}
