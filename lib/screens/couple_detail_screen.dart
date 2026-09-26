import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/inbreeding.dart';
import '../models/couple.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';

class CoupleDetailScreen extends StatefulWidget {
  final AppState appState;
  final String coupleId;
  const CoupleDetailScreen({super.key, required this.appState, required this.coupleId});

  @override
  State<CoupleDetailScreen> createState() => _CoupleDetailScreenState();
}

class _CoupleDetailScreenState extends State<CoupleDetailScreen> {
  final _eggsCtrl = TextEditingController();
  final _chicksCtrl = TextEditingController();
  DateTime? _incubDate;
  bool _initialized = false;

  void _syncFromCouple(Couple c) {
    if (_initialized) return;
    _eggsCtrl.text = c.eggs > 0 ? '${c.eggs}' : '';
    _chicksCtrl.text = c.chicks > 0 ? '${c.chicks}' : '';
    _incubDate = c.incubationDate == null ? null : DateTime.tryParse(c.incubationDate!);
    _initialized = true;
  }

  Future<void> _advance(Couple c) async {
    c.eggs = int.tryParse(_eggsCtrl.text.trim()) ?? c.eggs;
    c.chicks = int.tryParse(_chicksCtrl.text.trim()) ?? c.chicks;
    if (_incubDate != null) {
      c.incubationDate = _incubDate!.toIso8601String().substring(0, 10);
    }
    await widget.appState.advanceCouple(c);
    setState(() => _initialized = false);
  }

  Widget _parentTile({required bool male, required String? ring, required String? fallback}) {
    final exists = ring != null && widget.appState.findBird(ring) != null;
    final sp = exists ? widget.appState.speciesBySci(widget.appState.findBird(ring)!.sci) : null;
    return Material(
      color: male ? const Color(0xFFF3F6FD) : const Color(0xFFFDF1F2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: exists
            ? () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BirdDetailScreen(appState: widget.appState, ring: ring)),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(male ? Icons.male_rounded : Icons.female_rounded, size: 16, color: male ? AppColors.maleFg : AppColors.femaleFg),
                  const SizedBox(width: 4),
                  Text(
                    male ? 'MÂLE' : 'FEMELLE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: male ? AppColors.maleFg : AppColors.femaleFg),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(ring ?? fallback ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
              if (sp != null) Text(sp.label, style: const TextStyle(fontSize: 11.5, color: AppColors.mute), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.appState.findCouple(widget.coupleId);
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche couple')),
        body: const Center(child: Text('Ce couple n’existe plus.')),
      );
    }
    _syncFromCouple(c);
    final nextName = kCoupleStages[(c.stage + 1).clamp(0, 5)];
    final btnLabel = c.stage < 5 ? 'Passer à : $nextName' : 'Enregistrer et commencer une nouvelle ponte';

    return Scaffold(
      appBar: AppBar(title: const Text('Fiche couple')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          // Carte d'identité du couple : numéro, espèce, étape, les deux parents.
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppDecor.card(radius: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.id, style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.navy)),
                          Text(
                            widget.appState.speciesBySci(c.sci)?.label ?? c.sci,
                            style: const TextStyle(fontSize: 14, color: AppColors.mute),
                          ),
                        ],
                      ),
                    ),
                    Tag(c.stageName, tone: TagTone.bronze),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _parentTile(male: true, ring: c.maleRing, fallback: c.maleLabel)),
                    const SizedBox(width: 10),
                    Expanded(child: _parentTile(male: false, ring: c.femaleRing, fallback: c.femaleLabel)),
                  ],
                ),
                const SizedBox(height: 14),
                StageBar(stage: c.stage),
              ],
            ),
          ),
          if (c.maleRing != null && c.femaleRing != null) ...[
            const SectionLabel('Consanguinité attendue des jeunes'),
            Builder(builder: (context) {
              final coi = widget.appState.offspringInbreeding(c.maleRing, c.femaleRing);
              return InfoBanner(
                '${formatPercent(coi)} — ${inbreedingLevel(coi)}. Calcul sur les ancêtres connus.',
                warning: coi >= kInbreedingWarningThreshold,
              );
            }),
          ],
          const SectionLabel('Étape actuelle'),
          Text(c.stageName, style: const TextStyle(fontWeight: FontWeight.w600)),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(14),
            decoration: AppDecor.card(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.stage < 2)
                  const Text('Observer la compatibilité avant l’accouplement.', style: TextStyle(color: AppColors.mute, fontSize: 13)),
                if (c.stage >= 2)
                  TextField(
                    controller: _eggsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Nombre d'œufs"),
                  ),
                if (c.stage >= 3) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _incubDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setState(() => _incubDate = picked);
                    },
                    child: Text(_incubDate == null
                        ? 'Début d’incubation'
                        : '${_incubDate!.day.toString().padLeft(2, '0')}/${_incubDate!.month.toString().padLeft(2, '0')}/${_incubDate!.year}'),
                  ),
                ],
                if (c.stage >= 4) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _chicksCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Poussins éclos'),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: () => _advance(c), child: Text(btnLabel)),
                ),
              ],
            ),
          ),
          if (c.history.isNotEmpty) ...[
            const SectionLabel('Historique des pontes'),
            for (final h in c.history)
              InfoCard(
                leading: IconTile(name: 'egg', size: 34),
                title: h,
                dense: true,
              ),
          ],
        ],
      ),
    );
  }
}
