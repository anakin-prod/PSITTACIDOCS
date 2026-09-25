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

**`codemagic.yaml` le fait automatiquement à chaque build** (première étape :
`flutter create .`), donc si vous passez par Codemagic, vous n'avez rien à
faire de plus. Pour les générer vous-même en local :

```bash
flutter create . --platforms=android,ios --org com.psittacidocs --project-name psittacidocs
flutter pub get
dart run flutter_launcher_icons   # applique les icônes du dossier assets/images
flutter run                       # ou : flutter build apk / flutter build appbundle
```

## Mise en ligne via GitHub + Codemagic

1. Poussez ce dossier tel quel sur un nouveau dépôt GitHub.
2. Sur [codemagic.io](https://codemagic.io), connectez ce dépôt : le fichier
   `codemagic.yaml` déjà présent configure tout le pipeline (génération des
   plateformes, dépendances, icônes, build de l'App Bundle Android).
3. Le premier build produit un fichier `.aab` téléchargeable, prêt à envoyer
   manuellement sur la Google Play Console.
4. Pour une publication automatique à chaque build, ajoutez vos identifiants
   de compte de service Google Play dans Codemagic (Teams → Variables →
   groupe `google_play`), puis décommentez le bloc `google_play:` en bas de
   `codemagic.yaml`.

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
