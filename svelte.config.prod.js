import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://kit.svelte.dev/docs/integrations#preprocessors
	preprocess: vitePreprocess(),

	// Tell Svelte to treat .go files exactly like .svelte files.
	//  MUST match svelte.config.js — prod.sh copies THIS file over that one, so anything
	//   dev's config says and this one doesn't is a production-only failure.  Without it
	//    every generated ghost (33 of them, each a <script lang="ts"> file) reaches vite's
	//     import-analysis as raw JS and the dev server 500s on `</script>`.
	extensions: ['.svelte', '.go'],

	kit: {
		// Use adapter-node for production deployment
		adapter: adapter({
			out: 'build',
			precompress: false,
			envPrefix: ''
		}),
		
		// Production environment settings
		env: {
			publicPrefix: 'PUBLIC_'
		}
	},

	// Vite build configuration for debugging
	vite: {
		build: {
			// Generate source maps for debugging
			sourcemap: true,
			// Disable minification
			minify: false,
			// Keep original variable names
			target: 'esnext'
		}
	}
};

export default config;