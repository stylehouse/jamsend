<script lang="ts">
    // LibraryRun.svelte — reactive Library UI: a StemHive of the books.
    //
    // Mounted by Otro via H/{watched:UIs}/{UI:'Library'}.  Receives H (root Mundo).
    //
    // Each %Book under Li = H.ave/Library is one hive button, so the family of
    //   names reads at a glance — LeafJuggle|LeafFarm cluster on their shared stem
    //   (StemHive does the clustering; it knows nothing of books).
    // Two heat channels ride StemHive's per-item `styles` map, so StemHive needs
    //   no change — each book's id maps to one inline-style string carrying both:
    //   glow  — DocMinimap's amber→pink halo, brightness by how recently the book
    //           was lit (last_run_ms, exponential decay over GLOW_HALFLIFE_S).  The
    //           active book's last_run_ms is restamped every Auto tick, so it stays
    //           brightest; the rest fade.  Hue warms toward pink as ok_pct falls,
    //           so a breaking book glows hot.
    //   size  — font-size by relative rank on book_rank_score (the recency-weighted
    //           beliefs-mutex time), so a book that's been heavy across recent runs
    //           reads bigger.  Same score the old bubble-pile sized by.
    // Clicking a book activates it (e:activateBook).  The active book gets a detail
    //   strip below the hive — age, ok%, timing, the editable peel field, remove.
    //
    // Mung errors show as a red banner — fatal, user must fix code.
    // < a now_s tick (1s) re-derives the glow so it fades live between Auto bumps.

    import type { House }   from "$lib/O/Housing.svelte"
    import type { TheC }    from "$lib/data/Stuff.svelte"
    import { depeel, peel } from "$lib/Y.svelte"
    import StemHive         from "./StemHive.svelte"
    import { onDestroy }    from "svelte"

    let { H }: { H: House } = $props()

    // ── reactive Library particle from H.ave ─────────────────────────────
    // ob() tracks Li.version so these re-derive when Li.bump_version() fires
    // in Atime (e.g. after book.sc.active is mutated). o() would not track it.
    let Li = $derived(H.ave.ob({Library:1})[0])
    let books       = $derived(Li?.ob({Book:1})      || [])
    let mung_errors = $derived(Li?.ob({mung_error:1}) || [])
    // activeBook lives at the ave level (w.c.ave.roai({activeBook:1},...)),
    // not inside Li — so query H.ave directly.
    let activeBook  = $derived(H.ave.ob({activeBook:1})[0]?.sc.Book ?? null)
    let active_book = $derived((books as TheC[]).find(b => b.sc.Book === activeBook))

    // wall-clock seconds, ticked so the recency glow + age fade live between the
    //   Library's own version bumps (which only fire on a pct/avg change).
    let now_s = $state(Date.now() / 1000)
    const tick = setInterval(() => { now_s = Date.now() / 1000 }, 1000)
    onDestroy(() => clearInterval(tick))

    // ── add book ──────────────────────────────────────────────────────────
    let add_book_text = $state('')
    let adding_book   = $state(false)

    function do_add_book() {
        const name = add_book_text.trim()
        if (!name || !Li) return
        // idempotent — don't double-add
        if ((Li as TheC).o({ Book: name }).length) return
        ;(Li as TheC).i({ Book: name })
        ;(Li as TheC).bump_version()
        add_book_text = ''
        adding_book   = false
    }

    function do_remove_book(book: TheC) {
        if (!Li) return
        ;(Li as TheC).drop(book)
        ;(Li as TheC).bump_version()
    }

    // ── editable peel field per book ─────────────────────────────────────
    // editing[bookName] = current text in the input (or null = not editing)
    let editing: Record<string, string | null> = $state({})

    function extra_sc(book: TheC): Record<string, any> {
        const skip = new Set(['Book', 'ok_pct', 'last_run_ms', 'active', 'done',
                              'last_pct_change', 'time_avg', 'time_samples'])
        const out: Record<string, any> = {}
        for (const [k, v] of Object.entries(book.sc)) {
            if (!skip.has(k)) out[k] = v
        }
        return out
    }

    function start_edit(book: TheC) {
        editing[book.sc.Book] = depeel(extra_sc(book))
    }

    function commit_edit(book: TheC) {
        const raw = editing[book.sc.Book]
        if (raw == null) return
        editing[book.sc.Book] = null
        try {
            const parsed = peel(raw)
            // merge into book.sc (keep identity keys)
            for (const k of Object.keys(extra_sc(book))) {
                delete book.sc[k]
            }
            Object.assign(book.sc, parsed)
            ;(Li as TheC).bump_version()
        } catch (e) {
            console.warn('LibraryRun: peel failed', e)
        }
    }

    function activate(book: TheC) {
        H.i_elvisto('Auto/Auto', 'activateBook', { Book: book.sc.Book })
        // seek to Story once the new house appears — auto_reset_story already
        // sets restore_window_until, so NaviScroll will chase it when it arrives
        H.scroll_to_house?.('Story')
    }

    function reset_story() {
        H.i_elvisto('Auto/Auto', 'resetStory', {})
    }

    // ── recency-weighted rank score ───────────────────────────────────────
    // Reads every %sample under book/TimeSpool/TimeTotal,'beliefs', spooled each
    //   run by auto_sync_story_stats -> spool_time_sample, and folds them
    //   newest-first with a geometric recency weight:
    //     weight_i = DECAY^i,   i:0 the newest
    //     score    = sum(weight_i * sample_i) over sum(weight_i)
    // DECAY below 0.5 makes the newest single sample outweigh all the older ones
    //   combined, so one very-recent activation ranks a book above another book
    //   carrying many semi-recent ones.  Books with no %sample score -1.
    const DECAY = 0.45

    function book_tt(book: TheC): TheC | undefined {
        const spool = book.o({ TimeSpool: 1 })[0] as TheC | undefined
        return spool?.o({ TimeTotal: 'beliefs' })[0] as TheC | undefined
    }

    function book_samples(book: TheC): TheC[] {
        const tt = book_tt(book)
        return tt ? (tt.o({ sample: 1 }) as TheC[]) : []
    }

    // displayed ⏱ value — the honest flat mean spooled into %TimeTotal,'beliefs'
    function book_time_avg(book: TheC): number {
        return (book_tt(book)?.sc.avg as number) ?? -1
    }

    function book_sample_count(book: TheC): number {
        return book_samples(book).length
    }

    function book_rank_score(book: TheC): number {
        const samples = book_samples(book)
        if (!samples.length) return -1
        // newest first — %sample/at is wall-clock seconds when present,
        //   else fall back to stored order,
        //   where the spool evicts oldest so the last entry is newest.
        const ordered = samples.every(s => typeof s.sc.at === 'number')
            ? [...samples].sort((a, b) => (b.sc.at as number) - (a.sc.at as number))
            : [...samples].reverse()
        let vsum = 0, wsum = 0, w = 1
        for (const s of ordered) {
            const v = s.sc.sample as number
            if (typeof v !== 'number') continue
            vsum += w * v
            wsum += w
            w    *= DECAY
        }
        return wsum ? vsum / wsum : -1
    }

    // ── the two heat channels, both ridden into StemHive's `styles` map ───
    // glow brightness 0..1 — how recently this book was lit, decayed from
    //   last_run_ms over GLOW_HALFLIFE_S.  The active book's last_run_ms is
    //   restamped each Auto tick, so it sits at ~1 while it runs.
    const GLOW_HALFLIFE_S = 60
    function book_bright(book: TheC): number {
        const t = book.sc.last_run_ms as number | null | undefined
        if (!t) return 0
        const age = Math.max(0, now_s - t)
        return Math.pow(0.5, age / GLOW_HALFLIFE_S)
    }

    // warmth 0..1 — amber (passing) → pink (breaking), matching the minimap's
    //   warm hue.  ok_pct 1 → amber, 0 → pink; unknown → amber.
    function book_warm(book: TheC): number {
        const p = book.sc.ok_pct as number | null | undefined
        if (p == null) return 0
        return Math.min(1, Math.max(0, 1 - p))
    }

    // font-size by relative rank — the busiest recent book reads biggest, books
    //   with no samples sit at the floor.
    const SIZE_MIN = 10, SIZE_MAX = 22
    let rank_max = $derived.by(() => {
        let m = 0
        for (const b of books as TheC[]) m = Math.max(m, book_rank_score(b))
        return m
    })
    function book_size(book: TheC): number {
        const s = book_rank_score(book)
        if (s <= 0 || rank_max <= 0) return SIZE_MIN
        return SIZE_MIN + (s / rank_max) * (SIZE_MAX - SIZE_MIN)
    }

    // one inline-style string per book: font-size (importance) + the minimap's
    //   wide centred halo (recency·warmth).  Below 0.02 bright we skip the halo
    //   so a cold book is just sized, no glow.
    function book_style(book: TheC): string {
        const fs = `font-size:${book_size(book).toFixed(1)}px;`
        const b  = book_bright(book)
        if (b <= 0.02) return fs
        const w  = book_warm(book)
        const gg = Math.round(190 - 70 * w)
        const bb = Math.round(80 + 120 * w)
        const blur   = (b * 10 + 3).toFixed(1)
        const spread = (b * 2 + 1.5).toFixed(1)
        return `${fs}box-shadow:0 0 ${blur}px ${spread}px rgba(255,${gg},${bb},${(b * 0.85).toFixed(2)});border-radius:4px;`
    }

    let hive_items = $derived((books as TheC[]).map(b => ({
        id: b.sc.Book as string, label: b.sc.Book as string,
    })))
    let hive_pointed = $derived(new Set(activeBook ? [activeBook] : []))
    let hive_styles = $derived.by(() => {
        const m = new Map<string, string>()
        for (const b of books as TheC[]) m.set(b.sc.Book as string, book_style(b))
        return m
    })
    // everything-about-this-book on hover (native title; \n splits lines).
    let hive_tips = $derived.by(() => {
        const m = new Map<string, string>()
        for (const b of books as TheC[]) m.set(b.sc.Book as string, book_tip(b))
        return m
    })

    function book_tip(book: TheC): string {
        const lines = [book.sc.Book as string]
        if (book.sc.Book === activeBook) lines[0] += '  ▶ active'
        lines.push(`lit ${fmt_age(book)}`)
        if (book.sc.ok_pct != null)
            lines.push(`ok ${fmt_pct(book.sc.ok_pct)}${book.sc.done ? ` · ${book.sc.done} steps` : ''}`)
        const n = book_sample_count(book)
        if (n) lines.push(`⏱ ${fmt_avg(book)} · ${n} sample${n > 1 ? 's' : ''}`)
        const extra = extra_sc(book)
        if (Object.keys(extra).length) lines.push(depeel(extra))
        return lines.join('\n')
    }
    function hive_pick(id: string) {
        const book = (books as TheC[]).find(b => b.sc.Book === id)
        if (book) activate(book)
    }

    // ── human-readable age ────────────────────────────────────────────────
    const HR    = 3600
    const DAY   = HR * 24

    function fmt_age(book: TheC): string {
        const t = book.sc.last_run_ms as number | null | undefined
        if (!t) return 'never'
        const age = now_s - t
        if (age < 60)       return 'just now'
        if (age < HR)       return `${Math.floor(age / 60)}m ago`
        if (age < DAY)      return `${Math.floor(age / HR)}h ago`
        return `${Math.floor(age / DAY)}d ago`
    }

    function fmt_pct(p: number | null | undefined): string {
        if (p == null) return ''
        return Math.round(p * 100) + '%'
    }

    // time_avg is in seconds (sum_beliefs_time units)
    function fmt_avg(book: TheC): string {
        const a = book_time_avg(book)
        if (a < 0) return ''
        return a >= 1 ? `${a.toFixed(1)}s` : `${Math.round(a * 1000)}ms`
    }
</script>

<div class="library-run">
    <div class="lr-header">
        <span class="lr-title">📚 Library</span>
        {#if adding_book}
            <input
                class="lr-add-input"
                type="text"
                placeholder="BookName"
                bind:value={add_book_text}
                onkeydown={e => { if (e.key === 'Enter') do_add_book(); if (e.key === 'Escape') adding_book = false }}
            />
            <button class="lr-btn save" onclick={do_add_book}>+</button>
            <button class="lr-btn" onclick={() => adding_book = false}>×</button>
        {:else}
            <button class="lr-btn save" onclick={() => { adding_book = true; setTimeout(() => document.querySelector('.lr-add-input')?.focus(), 0) }}>+ book</button>
        {/if}
        <button class="lr-btn reset" onclick={reset_story}>↺ reset</button>
    </div>

    {#if mung_errors.length}
        <div class="lr-mung-banner">
            <strong>⛔ Mung errors — fix before saving:</strong>
            {#each mung_errors as me}
                <div class="lr-mung-msg">{me.sc.msg}</div>
            {/each}
        </div>
    {/if}

    {#if !Li}
        <div class="lr-empty">loading…</div>
    {:else}
        <!-- the hive: books clustered by name, glow=recency, size=importance -->
        <div class="lr-hive">
            <StemHive
                items={hive_items}
                pointed={hive_pointed}
                styles={hive_styles}
                tips={hive_tips}
                onpick={hive_pick}
            />
        </div>

        <!-- detail strip for whichever book is active (clicking a name activates) -->
        {#if active_book}
            {@const book = active_book as TheC}
            <div class="lr-detail">
                <div class="lr-detail-top">
                    <span class="lr-name">{book.sc.Book}</span>
                    <span class="lr-stats">
                        <span class="lr-age">{fmt_age(book)}</span>
                        {#if book.sc.ok_pct != null}
                            <span class="lr-pct">{fmt_pct(book.sc.ok_pct)}</span>
                        {/if}
                        {#if book_sample_count(book)}
                            <span class="lr-timing" title="{book_sample_count(book)} samples">
                                ⏱{fmt_avg(book)}
                            </span>
                        {/if}
                    </span>
                    <button class="lr-remove" onclick={() => do_remove_book(book)} title="remove">×</button>
                </div>

                {#if Object.keys(extra_sc(book)).length || editing[book.sc.Book] != null}
                    <div class="lr-extra">
                        {#if editing[book.sc.Book] != null}
                            <input
                                class="lr-peel-input"
                                type="text"
                                bind:value={editing[book.sc.Book]}
                                onblur={() => commit_edit(book)}
                                onkeydown={e => { if (e.key === 'Enter') commit_edit(book) }}
                            />
                        {:else}
                            <span class="lr-peel-view" onclick={() => start_edit(book)}>
                                {depeel(extra_sc(book))}
                            </span>
                        {/if}
                    </div>
                {/if}
            </div>
        {/if}
    {/if}
</div>

<style>
    .library-run {
        font-size: 0.82rem;
        padding: 0.5rem;
        border: 1px solid #444;
        border-radius: 4px;
        background: #111;
        color: #ccc;
        min-width: 300px;
    }

    /* ── header ─────────────────────────────────────────────────────────── */
    .lr-header {
        display: flex;
        align-items: center;
        gap: 0.4rem;
        margin-bottom: 0.5rem;
    }
    .lr-title { font-weight: bold; flex: 1 }

    .lr-mung-banner {
        background: #400;
        border: 1px solid #c44;
        border-radius: 3px;
        padding: 0.3rem 0.5rem;
        margin-bottom: 0.4rem;
        color: #f88;
    }
    .lr-mung-msg { font-size: 0.75rem; margin-top: 0.15rem; }

    /* ── the hive ────────────────────────────────────────────────────────── */
    /* breathing room around the buttons so the glow halos aren't clipped */
    .lr-hive { padding: 4px 2px; }

    /* ── active-book detail strip ────────────────────────────────────────── */
    .lr-detail {
        margin-top: 0.5rem;
        padding-top: 0.4rem;
        border-top: 1px solid #333;
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
    }
    .lr-detail-top {
        display: flex;
        align-items: baseline;
        gap: 0.4rem;
    }
    .lr-name {
        font-weight: 600;
        color: #ddd;
        line-height: 1.2;
    }
    .lr-remove {
        background: none;
        border: none;
        color: #555;
        cursor: pointer;
        font-size: 0.85em;
        padding: 0;
        line-height: 1;
        margin-left: auto;
    }
    .lr-remove:hover { color: #c88; }

    .lr-stats {
        display: flex;
        flex-wrap: wrap;
        gap: 0.3rem;
        align-items: baseline;
    }
    .lr-age    { color: #666; font-size: 0.80em; }
    .lr-pct    { color: #8a8; font-size: 0.80em; }
    .lr-timing { color: #78a; font-size: 0.80em; }

    .lr-extra { margin-top: 0.1rem; }
    .lr-peel-view {
        cursor: pointer;
        color: #9ab;
        font-family: monospace;
        font-size: 0.78em;
        word-break: break-all;
    }
    .lr-peel-view:hover { color: #cdf; text-decoration: underline; }
    .lr-peel-input {
        font-family: monospace;
        font-size: 0.78em;
        background: #222;
        color: #cdf;
        border: 1px solid #556;
        border-radius: 2px;
        padding: 0.1rem 0.2rem;
        width: 100%;
        box-sizing: border-box;
    }

    /* ── small shared buttons (header) ───────────────────────────────────── */
    .lr-btn {
        font-size: 0.75rem;
        padding: 0.12rem 0.35rem;
        border-radius: 3px;
        cursor: pointer;
        border: 1px solid #555;
        background: #222;
        color: #aaa;
    }
    .lr-btn.save  { border-color: #4a8; color: #8d8; }
    .lr-btn.reset { background: #2a1a1a; border-color: #844; color: #c88; }
    .lr-btn:hover { filter: brightness(1.2); }

    .lr-add-input {
        font-family: monospace;
        font-size: 0.78rem;
        background: #222;
        color: #cdf;
        border: 1px solid #556;
        border-radius: 2px;
        padding: 0.1rem 0.3rem;
        width: 110px;
    }

    .lr-empty { color: #555; font-style: italic; }
</style>
