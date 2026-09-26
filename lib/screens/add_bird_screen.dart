import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/bird.dart';
import '../models/species.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'bird_detail_screen.dart';
import 'species_picker_screen.dart';
import '../widgets/common.dart';

class AddBirdScreen extends StatefulWidget {
  final AppState appState;
  const AddBirdScreen({super.key, required this.appState});

  @override
  State<AddBirdScreen> createState() => _AddBirdScreenState();
}

class _AddBirdScreenState extends State<AddBirdScreen> {
  Species? _species;
  final _ringCtrl = TextEditingController();
  String _ringType = 'Fermée';
  final _diamCtrl = TextEditingController();
  String _sex = '';
  final _mutCtrl = TextEditingController(text: 'Ancestral');
  DateTime? _born;
  bool _bornEstimated = false;
  String _origin = 'Né à l’élevage';
  String? _fatherRing;
  String? _motherRing;
  bool _quarantine = false;
  final _quarDaysCtrl = TextEditingController(text: '30');
  String? _location;
  String _status = 'Jeune';
  final _notesCtrl = TextEditingController();
  String? _photoPath;
  String? _error;

  static const _origins = ['Né à l’élevage', 'Acheté', 'Échange', 'Don'];
  static const _statuses = ['Jeune', 'Reproducteur', 'Reproductrice', 'Au repos', 'À céder'];

  @override
  void initState() {
    super.initState();
    _location = widget.appState.settings.volieres.isNotEmpty
        ? widget.appState.settings.volieres.first
        : null;
  }

  Future<void> _pickSpecies() async {
    final s = await Navigator.of(context).push<Species>(
      MaterialPageRoute(builder: (_) => SpeciesPickerScreen(appState: widget.appState)),
    );
    if (s != null) {
      setState(() {
        if (_species?.sci != s.sci) {
          _fatherRing = null;
          _motherRing = null;
        }
        _species = s;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(picked.path).copy('${dir.path}/$fileName');
    setState(() => _photoPath = saved.path);
  }

  void _save() {
    setState(() => _error = null);
    if (_species == null) {
      setState(() => _error = 'Choisissez une espèce.');
      return;
    }
    final ring = _ringCtrl.text.trim().isNotEmpty
        ? _ringCtrl.text.trim()
        : 'SB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    if (_ringType != 'Aucune' && widget.appState.ringExists(ring)) {
      setState(() => _error = 'Ce numéro de bague est déjà utilisé par un autre oiseau.');
      return;
    }
    if (_sex.isEmpty) {
      setState(() => _error = 'Indiquez le sexe (ou choisissez Inconnu).');
      return;
    }

    String? quarUntil;
    if (_quarantine) {
      final days = int.tryParse(_quarDaysCtrl.text.trim()) ?? 30;
      quarUntil = DateTime.now().add(Duration(days: days)).toIso8601String().substring(0, 10);
    }

    final bird = Bird(
      ring: ring,
      sci: _species!.sci,
      mutation: _mutCtrl.text.trim().isEmpty ? 'Ancestral' : _mutCtrl.text.trim(),
      sex: _sex == '?' ? '' : _sex,
      born: _born == null ? '' : _born!.toIso8601String().substring(0, 10),
      bornEstimated: _bornEstimated,
      origin: _origin,
      status: _quarantine ? 'En quarantaine' : _status,
      fatherRing: _origin == 'Né à l’élevage' ? _fatherRing : null,
      motherRing: _origin == 'Né à l’élevage' ? _motherRing : null,
      ringType: _ringType,
      ringDiameter: _diamCtrl.text.trim(),
      location: _location ?? '',
      photoPath: _photoPath,
      notes: _notesCtrl.text.trim(),
      quarantineUntil: quarUntil,
    );

    widget.appState.addBird(bird);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => BirdDetailScreen(appState: widget.appState, ring: ring)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final fatherOptions = _species == null
        ? <String>[]
        : appState.birds.where((b) => b.sci == _species!.sci && b.sex == 'M').map((b) => b.ring).toList();
    final motherOptions = _species == null
        ? <String>[]
        : appState.birds.where((b) => b.sci == _species!.sci && b.sex == 'F').map((b) => b.ring).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un oiseau')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          _box('Espèce', [
            OutlinedButton(
              onPressed: _pickSpecies,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_species == null ? 'Choisir une espèce…' : _species!.label),
              ),
            ),
            if (_species != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_species!.sci, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: AppColors.mute)),
              ),
          ]),
          _box('Photo', [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6E3E1),
                    borderRadius: BorderRadius.circular(14),
                    image: _photoPath != null
                        ? DecorationImage(image: FileImage(File(_photoPath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _photoPath == null
                      ? const Icon(Icons.photo_camera_outlined, color: Color(0xFFB98A8E))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickPhoto,
                    child: Text(_photoPath == null ? 'Ajouter une photo' : 'Changer la photo'),
                  ),
                ),
              ],
            ),
          ]),
          _box('Bague', [
            TextField(
              controller: _ringCtrl,
              decoration: const InputDecoration(labelText: 'Numéro de bague'),
            ),
            const SizedBox(height: 10),
            _segmented(['Fermée', 'Ouverte', 'Aucune'], _ringType, (v) => setState(() => _ringType = v)),
            const SizedBox(height: 10),
            TextField(
              controller: _diamCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Diamètre (mm) — facultatif'),
            ),
          ]),
          _box('Sexe', [
            _segmented(['M', 'F', '?'], _sex, (v) => setState(() => _sex = v),
                labels: const {'M': 'Mâle', 'F': 'Femelle', '?': 'Inconnu'}),
          ]),
          _box('Description', [
            TextField(controller: _mutCtrl, decoration: const InputDecoration(labelText: 'Mutation')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _born ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _born = picked);
                    },
                    child: Text(_born == null ? 'Date de naissance' : formatIso(_born!.toIso8601String())),
                  ),
                ),
                Checkbox(value: _bornEstimated, onChanged: (v) => setState(() => _bornEstimated = v ?? false)),
                const Text('estimée', style: TextStyle(fontSize: 12)),
              ],
            ),
          ]),
          _box('Origine', [
            _segmented(_origins, _origin, (v) => setState(() => _origin = v)),
            if (_origin == 'Né à l’élevage') ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _fatherRing,
                decoration: const InputDecoration(labelText: 'Père'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Inconnu')),
                  for (final r in fatherOptions) DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: (v) => setState(() => _fatherRing = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _motherRing,
                decoration: const InputDecoration(labelText: 'Mère'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Inconnue')),
                  for (final r in motherOptions) DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: (v) => setState(() => _motherRing = v),
              ),
            ],
          ]),
          _box('Au quotidien', [
            DropdownButtonFormField<String>(
              initialValue: _location,
              decoration: const InputDecoration(labelText: 'Emplacement'),
              items: [
                for (final v in appState.settings.volieres) DropdownMenuItem(value: v, child: Text(v)),
              ],
              onChanged: (v) => setState(() => _location = v),
            ),
            const SizedBox(height: 10),
            if (!_quarantine)
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: [for (final v in _statuses) DropdownMenuItem(value: v, child: Text(v))],
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _quarantine,
              onChanged: (v) => setState(() => _quarantine = v),
              title: const Text('Placer en quarantaine', style: TextStyle(fontSize: 13)),
            ),
            if (_quarantine)
              TextField(
                controller: _quarDaysCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Durée (jours)'),
              ),
          ]),
          _box('Notes', [
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Caractère, alimentation, particularités…'),
            ),
          ]),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(onPressed: _save, child: const Text('Enregistrer l’oiseau')),
        ),
      ),
    );
  }

  Widget _box(String title, List<Widget> children) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: AppDecor.card(radius: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );

  Widget _segmented(
    List<String> values,
    String current,
    ValueChanged<String> onChanged, {
    Map<String, String>? labels,
  }) {
    return Row(
      children: [
        for (final v in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: PillChoice(
                label: Text(labels?[v] ?? v),
                selected: current == v,
                onSelected: (_) => onChanged(v),
              ),
            ),
          ),
      ],
    );
  }
}
