// cyto_lazy.ts — the lazy loader for cytoscape + its 4 layout plugins (Track B Stage 0, 2026-08-29).
//  These ~200KB used to ride the BOOT chunk: Ghost.svelte statically imports Cyto.svelte, which statically
//   imports Cytui.svelte, which statically imported the library — so every cold tab paid for it, even though
//    the LIVE app renders through Vyto (and, soon, Cello) and only `useCyto` Books ever build a graph.
//  Load it on demand instead, at the single point Cytui constructs its `cy` instance.  A module-SINGLETON
//   promise so N Cytui mounts import + register exactly once (cytoscape.use warns if an extension is
//    registered twice).  The library symbol is confined to this file; Cytui's 139 `cy.` call sites are
//     untouched — they run on the built instance, which only exists after this resolves.
//  ⚠ WHY A .ts MODULE, NOT A `<script module>` IN Cytui: vite-plugin-svelte refuses HMR self-acceptance to
//   any component carrying module-context state (glass_kinds.ts:62 — the trap that made Vytui a full-page
//    reload on every edit, wiping player tabs' AudioContext).  Keeping the singleton out here leaves Cytui
//     free of module state, so it stays hot-updatable.
let _cyto_p: Promise<any> | null = null

export function load_cytoscape(): Promise<any> {
    if (!_cyto_p) _cyto_p = (async () => {
        const [cy, fcose, coseBilkent, cola, dagre] = await Promise.all([
            import('cytoscape'),
            import('cytoscape-fcose'),
            import('cytoscape-cose-bilkent'),
            import('cytoscape-cola'),
            import('cytoscape-dagre'),
        ])
        const cytoscape = cy.default
        cytoscape.use(fcose.default)
        cytoscape.use(coseBilkent.default)
        cytoscape.use(cola.default)
        cytoscape.use(dagre.default)
        return cytoscape
    })()
    return _cyto_p
}
