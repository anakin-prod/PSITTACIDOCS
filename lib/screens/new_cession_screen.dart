import 'package:flutter/material.dart';

import '../models/bird_document.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class NewCessionScreen extends StatefulWidget {
  final AppState appState;
  const NewCessionScreen({super.key, required this.appState});

  @override
  State<NewCessionScreen> createState() => _NewCessionScreenState();
}

class _NewCessionScreenState extends State<NewCessionScreen> {
  String? _ring;
  final _buyerCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  final _priceCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _error;

  Future<void> _save() async {
    setState(() => _error = null);
    if (_ring == null) {
      setState(() => _error = 'Choisissez un oiseau.');
      return;
    }
    if (_buyerCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Indiquez le nouveau propriétaire.');
      return;
    }
    final bird = widget.appState.findBird(_ring);
    if (bird == null) return;
    await widget.appState.registerCession(
      bird,
      Cession(
        buyer: _buyerCtrl.text.trim(),
        date: _date.toIso8601String().substring(0, 10),
        price: _priceCtrl.text.trim(),
        contact: _contactCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.appState.birds.where((b) => !b.isCeded).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle cession')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _ring,
            decoration: const InputDecoration(labelText: 'Oiseau cédé'),
            items: [
              for (final b in available)
                DropdownMenuItem(
                  value: b.ring,
                  child: Text('${b.ring} · ${widget.appState.speciesBySci(b.sci)?.label ?? b.sci}'),
                ),
            ],
            onChanged: (v) => setState(() => _ring = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _buyerCtrl,
            decoration: const InputDecoration(labelText: 'Nouveau propriétaire', hintText: 'Nom, élevage ou particulier'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: Text('${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: 'Prix', hintText: 'facultatif'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactCtrl,
            decoration: const InputDecoration(labelText: 'Contact — facultatif'),
          ),
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
          ElevatedButton(onPressed: _save, child: const Text('Enregistrer la cession')),
        ],
      ),
    );
  }
}
