// boot_param — read a boot-time parameter, abstracting WHERE it comes from so the same
//  call works in the browser and in node (the UIless Story runner, jsdom or bare):
//
//    • browser:  the URL query string        ?B=Editron&W=Ghost/Net/Easy
//    • node:     an env var (UPPERCASED name)  B=Editron  W=Ghost/Net/Easy
//
//  The boot knobs: `A` (top-level world, default Auto), `B` (a Story Book for Auto to activate —
//   ?B=Editron boots the editor, ?B=Peregrination the runner), `W` (the Waft a Book opens).
//  Returns undefined when unset, so callers apply their own default (e.g. `|| 'Auto'`).
//  jsdom defines an (empty) `location`, so under vitest the URL branch simply misses and we
//   fall through to env — i.e. a CLI run drives the same knobs the browser drives via the URL.
//  `process` is absent in the browser bundle, hence the typeof guard (no ReferenceError).
export function boot_param(name: string): string | undefined {
    if (typeof location !== 'undefined' && location.search) {
        const v = new URLSearchParams(location.search).get(name)
        if (v != null) return v
    }
    if (typeof process !== 'undefined' && process.env) {
        const v = process.env[name.toUpperCase()]
        if (v != null && v !== '') return v
    }
    return undefined
}
