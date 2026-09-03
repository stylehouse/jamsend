<script lang="ts">
    // PoolFace — the %Pooling CELL: SoundPooling's control surface (SoundPooling_todo; the owner 2026-09-03:
    //  "how do we select what music we want to keep available to Captain … perhaps just another cell when
    //   there's any Crew" · "take SoundPooling all the way through CRUD if you like, of Pools, start with one
    //    that just acquires random whole LOFI tracks from all Piers|Crewmates").
    //  What it shows, all read LIVE off the radio world (no state of its own; react off H.version):
    //   · the %Pool compartments — name · take-policy · cap · a ✕ to drop one (the D of CRUD)
    //   · the steward's standing wants per compartment (what the phone wants next, from whom)
    //   · the sources a 'random' pool draws from (every mirrored catalog — crew and friends alike)
    //   · one-press presets: "random from everyone" (take:random) and "what I liked" (take:liked)
    //   · the two knobs the economy ships default-off behind: the steward tick + the fill bookings
    //  Face contract: { n: TheC, H: House } — imperative mount, so every read re-derives off H.version.
    let { n, H } = $props()
    let pose = $derived.by(() => { void H?.version; return String(n?.c?.pose ?? 'big') })
    let small = $derived(pose === 'small')

    const top = () => H?.top_House?.() ?? H
    const world = () => top()?.c?.radio_w ?? null

    type Def = { name: string; take: string; cap: number; salt: string }
    let defs = $state<Def[]>([])
    let wants = $state<Record<string, { of: string; from: string; why: string; do: string }[]>>({})
    let pooled = $state(0)
    let sources = $state(0)
    let holders = $state(0)
    let steward_on = $state(false)
    let fills_on = $state(false)

    $effect(() => {
        void H?.version
        const w = world()
        if (!w) { defs = []; wants = {}; pooled = 0; sources = 0; holders = 0; return }
        try {
            const d = (H.Ra_pool_defs?.(w, 0) ?? []) as Def[]
            defs = d.filter((p) => p.name)
            const prov = w.o({ Provisions: 1 })[0]
            const grouped: Record<string, any[]> = {}
            for (const want of (prov?.o({ Want: 1 }) ?? []) as any[]) {
                const k = String(want.sc.pool || '')
                ;(grouped[k] ??= []).push({ of: String(want.sc.of || ''), from: String(want.sc.from || ''), why: String(want.sc.why || ''), do: String(want.sc.do || '') })
            }
            wants = grouped
            const pub = H.Radio_pub?.(w)
            // PROBED, never minted (the ShuffleFace law — a read must not vivify a home): Ra_home_pool is
            //  an oai pair, and this runs in a render effect.
            const shelf = pub ? (w.o({ MusuPool: 1, pub })[0]?.o({ stock: 1, pub })[0] ?? null) : null
            pooled = shelf && H.Ra_recs ? (H.Ra_recs(shelf) as any[]).length : 0
            const src = (H.Ra_pool_sources?.(w) ?? []) as { id: string; from: string }[]
            sources = src.length
            holders = new Set(src.map((s) => s.from)).size
            steward_on = !!top()?.c?.pool_steward
            fills_on = !!w.c?.reach_on
        } catch {}
    })

    // ── the verbs (each a House method — the face holds no policy) ─────────────────────────────
    let name_draft = $state('')
    let take_draft = $state('random')
    let cap_draft = $state(12)
    const TAKES = ['radio', 'random', 'taste', 'liked', 'kept', 'latest']
    function define(name: string, take: string, cap: number) {
        const w = world(); if (!w || !name) return
        try { H.Ra_pool_define?.(w, name, take, Math.max(1, Math.floor(cap || 1))); top()?.bump_version?.() } catch {}
    }
    function drop(name: string) {
        const w = world(); if (!w) return
        try { H.Ra_pool_drop?.(w, name); top()?.bump_version?.() } catch {}
    }
    function reshuffle(name: string) {
        const w = world(); if (!w) return
        try {
            const shelf = H.Ra_pool_home?.(w)?.o({ Pools: 1 })[0]
            const p = shelf?.o({ Pool: 1, name })[0]
            if (p) { p.sc.salt = String((+(p.sc.salt || 0)) + 1); p.bump(); top()?.bump_version?.() }
        } catch {}
    }
    function toggle_steward() { const t = top(); if (!t?.c) return; if (t.c.pool_steward) delete t.c.pool_steward; else t.c.pool_steward = 1; t.bump_version?.() }
    function toggle_fills() { const w = world(); if (!w?.c) return; if (w.c.reach_on) delete w.c.reach_on; else w.c.reach_on = 1; top()?.bump_version?.() }
    let sitting = $state(false)
    function sit() {
        // one steward sit-down NOW (the same tick a track advance fires), so a fresh pool shows its wants at once
        const w = world(); const t = top(); if (!w || !t) return
        if (sitting) return          // a second press mid-pass would read the flag IT set and latch it on
        sitting = true
        try {
            const radio = w.o({ Radio: 1 })[0]
            const was = t.c.pool_steward; t.c.pool_steward = 1
            const p = H.Radio_pool_steward?.(w, radio)
            const done = () => { if (!was) delete t.c.pool_steward; sitting = false; t.bump_version?.() }
            if (p && p.then) p.then(done, done); else done()
        } catch { sitting = false }
    }
    const TAKE_WHY: Record<string, string> = {
        radio: 'keeps what you actually hear — tune the radio to someone and this fills with what it plays',
        random: 'circulation — random whole tracks from everyone who shares with you',
        taste: 'what you engage with most (likes ×3 · keeps ×2 · spins)',
        liked: 'only what you liked',
        kept: 'only what you kept',
        latest: 'the last jam, in order',
    }
</script>

{#if small}
    <div class="pf pf-bud" class:on={defs.length > 0} title={defs.length ? defs.length + ' pool' + (defs.length === 1 ? '' : 's') + ' · ' + pooled + ' pooled' : 'SoundPooling'}>🏊</div>
{:else}
    <div class="pf">
        <div class="pf-head">🏊 SoundPooling <span class="pf-dim">· {pooled} pooled · {sources} track{sources === 1 ? '' : 's'} reachable from {holders} {holders === 1 ? 'body' : 'bodies'}</span></div>
        <div class="pf-body">
            {#if !defs.length}
                <div class="pf-empty">no pools yet — a pool is a compartment of your phone's music that fills itself.</div>
            {/if}
            {#each defs as d (d.name)}
                <div class="pf-pool">
                    <div class="pf-row">
                        <span class="pf-name">{d.name}</span>
                        <span class="pf-take" title={TAKE_WHY[d.take] ?? d.take}>{d.take}</span>
                        <span class="pf-cap">cap {d.cap}</span>
                        <span class="pf-wants">{(wants[d.name] ?? []).length} wanted</span>
                        {#if d.take === 'random'}<button class="pf-btn" onclick={() => reshuffle(d.name)} title="draw again — a new salt, a new random order">🔀</button>{/if}
                        <button class="pf-btn pf-x" onclick={() => drop(d.name)} title="drop this pool — its copies become evict wants">✕</button>
                    </div>
                    {#if (wants[d.name] ?? []).length}
                        <div class="pf-wantlist">
                            {#each (wants[d.name] ?? []).slice(0, 8) as wnt (wnt.of + wnt.do)}
                                <div class="pf-want" title={wnt.why}>{wnt.do === 'evict' ? '⌫' : wnt.do === 'press' ? '⇩' : '⇊'} {wnt.of.slice(0, 18)}{#if wnt.from}<span class="pf-dim"> ← {wnt.from.slice(0, 8)}</span>{/if}</div>
                            {/each}
                            {#if (wants[d.name] ?? []).length > 8}<div class="pf-dim">… +{(wants[d.name] ?? []).length - 8}</div>{/if}
                        </div>
                    {/if}
                </div>
            {/each}
            <div class="pf-presets">
                {#if !defs.some((d) => d.take === 'random')}
                    <button class="pf-btn pf-preset" onclick={() => define('random', 'random', 12)} title={TAKE_WHY.random}>＋ random from everyone</button>
                {/if}
                {#if !defs.some((d) => d.take === 'radio')}
                    <button class="pf-btn pf-preset" onclick={() => define('radio', 'radio', 12)} title={TAKE_WHY.radio}>＋ keep what I hear</button>
                {/if}
                {#if !defs.some((d) => d.take === 'liked')}
                    <button class="pf-btn pf-preset" onclick={() => define('liked', 'liked', 12)} title={TAKE_WHY.liked}>＋ what I liked</button>
                {/if}
            </div>
            <div class="pf-form">
                <input class="pf-in" placeholder="pool name" bind:value={name_draft} autocomplete="off" />
                <select class="pf-in" bind:value={take_draft}>{#each TAKES as t}<option value={t}>{t}</option>{/each}</select>
                <input class="pf-in pf-num" type="number" min="1" bind:value={cap_draft} />
                <button class="pf-btn" onclick={() => { define(name_draft, take_draft, cap_draft); name_draft = '' }} disabled={!name_draft}>define</button>
            </div>
            <div class="pf-knobs">
                <button class="pf-btn" class:lit={steward_on} onclick={toggle_steward} title="the steward presses + evicts at every track advance">steward {steward_on ? 'on' : 'off'}</button>
                <button class="pf-btn" class:lit={fills_on} onclick={toggle_fills} title="pull-wants become standing bookings toward whoever holds the track">fills {fills_on ? 'on' : 'off'}</button>
                <button class="pf-btn" onclick={sit} disabled={sitting} title="one sit-down now — recompute what the pools want">{sitting ? 'sitting…' : 'sit down'}</button>
            </div>
        </div>
    </div>
{/if}

<style>
    /* pointer-events:none on the root (the glass_kinds contract — see LinkFace/HaulFace); controls re-arm */
    .pf { pointer-events: none; display: flex; flex-direction: column; gap: .5rem; width: 100%; height: 100%; box-sizing: border-box; padding: .8rem 1rem; color: #f4e6c8; overflow: hidden; font-size: .85rem; }
    .pf-bud { padding: 0; align-items: center; justify-content: center; font-size: clamp(1.5rem, 5vw, 2.8rem); line-height: 1; }
    .pf-bud.on { filter: drop-shadow(0 0 6px rgba(120, 220, 255, 0.55)); }
    .pf-head { font-size: .95rem; font-weight: 700; letter-spacing: .3px; }
    .pf-dim { font-weight: 400; opacity: .6; font-size: .8em; }
    .pf-body { flex: 1; min-height: 0; overflow: auto; display: flex; flex-direction: column; gap: .45rem; pointer-events: auto; }
    .pf-empty { opacity: .65; font-style: italic; }
    .pf-pool { border: 1px solid rgba(244, 230, 200, .18); border-radius: 6px; padding: .35rem .5rem; background: rgba(0, 0, 0, .18); }
    .pf-row { display: flex; gap: .5rem; align-items: center; flex-wrap: wrap; }
    .pf-name { font-weight: 700; }
    .pf-take { opacity: .8; border: 1px solid rgba(244, 230, 200, .25); border-radius: 4px; padding: 0 .3rem; font-size: .78em; }
    .pf-cap, .pf-wants { opacity: .7; font-size: .85em; }
    .pf-wantlist { margin-top: .25rem; display: flex; flex-direction: column; gap: .1rem; font-family: ui-monospace, monospace; font-size: .78em; opacity: .85; }
    .pf-presets, .pf-form, .pf-knobs { display: flex; gap: .4rem; flex-wrap: wrap; align-items: center; }
    .pf-btn { pointer-events: auto; cursor: pointer; background: rgba(244, 230, 200, .1); color: inherit; border: 1px solid rgba(244, 230, 200, .3); border-radius: 5px; padding: .15rem .5rem; font: inherit; font-size: .85em; }
    .pf-btn:hover { background: rgba(244, 230, 200, .2); }
    .pf-btn:disabled { opacity: .4; cursor: default; }
    .pf-btn.lit { background: rgba(120, 220, 255, .25); border-color: rgba(120, 220, 255, .6); }
    .pf-x { margin-left: auto; }
    .pf-preset { border-style: dashed; }
    .pf-in { pointer-events: auto; background: rgba(0, 0, 0, .3); color: inherit; border: 1px solid rgba(244, 230, 200, .3); border-radius: 5px; padding: .15rem .4rem; font: inherit; font-size: .85em; }
    .pf-num { width: 4.5rem; }
</style>
