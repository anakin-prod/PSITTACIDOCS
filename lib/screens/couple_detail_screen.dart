import 'package:flutter/material.dart';

import '../models/couple.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
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

  String _label(String? ring, String? fallback) {
    if (ring != null) {
      final b = widget.appState.findBird(ring);
      if (b != null) {
        final sp = widget.appState.speciesBySci(b.sci);
        return '${b.ring} · ${sp?.label ?? b.sci}';
      }
    }
    return fallback ?? '—';
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
        padding: const EdgeInsets.all(16),
        children: [
          Text(c.id, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          InfoCard(
            leading: const Icon(Icons.male, color: Colors.blue),
            title: _label(c.maleRing, c.maleLabel),
            subtitle: 'Mâle',
            onTap: c.maleRing == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BirdDetailScreen(appState: widget.appState, ring: c.maleRing!),
                    ),
                  ),
          ),
          InfoCard(
            leading: const Icon(Icons.female, color: Colors.pink),
            title: _label(c.femaleRing, c.femaleLabel),
            subtitle: 'Femelle',
            onTap: c.femaleRing == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BirdDetailScreen(appState: widget.appState, ring: c.femaleRing!),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(6, (i) {
              final filled = i <= c.stage;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: filled ? AppColors.bronze : AppColors.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SectionLabel('Étape actuelle'),
          Text(c.stageName, style: const TextStyle(fontWeight: FontWeight.w600)),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
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
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.navy,
                  child: Icon(iconFor('egg'), color: Colors.white, size: 16),
                ),
                title: h,
                dense: true,
              ),
          ],
        ],
      ),
    );
  }
}
