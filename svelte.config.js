import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

const config = {
	preprocess: vitePreprocess(),
	kit: { adapter: adapter() },
	// Tell Svelte to treat .go files exactly like .svelte files
    extensions: ['.svelte', '.go'],
};

export default config;
