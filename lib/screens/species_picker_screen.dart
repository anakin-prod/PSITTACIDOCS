import 'package:flutter/material.dart';

import '../models/species.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Recherche et sélection d'une espèce parmi les 381 intégrées. Retourne
/// l'espèce choisie via `Navigator.pop`.
class SpeciesPickerScreen extends StatefulWidget {
  final AppState appState;
  const SpeciesPickerScreen({super.key, required this.appState});

  @override
  State<SpeciesPickerScreen> createState() => _SpeciesPickerScreenState();
}

class _SpeciesPickerScreenState extends State<SpeciesPickerScreen> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final q = _ctrl.text.trim().toLowerCase();
    var list = widget.appState.species;
    if (q.isNotEmpty) {
      list = list
          .where((s) => s.label.toLowerCase().contains(q) || s.sci.toLowerCase().contains(q))
          .toList();
    }
    final shown = list.take(120).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Choisir une espèce')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Nom français ou latin',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${list.length} espèce${list.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.mute),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: shown.length,
              itemBuilder: (context, i) {
                final s = shown[i];
                return InfoCard(
                  leading: const CircleAvatar(
                    radius: 4,
                    backgroundColor: AppColors.bronze,
                  ),
                  title: s.label,
                  subtitle: s.sci,
                  trailing: ProtectionBadge(species: s),
                  onTap: () => Navigator.of(context).pop<Species>(s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
