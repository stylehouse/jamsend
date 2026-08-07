// Vite config for the daemon entrypoint (run under vite-node, NOT vitest).  A near-copy of
//  scripts/Story_cli.vitest.config.mjs minus the `test` block — same three load-bearing bits:
//   - svelte() bare (no sveltekit lifecycle) so .svelte compiles
//   - svelteTesting() for the `browser` export condition, so `mount()` resolves the CLIENT
//     svelte runtime rather than the SSR one (the SSR runtime no-ops $effect — the machine
//     would boot and never think)
//   - cacheDir under /tmp: /app/node_modules/.vite is root-owned in this container (EACCES)
//  Plain .mjs on purpose (a .ts config gets bundled into a root-owned node_modules/.vite-temp).
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { svelteTesting } from '@testing-library/svelte/vite'
import { defineConfig } from 'vite'
import path from 'node:path'

const APP = path.resolve('.')

export default defineConfig({
    plugins: [svelte(), svelteTesting()],
    resolve: {
        alias: {
            $lib: path.join(APP, 'src/lib'),
            // `dexie` → a file-backed key-value stand-in, for the daemon ONLY.  The app's own
            //  `import { Dexie, liveQuery } from 'dexie'` resolves here in this process and stays
            //   the real Dexie everywhere else — so persistence works headlessly, durably, and with
            //    no npm install (which in this repo means no libc-drift risk).  See dexie-node.ts.
            dexie: path.join(APP, 'scripts/daemon/dexie-node.ts'),
        },
        conditions: ['browser'],
    },
    cacheDir: '/tmp/daemon_vite',
    server: { fs: { allow: [APP, '/tmp'] } },
})
