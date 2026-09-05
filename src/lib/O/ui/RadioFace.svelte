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

    // HEART-SETTINGS (owner 2026-09-05: "long-press the heart to open heart-settings" — and before that,
    //  "the fact that ♥ can lead to Pooling or Heisting at your Cave is odd… needs explaining in one sentence").
    //   The sheet IS the explanation: one sentence, then the roads a ♥ can take on THIS device, each a line.
    //    It opens itself ONCE, after the first ♥ ever (Heard_tipped on the heard Mag — durable, stashed, never
    //     re-asked), and long-press is the way back forever.  The road switch (Heard_hand_set) and the tip are
    //      scalars on the Mag; the sheet holds no state of its own beyond open/closed.
    let sheet = $state(false)
    let holdT: any = null
    let held = false
    const HOLD_MS = 450
    const hold_start = () => { held = false; clearTimeout(holdT); holdT = setTimeout(() => { held = true; sheet = true }, HOLD_MS) }
    const hold_end = () => { clearTimeout(holdT); holdT = null }
    const like = () => {
        if (held) { held = false; return }              // the long-press already opened the sheet; not a like
        const ok = (H as any)?.Radio_like?.(n)
        try { const w = n?.c?.w; const me = (H as any)?.Radio_pub?.(w); if (ok && w && me && !(H as any)?.Heard_tipped?.(w, me)) { (H as any)?.Heard_tip?.(w, me); sheet = true } } catch {}
    }
    let roads = $derived.by(() => {
        void H?.version; void sheet
        try {
            const w = n?.c?.w; const me = (H as any)?.Radio_pub?.(w) || 'me'
            const ident = (H as any)?.Swarm_live_self?.()
            const targets = ident ? ((H as any)?.Heard_hand_targets?.(ident, (H as any)?.Heard_hand_myaddr?.(ident)) ?? []) : []
            return {
                copy: !!(w && (H as any)?.Ra_pool_consent?.(w)),
                folder: !!((H as any)?.Crate_nav?.()),
                hand: !!(w && (H as any)?.Heard_hand_on?.(w, me)),
                to: targets.length ? String(targets[0].name) : '',
            }
        } catch { return { copy: false, folder: false, hand: true, to: '' } }
    })
    const hand_toggle = () => { try { const w = n?.c?.w; const me = (H as any)?.Radio_pub?.(w) || 'me'; (H as any)?.Heard_hand_set?.(w, me, roads.hand ? 0 : 1); H?.bump_version?.() } catch {} }
    const hand_line = () => roads.hand ? (roads.to ? ' — ' + roads.to : ' — no linked device with a folder yet') : ' (off)'
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 1000)
        return () => clearInterval(iv)
    })

    // consent + want, read live (Ra_pool_consent / Radio_pool_wanted) so the source chip can say "needs setup"
    let pool_ok = $derived.by(() => { void H?.version; try { const w = n?.c?.w; return !!(w && (H as any)?.Ra_pool_consent?.(w)) } catch { return false } })
    // READY vs CARDS (owner 2026-09-05: "SoundPooling claims to have four but it says empty when I click next").
    //  A booked want mints its card at once; the bytes land later or never.  The dial plays only `ready`, so that
    //   is the number every surface here shows — `cards` rides beside it so "4 asked, 0 here yet" is sayable.
    let pool_c = $derived.by(() => { void H?.version; try { const w = n?.c?.w; const pub = (H as any)?.Radio_pub?.(w) || 'me'; return (H as any)?.Ra_pool_census?.(w, pub) ?? { cards: 0, ready: 0 } } catch { return { cards: 0, ready: 0 } } })
    let pool_n = $derived(pool_c.ready)
    let pool_wanted = $derived.by(() => { void H?.version; try { const w = n?.c?.w; return !!(w && (H as any)?.Radio_pool_wanted?.(w, null)) } catch { return false } })

    // THE SOURCE CHOOSER (owner 2026-09-05: *"when multiple Pier are online we should make the Grink in
    //  'from Grink' a dropdown (but upwards) chooser!"*).  `Radio_sources` is the model's answer — one row
    //   per %Theirs mirror that actually holds playable tracks, live-first — so the face lists what the
    //    dial can really reach rather than the friends list, which includes everyone with nothing to give.
    //  NOT ON `tick`.  This walks every mirror through `Ra_recs`; on the 1s clock that is a per-second
    //   crate walk for a menu nobody has opened.  `H.version` already folds in every real change to a
    //    mirror, which is the only thing that can move a row.
    let sources = $derived.by(() => { void H?.version; try { return (H as any)?.Radio_sources?.(n?.c?.w, n) ?? [] } catch { return [] } })
    let aimed_by = $derived.by(() => { void H?.version; return (n?.sc?.aim ? String(n?.sc?.aim_by || '') : '') })
    let menu = $state(false)
    // picking a holder PINS the dial (`sc.aim`) and leaves pool mode in the same act — Radio_aim_set owns
    //  both halves so the chip can never show "aimed at Grink" and "on the pool" at once.  '' = roam again.
    const aim_to = (pub: string) => { try { (H as any)?.Radio_aim_set?.(n, pub); H?.bump_version?.() } catch {} ; menu = false }
    // the pool is the one row that is not a holder, so it goes through the old flip rather than the aim —
    //  and only when we are not already there (Radio_source_next is a toggle, not a setter).
    const aim_pool = () => { try { if (face.source !== 'pool') (H as any)?.Radio_source_next?.(n); H?.bump_version?.() } catch {} ; menu = false }
    // more than one place to listen from ⇒ the press is a chooser; else it stays the old flip.
    let chooser = $derived(sources.length + (pool_ok ? 1 : 0) > 1)
    const chip_press = () => { if (chooser) { menu = !menu } else { try { (H as any)?.Radio_source_next?.(n) } catch {} } }
    let face = $derived.by(() => {
        void H?.version
        void tick
        const sc = n?.sc ?? {}
        // the first-time read: never played, nothing dialed — teach what ▶ will do, using the
        //  stoker's census (stock standing = the preheat already dug) so the promise is honest.
        const stock = +((n?.c?.w?.o?.({ Stoker: 1 })?.[0]?.sc?.stock) ?? 0)
        // the POOL: friend tracks standing in the %Theirs mirrors (the live share fill) —
        //  the radio dials across them too, and the face says so only when it's true.
        let pool = 0
        for (const home of (n?.c?.w?.o?.({ Theirs: 1 }) ?? [])) {
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
            source: (sc.source as string) ?? '',   // SoundPooling §2.6: '' | 'pool' — what the dial obeys
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
            // THE ♥ READS THE LEDGER, not a runtime mirror (2026-09-04).  `n.c.liked` dies with the process,
            //  so after a reload the heart went hollow while the ask it stood for was still standing — the
            //   button saying the opposite of the durable truth.  The mirror stays as the instant tell on
            //    the press itself (the ledger probe is a walk; the mirror is already in hand).
            likedThis: !!(
                (n?.c?.liked && n?.c?.rec?.sc?.id && n.c.liked[n.c.rec.sc.id]) ||
                (n?.sc?.by && n?.c?.rec?.sc?.id && (H as any)?.Heard_taken?.(n?.c?.w, (H as any)?.Radio_pub?.(n?.c?.w), n.sc.by, n.c.rec.sc.id))
            ),
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
    // ── PEERLESS: put the invite forward, right here (the owner 2026-08-28: *"in this case of being new
    //  and peerless they have the invite button put forward, on the Radio UI even? next to the local
    //   playing origin sayer"*).  We removed the fullscreen beg-to-share, so a new listener lands straight
    //    in the app playing their own shelf — and the one thing they still need, a way to bring a friend, now
    //     sits beside the ♪ LOCAL badge instead of greeting them at the door.  `door_friends === 0` is a
    //      COUNTED zero (stamped by standup, same read the Butler used) — `=== 0`, never `!x`, so it stays
    //       dark until the ghost has actually counted, rather than flashing on every boot's pre-count.  The
    //        button navigates to the Door cell (Sounditron_focus, world-resolved) where the QR + paste live.
    let peerless = $derived.by(() => { void H?.version; void tick; return (H?.c as any)?.door_friends === 0 })
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
            <button class="rf-btn rf-like" class:liked={face.likedThis} onclick={like}
                onpointerdown={hold_start} onpointerup={hold_end} onpointerleave={hold_end} onpointercancel={hold_end}
                oncontextmenu={(e) => { e.preventDefault(); sheet = true }}
                title={face.likedThis ? 'liked — it comes when this friend\'s turn comes round (see Haul)' : 'like this — the track is asked for and fetched one at a time per friend'}>{face.likedThis ? '♥' : '♡'}</button>
<!-- (the ⇊ keep button folded into ♥ — owner 2026-09-03: "turn the heist button into the like button") -->
        {/if}
    </div>
    {#if sheet}
        <!-- HEART-SETTINGS — the one sentence, then the roads.  Tap anywhere on it to close. -->
        <div class="rf-sheet" role="dialog" aria-label="what the heart does" onclick={() => { sheet = false }}>
            <div class="rf-sheet-law">♥ keeps it.</div>
            <div class="rf-road" class:on={roads.copy}>
                <span class="rf-road-tick">{roads.copy ? '✓' : '·'}</span>
                <span>a copy this phone can play{roads.copy ? '' : ' — set up in SoundPool'}</span>
            </div>
            {#if roads.folder}
                <div class="rf-road on"><span class="rf-road-tick">✓</span><span>the real file, into your music folder here</span></div>
            {:else}
                <button class="rf-road rf-road-btn" class:on={roads.hand} onclick={(e) => { e.stopPropagation(); hand_toggle() }}>
                    <span class="rf-road-tick">{roads.hand ? '✓' : '·'}</span>
                    <span>the real file, fetched by your linked device when it's around{hand_line()}</span>
                </button>
            {/if}
            <div class="rf-road rf-road-dim"><span class="rf-road-tick">·</span><span>the whole album it came from — not yet</span></div>
            <div class="rf-sheet-hint">hold ♥ to see this again</div>
        </div>
    {/if}
    <!-- provenance badge, unmistakably (the human 2026-08-07: "the UI in the player should be clear its
         remote, or local") — its own object like everything else here. -->
    <!-- THE SOURCE CHIP (Siphon_todo P2): the provenance badge is also the source selector —
         pressing it cycles friends-first ⇄ SoundPool via Radio_source_next, which stamps
         sc.source on the %Radio particle; the dial obeys it (Radio_dial's pool rung). -->
    <!-- ONE CHOOSER OVER EVERY CHIP (owner 2026-09-05: "not every sourcechangebutton click opens that menu").
         The first cut hung the menu on the from-a-friend chip only, so on ♪ SOUNDPOOL or ♪ LOCAL a press still
         did the old blind flip.  Now the wrapper + menu sit OUTSIDE the variant fork: whatever the chip says,
         a press opens the chooser whenever there is more than one place to listen from (friends + the pool),
         and only a one-source tab keeps the flip.  UPWARDS because the chip sits at the foot of the face. -->
    {#if face.source === 'pool' || face.by || (face.title && face.state !== 'off' && face.state !== 'digging')}
        <div class="rf-srcwrap">
            {#if menu}
                <div class="rf-menu">
                    {#each sources as s}
                        <button class="rf-menu-row" class:rf-menu-on={s.aimed && face.source !== 'pool'} onclick={() => aim_to(s.pub)}
                            title={s.live ? 'online now' : 'not heard from lately — the dial will pass over them'}>
                            <span class="rf-menu-dot" class:rf-menu-live={s.live}>●</span><span class="rf-menu-name">{s.name || s.pub.slice(0, 8)}</span><span class="rf-menu-n">{s.tracks}</span>
                        </button>
                    {/each}
                    <!-- ROAMING IS A CHOICE TOO, and it is the default the pin overrides — so it is a row,
                         not the absence of one.  Without it a listener who pinned Grink has no way back. -->
                    <button class="rf-menu-row rf-menu-any" class:rf-menu-on={!aimed_by && face.source !== 'pool'} onclick={() => aim_to('')}>any friend</button>
                    <!-- the pool wears its count like every holder row — the PLAYABLE count, the one the dial obeys;
                         "4 asked, 1 here" reads as 1/4 so the row never claims more than next can deliver. -->
                    {#if pool_ok}<button class="rf-menu-row rf-menu-any" class:rf-menu-on={face.source === 'pool'} onclick={aim_pool}
                        title={pool_c.cards > pool_c.ready ? pool_c.ready + ' playable of ' + pool_c.cards + ' asked for' : pool_c.ready + ' playable'}>
                        <span class="rf-menu-name">♪ SOUNDPOOL</span><span class="rf-menu-n">{pool_c.cards > pool_c.ready ? pool_c.ready + '/' + pool_c.cards : pool_c.ready}</span></button>{/if}
                </div>
            {/if}
            {#if face.source === 'pool'}
                <button class="rf-src rf-src-local rf-src-pool" onclick={chip_press} title={chooser ? 'press to choose where to listen from' : 'press to flip to friends'}>♪ SOUNDPOOL{#if chooser}<span class="rf-src-caret"> ▴</span>{/if}</button>
                {#if !pool_ok}<button class="rf-src-sub rf-invite-link" onclick={() => (H as any)?.Sounditron_focus?.('Pooling')} title="open SoundPool">setup</button>
                {:else if !pool_n}<div class="rf-src-sub">{pool_c.cards ? pool_c.cards + ' pooled · none playable yet' : 'empty'}</div>{/if}
            {:else if face.by}
                <button class="rf-src rf-src-remote" class:rf-src-aimed={aimed_by} onclick={chip_press}
                    title={chooser
                        ? (aimed_by ? 'pinned to ' + aimed_by + ' — press to choose someone else' : 'the source — press to choose who you are listening to')
                        : 'the source — press to flip friends | SoundPool'}
                    >{aimed_by ? '⦿ ' : 'from '}{aimed_by || face.byName || 'a friend'}{#if chooser}<span class="rf-src-caret"> ▴</span>{/if}</button>
            {:else if face.solo}
                <button class="rf-src rf-src-local" onclick={chip_press} title={chooser ? 'press to choose where to listen from' : 'the source — press to flip friends | SoundPool'}>♪ LOCAL · {soloWhy(face)}{#if chooser}<span class="rf-src-caret"> ▴</span>{/if}</button>
            {:else}
                <button class="rf-src rf-src-local" onclick={chip_press} title={chooser ? 'press to choose where to listen from' : 'the source — press to flip friends | SoundPool'}>♪ LOCAL — your own record{#if chooser}<span class="rf-src-caret"> ▴</span>{/if}</button>
            {/if}
        </div>
    {/if}
    {#if !pool_ok && pool_wanted && face.source !== 'pool'}
        <button class="rf-src-sub rf-invite-link" onclick={() => (H as any)?.Sounditron_focus?.('Pooling')} title="open SoundPool">SOUNDPOOL setup</button>
    {/if}
    <!-- THE INVITE, PUT FORWARD FOR A PEERLESS LISTENER — sits right under the ♪ LOCAL sayer, because
         "playing your own record, alone" is the exact moment bringing a friend is the obvious next move.
         Shows only on a counted-zero friend count, and only while something local is actually saying so
         (the same visibility as the local badge above), so it never nags a tab that has friends or a
         player sitting off.  Press → the Door cell, where the invite QR + paste already live.
         WORDED AS A FACT WITH A DOOR IN IT (the owner 2026-08-28: "have the thing by LOCAL say
          'no peers ever, [invite some]' where invite some is a link to the Door"). -->
    {#if peerless && face.by == null && face.title && face.state !== 'off' && face.state !== 'digging'}
        <div class="rf-src rf-src-local">no peers ever, <button class="rf-invite-link" onclick={() => H?.Sounditron_focus?.('Door')}
            title="bring a friend in to listen together (opens the Door, where the invite QR lives)">invite some</button></div>
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
            <!-- OWN-RADIO FIRST (the owner 2026-08-28: "should just get on with your own Radio ASAP") —
                 a stocked shelf is an invitation to press play NOW, never a waiting room for a friend. -->
            <span class="rf-chip">{face.pool > 0 ? `▶ plays your friends' music — ${face.pool} ${face.pool === 1 ? 'track' : 'tracks'} ready` : face.stock > 0 ? `▶ your own records — ${face.stock} ready to play` : '▶ nothing on the shelf yet'}</span>
        {/if}
    </div>
</div>
{/if}

<style>
    /* HEART-SETTINGS: a small card over the face, pointer-events re-armed (the overlay is none). */
    .rf-sheet { position: absolute; left: 8px; right: 8px; bottom: 56px; z-index: 5; pointer-events: auto; background: rgba(18, 16, 24, 0.96); color: #eee; border: 1px solid rgba(255, 210, 120, 0.35); border-radius: 10px; padding: 10px 12px; font-size: 12.5px; line-height: 1.35; box-shadow: 0 6px 24px rgba(0,0,0,0.45); }
    .rf-sheet-law { font-weight: 700; font-size: 14px; margin-bottom: 6px; color: #ffd27a; }
    .rf-road { display: flex; gap: 8px; align-items: baseline; padding: 3px 0; opacity: 0.55; text-align: left; }
    .rf-road.on { opacity: 1; }
    .rf-road-dim { opacity: 0.35; font-style: italic; }
    .rf-road-btn { background: none; border: 0; color: inherit; font: inherit; width: 100%; cursor: pointer; padding: 3px 0; }
    .rf-road-tick { width: 1em; flex: 0 0 1em; color: #ffd27a; }
    .rf-sheet-hint { margin-top: 6px; font-size: 11px; opacity: 0.5; }
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
    .rf-src-sub { display: block; margin-top: -2px; font-size: .78em; opacity: .75; letter-spacing: .3px; }
    .rf-keep { width: 30px; height: 30px; font-size: 12px; }
    .rf-like { width: 30px; height: 30px; font-size: 14px; }
    .rf-like.liked { background: #6b2e3a; border-color: #c75777; color: #ffeaf0; }
    .rf-keep.kept { background: #2e6b3a; border-color: #57c777; color: #eafff0; }
    .rf-keep.kept:hover { background: #57c777; color: #04202a; }
    .rf-note { font-size: 9px; opacity: 0.6; font-style: italic; }
    .rf-src {
        display: inline-block; padding: 1px 7px; border-radius: 999px;
        font-size: 0.72em; letter-spacing: 0.04em; font-weight: 600;
    }
    /* the badge is now ALSO a button (the source chip) — keep its badge look, add the hand */
    button.rf-src { pointer-events: auto; cursor: pointer; font-family: inherit; }
    button.rf-src:hover { filter: brightness(1.25); }
    .rf-src-remote { background: rgba(127, 200, 232, 0.16); color: #8fd0ee; border: 1px solid rgba(127, 200, 232, 0.4); }
    /* PINNED reads as a filled chip, not a differently-worded one: "⦿ Grink" and "from Grink" must be
       distinguishable at a glance from across the room, which is the whole point of a badge. */
    .rf-src-aimed { background: rgba(127, 200, 232, 0.34); color: #d8f0ff; border-color: rgba(127, 200, 232, 0.75); }
    .rf-src-caret { opacity: .7; font-size: .9em; }
    /* the upward chooser.  `position:absolute; bottom:100%` is the "but upwards" — anchored to the chip so
       it tracks wherever the glass puts the face, and pointer-events re-armed because the .rf overlay is
       pointer-events:none (the glass must stay pannable; only controls opt back in). */
    .rf-srcwrap { position: relative; display: inline-block; pointer-events: auto; }
    .rf-menu {
        position: absolute; bottom: 100%; left: 0; margin-bottom: 5px; z-index: 5;
        display: flex; flex-direction: column; gap: 1px; min-width: 132px;
        padding: 3px; border-radius: 8px;
        background: rgba(6, 24, 32, 0.96); border: 1px solid rgba(127, 200, 232, 0.4);
        box-shadow: 0 6px 18px rgba(0, 0, 0, 0.55);
    }
    .rf-menu-row {
        pointer-events: auto; cursor: pointer; font-family: inherit;
        display: flex; align-items: center; gap: 5px; width: 100%;
        padding: 3px 6px; border: none; border-radius: 5px;
        background: none; color: #8fd0ee; font-size: 0.72em; font-weight: 600;
        letter-spacing: 0.04em; text-align: left; white-space: nowrap;
    }
    .rf-menu-row:hover { background: rgba(127, 200, 232, 0.18); color: #d8f0ff; }
    .rf-menu-on { background: rgba(127, 200, 232, 0.26); color: #d8f0ff; }
    .rf-menu-name { flex: 1; }
    /* the dot is presence and nothing else — a dim dot is "not heard from lately", which is a real row
       worth showing (their tracks are still mirrored) rather than one worth hiding. */
    .rf-menu-dot { font-size: 0.7em; opacity: 0.28; line-height: 1; }
    .rf-menu-live { opacity: 1; color: #7fd8a0; }
    .rf-menu-n { opacity: 0.55; font-weight: 400; }
    .rf-menu-any { color: #b6c9a8; }
    .rf-menu-any:hover { background: rgba(182, 201, 168, 0.18); color: #e6f0dd; }
    .rf-src-local  { background: rgba(182, 201, 168, 0.13); color: #b6c9a8; border: 1px solid rgba(182, 201, 168, 0.32); }
    /* the peerless invite nudge — a plain sentence with a warm link in it ("no peers ever, invite some"),
       the link a real button that opts pointer-events back in through the .rf overlay's
       pointer-events:none shield.  Sits just under the ♪ LOCAL badge, quiet enough not to fight the
       player but present enough to be the obvious next move. */
    .rf-invite-link {
        pointer-events: auto; cursor: pointer;
        display: inline; padding: 0 2px; margin: 0;
        font-size: inherit; font-weight: 600;
        background: none; border: none;
        color: #e9b84e; text-decoration: underline; text-underline-offset: 2px;
    }
    .rf-invite-link:hover { color: #ffd76e; }
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
