import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig, loadEnv, type PluginOption } from 'vite';
import { attachRelay } from './src/lib/server/relay';
import { serve_diges, write_status_waft } from './src/lib/server/dige';

// Root .env/.env.local, merged under process.env (env_file injection wins).  This is how
//  site-specific names/creds stay OUT of tracked files: PROD_DOMAIN &c. live in the
//   gitignored .env and get baked below.  (A comment further down used to claim /app/.env
//    is a directory here and loadEnv would trip — measured 2026-08-14: it is a plain file;
//     the try/catch keeps a broken .env from taking the whole config down regardless.)
let dotenv: Record<string, string> = {};
try { dotenv = loadEnv(process.env.NODE_ENV === 'production' ? 'production' : 'development', process.cwd(), ''); } catch {}
const env = (k: string) => process.env[k] ?? dotenv[k] ?? '';

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
//  (Reads process.env first — env_file injection — falling back to the root .env via the
//   loadEnv merge at the top of this file.)
//  host.docker.internal is ALWAYS allowed on top of the env list: it's how a flock runner
//  container reaches the host dev server (dockers/flock TARGET_BASE). It's a Docker-internal
//  alias — functionally localhost-from-a-container, not a public domain — so it widens no
//  public surface. IP-literal Hosts (e.g. the bridge gateway 172.17.0.1 the CLI uses) need
//  no allowlist entry; Vite always serves those.
const allowedHosts = [
	'host.docker.internal',
	...env('ALLOWED_HOSTS').split(',').map(h => h.trim()).filter(Boolean),
];

// Atlas's dige index, served from the process that holds the repo (src/lib/server/dige.ts explains
//  why here and not a new container).  Same dev-only shape as relayPlugin: configureServer never
//   runs in a build, so this adds no production surface.  A tab that cannot reach it simply falls
//    back to reading + diging each file itself, which is what it did before.
function digePlugin(): PluginOption {
	return {
		name: 'atlas-dige',
		configureServer(server) {
			server.middlewares.use((req, res, next) => {
				try { if (serve_diges(process.cwd(), req, res)) return } catch { /* fall through to vite */ }
				next();
			});

			// THE STATUS WAFT, written on boot and kept fresh on change (Docindex_todo).
			//  VITE IS ALREADY THE INOTIFY DAEMON — chokidar watching is how HMR works — so the
			//   "watcher process" the design wanted is a process you are already running.  A separate
			//    container was considered and refused: a third image sharing /app/node_modules is the
			//     documented 2026-08-07 outage (Alpine/musl vs Debian/glibc native binaries), so the
			//      cheapest option and the safest option are the same one here.
			//  Debounced because a save storm (a branch switch, a LocalGen run writing 12 gen files)
			//   would otherwise rewrite the file a dozen times; `write_status_waft` also no-ops when the
			//    text is unchanged, so a touched-but-identical file costs a stat sweep and no disk write.
			let pending: NodeJS.Timeout | null = null;
			const refresh = (why: string) => {
				if (pending) clearTimeout(pending);
				pending = setTimeout(() => {
					pending = null;
					try {
						const t0 = Date.now();
						const r = write_status_waft(process.cwd());
						if (r.changed) console.log(`🗂 status waft: ${r.docs} docs (${why}, ${Date.now() - t0}ms)`);
					} catch (e) { console.warn('🗂 status waft failed', e); }
				}, 400);
			};
			refresh('boot');
			// only source changes matter — the file we write lives under wormhole/, so reacting to it
			//  would be a loop that never settles
			const interesting = (p: string) => /\.(g|svelte|ts|md)$/.test(p) && !p.includes('/wormhole/');
			for (const ev of ['add', 'change', 'unlink'] as const)
				server.watcher.on(ev, (p: string) => { if (interesting(p)) refresh(ev); });
		},
	};
}

export default defineConfig({
	plugins: [sveltekit(), relayPlugin(), digePlugin()],

	// Bake the cluster's PUBLIC trust anchors into the client so the browser can VERIFY inbound
	//  signed frames (this-dock-updated, etc.). Sourced from process.env (compose env_file
	//   .env.cluster-identos) — same pattern as ALLOWED_HOSTS above. Only the PUBLIC pubs + the role
	//    LABEL cross into the bundle; CLUSTER_IDENTO_*_KEY (the secrets) are NEVER referenced here, so
	//     they cannot leak into client code. The browser editor's own signing key comes from
	//      localStorage (per-profile, out-of-band), not from any baked env.
	define: {
		'import.meta.env.VITE_CLUSTER_TRUSTED_PUBS': JSON.stringify(process.env.CLUSTER_TRUSTED_PUBS ?? ''),
		'import.meta.env.VITE_CLUSTER_ROLE':         JSON.stringify(process.env.CLUSTER_ROLE ?? ''),
		// This site's public name + TURN credentials, baked for the client's ICE config
		//  (Peerily's Peer_OPTIONS + the /ice probe page).  From the gitignored .env — no
		//   deployment's domain or TURN cred is committed.  Unset ⇒ '' ⇒ the own-infra ICE
		//    entries are simply omitted and the public STUN list carries a fresh clone.
		//     (TURN creds are inherently client-visible — every browser gets them — so
		//      baking them into the bundle leaks nothing the TURN protocol doesn't.)
		'import.meta.env.VITE_PROD_DOMAIN': JSON.stringify(env('PROD_DOMAIN')),
		'import.meta.env.VITE_TURN_USER':   JSON.stringify(env('TURN_USER')),
		'import.meta.env.VITE_TURN_CRED':   JSON.stringify(env('TURN_CRED')),
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
