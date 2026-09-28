import 'package:flutter/material.dart';

import '../logic/pdf_export.dart';
import '../premium/premium_gate.dart';
import '../premium/premium_service.dart';
import '../services.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'cessions_screen.dart';
import 'conservation_screen.dart';
import 'documents_screen.dart';
import 'env_readings_screen.dart';
import 'genealogy_screen.dart';
import 'genetics_screen.dart';
import 'incubations_screen.dart';
import 'settings_screen.dart';
import 'species_screen.dart';
import 'stats_screen.dart';
import '../widgets/animations.dart';
import 'account_screen.dart';
import 'cloud_intro_screen.dart';
import 'paywall_screen.dart';

class MoreScreen extends StatelessWidget {
  final AppState appState;
  const MoreScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    // Ouvre la généalogie du premier oiseau ayant des parents connus (à
    // défaut, du premier oiseau). La bague est copiée dans une variable non
    // nullable avant d'être capturée par la fonction, comme l'exige Dart.
    VoidCallback? openGenealogy;
    if (appState.birds.isNotEmpty) {
      final withParents = appState.birds.where((b) => b.hasParents);
      final String ring = withParents.isNotEmpty
          ? withParents.first.ring
          : appState.birds.first.ring;
      openGenealogy = () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GenealogyScreen(appState: appState, ring: ring),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
        children: staggered([
          const ScreenHeader(title: 'Plus', subtitle: 'Outils, suivi et réglages'),
          const GroupLabel('Compte'),
          ListenableBuilder(
            listenable: Listenable.merge([Services.cloud, Services.premium]),
            builder: (context, _) {
              final cloud = Services.cloud;
              final premium = Services.premium;
              return Column(
                children: [
                  InfoCard(
                    leading: _menuIcon('cloud'),
                    title: cloud.signedIn ? 'Mon compte' : 'Sauvegarde en ligne',
                    subtitle: cloud.signedIn
                        ? '${cloud.email ?? ''} · ${describeSync(cloud).title}'
                        : 'Connexion, sauvegarde et synchronisation',
                    trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => cloud.signedIn ? const AccountScreen() : const CloudIntroScreen(),
                      ),
                    ),
                  ),
                  InfoCard(
                    leading: _menuIcon('star'),
                    title: 'Psittacidocs Premium',
                    subtitle: premium.isPremium ? 'Abonnement actif' : 'Découvre les fonctions Premium',
                    trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    ),
                  ),
                ],
              );
            },
          ),
          const GroupLabel('Mon élevage'),
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
            onTap: openGenealogy,
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
          const GroupLabel('Suivi'),
          InfoCard(
            leading: _menuIcon('thermo'),
            title: 'Conditions des volières',
            subtitle: 'Température, humidité, éclairage',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: () async {
              if (!await ensurePremium(context, PremiumFeature.breedingLogs, reason: 'Le suivi des volières fait partie de Premium.')) return;
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EnvReadingsScreen(appState: appState)),
              );
            },
          ),
          InfoCard(
            leading: _menuIcon('egg'),
            title: 'Incubation',
            subtitle: '${appState.incubations.where((i) => i.isActive).length} en cours',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: () async {
              if (!await ensurePremium(context, PremiumFeature.breedingLogs, reason: 'Le suivi de l’incubation fait partie de Premium.')) return;
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => IncubationsScreen(appState: appState)),
              );
            },
          ),
          InfoCard(
            leading: _menuIcon('genetics'),
            title: 'Calculateur génétique',
            subtitle: 'Mutations possibles chez les jeunes',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: () async {
              if (!await ensurePremium(context, PremiumFeature.geneticsCalculator, reason: 'Le calculateur génétique fait partie de Premium.')) return;
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GeneticsScreen(appState: appState)),
              );
            },
          ),
          const GroupLabel('Ressources'),
          InfoCard(
            leading: _menuIcon('shield'),
            title: 'Perroquets menacés',
            subtitle: 'Les chiffres de la conservation en graphiques',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ConservationScreen(appState: appState)),
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
            leading: _menuIcon('pdf'),
            title: 'Inventaire de l’élevage (PDF)',
            subtitle: 'Tous tes oiseaux dans un tableau à partager ou imprimer',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (!await ensurePremium(context, PremiumFeature.pdfExport, reason: 'Les exports PDF font partie de Premium.')) return;
              try {
                await shareInventory(appState);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Export PDF impossible : $e')));
              }
            },
          ),
          const GroupLabel('Réglages'),
          InfoCard(
            leading: _menuIcon('gear'),
            title: 'Paramètres',
            subtitle: 'Élevage, volières, rappels',
            trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsScreen(appState: appState)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _menuIcon(String name) => IconTile(name: name);
}
