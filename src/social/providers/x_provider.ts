import type { SocialPost, SocialProvider } from '../types';

export class XProvider implements SocialProvider {
  name = 'x';

  constructor(private bearerToken: string | null) {}

  async fetch(): Promise<SocialPost[]> {
    if (!this.bearerToken) return [];
    // Real X API integration — placeholder until credentials are configured.
    // Will use the user timeline endpoint for @goiasoficial.
    console.log('x.fetch: X_BEARER_TOKEN configured but integration not yet implemented');
    return [];
  }
}
