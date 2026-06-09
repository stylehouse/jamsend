<script lang="ts">
    // LibraryRun.svelte — reactive Library UI.
    //
    // Mounted by Otro via H/{watched:UIs}/{UI:'Library'}.
    // Receives H (the root Mundo house).
    //
    // Shows each %Book under Li = H.ave/Library as a bubble.
    // Bubble size = relative rank by a recency-weighted beliefs-mutex time,
    //   folding each %sample under book/TimeSpool/TimeTotal,'beliefs'
    //   newest-first with a geometric weight,
    //   so one very-recent run outweighs many semi-recent ones.
    // Sizes stay relative to each other, so the pile reads the same
    //   regardless of absolute timings, across sessions.
    //
    // Mung errors are shown as red banners at the top — fatal, user must fix code.
    // < more reactive UI - last run etc values don't update
    // < mode where it's a test runner listening for pushes

    import type { House }   from "$lib/O/Housing.svelte"
    import type { TheC }    from "$lib/data/Stuff.svelte"
    import { depeel, peel } from "$lib/Y.svelte"

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
    let isActive = (book) => book.sc.Book == activeBook

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

    // ── recency-weighted rank sizing ──────────────────────────────────────
    // The pile sorts by book_rank_score, descending,
    //   then maps each book's rank to a tier,
    //   so all four sizes stay filled regardless of absolute timings.
    // The score reads every %sample under book/TimeSpool/TimeTotal,'beliefs',
    //   spooled each run by auto_sync_story_stats -> spool_time_sample,
    //   and folds them newest-first with a geometric recency weight:
    //     weight_i = DECAY^i,   i:0 the newest
    //     score    = sum(weight_i * sample_i) over sum(weight_i)
    // DECAY below 0.5 makes the newest single sample outweigh all the older
    //   ones combined, so one very-recent activation ranks a book above
    //   another book carrying many semi-recent ones.
    // Books with no %sample score -1, sit at the end, and share 'sm'.
    const TIERS = ['xl', 'lg', 'md', 'sm'] as const
    type Tier = typeof TIERS[number]
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

    let ranked_books = $derived.by(() => {
        const bs = [...books] as TheC[]
        bs.sort((a, b) => book_rank_score(b) - book_rank_score(a))
        const n = bs.length
        return bs.map((book, i) => {
            // quarter-based: top 25% → xl, next → lg, next → md, rest → sm
            const tier_i = n <= 1 ? 0 : Math.min(3, Math.floor((i / n) * 4))
            return { book, tier: TIERS[tier_i] as Tier }
        })
    })

    // ── human-readable age ────────────────────────────────────────────────
    const NOW_S = Date.now() / 1000
    const HR    = 3600
    const DAY   = HR * 24

    function fmt_age(book: TheC): string {
        const t = book.sc.last_run_ms as number | null | undefined
        if (!t) return 'never'
        const age = NOW_S - t
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
        <!-- flex-wrap pile: books size themselves by relative rank -->
        <div class="lr-pile">
            {#each ranked_books as { book, tier } (book.sc.Book)}
                {@const active = isActive(book)}
                <div
                    class="lr-book tier-{tier}"
                    class:lr-active={active}
                    title={book.sc.Book}
                >
                    <div class="lr-book-top">
                        <span class="lr-name">{book.sc.Book}</span>
                        <button
                            class="lr-remove"
                            onclick={() => do_remove_book(book)}
                            title="remove">×</button>
                    </div>

                    <!-- age + ok% always shown; timing only if we have samples -->
                    <div class="lr-stats">
                        <span class="lr-age">{fmt_age(book)}</span>
                        {#if book.sc.ok_pct != null}
                            <span class="lr-pct">{fmt_pct(book.sc.ok_pct)}</span>
                        {/if}
                        {#if book_sample_count(book)}
                            <span class="lr-timing" title="{book_sample_count(book)} samples">
                                ⏱{fmt_avg(book)}
                            </span>
                        {/if}
                    </div>

                    <!-- extra sc — click to edit, hidden when empty -->
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

                    <button
                        class="lr-activate {active ? 'is-active' : 'is-idle'}"
                        onclick={() => activate(book)}
                    >{active ? '▶ active' : 'activate'}</button>
                </div>
            {/each}
        </div>
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

    /* ── bubble pile ─────────────────────────────────────────────────────── */
    /* flex-wrap lets the bigger cards naturally crowd out smaller ones */
    .lr-pile {
        display: flex;
        flex-wrap: wrap;
        gap: 0.4rem;
        align-items: flex-start;
    }

    .lr-book {
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
        background: #1a1a1a;
        border: 1px solid #333;
        border-radius: 5px;
        padding: 0.35rem 0.45rem;
        transition: border-color 0.15s, background 0.15s;
    }
    .lr-book:hover { border-color: #555; background: #1f1f1f; }
    .lr-book.lr-active {
        border-color: #3a7a3a;
        background: #111e11;
    }

    /* ── relative rank tiers ─────────────────────────────────────────────── */
    /* font-size carries the size; min-width keeps the card readable at each tier */
    .tier-xl { font-size: 1.35rem; min-width: 170px; }
    .tier-lg { font-size: 1.00rem; min-width: 130px; }
    .tier-md { font-size: 0.78rem; min-width: 96px;  }
    .tier-sm { font-size: 0.65rem; min-width: 72px;  }

    /* ── internals ───────────────────────────────────────────────────────── */
    .lr-book-top {
        display: flex;
        align-items: flex-start;
        gap: 0.25rem;
    }
    .lr-name {
        font-weight: 600;
        color: #ddd;
        flex: 1;
        word-break: break-word;
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
        flex-shrink: 0;
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

    .lr-activate {
        margin-top: 0.25rem;
        font-size: 0.72em;
        padding: 0.12rem 0.35rem;
        border-radius: 3px;
        cursor: pointer;
        border: 1px solid #555;
        background: #222;
        color: #aaa;
        align-self: flex-start;
    }
    .lr-activate.is-active { background: #1a3a1a; border-color: #4a8; color: #8d8; }
    .lr-activate.is-idle   { background: #222;    border-color: #555; color: #aaa; }
    .lr-activate:hover     { filter: brightness(1.3); }

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
