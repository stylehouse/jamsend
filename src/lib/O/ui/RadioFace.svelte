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
            // the head the offer skipped past (Ra_preview_offset): a friend's track opens 30–70% in, and
            //  until 2026-08-08 the clock silently pretended the track BEGAN there.  sc.skip is absent on
            //   a from-the-start cut, so this stays 0 for local records and every Book.
            skip:   +(sc.skip ?? 0),
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
    // the progress RING (the bitsy player, 2026-08-09): arc length for a fraction of the
    //  r=26 circle.  The ring replaces the bar — a round cell wants round furniture.
    const RING_C = 2 * Math.PI * 26
    const ringlen = (frac: number) => (Math.max(0, Math.min(1, frac)) * RING_C).toFixed(1)
    // ── THE POSE (2026-08-10, the owner: *"the radio should display as a play button (like Door
    //  becomes only a Door icon)"*).  Same `.c.pose` seam DoorFace reads: the commissioner stamps
    //   `small` on a bud and `big` on the belly, and a bud renders ONE GLYPH — not a folded player,
    //    not a player with its chips hidden.  Defaults to `big`, so any glass that does not pose its
    //     cells gets exactly the face it got before this existed.
    let pose = $derived.by(() => { void H?.version; void tick; return String(n?.c?.pose ?? 'big') })
    let small = $derived(pose === 'small')
</script>

<!-- SMALL IS THE WHOLE FACE, not a folded player (DoorFace's discipline, same reason): one early
     return, so a bud does not mount the transport, the ring, the friend-pool census or the 1s clock —
     and a single branch is the only way to be sure of that by reading it.  The glyph reports STATE:
     ▶ when it is playing (press the cell to come back to it), ▷ when it is not. -->
{#if small}
    <div class="rf rf-bud" class:on={face.state === 'playing'}
         title={face.state === 'playing' ? 'the player — press to come back to it' : 'the player'}>{face.state === 'playing' ? '▶' : '▷'}</div>
{:else}
<div class="rf" class:on={face.state === 'playing'}>
    <!-- THE BITSY PLAYER (the owner 2026-08-09: "pop the player visual for something more
         individual bitsy and layoutable").  The old face was a left-aligned text column — the
         worst shape for a round room.  Now every piece is its OWN small object: the title a
         pill, the artist a pill, each stat a chip — and the transport is a round cluster with
         the PROGRESS RING around the skip button (a round cell wants round furniture; the bar
         is retired).  Composed centre-out, so the foam seat's inscribed box fills gracefully. -->
    <!-- no glyph on the title (the owner 2026-08-11): the state already reads off the transport
         button (⏸/▶) and the ring, so a ♪ in front of the track name was furniture competing with
         the one thing the pill is for.  ICON is kept — the bud pose and any future chip may want it. -->
    <div class="rf-title chip">{face.title ?? 'the radio'}</div>
    {#if face.artist}<div class="rf-artist chip">{face.artist}</div>{/if}
    <!-- WEIGHTED BY WHAT YOU REACH FOR (the human 2026-08-07: "pause should be small, next big, star not
         at all ... and heist big").  SKIP is the heart of the cluster wearing the ring; pause is a small
         satellite left, KEEP a satellite right (friend tracks only — your own you already hold; ⇊ mints
         a %Keep, ✓ is the tell it took, n.c.kept runtime). -->
    <div class="rf-transport">
        <button class="rf-btn rf-small" onclick={() => (H as any)?.Radio_toggle?.(n)}
            title={face.state === 'playing' ? 'pause' : 'play'}>
            {face.state === 'playing' || face.state === 'digging' || face.state === 'starved' ? '⏸' : '▶'}
        </button>
        <div class="rf-hub">
            {#if face.of > 0}
                <!-- the ring tells the same story the bar did: a dim leading arc for the skipped
                     head (Ra_preview_offset), gold for what's been heard, all fractions of the
                     FULL track (skip + of).  Starts at 12 o'clock (the -90° rotation). -->
                <svg class="rf-ring" viewBox="0 0 60 60" aria-hidden="true">
                    <circle class="rf-ring-track" cx="30" cy="30" r="26"></circle>
                    {#if face.skip > 0}
                        <circle class="rf-ring-skip" cx="30" cy="30" r="26"
                                style="stroke-dasharray:{ringlen(face.skip / (face.skip + face.of))} {RING_C};"></circle>
                    {/if}
                    <circle class="rf-ring-fill" cx="30" cy="30" r="26"
                            style="stroke-dasharray:{ringlen(Math.min(1, face.at / face.of) * face.of / (face.skip + face.of))} {RING_C}; stroke-dashoffset:-{ringlen(face.skip / (face.skip + face.of))};"></circle>
                </svg>
            {/if}
            <button class="rf-btn rf-heart" onclick={() => (H as any)?.Radio_skip?.(n)} title="next">⏭</button>
        </div>
        {#if face.by}
            <button class="rf-btn rf-keep" class:kept={face.keptThis}
                onclick={() => { (H as any)?.Radio_keep?.(n) }}
                title={face.keptThis ? 'kept — open the keep and press ▶ to start the download' : "keep this — queues a download you start (▶) from the keep panel"}>{face.keptThis ? '✓' : '⇊'}</button>
        {/if}
    </div>
    <!-- provenance badge, unmistakably (the human 2026-08-07: "the UI in the player should be clear its
         remote, or local") — its own object like everything else here. -->
    {#if face.by}
        <div class="rf-src rf-src-remote">⚯ from {face.byName || 'a friend'}</div>
    {:else if face.solo && face.title && face.state !== 'off' && face.state !== 'digging'}
        <div class="rf-src rf-src-local">♪ LOCAL · {soloWhy(face)}</div>
    {:else if face.title && face.state !== 'off' && face.state !== 'digging'}
        <div class="rf-src rf-src-local">♪ LOCAL — your own record</div>
    {/if}
    {#if face.note}<div class="rf-note">{face.note}</div>{/if}
    <!-- terse on purpose (the owner 2026-08-21: "I'd like this message to just be '!tape'") — the
         endgame advance in Radio_pump_tick means a starve you actually SEE is now the rare mid-track
         kind, and a two-character bang reads faster than a sentence ever did. -->
    {#if face.state === 'starved'}<div class="rf-note">!tape</div>{/if}
    <!-- the small facts, each its own chip: the moving clock, then drops.  "N played" and
         "⚯ N on the dial" are GONE (the owner 2026-08-09: *"remove the '9 played' and '24 on the
          dial' from the %Radio cell, I don't care"*) — bookkeeping the listener never asked for.
         `face.played`/`face.pool` stay computed: `first` still forks on played, and the first-time
         chip still says how many tracks are ready — that one is an INVITATION, not a ledger. -->
    <div class="rf-chips">
        {#if face.of > 0}
            <!-- THE CLOCK IS HIDDEN (the owner 2026-08-11, quoting what it rendered: "0:00 + 0:00 /
                 1:00").  Numbers-as-time is the least round thing in a round room, and the ring
                 already says how far through we are.  Commented, not deleted — `mmss`, `face.at`,
                 `face.skip` and `.rf-clock`/`.rf-skiptime` all stay, so putting it back is
                 uncommenting this one span.
            <span class="rf-chip rf-clock">
                {#if face.skip > 0}<span class="rf-skiptime">{mmss(face.skip)} +</span> {mmss(face.at)} / {mmss(face.skip + face.of)}{:else}{mmss(face.at)} / {mmss(face.of)}{/if}
            </span>
            -->
            <!-- AND THE DROPS CHIP IS GONE TOO (the owner 2026-08-11: *"I don't need the Radio to say
                 '5 drops'"*) — the third and last of the ledger chips, going the same way as "N played"
                  and "⚯ N on the dial" for the same reason: a count of lost packets is something the
                   listener can neither act on nor want, and the audio itself already reports a drop
                    better than a number can.  `face.drops` stays computed (it is a real fact, and the
                     diagnostics still read it); only the chip left.
            {#if face.drops > 0}<span class="rf-chip">{face.drops} drops</span>{/if}
            -->
        {:else if face.state === 'digging' && !face.note}
            <span class="rf-chip">{face.own ? 'digging your crates…' : 'looking for a friend to play…'}</span>
        {:else if face.first}
            <span class="rf-chip">{face.pool > 0 ? `▶ plays your friends' music — ${face.pool} ${face.pool === 1 ? 'track' : 'tracks'} ready` : face.stock > 0 ? '▶ waiting for a friend — your own crate is in the Tuner' : '▶ waiting for a friend to come online'}</span>
        {/if}
    </div>
</div>
{/if}

<style>
    /* SMALL — THE PLAY BUTTON, and nothing else.  Intrinsic box on BOTH axes (no height:100%, which
       would measure the mold this face is sitting in and hand the layout an aspect that is not a fact
       about anything — see DoorFace's note, where that was a bug you could see). */
    .rf.rf-bud { font-size: 30px; line-height: 1; padding: 2px; color: #8d8da8; }
    .rf.rf-bud.on { color: #cfe8c0; }
    /* THE BITSY LAYOUT — a centred column of individual objects, sized for a round room. */
    .rf {
        pointer-events: none;
        width: max-content;
        max-width: 240px;
        padding: 6px 8px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #e8dcc0;
        text-align: center;
        display: flex; flex-direction: column; align-items: center; gap: 3px;
    }
    /* every piece is its own small object */
    .chip {
        background: rgba(16, 28, 36, 0.78);
        border: 1px solid rgba(217, 160, 38, 0.28);
        border-radius: 999px;
        padding: 2px 10px;
    }
    .rf-title { font-size: 12px; font-weight: 700; overflow-wrap: anywhere; max-width: 100%; }
    .rf-artist { font-size: 10px; opacity: 0.85; padding: 1px 8px; }
    .rf-transport { display: flex; align-items: center; gap: 10px; margin: 3px 0 1px; }
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
    /* the hub: the constant verb wears the progress ring */
    .rf-hub { position: relative; width: 56px; height: 56px; flex: none; }
    .rf-heart { position: absolute; inset: 8px; width: 40px; height: 40px; font-size: 17px; }
    .rf-ring { position: absolute; inset: 0; width: 100%; height: 100%; transform: rotate(-90deg); pointer-events: none; }
    .rf-ring-track { fill: none; stroke: #1a2f38; stroke-width: 3.4; }
    .rf-ring-skip  { fill: none; stroke: #3a4a52; stroke-width: 3.4; stroke-linecap: butt; }
    .rf-ring-fill  { fill: none; stroke: #d9a026; stroke-width: 3.4; stroke-linecap: round;
                     transition: stroke-dasharray 0.4s linear; }
    .rf-small { width: 24px; height: 24px; font-size: 10px; opacity: 0.8; }
    .rf-small:hover { opacity: 1; }
    .rf-keep { width: 30px; height: 30px; font-size: 12px; }
    .rf-keep.kept { background: #2e6b3a; border-color: #57c777; color: #eafff0; }
    .rf-keep.kept:hover { background: #57c777; color: #04202a; }
    .rf-note { font-size: 9px; opacity: 0.6; font-style: italic; }
    .rf-src {
        display: inline-block; padding: 1px 7px; border-radius: 999px;
        font-size: 0.72em; letter-spacing: 0.04em; font-weight: 600;
    }
    .rf-src-remote { background: rgba(127, 200, 232, 0.16); color: #8fd0ee; border: 1px solid rgba(127, 200, 232, 0.4); }
    .rf-src-local  { background: rgba(182, 201, 168, 0.13); color: #b6c9a8; border: 1px solid rgba(182, 201, 168, 0.32); }
    /* the small facts file in a wrapping row of chips, each its own object */
    .rf-chips { display: flex; flex-wrap: wrap; justify-content: center; gap: 3px; max-width: 100%; }
    .rf-chip {
        font-size: 9px; opacity: 0.85; white-space: nowrap;
        background: rgba(16, 28, 36, 0.6); border: 1px solid rgba(217, 160, 38, 0.16);
        border-radius: 999px; padding: 1px 7px;
    }
    /* pairs with the hidden clock chip above — uncomment both together, or svelte-check
       correctly calls this an unused selector.
    .rf-skiptime { opacity: 0.55; } */
    .on .rf-title { color: #ffd869; }
</style>
