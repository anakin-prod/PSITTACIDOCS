#!/usr/bin/env bash
# Prépare la version iPhone avant compilation (workflow « ios-release » de codemagic.yaml).
set -euo pipefail

echo "1/5 · Génération du dossier ios/"
# Comme pour Android, ce dossier n'est pas versionné : il est recréé avec la
# version de Flutter de la machine de build. lib/, assets/ et pubspec.yaml ne
# sont pas touchés. Le dossier android/ est créé aussi, sans être compilé :
# les outils d'icônes et d'écran de démarrage en ont besoin.
flutter create . --platforms=android,ios --org app --project-name psittacidocs

echo "2/5 · Installation des dépendances"
flutter pub get

echo "3/5 · Réglages iPhone : Firebase, connexion Apple et Google, autorisations"
python3 scripts/patch_ios.py

echo "4/5 · Génération des icônes d'appli"
dart run flutter_launcher_icons

echo "5/5 · Génération de l'écran de démarrage (logo sur fond bleu nuit)"
dart run flutter_native_splash:create
