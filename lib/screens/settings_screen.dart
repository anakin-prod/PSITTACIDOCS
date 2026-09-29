import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import 'onboarding_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final AppState appState;
  const SettingsScreen({super.key, required this.appState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameCtrl;
  final _newVolCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.appState.settings.elevageName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _newVolCtrl.dispose();
    super.dispose();
  }

  Future<void> _addVoliere() async {
    if (_newVolCtrl.text.trim().isEmpty) return;
    await widget.appState.addVoliere(_newVolCtrl.text);
    _newVolCtrl.clear();
    setState(() {});
  }

  Widget _switchRow({
    required String icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool last = false,
  }) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            IconTile(name: icon, size: 36),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.navy))),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
      if (!last) const Divider(height: 1, color: AppColors.line),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final settings = appState.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: staggered([
          const SectionLabel('Élevage'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecor.card(radius: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom de l’élevage', hintText: 'ex. Élevage du Vallon'),
                  onChanged: (v) {
                    settings.elevageName = v;
                    appState.saveSettings();
                  },
                ),
                const SizedBox(height: 8),
                const Text('Affiché en grand en haut de l’Accueil.', style: TextStyle(fontSize: 12, color: AppColors.mute)),
              ],
            ),
          ),
          const SectionLabel('Emplacements'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecor.card(radius: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (settings.volieres.isEmpty) const EmptyHint('Aucun emplacement pour l’instant.'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < settings.volieres.length; i++)
                      Container(
                        padding: const EdgeInsets.only(left: 14, right: 4),
                        height: 38,
                        decoration: BoxDecoration(color: AppColors.bronzeBg, borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(settings.volieres[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.bronzeDark)),
                            IconButton(
                              tooltip: 'Supprimer ${settings.volieres[i]}',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.bronzeDark),
                              onPressed: () async {
                                await appState.removeVoliere(i);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newVolCtrl,
                        onSubmitted: (_) => _addVoliere(),
                        decoration: const InputDecoration(hintText: 'Nouvel emplacement (ex. Volière extérieure)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AddButton(tooltip: 'Ajouter l’emplacement', onPressed: _addVoliere),
                  ],
                ),
              ],
            ),
          ),
          const SectionLabel('Rappels'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: AppDecor.card(radius: 22),
            child: Column(
              children: [
                _switchRow(
                  icon: 'egg',
                  title: 'Éclosions à venir',
                  value: settings.remindEclosion,
                  onChanged: (v) {
                    setState(() => settings.remindEclosion = v);
                    appState.saveSettings();
                  },
                ),
                _switchRow(
                  icon: 'leaf',
                  title: 'Sevrages',
                  value: settings.remindSevrage,
                  onChanged: (v) {
                    setState(() => settings.remindSevrage = v);
                    appState.saveSettings();
                  },
                ),
                _switchRow(
                  icon: 'shield',
                  title: 'Fins de quarantaine',
                  value: settings.remindQuarantaine,
                  onChanged: (v) {
                    setState(() => settings.remindQuarantaine = v);
                    appState.saveSettings();
                  },
                ),
                _switchRow(
                  icon: 'steth',
                  title: 'Visites vétérinaires',
                  value: settings.remindVeto,
                  onChanged: (v) {
                    setState(() => settings.remindVeto = v);
                    appState.saveSettings();
                  },
                ),
                _switchRow(
                  icon: 'bowl',
                  title: 'Nourrissage quotidien',
                  value: settings.remindNourrissage,
                  last: true,
                  onChanged: (v) {
                    setState(() => settings.remindNourrissage = v);
                    appState.saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SectionLabel('Données'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecor.card(radius: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.red),
                  label: const Text('Effacer toutes les données', style: TextStyle(color: AppColors.red)),
                  onPressed: appState.isEmptyBreeding
                      ? null
                      : () async {
                          final signedIn = Services.cloud.signedIn;
                          final ok = await confirmDestructive(
                            context,
                            title: 'Effacer toutes les données ?',
                            message: 'Oiseaux, couples, documents enregistrés, incubations, relevés et agenda '
                                'seront supprimés de cet appareil. Tes réglages sont conservés.'
                                '${signedIn ? '\n\nTu es connecté : l’effacement sera aussi appliqué à ta sauvegarde en ligne et à tes autres appareils.' : ''}',
                            confirmLabel: 'Tout effacer',
                          );
                          if (!ok) return;
                          await appState.eraseAllData();
                          if (!context.mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Toutes les données ont été effacées.')),
                          );
                        },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pour effacer aussi ton compte en ligne, utilise « Supprimer mon compte » dans Mon compte.',
                  style: TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.mute),
                ),
              ],
            ),
          ),
          const SectionLabel('À propos'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecor.card(radius: 22),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset('assets/images/icon.png', width: 52, height: 52),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Psittacidocs', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy)),
                      const Text('Version 1.0', style: TextStyle(fontSize: 12.5, color: AppColors.mute)),
                      const Text('Gestion d’élevage de psittacidés', style: TextStyle(fontSize: 12.5, color: AppColors.bronzeDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.slideshow_outlined, size: 20),
            label: const Text('Revoir la présentation'),
            onPressed: () => showOnboarding(context),
          ),
        ]),
      ),
    );
  }
}
