#!/usr/bin/env bash
# Génère une clé de signature Google Play (clé d'importation) pour Psittacidocs.
# N'est plus lancé par Codemagic : la clé a déjà été créée et enregistrée sous
# le nom « psittacidocs_upload ». Conservé uniquement en cas de besoin futur
# (par exemple après une réinitialisation de la clé auprès du support Google Play).
# Produit : cle_signature/psittacidocs-upload.jks + IDENTIFIANTS_CLE_A_CONSERVER.txt
set -euo pipefail
OUT=cle_signature
mkdir -p "$OUT"
KEYTOOL=$(command -v keytool || echo "$JAVA_HOME/bin/keytool")
# Mot de passe aléatoire, jamais affiché dans le journal du build :
# il est écrit uniquement dans le fichier d'identifiants téléchargeable.
PASS=$(openssl rand -hex 16)
ALIAS=upload
"$KEYTOOL" -genkeypair \
  -keystore "$OUT/psittacidocs-upload.jks" -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias "$ALIAS" -storepass "$PASS" -keypass "$PASS" \
  -dname "CN=Psittacidocs, O=Psittacidocs, C=FR" > /dev/null 2>&1
SHA1=$("$KEYTOOL" -list -v -keystore "$OUT/psittacidocs-upload.jks" -storepass "$PASS" -alias "$ALIAS" 2>/dev/null | grep -m1 "SHA1:" | sed 's/.*SHA1: *//')
cat > "$OUT/IDENTIFIANTS_CLE_A_CONSERVER.txt" <<EOF
Clé de signature Google Play (clé d'importation) — Psittacidocs
Générée le : $(date -u +"%d/%m/%Y")

Fichier            : psittacidocs-upload.jks
Keystore password  : $PASS
Key alias          : $ALIAS
Key password       : $PASS
Empreinte SHA-1    : $SHA1

À conserver précieusement (gestionnaire de mots de passe + sauvegarde).
Toutes les mises à jour de l'appli sur Google Play devront être signées
avec cette même clé.
EOF
echo "Clé générée (empreinte SHA-1 : $SHA1)."
echo "Télécharge les deux fichiers dans l'onglet Artifacts de ce build."
