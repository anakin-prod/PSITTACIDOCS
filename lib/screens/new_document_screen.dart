import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/bird_document.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const kDocTypes = [
  'Certificat de cession',
  'Facture',
  'Certificat de baguage',
  'Document CITES',
  'Certificat vétérinaire',
  'Autre',
];

class NewDocumentScreen extends StatefulWidget {
  final AppState appState;
  final String? initialRing;
  const NewDocumentScreen({super.key, required this.appState, this.initialRing});

  @override
  State<NewDocumentScreen> createState() => _NewDocumentScreenState();
}

class _NewDocumentScreenState extends State<NewDocumentScreen> {
  String? _ring;
  String _type = kDocTypes.first;
  String? _fileName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ring = widget.initialRing;
  }

  Future<void> _pickFile() async {
    // API file_picker v13 : pickFile() renvoie le fichier choisi, ou null si
    // l'utilisateur a annulé.
    final file = await FilePicker.pickFile();
    if (file != null) {
      setState(() => _fileName = file.name);
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_ring == null) {
      setState(() => _error = 'Choisissez un oiseau.');
      return;
    }
    if (_fileName == null) {
      setState(() => _error = 'Choisissez un fichier à joindre.');
      return;
    }
    final bird = widget.appState.findBird(_ring);
    if (bird == null) return;
    await widget.appState.addDocument(bird, BirdDocument(type: _type, fileName: _fileName!));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau document')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _ring,
            decoration: const InputDecoration(labelText: 'Oiseau concerné'),
            items: [
              for (final b in appState.birds)
                DropdownMenuItem(
                  value: b.ring,
                  child: Text('${b.ring} · ${appState.speciesBySci(b.sci)?.label ?? b.sci}'),
                ),
            ],
            onChanged: (v) => setState(() => _ring = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type de document'),
            items: [for (final t in kDocTypes) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.attach_file, size: 18),
            label: Text(_fileName ?? 'Choisir un fichier'),
            onPressed: _pickFile,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: const TextStyle(color: AppColors.red)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Ajouter le document')),
        ],
      ),
    );
  }
}
