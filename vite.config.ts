import { svelteTesting } from '@testing-library/svelte/vite';
import tailwindcss from '@tailwindcss/vite';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import { webSocketServer } from '$lib/ws-server';

export default defineConfig({
	plugins: [tailwindcss(), sveltekit(),
		 webSocketServer
		],
	// Enable debug logs
	// logLevel: 'info',
	  
	//   server: {
	// 	host: '0.0.0.0',
	// 	port: 9091,
	// 	strictPort: true,
		
	// 	// Fix for "[vite] server connection lost. Polling for restart..." error
	// 	hmr: {
	// 	  clientPort: 9091,
	// 	  host: '0.0.0.0',
	// 	  protocol: 'ws',
	// 	},
		
	// 	// Increase timeout for container networking
	// 	watch: {
	// 	  usePolling: true,
	// 	  interval: 1000,
	// 	}
	//   },




	test: {
		workspace: [
			{
				extends: './vite.config.ts',
				plugins: [svelteTesting()],
				test: {
					name: 'client',
					environment: 'jsdom',
					clearMocks: true,
					include: ['src/**/*.svelte.{test,spec}.{js,ts}'],
					exclude: ['src/lib/server/**'],
					setupFiles: ['./vitest-setup-client.ts']
				}
			},
			{
				extends: './vite.config.ts',
				test: {
					name: 'server',
					environment: 'node',
					include: ['src/**/*.{test,spec}.{js,ts}'],
					exclude: ['src/**/*.svelte.{test,spec}.{js,ts}']
				}
			}
		]
	}
});
