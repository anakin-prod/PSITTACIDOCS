#!/usr/bin/env python3
"""Réglages du projet iPhone, appliqués après `flutter create` (voir prepare_ios.sh).

Le dossier ios/ n'est pas versionné : il est recréé à chaque build par Codemagic
avec la version de Flutter de la machine. Ce script y ajoute tout ce qui est
propre à Psittacidocs, de façon répétable (le relancer ne change rien) :

  1. Identifiant de l'appli (app.psittacidocs) vérifié.
  2. iOS 15 minimum (exigé par Firebase), iPhone uniquement.
  3. Droit « Se connecter avec Apple » (fichier Runner.entitlements).
  4. Info.plist : nom affiché, textes des autorisations (photos, appareil
     photo…), absence de chiffrement propriétaire, réglages de la connexion
     Google.
  5. Firebase : copie de firebase/GoogleService-Info.plist dans l'appli.

Sans GoogleService-Info.plist, l'appli se compile quand même : elle fonctionne
alors sans les comptes en ligne (un avertissement est affiché dans le journal).
"""
import hashlib
import os
import plistlib
import re
import shutil
import sys

BUNDLE_ID = "app.psittacidocs"
DISPLAY_NAME = "Psittacidocs"
MIN_IOS = (15, 0)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
IOS = os.path.join(ROOT, "ios")
RUNNER = os.path.join(IOS, "Runner")
PBXPROJ = os.path.join(IOS, "Runner.xcodeproj", "project.pbxproj")
INFO_PLIST = os.path.join(RUNNER, "Info.plist")
ENTITLEMENTS = os.path.join(RUNNER, "Runner.entitlements")
PODFILE = os.path.join(IOS, "Podfile")
FIREBASE_PLIST_SRC = os.path.join(ROOT, "firebase", "GoogleService-Info.plist")
FIREBASE_PLIST_DST = os.path.join(RUNNER, "GoogleService-Info.plist")

USAGE_TEXTS = {
    "NSPhotoLibraryUsageDescription":
        "Psittacidocs accède à tes photos uniquement quand tu choisis une photo "
        "pour la fiche d’un oiseau ou pour un document.",
    "NSCameraUsageDescription":
        "Psittacidocs utilise l’appareil photo uniquement si tu choisis de "
        "photographier un oiseau ou un document.",
    "NSAppleMusicUsageDescription":
        "Psittacidocs te permet de joindre des fichiers à tes oiseaux ; ta "
        "bibliothèque multimédia n’est consultée que si tu y choisis toi-même un fichier.",
}


def fail(msg):
    print(f"ERREUR : {msg}")
    sys.exit(1)


def warn(msg):
    print(f"ATTENTION : {msg}")


# ---------------------------------------------------------------------------
# project.pbxproj
# ---------------------------------------------------------------------------

def new_id(text, seed):
    """Identifiant Xcode (24 caractères hexadécimaux) stable et inutilisé."""
    i = 0
    while True:
        h = hashlib.md5(f"psittacidocs:{seed}:{i}".encode()).hexdigest()[:24].upper()
        if h not in text:
            return h
        i += 1


def patch_deployment_target(text):
    def bump(m):
        major, minor = (int(x) for x in m.group(2).split("."))
        if (major, minor) < MIN_IOS:
            return f"{m.group(1)}{MIN_IOS[0]}.{MIN_IOS[1]};"
        return m.group(0)
    return re.sub(r"(IPHONEOS_DEPLOYMENT_TARGET = )(\d+\.\d+);", bump, text)


def patch_device_family(text):
    # iPhone uniquement : l'appli reste installable sur iPad (mode iPhone), mais
    # l'App Store ne demande alors que des captures d'écran d'iPhone.
    return re.sub(r'TARGETED_DEVICE_FAMILY = "?[0-9,]+"?;', 'TARGETED_DEVICE_FAMILY = 1;', text)


def patch_entitlements_setting(text):
    """Ajoute CODE_SIGN_ENTITLEMENTS aux trois configurations de la cible Runner."""
    out = []
    lines = text.split("\n")
    for idx, line in enumerate(lines):
        m = re.match(r"^(\s*)INFOPLIST_FILE = Runner/Info\.plist;", line)
        if m:
            # Le bloc buildSettings de cette configuration, pour éviter un doublon.
            start = idx
            while start > 0 and "buildSettings = {" not in lines[start]:
                start -= 1
            end = idx
            while end < len(lines) - 1 and not re.match(r"^\s*};", lines[end]):
                end += 1
            block = "\n".join(lines[start:end])
            if "CODE_SIGN_ENTITLEMENTS" not in block:
                out.append(f"{m.group(1)}CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;")
        out.append(line)
    return "\n".join(out)


def patch_firebase_resource(text):
    """Déclare GoogleService-Info.plist comme ressource de l'appli."""
    if "GoogleService-Info.plist" in text:
        return text
    file_id = new_id(text, "GoogleService-Info.plist/file")
    text_with = text + file_id
    build_id = new_id(text_with, "GoogleService-Info.plist/build")

    # 1. Référence du fichier, juste après celle d'Info.plist.
    m = re.search(r"^(\s*)[0-9A-F]{24} /\* Info\.plist \*/ = \{isa = PBXFileReference;[^\n]*\n", text, re.M)
    if not m:
        fail("project.pbxproj : référence d'Info.plist introuvable.")
    ref = (f"{m.group(1)}{file_id} /* GoogleService-Info.plist */ = {{isa = PBXFileReference; "
           f"lastKnownFileType = text.plist.xml; path = \"GoogleService-Info.plist\"; sourceTree = \"<group>\"; }};\n")
    text = text[:m.end()] + ref + text[m.end():]

    # 2. Fichier dans le groupe Runner, à côté d'Info.plist.
    m = re.search(r"^(\s*)[0-9A-F]{24} /\* Info\.plist \*/,\n", text, re.M)
    if not m:
        fail("project.pbxproj : Info.plist introuvable dans le groupe Runner.")
    text = text[:m.end()] + f"{m.group(1)}{file_id} /* GoogleService-Info.plist */,\n" + text[m.end():]

    # 3. Fichier de compilation (ressource).
    m = re.search(r"/\* Begin PBXBuildFile section \*/\n", text)
    if not m:
        fail("project.pbxproj : section PBXBuildFile introuvable.")
    build = (f"\t\t{build_id} /* GoogleService-Info.plist in Resources */ = {{isa = PBXBuildFile; "
             f"fileRef = {file_id} /* GoogleService-Info.plist */; }};\n")
    text = text[:m.end()] + build + text[m.end():]

    # 4. Ajout à l'étape « Copy Bundle Resources » de l'appli (celle qui
    #    contient déjà LaunchScreen.storyboard).
    m = re.search(r"^(\s*)[0-9A-F]{24} /\* LaunchScreen\.storyboard in Resources \*/,\n", text, re.M)
    if not m:
        fail("project.pbxproj : étape des ressources de l'appli introuvable.")
    text = text[:m.end()] + f"{m.group(1)}{build_id} /* GoogleService-Info.plist in Resources */,\n" + text[m.end():]
    return text


# ---------------------------------------------------------------------------
# Info.plist, entitlements, Podfile
# ---------------------------------------------------------------------------

def patch_info_plist(google):
    with open(INFO_PLIST, "rb") as f:
        info = plistlib.load(f)
    info["CFBundleDisplayName"] = DISPLAY_NAME
    for key, value in USAGE_TEXTS.items():
        info[key] = value
    # Pas de chiffrement propriétaire (seulement HTTPS fourni par le système) :
    # évite la question sur l'exportation à chaque envoi sur App Store Connect.
    info["ITSAppUsesNonExemptEncryption"] = False

    if google:
        client_id, reversed_id = google
        info["GIDClientID"] = client_id
        types = [t for t in info.get("CFBundleURLTypes", [])
                 if reversed_id not in t.get("CFBundleURLSchemes", [])]
        types.append({
            "CFBundleTypeRole": "Editor",
            "CFBundleURLName": "google-sign-in",
            "CFBundleURLSchemes": [reversed_id],
        })
        info["CFBundleURLTypes"] = types

    with open(INFO_PLIST, "wb") as f:
        plistlib.dump(info, f, fmt=plistlib.FMT_XML, sort_keys=False)


def write_entitlements():
    ent = {"com.apple.developer.applesignin": ["Default"]}
    with open(ENTITLEMENTS, "wb") as f:
        plistlib.dump(ent, f, fmt=plistlib.FMT_XML)


def patch_podfile():
    """Fixe iOS 15 dans le Podfile s'il existe (selon la version de Flutter, les
    modules peuvent aussi passer par Swift Package Manager, sans Podfile)."""
    if not os.path.exists(PODFILE):
        return False
    with open(PODFILE, encoding="utf-8") as f:
        text = f.read()
    line = f"platform :ios, '{MIN_IOS[0]}.{MIN_IOS[1]}'"
    new, n = re.subn(r"^\s*#?\s*platform :ios, '[0-9.]+'\s*$", line, text, count=1, flags=re.M)
    if n == 0:
        new = line + "\n" + text
    if new != text:
        with open(PODFILE, "w", encoding="utf-8") as f:
            f.write(new)
    return True


def read_firebase_plist():
    """Renvoie (CLIENT_ID, REVERSED_CLIENT_ID) ou None ; vérifie l'identifiant."""
    if not os.path.exists(FIREBASE_PLIST_SRC):
        warn("firebase/GoogleService-Info.plist absent : cette version iPhone "
             "fonctionnera sans les comptes en ligne (voir firebase/LISEZ-MOI.txt).")
        return None, False
    with open(FIREBASE_PLIST_SRC, "rb") as f:
        fb = plistlib.load(f)
    bundle = fb.get("BUNDLE_ID")
    if bundle != BUNDLE_ID:
        fail(f"GoogleService-Info.plist est prévu pour « {bundle} » au lieu de "
             f"« {BUNDLE_ID} ». Télécharge celui de l'appli iOS app.psittacidocs dans Firebase.")
    shutil.copyfile(FIREBASE_PLIST_SRC, FIREBASE_PLIST_DST)
    client_id = fb.get("CLIENT_ID")
    reversed_id = fb.get("REVERSED_CLIENT_ID")
    if not client_id or not reversed_id:
        warn("GoogleService-Info.plist ne contient pas CLIENT_ID : la connexion "
             "Google ne marchera pas sur iPhone. Retélécharge le fichier depuis "
             "Firebase (connexion Google activée).")
        return None, True
    return (client_id, reversed_id), True


def main():
    if not os.path.exists(PBXPROJ) or not os.path.exists(INFO_PLIST):
        fail("dossier ios/ incomplet : lance d'abord « flutter create . --platforms=ios ».")

    with open(PBXPROJ, encoding="utf-8") as f:
        pbx = f.read()
    if f"PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};" not in pbx:
        found = re.findall(r"PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);", pbx)
        fail(f"identifiant de l'appli inattendu ({', '.join(sorted(set(found)))}), "
             f"« {BUNDLE_ID} » attendu.")

    google, has_firebase = read_firebase_plist()

    pbx = patch_deployment_target(pbx)
    pbx = patch_device_family(pbx)
    pbx = patch_entitlements_setting(pbx)
    if has_firebase:
        pbx = patch_firebase_resource(pbx)
    with open(PBXPROJ, "w", encoding="utf-8") as f:
        f.write(pbx)

    write_entitlements()
    patch_info_plist(google)
    podfile = patch_podfile()

    print(f"Projet iPhone prêt : {BUNDLE_ID}, iOS {MIN_IOS[0]}.{MIN_IOS[1]} minimum, iPhone uniquement.")
    print("  · Se connecter avec Apple : activé (Runner.entitlements)")
    print(f"  · Firebase : {'GoogleService-Info.plist ajouté' if has_firebase else 'absent'}")
    print(f"  · Connexion Google : {'configurée' if google else 'non configurée'}")
    print(f"  · Podfile : {'iOS 15 fixé' if podfile else 'absent (Swift Package Manager)'}")


if __name__ == "__main__":
    main()
