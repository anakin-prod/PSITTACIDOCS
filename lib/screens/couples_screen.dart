import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final sp = appState.speciesBySci(couple.sci);
    final detail = couple.stage >= 2
        ? '${couple.eggs} œuf${couple.eggs > 1 ? 's' : ''}'
            '${couple.stage >= 4 ? ' · ${couple.chicks} poussin${couple.chicks > 1 ? 's' : ''}' : ''}'
        : 'Compatibilité à observer';

    return PressableScale(
      child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CoupleDetailScreen(appState: appState, coupleId: couple.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: AppDecor.card(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${couple.id}${sp != null ? ' · ${sp.label}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy),
                  ),
                ),
                Tag(couple.stageName, tone: TagTone.bronze),
              ],
            ),
            const SizedBox(height: 8),
            StageBar(stage: couple.stage),
            const SizedBox(height: 6),
            Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.mute)),
          ],
        ),
      ),
      ),
    );
  }
}
