import { describe, expect, it, vi } from 'vitest';
import { downloadCampaignVideo, isTrustedGoogleVideoUrl } from './campaign-video.server';

describe('URL de téléchargement vidéo', () => {
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
