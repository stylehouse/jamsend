// Runs before any app module loads (vitest setupFiles).
// jsdom provides document/window but NOT indexedDB; Housing imports dexie.
// Stub indexedDB just enough that module-load doesn't throw. A pure Story run
//  shouldn't actually persist; if it does we'll see it and add a real fs adapter.
const g = globalThis as any
if (!g.indexedDB) {
    g.indexedDB = {
        open() {
            const req: any = { result: null, onsuccess: null, onerror: null, onupgradeneeded: null }
            return req
        },
        deleteDatabase() { return { onsuccess: null, onerror: null } },
        databases: async () => [],
        cmp: () => 0,
    }
}
g.requestAnimationFrame ||= (cb: any) => setTimeout(() => cb(Date.now()), 16)
g.cancelAnimationFrame ||= (id: any) => clearTimeout(id)

// jsdom omits matchMedia, but svelte/motion constructs a `prefers-reduced-motion`
//  MediaQuery AT MODULE LOAD (svelte/src/motion/index.js) — so merely importing
//   `Spring`/`Tween` (Cellui's Pixar swap does) throws `window.matchMedia is not a
//    function` and takes down the WHOLE headless boot, LocalGen included (the ghost
//     tree imports Cellui via Cello.svelte).  Stub it: matches:false = "no reduced
//      motion", the right headless default; the MediaQuery reads `.matches` and
//       subscribes via addEventListener, so both must exist.  Live browsers have the
//        real thing; this only fills the jsdom gap.
g.matchMedia ||= (query: string) => ({
    matches: false,
    media: String(query ?? ''),
    onchange: null,
    addEventListener() {},
    removeEventListener() {},
    addListener() {},        // deprecated alias some code still calls
    removeListener() {},
    dispatchEvent() { return false },
})
if (g.window && !g.window.matchMedia) g.window.matchMedia = g.matchMedia

// The machine is a perpetual reactive system with fire-and-forget elvises; sampling
//  it from a test and tearing down mid-flight legitimately leaves late promises that
//  reject (e.g. an elvis to a House we didn't spawn). Tolerate them so a clean run
//  exits 0 — a real assertion failure still fails the test.
process.on('unhandledRejection', () => {})
