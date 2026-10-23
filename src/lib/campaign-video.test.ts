import { describe, expect, it, vi } from 'vitest';
import { downloadCampaignVideo, isTrustedGoogleVideoUrl, submitCampaignVideo } from './campaign-video.server';

describe('URL de téléchargement vidéo', () => {
  it('utilise le repli Veo standard demandé sans changer le contrat asynchrone', async () => {
    vi.stubEnv('VIDEO_MODEL', '');
    const spy = vi.spyOn(globalThis, 'fetch').mockResolvedValue(new Response(JSON.stringify({ name: 'operations/example' }), { status: 200 }));
    try {
      const job = await submitCampaignVideo('Produit', 'TEST_KEY');
      expect(job.model).toBe('veo-3.1-generate-preview');
      expect(spy.mock.calls[0]?.[0]).toBe('https://generativelanguage.googleapis.com/v1beta/models/veo-3.1-generate-preview:predictLongRunning');
    } finally {
      spy.mockRestore();
      vi.unstubAllEnvs();
    }
  });
  it('accepte generativelanguage.googleapis.com et les sous-domaines googleapis.com', () => {
    expect(isTrustedGoogleVideoUrl('https://generativelanguage.googleapis.com/v1beta/files/abc:download')).toBe(true);
    expect(isTrustedGoogleVideoUrl('https://storage.googleapis.com/x')).toBe(true);
  });
  it('refuse les autres domaines et le http', () => {
    expect(isTrustedGoogleVideoUrl('https://evil.com/googleapis.com')).toBe(false);
    expect(isTrustedGoogleVideoUrl('https://googleapis.com.evil.com/x')).toBe(false);
    expect(isTrustedGoogleVideoUrl('http://generativelanguage.googleapis.com/x')).toBe(false);
    expect(isTrustedGoogleVideoUrl('pas une url')).toBe(false);
  });
  it("n'envoie pas la clé à un domaine non vérifié", async () => {
    const spy = vi.spyOn(globalThis, 'fetch');
    await expect(downloadCampaignVideo('https://evil.com/v.mp4', 'KEY')).rejects.toThrow('domaine non Google');
    expect(spy).not.toHaveBeenCalled();
    spy.mockRestore();
  });
});
