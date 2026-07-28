<script lang="ts">
    // UptimeFace — the live heartbeat cell (the human: "an uptime counter somewhere that I can see
    //  continuously update in the Vyto").  Ticks every second off its OWN timer — it never bumps the
    //   world, so the layout stays still (only this one face repaints; Svelte reactivity is scoped to
    //    the component, so this is safe with or without Vytui's idle gate).  `since` rides .c (runtime,
    //     never snapped): uptime is a LIVENESS fact, not state — it SHOULD reset on reload, and a
    //      near-zero reading right after a hard reload is the "did my reload actually land?" tell.
    let { n, H } = $props()

    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 1000)
        return () => clearInterval(iv)
    })

    let up = $derived.by(() => {
        void H?.version
        void tick
        const since = +(n?.c?.since ?? 0)
        const secs  = since ? Math.max(0, Math.round((Date.now() - since) / 1000)) : 0
        const h = Math.floor(secs / 3600)
        const m = Math.floor((secs % 3600) / 60)
        const s = secs % 60
        const label = h ? `${h}h ${m}m` : (m ? `${m}m ${s < 10 ? '0' : ''}${s}s` : `${s}s`)
        return { secs, label, fresh: since > 0 && secs < 10, beat: secs % 2 === 0 }
    })
</script>

<div class="uf" class:fresh={up.fresh}>
    <span class="uf-dot" class:beat={up.beat}></span>
    <span class="uf-label">{up.label}</span>
    <span class="uf-sub">{up.fresh ? 'fresh reload' : 'alive'}</span>
</div>

<style>
    .uf {
        display: flex; align-items: center; gap: 0.4rem;
        padding: 0.3rem 0.5rem; font-family: system-ui, sans-serif; color: #cfe0ff;
    }
    /* the beating heart — pulses once a second so "is it alive?" is answered at a glance */
    .uf-dot {
        width: 0.55rem; height: 0.55rem; border-radius: 50%; flex: none;
        background: #6fd08a; box-shadow: 0 0 7px rgba(110, 210, 140, 0.7);
        opacity: 0.3; transition: opacity 0.7s ease;
    }
    .uf-dot.beat { opacity: 1; }
    .uf-label { font-variant-numeric: tabular-nums; font-size: 1rem; font-weight: 600; }
    .uf-sub {
        font-size: 0.62rem; letter-spacing: 0.08em; text-transform: uppercase;
        color: rgba(150, 170, 205, 0.6);
    }
    /* a fresh reload flashes amber for its first 10s, so a reload is unmistakable */
    .uf.fresh .uf-dot { background: #f0c060; box-shadow: 0 0 8px rgba(240, 190, 110, 0.75); }
    .uf.fresh .uf-sub { color: rgba(240, 200, 150, 0.85); }
</style>
