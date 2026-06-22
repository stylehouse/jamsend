import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig, type PluginOption } from 'vite';
import { attachRelay } from './src/lib/server/relay';

// Peeroleum's real websocket transport (heading 10): attach the /relay endpoint to the dev
//  server's http server.  configureServer runs only under `vite dev` (not build), so this is
//   dev-only; production would call attachRelay() on its own http server.  See src/lib/server/relay.ts.
function relayPlugin(): PluginOption {
	return {
		name: 'peeroleum-relay',
		configureServer(server) {
			if (server.httpServer) attachRelay(server.httpServer);
		},
	};
}

// Hosts Vite will serve to beyond localhost (which is always allowed).  Sourced from the
//  ALLOWED_HOSTS env var — comma-separated, injected by docker-compose's env_file
//  (.env.local) — so the public domains live in an untracked .env, not in this tracked
//  file, and can be phased out by editing one line with no code change.  Empty default =
//  localhost-only, the secure posture: a stray public hostname is refused, not served.
//  (Read straight off process.env, not Vite's loadEnv, because /app/.env is a directory
//   here and loadEnv would trip over it.)
const allowedHosts = (process.env.ALLOWED_HOSTS ?? '')
	.split(',').map(h => h.trim()).filter(Boolean);

export default defineConfig({
	plugins: [sveltekit(), relayPlugin()],

	// Bake the cluster's PUBLIC trust anchors into the client so the browser can VERIFY inbound
	//  signed frames (this-dock-updated, etc.). Sourced from process.env (compose env_file
	//   .env.cluster-identos) — same pattern as ALLOWED_HOSTS above. Only the PUBLIC pubs + the role
	//    LABEL cross into the bundle; CLUSTER_IDENTO_*_KEY (the secrets) are NEVER referenced here, so
	//     they cannot leak into client code. The browser editor's own signing key comes from
	//      localStorage (per-profile, out-of-band), not from any baked env.
	define: {
		'import.meta.env.VITE_CLUSTER_TRUSTED_PUBS': JSON.stringify(process.env.CLUSTER_TRUSTED_PUBS ?? ''),
		'import.meta.env.VITE_CLUSTER_ROLE':         JSON.stringify(process.env.CLUSTER_ROLE ?? ''),
	},

	build: {
		// Generate source maps for production debugging
		sourcemap: true,
		
		// Disable minification to make debugging easier
		minify: false,
		
		// Keep original variable names
		target: 'esnext',
		
		// Increase chunk size warning limit (optional)
		chunkSizeWarningLimit: 1000
	},
	

	server: {
		allowedHosts
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
