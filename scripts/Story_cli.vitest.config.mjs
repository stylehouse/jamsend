// Vitest config for the Story_cli runner / boot proof. Plain .mjs (NOT .ts) on
//  purpose: a .ts config makes vite bundle it into node_modules/.vite-temp, which is
//  root-owned in this container (EACCES). .mjs is imported directly — no temp write.
//   - jsdom env so client-compiled ghosts mount (onMount fires)
//   - bare svelte() (no sveltekit lifecycle restarts) + svelteTesting() for the
//     browser export condition (so mount() resolves the client runtime)
//   - pool:'forks' → each test file in a fresh child process
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { svelteTesting } from '@testing-library/svelte/vite'
import { defineConfig } from 'vitest/config'
import path from 'node:path'

const APP = path.resolve('.')

export default defineConfig({
    plugins: [svelte(), svelteTesting()],
    resolve: { alias: { $lib: path.join(APP, 'src/lib') }, conditions: ['browser'] },
    // a root-run dev server leaves /app/node_modules/.vite root-owned → EACCES when the
    //  svelte optimizer writes _svelte_metadata.json.  Point the cache at a node-writable
    //   /tmp dir (the proven LakeRace fix; --root was tried and breaks bare svelte resolution).
    cacheDir: '/tmp/story_cli_vite',
    server: { fs: { allow: [APP, '/tmp'] } },
    test: {
        environment: 'jsdom',
        include: [path.join(APP, 'scripts/**/*.spec.ts')],
        setupFiles: [path.join(APP, 'scripts/Story_cli.setup.ts')],
        testTimeout: 60_000,
        hookTimeout: 60_000,
        pool: 'forks',
        fileParallelism: false,
    },
})
