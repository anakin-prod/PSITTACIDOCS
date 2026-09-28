/// Réglages généraux de l'application.

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

/// Tant que ce réglage est à `false`, TOUTES les fonctions sont accessibles à
/// tout le monde, abonné ou non : c'est le mode à utiliser pendant les tests,
/// puisque l'abonnement ne peut pas être acheté avant que les produits soient
/// créés dans la Play Console.
///
/// Le jour du lancement public, il suffit de passer ce réglage à `true`.
const bool kPremiumEnforced = false;

/// Nombre d'oiseaux présents autorisés avec la formule gratuite.
const int kFreeBirdLimit = 25;

/// Identifiants des abonnements, à créer à l'identique dans la Play Console
/// (Monétiser → Produits → Abonnements). Les prix affichés dans l'appli sont
/// ceux de la Play Console : aucun tarif n'est écrit ici.
const String kSubMonthlyId = 'psittacidocs_premium_monthly';
const String kSubYearlyId = 'psittacidocs_premium_yearly';
const Set<String> kSubscriptionIds = {kSubMonthlyId, kSubYearlyId};
