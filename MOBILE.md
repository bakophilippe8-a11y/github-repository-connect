# Application Android (APK)

L'APK est une enveloppe Capacitor qui ouvre l'application publiée (`APP_URL`, par défaut `https://github-harbor-connector.lovable.app`). Mettre à jour l'application web met à jour l'APK sans le recompiler.

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

## Clé IA de chaque vendeur
L'application n'utilise aucun crédit Lovable : chaque vendeur colle sa propre clé API Google (Gemini) dans **Paramètres API → Clé IA**. La clé est chiffrée côté serveur et les appels IA (réponses, brouillons, vidéos Veo) sont facturés par Google directement sur le compte du vendeur. Sans clé enregistrée, les fonctions IA affichent un message renvoyant vers cet écran.

Attention : la documentation Google consultée le 23 octobre 2026 annonce l'arrêt de `veo-3.1-generate-preview` et `veo-3.1-fast-generate-preview` depuis le 22 octobre. La valeur de repli `VIDEO_MODEL=veo-3.1-generate-preview` ne garantit donc plus une génération fonctionnelle. Google recommande Gemini Omni Flash ou les modèles GA de Gemini Enterprise Agent Platform ; leur intégration nécessite de vérifier le contrat API, pas simplement de changer le nom du modèle. Aucun remplacement du modèle texte n'a été effectué. Source : https://ai.google.dev/gemini-api/docs/veo.

## Mettre à jour l'APK
1. Modifiez l'application dans Lovable et publiez-la : l'APK existant charge automatiquement la nouvelle version (il ouvre `APP_URL`).
2. Recompilez uniquement si vous changez le nom, l'icône, l'identifiant ou `APP_URL` : poussez sur GitHub puis relancez le workflow **Build APK** (ou créez un tag `v*`). L'APK doit être signé avec LE MÊME keystore que la première version, sinon Android refuse la mise à jour.

## Dans la WebView Android
La session de connexion persiste après fermeture de l'app (stockage local de la WebView conservé). Les liens externes (Facebook, Google AI Studio) s'ouvrent avec `target="_blank"` dans le navigateur du téléphone. L'interface est utilisable sur petit écran et la vidéo se lit en plein écran (`playsInline`).
