<script lang="ts">
    // PoolFace — the %Pooling CELL as ONE SENTENCE (owner 2026-09-03, the final cut):
    //   "SoundPool keeps rolling [ 300 ] MB of music in browser storage, sourced from [ ] friends (less
    //    predictable) and [x] crew (your devices, see Door)"
    //  One number, three checkboxes.  0 MB = off (Ra_pool_off cleans out).  A number = on (Ra_pool_start —
    //   consent, budget, one rolling random compartment).  The first two are `who`.  "then one day we can point
    //    it places".  Face contract: { n: TheC, H: House }; every read re-derives off H.version.
    //  ── AND [x] RECENT ACQUISITIONS (owner 2026-09-04: *"perhaps soundpooling also defaults on a [x] recent
    //   acquisitions"*).  A second compartment taking half the budget, drawn from the newlyadded ledger: what
    //    landed on your share lately also gets a lofi copy on the phone.  Heist it on the desktop, hear it on
    //     the bus.  THE DEFAULT LIVES HERE, not in Ra_pool_start, because it is a fact about the sentence
    //      rather than about the machine — Ra_pool_start stays the one-compartment door it says it is, and
    //       every pool fixture keeps meaning what it meant.  It is only defaulted at a FIRST yes; after that
    //        the checkbox is the human's and is never re-asserted under them.
    let { n, H } = $props()
    let pose = $derived.by(() => { void H?.version; return String(n?.c?.pose ?? 'big') })
    let small = $derived(pose === 'small')
    const top = () => H?.top_House?.() ?? H
    const world = () => top()?.c?.radio_w ?? null

    let consent = $state(false)
    let budget = $state(0)
    let who = $state('crew')
    let recent = $state(true)
    let pooled = $state(0)
    let free_gb = $state<number | null>(null)
    $effect(() => {
        void H?.version
        const w = world()
        if (!w) { consent = false; budget = 0; pooled = 0; return }
        try {
            consent = !!H.Ra_pool_consent?.(w)
            budget = +(H.Ra_pool_budget?.(w) || 0)
            who = String(H.Ra_pool_who?.(w) || 'crew')
            // before the first yes there is no compartment to read, so the checkbox shows the DEFAULT it
            //  will act on; afterwards it shows what actually stands.
            recent = consent ? !!H.Ra_pool_recent_on?.(w) : true
            const pub = H.Radio_pub?.(w) || 'me'
            const shelf = H.Ra_pool_stock?.(w, pub) ?? null   // probed, never minted
            pooled = shelf && H.Ra_recs ? (H.Ra_recs(shelf) as any[]).length : 0
        } catch {}
    })
    $effect(() => {
        let gone = false
        try { navigator.storage?.estimate?.().then((e: any) => { if (gone || !e) return; const q = +(e.quota || 0), u = +(e.usage || 0); if (q > 0) free_gb = Math.max(0, Math.round((q - u) / 1e8) / 10) }).catch(() => {}) } catch {}
        return () => { gone = true }
    })
    let draft = $state(300)
    $effect(() => { if (consent) draft = budget })
    const bump = () => { try { top()?.bump_version?.() } catch {} }
    const friends = $derived(who === 'all' || who === 'friends')
    const crew = $derived(who === 'all' || who === 'crew')
    function set_mb(v: number) {
        const w = world(); if (!w) return
        draft = Math.max(0, Math.floor(v || 0))
        try {
            if (draft === 0) { if (consent) { const p = H.Ra_pool_off?.(w); if (p && p.then) p.then(bump, bump); else bump() } }
            else if (consent) { H.Ra_pool_budget_set?.(w, draft); bump() }
            else {
                H.Ra_pool_start?.(w, draft, Math.floor(Date.now() / 1000), who)
                // the FIRST yes is where the default is applied — one act, so a person who unticked it
                //  before typing a number gets what they asked for and not what we assumed.
                if (recent) { H.Ra_pool_recent_set?.(w, 1) }
                bump()
            }
        } catch {}
    }
    function set_who(f: boolean, c: boolean) {
        const w = world(); if (!w) return
        const next = f && c ? 'all' : f ? 'friends' : c ? 'crew' : 'none'
        who = next
        try { if (consent) { H.Ra_pool_start?.(w, budget, Math.floor(Date.now() / 1000), next); bump() } } catch {}
    }
    function set_recent(on: boolean) {
        const w = world(); if (!w) return
        recent = on
        try { if (consent) { H.Ra_pool_recent_set?.(w, on ? 1 : 0); bump() } } catch {}
    }
    const num = (e: Event) => +((e.currentTarget as HTMLInputElement).value)
</script>

{#if small}
    <div class="pf pf-bud" class:on={consent} title={consent ? budget + ' MB rolling · ' + pooled + ' pooled' : 'SoundPool — off'}>🏊</div>
{:else}
    <div class="pf">
        <p class="pf-sentence">
            <b>SoundPool</b> keeps rolling
            <input class="pf-mb" type="number" min="0" step="100" value={draft} onchange={(e) => set_mb(num(e))} title="megabytes of music to keep — 0 switches it off and clears it out" />
            MB of music in browser storage{#if free_gb != null} <span class="pf-dim">({free_gb} GB free)</span>{/if}, sourced from
            <label class="pf-ck"><input type="checkbox" checked={friends} onchange={(e) => set_who((e.currentTarget as HTMLInputElement).checked, crew)} /> friends <span class="pf-dim">(less predictable)</span></label>
            <label class="pf-ck"><input type="checkbox" checked={crew} onchange={(e) => set_who(friends, (e.currentTarget as HTMLInputElement).checked)} /> crew <span class="pf-dim">(your devices, see <button class="pf-link" onclick={() => (H as any)?.Sounditron_focus?.('Door')} title="opens the Door — your crew and friends">Door</button>)</span></label>
            and
            <label class="pf-ck"><input type="checkbox" checked={recent} onchange={(e) => set_recent((e.currentTarget as HTMLInputElement).checked)} /> recent acquisitions <span class="pf-dim">(what you just downloaded)</span></label>{#if consent}<span class="pf-dim"> · {pooled} pooled so far</span>{/if}
        </p>
    </div>
{/if}

<style>
    .pf { pointer-events: none; display: flex; flex-direction: column; width: 100%; height: 100%; box-sizing: border-box; padding: 1rem 2.2rem; color: #f4e6c8; overflow: hidden; font-size: .95rem; }
    .pf-bud { align-items: center; justify-content: center; padding: 0; font-size: clamp(1.5rem, 5vw, 2.8rem); line-height: 1; }
    .pf-bud.on { filter: drop-shadow(0 0 6px rgba(120, 220, 255, 0.55)); }
    .pf-sentence { margin: 0; line-height: 1.7; max-width: 100%; overflow-wrap: anywhere; pointer-events: auto; }
    .pf-dim { opacity: .6; font-size: .85em; }
    .pf-mb { width: 4.5em; box-sizing: border-box; background: rgba(0, 0, 0, .35); color: inherit; border: 1px solid rgba(244, 230, 200, .35); border-radius: 6px; padding: .1rem .3rem; font: inherit; font-weight: 700; text-align: right; vertical-align: baseline; }
    .pf-ck { white-space: nowrap; cursor: pointer; }
    .pf-ck input { vertical-align: -1px; margin: 0 .2em 0 0; }
    .pf-link { pointer-events: auto; cursor: pointer; background: none; border: none; padding: 0; color: inherit; font: inherit; text-decoration: underline; opacity: .9; }
</style>
