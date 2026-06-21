// scripts/compile.vite.config.ts — a minimal vite-node config for the UIless compile tools.
//
// lang-compile / compile_request only need vite's module loading (the lang registry's ?raw
//  grammar import, import.meta.glob, the external tokenizer) — NOT the sveltekit()/svelte
//   plugin. Loading the full app config drags in the svelte optimizer's buildStart, which writes
//    node_modules/.vite/_svelte_metadata.json; when that cache dir is root-owned (a host commit
//     run as root), a headless `node`-user compile dies with EACCES before it even parses a .g.
//   Pointing these tools at a plugin-free config sidesteps that entirely and keeps them runnable
//    on any infra, and a private cacheDir (overridable via VITE_CACHE_DIR) avoids the shared one.
import { defineConfig } from 'vite'

export default defineConfig({
	cacheDir: process.env.VITE_CACHE_DIR || 'node_modules/.vite-compile',
})
