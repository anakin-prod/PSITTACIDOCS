import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

/// Couleurs des catégories de la Liste rouge de l'UICN, de la plus grave à la moins grave.
const _cEX = Color(0xFF2B2F3F);
const _cEW = Color(0xFF5B3A78);
const _cCR = Color(0xFFB01019);
const _cEN = Color(0xFFE0582A);
const _cVU = Color(0xFFE8A33C);
const _cNT = Color(0xFFC7B34A);

/// Chiffres de conservation des perroquets, en graphiques. Chaque chiffre est
/// accompagné de sa source et de son année ; aucune donnée n'est estimée.
class ConservationScreen extends StatelessWidget {
  final AppState appState;
  const ConservationScreen({super.key, required this.appState});

  Widget _source(String text) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text('Source : $text', style: const TextStyle(fontSize: 11, color: AppColors.mute)),
  );

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: AppDecor.card(radius: 22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _keyFigure(String value, String label, String source) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.navy)),
          const SizedBox(height: 6),
          Text(source, style: const TextStyle(fontSize: 10, color: AppColors.mute)),
        ],
      ),
    ),
  );

  Widget _threat(String icon, String region, String threat) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: AppDecor.card(radius: 20),
    child: Row(
      children: [
        IconTile(name: icon, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(region, style: const TextStyle(fontSize: 12, color: AppColors.mute)),
              Text(threat, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.navy)),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Protection des espèces de la base (données CITES / UE vérifiées).
    final annexA = appState.species.where((s) => s.ue == 'A').length;
    final annexB = appState.species.where((s) => s.ue == 'B').length;
    final notListed = appState.species.where((s) => s.isNotListed).length;

    // Oiseaux présents de l'élevage, par annexe européenne.
    final present = appState.birds.where((b) => !b.isCeded).toList();
    int byAnnex(bool Function(String ue) test) =>
        present.where((b) => test(appState.speciesBySci(b.sci)?.ue ?? '')).length;
    final myA = byAnnex((u) => u == 'A');
    final myB = byAnnex((u) => u == 'B');
    final myNI = byAnnex((u) => u == 'NI');
    final myUnknown = present.length - myA - myB - myNI;

    return Scaffold(
      appBar: AppBar(title: const Text('Perroquets menacés')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: staggered([
          // Chiffre phare
          ClipRRect(
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
                        'LISTE ROUGE DE L’UICN',
                        style: TextStyle(fontSize: 12, letterSpacing: 1, color: AppColors.bronzeOnNavy, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 27),
                        duration: const Duration(milliseconds: 1100),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => Text(
                          '${v.round()} %',
                          style: GoogleFonts.lora(fontSize: 56, fontWeight: FontWeight.w600, color: Colors.white, height: 1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'des espèces de perroquets sont menacées d’extinction, contre 12,8 % pour l’ensemble des oiseaux.',
                        style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.onNavyMuted),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Source : BirdLife International, évaluations de la Liste rouge 2022',
                        style: TextStyle(fontSize: 10.5, color: AppColors.onNavyMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SectionLabel('Les groupes d’oiseaux les plus menacés'),
          _card([
            const Text('Part des espèces menacées d’extinction', style: TextStyle(fontSize: 12, color: AppColors.mute)),
            const SizedBox(height: 6),
            const HBarChart(
              unit: '%',
              maxValue: 70,
              items: [
                BarItem('Albatros', 68),
                BarItem('Grues', 67),
                BarItem('Perroquets', 27, highlight: true),
                BarItem('Faisans', 21),
                BarItem('Pigeons', 18),
                BarItem('Tous les oiseaux', 12.8),
              ],
            ),
            _source('BirdLife International (autorité officielle de la Liste rouge pour les oiseaux), 2022'),
          ]),
          const SectionLabel('Les perroquets sur la Liste rouge'),
          _card([
            const Text('Nombre d’espèces par catégorie', style: TextStyle(fontSize: 12, color: AppColors.mute)),
            const SizedBox(height: 6),
            const HBarChart(
              items: [
                BarItem('Éteintes', 16, color: _cEX),
                BarItem('Éteinte à l’état sauvage', 1, color: _cEW),
                BarItem('En danger critique', 20, color: _cCR),
                BarItem('En danger', 26, color: _cEN),
                BarItem('Vulnérables', 52, color: _cVU),
                BarItem('Quasi menacées', 53, color: _cNT),
              ],
            ),
            _source('recherche sur la Liste rouge de l’UICN publiée par Lafeber, 2023. '
                'Les totaux varient légèrement selon l’année d’évaluation et la classification retenue.'),
          ]),
          const SectionLabel('Chiffres clés'),
          IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _keyFigure('+ de 50 %', 'des espèces de perroquets voient leurs populations diminuer', 'Berkunsky et al., 2017'),
              const SizedBox(width: 10),
              _keyFigure('16', 'espèces de perroquets éteintes, surtout sur des îles', 'Olah et al., 2016'),
            ],
          ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _keyFigure('570 000', 'Conures à front rouge capturées illégalement en 25 ans (jusqu’en 2019)', 'BirdLife International, 2021'),
              const SizedBox(width: 10),
              _keyFigure('+ de 50 %', 'des perroquets d’Amérique latine et des Caraïbes sont quasi menacés, menacés ou éteints', 'BirdLife International, 2021'),
            ],
          ),
          ),
          const SectionLabel('La menace principale selon les régions'),
          _threat('leaf', 'Amérique centrale et du Sud', 'Agriculture'),
          _threat('shield', 'Afrique', 'Chasse et piégeage'),
          _threat('tree', 'Australasie', 'Exploitation forestière et urbanisation'),
          _source('Olah et al., Biodiversity and Conservation (2016), résumé par Mongabay'),
          const SectionLabel('Protection des espèces de l’appli'),
          _card([
            DonutChart(
              centerValue: '${appState.species.length}',
              centerLabel: 'espèces',
              slices: [
                ChartSlice('Annexe A (UE)', annexA.toDouble(), _cCR),
                ChartSlice('Annexe B (UE)', annexB.toDouble(), AppColors.bronze),
                ChartSlice('Non inscrites', notListed.toDouble(), const Color(0xFFCBD0E0)),
              ],
            ),
            _source('annexes CITES en vigueur et règlement (CE) n° 338/97, vérifiés pour chaque espèce'),
          ]),
          const SectionLabel('Dans ton élevage'),
          if (present.isEmpty)
            const EmptyHint('Ajoute des oiseaux pour voir la répartition de ton élevage.')
          else
            _card([
              DonutChart(
                centerValue: '${present.length}',
                centerLabel: 'oiseau${present.length > 1 ? 'x' : ''}',
                slices: [
                  ChartSlice('Annexe A (UE)', myA.toDouble(), _cCR),
                  ChartSlice('Annexe B (UE)', myB.toDouble(), AppColors.bronze),
                  ChartSlice('Non inscrits', myNI.toDouble(), const Color(0xFFCBD0E0)),
                  if (myUnknown > 0) ChartSlice('Espèce inconnue', myUnknown.toDouble(), AppColors.neutralFg),
                ],
              ),
              if (myA > 0)
                InfoBanner(
                  '$myA oiseau${myA > 1 ? 'x' : ''} de ton élevage appartien${myA > 1 ? 'nent' : 't'} à une espèce de l’Annexe A : '
                  'leur vente ou leur cession nécessite en principe un certificat intracommunautaire (CIC).',
                  warning: true,
                ),
            ]),
        ]),
      ),
    );
  }
}
