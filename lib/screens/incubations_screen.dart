import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../models/breeding.dart';
import '../models/species.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'incubation_detail_screen.dart';
import 'species_picker_screen.dart';

/// Liste des incubations (en cours puis terminées).
class IncubationsScreen extends StatefulWidget {
  final AppState appState;
  const IncubationsScreen({super.key, required this.appState});

  @override
  State<IncubationsScreen> createState() => _IncubationsScreenState();
}

class _IncubationsScreenState extends State<IncubationsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final active = appState.incubations.where((i) => i.isActive).toList();
    final done = appState.incubations.where((i) => !i.isActive).toList();

    Widget tile(Incubation inc) {
      final sp = inc.sci.isEmpty ? null : appState.speciesBySci(inc.sci);
      final subtitle = inc.isActive
          ? 'Jour ${inc.dayNumber} sur ${inc.incubationDays} · éclosion prévue le ${formatDate(inc.expectedHatch)}'
          : 'Terminée · ${inc.hatched} éclos sur ${inc.eggs} œuf${inc.eggs > 1 ? 's' : ''}';
      return InfoCard(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: inc.isActive ? AppColors.navy : AppColors.mute,
          child: Icon(iconFor('egg'), color: Colors.white, size: 18),
        ),
        title: '${inc.label}${sp != null ? ' · ${sp.label}' : ''}',
        subtitle: subtitle,
        trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => IncubationDetailScreen(appState: appState, incubationId: inc.id)),
          );
          setState(() {});
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incubation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nouvelle incubation',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => NewIncubationScreen(appState: appState)),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionLabel('En cours'),
          if (active.isEmpty) const EmptyHint('Aucune incubation en cours. Touche + pour en démarrer une.'),
          for (final i in active) tile(i),
          if (done.isNotEmpty) ...[
            const SectionLabel('Terminées'),
            for (final i in done) tile(i),
          ],
        ],
      ),
    );
  }
}

/// Démarrage d'une nouvelle incubation.
class NewIncubationScreen extends StatefulWidget {
  final AppState appState;
  const NewIncubationScreen({super.key, required this.appState});

  @override
  State<NewIncubationScreen> createState() => _NewIncubationScreenState();
}

class _NewIncubationScreenState extends State<NewIncubationScreen> {
  final _labelCtrl = TextEditingController(text: 'Couveuse 1');
  String? _coupleId;
  Species? _species;
  final _eggsCtrl = TextEditingController();
  DateTime _start = DateTime.now();
  final _daysCtrl = TextEditingController();
  final _tMinCtrl = TextEditingController();
  final _tMaxCtrl = TextEditingController();
  final _hMinCtrl = TextEditingController();
  final _hMaxCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_labelCtrl, _eggsCtrl, _daysCtrl, _tMinCtrl, _tMaxCtrl, _hMinCtrl, _hMaxCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onCoupleChanged(String? id) {
    setState(() {
      _coupleId = id;
      final c = id == null ? null : widget.appState.findCouple(id);
      if (c != null) {
        final sp = widget.appState.speciesBySci(c.sci);
        if (sp != null) _species = sp;
        if (c.eggs > 0 && _eggsCtrl.text.trim().isEmpty) _eggsCtrl.text = '${c.eggs}';
      }
    });
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final days = int.tryParse(_daysCtrl.text.trim());
    if (_labelCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Donne un nom à la couveuse (ex. « Couveuse 1 »).');
      return;
    }
    if (days == null || days <= 0 || days > 60) {
      setState(() => _error = 'Indique la durée d’incubation prévue, en jours (entre 1 et 60).');
      return;
    }
    final tMin = parseNumber(_tMinCtrl.text), tMax = parseNumber(_tMaxCtrl.text);
    final hMin = parseNumber(_hMinCtrl.text), hMax = parseNumber(_hMaxCtrl.text);
    if (tMin != null && tMax != null && tMin > tMax) {
      setState(() => _error = 'La température minimale est supérieure à la maximale.');
      return;
    }
    if (hMin != null && hMax != null && hMin > hMax) {
      setState(() => _error = 'L’humidité minimale est supérieure à la maximale.');
      return;
    }
    final inc = Incubation(
      id: widget.appState.nextId(),
      label: _labelCtrl.text.trim(),
      coupleId: _coupleId,
      sci: _species?.sci ?? '',
      eggs: int.tryParse(_eggsCtrl.text.trim()) ?? 0,
      startDate: _start.toIso8601String().substring(0, 10),
      incubationDays: days,
      targetTempMin: tMin,
      targetTempMax: tMax,
      targetHumMin: hMin,
      targetHumMax: hMax,
      notes: _notesCtrl.text.trim(),
    );
    await widget.appState.addIncubation(inc);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => IncubationDetailScreen(appState: widget.appState, incubationId: inc.id)),
    );
  }

  Widget _range(String label, TextEditingController min, TextEditingController max, String unit) => Row(
    children: [
      Expanded(
        child: TextField(
          controller: min,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '$label min ($unit)'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: max,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '$label max ($unit)'),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle incubation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _labelCtrl, decoration: const InputDecoration(labelText: 'Couveuse')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _coupleId,
            decoration: const InputDecoration(labelText: 'Couple — facultatif'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Aucun')),
              for (final c in appState.couples)
                DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.id}${appState.speciesBySci(c.sci) != null ? ' · ${appState.speciesBySci(c.sci)!.label}' : ''}'),
                ),
            ],
            onChanged: _onCoupleChanged,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final s = await Navigator.of(context).push<Species>(
                MaterialPageRoute(builder: (_) => SpeciesPickerScreen(appState: appState)),
              );
              if (s != null) setState(() => _species = s);
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_species == null ? 'Espèce — facultatif' : _species!.label),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _eggsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nombre d’œufs'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _daysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Durée prévue (jours)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.event, size: 18),
            label: Text('Mise en incubation le ${formatDate(_start)}'),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _start,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (d != null) setState(() => _start = d);
            },
          ),
          const SectionLabel('Consignes — facultatif'),
          const Text(
            'Les plages dépendent de l’espèce et de ta couveuse : l’appli ne propose pas de valeurs '
            'par défaut. Si tu les renseignes, les relevés hors plage seront signalés.',
            style: TextStyle(fontSize: 12, color: AppColors.mute),
          ),
          const SizedBox(height: 10),
          _range('Température', _tMinCtrl, _tMaxCtrl, '°C'),
          const SizedBox(height: 12),
          _range('Humidité', _hMinCtrl, _hMaxCtrl, '%'),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes — facultatif')),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: const TextStyle(color: AppColors.red)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Démarrer l’incubation')),
        ],
      ),
    );
  }
}
