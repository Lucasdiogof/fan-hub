import type { SocialPost, SocialProvider } from '../types';

export class InstagramProvider implements SocialProvider {
  name = 'instagram';

  constructor(private accessToken: string | null) {}

  async fetch(): Promise<SocialPost[]> {
    if (!this.accessToken) return [];
    // Real Meta Graph API integration — placeholder until credentials are configured.
    // Will use Business Discovery endpoint for @goiasoficial.
    console.log('instagram.fetch: META_ACCESS_TOKEN configured but integration not yet implemented');
    return [];
  }
}
