import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    ssr: true,
    outDir: 'dist-server',
    target: 'node18',
    rollupOptions: {
      input: 'server.ts',
      external: ['express', 'socket.io'] // Don't bundle Node.js deps
    }
  }
});

