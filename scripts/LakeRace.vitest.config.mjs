// Vitest config for the LakeRace headless compile harness. Same shape as
//  Story_cli.vitest.config.mjs, but cacheDir → a node-writable /tmp dir: the dev
//   server (run as root) leaves /app/node_modules/.vite root-owned → EACCES for a
//    node-user vitest. Overriding cacheDir (not --root, which breaks bare module
//     resolution) keeps node_modules resolution at /app while parking the cache in /tmp.
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { svelteTesting } from '@testing-library/svelte/vite'
import { defineConfig } from 'vitest/config'
import path from 'node:path'

const APP = path.resolve('.')

export default defineConfig({
    cacheDir: '/tmp/lakerace-vite',
    plugins: [svelte(), svelteTesting()],
    resolve: { alias: { $lib: path.join(APP, 'src/lib') }, conditions: ['browser'] },
    server: { fs: { allow: [APP, '/tmp'] } },
    test: {
        environment: 'jsdom',
        include: [path.join(APP, 'scripts/LakeRace.spec.ts')],
        setupFiles: [path.join(APP, 'scripts/Story_cli.setup.ts')],
        testTimeout: 120_000,
        hookTimeout: 120_000,
        pool: 'forks',
        fileParallelism: false,
    },
})
