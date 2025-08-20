// vite.config.ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import laravel from 'laravel-vite-plugin'
import tailwindcss from '@tailwindcss/vite'

const port = Number(process.env.VITE_PORT || 5173)
const hmrHost = process.env.VITE_HMR_HOST || 'host.docker.internal'
const hmrClientPort = Number(process.env.VITE_HMR_CLIENT_PORT || port)

export default defineConfig({
  plugins: [
    laravel({
      input: ['resources/js/app.ts'],
      ssr: 'resources/js/ssr.ts',
      refresh: true,
    }),
    tailwindcss(),
    vue({
      template: {
        transformAssetUrls: { base: null, includeAbsolute: false },
      },
    }),
  ],
  server: {
    host: true,
    port,
    strictPort: true,
    watch: { usePolling: true, interval: 100 },
    hmr: { host: hmrHost, clientPort: hmrClientPort },
  },
})
