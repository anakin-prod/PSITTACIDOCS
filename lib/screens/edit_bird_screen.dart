import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/bird.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';

class EditBirdScreen extends StatefulWidget {
  final AppState appState;
  final String ring;
  const EditBirdScreen({super.key, required this.appState, required this.ring});

  @override
  State<EditBirdScreen> createState() => _EditBirdScreenState();
}

class _EditBirdScreenState extends State<EditBirdScreen> {
  late Bird bird;
  late TextEditingController _ringCtrl;
  late TextEditingController _mutCtrl;
  late TextEditingController _diamCtrl;
  late TextEditingController _notesCtrl;
  late String _ringType;
  late String _sex;
  late String _status;
  late String? _location;
  DateTime? _born;
  String? _photoPath;
  String? _error;

  static const _statuses = [
    'Jeune', 'Reproducteur', 'Reproductrice', 'Au repos', 'À céder', 'En quarantaine', 'Cédé',
  ];

  @override
  void initState() {
    super.initState();
    bird = widget.appState.findBird(widget.ring)!;
    _ringCtrl = TextEditingController(text: bird.ring);
    _mutCtrl = TextEditingController(text: bird.mutation);
    _diamCtrl = TextEditingController(text: bird.ringDiameter);
    _notesCtrl = TextEditingController(text: bird.notes);
    _ringType = bird.ringType.isEmpty ? 'Fermée' : bird.ringType;
    _sex = bird.sex;
    _status = bird.status;
    _location = widget.appState.settings.volieres.contains(bird.location) ? bird.location : null;
    _born = bird.born.isEmpty ? null : DateTime.tryParse(bird.born);
    _photoPath = bird.photoPath;
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(picked.path).copy('${dir.path}/$fileName');
    setState(() => _photoPath = saved.path);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final newRing = _ringCtrl.text.trim();
    if (_ringType != 'Aucune' && newRing.isEmpty) {
      setState(() => _error = 'Indiquez le numéro de bague, ou choisissez « Aucune ».');
      return;
    }
    if (newRing.isNotEmpty && widget.appState.ringExists(newRing, excluding: bird)) {
      setState(() => _error = 'Ce numéro de bague est déjà utilisé par un autre oiseau.');
      return;
    }
    if (newRing.isNotEmpty && newRing != bird.ring) {
      await widget.appState.renameBirdRing(bird, newRing);
    }
    bird.ringType = _ringType;
    bird.ringDiameter = _diamCtrl.text.trim();
    bird.sex = _sex;
    bird.mutation = _mutCtrl.text.trim();
    bird.born = _born == null ? '' : _born!.toIso8601String().substring(0, 10);
    bird.location = _location ?? '';
    bird.status = _status;
    bird.photoPath = _photoPath;
    bird.notes = _notesCtrl.text.trim();
    await widget.appState.updateBird(bird);
    if (!mounted) return;
    // On renvoie la bague (éventuellement renommée) à la fiche appelante,
    // qui se rafraîchit elle-même : on ne remplace pas l'écran, on revient
    // simplement en arrière pour ne pas laisser une fiche obsolète dans la pile.
    Navigator.of(context).pop(bird.ring);
  }

  Future<void> _delete() async {
    final ok = await confirmDestructive(
      context,
      title: 'Supprimer ${bird.ring} ?',
      message: 'Cette action est définitive. ${bird.ring} sera retiré de l’élevage et de l’historique.',
    );
    if (!ok) return;
    await widget.appState.deleteBird(bird);
    if (!mounted) return;
    Navigator.of(context)
      ..pop()
      ..pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Modifier ${bird.ring}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
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
                  child: _photoPath == null ? const Icon(Icons.photo_camera_outlined) : null,
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
            TextField(controller: _ringCtrl, decoration: const InputDecoration(labelText: 'Numéro de bague')),
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
            _segmented(['M', 'F', ''], _sex, (v) => setState(() => _sex = v),
                labels: const {'M': 'Mâle', 'F': 'Femelle', '': 'Inconnu'}),
          ]),
          _box('Description', [
            TextField(controller: _mutCtrl, decoration: const InputDecoration(labelText: 'Mutation')),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _born ?? DateTime.now(),
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _born = picked);
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_born == null ? 'Date de naissance' : formatIso(_born!.toIso8601String())),
              ),
            ),
          ]),
          _box('Au quotidien', [
            DropdownButtonFormField<String>(
              initialValue: _location,
              decoration: const InputDecoration(labelText: 'Emplacement'),
              items: [
                for (final v in widget.appState.settings.volieres)
                  DropdownMenuItem(value: v, child: Text(v)),
              ],
              onChanged: (v) => setState(() => _location = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: [for (final v in _statuses) DropdownMenuItem(value: v, child: Text(v))],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
          ]),
          _box('Notes', [
            TextField(controller: _notesCtrl, maxLines: 3),
          ]),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
            ),
          ElevatedButton(onPressed: _save, child: const Text('Enregistrer les modifications')),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF0B4B4)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Zone de danger', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
                  onPressed: _delete,
                  child: const Text('Supprimer cet oiseau'),
                ),
              ],
            ),
          ),
        ],
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
