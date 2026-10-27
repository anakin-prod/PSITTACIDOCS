# Psittacidocs

Application de gestion d'élevage de psittacidés (perroquets) : fiche
individuelle par oiseau, couples et reproduction, généalogie, documents et
traçabilité, cessions, agenda, statistiques, et base de 381 espèces avec leur
statut CITES / Union européenne.

Ce dépôt contient le **code source réel** de l'application (Flutter/Dart),
pas seulement une maquette. Les données sont sauvegardées sur l'appareil
(fichier local), pas de compte ni de serveur requis pour l'instant.

## Pourquoi il manque les dossiers `android/` et `ios/`

Ces dossiers (configuration Gradle, projet Xcode) sont générés
automatiquement par Flutter et sont très sensibles à la version exacte de
Flutter utilisée. Les régénérer à la main sans pouvoir compiler pour vérifier
aurait été plus risqué que de laisser l'outil officiel s'en charger.

**Chaque build Codemagic les recrée automatiquement** via
`scripts/prepare_android.sh`, qui applique aussi la configuration de signature
et le nom affiché de l'appli (`scripts/patch_android.py`). Pour faire la même
chose en local :

```bash
bash scripts/prepare_android.sh
flutter run                       # ou : flutter build apk / flutter build appbundle
```

## Les builds Codemagic

Le fichier `codemagic.yaml` définit trois workflows (deux Android, un
iPhone décrit plus bas), à lancer à la main depuis
Codemagic (**Start new build**, puis choix du workflow) :

| Workflow | Résultat | Quand l'utiliser |
| --- | --- | --- |
| **1 · Build de test** | `psittacidocs-test-N.apk` | Pour installer l'appli sur ton téléphone et la tester. Signé avec une clé de test : refusé par Google Play. |
| **2 · Build Google Play** | `psittacidocs-play-N.aab` | Pour publier sur Google Play. Signé avec ta propre clé. |
| **3 · Build iPhone** | `.ipa` envoyé sur TestFlight | Pour tester sur iPhone puis publier sur l'App Store. |

Les fichiers produits se téléchargent dans l'onglet **Artifacts** du build.

### La clé de signature

La clé a déjà été générée et enregistrée dans Codemagic (**Team settings →
codemagic.yaml settings → Code signing identities → Android keystores**) sous
le nom de référence `psittacidocs_upload`. Le build Google Play la récupère
automatiquement, vérifie qu'il la reçoit bien, puis contrôle que le fichier
produit n'est pas signé avec une clé de test avant de le livrer.

Garde précieusement `psittacidocs-upload.jks` et le fichier d'identifiants :
Codemagic ne permet pas de les re-télécharger. Le script qui a servi à créer la
clé est conservé dans `scripts/generate_keystore.sh`, uniquement pour un
éventuel besoin futur (par exemple après une réinitialisation de la clé auprès
du support Google Play).

### Premier envoi sur Google Play

Le tout premier `.aab` doit être envoyé à la main dans la Google Play Console
(création de l'appli, puis piste de test interne). Google Play gère ensuite la
signature finale (« Play App Signing ») ; ta clé sert de clé d'importation.
Le numéro de build augmente automatiquement à chaque build, ce qu'exige
Google Play.

Identifiant de l'application : `app.psittacidocs`. Il devient
**définitif** dès le premier envoi sur Google Play.

## Version iPhone (workflow « 3 · Build iPhone »)

Le dossier `ios/` est recréé à chaque build par `scripts/prepare_ios.sh`, puis
`scripts/patch_ios.py` y ajoute : identifiant `app.psittacidocs`, iOS 15
minimum, iPhone uniquement, droit « Se connecter avec Apple », textes des
autorisations (photos, appareil photo), configuration Firebase
(`firebase/GoogleService-Info.plist`) et connexion Google. Le build signe
l'appli et l'envoie directement sur **TestFlight**.

Préparation, une seule fois :

1. **developer.apple.com → Identifiers** : créer l'App ID `app.psittacidocs`
   (nom « Psittacidocs ») et cocher **Sign in with Apple**.
2. **App Store Connect → Applications → +** : créer l'appli (même
   identifiant, nom « Psittacidocs », langue principale français, SKU
   `psittacidocs`).
3. **App Store Connect → Utilisateurs et accès → Intégrations → API App Store
   Connect** : créer une clé (accès « App Manager »), télécharger le `.p8`,
   noter l'Issuer ID et le Key ID.
4. **Codemagic → Integrations → Developer Portal → Manage keys** : utiliser
   la clé du compte Apple, nommée `tyto_apple` (commune à toutes les applis).
5. **Codemagic → codemagic.yaml settings → Code signing identities** :
   - *iOS certificates* → **Generate certificate** → type *Apple Distribution*
     (télécharger et garder le fichier proposé) ;
   - sur developer.apple.com → **Profiles** : créer un profil *App Store
     Connect* pour `app.psittacidocs` avec ce certificat ;
   - *iOS provisioning profiles* → **Fetch profiles** → sélectionner ce
     profil → **Download selected**.
6. Firebase : voir `firebase/LISEZ-MOI.txt` (points 3 et 4).

Abonnements : les créer dans App Store Connect (**Monétisation →
Abonnements**, un groupe « Psittacidocs Premium ») avec **les mêmes
identifiants** que sur Google Play : `psittacidocs_premium_monthly` et
`psittacidocs_premium_yearly`. Les deux boutiques sont indépendantes : un
abonnement pris sur Android ne vaut pas sur iPhone ; les données, elles, se
synchronisent par le compte Psittacidocs. Avant tout abonnement payant, signer
le contrat « Applications payantes » (App Store Connect → Accords, taxes et
coordonnées bancaires).

### Premium et pages web

- Le verrouillage Premium se règle par boutique dans `lib/config/app_config.dart` :
  `kPremiumEnforcedIos = true` (App Store) et `kPremiumEnforcedAndroid = false`
  (à passer à `true` au lancement sur Google Play).
- Pages publiées par GitHub Pages : politique de confidentialité
  (`docs/privacy-policy/`) et assistance (`docs/support/`, URL d'assistance de
  l'App Store : https://anakin-prod.github.io/PSITTACIDOCS/support/).

## Psittacopédie : ajouter des informations

Les informations de la Psittacopédie (carte de l'écran d'Accueil, qui change à
chaque ouverture, et liste complète via « Tout voir ») sont dans
`assets/data/parrot_facts.json`. Chaque information a ce format :

```json
{"id": "f038", "theme": "Anatomie", "text": "…", "source": "Organisme, titre de la page", "sci": "Nom scientifique"}
```

- `source` est obligatoire : une information sans source n'est pas affichée.
- `sci` est facultatif : s'il correspond à une espèce de la base, un lien vers
  sa fiche est proposé.
- `theme` libre : chaque nouveau thème devient automatiquement un filtre.

## Structure du projet

```
lib/
  models/     Oiseau, Couple, Espèce, Document, Santé, Cession, Événement...
  state/      AppState : toutes les données + sauvegarde locale + logique
              métier (compatibilité des couples, généalogie, agenda...)
  screens/    Un fichier par écran
  theme/      Couleurs et typographies (Lora / Poppins)
  widgets/    Composants réutilisés (cartes, badges, avatars...)
assets/
  data/species.json   Les 381 espèces, avec leur statut CITES / UE
  images/              Icône, logo
```

## Le statut CITES / UE

Les 381 espèces embarquent un statut CITES international et un statut
européen (voir `assets/data/species.json`), établis à partir du texte
officiel des annexes (en vigueur depuis le 21/05/2023, inchangé pour les
perroquets à la CoP20 de décembre 2025) et du règlement européen (CE)
n° 338/97. Chaque fiche espèce, dans l'appli, renvoie vers
[Species+](https://speciesplus.net) (base officielle CITES/UE) pour
vérification avant toute cession réelle — les annexes peuvent être modifiées
par une future conférence CITES ou un futur règlement européen.

## Une remarque honnête sur ce premier lâcher de code

Ce projet a été écrit intégralement à la main, sans pouvoir compiler ni
exécuter `flutter analyze` (l'environnement où il a été généré n'a pas accès
au SDK Flutter ni à Internet). Il a été relu attentivement mais **le tout
premier build sur Codemagic est susceptible de faire remonter une ou deux
erreurs mineures** (import oublié, léger décalage d'API selon la version de
Flutter utilisée) — c'est normal pour un projet de cette taille sans retour
du compilateur, et généralement rapide à corriger une fois le message
d'erreur du build en main.
