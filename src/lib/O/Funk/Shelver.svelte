<script module lang="ts">
    import type { TheC } from "$lib/data/Stuff.svelte"

    const STORY_DIR = "wormhole/Story"   // every subdir here is a Book (a Story toc lives inside)
    const MISC      = "Misc"             // the catch-all shelf for a Book that prefixes no existing What

    // shelver_run — the Shelver kind's BEHAVIOUR, pumped centrally each tick while Credence is open.
    //   a GhostList-twin: GhostList walks src/Ghost into a file index; the Shelver walks
    //    wormhole/Story into the Credence board, auto-filing any Book that isn't on it yet.
    //   climbs to the House that owns LiesStore_listing (the IO pump lives on w:Lies, not here),
    //    then hands off to the async walk — fire-and-forget, like every other pumped run.
    export function shelver_run(host: TheC, funk: TheC, ww: TheC): void {
        let H: any = ww
        while (H && typeof H.LiesStore_listing !== "function") H = H.c?.up
        if (H) void shelver_walk(H, host, funk, ww)
    }

    // shelver_walk — list wormhole/Story, then file each unknown Book onto host (the Credence Waft).
    //   throttled by funk.c.walked_at (off-snap: a session throttle, no business in the snap).
    //   the listing is a stable req (oai by rw_dir): an unfinished one just means "come back next
    //    tick" — its ttlilt re-pumps us — so we return without stamping walked_at and retry.
    async function shelver_walk(H: any, host: TheC, funk: TheC, ww: TheC): Promise<void> {
        const now      = Date.now()
        const interval = Number(funk.sc.interval_ms ?? 300000)   // a Book appears rarely → a 5-min sweep; the chip's a manual rescan
        if (funk.c.walked_at && now - Number(funk.c.walked_at) < interval) return

        const lreq = await H.LiesStore_listing(ww, STORY_DIR)
        if (!lreq.sc.finished) return
        const reply = lreq.sc.reply as { entries?: { name: string, is_dir: boolean }[] } | undefined
        const books = (reply?.entries ?? []).filter(e => e.is_dir).map(e => e.name)

        // every Book already on the board, ANYWHERE — a hand-placed What:Toy cell counts, so we leave it.
        const on_board = new Set<string>()
        const scan = (c: TheC) => { for (const k of c.o() as TheC[]) {
            if (k.sc.Funkcion === "Storying" && k.sc.of_Book) on_board.add(k.sc.of_Book as string)
            scan(k) } }
        scan(host)
        // the shelves we file BY PREFIX = the existing What:<X> groups (Misc stays the fallback, never a target).
        const shelves = (host.o({ What: 1 }) as TheC[]).map(s => s.sc.What as string).filter(Boolean)
        // the ledger of Books THIS Shelver filed before — so a Book the human then deleted from the
        //  board never boomerangs back.  Persisted as %shelved children (the only snap footprint).
        const filed = new Set((funk.o({ shelved: 1 }) as TheC[]).map(s => s.sc.shelved as string))

        const plan = shelver_plan(books, on_board, shelves, filed)
        for (const { book, shelf } of plan) {
            const fresh = !host.oa({ What: shelf })
            // the catch-all is born %inline — a crowded bucket reads best as flowed chips, not a tall column
            //  (the prefix shelves are human-curated; Waft_dip's off-snap hint inlines them already).
            const what  = host.oai({ What: shelf }, fresh && shelf === MISC ? { inline: 1 } : {})
            if (fresh) what.i({ Funkcion: "StoryTimes" })   // a shelf the Shelver mints gets its own run-all station
            what.i({ Funkcion: "Storying", of_Book: book })
            funk.i({ shelved: book })                       // remember we filed it
        }
        funk.c.walked_at  = now
        funk.c.last_count = books.length
        funk.bump_version()                              // refresh the inline tally (off-snap count)
        if (plan.length) host.bump_version()             // a real filing → watch_c saves the toc + binds the new cells
    }

    // shelver_plan — the PURE filing decision, factored out so it tests headless (no House, no IO).
    //   books     — every Book dir under wormhole/Story.
    //   on_board  — Books already represented anywhere on the board (incl. a manual Toy placement).
    //   shelves   — existing What:<X> names; a Book files under the LONGEST one that prefixes its name.
    //   filed     — the ledger; a removed-by-hand Book stays here, so we never re-file it.
    //   yields one {book, shelf} per Book new to the board AND never auto-filed; shelf = best prefix | Misc.
    export function shelver_plan(
        books: string[], on_board: Set<string>, shelves: string[], filed: Set<string>,
    ): { book: string, shelf: string }[] {
        const out: { book: string, shelf: string }[] = []
        for (const book of [...books].sort()) {
            if (on_board.has(book) || filed.has(book)) continue
            const hit = shelves
                .filter(x => x && x !== MISC && book.startsWith(x))
                .sort((a, b) => b.length - a.length)[0]
            out.push({ book, shelf: hit ?? MISC })
        }
        return out
    }
</script>

<script lang="ts">
    // Shelver.svelte — the Shelver Funkcion KIND's face: a one-line ledger of the auto-filer.
    //   the work is shelver_run above (pumped centrally); this only reports and offers a manual rescan.
    //    counts are off-snap (funk.c), read through funk.version like every pumped cell.
    import type { House } from "$lib/O/Housing.svelte"

    let { funk, raw = false }: { H?: House, w?: TheC, funk: TheC, raw?: boolean } = $props()

    let count = $derived((() => { void funk.version; return Number(funk.c.last_count ?? 0) })())
    let filed = $derived((() => { void funk.version; return (funk.o({ shelved: 1 }) as TheC[]).length })())

    // rescan: drop the throttle so the next pump tick walks at once (the central pump ticks every beat).
    function rescan() { funk.c.walked_at = 0; funk.bump_version() }
</script>

{#if raw}
    <div class="sh-raw">Funkcion:Shelver — {filed} auto-filed</div>
{:else}
    <button class="sh" onclick={rescan}
        title="Shelver · files new wormhole/Story Books onto this board by name-prefix (else What:Misc), leaving hand-placed cells be · click to rescan now">
        <span class="sh-ico">📚</span>
        <span class="sh-name">Shelver</span>
        <span class="sh-sum">{count} books · {filed} filed</span>
    </button>
{/if}

<style>
    .sh {
        display: inline-flex; align-items: center; gap: 0.35rem; margin: 0.15rem 0;
        padding: 0.2rem 0.6rem; border-radius: 5px; cursor: pointer;
        border: 1px solid #2c3450; background: #121624;
        font-family: monospace; font-size: 0.76rem; color: #9aa6cc;
        transition: filter 0.1s, border-color 0.12s;
    }
    .sh:hover { filter: brightness(1.3); border-color: #44609e; }
    .sh-ico  { font-size: 0.85rem; line-height: 1; }
    .sh-name { color: #c4ccea; }
    .sh-sum  { font-variant-numeric: tabular-nums; color: #889; }
    .sh-raw  { font-family: monospace; font-size: 0.72rem; color: #6a7a9a; padding: 0.1rem 0.2rem; }
</style>
