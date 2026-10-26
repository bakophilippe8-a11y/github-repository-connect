import type { CapacitorConfig } from '@capacitor/cli';

// TanStack Start/Nitro is a server-rendered app. Set the GitHub repository
// variable CAPACITOR_SERVER_URL to the deployed HTTPS app URL when the APK
// should load the hosted application instead of relying on a static export.
const serverUrl = process.env.CAPACITOR_SERVER_URL?.trim();

if (serverUrl && !/^https:\/\//i.test(serverUrl)) {
  throw new Error('CAPACITOR_SERVER_URL must be an HTTPS URL.');
}

const config: CapacitorConfig = {
  appId: 'com.bladers.agentsia',
  appName: 'Agents IA',
  webDir: 'dist',
  server: {
    ...(serverUrl ? { url: serverUrl } : {}),
    androidScheme: 'https',
    cleartext: true,
    errorPath: 'index.html',
  },
  android: {
    allowMixedContent: true,
  },
};

export default config;
