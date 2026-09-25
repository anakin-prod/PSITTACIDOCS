import 'package:flutter/material.dart';

import '../logic/inbreeding.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'couple_detail_screen.dart';

class NewCoupleScreen extends StatefulWidget {
  final AppState appState;
  const NewCoupleScreen({super.key, required this.appState});

  @override
  State<NewCoupleScreen> createState() => _NewCoupleScreenState();
}

class _NewCoupleScreenState extends State<NewCoupleScreen> {
  String? _male;
  String? _female;
  bool _confirmOk = false;
  String? _error;

  Future<void> _save() async {
    setState(() => _error = null);
    if (_male == null || _female == null) {
      setState(() => _error = 'Choisissez un mâle et une femelle.');
      return;
    }
    final info = widget.appState.compatInfo(_male, _female);
    if (info.hasBlocking) return;
    if (info.hasWarnings && !_confirmOk) {
      setState(() => _error = 'Confirmez que vous avez pris connaissance de l’alerte ci-dessus.');
      return;
    }
    final couple = await widget.appState.formCouple(_male!, _female!);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CoupleDetailScreen(appState: widget.appState, coupleId: couple.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final paired = appState.pairedRings;
    final males = appState.birds.where((b) => b.sex == 'M' && !b.isCeded && !paired.contains(b.ring)).toList();
    final females = appState.birds.where((b) => b.sex == 'F' && !b.isCeded && !paired.contains(b.ring)).toList();
    final info = appState.compatInfo(_male, _female);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau couple')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _male,
                  decoration: const InputDecoration(labelText: 'Mâle'),
                  items: [
                    for (final b in males)
                      DropdownMenuItem(
                        value: b.ring,
                        child: Text('${b.ring} · ${appState.speciesBySci(b.sci)?.label ?? b.sci}'),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _male = v;
                    _confirmOk = false;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _female,
                  decoration: const InputDecoration(labelText: 'Femelle'),
                  items: [
                    for (final b in females)
                      DropdownMenuItem(
                        value: b.ring,
                        child: Text('${b.ring} · ${appState.speciesBySci(b.sci)?.label ?? b.sci}'),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _female = v;
                    _confirmOk = false;
                    _error = null;
                  }),
                ),
              ],
            ),
          ),
          if (_male != null && _female != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Consanguinité attendue des jeunes : ${formatPercent(info.offspringInbreeding)} '
                '(${inbreedingLevel(info.offspringInbreeding).toLowerCase()}), calculée sur les ancêtres connus.',
                style: const TextStyle(fontSize: 12, color: AppColors.mute),
              ),
            ),
            for (final m in info.blocking)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(m, style: const TextStyle(color: AppColors.red, fontSize: 13)),
              ),
            if (info.hasWarnings) ...[
              InfoBanner(info.warnings.join('\n'), warning: true),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _confirmOk,
                onChanged: (v) => setState(() => _confirmOk = v ?? false),
                title: const Text(
                  'Je confirme vouloir former ce couple malgré cette alerte',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
            if (!info.hasBlocking && !info.hasWarnings)
              const InfoBanner('Aucune incompatibilité détectée entre ces deux oiseaux.'),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Former le couple')),
        ],
      ),
    );
  }
}
