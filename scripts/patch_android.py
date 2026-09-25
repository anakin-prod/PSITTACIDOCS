#!/usr/bin/env python3
"""Adapte le projet Android généré par `flutter create .` pour Psittacidocs.

Le dossier android/ n'est pas versionné : il est régénéré à chaque build par
`flutter create .` (voir scripts/prepare_android.sh). Ce script lui applique
ensuite deux réglages :

1. Signature : si Codemagic fournit une clé (workflow « Build Google Play »,
   via `android_signing`), le build release est signé avec elle, grâce aux
   variables CM_KEYSTORE_PATH, CM_KEYSTORE_PASSWORD, CM_KEY_ALIAS et
   CM_KEY_PASSWORD. Sans clé (workflow « Build de test »), le build reste
   signé avec la clé de débogage, installable directement sur un téléphone.
2. Nom affiché sous l'icône : « Psittacidocs » au lieu de « psittacidocs ».
3. Contrôle : l'identifiant d'application doit être exactement « app.psittacidocs ».

Le script échoue avec un message explicite si le fichier généré ne ressemble
pas à ce qui est attendu, plutôt que de produire un build mal signé.
"""
import pathlib
import re
import sys

MARKER = "PSITTACIDOCS_SIGNING"
# Identifiant Google Play définitif de l'appli : ne jamais le modifier après le
# premier envoi sur la Play Console.
EXPECTED_APP_ID = "app.psittacidocs"
APP_DIR = pathlib.Path("android/app")


def fail(msg: str) -> None:
    print(f"ERREUR (patch_android.py) : {msg}", file=sys.stderr)
    sys.exit(1)


KTS_SIGNING = """    // PSITTACIDOCS_SIGNING : clé fournie par Codemagic (android_signing).
    signingConfigs {
        create("release") {
            val ksPath = System.getenv("CM_KEYSTORE_PATH")
            if (ksPath != null) {
                storeFile = file(ksPath)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD")
            }
        }
    }

"""
KTS_DEBUG_LINE = 'signingConfig = signingConfigs.getByName("debug")'
KTS_NEW_LINE = (
    'signingConfig = if (System.getenv("CM_KEYSTORE_PATH") != null) '
    'signingConfigs.getByName("release") else signingConfigs.getByName("debug")'
)

GROOVY_SIGNING = """    // PSITTACIDOCS_SIGNING : clé fournie par Codemagic (android_signing).
    signingConfigs {
        release {
            if (System.getenv("CM_KEYSTORE_PATH")) {
                storeFile file(System.getenv("CM_KEYSTORE_PATH"))
                storePassword System.getenv("CM_KEYSTORE_PASSWORD")
                keyAlias System.getenv("CM_KEY_ALIAS")
                keyPassword System.getenv("CM_KEY_PASSWORD")
            }
        }
    }

"""
GROOVY_DEBUG_LINE = "signingConfig signingConfigs.debug"
GROOVY_NEW_LINE = (
    'signingConfig System.getenv("CM_KEYSTORE_PATH") '
    "? signingConfigs.release : signingConfigs.debug"
)


def patch_gradle() -> None:
    kts = APP_DIR / "build.gradle.kts"
    groovy = APP_DIR / "build.gradle"
    if kts.exists():
        path, block, old_line, new_line = kts, KTS_SIGNING, KTS_DEBUG_LINE, KTS_NEW_LINE
    elif groovy.exists():
        path, block, old_line, new_line = groovy, GROOVY_SIGNING, GROOVY_DEBUG_LINE, GROOVY_NEW_LINE
    else:
        fail("aucun fichier android/app/build.gradle(.kts) trouvé. `flutter create .` a-t-il bien tourné ?")
        return

    src = path.read_text(encoding="utf-8")
    ids = re.findall(r'applicationId\s*=?\s*"([^"]+)"', src)
    if ids != [EXPECTED_APP_ID]:
        fail(f"identifiant d'application inattendu dans {path} : {ids} (attendu : {EXPECTED_APP_ID}).")
    print(f"Identifiant d'application : {EXPECTED_APP_ID}")
    if MARKER in src:
        print(f"{path} : signature déjà configurée, rien à faire.")
        return

    match = re.search(r"^[ \t]*buildTypes\s*\{", src, flags=re.MULTILINE)
    if not match:
        fail(f"bloc « buildTypes {{ » introuvable dans {path}.")
    if old_line not in src:
        fail(f"ligne « {old_line} » introuvable dans {path} (modèle Flutter modifié ?).")

    src = src[: match.start()] + block + src[match.start():]
    src = src.replace(old_line, new_line, 1)
    path.write_text(src, encoding="utf-8")
    print(f"{path} : signature Codemagic configurée.")


def patch_label() -> None:
    manifest = APP_DIR / "src/main/AndroidManifest.xml"
    if not manifest.exists():
        fail(f"{manifest} introuvable.")
    src = manifest.read_text(encoding="utf-8")
    new_src, count = re.subn(r'android:label="[^"]*"', 'android:label="Psittacidocs"', src, count=1)
    if count == 0:
        print("Avertissement : attribut android:label introuvable, nom de l'appli inchangé.")
        return
    manifest.write_text(new_src, encoding="utf-8")
    print("AndroidManifest.xml : nom affiché réglé sur « Psittacidocs ».")


if __name__ == "__main__":
    patch_gradle()
    patch_label()
