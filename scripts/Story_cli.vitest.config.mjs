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
    // run with --root /tmp/cliroot (node-writable) so .vite-temp/.vite land there,
    //  not in the root-owned /app/node_modules; allow serving the real /app files.
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
