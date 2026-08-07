<script lang="ts">
    // HeistSetup — the ⇊ "keep what you're hearing" chooser, whooshed fullscreen (the human 2026-07-28:
    //  "I want the entire UI whooshed into the Heist setup UI, like we used to have with %places — to find
    //   name collisions, and decide on a genre to keep|change we might file it under").  It is a face-only
    //    Lens:Panel Funk (registered in Funk/kinds.ts, hosted by the global Panel Lens in BigSoundland) — the
    //     display-neutral fullscreen route, NOT a Vyto glass node (the display refactor's zone).
    //
    //  It reads the ACTIVE %Keep (Radio_keep minted it under Ra_home_shop) and shows the folder the source
    //   described back: the husks tagged rummage:<seed> in the friend mirror (Heist_rummage_answer landed
    //    them).  Per artist you pick a GENRE (the top folder to file under, default = the source's own tag);
    //     per track a keep/skip tick, with a collision badge when your crate already holds it.  Commit writes
    //      %Pick children + flips the keep to committing; the beat driver (Heist_keep_pull) pulls the chosen
    //       tracks and lands them under music/<genre>/<file> — straight into the collection the radio digs.
    import FaceSucker from "$lib/p2p/ui/FaceSucker.svelte"
    import { onMount } from "svelte"
    import type { House } from "$lib/O/Housing.svelte"

    // mounted as a Lens panel (LensHost) — the extra panel props (lens/funk/w) land in rest, ignored: the
    //  chooser self-locates the active %Keep (there is at most one heist mid-flight), so no cell threading.
    let { H, ...rest }: { H: House } & Record<string, any> = $props()
    void rest

    const A = H as any

    // the folder-describe round-trip and the pull both land off the beat (a C-tree mutation on the tick),
    //  which a bare H.version derive can miss between bumps — so poll a slow clock beside it (IdHatch idiom).
    let poll = $state(0)
    onMount(() => { const iv = setInterval(() => poll++, 400); return () => clearInterval(iv) })

    // the human's edits — kept out of the model until commit.  Effective value falls back to the husk's own
    //  default (source genre) / "keep unless already held", so an untouched row still commits sensibly.
    let genres = $state<Record<string, string>>({})       // artist → chosen genre folder
    let keepFlags = $state<Record<string, boolean>>({})    // track id → keep?

    function rw() { return A?.top_House?.()?.c?.radio_w }
    function safe(s: string) { return String(s ?? '').replace(/[\/\x00]/g, '-') }

    let view = $derived.by(() => {
        void H?.version; void poll
        const w = rw()
        if (!w) return null
        const me = A?.Radio_pub?.(w) || 'me'
        const shop = A?.Ra_home_shop?.(w, me)
        if (!shop) return null
        // the active keep: the furthest-along one (a chooser open on 'choosing' beats a stale 'done').
        const rank: Record<string, number> = { choosing: 4, committing: 3, done: 2, asking: 1, wanted: 0 }
        let keep: any = null
        for (const k of shop.o({ Haul: 1 })) {
            if (!keep || (rank[k.sc.state] ?? -1) > (rank[keep.sc.state] ?? -1)) keep = k
        }
        if (!keep) return null
        const them = String(keep.sc.pub)
        const seed = String(keep.sc.seed)
        const ownlib = A?.Ra_home_self?.(w, me)
        const mir = A?.Ra_home_them?.(w, them)
        // the folder husks tagged for this seed — the PAGED-aware read (a friend mirror is a Mag, so a flat
        //  o() misses records that merged onto a page); fall back to flat if the helper isn't mixed on.
        const allHusks = (mir && A?.Heist_rummage_recs) ? A.Heist_rummage_recs(mir, seed) : (mir ? mir.o({ Record: 1, rummage: seed }) : [])
        // EXCLUDE the seed itself: you're streaming it live, and pulling it mid-stream would fight the radio
        //  for the same mirror record + want-cursor. Keep the REST of its folder; the seed you already hear.
        const husks = allHusks.filter((r: any) => String(r.sc.id) !== seed)
        const seedDropped = allHusks.length !== husks.length
        const picks = keep.o({ Pick: 1 })
        const landedIds = new Set(picks.filter((p: any) => p.sc.landed).map((p: any) => String(p.sc.id)))
        const pickedIds = new Set(picks.map((p: any) => String(p.sc.id)))   // the committed choice (model truth, survives remount)
        const rows = husks.map((r: any) => {
            const path = String(r.sc.path || '')
            const file = path.split('/').filter(Boolean).pop() || (String(r.sc.title || r.sc.id) + (r.sc.ext ? '.' + r.sc.ext : ''))
            return {
                id: String(r.sc.id),
                title: String(r.sc.title || '(untitled)'),
                artist: String(r.sc.artist || 'Unknown'),
                genre0: String(r.sc.genre || ''),
                file,
                // THE PATH IT ACTUALLY LANDS AT (Heist_cp_path): a heist is a copy, so the source's own
                //  subdirs AND filename survive — showing only the basename claimed the album folders
                //   get flattened away, which they don't.  Same '..'/'.' strip as the ghost's.
                cp: path.split('/').filter((p: string) => p && p !== '.' && p !== '..').join('/')
                    || (String(r.sc.id) + (r.sc.ext ? '.' + r.sc.ext : '')),
                held: !!(ownlib && A?.Heist_held?.(ownlib, r.sc.artist, r.sc.title)),
                landed: landedIds.has(String(r.sc.id)),
                picked: pickedIds.has(String(r.sc.id)),
            }
        })
        rows.sort((a: any, b: any) => (a.artist + a.title).localeCompare(b.artist + b.title))
        // the committed picks straight from the MODEL — so the committing/done list shows ✓ ticks even after
        //  Heist_land removes a landed husk from the mirror (the review's cosmetic finding: rows vanished).
        const pickRows = picks.map((p: any) => ({
            id: String(p.sc.id),
            artist: String(p.sc.artist || 'Unknown'),
            title: String(p.sc.title || p.sc.id),
            landed: !!p.sc.landed,
        })).sort((a: any, b: any) => (a.artist + a.title).localeCompare(b.artist + b.title))
        return {
            keep, state: String(keep.sc.state || 'wanted'), them,
            themName: String(keep.sc.from_name || 'a friend'),
            seedTitle: String(keep.sc.Haul || 'this track'),
            seed, rows, pickRows, seedDropped,
            asks: +(keep.sc.asks || 0),
            landed_n: +(keep.sc.landed_n || 0), total_n: +(keep.sc.total_n || 0),
        }
    })

    // the distinct genres already in the folder + a few staples — a datalist so a genre is one keystroke.
    let genreOptions = $derived.by(() => {
        // no 'Unfiled' staple: picking it would create a folder literally called Unfiled.  Leaving the
        //  field empty is the "file it nowhere, keep their folders" choice, which is also the default.
        const s = new Set<string>(['Ambient', 'Jazz', 'Electronic', 'Rock', 'Hip Hop', 'Folk', 'Classical'])
        for (const r of (view?.rows ?? [])) if (r.genre0) s.add(r.genre0)
        for (const g of Object.values(genres)) if (g) s.add(g)
        return [...s]
    })

    // group rows by artist so the genre picker is per-artist (Heist files per artist: [{artist,genre}]).
    let byArtist = $derived.by(() => {
        const m = new Map<string, any[]>()
        for (const r of (view?.rows ?? [])) { if (!m.has(r.artist)) m.set(r.artist, []); m.get(r.artist)!.push(r) }
        return [...m.entries()].map(([artist, tracks]) => ({ artist, tracks }))
    })

    function genreFor(artist: string, fallback: string): string {
        return genres[artist] !== undefined ? genres[artist] : fallback
    }
    function keepOf(r: any): boolean {
        return keepFlags[r.id] !== undefined ? keepFlags[r.id] : !r.held
    }
    // the tally in the commit button + a live "→ N new, M already held" read.
    let tally = $derived.by(() => {
        void poll
        let keep = 0, held = 0
        for (const r of (view?.rows ?? [])) { if (keepOf(r)) keep++; if (r.held) held++ }
        return { keep, held }
    })

    function setGenre(artist: string, val: string) { genres = { ...genres, [artist]: val } }
    function toggleKeep(r: any) { keepFlags = { ...keepFlags, [r.id]: !keepOf(r) } }

    function commit() {
        const v = view
        if (!v) return
        const choices = v.rows.map((r) => ({
            id: r.id, artist: r.artist, title: r.title,
            // '' when the human pinned nothing — NOT 'Unfiled', which would be committed as a real
            //  category and land the tracks in a folder of that name (see Heist_keep_commit).
            genre: safe(genreFor(r.artist, r.genre0)),
            keep: keepOf(r),
        }))
        A?.post_do?.(() => A?.Heist_keep_commit?.(rw(), v.keep, choices), { see: 'heist_commit' })
    }
    function cancel() {
        const v = view
        A?.post_do?.(() => { if (v?.keep) A?.Heist_keep_cancel?.(rw(), v.keep) }, { see: 'heist_cancel' })
        close()
    }
    function close() { A?.Lies_lens_dismiss?.('Panel', 'HeistSetup') }
</script>

<FaceSucker altitude={88} fullscreen={true}>
    {#snippet content()}
        <div class="hs">
            {#if !view}
                <h2>⇊ Keep</h2>
                <p class="muted">starting… (click ⇊ on a track that's playing from a friend)</p>
                <div class="row"><button onclick={close}>Close</button></div>
            {:else}
                <h2>⇊ Keep the folder <span class="frm">from {view.themName}</span></h2>

                {#if view.state === 'wanted' || view.state === 'asking'}
                    <p class="muted spin">🔎 asking {view.themName} what else is around “{view.seedTitle}”…{#if view.asks > 1} <span class="dim">· asked {view.asks}×</span>{/if}</p>
                    <p class="hint">only the source can resolve the folder — a radio track carries just its id, so this is a live round-trip. It'll fill in a moment.</p>
                    <div class="row"><button onclick={close}>Close</button><button class="ghost" onclick={cancel}>Cancel keep</button></div>

                {:else if view.state === 'choosing'}
                    <p class="muted">Pick what to pull into your collection. Choose a genre to file each artist under (change it if you like), untick anything you don't want.</p>
                    {#if view.seedDropped}<p class="hint">“{view.seedTitle}” streams live from {view.themName} — here's the rest of its folder to keep.</p>{/if}
                    {#if view.rows.length === 0}
                        <p class="hint">the source's folder held only the track you're playing (or the folder is gone) — nothing else to grab.</p>
                    {/if}
                    <div class="groups">
                        {#each byArtist as g (g.artist)}
                            <div class="grp">
                                <div class="grp-h">
                                    <span class="artist">{g.artist}</span>
                                    <label class="genre">file under
                                        <input list="hs-genres" value={genreFor(g.artist, g.tracks[0].genre0)}
                                               oninput={(e) => setGenre(g.artist, (e.target as HTMLInputElement).value)} />
                                    </label>
                                </div>
                                {#each g.tracks as r (r.id)}
                                    <label class="trk" class:held={r.held} class:skip={!keepOf(r)}>
                                        <input type="checkbox" checked={keepOf(r)} onchange={() => toggleKeep(r)} />
                                        <span class="ttl">{r.title}</span>
                                        {#if r.held}<span class="badge held">✓ already in your crate</span>{/if}
                                        <!-- no invented `music/` root and no `Unfiled` folder: an unpinned
                                             artist prepends NOTHING (Heist_filing_for), and the source's
                                             own relative path rides underneath unrenamed. -->
                                        <span class="dest">→ {safe(genreFor(g.artist, r.genre0)) ? safe(genreFor(g.artist, r.genre0)) + '/' : ''}{r.cp}</span>
                                    </label>
                                {/each}
                            </div>
                        {/each}
                    </div>
                    <datalist id="hs-genres">{#each genreOptions as o}<option value={o}></option>{/each}</datalist>
                    <div class="row">
                        <button class="go" disabled={tally.keep === 0} onclick={commit}>
                            Keep {tally.keep} {tally.keep === 1 ? 'track' : 'tracks'} into /music
                        </button>
                        <span class="note">{#if tally.held > 0}{tally.held} already held (unticked by default){/if}</span>
                        <span class="spacer"></span>
                        <button class="ghost" onclick={cancel}>Cancel</button>
                    </div>

                {:else if view.state === 'committing'}
                    <p class="muted">Pulling into your collection…</p>
                    <div class="bar"><div class="fill" style="width:{view.total_n ? Math.round(100 * view.landed_n / view.total_n) : 0}%"></div></div>
                    <p class="hint">{view.landed_n} / {view.total_n} landed — each file is byte-verified against the source before it's written. You can close this; it keeps going in the background.</p>
                    <div class="groups small">
                        {#each view.pickRows as r (r.id)}
                            <div class="trk"><span class="tick">{r.landed ? '✓' : '…'}</span><span class="ttl">{r.artist} — {r.title}</span></div>
                        {/each}
                    </div>
                    <div class="row"><button onclick={close}>Close (keeps running)</button><button class="ghost" onclick={cancel}>Abandon</button></div>

                {:else}
                    <p class="done">✓ Kept {view.landed_n} {view.landed_n === 1 ? 'track' : 'tracks'} into your collection.</p>
                    <p class="hint">they're filed under their genres in /music and will turn up in the radio as it re-digs.</p>
                    <div class="row"><button class="go" onclick={cancel}>Done</button></div>
                {/if}
            {/if}
        </div>
    {/snippet}
</FaceSucker>

<style>
    .hs { max-width: 46rem; display: flex; flex-direction: column; gap: 0.7rem; color: #e8dcc0; font-family: ui-rounded, 'Trebuchet MS', sans-serif; }
    .hs h2 { margin: 0; font-size: 1.2rem; }
    .frm { opacity: 0.7; font-weight: 400; font-size: 0.95rem; }
    .muted { opacity: 0.8; margin: 0; }
    .hint { font-size: 0.78rem; opacity: 0.6; margin: 0; }
    .dim { opacity: 0.55; font-size: 0.85em; }
    .spin { color: #d9a026; }
    .groups { display: flex; flex-direction: column; gap: 0.6rem; max-height: 56vh; overflow-y: auto; padding-right: 0.3rem; }
    .groups.small { max-height: 40vh; }
    .grp { border: 1px solid #2a3f48; border-radius: 6px; padding: 0.5rem 0.6rem; background: #0e1c22; }
    .grp-h { display: flex; align-items: center; justify-content: space-between; gap: 0.6rem; margin-bottom: 0.35rem; flex-wrap: wrap; }
    .artist { font-weight: 700; }
    .genre { font-size: 0.8rem; opacity: 0.85; display: flex; align-items: center; gap: 0.35rem; }
    .genre input { background: #061318; color: #ffd869; border: 1px solid #d9a026; border-radius: 4px; padding: 0.15rem 0.4rem; font-size: 0.8rem; width: 11rem; }
    .trk { display: flex; align-items: center; gap: 0.5rem; font-size: 0.85rem; padding: 0.15rem 0; }
    .trk.skip { opacity: 0.4; }
    .trk .ttl { flex: 1 1 auto; overflow-wrap: anywhere; }
    .trk .dest { font-size: 0.7rem; opacity: 0.5; font-family: monospace; white-space: nowrap; }
    .badge.held { font-size: 0.7rem; color: #57c777; border: 1px solid #2e6b3a; border-radius: 3px; padding: 0 0.3rem; }
    .tick { width: 1.2rem; text-align: center; }
    .bar { height: 5px; background: #1a2f38; border-radius: 3px; overflow: hidden; }
    .fill { height: 100%; background: #d9a026; transition: width 0.4s linear; }
    .done { color: #57c777; font-weight: 700; margin: 0; }
    .row { display: flex; align-items: center; gap: 0.6rem; flex-wrap: wrap; margin-top: 0.3rem; }
    .row .spacer { flex: 1 1 auto; }
    .row .note { font-size: 0.75rem; opacity: 0.6; }
    button { padding: 0.35rem 0.8rem; border: 1px solid #d9a026; border-radius: 5px; background: #1a2f38; color: #e8dcc0; cursor: pointer; font-size: 0.85rem; }
    button:hover { background: #d9a026; color: #04202a; }
    button.go { background: #2e6b3a; border-color: #57c777; color: #eafff0; font-weight: 700; }
    button.go:hover { background: #57c777; color: #04202a; }
    button.ghost { background: transparent; border-color: #3a5560; opacity: 0.8; }
    button:disabled { opacity: 0.35; cursor: default; }
</style>
