# Feuille de route — Clé IA par vendeur + APK Android

- [ ] 1. Écran « Clé IA » dans Paramètres API (champ, test serveur, stockage chiffré, migration 0004 canal 'ai', guide FR)
- [ ] 2. Remplacer la passerelle Lovable par Google Gemini (@ai-sdk/google) dans sales-ai, facebook-campaign-ai, claude-script, campaign-video ; retirer @tanstack/ai*
- [ ] 3. Erreurs/coûts : pas de clé → message ; 401/403 → clé invalide ; 429 → quota ; plafonds quotidiens par vendeur ; avertissement coût vidéo
- [ ] 4. APK : vérifier capacitor.config.ts, android/, workflow build-apk.yml, WebView (session, liens externes, petit écran), MOBILE.md
- [ ] 5. Qualité : tests Vitest, typecheck, build, AGENTS.md/MOBILE.md à jour
- [ ] Réponse finale : fichiers modifiés + actions requises de l'utilisateur
