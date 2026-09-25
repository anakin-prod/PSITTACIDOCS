#!/usr/bin/env bash
# Prépare le projet avant compilation (utilisé par les workflows de codemagic.yaml).
set -euo pipefail

echo "1/4 · Génération des dossiers de plateforme (android/, ios/)"
# Ces dossiers ne sont pas versionnés : ils sont très sensibles à la version de
# Flutter et sont donc recréés ici avec celle de la machine de build. Le code
# existant (lib/, assets/, pubspec.yaml) n'est pas touché.
flutter create . --platforms=android,ios --org app --project-name psittacidocs

echo "2/4 · Réglage de la signature et du nom de l'appli"
python3 scripts/patch_android.py

echo "3/4 · Installation des dépendances"
flutter pub get

echo "4/4 · Génération des icônes d'appli"
dart run flutter_launcher_icons
