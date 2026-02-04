import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    ssr: true,
    outDir: 'dist-server',
    // 1. Stop the squashing
    minify: false,
    // 2. Generate maps (true or 'inline')
    sourcemap: true, 
    // 3. Keep code modern to avoid transpilation "noise"
    target: 'esnext', 
    rollupOptions: {
      input: 'server.ts',
      external: ['express', 'socket.io'],
      output: {
        // 4. THIS is the "Less Compiley" secret: 
        // It outputs one file per source file instead of one big bundle.
        preserveModules: true,
        preserveModulesRoot: 'src', // adjust based on your file structure
        format: 'es',
        entryFileNames: '[name].js'
      }
    }
  }
});
