<script lang="ts">
    // LibraryRun.svelte — reactive Library UI.
    //
    // Mounted by Otro via H/{watched:UIs}/{UI:'Library'}.
    // Receives H (the root Mundo house).
    //
    // Shows each Book particle from Li = H.ave.find({Library:1}):
    //   • name (read-only label)
    //   • ok_pct % and last_run_ms (formatted)
    //   • editable peel textfield for extra sc (everything except Book/ok_pct/last_run_ms/active)
    //   • Activate button (sends activateBook elvis to A:Auto/w:Auto)
    //   • Reset button (sends resetStory elvis to A:Auto/w:Auto)
    //
    // Mung errors are shown as red banners at the top — fatal, user must fix code.

    import type { House }   from "$lib/O/Housing.svelte"
    import type { TheC }    from "$lib/data/Stuff.svelte"
    import { depeel, peel } from "$lib/Y.svelte"

    let { H }: { H: House } = $props()

    // ── reactive Library particle from H.ave ─────────────────────────────
    let Li = $derived((H.ave ?? []).find((c: TheC) => c.sc.Library != null) ?? null)
    let books = $derived(Li ? (Li as TheC).o({ Book: 1 }) as TheC[] : [])
    let mung_errors = $derived(Li ? (Li as TheC).o({ mung_error: 1 }) as TheC[] : [])

    // ── editable peel field per book ─────────────────────────────────────
    // editing[bookName] = current text in the input (or null = not editing)
    let editing: Record<string, string | null> = $state({})

    function extra_sc(book: TheC): Record<string, any> {
        const skip = new Set(['Book', 'ok_pct', 'last_run_ms', 'active', 'done'])
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
        H.elvisto('Auto/Auto', 'activateBook', { Book: book.sc.Book })
    }

    function reset_story() {
        H.elvisto('Auto/Auto', 'resetStory', {})
    }

    function fmt_ms(ms: number | null | undefined): string {
        if (ms == null) return '—'
        const d = new Date(ms)
        return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })
            + '.' + String(d.getMilliseconds()).padStart(3, '0')
    }

    function fmt_pct(p: number | null | undefined): string {
        if (p == null) return '—'
        return Math.round(p * 100) + '%'
    }
</script>

<div class="library-run">
    <div class="lr-header">
        <span class="lr-title">📚 Library</span>
        <button class="lr-btn reset" onclick={reset_story}>↺ reset Story</button>
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
        <table class="lr-table">
            <thead>
                <tr>
                    <th>Book</th>
                    <th>ok%</th>
                    <th>last run</th>
                    <th>extra sc</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                {#each books as book (book.sc.Book)}
                    <tr class:lr-active={book.sc.active}>
                        <td class="lr-name">{book.sc.Book}</td>
                        <td class="lr-stat">{fmt_pct(book.sc.ok_pct)}</td>
                        <td class="lr-stat lr-ms">{fmt_ms(book.sc.last_run_ms)}</td>
                        <td class="lr-extra">
                            {#if editing[book.sc.Book] != null}
                                <input
                                    class="lr-peel-input"
                                    type="text"
                                    bind:value={editing[book.sc.Book]}
                                    onblur={() => commit_edit(book)}
                                    onkeydown={e => { if (e.key === 'Enter') commit_edit(book) }}
                                />
                            {:else}
                                <span
                                    class="lr-peel-view"
                                    onclick={() => start_edit(book)}
                                    title="click to edit"
                                >{depeel(extra_sc(book)) || '—'}</span>
                            {/if}
                        </td>
                        <td class="lr-actions">
                            <button
                                class="lr-btn {book.sc.active ? 'active' : 'idle'}"
                                onclick={() => activate(book)}
                            >{book.sc.active ? '▶ active' : 'activate'}</button>
                        </td>
                    </tr>
                {/each}
            </tbody>
        </table>
    {/if}
</div>

<style>
    .library-run {
        font-size: 0.85rem;
        padding: 0.5rem;
        border: 1px solid #444;
        border-radius: 4px;
        background: #111;
        color: #ccc;
        min-width: 420px;
    }
    .lr-header {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        margin-bottom: 0.4rem;
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
    .lr-mung-msg { font-size: 0.78rem; margin-top: 0.15rem; }
    .lr-table { width: 100%; border-collapse: collapse; }
    .lr-table th { text-align: left; color: #888; font-weight: normal; padding: 0.1rem 0.3rem; border-bottom: 1px solid #333; }
    .lr-table td { padding: 0.2rem 0.3rem; border-bottom: 1px solid #222; vertical-align: middle; }
    .lr-active td { background: #1a2a1a; }
    .lr-name { font-weight: 600; color: #ddd; }
    .lr-stat { color: #aaa; white-space: nowrap; }
    .lr-ms { font-family: monospace; font-size: 0.78rem; }
    .lr-extra { min-width: 120px; }
    .lr-peel-view {
        cursor: pointer;
        color: #9ab;
        font-family: monospace;
        font-size: 0.78rem;
    }
    .lr-peel-view:hover { color: #cdf; text-decoration: underline; }
    .lr-peel-input {
        font-family: monospace;
        font-size: 0.78rem;
        background: #222;
        color: #cdf;
        border: 1px solid #556;
        border-radius: 2px;
        padding: 0.1rem 0.25rem;
        width: 100%;
    }
    .lr-btn {
        font-size: 0.78rem;
        padding: 0.15rem 0.4rem;
        border-radius: 3px;
        cursor: pointer;
        border: 1px solid #555;
        background: #222;
        color: #aaa;
    }
    .lr-btn.active { background: #1a3a1a; border-color: #4a8; color: #8d8; }
    .lr-btn.idle   { background: #222;    border-color: #555; color: #aaa; }
    .lr-btn.reset  { background: #2a1a1a; border-color: #844; color: #c88; }
    .lr-btn:hover  { filter: brightness(1.2); }
</style>