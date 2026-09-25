import 'package:flutter/material.dart';

import '../models/agenda_event.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class NewEventScreen extends StatefulWidget {
  final AppState appState;
  const NewEventScreen({super.key, required this.appState});

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  final _titleCtrl = TextEditingController();
  String _type = kEventTypeIcons.keys.first;
  DateTime? _date;
  final _notesCtrl = TextEditingController();
  String? _error;

  Future<void> _save() async {
    setState(() => _error = null);
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Donnez un titre à l’événement.');
      return;
    }
    if (_date == null) {
      setState(() => _error = 'Choisissez une date.');
      return;
    }
    await widget.appState.addEvent(
      AgendaEvent(
        id: widget.appState.nextId(),
        title: _titleCtrl.text.trim(),
        type: _type,
        date: _date!.toIso8601String().substring(0, 10),
        notes: _notesCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel événement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titre', hintText: 'ex. Vermifuge des jeunes'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [for (final t in kEventTypeIcons.keys) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_date == null
                  ? 'Date'
                  : '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes — facultatif', hintText: 'Précisions, oiseaux concernés…'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: const TextStyle(color: AppColors.red)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Ajouter à l’agenda')),
        ],
      ),
    );
  }
}
