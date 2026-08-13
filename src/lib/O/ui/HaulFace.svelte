<script lang="ts">
    // HaulFace — WHAT YOU HEISTED (the owner 2026-08-13, ruling on whether to build it: *"yeah build
    //  something aye"*).  The list of albums that have actually landed in your collection, newest first.
    //
    // WHERE THE DATA COMES FROM, AND WHY THERE IS NO SECOND LEDGER.  Heist_todo's vocabulary table
    //  reserves `%Haul` for "the What Heisted ledger" and states *"The ledger is not built yet"* — which
    //   is stale.  The newlyadded log has recorded every landed file durably for weeks (`of` the path,
    //    `dir` the folder, `at` when it first landed, `feeling` its probation), and
    //     `Heist_newlyadded_grouped` already folds it per ALBUM, which is the unit this list wants.  What
    //      was missing was a surface, not a store.  `Heist_haul_look` mirrors that ledger onto a dontSnap
    //       `%Hauls` bag on a slow beat; this face reads the bag.  Two stores for one fact would be the
    //        "there's only one of anything" mistake the project keeps having to un-make.
    //
    // WHAT IT CANNOT SAY: who gave it to you.  The newlyadded log deliberately never records a source
    //  (its own header states the rule; the owner restated it 2026-08-11 — *"just the destination
    //   directory and when, not who it came from"*).  A blank where "from S" would go is a RULING.
    //
    // Props { n, H } — `n` is the %Hauls bag.  Reads off .sc, so no work happens in the render: the disk
    //  read is Heist_keep_beat's, 20s apart.  A slow local tick keeps "2h ago" honest between bumps, the
    //   HeistFace/UptimeFace idiom — H.version can go quiet for minutes on a settled tab.
    let { n, H } = $props()

    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 30000); return () => clearInterval(iv) })

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
            fresh: String(r.sc.feeling || '') === 'fresh',
        }))
        let tracks = 0
        for (const a of albums) tracks += a.tracks
        // TODAY is the number worth leading with: a list that only ever grows stops being news, and the
        //  one question you come back to this cell with is "did the ones I left running land?".
        const dayAgo = Math.floor(Date.now() / 1000) - 86400
        const today = albums.filter((a) => a.at >= dayAgo)
        return { albums, tracks, today: today.length, todayTracks: today.reduce((s, a) => s + a.tracks, 0) }
    })
</script>

<div class="hf">
    <div class="hf-head">
        <span class="hf-badge">✓</span>
        <span class="hf-mk">Haul{#if face.albums.length}<span class="hf-mkv">:{face.albums.length}</span>{/if}</span>
        <span class="hf-sub">
            {#if face.today}{face.todayTracks} track{face.todayTracks === 1 ? '' : 's'} today{:else if face.tracks}{face.tracks} track{face.tracks === 1 ? '' : 's'} kept{:else}nothing yet{/if}
        </span>
    </div>

    {#if !face.albums.length}
        <!-- an empty list still says what it IS, so the cell is never a mystery blank -->
        <div class="hf-empty">music you keep off a friend's radio lands here</div>
    {:else}
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
            {#if face.albums.length > 12}
                <div class="hf-more">…and {face.albums.length - 12} more</div>
            {/if}
        </div>
    {/if}
</div>

<style>
    .hf {
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
    .hf-name { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    /* the folder ABOVE the album is dimmer — it is context (the artist), not the thing itself */
    .hf-above { color: rgba(150, 170, 200, 0.55); }
    .hf-when { font-size: 9px; color: rgba(150, 170, 200, 0.6); white-space: nowrap; }
    /* still on probation — it landed but you have not said whether you want it.  Quiet: this is a
       tint, not an alarm; the probation verdict UI is a separate thread the owner has parked. */
    .hf-row.fresh .hf-n { color: #6fd08a; }
    .hf-more { font-size: 9px; color: rgba(150, 170, 200, 0.5); padding-left: 2.2rem; }
</style>
