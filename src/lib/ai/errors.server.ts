/** Erreur dont le message est destiné à l'utilisateur (aucune donnée interne). */
export class SafeError extends Error {
  constructor(message: string) { super(message); this.name = 'SafeError'; }
}

const MESSAGES: Record<number, string> = {
  401: 'La configuration du service IA est invalide.',
  402: 'Crédits IA insuffisants. Rechargez vos crédits puis relancez le traitement.',
  403: 'Le service IA a refusé la requête. Contactez le support si le problème persiste.',
  404: 'Modèle IA introuvable. Vérifiez la configuration du modèle.',
  429: 'Trop de requêtes vers le service IA. Réessayez dans un instant.',
};

/** Convertit toute erreur en statut + message sûr ; le détail reste dans les journaux serveur. */
export function classifyAiFailure(error: unknown) {
  const failure = error as { statusCode?: number; message?: string; name?: string };
  console.error('[ai] échec', failure?.statusCode ?? 'sans-statut', failure?.message);
  if (error instanceof SafeError) return { status: 500, message: error.message };
  const status = typeof failure?.statusCode === 'number' ? failure.statusCode : 500;
  return { status, message: MESSAGES[status] ?? 'Le traitement a échoué. Réessayez dans un instant.' };
}

/**
 * Seule l'absence de crédits justifie une suspension persistante de l'IA.
 * Un 403/404 (modèle mal configuré, incident passager) est signalé sans bloquer le vendeur.
 */
export const shouldPauseAi = (status: number) => status === 402;
