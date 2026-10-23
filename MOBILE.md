# Application Android (APK)

L'APK est une enveloppe Capacitor qui ouvre l'application publiée (`APP_URL`, par défaut l'URL Lovable du README). Mettre à jour l'application web met à jour l'APK sans le recompiler.

## Obtenir l'APK (sans rien installer sur votre ordinateur)
1. Envoyez le projet sur GitHub (Lovable → Connecteurs → GitHub, ou dépôt GitHub existant).
2. GitHub → onglet **Actions** → **Build APK** → **Run workflow**. Après 5 à 10 minutes, téléchargez l'artefact **agents-ia-apk**.
3. Installez le fichier `.apk` sur le téléphone (autoriser « sources inconnues »).

Sans clé de signature, la compilation produit un APK *debug* : il s'installe, mais il ne convient pas à la vente.

## APK signé (obligatoire pour vendre et mettre à jour)
Créez UNE FOIS la clé, puis conservez-la en lieu sûr (sans elle, aucune mise à jour possible) :

    keytool -genkeypair -v -keystore release.keystore -alias agentsia -keyalg RSA -keysize 2048 -validity 10000
    base64 -w0 release.keystore

GitHub → Settings → Secrets and variables → Actions : créez `KEYSTORE_BASE64` (sortie de la 2e commande), `KEYSTORE_PASSWORD`, `KEY_ALIAS` (agentsia) et `KEY_PASSWORD`. Variable facultative : `APP_URL`.

## Personnalisation
Nom : `capacitor.config.ts` (`appName`) · Identifiant : `appId` + `applicationId` dans `android/app/build.gradle` · Icône : remplacez `assets/icon-only.png` (1024×1024 conseillé).
