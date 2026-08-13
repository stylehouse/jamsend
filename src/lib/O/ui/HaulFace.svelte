<script lang="ts">
    // HaulFace — WHAT YOU HEISTED (the owner 2026-08-13, ruling on whether to build it: *"yeah build
    //  something aye"*).  The list of albums that have actually landed in your collection, newest first.
    //
    // WHERE THE DATA COMES FROM, AND WHY THERE IS NO SECOND LEDGER.  Heist_todo's vocabulary table
    //  reserves `%Haul` for "the What Heisted ledger" and states *"The ledger is not built yet"* — which
    //   is stale.  The newlyadded log has recorded every landed file durably for weeks (`of` the path,
    //    `dir` the folder, `at` when it first landed, `id` the Mag join to the holding), and
    //     `Heist_newlyadded_grouped` already folds it per ALBUM, which is the unit this list wants.  What
    //      was missing was a surface, not a store.  `Heist_haul_look` mirrors that ledger onto a dontSnap
    //       `%Hauls` bag on a slow beat; this face reads the bag.  Two stores for one fact would be the
    //        "there's only one of anything" mistake the project keeps having to un-make.
    //
    // WHAT IT CANNOT SAY: who gave it to you.  The newlyadded log deliberately never records a source
    //  (its own header states the rule; the owner restated it 2026-08-11 — *"just the destination
    //   directory and when, not who it came from"*).  A blank where "from S" would go is a RULING.
    //
    // ── AND THE HALF THAT IS STILL COMING (the owner 2026-08-13: *"hmm I thought Haul was all Heists we
    //  were currently working on... think about presenting them all on Haul, such that we can click into
    //   them through there, where you can cancel them.  building the ways through the UI to the objects"*).
    //  This cell read "the larger collective" as THE PAST — albums that landed.  The owner read it as THE
    //   PRESENT — every nab in flight.  Both are the whole take, and the half that was missing is the half
    //    with verbs on it: a heist you can open, promote, pause or call off.
    //  IT IS A WAY THROUGH, NOT A CONTROL PANEL.  Every row is a door to the %Heist particle itself, which
    //   is where the real form lives; the row carries only what you decide FROM a list — which one, in what
    //    order, and "not this one".  `Heist_live_rows` finds the same particles the beat walks and orders
    //     them with the same verb the beat orders them by, so this list cannot claim a running order the
    //      machine does not have.
    //  NOTHING HERE MINTS.  `Heist_live_rows`/`Heist_shop_find` are `o`-only by construction (a reader
    //   built on `oai` conjures what it reports on, and a face asks every poll).
    // Props { n, H } — `n` is the %Hauls bag.  Reads off .sc, so no work happens in the render: the disk
    //  read is Heist_keep_beat's, 20s apart.  A slow local tick keeps "2h ago" honest between bumps, the
    //   HeistFace/UptimeFace idiom — H.version can go quiet for minutes on a settled tab.
    let { n, H } = $props()
    const A = H as any
    // The world the bag hangs off IS the radio|Sounditron world (Heist_haul_look stamps `.c.up = rw`), which
    //  is what both the heist reader and the focus verbs want.
    // ⚠ WITH A FALLBACK, BECAUSE `.c` DIES ON RELOAD.  `c.up` is re-stamped by Heist_haul_look — on the SLOW
    //  beat, up to ~20s after a reload.  That gap did not matter while this cell only listed the past; it
    //   matters now that Sounditron stops budding heists individually when this cell is on the rim, because
    //    a blank live list for 20s would mean NO WAY IN to a running heist at all.  `H.c.radio_w` is stamped
    //     at boot and answers immediately, so the two together have no window.
    let W = $derived((n as any)?.c?.up ?? (H as any)?.c?.radio_w ?? null)

    // TWO CLOCKS, because the cell now shows two tenses.  "2h ago" is happy at 30s; a running heist's
    //  landed-count is not, and this cell is the one place you watch several at once.  One 1s tick with a
    //   cheap derive is simpler than two intervals, and it is the HeistFace cadence (500ms) halved.
    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 1000); return () => clearInterval(iv) })

    function ago(atSecs: number): string {
        if (!atSecs) return ''
        const s = Math.max(0, Math.floor(Date.now() / 1000) - atSecs)
        if (s < 90) return 'just now'
        const m = Math.floor(s / 60)
        if (m < 60) return `${m}m ago`
        const h = Math.floor(m / 60)
        if (h < 24) return `${h}h ago`
        const d = Math.floor(h / 24)
        return d === 1 ? 'yesterday' : `${d}d ago`
    }

    let face = $derived.by(() => {
        void H?.version
        void tick
        // `n` IS the bag, so read it directly — `o()` finds, it never mints.  (Going through the ghost's
        //  Heist_haul_rows would work too, but it takes the world and would make this face depend on
        //   `n.c.up` being wired; the rows are right here.)  A reader built on `oai` would mint on every
        //    poll, which is how a face quietly becomes a writer — the reason to say which this is.
        const rows: any[] = (n?.o?.({ Haul: 1 }) ?? []).slice().sort((a: any, b: any) => (+b.sc.at || 0) - (+a.sc.at || 0))
        const albums = rows.map((r: any) => ({
            key: String(r.sc.dir || ''),
            name: String(r.sc.name || r.sc.dir || ''),
            above: String(r.sc.above || ''),
            tracks: +(r.sc.tracks || 0),
            at: +(r.sc.at || 0),
            when: ago(+(r.sc.at || 0)),
            // FRESH IS NOW A CLOCK, NOT AN OPINION (2026-08-13).  It read `feeling === 'fresh'` — a field
            //  the app had no writer for, so in practice EVERY landed row was green forever, which is the
            //   same as no highlight at all.  The owner cut feelings (*"I never signed off on holding
            //    feelings for each track"*).  A download list's honest "new" is "arrived today", which the
            //     ledger's `at` already knows and nobody has to maintain.
            fresh: +(r.sc.at || 0) >= Math.floor(Date.now() / 1000) - 86400,
        }))
        let tracks = 0
        for (const a of albums) tracks += a.tracks
        // TODAY is the number worth leading with: a list that only ever grows stops being news, and the
        //  one question you come back to this cell with is "did the ones I left running land?".
        const dayAgo = Math.floor(Date.now() / 1000) - 86400
        const today = albums.filter((a) => a.at >= dayAgo)

        // ── the live half.  `keep` is the PARTICLE, carried on the row so a press acts on the object
        //  rather than on a name — the whole point of the ways-through (all %Heists share a mainkey, so a
        //   string could not have addressed one of five; the same reason `focused_keep` exists at all).
        const keeps: any[] = A?.Heist_live_rows?.(W) ?? []
        const live = keeps.map((k: any) => {
            const g = A?.Heist_keep_gist?.(k) ?? { word: '', live: 1, form: 0, landed: 0, total: 0 }
            return {
                keep: k,
                key: String(k.sc.seed || k.sc.Heist || ''),
                name: String(k.sc.Heist || k.sc.seed || 'heist'),
                // NB no `from` — who gave it to you is deliberately unrecorded (the newlyadded log's own
                //  rule, restated by the owner 2026-08-11: *"just the destination directory and when, not
                //   who it came from"*).  A live heist DOES know its source, but showing it here and not on
                //    the landed row below would make the list say two different things about one album.
                word: String(g.word || ''),
                form: !!g.form,
                paused: !!k.sc.paused,
                landed: +(g.landed || 0),
                total: +(g.total || 0),
                // the unity, if the record knew it — the count the form leads with, so the list and the
                //  form cannot quote different sizes for the same folder.
                unN: +(k.sc.un_n || 0),
            }
        }).filter((r: any) => String(r.keep.sc.state || 'primed') !== 'done')

        // HOW MANY ALBUMS THERE REALLY ARE, which is NOT `albums.length`.  `Heist_haul_look` whittles the
        //  bag to the newest 40 (`Heist_haul_keep`) so the slow beat cannot re-mint and re-drop hundreds of
        //   rows every pass, and it stamps the true total on the bag as `n_all` for exactly this line.
        //  A CAP THAT DOES NOT SAY SO READS AS COMPLETENESS.  Without this the cell would count its own
        //   truncated list and tell a human with 300 landed albums that they have 40 — the most confident
        //    possible way to be wrong, since nothing on screen would look like an omission.
        const nAll = Math.max(+((n as any)?.sc?.n_all ?? 0), albums.length)

        return {
            albums, tracks, nAll, today: today.length, todayTracks: today.reduce((s, a) => s + a.tracks, 0),
            // (no `anyPausable` — it was minted for a "pause all" that has not been asked for.  A derive
            //  nothing renders is a fact thrown away every pass; if pause-all lands, it wants a real verb
            //   on the ghost, not a boolean here.  See [[derived-in-a-face-is-a-fact-thrown-away]].)
            live,
        }
    })

    // ── THE VERBS.  Each one is the SAME call the heist's own cell makes — this list is a second way to
    //  the object, never a second implementation of what pressing it means.
    function open(keep: any) { A?.Sounditron_focus_keep?.(W, keep) }
    function pause(keep: any) { A?.Heist_keep_pause?.(keep) }
    function resume(keep: any) { A?.Heist_keep_resume?.(keep) }
    function first(keep: any) { A?.Heist_keep_first?.(keep) }
    // CANCEL ARMS ONCE.  It drops the intent and keeps whatever already landed — recoverable in the sense
    //  that no file is deleted, but it does throw away a setup you may have spent a minute on, and in a
    //   LIST the row under your cursor moves as heists finish. One confirming press, armed per row, and it
    //    disarms on any other press. (The 🗑 that really deletes stays in the cell, where it belongs.)
    // ── SMALL IS JUST THE ARROWS (the owner 2026-08-13: *"the Haul cell should just have the downdown
    //  arrows icon when small"*).  Sounditron's focus cut stamps `.c.pose = 'small'` on every bud, and the
    //   pose law says a bud draws *"name, and an icon if you have one.  Nothing else"* — this cell was
    //    drawing its head, its counts and its whole live list at rim size, where none of it is readable.
    //  ⇊ IS THE APP'S OWN WORD for this (the press that starts a heist, the ⇊✓/⇊⏸/⇊↑ console marks), so at
    //   bud size the glyph alone says "your downloads" without a syllable of chrome.  Not even the ✓/⇊
    //    tense swap: at this size a changing glyph reads as a different cell, which is the mirror-tok
    //     lesson ([[a-cells-identity-was-its-state]]) arriving through the eye instead of the renderer.
    //  `.c` never bumps, so it is the 1s tick that keeps this live — same as everything else here.
    let bud = $derived.by(() => { void H?.version; void tick; return String((n as any)?.c?.pose ?? '') === 'small' })

    let arm = $state('')
    $effect(() => { void tick; if (arm && !face.live.some((r: any) => r.key === arm)) arm = '' })
    function cancel(row: any) {
        if (arm !== row.key) { arm = row.key; return }
        arm = ''
        A?.Heist_keep_cancel?.(W, row.keep)
    }
</script>

{#if bud}
    <!-- the whole cell is the button (Vytui draws a pressable organ as one and runs `.c.press` on click),
         so this needs no handler of its own — pressing it makes Haul the belly like any other bud. -->
    <div class="hf hf-bud"><span class="hf-badge going">⇊</span></div>
{:else}
<div class="hf">
    <div class="hf-head">
        <!-- the badge follows the TENSE: something in flight makes this a live cell, not an archive -->
        <span class="hf-badge" class:going={face.live.length}>{face.live.length ? '⇊' : '✓'}</span>
        <span class="hf-mk">Haul{#if face.nAll}<span class="hf-mkv">:{face.nAll}</span>{/if}</span>
        <!-- NO "nothing yet" TAIL BRANCH: with nothing landed the .hf-empty line below already says the
             cell is empty, and says it better (it says what WOULD be here).  Two ways of saying nothing
             happened is the cheapest kind of furniture and the easiest to miss. -->
        <span class="hf-sub">
            {#if face.live.length}{face.live.length} on the go{:else if face.today}{face.todayTracks} track{face.todayTracks === 1 ? '' : 's'} today{:else if face.tracks}{face.tracks} track{face.tracks === 1 ? '' : 's'} kept{/if}
        </span>
    </div>

    {#if face.live.length}
        <div class="hf-list hf-live">
            {#each face.live as r (r.key)}
                <!-- THE ROW IS THE DOOR.  The name is the button; the verbs sit to its right and stop the
                     press from bubbling, so "open it" and "call it off" can never be the same click. -->
                <div class="hf-row hf-liverow" class:paused={r.paused}>
                    <button class="hf-open" onclick={() => open(r.keep)} title="open this heist">
                        <!-- the name carries its OWN title, the landed row's idiom: an album folder is
                             routinely longer than 320px and the name is what elides, so hovering the
                             elided thing has to show the thing (hovering anywhere else still offers the
                             door's own tooltip — the innermost title wins). -->
                        <span class="hf-name" title={r.name}>{r.name}</span>
                        <span class="hf-state">{r.word}{#if !r.form && r.total}&nbsp;{r.landed}/{r.total}{:else if r.form && r.unN}&nbsp;{r.unN} track{r.unN === 1 ? '' : 's'}{/if}</span>
                    </button>
                    <span class="hf-acts">
                        {#if r.paused}
                            <button class="hf-b" onclick={() => resume(r.keep)} title="carry on with this one">▶</button>
                        {:else}
                            <button class="hf-b" onclick={() => pause(r.keep)} title="not now — it keeps its place and everything you set up">⏸</button>
                        {/if}
                        {#if face.live.length > 1}
                            <button class="hf-b" onclick={() => first(r.keep)} title="run this one before the others">↑</button>
                        {/if}
                        <button class="hf-b hf-x" class:armed={arm === r.key}
                                onclick={() => cancel(r)}
                                title={arm === r.key ? 'press again to call it off — anything already landed stays' : 'call this heist off'}
                        >{arm === r.key ? 'sure?' : '✕'}</button>
                    </span>
                </div>
            {/each}
        </div>
    {/if}

    {#if !face.albums.length}
        <!-- an empty list still says what it IS, so the cell is never a mystery blank.  Only when nothing
             is in flight either — with heists going, the list above already says what this cell is for. -->
        {#if !face.live.length}
            <div class="hf-empty">music you keep off a friend's radio lands here</div>
        {/if}
    {:else}
        <!-- the two tenses need one word between them, and only when both are on screen: with nothing in
             flight the ✓ header already says what the list is. -->
        {#if face.live.length}<div class="hf-sep">landed</div>{/if}
        <div class="hf-list">
            {#each face.albums.slice(0, 12) as a (a.key)}
                <div class="hf-row" class:fresh={a.fresh}>
                    <span class="hf-n">{a.tracks}</span>
                    <span class="hf-name" title={a.key}>
                        {#if a.above}<span class="hf-above">{a.above}/</span>{/if}{a.name}
                    </span>
                    <span class="hf-when">{a.when}</span>
                </div>
            {/each}
            <!-- counted off `nAll`, not off the rendered list: the bag itself is capped at 40, so
                 `albums.length - 12` was an overflow line bounded by a cap it never mentioned — it would
                 sit at "…and 28 more" for ever while the real number climbed past 300. -->
            {#if face.nAll > 12}
                <div class="hf-more">…and {face.nAll - 12} more</div>
            {/if}
        </div>
    {/if}
</div>
{/if}

<style>
    /* THE BUD: one glyph, centred, and no box of its own — the cell IS the box.  `min-width/height 0` and
       no padding so the mold measures the glyph rather than a 320px-wide shell with one character in it
       ([[a-face-must-hand-back-an-intrinsic-box]]: height:100% measures the mold it was given, so a bud
       that keeps the full-size padding hands back a box that is mostly air and gets sized for the air). */
    .hf-bud {
        max-width: none; padding: 0; gap: 0;
        align-items: center; justify-content: center;
        font-size: 20px; line-height: 1;
    }
    .hf-bud .hf-badge { font-size: inherit; }

    /* POINTER-EVENTS:NONE ON THE ROOT — the glass_kinds contract, which this face was missing (it was
       written without a browser to look with).  Vytui's .face-mold is a RECTANGLE at the cell's bbox and
       voronoi bboxes overlap heavily, so any face root left `auto` floats its dead padding over a
       neighbour's controls and eats the click — the symptom already recorded in Vytui as "pause is
       impossible to click sometimes", which this cell of all cells must not cause: it is full of ⏸.
       An `auto` descendant still hit-tests its own small box under a `none` ancestor, so every part you
       can press or hover re-arms below (.hf-open, .hf-b, and .hf-name for its title). */
    .hf {
        pointer-events: none;
        font-family: system-ui, sans-serif; color: #d8e4f5;
        display: flex; flex-direction: column; gap: 5px;
        padding: 6px 8px; max-width: 320px;
    }
    .hf-head { display: flex; align-items: baseline; gap: 6px; }
    .hf-badge { color: #6fd08a; font-size: 12px; flex: none; }
    .hf-mk { font-size: 12px; font-weight: 600; letter-spacing: 0.02em; }
    .hf-mkv { color: #8fb4e8; }
    .hf-sub { font-size: 9.5px; color: rgba(160, 180, 210, 0.7); letter-spacing: 0.04em; }
    .hf-empty { font-size: 10px; color: rgba(150, 170, 200, 0.55); line-height: 1.4; }
    .hf-list { display: flex; flex-direction: column; gap: 2px; }
    /* the row is grid, not flex, so the counts line up down the left and a long album name truncates
       instead of pushing the "2h ago" off the cell — the one thing you scan this list for. */
    .hf-row {
        display: grid; grid-template-columns: 1.6rem 1fr auto; align-items: baseline;
        gap: 6px; font-size: 10.5px; line-height: 1.5;
    }
    .hf-n {
        font-variant-numeric: tabular-nums; text-align: right;
        color: #8fb4e8; font-weight: 600;
    }
    /* `width: max-content` + `max-width: 100%` so the name's BOX is the name: short ones stop at their
       text (which is what the `title` hover has to hug now that the root is pointer-events:none), long
       ones clamp to the column and elide as before.  `pointer-events: auto` is only for that title. */
    .hf-name {
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
        width: max-content; max-width: 100%; pointer-events: auto;
    }
    /* the folder ABOVE the album is dimmer — it is context (the artist), not the thing itself.
       LEFT AS ONE ELIDED STRING ON PURPOSE, having tried the other way: the single ellipsis spends the
       room in reading order, so a very long artist folder shortens the ALBUM rather than itself.  The
       obvious fix — cap the artist with a `max-width: 40%` inline-block — is wrong, because the name is
       a shrink-to-fit box: the percentage resolves against the pair's OWN width, so "The Beatles/Revolver"
       would elide the artist while sitting in a half-empty row.  Doing it properly needs the pair to
       become two flex items with unequal shrink, and that changes what baseline the row aligns on for a
       gain of a few characters — not a trade to make blind. */
    .hf-above { color: rgba(150, 170, 200, 0.55); }
    .hf-when { font-size: 9px; color: rgba(150, 170, 200, 0.6); white-space: nowrap; }
    /* it landed today.  Quiet: this is a tint, not an alarm.  (Was "still on probation" while the row
       carried a `feeling`; that field had no writer and is gone — see the `fresh` derive above.) */
    .hf-row.fresh .hf-n { color: #6fd08a; }
    /* the overflow line starts where the NAMES start (the count column + its gap), not at a guessed
       indent — it is the twelfth row's continuation, so it reads as one column with them. */
    .hf-more { font-size: 9px; color: rgba(150, 170, 200, 0.5); padding-left: calc(1.6rem + 6px); }

    /* ── the live half ──────────────────────────────────────────────────────────────────────────────
       Deliberately NOT styled like the landed rows: they are different tenses and a glance has to tell
       them apart without reading. Warm pink is the heist colour everywhere else in this app (kf-title),
       so the cell borrows it rather than inventing a third vocabulary. */
    .hf-badge.going { color: #e8a9c0; }
    /* THE TENSES DIFFER IN SHAPE, NOT ONLY IN COLOUR.  Pink-vs-grey is the right vocabulary but it is a
       weak tell on the rim, where this cell is a bud a few dozen pixels tall and half of it is read at a
       glance from across the glass (and no tell at all for a colour-blind eye).  A rail down the live
       block indents it as a GROUP: two shapes, one question answered without reading a word.  It costs
       8px of width and nothing in height, which is the only budget a shrinking glass has. */
    .hf-live {
        gap: 3px;
        border-left: 2px solid rgba(232, 169, 192, 0.32); padding-left: 6px;
    }
    /* the word and the rule on ONE line, rather than a full-width border above a line of its own: the
       separator was paying for ~20px to say six letters, and the rail above already marks where the live
       half stops.  The rule runs out from the word to the cell edge, so the label reads as a heading of
       what's below rather than as a divider that happens to have a word stuck on it. */
    .hf-sep {
        display: flex; align-items: center; gap: 6px;
        font-size: 8.5px; letter-spacing: 0.09em; text-transform: uppercase;
        color: rgba(150, 170, 200, 0.42); margin-top: 4px;
    }
    .hf-sep::after {
        content: ''; flex: 1 1 auto; height: 1px;
        background: rgba(150, 170, 200, 0.13);
    }
    /* two columns, not three: the name+state button takes the room and the verbs are intrinsic, so a long
       album title truncates instead of pushing ✕ out of the cell (the same law the landed row follows). */
    .hf-liverow { grid-template-columns: 1fr auto; gap: 4px; align-items: center; }
    /* PAUSED DIMS THE HEIST, NOT THE CONTROLS.  The dim was on the whole row, which faded ▶ — the one
       button a stopped heist exists to offer — along with the name it was reporting on.  A control must
       never advertise its own disuse; opacity on the parent cannot be taken back by a child, so the dim
       lives on the door instead. */
    .hf-liverow.paused .hf-open { opacity: 0.62; }
    .hf-open {
        pointer-events: auto;
        display: flex; align-items: baseline; gap: 5px; min-width: 0;
        background: none; border: 0; padding: 1px 2px; margin: 0; cursor: pointer;
        font: inherit; text-align: left; color: #e8a9c0; border-radius: 3px;
    }
    .hf-open:hover { background: rgba(232, 169, 192, 0.09); }
    .hf-open:active { transform: translateY(1px); }
    .hf-open .hf-name { font-weight: 600; }
    .hf-state {
        font-size: 8.5px; color: rgba(160, 180, 210, 0.72); white-space: nowrap; flex: none;
        font-variant-numeric: tabular-nums;
    }
    .hf-acts { display: flex; gap: 3px; flex: none; }
    /* A 9px GLYPH IN 1px OF PADDING IS A TARGET, NOT A BUTTON.  These were ~15×14 boxes — under a finger
       on the rim that is a coin toss between "pause" and "call it off", which are not neighbouring
       meanings.  The box is now square-ish and ≥18px, the glyph centred in it (inline-flex, so ⏸ ▶ ↑ ✕
       sit on the box's middle rather than on a text baseline that each of them measures differently).
       Height is what a press aims at and it costs the row nothing: the name line is already ~16px. */
    .hf-b {
        pointer-events: auto;
        display: inline-flex; align-items: center; justify-content: center;
        min-width: 20px; min-height: 18px;
        background: none; border: 1px solid rgba(150, 175, 215, 0.28); border-radius: 3px;
        color: rgba(190, 210, 235, 0.85); font: inherit; font-size: 9.5px; line-height: 1;
        padding: 2px 5px; cursor: pointer;
    }
    .hf-b:hover { border-color: rgba(150, 175, 215, 0.6); color: #d7e6f7; }
    .hf-b:active { transform: translateY(1px); }
    /* the keyboard's version of :hover — invisible to a mouse, and the rail colour so a tabbed press
       lands in the same vocabulary the row is already speaking. */
    .hf-open:focus-visible, .hf-b:focus-visible {
        outline: 1px solid rgba(232, 169, 192, 0.75); outline-offset: 1px;
    }
    /* ARMED IS A QUESTION, NOT A DANGER STRIPE.  Calling a heist off deletes no file — it throws away an
       intent and a minute of setup — so the armed state must ask rather than warn: the heist's own pink,
       a wash instead of a fill, and italics, which is how a word reads as being SAID to you.  A red block
       here would be a lie about the stakes, and the cell has a real 🗑 elsewhere that would then have
       nothing louder left to be.
       Nothing pins the width: arming grows the button LEFTWARDS (it is the last item in a right-aligned
       group), so the pointer that armed it is still over the button it must press again. */
    .hf-x.armed {
        border-color: rgba(232, 169, 192, 0.55); background: rgba(232, 169, 192, 0.13);
        color: #f0c4d5; font-style: italic; letter-spacing: 0.01em;
    }
</style>
