import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';

/// Présentation de la formule Premium et achat de l'abonnement.
///
/// Les prix affichés viennent de Google Play. Tant que les abonnements ne sont
/// pas créés dans la Play Console, l'écran explique simplement qu'ils ne sont
/// pas encore disponibles.
class PaywallScreen extends StatelessWidget {
  /// Raison pour laquelle l'écran s'ouvre (fonction demandée, limite atteinte…).
  final String? reason;
  const PaywallScreen({super.key, this.reason});

  static const _benefits = <(String, String)>[
    ('couple', 'Oiseaux en nombre illimité'),
    ('cloud', 'Sauvegarde en ligne et synchronisation entre appareils'),
    ('genetics', 'Calculateur génétique'),
    ('thermo', 'Suivi des volières et de l’incubation'),
    ('pdf', 'Exports PDF : fiches et inventaire'),
  ];

  String _period(ProductDetails p) => p.id == kSubYearlyId ? 'par an' : 'par mois';
  String _label(ProductDetails p) => p.id == kSubYearlyId ? 'Annuel' : 'Mensuel';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListenableBuilder(
        listenable: Services.premium,
        builder: (context, _) {
          final premium = Services.premium;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: staggered([
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  color: AppColors.navy,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: -54,
                        top: -28,
                        child: Opacity(
                          opacity: 0.08,
                          child: Image.asset('assets/images/parrot_silhouette.png', width: 180, height: 180),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PSITTACIDOCS PREMIUM',
                            style: TextStyle(fontSize: 12, letterSpacing: 1, color: AppColors.bronzeOnNavy, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            premium.isPremium ? 'Ton abonnement est actif' : 'Ton élevage, sans limites',
                            style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white, height: 1.2),
                          ),
                          if (reason != null && !premium.isPremium) ...[
                            const SizedBox(height: 8),
                            Text(reason!, style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.onNavyMuted)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!kPremiumEnforced)
                const InfoBanner(
                  'Version de test : toutes les fonctions sont actuellement accessibles gratuitement.',
                ),
              const SectionLabel('Ce que comprend Premium'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecor.card(radius: 22),
                child: Column(
                  children: [
                    for (final b in _benefits)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            IconTile(name: b.$1, size: 36),
                            const SizedBox(width: 12),
                            Expanded(child: Text(b.$2, style: const TextStyle(fontSize: 14, color: AppColors.navy))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SectionLabel('Abonnement'),
              if (premium.isPremium)
                _ActiveCard(onManage: () => launchUrl(
                  Uri.parse('https://play.google.com/store/account/subscriptions'),
                  mode: LaunchMode.externalApplication,
                ))
              else if (premium.loadingProducts)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
              else if (premium.products.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecor.card(radius: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        premium.storeAvailable
                            ? 'L’abonnement n’est pas encore disponible.'
                            : 'Google Play est inaccessible pour le moment.',
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.navy),
                      ),
                      const SizedBox(height: 4),
                      const Text('Réessaie un peu plus tard.', style: TextStyle(fontSize: 13, color: AppColors.mute)),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: premium.loadProducts, child: const Text('Réessayer')),
                    ],
                  ),
                )
              else
                for (final p in premium.products)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecor.card(radius: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(_label(p), style: GoogleFonts.lora(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.navy)),
                            ),
                            Text(p.price, style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.navy)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _period(p),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, color: AppColors.mute),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: premium.purchaseInProgress ? null : () => premium.buy(p),
                          child: premium.purchaseInProgress
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : Text('Choisir l’abonnement ${_label(p).toLowerCase()}'),
                        ),
                      ],
                    ),
                  ),
              if (premium.message != null) InfoBanner(premium.message!, warning: true),
              const SizedBox(height: 6),
              if (!premium.isPremium)
                Center(
                  child: TextButton(
                    onPressed: premium.storeAvailable ? premium.restore : null,
                    child: const Text('Restaurer mes achats'),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Abonnement à renouvellement automatique, facturé sur ton compte Google Play. '
                'Tu peux le résilier à tout moment dans Google Play (Paiements et abonnements → Abonnements) : '
                'il reste alors actif jusqu’à la fin de la période déjà payée. '
                'L’abonnement est lié à ton compte Google Play et se retrouve sur tous tes appareils connectés à ce compte.',
                style: TextStyle(fontSize: 11.5, height: 1.45, color: AppColors.mute),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl), mode: LaunchMode.externalApplication),
                  child: const Text(
                    'Politique de confidentialité',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.bronzeDark),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final VoidCallback onManage;
  const _ActiveCard({required this.onManage});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: AppDecor.card(radius: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Tag('Abonnement actif', tone: TagTone.good),
        const SizedBox(height: 10),
        const Text(
          'Merci pour ton soutien ! Toutes les fonctions Premium sont débloquées.',
          style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.navy),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onManage, child: const Text('Gérer mon abonnement')),
      ],
    ),
  );
}
