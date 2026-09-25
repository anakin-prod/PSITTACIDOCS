import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../models/breeding.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import '../widgets/mini_chart.dart';

class IncubationDetailScreen extends StatefulWidget {
  final AppState appState;
  final String incubationId;
  const IncubationDetailScreen({super.key, required this.appState, required this.incubationId});

  @override
  State<IncubationDetailScreen> createState() => _IncubationDetailScreenState();
}

class _IncubationDetailScreenState extends State<IncubationDetailScreen> {
  String _range(double? min, double? max, String unit) {
    if (min == null && max == null) return 'non définie';
    if (min != null && max != null) return '${formatNumber(min)} à ${formatNumber(max)} $unit';
    if (min != null) return 'au moins ${formatNumber(min)} $unit';
    return 'au plus ${formatNumber(max!)} $unit';
  }

  Future<void> _addReading(Incubation inc) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NewIncubatorReadingScreen(appState: widget.appState, incubation: inc)),
    );
    if (added == true) setState(() {});
  }

  Future<void> _finish(Incubation inc) async {
    final ctrl = TextEditingController(text: '${inc.eggs}');
    final hatched = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer l’incubation'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nombre de poussins éclos'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text.trim()) ?? 0),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (hatched == null) return;
    await widget.appState.finishIncubation(inc, hatched);
    setState(() {});
  }

  Future<void> _delete(Incubation inc) async {
    final ok = await confirmDestructive(
      context,
      title: 'Supprimer cette incubation ?',
      message: '« ${inc.label} » et tous ses relevés seront supprimés.',
    );
    if (!ok) return;
    await widget.appState.deleteIncubation(inc.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final inc = appState.findIncubation(widget.incubationId);
    if (inc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incubation')),
        body: const Center(child: Text('Cette incubation n’existe plus.')),
      );
    }
    final sp = inc.sci.isEmpty ? null : appState.speciesBySci(inc.sci);
    final readings = inc.readingsSortedAsc;
    final last = readings.isEmpty ? null : readings.last;
    final temps = [for (final r in readings) if (r.temperature != null) r.temperature!];
    final hums = [for (final r in readings) if (r.humidity != null) r.humidity!];
    final progress = inc.incubationDays <= 0 ? 0.0 : (inc.dayNumber / inc.incubationDays).clamp(0.0, 1.0).toDouble();

    final alerts = <String>[
      if (last != null && inc.tempOutOfRange(last.temperature))
        'Dernière température hors plage : ${formatNumber(last.temperature!)} °C '
            '(consigne ${_range(inc.targetTempMin, inc.targetTempMax, '°C')}).',
      if (last != null && inc.humOutOfRange(last.humidity))
        'Dernière humidité hors plage : ${formatNumber(last.humidity!)} % '
            '(consigne ${_range(inc.targetHumMin, inc.targetHumMax, '%')}).',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incubation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
            onPressed: () => _delete(inc),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(inc.label, style: Theme.of(context).textTheme.headlineSmall),
          if (sp != null)
            Text(sp.label, style: const TextStyle(color: AppColors.mute)),
          const SizedBox(height: 12),
          if (inc.isActive) ...[
            Text(
              'Jour ${inc.dayNumber} sur ${inc.incubationDays}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.line,
                color: AppColors.bronze,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Éclosion prévue le ${formatDate(inc.expectedHatch)} · ${appState.relativeLabel(inc.expectedHatch.toIso8601String().substring(0, 10))}',
              style: const TextStyle(fontSize: 12, color: AppColors.mute),
            ),
          ] else
            InfoBanner('Incubation terminée : ${inc.hatched} éclos sur ${inc.eggs} œuf${inc.eggs > 1 ? 's' : ''}.'),
          for (final a in alerts) InfoBanner(a, warning: true),
          const SectionLabel('Consignes'),
          Text('Température : ${_range(inc.targetTempMin, inc.targetTempMax, '°C')}', style: const TextStyle(fontSize: 13)),
          Text('Humidité : ${_range(inc.targetHumMin, inc.targetHumMax, '%')}', style: const TextStyle(fontSize: 13)),
          Text(
            'Mise en incubation le ${formatDate(inc.start)} · ${inc.eggs} œuf${inc.eggs > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 13),
          ),
          if (inc.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(inc.notes, style: const TextStyle(fontSize: 13, color: AppColors.mute)),
            ),
          const SectionLabel('Courbes'),
          MiniLineChart(
            title: 'Température',
            unit: '°C',
            values: temps,
            targetMin: inc.targetTempMin,
            targetMax: inc.targetTempMax,
          ),
          MiniLineChart(
            title: 'Humidité',
            unit: '%',
            values: hums,
            targetMin: inc.targetHumMin,
            targetMax: inc.targetHumMax,
          ),
          const SectionLabel('Relevés'),
          if (readings.isEmpty) const EmptyHint('Aucun relevé pour l’instant.'),
          for (final r in readings.reversed)
            InfoCard(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: (inc.tempOutOfRange(r.temperature) || inc.humOutOfRange(r.humidity))
                    ? AppColors.red
                    : AppColors.navy,
                child: Icon(iconFor('thermo'), color: Colors.white, size: 16),
              ),
              title: [
                if (r.temperature != null) '${formatNumber(r.temperature!)} °C',
                if (r.humidity != null) '${formatNumber(r.humidity!)} %',
                if (r.turns != null) '${r.turns} retournement${r.turns! > 1 ? 's' : ''}',
              ].join(' · '),
              subtitle: formatDateTime(DateTime.parse(r.date)) + (r.notes.isNotEmpty ? ' · ${r.notes}' : ''),
            ),
          const SizedBox(height: 12),
          if (inc.isActive) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un relevé'),
              onPressed: () => _addReading(inc),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () => _finish(inc), child: const Text('Terminer l’incubation')),
          ],
        ],
      ),
    );
  }
}

/// Saisie d'un relevé de couveuse. Renvoie true si un relevé a été ajouté.
class NewIncubatorReadingScreen extends StatefulWidget {
  final AppState appState;
  final Incubation incubation;
  const NewIncubatorReadingScreen({super.key, required this.appState, required this.incubation});

  @override
  State<NewIncubatorReadingScreen> createState() => _NewIncubatorReadingScreenState();
}

class _NewIncubatorReadingScreenState extends State<NewIncubatorReadingScreen> {
  DateTime _date = DateTime.now();
  final _tempCtrl = TextEditingController();
  final _humCtrl = TextEditingController();
  final _turnsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_tempCtrl, _humCtrl, _turnsCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final temp = parseNumber(_tempCtrl.text);
    final hum = parseNumber(_humCtrl.text);
    final turns = int.tryParse(_turnsCtrl.text.trim());
    if (temp == null && hum == null && turns == null) {
      setState(() => _error = 'Indique au moins une mesure : température, humidité ou retournements.');
      return;
    }
    if (hum != null && (hum < 0 || hum > 100)) {
      setState(() => _error = 'L’humidité doit être comprise entre 0 et 100 %.');
      return;
    }
    await widget.appState.addIncubatorReading(
      widget.incubation,
      IncubatorReading(
        id: widget.appState.nextId(),
        date: isoDateTime(_date),
        temperature: temp,
        humidity: hum,
        turns: turns,
        notes: _notesCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relevé de couveuse')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(formatDateTime(_date)),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (d == null || !context.mounted) return;
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
              setState(() => _date = DateTime(d.year, d.month, d.day, t?.hour ?? _date.hour, t?.minute ?? _date.minute));
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tempCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Température (°C)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _humCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Humidité (%)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _turnsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Retournements depuis le relevé précédent'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes — facultatif')),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: const TextStyle(color: AppColors.red)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Enregistrer le relevé')),
        ],
      ),
    );
  }
}
