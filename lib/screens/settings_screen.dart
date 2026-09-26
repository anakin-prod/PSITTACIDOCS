import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  final AppState appState;
  const SettingsScreen({super.key, required this.appState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  final _newVolCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.appState.settings.elevageName);
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final settings = appState.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Élevage', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Nom de l'élevage", hintText: 'ex. Élevage du Vallon'),
                  onChanged: (v) {
                    settings.elevageName = v;
                    appState.saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SectionLabel('Emplacements'),
          for (var i = 0; i < settings.volieres.length; i++)
            InfoCard(
              leading: const Icon(Icons.shield_outlined, color: AppColors.navy),
              title: settings.volieres[i],
              dense: true,
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () async {
                  await appState.removeVoliere(i);
                  setState(() {});
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _newVolCtrl,
                  decoration: const InputDecoration(labelText: 'Ajouter un emplacement', hintText: 'ex. Volière extérieure'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Ajouter l'emplacement"),
                    onPressed: () async {
                      await appState.addVoliere(_newVolCtrl.text);
                      _newVolCtrl.clear();
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('Rappels'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Éclosions à venir', style: TextStyle(fontSize: 13)),
                  value: settings.remindEclosion,
                  onChanged: (v) {
                    setState(() => settings.remindEclosion = v);
                    appState.saveSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text('Sevrages', style: TextStyle(fontSize: 13)),
                  value: settings.remindSevrage,
                  onChanged: (v) {
                    setState(() => settings.remindSevrage = v);
                    appState.saveSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text('Fins de quarantaine', style: TextStyle(fontSize: 13)),
                  value: settings.remindQuarantaine,
                  onChanged: (v) {
                    setState(() => settings.remindQuarantaine = v);
                    appState.saveSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text('Visites vétérinaires', style: TextStyle(fontSize: 13)),
                  value: settings.remindVeto,
                  onChanged: (v) {
                    setState(() => settings.remindVeto = v);
                    appState.saveSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text('Nourrissage quotidien', style: TextStyle(fontSize: 13)),
                  value: settings.remindNourrissage,
                  onChanged: (v) {
                    setState(() => settings.remindNourrissage = v);
                    appState.saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SectionLabel('À propos'),
          const InfoCard(
            leading: CircleAvatar(radius: 18, backgroundColor: AppColors.navy, child: Icon(Icons.eco, color: Colors.white, size: 18)),
            title: 'Psittacidocs',
            subtitle: 'Version 1.0',
          ),
        ],
      ),
    );
  }
}
