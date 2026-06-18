// boot_param — read a boot-time parameter, abstracting WHERE it comes from so the same
//  call works in the browser and in node (the headless Story runner, jsdom or bare):
//
//    • browser:  the URL query string        ?A=Editron&W=Ghost/Net/Easy
//    • node:     an env var (UPPERCASED name)  A=Editron  W=Ghost/Net/Easy
//
//  The boot knobs are `A` (the top-level Actor/world to stand up) and `W` (the Waft to open).
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
