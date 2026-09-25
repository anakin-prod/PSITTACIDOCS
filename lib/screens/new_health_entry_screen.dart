import 'package:flutter/material.dart';

import '../models/bird_document.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class NewHealthEntryScreen extends StatefulWidget {
  final AppState appState;
  final String ring;
  const NewHealthEntryScreen({super.key, required this.appState, required this.ring});

  @override
  State<NewHealthEntryScreen> createState() => _NewHealthEntryScreenState();
}

class _NewHealthEntryScreenState extends State<NewHealthEntryScreen> {
  String _type = 'Pesée';
  DateTime _date = DateTime.now();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _error;

  static const _types = ['Pesée', 'Traitement', 'Visite vétérinaire', 'Vaccination', 'Autre'];

  Future<void> _save() async {
    setState(() => _error = null);
    if (_type == 'Pesée' && _weightCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Indiquez le poids mesuré.');
      return;
    }
    final bird = widget.appState.findBird(widget.ring);
    if (bird == null) return;
    await widget.appState.addHealthEntry(
      bird,
      HealthEntry(
        id: widget.appState.nextId(),
        date: _date.toIso8601String().substring(0, 10),
        type: _type,
        weight: _type == 'Pesée' ? double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')) : null,
        notes: _notesCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bird = widget.appState.findBird(widget.ring);
    final sp = bird == null ? null : widget.appState.speciesBySci(bird.sci);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle entrée')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${bird?.ring ?? ''} · ${sp?.label ?? ''}', style: const TextStyle(color: AppColors.mute)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [for (final t in _types) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(1990),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Text('${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
          ),
          if (_type == 'Pesée') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Poids (g)', hintText: 'ex. 248'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes — facultatif'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: const TextStyle(color: AppColors.red)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Ajouter au journal')),
        ],
      ),
    );
  }
}
