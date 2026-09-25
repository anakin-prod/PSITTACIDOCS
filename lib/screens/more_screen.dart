import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'cessions_screen.dart';
import 'documents_screen.dart';
import 'genealogy_screen.dart';
import 'settings_screen.dart';
import 'species_screen.dart';
import 'stats_screen.dart';

class MoreScreen extends StatelessWidget {
  final AppState appState;
  const MoreScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    String? genoDefault;
    if (appState.birds.isNotEmpty) {
      final withParents = appState.birds.where((b) => b.hasParents);
      genoDefault = withParents.isNotEmpty
          ? withParents.first.ring
          : appState.birds.first.ring;
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('Plus', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          InfoCard(
            leading: _menuIcon('doc'),
            title: 'Documents et traçabilité',
            subtitle: '${appState.allDocuments.length} document${appState.allDocuments.length > 1 ? 's' : ''} enregistrés',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DocumentsScreen(appState: appState)),
            ),
          ),
          InfoCard(
            leading: _menuIcon('tree'),
            title: 'Généalogie',
            subtitle: 'Arbres familiaux',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: genoDefault == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GenealogyScreen(appState: appState, ring: genoDefault),
                    ),
                  ),
          ),
          InfoCard(
            leading: _menuIcon('out'),
            title: 'Cessions',
            subtitle:
                '${appState.cededBirds.length} départ${appState.cededBirds.length > 1 ? 's' : ''} vers de nouveaux propriétaires',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CessionsScreen(appState: appState)),
            ),
          ),
          InfoCard(
            leading: _menuIcon('chart'),
            title: 'Statistiques',
            subtitle: 'Reproduction, jeunes, historique',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StatsScreen(appState: appState)),
            ),
          ),
          InfoCard(
            leading: _menuIcon('book'),
            title: 'Espèces de psittacidés',
            subtitle: '${appState.species.length} espèces intégrées',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SpeciesScreen(appState: appState)),
            ),
          ),
          InfoCard(
            leading: _menuIcon('gear'),
            title: 'Paramètres',
            subtitle: 'Élevage, volières, rappels',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsScreen(appState: appState)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuIcon(String name) => CircleAvatar(
    radius: 18,
    backgroundColor: const Color(0xFF0E2254),
    child: Icon(iconFor(name), color: Colors.white, size: 18),
  );
}
