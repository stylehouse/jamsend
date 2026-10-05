import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

const config = {
	preprocess: vitePreprocess(),
	// outDir from the env (2026-10-04): any fresh process loading the sveltekit plugin rewrites every file under
	//  outDir (its skip-unchanged cache is in-memory), and :9091's Vite answers with a full reload to EVERY live tab.
	//   A spare server runs as `SVELTEKIT_OUTDIR=.svelte-kit-9099 npx vite dev --port 9099` and leaves .svelte-kit alone.
	kit: { adapter: adapter(), outDir: process.env.SVELTEKIT_OUTDIR || '.svelte-kit' },
	// Tell Svelte to treat .go files exactly like .svelte files
    extensions: ['.svelte', '.go'],
};

export default config;
