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
4. Firebase (comptes en ligne) : si le fichier firebase/google-services.json
   est présent, il est copié dans android/app/ et le plugin « google-services »
   est branché. S'il est absent, le build reste valide : l'appli fonctionne alors
   sans les comptes en ligne (c'est le cas tant que le projet Firebase n'est pas
   créé). Android 7.0 (API 24) est exigé comme version minimale.

Le script échoue avec un message explicite si le fichier généré ne ressemble
pas à ce qui est attendu, plutôt que de produire un build mal signé.
"""
import json
import pathlib
import re
import shutil
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
    src = force_target_sdk(src, path)
    src = force_min_sdk(src, path)
    path.write_text(src, encoding="utf-8")
    print(f"{path} : signature Codemagic configurée.")


# Google Play exige que les applis ciblent une version récente d'Android.
# On l'impose explicitement plutôt que de dépendre de la valeur par défaut de
# Flutter, qui peut être en retard.
TARGET_SDK = 36


def force_target_sdk(src: str, path) -> str:
    patterns = [
        (r"targetSdk\s*=\s*[^\n]+", f"targetSdk = {TARGET_SDK}"),          # Kotlin DSL
        (r"targetSdkVersion\s+[^\n]+", f"targetSdkVersion {TARGET_SDK}"),  # Groovy
    ]
    for pattern, replacement in patterns:
        new_src, n = re.subn(pattern, replacement, src, count=1)
        if n:
            print(f"{path} : version Android ciblée fixée à l'API {TARGET_SDK}.")
            return new_src
    fail(f"réglage « targetSdk » introuvable dans {path} (modèle Flutter modifié ?).")
    return src


# Firebase Authentication et Cloud Firestore exigent au minimum Android 6 ; on
# vise Android 7.0 (API 24), qui couvre plus de 97 % des appareils.
MIN_SDK = 24


def force_min_sdk(src: str, path) -> str:
    substitutions = [
        (r"minSdk\s*=\s*flutter\.minSdkVersion", f"minSdk = maxOf(flutter.minSdkVersion, {MIN_SDK})"),
        (r"minSdkVersion\s+flutter\.minSdkVersion", f"minSdkVersion Math.max(flutter.minSdkVersion, {MIN_SDK})"),
    ]
    for pattern, replacement in substitutions:
        new_src, n = re.subn(pattern, replacement, src, count=1)
        if n:
            print(f"{path} : version Android minimale : au moins l'API {MIN_SDK}.")
            return new_src
    # Valeur fixe dans le modèle : on la relève si nécessaire.
    match = re.search(r"(minSdk(?:Version)?\s*=?\s*)(\d+)", src)
    if match:
        value = max(int(match.group(2)), MIN_SDK)
        print(f"{path} : version Android minimale fixée à l'API {value}.")
        return src[: match.start(2)] + str(value) + src[match.end(2):]
    print("Avertissement : réglage minSdk introuvable, valeur par défaut de Flutter conservée.")
    return src


# ---------------------------------------------------------------------------
# Firebase
# ---------------------------------------------------------------------------

FIREBASE_JSON = pathlib.Path("firebase/google-services.json")
ANDROID_DIR = pathlib.Path("android")
# Version du plugin Gradle « google-services » (vérifiée en septembre 2026).
GMS_PLUGIN_VERSION = "4.4.4"
GMS_ID = "com.google.gms.google-services"


def _insert_after_line(path: pathlib.Path, pattern: str, new_line: str, what: str) -> None:
    src = path.read_text(encoding="utf-8")
    if GMS_ID in src:
        print(f"{path} : plugin google-services déjà présent.")
        return
    match = re.search(pattern, src, flags=re.MULTILINE)
    if not match:
        fail(f"{what} : ligne du plugin « com.android.application » introuvable dans {path} (modèle Flutter modifié ?).")
        return
    indent = match.group(1)
    src = src[: match.end()] + "\n" + indent + new_line + src[match.end():]
    path.write_text(src, encoding="utf-8")
    print(f"{path} : plugin google-services ajouté.")


def patch_firebase() -> None:
    if not FIREBASE_JSON.exists():
        print(
            "Firebase : firebase/google-services.json absent → build SANS comptes en ligne "
            "(l'appli fonctionne, les comptes sont désactivés)."
        )
        return

    try:
        data = json.loads(FIREBASE_JSON.read_text(encoding="utf-8"))
    except ValueError as exc:
        fail(f"firebase/google-services.json n'est pas un JSON valide : {exc}")
        return
    packages = [
        client.get("client_info", {}).get("android_client_info", {}).get("package_name")
        for client in data.get("client", [])
    ]
    if EXPECTED_APP_ID not in packages:
        fail(
            f"firebase/google-services.json est prévu pour {packages}, pas pour {EXPECTED_APP_ID}. "
            "Dans Firebase, l'appli Android doit avoir exactement ce nom de package."
        )
        return

    shutil.copyfile(FIREBASE_JSON, APP_DIR / "google-services.json")
    print(f"Firebase : configuration copiée dans {APP_DIR / 'google-services.json'}.")

    # 1) Déclaration du plugin dans settings.gradle(.kts)
    kts = ANDROID_DIR / "settings.gradle.kts"
    groovy = ANDROID_DIR / "settings.gradle"
    if kts.exists():
        _insert_after_line(
            kts,
            r'^([ \t]*)id\("com\.android\.application"\)[^\n]*$',
            f'id("{GMS_ID}") version "{GMS_PLUGIN_VERSION}" apply false',
            "settings",
        )
    elif groovy.exists():
        _insert_after_line(
            groovy,
            r'^([ \t]*)id\s+"com\.android\.application"[^\n]*$',
            f'id "{GMS_ID}" version "{GMS_PLUGIN_VERSION}" apply false',
            "settings",
        )
    else:
        fail("android/settings.gradle(.kts) introuvable.")

    # 2) Application du plugin dans android/app/build.gradle(.kts)
    app_kts = APP_DIR / "build.gradle.kts"
    app_groovy = APP_DIR / "build.gradle"
    if app_kts.exists():
        _insert_after_line(app_kts, r'^([ \t]*)id\("com\.android\.application"\)[ \t]*$', f'id("{GMS_ID}")', "app")
    elif app_groovy.exists():
        _insert_after_line(app_groovy, r'^([ \t]*)id\s+"com\.android\.application"[ \t]*$', f'id "{GMS_ID}"', "app")
    else:
        fail("android/app/build.gradle(.kts) introuvable.")


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
    patch_firebase()
