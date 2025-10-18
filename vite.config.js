import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: process.env.VITE_API_URL || 'http://localhost:3001',
        changeOrigin: true,
        secure: false,
      }
    },
    // Add these for better static asset handling
    fs: {
      strict: false
    },
    // Disable HMR if not needed
    hmr: {
      overlay: false
    },
    // Ignore certain files to prevent unnecessary restarts
    watch: {
      ignored: [
        '**/node_modules/**',
        '**/package-lock.json',
        '**/.git/**',
        '**/dist/**'
      ]
    }
  },
  build: {
    // Increase chunk size warning limit
    chunkSizeWarningLimit: 1000,
    // Better source maps
    sourcemap: false,
    // Enable minification for production
    minify: 'terser',
    // Ensure proper module format
    rollupOptions: {
      output: {
        format: 'es',
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]'
      }
    }
  },
  // Add base URL if needed
  base: '/',
  // Improve asset handling
  assetsInclude: ['**/*.svg']
})