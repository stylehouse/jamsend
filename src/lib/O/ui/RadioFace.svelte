<script lang="ts">
    // RadioFace — the radio's face in the glass: mounted by Cytui on a %Radio particle wearing
    //  sc.face:'Radio' (glass_kinds.ts).  Reads the particle's sc each H.version bump; the
    //   buttons call the Radio ghost's verbs straight on H (ghost methods mix onto the House).
    //  Pointer events: the overlay div is pointer-events:none (the glass must stay pannable),
    //   so ONLY the buttons re-arm them — a drag anywhere else falls through to the graph.
    let { n, H } = $props()

    // the second-hand: sc.at is written WITHOUT a version bump (a bump/sec would re-tessellate
    //  the glass), so the face polls its own clock — H.version still folds in real changes.
    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 1000)
        return () => clearInterval(iv)
    })

    let face = $derived.by(() => {
        void H?.version
        void tick
        const sc = n?.sc ?? {}
        // the first-time read: never played, nothing dialed — teach what ▶ will do, using the
        //  stoker's census (stock standing = the preheat already dug) so the promise is honest.
        const stock = +((n?.c?.w?.o?.({ Stoker: 1 })?.[0]?.sc?.stock) ?? 0)
        // the POOL: friend tracks standing in the %MusuThem mirrors (the live share fill) —
        //  the radio dials across them too, and the face says so only when it's true.
        let pool = 0
        for (const home of (n?.c?.w?.o?.({ MusuThem: 1 }) ?? [])) {
            // a friend's mirror is PAGED (%Mag:shuffle › %Cloud › %Record), not flat — so count via the
            //  shape-agnostic Ra_recs census (what Radio_dial_pool / Radio_lineup_fill / CrateFace all use),
            //   NOT a flat stock.o({Record}) which reads 0 on every real peer and hid the whole friend pool.
            const stock = home?.o?.({ stock: 1 })?.[0]
            pool += ((H as any)?.Ra_recs ? (H as any).Ra_recs(stock) : (stock?.o?.({ Record: 1 }) ?? [])).length
        }
        return {
            pool,
            state:  (sc.Radio as string) ?? 'off',
            title:  sc.title as string | undefined,
            artist: sc.artist as string | undefined,
            at:     +(sc.at ?? 0),
            of:     +(sc.of ?? 0),
            played: +(sc.played ?? 0),
            drops:  +(sc.drops ?? 0),
            note:   sc.note as string | undefined,
            by:     sc.by as string | undefined,
            byName: (sc.by_name as string) ?? '',
            own:    !!sc.own,   // the source switch: true = playing MY records, false = friends' (default)
            // solo — the DIAL fell to its last rung: no friend was reachable so we are playing your own
            //  shelf rather than sitting silent (Radio_dial, 2026-08-08).  Distinct from `own`, which is
            //   the listener CHOOSING their own records; solo is the radio saying nobody else was there.
            //    Cleared in Radio_open the moment a friend's track actually opens.
            solo:   (sc.solo as string) ?? '',
            soloBy: (sc.solo_by as string) ?? '',
            first:  ((sc.Radio ?? 'off') === 'off') && !sc.title && !+(sc.played ?? 0),
            stock,
            // the heist gesture's ✓ tell (the human 2026-07-28 "keep what you're hearing"): Radio_keep
            //  stamps n.c.kept[seed] (runtime, never snapped) so the ⇊ reads back as kept for this track.
            keptThis: !!(n?.c?.kept && n?.c?.rec?.sc?.id && n.c.kept[n.c.rec.sc.id]),
        }
    })

    const mmss = (s: number) => {
        const m = Math.floor(s / 60), r = Math.floor(s % 60)
        return `${m}:${r < 10 ? '0' : ''}${r}`
    }
    const ICON: Record<string, string> = { off: '📻', digging: '⛏', playing: '♪', paused: '⏸', starved: '…' }
    // the three ways to be playing your own music, which want three different sentences.  `gathering` is
    //  the one that matters: a friend IS there and their bytes are in flight, so the honest line is a
    //   promise, not a lament — and saying "nobody online" here is a flat lie the listener can disprove
    //    by looking at their friends list.
    const soloWhy = (f: { solo: string, soloBy: string }) =>
        f.solo === 'gathering' ? `waiting on ${f.soloBy || 'a friend'}’s music` :
        f.solo === 'offline'   ? 'your friends are offline' :
                                 'nobody online yet'
</script>

<div class="rf" class:on={face.state === 'playing'}>
    <!-- transport on its OWN row: a long title can no longer occlude the next/★ buttons —
         the title lives below, on its own line, where it only ever occludes itself. -->
    <!-- WEIGHTED BY WHAT YOU REACH FOR (the human 2026-08-07: "pause should be small, next big, star not
         at all ... and heist big").  A phone player is thumbs, not a mixing desk: the two verbs that fire
         constantly — SKIP and KEEP — get the area, pause gets a corner, and ★ is gone (favouriting is
         beyond v1.0; Radio_mag_pop still stands in the ghost, it just spends no glass). -->
    <div class="rf-transport">
        <button class="rf-btn rf-small" onclick={() => (H as any)?.Radio_toggle?.(n)}
            title={face.state === 'playing' ? 'pause' : 'play'}>
            {face.state === 'playing' || face.state === 'digging' || face.state === 'starved' ? '⏸' : '▶'}
        </button>
        <button class="rf-btn rf-skip rf-big" onclick={() => (H as any)?.Radio_skip?.(n)} title="next">⏭</button>
        <!-- the HEIST gesture (the human 2026-07-28 "keep what you're hearing"): only on a FRIEND'S track
             (face.by) — your own you already hold.  ONE CLICK: ⇊ mints a %Keep and that's it — no popup.
             It becomes a %Keep you OPEN and START (▶) from the keep panel — the original then downloads
             straight into music/<genre>/.  ✓ is the tell it's kept (n.c.kept, runtime). -->
        {#if face.by}
            <button class="rf-btn rf-skip rf-keep rf-big" class:kept={face.keptThis}
                onclick={() => { (H as any)?.Radio_keep?.(n) }}
                title={face.keptThis ? 'kept — open the keep and press ▶ to start the download' : "keep this — queues a download you start (▶) from the keep panel"}>{face.keptThis ? '✓' : '⇊'}</button>
        {/if}
    </div>
    <div class="rf-title">{ICON[face.state] ?? '📻'} {face.title ?? 'the radio'}</div>
    {#if face.artist}<div class="rf-artist">{face.artist}</div>{/if}
    <!-- provenance: whose Pier this track streams from, or that it's your OWN record — the human 2026-07-28
         wanted to always know the source, and for it to be clear when just playing your own music. -->
    <!-- REMOTE OR LOCAL, unmistakably (the human 2026-08-07: "the UI in the player should be clear its
         remote, or local").  This used to be a whispered grey line; a listener needs to know at a glance
         whether these bytes are crossing a wire — it governs whether a stall is their disk or the net,
         and whether ⇊ even makes sense.  A badge, not a footnote. -->
    {#if face.by}
        <div class="rf-src rf-src-remote">⚯ STREAMING from {face.byName || 'a friend'}</div>
    {:else if face.solo && face.title && face.state !== 'off' && face.state !== 'digging'}
        <!-- THE LABEL the human asked for (2026-08-08): playing your own is fine, being unclear about
             WHY is not.  This is not the same message as the plain local badge below — that one means
             "you chose your own records", this one means "nobody was online, so here's yours". -->
        <div class="rf-src rf-src-local">♪ LOCAL — your own record · {soloWhy(face)}</div>
    {:else if face.title && face.state !== 'off' && face.state !== 'digging'}
        <div class="rf-src rf-src-local">♪ LOCAL — your own record</div>
    {/if}
    {#if face.note}<div class="rf-note">{face.note}</div>{/if}
    <!-- the "why is it silent" line: a starved radio holds a loaded track but the next piece hasn't
         arrived over the wire, so the bar freezes.  Say so — the human asked that the page never go
         quiet WITHOUT explaining itself.  It resumes itself the instant the piece lands (no user action).
         WORDING (2026-08-06, the human): "off the tape", not "the next piece hasn't arrived yet" — the
         old line described the MECHANISM to someone who only wanted to know the music stopped. -->
    {#if face.state === 'starved'}<div class="rf-note">off the tape — holding the line, it'll resume itself</div>{/if}
    {#if face.of > 0}
        <div class="rf-bar"><div class="rf-fill" style="width:{Math.min(100, 100 * face.at / face.of)}%"></div></div>
        <div class="rf-time">{mmss(face.at)} / {mmss(face.of)}
            {#if face.played > 0}&nbsp;· {face.played} played{/if}
            {#if face.drops > 0}&nbsp;· {face.drops} drops{/if}</div>
    {:else if face.state === 'digging' && !face.note}
        <div class="rf-time">{face.own ? 'digging your crates…' : 'looking for a friend to play…'}</div>
    {:else if face.first}
        <div class="rf-time">{face.pool > 0 ? `▶ plays your friends' music — ${face.pool} ${face.pool === 1 ? 'track' : 'tracks'} ready` : face.stock > 0 ? '▶ waiting for a friend — your own crate is in the Tuner' : '▶ waiting for a friend to come online'}</div>
    {/if}
    {#if face.pool > 0 && !face.first && !face.own}
        <div class="rf-time">⚯ {face.pool} friend {face.pool === 1 ? 'track rides' : 'tracks ride'} the dial</div>
    {/if}
</div>

<style>
    .rf {
        pointer-events: none;
        width: max-content;
        max-width: 300px;
        padding: 8px 12px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #e8dcc0;
        text-align: left;
    }
    .rf-transport { display: flex; align-items: center; gap: 8px; margin-bottom: 5px; }
    .rf-btn {
        pointer-events: auto;
        cursor: pointer;
        background: #1a2f38;
        color: #e8dcc0;
        border: 1px solid #d9a026;
        border-radius: 50%;
        width: 34px;
        height: 34px;
        font-size: 14px;
        line-height: 1;
        flex: none;
    }
    .rf-btn:hover { background: #d9a026; color: #04202a; }
    /* thumb-weighted (see the transport comment): next + keep are the constant verbs, pause is a corner */
    .rf-big   { font-size: 1.55em; padding: 0.30em 0.62em; flex: 1 1 auto; min-height: 2.1em; }
    .rf-small { font-size: 0.9em;  padding: 0.18em 0.34em; flex: 0 0 auto; opacity: 0.8; }
    .rf-small:hover { opacity: 1; }
    .rf-skip { width: 26px; height: 26px; font-size: 10px; }
    .rf-keep.kept { background: #2e6b3a; border-color: #57c777; color: #eafff0; }
    .rf-keep.kept:hover { background: #57c777; color: #04202a; }
    .rf-title { font-size: 12px; font-weight: 700; overflow-wrap: anywhere; }
    .rf-artist { font-size: 10px; opacity: 0.8; }
    .rf-note { font-size: 9px; opacity: 0.6; font-style: italic; }
    .rf-src {
        display: inline-block; margin-top: 2px; padding: 1px 5px; border-radius: 3px;
        font-size: 0.72em; letter-spacing: 0.04em; font-weight: 600;
    }
    .rf-src-remote { background: rgba(127, 200, 232, 0.16); color: #8fd0ee; border: 1px solid rgba(127, 200, 232, 0.4); }
    .rf-src-local  { background: rgba(182, 201, 168, 0.13); color: #b6c9a8; border: 1px solid rgba(182, 201, 168, 0.32); }
    .rf-bar {
        margin-top: 6px;
        height: 3px;
        background: #1a2f38;
        border-radius: 2px;
        overflow: hidden;
    }
    .rf-fill { height: 100%; background: #d9a026; transition: width 0.4s linear; }
    .rf-time { font-size: 9px; opacity: 0.7; margin-top: 3px; }
    .on .rf-title { color: #ffd869; }
</style>
