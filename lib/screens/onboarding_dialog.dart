import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';

/// Une étape de la présentation.
class _Step {
  final String? icon; // nom d'icône de l'appli ; null = illustration du perroquet
  final String title;
  final String text;
  const _Step(this.icon, this.title, this.text);
}

const List<_Step> _steps = [
  _Step(null, 'Bienvenue dans Psittacidocs',
      'Le carnet d’élevage de tes perroquets et perruches. Voici en quelques écrans ce que l’appli peut faire pour toi.'),
  _Step('bird', 'Mes oiseaux',
      'Une fiche complète par oiseau : bague, espèce, mutation, origine, photos, santé, et tous ses documents (certificats, factures…).'),
  _Step('couple', 'Couples et reproduction',
      'Forme tes couples et suis chaque saison : pontes, incubation, éclosions, sevrage. Une alerte te prévient si deux oiseaux sont apparentés.'),
  _Step('tree', 'Généalogie',
      'Les jeunes sont reliés automatiquement à leurs parents : l’arbre généalogique se construit tout seul.'),
  _Step('calendar', 'Agenda et rappels',
      'Éclosions, sevrages, fins de quarantaine, visites vétérinaires : l’appli te signale les dates importantes.'),
  _Step('shield', 'Espèces et réglementation',
      '381 espèces de psittacidés, avec leur statut CITES et leur annexe européenne, pour savoir quand un certificat est nécessaire.'),
  _Step('genetics', 'Calculateur génétique',
      'Prévois les couleurs possibles des jeunes à partir des mutations des parents, avec des listes prêtes à l’emploi pour les espèces les plus élevées.'),
  _Step('book', 'Psittacopédie',
      'Des centaines d’informations sourcées sur les perroquets, une à découvrir à chaque visite sur l’Accueil, et les chiffres de leur conservation.'),
  _Step('cloud', 'Tes données, où tu veux',
      'Tout fonctionne sans connexion. Si tu le souhaites, un compte facultatif sauvegarde ton élevage en ligne et le synchronise entre tes appareils.'),
];

Future<File> _flagFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/psittacidocs_presentation_vue');
}

/// Affiche la présentation si elle n'a encore jamais été vue sur cet appareil.
Future<void> showOnboardingIfFirstLaunch(BuildContext context) async {
  try {
    final flag = await _flagFile();
    if (await flag.exists()) return;
    if (!context.mounted) return;
    await showOnboarding(context);
    await flag.writeAsString(DateTime.now().toIso8601String());
  } catch (_) {
    // Sans conséquence : au pire, la présentation réapparaîtra une fois.
  }
}

/// Affiche la présentation (aussi accessible depuis Paramètres → À propos).
Future<void> showOnboarding(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const _OnboardingDialog(),
);

class _OnboardingDialog extends StatefulWidget {
  const _OnboardingDialog();

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  final _pages = PageController();
  int _index = 0;

  bool get _last => _index == _steps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_last) {
      Navigator.of(context).pop();
      return;
    }
    _pages.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Widget _header(_Step step) => Container(
    height: 160,
    width: double.infinity,
    color: AppColors.navy,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          right: -40,
          bottom: -30,
          child: Opacity(
            opacity: 0.07,
            child: Image.asset('assets/images/parrot_silhouette.png', width: 170, height: 170),
          ),
        ),
        if (step.icon == null)
          Image.asset('assets/images/splash_parrot.png', height: 132)
        else
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.bronzeOnNavy.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: step.icon == 'bird'
                  ? const ImageIcon(AssetImage('assets/images/nav_parrot.png'), color: AppColors.bronzeOnNavy, size: 44)
                  : Icon(iconFor(step.icon!), color: AppColors.bronzeOnNavy, size: 40),
            ),
          ),
        Positioned(
          top: 12,
          right: 14,
          child: Text(
            '${_index + 1} / ${_steps.length}',
            style: const TextStyle(fontSize: 12, color: AppColors.onNavyMuted, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 370,
              child: PageView.builder(
                controller: _pages,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final step = _steps[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(step),
                      // Défilante par sécurité, pour les petits écrans.
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: GoogleFonts.lora(fontSize: 21, fontWeight: FontWeight.w600, color: AppColors.navy),
                              ),
                              const SizedBox(height: 8),
                              Text(step.text, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.mute)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Points de progression
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.bronze : AppColors.neutralBg,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 18, 16),
              child: Row(
                children: [
                  if (!_last)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Passer', style: TextStyle(color: AppColors.mute)),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    // Le thème donne aux boutons toute la largeur : dans une
                    // rangée, il faut une taille fixe.
                    style: ElevatedButton.styleFrom(minimumSize: const Size(140, 50)),
                    onPressed: _next,
                    child: Text(_last ? 'C’est parti !' : 'Suivant'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
