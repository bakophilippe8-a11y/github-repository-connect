# Feuille de route — Clé IA par vendeur + APK Android

- [x] 1. Écran « Clé IA » dans Paramètres API (champ, test serveur, stockage chiffré, migration 0004 canal 'ai', guide FR)
- [x] 2. Passerelle Lovable remplacée par Google Gemini (@ai-sdk/google) ; @tanstack/ai* et @ai-sdk/openai/anthropic retirés
- [x] 3. Erreurs/coûts : pas de clé → message ; 401/403 → clé invalide (IA suspendue) ; 429 → quota Google ; plafonds quotidiens par vendeur ; avertissement coût vidéo
- [x] 4. APK : capacitor.config.ts, android/ et workflow build-apk.yml vérifiés et cohérents ; MOBILE.md documenté
- [x] 5. Qualité : 42 tests passent, typecheck OK, build OK, AGENTS.md/MOBILE.md à jour
- [ ] Action utilisateur : appliquer la migration 0004 sur la base (aucun accès base depuis cet environnement)
