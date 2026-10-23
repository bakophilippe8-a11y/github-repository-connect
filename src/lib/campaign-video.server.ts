import { generateVideo, getVideoJobStatus } from '@tanstack/ai';
import { lovableVideo } from '@tanstack/ai-lovable';
import { VIDEO_SECONDS } from './video-prompt';

type VideoModel = Parameters<typeof lovableVideo>[0];
const model = () => (process.env['VIDEO_MODEL'] || 'google/veo-3.1-lite') as VideoModel;

/** Lance un job vidéo asynchrone (clip vertical 720x1280). Facturé par seconde de vidéo terminée. */
export async function submitCampaignVideo(prompt: string) {
  const adapter = lovableVideo(model());
  const { jobId } = await generateVideo({ adapter, prompt, size: '720x1280', duration: VIDEO_SECONDS });
  return { jobId, model: model() as string };
}

export async function pollCampaignVideo(jobId: string) {
  return getVideoJobStatus({ adapter: lovableVideo(model()), jobId });
}
