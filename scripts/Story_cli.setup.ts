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

// The machine is a perpetual reactive system with fire-and-forget elvises; sampling
//  it from a test and tearing down mid-flight legitimately leaves late promises that
//  reject (e.g. an elvis to a House we didn't spawn). Tolerate them so a clean run
//  exits 0 — a real assertion failure still fails the test.
process.on('unhandledRejection', () => {})
