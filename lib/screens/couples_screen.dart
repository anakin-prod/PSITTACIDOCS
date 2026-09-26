import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/inbreeding.dart';
import '../models/couple.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'couple_detail_screen.dart';
import 'new_couple_screen.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';

class CouplesScreen extends StatelessWidget {
  final AppState appState;
  const CouplesScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
        children: staggered([
          ScreenHeader(
            title: 'Couples',
            subtitle: '${appState.couples.length} couple${appState.couples.length > 1 ? 's' : ''} en reproduction',
            trailing: AddButton(
              tooltip: 'Former un couple',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => NewCoupleScreen(appState: appState)),
              ),
            ),
          ),
          if (appState.couples.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Aucun couple pour l’instant.', style: TextStyle(color: AppColors.mute)),
            ),
          for (final c in appState.couples) _CoupleCard(appState: appState, couple: c),
        ]),
      ),
    );
  }
}

class _CoupleCard extends StatelessWidget {
  final AppState appState;
  final Couple couple;
  const _CoupleCard({required this.appState, required this.couple});

  Widget _bird(bool male) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: male ? AppColors.maleBg : AppColors.femaleBg,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: Colors.white, width: 2.5),
    ),
    child: Icon(male ? Icons.male_rounded : Icons.female_rounded, size: 20, color: male ? AppColors.maleFg : AppColors.femaleFg),
  );

  @override
  Widget build(BuildContext context) {
    final sp = appState.speciesBySci(couple.sci);
    final detail = couple.stage >= 2
        ? '${couple.eggs} œuf${couple.eggs > 1 ? 's' : ''}'
            '${couple.stage >= 4 ? ' · ${couple.chicks} poussin${couple.chicks > 1 ? 's' : ''}' : ''}'
        : 'Compatibilité à observer';
    final male = couple.maleRing ?? couple.maleLabel ?? '?';
    final female = couple.femaleRing ?? couple.femaleLabel ?? '?';
    final coi = couple.maleRing != null && couple.femaleRing != null
        ? appState.offspringInbreeding(couple.maleRing, couple.femaleRing)
        : 0.0;

    return PressableScale(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppDecor.card(radius: 22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CoupleDetailScreen(appState: appState, coupleId: couple.id)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 66,
                        height: 44,
                        child: Stack(
                          children: [
                            Positioned(left: 0, top: 2, child: _bird(true)),
                            Positioned(left: 24, top: 2, child: _bird(false)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(couple.id, style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy)),
                            Text(sp?.label ?? couple.sci, style: const TextStyle(fontSize: 12.5, color: AppColors.mute)),
                          ],
                        ),
                      ),
                      Tag(couple.stageName, tone: TagTone.bronze),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('$male  ×  $female', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.navy)),
                  const SizedBox(height: 12),
                  StageBar(stage: couple.stage),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.mute))),
                      if (coi >= kInbreedingWarningThreshold)
                        Tag('Consanguinité ${formatPercent(coi)}', tone: TagTone.warning),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
