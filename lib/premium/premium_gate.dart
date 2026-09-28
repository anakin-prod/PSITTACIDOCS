import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../screens/paywall_screen.dart';
import '../services.dart';
import '../state/app_state.dart';
import 'premium_service.dart';

/// Vérifie qu'une fonction Premium est accessible ; sinon, propose l'abonnement.
/// Renvoie `true` si l'utilisateur peut continuer.
///
/// Tant que le verrouillage est désactivé ([kPremiumEnforced]), la réponse est
/// toujours « oui » et l'écran d'abonnement n'apparaît jamais.
Future<bool> ensurePremium(BuildContext context, PremiumFeature feature, {String? reason}) async {
  if (Services.premium.allows(feature)) return true;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => PaywallScreen(reason: reason)),
  );
  return Services.premium.allows(feature);
}

/// Vérifie que l'ajout d'un oiseau reste dans la limite de la formule gratuite.
Future<bool> ensureBirdQuota(BuildContext context, AppState appState) async {
  final present = appState.birds.where((b) => !b.isCeded).length;
  if (!Services.premium.birdLimitReached(present)) return true;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PaywallScreen(reason: 'La formule gratuite est limitée à $kFreeBirdLimit oiseaux.'),
    ),
  );
  return !Services.premium.birdLimitReached(present);
}
