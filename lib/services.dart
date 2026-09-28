import 'cloud/cloud_service.dart';
import 'premium/premium_service.dart';

/// Accès partagé aux services créés au démarrage de l'appli : comptes en ligne
/// avec synchronisation, et abonnement Premium.
class Services {
  Services._();

  static late CloudService cloud;
  static late PremiumService premium;
}
