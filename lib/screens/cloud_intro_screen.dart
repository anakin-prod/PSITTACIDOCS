import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import 'sign_in_screen.dart';

/// Présentation de la sauvegarde en ligne, affichée AVANT de proposer la
/// connexion : ce qui est envoyé, où, et ce qui reste sur le téléphone.
class CloudIntroScreen extends StatelessWidget {
  const CloudIntroScreen({super.key});

  Widget _point(String icon, String title, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(name: icon, size: 40),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.navy)),
              const SizedBox(height: 2),
              Text(text, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.mute)),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final available = Services.cloud.available;
    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegarde en ligne')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: staggered([
          Text(
            'Retrouve ton élevage partout',
            style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.navy, height: 1.2),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crée un compte pour sauvegarder tes données en ligne et les synchroniser entre tes appareils. '
            'C’est facultatif : l’appli fonctionne exactement pareil sans compte.',
            style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.mute),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppDecor.card(radius: 22),
            child: Column(
              children: [
                _point('cloud', 'Une copie de sécurité',
                    'Si tu perds ou changes de téléphone, tu retrouves ton élevage en te connectant.'),
                _point('couple', 'Plusieurs appareils',
                    'Tes modifications sont envoyées automatiquement et récupérées sur tes autres appareils.'),
                _point('shield', 'Où sont tes données ?',
                    'Hébergées par Google (Firebase) en Europe. Elles ne sont accessibles qu’avec ton compte.'),
                _point('cam', 'Ce qui reste sur ton téléphone',
                    'Les photos et les documents ne sont pas envoyés : ils restent sur l’appareil où tu les as ajoutés.'),
                _point('out', 'Tu gardes le contrôle',
                    'Tu peux supprimer ton compte et toutes tes données en ligne à tout moment, depuis l’appli.'),
              ],
            ),
          ),
          if (!available)
            const InfoBanner(
              'Les comptes en ligne ne sont pas encore activés dans cette version de l’appli.',
              warning: true,
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: available
                ? () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  )
                : null,
            child: const Text('Continuer'),
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl), mode: LaunchMode.externalApplication),
              child: const Text(
                'Lire la politique de confidentialité',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.bronzeDark),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'En continuant, tu confirmes avoir pris connaissance de la politique de confidentialité.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.mute),
          ),
        ]),
      ),
    );
  }
}
