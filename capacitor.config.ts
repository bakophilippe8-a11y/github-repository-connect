import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.bladers.agentsia',
  appName: 'Agents IA',
  webDir: 'dist',
  server: {
    // Force Capacitor à servir les fichiers locaux et requêtes sous le schéma sécurisé HTTPS
    androidScheme: 'https',
    cleartext: true,
    errorPath: 'index.html'
  },
  android: {
    allowMixedContent: true
  }
};

export default config;
