// Headless stub for SvelteKit's `$app/navigation` virtual module.  The real one is provided by the
//  SvelteKit vite plugin in the running dev server (where LinkDevice/InvitePanel call `replaceState`
//   to rewrite the ?Iz/?I bar without navigating).  The Story_cli / LocalGen vitest config uses bare
//    `svelte()` (no sveltekit plugin), so `$app/navigation` is unresolvable there and any .svelte that
//     imports it fails to transform — breaking Book compilation + the boot proof.  This no-op stub, aliased
//      in Story_cli.vitest.config.mjs, lets those files load headless; the bar-rewrite is a live-tab concern
//       only, so no-ops are exactly right (jsdom has no address bar worth keeping in step).
export function goto() { return Promise.resolve() }
export function replaceState() {}
export function pushState() {}
export function invalidate() { return Promise.resolve() }
export function invalidateAll() { return Promise.resolve() }
export function preloadData() { return Promise.resolve() }
export function preloadCode() { return Promise.resolve() }
export function beforeNavigate() {}
export function afterNavigate() {}
export function onNavigate() {}
export function disableScrollHandling() {}
export function pushStateExternal() {}
