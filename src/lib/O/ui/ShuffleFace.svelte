<script lang="ts">
    // ShuffleFace — THE SHUFFLE POOL, drawn (the human 2026-08-07: "the set of tracks we're skipping
    //  through ... should actually find every track fairly soon, whereas it keeps playing the same 10
    //   tracks ... perhaps we can get a visual on that. should be on the page, in Vyto!").
    //
    //  The thing worth seeing is the gap between two sets that are easy to assume are the same:
    //   · what is IN REACH — every %Record standing on a friend crate (or my own shelf), husks included;
    //   · what the DIAL CAN ACTUALLY PICK — Radio_dial_pool admits a record only once chunk 0 is PRESENT,
    //      because a husk plays silence.  So an un-warmed record is not "slow to start", it is INVISIBLE.
    //  When those two diverge the radio replays a small pool while a full catalog sits behind it, and no
    //   number on any other face says so.  Here it is a SHAPE: a wall of hollow pips with a lit cluster in
    //    it.  One pip per record, fill = how much of its free preview has landed.
    //
    //  Props { n, H } — n is the %Shuffle organ (dontSnap, minted in Sounditron_commission); it carries no
    //   state of its own, it is a place to hang this face.  Everything is read live off the radio world.
    //  Reads are PRESENCE-ONLY (Ra_chunk_have / Repli_chunk_at never touch the bytes), on its own slow
    //   poll, and nothing here writes — a diagnostic that changed what it measures would be worthless.
    let { n, H } = $props()
    const A = H as any
    void n

    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 700); return () => clearInterval(iv) })
    let helping = $state(false)

    let view = $derived.by(() => {
        void tick
        void H?.version
        const w = A?.top_House?.()?.c?.radio_w
        if (!w) return null
        const radio = w.o?.({ Radio: 1 })?.[0]
        const heard = radio?.c?.heard ?? {}
        const playingId = radio?.c?.rec?.sc?.id != null ? String(radio.c.rec.sc.id) : ''

        // POOL MODE (SoundPooling_todo §3.3): the source chip flipped to 'pool' — show the OPFS
        //  SoundPool shelf (your pocket copies), NOT the friend mirrors.  Probe-first (oa) so a
        //   render never mints the home (the ShuffleFace read-only law); `open` (chunk 0 present)
        //    now means "the bytes are LOCAL", never a latency question.  The picture then matches
        //     what the dial's pool rung actually picks from.
        const shelves: { name: string; recs: any[] }[] = []
        const poolMode = radio?.sc?.source === 'pool'
        if (poolMode) {
            // POOL MODE: the OPFS SoundPool shelf ONLY — probe-first (oa) so a render never mints the
            //  home; `open` (chunk 0 present) here means the bytes are LOCAL, not a latency question.
            const me = A?.Radio_pub?.(w)
            const pool = (me && w.oa?.({ MusuPool: 1, pub: me })) ? A?.Ra_home_pool?.(w, me) : null
            shelves.push({ name: '♪ your pool', recs: pool ? (A?.Ra_recs?.(pool) ?? []) : [] })
        }
        // every shelf the dial can reach: the friend crates by default, plus my own when the listener
        //  flipped the source switch (radio.sc.own) — the same two ladders Radio_dial walks.
        for (const home of (poolMode ? [] : (w.o?.({ MusuThem: 1 }) ?? []))) {
            const pub = String(home.sc?.pub ?? '')
            if (!pub) continue
            const shelf = A?.Ra_home_them?.(w, pub)
            if (!shelf) continue
            shelves.push({ name: String(home.sc?.name ?? pub.slice(0, 6)), recs: A?.Ra_recs?.(shelf) ?? [] })
        }
        if (!poolMode && radio?.sc?.own) {
            // Ra_home_self is a find-or-CREATE (oai) — probe first so a mere render can never mint a
            //  home.  Same reason the MusuThem walk above goes through w.o() and only then resolves.
            const me = A?.Radio_pub?.(w)
            const mine = (me && w.oa?.({ MusuSelf: 1, pub: me })) ? A?.Ra_home_self?.(w, me) : null
            if (mine) shelves.push({ name: 'mine', recs: A?.Ra_recs?.(mine) ?? [] })
        }

        let reach = 0, dialable = 0, warm = 0, heardN = 0
        const groups = shelves.map((s) => {
            const pips = s.recs.map((rec: any) => {
                const id = String(rec.sc?.id ?? '')
                const P = Math.min(+(rec.sc?.preview ?? 0), +(rec.sc?.total ?? 0))
                // presence, not materialisation — the same read Radio_dial_pool gates on
                const map = A?.Ra_chunk_have?.(rec) ?? []
                let held = 0
                for (let i = 0; i < P; i++) if (map[i] != null) held++
                const open = P > 0 && map[0] != null      // chunk 0 ⇒ the dial may pick it
                const done = P > 0 && held >= P
                const was = !!heard[id]
                reach++
                if (open) dialable++
                if (done) warm++
                if (was) heardN++
                return {
                    id,
                    title: String(rec.sc?.title ?? id.slice(0, 6)),
                    artist: String(rec.sc?.artist ?? ''),
                    pct: P > 0 ? Math.round(held * 100 / P) : 0,
                    // Ra_stage already decides this and stamps it on the head — husk | pulling | landing |
                    //  parked | previewed | whole — so the face reads a fact rather than re-deriving one.
                    //   `parked` is the interesting one: a want outstanding PAST the preview boundary, i.e.
                    //    the %Stream proper rather than the free window.
                    stage: String(rec.sc?.stage ?? ''),
                    open, done, was, playing: id === playingId,
                }
            })
            // catalog order is the order the old warm window crawled in — keep it, so a contiguous
            //  lit run reads as "the window only ever moved one way" at a glance.
            return { name: s.name, pips }
        })
        // WHAT THE ONE YOU ARE HEARING IS DOING (the human 2026-08-07: "indicate here when the playing now
        //  one is asking-for | in the Stream after Preview").  The counts above are about the POOL; this is
        //   the single track under the needle, and the two answer different questions — a full pool tells
        //    you nothing about whether the thing playing is about to run dry.
        let now: any = null
        for (const g of groups) for (const p of g.pips) if (p.playing) now = p
        const NOW: Record<string, string> = {
            pulling:   'asking — nothing landed yet',
            landing:   'asking — preview filling',
            parked:    'in the Stream, past the preview',
            previewed: 'preview whole — free window held',
            whole:     'whole track held',
            husk:      'husk — nothing asked for',
        }
        // THE STEWARD WANT-LIST (SoundPooling_todo §5.4 — "what your phone wants next and why"): a
        //  PURE read over %Provisions → %Want,of,do,why,pool, grouped by the pool compartment each
        //   want provisions for.  Probe-first (o, never oai) so a render never mints Provisions.  Only
        //    surfaced in pool mode, where it is the composition the human is shaping.
        let wantGroups: { pool: string; wants: { of: string; do: string; why: string }[] }[] = []
        if (poolMode) {
            const prov = w.o?.({ Provisions: 1 })?.[0]
            const byPool: Record<string, { of: string; do: string; why: string }[]> = {}
            for (const want of (prov?.o?.({ Want: 1 }) ?? [])) {
                const pool = String(want.sc?.pool ?? '')
                ;(byPool[pool] = byPool[pool] ?? []).push({
                    of: String(want.sc?.of ?? '').slice(0, 6),
                    do: String(want.sc?.do ?? ''),
                    why: String(want.sc?.why ?? ''),
                })
            }
            wantGroups = Object.keys(byPool).sort().map((pool) => ({ pool, wants: byPool[pool] }))
        }
        return {
            groups, reach, dialable, warm, heardN, poolMode, wantGroups,
            fresh: Math.max(0, dialable - heardN),
            replays: +(radio?.sc?.replays ?? 0),
            now, nowSays: now ? (NOW[now.stage] ?? now.stage) : '',
            // `parked` IS the after-preview seam — worth its own colour, since it is the state a starve
            //  shows up in and the one the preview boundary was invented to make visible.
            nowDeep: !!now && now.stage === 'parked',
        }
    })
</script>

{#if view}
    <div class="sf">
        <div class="sf-head">
            <span class="sf-n"><b>{view.dialable}</b>/{view.reach}</span>
            <span class="sf-dim">the dial can reach</span>
            {#if view.fresh === 0 && view.dialable > 0}
                <span class="sf-warn">· all heard — replaying</span>
            {:else}
                <span class="sf-dim">· {view.fresh} unheard</span>
            {/if}
            <button class="sf-q" onclick={() => (helping = !helping)} title="how to read this">?</button>
        </div>

        {#if view.now}
            <div class="sf-now" class:deep={view.nowDeep} title="the track under the needle, and what it is waiting on">
                <span class="sf-now-t">♪ {view.now.title}</span>
                <span class="sf-now-s">{view.nowSays}</span>
            </div>
        {/if}

        {#if helping}
            <div class="sf-help">
                <b>One pip per track</b> on the shelves the radio can reach.
                <div><span class="sf-key sf-key-husk"></span> <b>hollow</b> — a husk. Not one byte of it has
                    arrived, and the shuffle <i>cannot pick it at all</i>: the dial only admits a track once
                    its first chunk is here, because a husk would play silence.</div>
                <div><span class="sf-key sf-key-open"></span> <b>outlined, part-filled</b> — playable. The fill
                    is how much of its free preview has landed.</div>
                <div><span class="sf-key sf-key-done"></span> <b>solid</b> — whole preview in hand; starts instantly.</div>
                <div><span class="sf-key sf-key-was"></span> <b>faded</b> — heard this sitting, so the dial skips it.</div>
                <div><span class="sf-key sf-key-play"></span> <b>white</b> — playing now.</div>
                <div class="sf-help-p">The big number is <b>what the dial can reach / what stands on the
                    shelves</b>. A wall of hollow pips beside a small lit cluster means the radio is
                    shuffling a tiny pool while a full catalog sits behind it — that is the thing to watch.
                    <b>“all heard — replaying”</b> means every playable track has been played this sitting, so
                    it is now repeating rather than going quiet.</div>
            </div>
        {/if}

        {#each view.groups as g}
            <div class="sf-grp">
                <!-- the per-shelf count, so a surprising total can be attributed to a shelf at a glance
                     (61/638 against a 62-track crate, 2026-08-07 — the number that found the leak) -->
                <div class="sf-grp-name">{g.name} · {g.pips.length}</div>
                <div class="sf-pips">
                    {#each g.pips as p}
                        <div class="sf-pip"
                             class:open={p.open}
                             class:done={p.done}
                             class:was={p.was}
                             class:playing={p.playing}
                             title="{p.artist ? p.artist + ' — ' : ''}{p.title} · {p.pct}% of preview{p.open ? '' : ' · husk, the dial cannot pick it'}{p.was ? ' · heard' : ''}">
                            <div class="sf-fill" style="height:{p.pct}%"></div>
                        </div>
                    {/each}
                </div>
            </div>
        {/each}

        {#if view.replays > 0}
            <div class="sf-foot">↻ {view.replays} replay{view.replays === 1 ? '' : 's'} — the pool ran out, not the music</div>
        {/if}
        {#if !view.reach && !view.poolMode}
            <div class="sf-foot sf-dim">no crate in reach yet</div>
        {/if}
        <!-- THE STEWARD WANT-LIST — "what your phone wants next and why" (SoundPooling §5.4).  Shown in
             pool mode: the composition the steward is provisioning, grouped by pool compartment. -->
        {#if view.poolMode}
            {#if view.wantGroups.length}
                <div class="sf-wants">
                    {#each view.wantGroups as wg}
                        <div class="sf-want-pool">{wg.pool || 'pool'} · wants {wg.wants.length}</div>
                        {#each wg.wants.slice(0, 6) as want}
                            <div class="sf-want" title={want.why}>
                                <span class="sf-want-do sf-want-{want.do}">{want.do}</span>
                                <span class="sf-want-of">{want.of}</span>
                                <span class="sf-want-why">{want.why}</span>
                            </div>
                        {/each}
                        {#if wg.wants.length > 6}<div class="sf-want sf-dim">…and {wg.wants.length - 6} more</div>{/if}
                    {/each}
                </div>
            {:else}
                <div class="sf-foot sf-dim">the steward hasn't sat down yet — flip pool_steward on, or siphon a track</div>
            {/if}
        {/if}
    </div>
{/if}

<style>
    .sf { font-size: 10px; line-height: 1.3; padding: 2px 3px; color: #cfe8dd; }
    .sf-head { display: flex; gap: 4px; align-items: baseline; flex-wrap: wrap; margin-bottom: 3px; }
    .sf-n { font-family: monospace; font-size: 12px; color: #7fe8bf; }
    .sf-n b { font-weight: 700; }
    .sf-dim { opacity: 0.55; }
    .sf-warn { color: #ffb27f; }
    .sf-grp { margin-top: 3px; }
    .sf-grp-name { font-size: 8px; opacity: 0.5; font-family: monospace; }
    .sf-pips { display: flex; flex-wrap: wrap; gap: 2px; margin-top: 2px; }
    /* a husk: hollow. the wall of these beside a small lit cluster IS the bug the human reported. */
    .sf-pip {
        position: relative; width: 7px; height: 11px; border-radius: 1px;
        border: 1px solid rgba(127, 232, 191, 0.28); background: transparent;
        overflow: hidden; display: flex; align-items: flex-end;
    }
    .sf-fill { width: 100%; background: rgba(127, 232, 191, 0.30); }
    .sf-pip.open { border-color: rgba(127, 232, 191, 0.85); }
    .sf-pip.open .sf-fill { background: rgba(127, 232, 191, 0.55); }
    .sf-pip.done .sf-fill { background: rgba(127, 232, 191, 0.85); }
    /* heard this sitting — spent, so it stops competing for the eye */
    .sf-pip.was { opacity: 0.34; }
    .sf-pip.playing { border-color: #fff; box-shadow: 0 0 4px rgba(255, 255, 255, 0.8); opacity: 1; }
    .sf-pip.playing .sf-fill { background: #fff; }
    .sf-foot { margin-top: 3px; font-size: 9px; opacity: 0.7; }
    /* the steward want-list — the phone's composition, quiet enough not to fight the pips */
    .sf-wants { margin-top: 4px; border-top: 1px solid rgba(127, 232, 191, 0.18); padding-top: 3px; }
    .sf-want-pool { font-size: 9px; color: #7fe8bf; letter-spacing: 0.03em; margin: 3px 0 1px; }
    .sf-want { display: flex; gap: 4px; align-items: baseline; font-size: 9px; line-height: 1.35; }
    .sf-want-do { flex: none; font-family: monospace; padding: 0 3px; border-radius: 3px; }
    .sf-want-press { background: rgba(127, 232, 191, 0.18); color: #7fe8bf; }
    .sf-want-pull  { background: rgba(127, 200, 232, 0.18); color: #8fd0ee; }
    .sf-want-evict { background: rgba(232, 160, 127, 0.18); color: #e8a07f; }
    .sf-want-of { flex: none; font-family: monospace; opacity: 0.8; }
    .sf-want-why { flex: 0 1 auto; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; opacity: 0.6; }
    /* the now-playing line: one row, the title clipped rather than wrapping, so the cell keeps its height */
    .sf-now {
        display: flex; gap: 4px; align-items: baseline; margin-top: 2px;
        font-size: 9px; line-height: 1.3; color: #cfe6dd;
    }
    .sf-now-t { flex: 0 1 auto; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .sf-now-s { flex: none; opacity: 0.7; }
    .sf-now.deep .sf-now-s { color: #7fe8bf; opacity: 1; }
    .sf-q {
        /* RE-ARM THE CLICKS (the human 2026-08-07: "the '?' button ... doesn't work").  Vytui's `.faces`
           layer and every face root are pointer-events:none — the mold is a rectangle over the voronoi
           cell and must not swallow the canvas — so an interactive control has to opt back IN, one by one.
           This one had `cursor: pointer` and nothing else, so it LOOKED clickable and never was. */
        pointer-events: auto;
        margin-left: auto; width: 13px; height: 13px; line-height: 1; padding: 0;
        border: 1px solid rgba(127, 232, 191, 0.45); border-radius: 50%;
        background: transparent; color: #7fe8bf; font-size: 9px; cursor: pointer; flex: none;
    }
    .sf-q:hover { background: rgba(127, 232, 191, 0.15); }
    .sf-help {
        margin: 3px 0; padding: 4px 5px; font-size: 9px; line-height: 1.45;
        background: rgba(0, 0, 0, 0.28); border: 1px solid rgba(127, 232, 191, 0.22); border-radius: 3px;
    }
    .sf-help div { margin-top: 2px; }
    .sf-help-p { margin-top: 4px; opacity: 0.85; }
    .sf-key {
        display: inline-block; width: 6px; height: 9px; vertical-align: -1px; border-radius: 1px;
        border: 1px solid rgba(127, 232, 191, 0.28); margin-right: 2px;
    }
    .sf-key-open { border-color: rgba(127, 232, 191, 0.85); background: linear-gradient(to top, rgba(127, 232, 191, 0.55) 50%, transparent 50%); }
    .sf-key-done { border-color: rgba(127, 232, 191, 0.85); background: rgba(127, 232, 191, 0.85); }
    .sf-key-was { border-color: rgba(127, 232, 191, 0.85); background: rgba(127, 232, 191, 0.85); opacity: 0.34; }
    .sf-key-play { border-color: #fff; background: #fff; }
</style>
