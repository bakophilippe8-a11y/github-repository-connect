import { VIDEO_SECONDS } from './video-prompt';

/**
 * Vidéo de campagne via Veo (API Gemini), avec la clé API Google du vendeur :
 * la génération est facturée par Google directement sur le compte du vendeur.
 * Flux asynchrone de l'API Gemini : lancement (predictLongRunning) puis interrogation de l'opération.
 */
const API = 'https://generativelanguage.googleapis.com/v1beta';
// Repli demandé ; Google annonce l'arrêt de ces previews le 22 octobre 2026.
// Un modèle de remplacement nécessite de vérifier également son contrat API.
const model = () => process.env['VIDEO_MODEL'] || 'veo-3.1-generate-preview';

type GoogleError = { error?: { code?: number; message?: string; status?: string } };

async function googleError(response: Response): Promise<never> {
  const body = await response.json().catch(() => ({})) as GoogleError;
  const status = body.error?.code ?? response.status;
  const error = new Error(`Google Veo: ${body.error?.status ?? response.status} ${body.error?.message ?? ''}`.trim());
  (error as Error & { statusCode: number }).statusCode = status;
  throw error;
}

/** Lance un job vidéo asynchrone (clip vertical 9:16). Facturé par Google au compte du vendeur. */
export async function submitCampaignVideo(prompt: string, apiKey: string) {
  const response = await fetch(`${API}/models/${model()}:predictLongRunning`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
    body: JSON.stringify({
      instances: [{ prompt }],
      parameters: { aspectRatio: '9:16', durationSeconds: VIDEO_SECONDS, resolution: '720p' },
    }),
  });
  if (!response.ok) await googleError(response);
  const operation = await response.json() as { name?: string };
  if (!operation.name) throw new Error('Google Veo: opération sans identifiant.');
  return { jobId: operation.name, model: model() };
}

export type VideoJob =
  | { status: 'generating'; progress?: number }
  | { status: 'failed'; error?: string }
  | { status: 'completed'; url: string };

/** Interroge l'opération Veo. L'URL retournée exige l'en-tête x-goog-api-key au téléchargement. */
export async function pollCampaignVideo(jobId: string, apiKey: string): Promise<VideoJob> {
  const response = await fetch(`${API}/${jobId}`, { headers: { 'x-goog-api-key': apiKey } });
  if (!response.ok) await googleError(response);
  const operation = await response.json() as {
    done?: boolean;
    error?: { code?: number; message?: string };
    response?: {
      generateVideoResponse?: { generatedSamples?: { video?: { uri?: string } }[] };
      videos?: { uri?: string; gcsUri?: string }[];
      raiMediaFilteredCount?: number;
    };
  };
  if (operation.error) return { status: 'failed', error: operation.error.message ?? 'Échec inconnu.' };
  if (!operation.done) return { status: 'generating' };
  const uri = operation.response?.generateVideoResponse?.generatedSamples?.[0]?.video?.uri
    ?? operation.response?.videos?.[0]?.uri
    ?? operation.response?.videos?.[0]?.gcsUri;
  if (!uri) return { status: 'failed', error: 'Vidéo filtrée ou absente de la réponse.' };
  return { status: 'completed', url: uri };
}

/** N'accepte que des URL https sur googleapis.com (ou un sous-domaine) avant d'y envoyer la clé. */
export function isTrustedGoogleVideoUrl(url: string) {
  try {
    const { protocol, hostname } = new URL(url);
    const host = hostname.toLowerCase();
    return protocol === 'https:' && (host === 'googleapis.com' || host.endsWith('.googleapis.com'));
  } catch { return false; }
}

/** Télécharge la vidéo générée (l'URL Google exige la clé API du vendeur). */
export async function downloadCampaignVideo(url: string, apiKey: string) {
  if (!isTrustedGoogleVideoUrl(url)) throw new Error('Adresse de la vidéo refusée : domaine non Google, la clé IA n’est pas envoyée.');
  const file = await fetch(url, { headers: { 'x-goog-api-key': apiKey }, signal: AbortSignal.timeout(60000) });
  if (!file.ok) await googleError(file);
  return file;
}
