import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../models/breeding.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import '../widgets/gauges.dart';
import '../widgets/mini_chart.dart';
import '../widgets/animations.dart';

/// Relevés de température, d'humidité et d'éclairage des volières.
class EnvReadingsScreen extends StatefulWidget {
  final AppState appState;
  const EnvReadingsScreen({super.key, required this.appState});

  @override
  State<EnvReadingsScreen> createState() => _EnvReadingsScreenState();
}

class _EnvReadingsScreenState extends State<EnvReadingsScreen> {
  String? _location; // null = toutes les volières

  String _summary(EnvReading r) {
    final parts = <String>[
      if (r.temperature != null) '${formatNumber(r.temperature!)} °C',
      if (r.humidity != null) '${formatNumber(r.humidity!)} %',
      if (r.lightHours != null) '${formatNumber(r.lightHours!)} h de lumière',
    ];
    return parts.isEmpty ? 'Relevé' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final locations = <String>{
      ...appState.settings.volieres,
      ...appState.envReadings.map((r) => r.location),
    }.where((l) => l.isNotEmpty).toList();

    final filtered = appState.envReadings
        .where((r) => _location == null || r.location == _location)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final chrono = filtered.reversed.toList();
    final temps = [for (final r in chrono) if (r.temperature != null) r.temperature!];
    final hums = [for (final r in chrono) if (r.humidity != null) r.humidity!];
    final lights = [for (final r in chrono) if (r.lightHours != null) r.lightHours!];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions des volières'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nouveau relevé',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NewEnvReadingScreen(appState: appState, initialLocation: _location),
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: staggered([
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PillChoice(
                    label: const Text('Toutes'),
                    selected: _location == null,
                    onSelected: (_) => setState(() => _location = null),
                  ),
                ),
                for (final l in locations)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PillChoice(
                      label: Text(l),
                      selected: _location == l,
                      onSelected: (_) => setState(() => _location = l),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Dernier relevé en jauges animées : thermomètre (bleu → rouge selon la
          // température), goutte d'humidité, soleil pour la durée d'éclairage.
          if (filtered.isNotEmpty)
            Container(
              key: ValueKey('last-${filtered.first.id}'),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: AppDecor.card(radius: 20),
              child: Column(
                children: [
                  Text(
                    'Dernier relevé · ${filtered.first.location} · ${formatDateTime(DateTime.parse(filtered.first.date))}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.mute),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ThermometerGauge(value: filtered.first.temperature),
                      HumidityGauge(value: filtered.first.humidity),
                      LightGauge(hours: filtered.first.lightHours),
                    ],
                  ),
                ],
              ),
            ),
          if (_location == null && filtered.isNotEmpty)
            const InfoBanner('Choisis une volière pour afficher ses courbes.'),
          if (_location != null) ...[
            if (temps.isNotEmpty) MiniLineChart(title: 'Température', unit: '°C', values: temps),
            if (hums.isNotEmpty) MiniLineChart(title: 'Humidité', unit: '%', values: hums),
            if (lights.isNotEmpty) MiniLineChart(title: 'Durée d’éclairage', unit: 'h', values: lights),
          ],
          const SectionLabel('Relevés'),
          if (filtered.isEmpty)
            const EmptyHint('Aucun relevé pour l’instant. Touche + pour en ajouter un.'),
          for (final r in filtered)
            InfoCard(
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: r.temperature == null ? AppColors.navy : ambientTemperatureColor(r.temperature!), borderRadius: BorderRadius.circular(13)), child: Icon(iconFor('thermo'), color: Colors.white, size: 18)),
              title: _summary(r),
              subtitle: '${r.location} · ${formatDateTime(DateTime.parse(r.date))}'
                  '${r.notes.isNotEmpty ? ' · ${r.notes}' : ''}',
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.mute),
                tooltip: 'Supprimer',
                onPressed: () async {
                  final ok = await confirmDestructive(
                    context,
                    title: 'Supprimer ce relevé ?',
                    message: 'Le relevé du ${formatDateTime(DateTime.parse(r.date))} sera supprimé.',
                    confirmLabel: 'Supprimer',
                  );
                  if (!ok) return;
                  await appState.deleteEnvReading(r.id);
                  setState(() {});
                },
              ),
            ),
        ]),
      ),
    );
  }
}

/// Saisie d'un relevé de volière.
class NewEnvReadingScreen extends StatefulWidget {
  final AppState appState;
  final String? initialLocation;
  const NewEnvReadingScreen({super.key, required this.appState, this.initialLocation});

  @override
  State<NewEnvReadingScreen> createState() => _NewEnvReadingScreenState();
}

class _NewEnvReadingScreenState extends State<NewEnvReadingScreen> {
  String? _location;
  DateTime _date = DateTime.now();
  final _tempCtrl = TextEditingController();
  final _humCtrl = TextEditingController();
  final _lightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final volieres = widget.appState.settings.volieres;
    _location = volieres.contains(widget.initialLocation)
        ? widget.initialLocation
        : (volieres.isNotEmpty ? volieres.first : null);
  }

  @override
  void dispose() {
    _tempCtrl.dispose();
    _humCtrl.dispose();
    _lightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    setState(() => _date = DateTime(d.year, d.month, d.day, t?.hour ?? _date.hour, t?.minute ?? _date.minute));
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_location == null) {
      setState(() => _error = 'Ajoute d’abord une volière dans les Paramètres.');
      return;
    }
    final temp = parseNumber(_tempCtrl.text);
    final hum = parseNumber(_humCtrl.text);
    final light = parseNumber(_lightCtrl.text);
    if (temp == null && hum == null && light == null) {
      setState(() => _error = 'Indique au moins une mesure : température, humidité ou éclairage.');
      return;
    }
    if (hum != null && (hum < 0 || hum > 100)) {
      setState(() => _error = 'L’humidité doit être comprise entre 0 et 100 %.');
      return;
    }
    if (light != null && (light < 0 || light > 24)) {
      setState(() => _error = 'La durée d’éclairage doit être comprise entre 0 et 24 h.');
      return;
    }
    await widget.appState.addEnvReading(EnvReading(
      id: widget.appState.nextId(),
      date: isoDateTime(_date),
      location: _location!,
      temperature: temp,
      humidity: hum,
      lightHours: light,
      notes: _notesCtrl.text.trim(),
    ));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final volieres = widget.appState.settings.volieres;
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau relevé')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _location,
            decoration: const InputDecoration(labelText: 'Volière'),
            items: [for (final v in volieres) DropdownMenuItem(value: v, child: Text(v))],
            onChanged: (v) => setState(() => _location = v),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(formatDateTime(_date)),
            onPressed: _pickDateTime,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tempCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(labelText: 'Température (°C)', hintText: 'ex. 22,5'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _humCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Humidité (%)', hintText: 'ex. 60'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Durée d’éclairage (heures sur la journée)', hintText: 'ex. 12'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes — facultatif'),
          ),
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
