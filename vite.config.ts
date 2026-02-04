import { svelteTesting } from '@testing-library/svelte/vite';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
// import { webSocketServer } from './src/lib/abandoned/ws-server/ws-server';

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
  },
	plugins: [sveltekit(),
		//  webSocketServer
		],



	server: {
		allowedHosts: ["jamsend.duckdns.org","djamsend.duckdns.org","jamdense.duckdns.org"]
	}
	// test: {
	// 	workspace: [
	// 		{
	// 			extends: './vite.config.ts',
	// 			plugins: [svelteTesting()],
	// 			test: {
	// 				name: 'client',
	// 				environment: 'jsdom',
	// 				clearMocks: true,
	// 				include: ['src/**/*.svelte.{test,spec}.{js,ts}'],
	// 				exclude: ['src/lib/server/**'],
	// 				setupFiles: ['./vitest-setup-client.ts']
	// 			}
	// 		},
	// 		{
	// 			extends: './vite.config.ts',
	// 			test: {
	// 				name: 'server',
	// 				environment: 'node',
	// 				include: ['src/**/*.{test,spec}.{js,ts}'],
	// 				exclude: ['src/**/*.svelte.{test,spec}.{js,ts}']
	// 			}
	// 		}
	// 	]
	// }
});
