<script lang="ts">
    // SchemeSwitcher — the critique surface (owner: "make it a switchable thing… so I can critique multiple
    //  at a time").  BigSoundland mounts THIS as the glass and passes the real live renderer as `vyto`, so the
    //   app opens on the normal Vyto view and a tiny faux-dropdown (beside the ▦ guts button) flips the SAME
    //    live House ({H}) through every C** renderer in place.  The choice PERSISTS across reloads (localStorage).
    //     One <svelte:boundary> per scheme — a scheme that throws can't take down the picker or its siblings,
    //      and 'live' (real Vyto) stays safe.
    import { onMount } from 'svelte'
    import Cellui        from '../Cellui.svelte'
    import SchemeMesh     from './schemes/SchemeMesh.svelte'
    import SchemeTree     from './schemes/SchemeTree.svelte'
    import SchemeStaff    from './schemes/SchemeStaff.svelte'
    import SchemeResidual from './schemes/SchemeResidual.svelte'

    // `vyto` = the ACTUAL renderer BigSoundland selected (Vytui/Cytui) — passed in so the default view is the
    //  real live glass with the correct house, not a re-imported one that might miss its commissioned world.
    let { H, vyto } = $props()

    // ── the renderers, in the owner's order: Vyto first, Cello the prominent one, the rest smaller ────────
    const SCHEMES = $derived([
        { key: 'live',     label: 'Vyto',      hint: 'the live glass',        comp: vyto },
        { key: 'cello',    label: 'Cello',     hint: 'cells',                 comp: Cellui },
        { key: 'residual', label: 'Residual',  hint: 'ink ∝ surprise',        comp: SchemeResidual },
        { key: 'mesh',     label: 'Mesh',      hint: 'atom-weave',            comp: SchemeMesh },
        { key: 'tree',     label: 'Tree',      hint: 'blob-nest',             comp: SchemeTree },
        { key: 'staff',    label: 'Staff',     hint: 'score',                 comp: SchemeStaff },
    ])

    // ── persistence — remember the last renderer across reloads ──────────────────────────────────────────
    //  Hydrate ONCE in onMount (so SSR renders the safe 'live' default and there's no hydration mismatch),
    //   then persist on every change.  Guarded — a private-mode / no-storage environment just doesn't persist.
    const STORE_KEY = 'cello:renderer'
    function stored(): string | null {
        try { return typeof localStorage !== 'undefined' ? localStorage.getItem(STORE_KEY) : null } catch { return null }
    }
    let which = $state('live')     // open on the real Vyto — the app looks normal until you flip a renderer
    let hydrated = $state(false)
    onMount(() => {
        const s = stored()
        if (s && SCHEMES.some(x => x.key === s)) which = s
        hydrated = true
    })
    $effect(() => {
        if (!hydrated) return
        try { localStorage.setItem(STORE_KEY, which) } catch { /* no-storage — don't persist */ }
    })

    let Current = $derived((SCHEMES.find(s => s.key === which) ?? SCHEMES[0]).comp)
    let currentLabel = $derived((SCHEMES.find(s => s.key === which) ?? SCHEMES[0]).label)

    // ── the faux dropdown ────────────────────────────────────────────────────────────────────────────────
    let open = $state(false)
    function pick(key: string) { which = key; open = false }
    // close on any press outside the picker (capture so it beats a child's stopPropagation)
    $effect(() => {
        if (!open || typeof window === 'undefined') return
        const close = (e: Event) => {
            if (!(e.target as HTMLElement)?.closest?.('.rswitch')) open = false
        }
        window.addEventListener('pointerdown', close, true)
        return () => window.removeEventListener('pointerdown', close, true)
    })

    // ── wheel over the switcher cycles renderers (owner: "mousewheel up or down … to switch") ────────────
    //  up = previous, down = next, wrapping.  Attached non-passive so we can swallow the page-scroll.
    function cycle(dir: number) {
        const keys = SCHEMES.map(s => s.key)
        const i = Math.max(0, keys.indexOf(which))
        which = keys[(i + dir + keys.length) % keys.length]
    }
    let rswitch_el = $state<HTMLDivElement | null>(null)
    $effect(() => {
        const el = rswitch_el
        if (!el) return
        const onwheel = (e: WheelEvent) => { e.preventDefault(); cycle(e.deltaY > 0 ? 1 : -1) }
        el.addEventListener('wheel', onwheel, { passive: false })
        return () => el.removeEventListener('wheel', onwheel)
    })
</script>

<div class="switch-root">
    <div class="switch-stage">
        {#if Current}
            <svelte:boundary>
                <Current {H} />
                {#snippet failed(err)}
                    <div class="switch-fail">this scheme threw — {String((err as any)?.message ?? err)}</div>
                {/snippet}
            </svelte:boundary>
        {:else}
            <div class="switch-fail">no renderer wired for “{which}”</div>
        {/if}
    </div>

    <!-- ── the faux dropdown — a tiny button beside the ▦ guts button (top-right corner) ── -->
    <div class="rswitch" class:open={open} bind:this={rswitch_el}>
        <button
            class="rswitch-toggle"
            onclick={() => (open = !open)}
            title="renderer: {currentLabel} — click to pick, or wheel to switch"
            aria-label="switch renderer (current: {currentLabel})"
            aria-expanded={open}
        >▤</button>
        {#if open}
            <div class="rswitch-menu" role="menu">
                {#each SCHEMES as s (s.key)}
                    <button
                        class="rswitch-item"
                        class:big={s.key === 'cello'}
                        class:small={s.key !== 'live' && s.key !== 'cello'}
                        class:on={which === s.key}
                        role="menuitemradio"
                        aria-checked={which === s.key}
                        onclick={() => pick(s.key)}
                    >
                        <span class="rswitch-name">{s.label}</span>
                        <span class="rswitch-hint">{s.hint}</span>
                    </button>
                {/each}
            </div>
        {/if}
    </div>
</div>

<style>
    .switch-root { min-height: 100vh; width: 100%; display: flex; flex-direction: column; background: #0b0d0c; }
    .switch-stage { position: relative; flex: 1 1 auto; min-height: 100vh; overflow: hidden; }
    .switch-fail { padding: 2rem; color: #d98; font: 13px monospace; }

    /* ── the faux dropdown — fixed, top-right, sitting to the LEFT of the ▦ .scape-guts button (which is
       at top:0;right:0, ~2rem wide).  Same quiet-corner discipline: near-invisible at rest, full on hover. */
    .rswitch { position: fixed; top: 0; right: 2.1rem; z-index: 1000000; font-family: inherit; }
    .rswitch-toggle {
        background: none; border: none; border-radius: 6px; cursor: pointer;
        color: #cfe0ff; opacity: 0.2; font-size: 1rem; line-height: 1; padding: 0.5rem 0.55rem;
        -webkit-tap-highlight-color: transparent; transition: opacity 0.15s ease, background 0.15s ease;
    }
    .rswitch-toggle:hover, .rswitch-toggle:focus-visible,
    .rswitch.open .rswitch-toggle { opacity: 1; background: rgba(120, 150, 210, 0.18); outline: none; }

    .rswitch-menu {
        position: absolute; top: 2rem; right: 0; min-width: 168px;
        display: flex; flex-direction: column; gap: 2px; padding: 5px;
        background: #121614; border: 1px solid #2c332f; border-radius: 8px;
        box-shadow: 0 10px 28px rgba(0, 0, 0, 0.55);
    }
    .rswitch-item {
        display: flex; align-items: baseline; gap: 8px; text-align: left;
        background: #1b201d; border: 1px solid #2c332f; border-radius: 6px;
        color: #cbd5d0; cursor: pointer; padding: 6px 10px; transition: background 0.12s;
        font: 12px/1.1 "Berkeley Mono", monospace;
    }
    .rswitch-item:hover { background: #242b27; }
    .rswitch-item.on { background: #e8c33a; color: #14110a; border-color: #e8c33a; }
    .rswitch-item.on .rswitch-hint { color: #6b5a12; }
    /* Cello is the prominent one; the rest are smaller (owner: "Vyto first, Cello big, the others smaller") */
    .rswitch-item.big  { padding: 9px 11px; font-size: 14px; font-weight: 600; }
    .rswitch-item.small { padding: 4px 10px; font-size: 11px; opacity: 0.9; }
    .rswitch-name { flex: 0 0 auto; }
    .rswitch-hint { color: #7f908a; font-size: 0.85em; }
    .rswitch-item.big .rswitch-hint { color: #9fb0a8; }
</style>
