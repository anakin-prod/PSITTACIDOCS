/// Réglages généraux de l'application.
import 'dart:io' show Platform;

/// Politique de confidentialité, hébergée sur GitHub Pages.
const String kPrivacyPolicyUrl = 'https://anakin-prod.github.io/PSITTACIDOCS/privacy-policy/';

/// Page de la politique où l'on explique comment supprimer son compte.
const String kAccountDeletionUrl =
    'https://anakin-prod.github.io/PSITTACIDOCS/privacy-policy/#suppression-compte';

/// Contact de l'éditeur.
const String kContactEmail = 'contact.surnia@gmail.com';

/// Identifiant du client web du projet Firebase (présent dans
/// google-services.json, entrée de type 3). Ce n'est pas un secret : il sert
/// uniquement à ce que Google délivre un jeton reconnu par Firebase lors de la
/// connexion avec Google. À mettre à jour si google-services.json change.
const String kGoogleServerClientId =
    '978475003492-jstio4i9jvl0pr707bnvabbunntk9l9h.apps.googleusercontent.com';

// ---------------------------------------------------------------------------
// Formule Premium
// ---------------------------------------------------------------------------

/// Verrouillage Premium, réglé séparément pour chaque boutique.
///
/// À `false`, TOUTES les fonctions sont accessibles à tout le monde, abonné ou
/// non : c'est le mode des tests, tant que l'abonnement n'est pas en vente.
/// À `true`, la formule gratuite est limitée et Premium s'achète dans la
/// boutique de l'appareil.
///
/// iPhone : activé pour la publication sur l'App Store (abonnements créés dans
/// App Store Connect).
/// Android : désactivé pendant le test fermé ; à passer à `true` le jour du
/// lancement sur Google Play, une fois les abonnements créés dans la Play Console.
const bool kPremiumEnforcedIos = true;
const bool kPremiumEnforcedAndroid = false;

/// Verrouillage en vigueur sur cet appareil.
bool get kPremiumEnforced => Platform.isIOS ? kPremiumEnforcedIos : kPremiumEnforcedAndroid;

/// Nombre d'oiseaux présents autorisés avec la formule gratuite.
const int kFreeBirdLimit = 25;

/// Identifiants des abonnements, à créer à l'identique dans la Play Console
/// (Monétiser → Produits → Abonnements) et dans App Store Connect (Monétisation
/// → Abonnements, un seul groupe « Psittacidocs Premium »). Les prix affichés
/// dans l'appli sont ceux des boutiques : aucun tarif n'est écrit ici.
const String kSubMonthlyId = 'psittacidocs_premium_monthly';
const String kSubYearlyId = 'psittacidocs_premium_yearly';
const Set<String> kSubscriptionIds = {kSubMonthlyId, kSubYearlyId};

// ---------------------------------------------------------------------------
// Boutique de l'appareil (Google Play sur Android, App Store sur iPhone)
// ---------------------------------------------------------------------------

/// Vrai sur iPhone : l'abonnement passe alors par l'App Store.
bool get kIsAppleStore => Platform.isIOS;

/// Page où l'utilisateur gère ou résilie son abonnement.
String get kManageSubscriptionsUrl => kIsAppleStore
    ? 'https://apps.apple.com/account/subscriptions'
    : 'https://play.google.com/store/account/subscriptions';

/// Conditions d'utilisation standard d'Apple (CLUF), à afficher près de
/// l'abonnement sur iPhone comme l'exige l'App Store.
const String kAppleStandardEulaUrl = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
