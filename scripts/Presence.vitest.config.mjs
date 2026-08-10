// Vitest config for Presence.spec.ts — Story_cli's config plus ONE alias.
//
//  Why a config of its own.  Presence.spec.ts is the only spec that needs BOTH halves at once: the
//   machine booted in JSDOM (so the ghosts mount and Creduler can acquire gen/N/Presence.go) AND the
//    REAL Node relay (src/lib/server/relay.ts, so the `who` answer is the actual server's, not a
//     hand-written stand-in).  Those two pull `ws` in opposite directions: Story_cli's config sets
//      resolve.conditions:['browser'] — needed for svelte's client runtime — and under that condition
//       bare `ws` resolves to its BROWSER shim, whose WebSocketServer is not a constructor.  relay.ts
//        imports `ws` itself, so no amount of care in the spec file fixes it.
//  An explicit alias is applied BEFORE conditions, so it wins: point `ws` at the real Node entry.
//   Scoped to this one file rather than added to Story_cli's shared config, because every other spec
//    is happier not having a Node socket library aliased in underneath it.
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { svelteTesting } from '@testing-library/svelte/vite'
import { defineConfig } from 'vitest/config'
import path from 'node:path'

const APP = path.resolve('.')

export default defineConfig({
    plugins: [svelte(), svelteTesting()],
    resolve: {
        alias: {
            $lib: path.join(APP, 'src/lib'),
            ws: path.join(APP, 'node_modules/ws/index.js'),   // ← the whole reason this config exists
        },
        conditions: ['browser'],
    },
    cacheDir: '/tmp/story_cli_vite',
    server: { fs: { allow: [APP, '/tmp'] } },
    test: {
        environment: 'jsdom',
        include: [path.join(APP, 'scripts/Presence.spec.ts')],
        setupFiles: [path.join(APP, 'scripts/Story_cli.setup.ts')],
        testTimeout: 60_000,
        hookTimeout: 60_000,
        pool: 'forks',
        fileParallelism: false,
    },
})
