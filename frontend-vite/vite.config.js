/// <reference types="vitest" />

import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],

  server: {
    allowedHosts: ['qrgenix.duckdns.org'],
  },

  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/vitest.setup.ts', // optional if you use jest-dom matchers
  },
})
