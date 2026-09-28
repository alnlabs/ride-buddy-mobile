const DEFAULT_API = 'http://127.0.0.1:8080/api/v1';

export const Env = {
  get apiBaseUrl(): string {
    return process.env.EXPO_PUBLIC_API_BASE_URL?.trim() || DEFAULT_API;
  },

  get googleMapsKey(): string | undefined {
    const key = process.env.EXPO_PUBLIC_GOOGLE_MAPS_API_KEY?.trim();
    if (!key || key === 'your_google_maps_key') return undefined;
    return key;
  },

  get apiOrigin(): string {
    const uri = new URL(this.apiBaseUrl);
    const segments = uri.pathname.split('/').filter(Boolean);
    if (segments.length >= 2 && segments[segments.length - 2] === 'api' && segments[segments.length - 1] === 'v1') {
      segments.splice(-2);
    }
    uri.pathname = segments.length ? `/${segments.join('/')}` : '';
    return uri.toString().replace(/\/$/, '');
  },

  wsNativeUrl(accessToken: string): string {
    const origin = new URL(this.apiOrigin);
    const scheme = origin.protocol === 'https:' ? 'wss:' : 'ws:';
    const path = [...origin.pathname.split('/').filter(Boolean), 'ws-native'].join('/');
    const url = new URL(`${scheme}//${origin.host}/${path}`);
    url.searchParams.set('access_token', accessToken);
    return url.toString();
  },
};
