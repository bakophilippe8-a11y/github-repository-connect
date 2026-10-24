# Feuille de route — Clé IA par vendeur + APK Android

- [x] 1. Écran « Clé IA » dans Paramètres API (champ, test serveur, stockage chiffré, migration 0004 canal 'ai', guide FR)
- [x] 2. Passerelle Lovable remplacée par Google Gemini (@ai-sdk/google) ; @tanstack/ai* et @ai-sdk/openai/anthropic retirés
- [x] 3. Erreurs/coûts : pas de clé → message ; 401/403 → clé invalide (IA suspendue) ; 429 → quota Google ; plafonds quotidiens par vendeur ; avertissement coût vidéo
- [x] 4. APK : capacitor.config.ts, android/ et workflow build-apk.yml vérifiés et cohérents ; MOBILE.md documenté
- [x] 5. Qualité : 42 tests passent, typecheck OK, build OK, AGENTS.md/MOBILE.md à jour
- [x] Activer la base propre au projet via Lovable Cloud et vérifier les nouvelles références de configuration.
- [ ] Installer et contrôler le schéma complet : attend l'autorisation d'adapter le script aux restrictions Cloud (stockage séparé et références aux comptes).
- [ ] Saisir le secret de chiffrement puis vérifier l'authentification et publier : attend la réussite du schéma et la saisie sécurisée par l'utilisateur.
- [x] Corriger la compilation après activation Cloud sans modifier le schéma : contrat de données séparé, connexions et isolation inchangées ; 55 tests réussis, journal automatique « build OK ».
- [x] Demander la publication de ce projet et remplacer l'adresse Android par celle de ce projet.
- [x] Vérifier les modèles Google ; conserver le modèle texte et utiliser le repli vidéo demandé, en documentant l'arrêt des previews.
- [x] Vérifier le secret de chiffrement : absent des secrets de ce projet ; aucun secret créé ni changé.
- [x] Vérifier les dernières modifications : 48 tests passent et journal automatique « build OK » ; aucun résultat de typecheck séparé disponible.
