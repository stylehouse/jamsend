// run.mjs — the daemon's launcher.  `node scripts/daemon/run.mjs` and nothing else.
//
// WHY NOT just `vite-node main.ts`: vite-node's CLI defaults every module to the **ssr** transform
//  mode, and vite-plugin-svelte compiles for SSR under that flag — so `mount()` gets a render
//   function instead of a component and the machine never thinks.  (That is also why every headless
//    boot in this repo runs under vitest: `environment: jsdom` flips vitest's transformMode to web.)
//  vite-node's PROGRAMMATIC api takes the transformMode we need, so the daemon stays a plain node
//   process instead of pretending to be a test.
//
//   node scripts/daemon/run.mjs            # forever
//   SECS=60 node scripts/daemon/run.mjs    # smoke run
import { createServer } from 'vite'
import { ViteNodeServer } from 'vite-node/server'
import { ViteNodeRunner } from 'vite-node/client'
import { installSourcemapsSupport } from 'vite-node/source-map'
import path from 'node:path'

const APP = path.resolve(path.join(import.meta.dirname, '../..'))

const server = await createServer({
    configFile: path.join(APP, 'scripts/daemon/daemon.vite.config.mjs'),
    root: APP,
    // The dep pre-bundler rewrites imports to /@fs/… dev-server URLs that vite-node cannot resolve
    //  ("Cannot find module '/@fs/tmp/daemon_vite/deps/chunk-….js'" — the first failure here).
    //   Nothing needs pre-bundling in a node process; turn discovery off entirely.
    optimizeDeps: { noDiscovery: true, include: [] },
    server: { middlewareMode: true, watch: null, hmr: false },
    logLevel: 'warn',
})
await server.pluginContainer.buildStart({})

const node = new ViteNodeServer(server, {
    // web for everything: these modules are the browser bundle, they just happen to be running
    //  in a process with a jsdom bolted on.  ssr mode would SSR-compile the .svelte files.
    transformMode: { web: [/.*/], ssr: [] },
})
installSourcemapsSupport({ getSourceMap: source => node.getSourceMap(source) })

const runner = new ViteNodeRunner({
    root: server.config.root,
    base: server.config.base,
    fetchModule: (id) => node.fetchModule(id),
    resolveId: (id, importer) => node.resolveId(id, importer),
})

try {
    await runner.executeFile(path.join(APP, 'scripts/daemon/main.ts'))
} finally {
    await server.close()
}
