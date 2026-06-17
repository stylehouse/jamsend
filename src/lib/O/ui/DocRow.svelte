<script lang="ts">
    // DocRow.svelte — reactive doc header row used in both the Liesui flat list
    // and inside Waft.svelte for each Doc entry.
    //
    // Why a component and not a snippet:
    //   Snippets capture their outer closure at definition time.  When Liesui
    //   throttles its $state writes, pending_paths / loaded_docs go stale inside
    //   the snippet and don't update.  As a component, $derived tracks
    //   doc.version (for path / flags) and w.version (for Lies-wide state)
    //   independently and always reflects the current particle state.
    //
    // Rename UX:
    //   Inline form with [rename] and cancel, replacing the path row.
    //   The input opens with the cursor placed just before the first '.' that
    //   is to the right of the last '/' — i.e. at the stem boundary — so the
    //   stem can be immediately edited, suffixed, or deleted with shift+backspace.
    //   e.g.  Ghost/test/Idzeuzia.g  →  cursor before '.g',  selection = 'Hello'
    //         Ghost/Tour             →  cursor at end (no extension)
    //
    // Props:
    //   w         — Lies's w particle (Good,type:'text/Doc' and compile_pending live here)
    //   doc       — Doc TheC (sc.path, sc.new?, sc.not_found?)
    //   waft      — parent Waft particle; null in the flat loaded-docs list
    //   examining — from Liesui; carries examining.sc.active_path (Lang's active doc).
    //               version bumps when Lang_set_active_dock fires — is_examining reacts
    //               without a Liesui re-render (pure Svelte 5 $derived reactivity).
    //   on_del    — deletion callback; omit in flat list (no × button)
    //   on_rename — (old_path, new_path) → void; omit in flat list (no ✎ button)
    //   on_focus  — called when the user opens the doc row; Waft supplies this
    //               to fire Lies_set_cursor and advance the graft cursor.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import DocDiff from "$lib/O/ui/DocDiff.svelte"

    let { H, w, doc, waft = null, on_del, on_rename, on_focus, examining }: {
        H:          House
        w:          TheC
        doc:        TheC
        waft?:      TheC | null
        on_del?:    (doc: TheC) => void
        on_rename?: (old_path: string, new_path: string) => void
        on_focus?:  (doc: TheC) => void   // called when the user opens this doc row
        examining?: TheC | null
    } = $props()

    // ── reactive reads ────────────────────────────────────────────────
    let path      = $derived((() => { void doc.version; return doc.sc.path as string })())
    let is_new    = $derived((() => { void doc.version; return !!doc.sc.new })())
    let show_nf   = $derived((() => { void doc.version; return !!doc.sc.not_found && !doc.sc.new })())
    let thang     = $derived((() => { void doc.version; return doc.sc.thang })())
    let codetype  = $derived(ls_codetype(path))

    // Look up the Good for this path from w every time w or the Good changes.
    // The Good lives under req:Store; track both the Store subtree and the Good's
    //  off-snap content version (good.vers) so the row reacts when content lands or
    //  a surprise_read is stamped|cleared.
    let good = $derived((() => {
        const store = (w.ob({ req: 'Store' }) as TheC[])[0] as TheC | undefined
        const g = store
            ? (store.ob({ Good: 1, type: 'text/Doc', path }) as TheC[])[0] as TheC | undefined
            : undefined
        void g?.vers
        return g
    })())
    let is_loaded = $derived(!!good && good.c.content !== undefined)
    // Pull-before-push parked the auto-save: disk changed under the open edit and
    //  the text is stashed on good/%surprise_read.  Present → show the conflict row.
    let surprise = $derived((() => {
        void good?.vers
        return good ? (good.o({ surprise_read: 1 }) as TheC[])[0] as TheC | undefined : undefined
    })())
    let mine_text   = $derived((() => { void surprise?.version; return surprise?.sc.text as string | undefined })())
    let theirs_text = $derived((() => { void surprise?.version; return surprise?.c.disk_text as string | undefined })())
    let is_pending = $derived(!!(w.ob({ compile_pending: 1, path }) as TheC[]).some(p => !p.sc.done))
    // Glow when this doc is the one currently open in Lang.
    // examining.sc.active_path mirrors ave/{active_dock:1}.sc.path and bumps when
    // Lang_set_active_dock fires — no Liesui re-render required, pure Svelte 5.
    let is_examining = $derived(examining?.vers && examining.sc.active_path === path)

    // ── codetype derivation ───────────────────────────────────────────
    // Second-level extensions: Housing.svelte.ts → 'svelte.ts'.
    // No dot → '' (avoids returning the bare filename as a codetype).
    const SECOND_LEVEL_FILETYPES = ['svelte']
    function ls_codetype(p: string): string {
        const parts = p.split('.')
        if (parts.length <= 1) return ''
        const ext  = parts[parts.length - 1]
        const prev = parts.length >= 3 ? parts[parts.length - 2] : ''
        if (prev && SECOND_LEVEL_FILETYPES.includes(prev)) return `${prev}.${ext}`
        return ext
    }

    // ── surprise_read conflict resume ─────────────────────────────────
    let show_diff = $state(false)
    // keep mine: push the stashed text over disk.  take theirs: drop the stash and
    //  re-read disk into the editor.  Both run in Lies (see e_Lies_surprise_*).
    function keep_mine()   { H.i_elvisto('Lies/Lies', 'Lies_surprise_keep_mine',   { path }) }
    function take_theirs() { H.i_elvisto('Lies/Lies', 'Lies_surprise_take_theirs', { path }) }

    // ── rename state ──────────────────────────────────────────────────
    let renaming = $state<string | null>(null)

    function start_rename()  { renaming = path }
    function cancel_rename() { renaming = null }
    function commit_rename() {
        const n = renaming?.trim() ?? ''
        renaming = null
        if (!n || n === path) return
        on_rename?.(path, n)
    }
</script>

<div class="ls-doc-hdr">
    {#if renaming !== null}
        <!-- rename form — mirrors the +Doc form style (input + [rename] cancel) -->
        <input class="ls-input ls-rename-input"
            value={renaming}
            oninput={(ev) => renaming = (ev.target as HTMLInputElement).value}
            onkeydown={(ev) => {
                if (ev.key === 'Enter')  commit_rename()
                if (ev.key === 'Escape') cancel_rename()
            }}
            use:place_cursor_at_stem />
        <button class="ls-add-btn ls-add-btn-sm" onclick={commit_rename}
                disabled={!renaming?.trim() || renaming.trim() === path}>rename</button>
        <button class="ls-cancel-btn" onclick={cancel_rename}>cancel</button>
    {:else}
        <!-- clicking the path label switches the active doc in Lang
             and notifies Lies (via on_focus) to move the graft cursor -->
        <button class="ls-doc-path ls-doc-open-btn" title="open in editor"
                class:ls-doc-examining={is_examining}
                onclick={() => { H.i_elvisto('Lang/Lang', 'Dock_open', { path }); on_focus?.(doc) }}>
            {path}
        </button>
        {#if codetype}<span class="ls-badge">{codetype}</span>{/if}
        {#if is_new}
            <span class="ls-flag ls-flag-new"
                title="created here, not yet written to disk — a spawning ghost">new</span>
        {:else if show_nf}
            <span class="ls-flag ls-flag-missing"
                title="file not found on disk — rename to fix, or write via compile">?</span>
        {/if}
        {#if thang}
            <span class="ls-flag ls-flag-new" title="counter for debug">{thang}</span>
        {/if}
        {#if is_pending}
            <span class="ls-state-ind" title="writing…">⏳</span>
        {:else if !is_loaded && !is_new && !show_nf}
            <span class="ls-state-ind ls-dim" title="not yet loaded">…</span>
        {/if}
        <span class="ls-spacer"></span>
        {#if on_rename}
            <button class="ls-icon-btn" title="rename" onclick={start_rename}>✎</button>
        {/if}
        {#if on_del && waft}
            <button class="ls-icon-btn ls-del-btn" title="remove"
                    onclick={() => on_del!(doc)}>×</button>
        {/if}
    {/if}
</div>

{#if surprise}
    <!-- pull-before-push found disk changed under the open edit; the auto-save is
         parked on good/%surprise_read.  Resume it: keep mine (push over disk) or
         take theirs (re-read disk into the editor). -->
    <div class="ls-conflict">
        <div class="ls-conflict-hdr">
            <span class="ls-conflict-warn"
                  title="this file changed on disk while you were editing — your save is held">⚠ disk changed under your edit</span>
            <button class="ls-conflict-btn ls-keep"  onclick={keep_mine}
                    title="overwrite disk with your edit">keep mine</button>
            <button class="ls-conflict-btn ls-take"  onclick={take_theirs}
                    title="discard your edit and reload from disk">take theirs</button>
            <button class="ls-conflict-toggle" onclick={() => show_diff = !show_diff}>
                {show_diff ? 'hide diff' : 'diff'}</button>
        </div>
        {#if show_diff}
            {#if theirs_text !== undefined}
                <DocDiff mine={mine_text ?? ''} theirs={theirs_text} />
            {:else}
                <div class="ls-conflict-note">disk version not loaded (page reloaded) — “take theirs” to fetch it.</div>
            {/if}
        {/if}
    </div>
{/if}

<script module>
    // place_cursor_at_stem — Svelte use: action for rename inputs.
    //
    //   Places the cursor just before the first '.' to the right of the last '/',
    //   so the file stem is selected and the extension is preserved.
    //
    //   e.g.  Ghost/test/Idzeuzia.g    → selects 'Hello', cursor before '.g'
    //         Ghost/test/Foo.svelte.ts → selects 'Foo', cursor before '.svelte.ts'
    //         Ghost/Tour                → cursor at end (no extension)
    //
    //   Called once on mount (the input is inside {#if renaming !== null}).
    export function place_cursor_at_stem(node: HTMLInputElement) {
        node.focus()
        const val      = node.value
        const slash_i  = val.lastIndexOf('/')
        const base     = slash_i >= 0 ? val.slice(slash_i + 1) : val
        const dot_i    = base.indexOf('.')
        const stem_end = slash_i >= 0
            ? slash_i + 1 + (dot_i >= 0 ? dot_i : base.length)
            : (dot_i >= 0 ? dot_i : base.length)
        const stem_start = slash_i >= 0 ? slash_i + 1 : 0
        node.setSelectionRange(stem_start, stem_end)
        return {}
    }
</script>

<style>
    .ls-doc-hdr {
        display: flex; align-items: center; gap: 0.25rem;
        flex-wrap: wrap; min-height: 1.4rem;
        border-bottom: 1px solid #1c1c1c; padding: 0.1rem 0;
    }
    .ls-doc-path  { font-family: monospace; font-size: 0.76rem; color: #9ab; flex: 1 }
    .ls-doc-open-btn {
        background: none; border: none; cursor: pointer; text-align: left;
        padding: 0; font-family: monospace; font-size: 0.76rem; color: #9ab;
        flex: 1; white-space: nowrap;
    }
    .ls-doc-open-btn:hover { color: #c8dff0; text-decoration: underline; }
    /* Active doc in Lang — title glows blue-white.
       Works for both the Good flat list and Waft/Doc entries. */
    .ls-doc-examining { color: #d4eeff !important; text-shadow: 0 0 7px #4488cc99; }
    .ls-badge {
        font-size: 0.68rem; background: #1c1c28;
        border: 1px solid #333; border-radius: 2px; padding: 0 0.2rem; color: #778; flex-shrink: 0;
    }
    .ls-flag        { font-size: 0.68rem; border-radius: 2px; padding: 0 0.2rem; flex-shrink: 0; cursor: default }
    .ls-flag-new    { background: #1a3a1a; color: #6a9; border: 1px solid #2a5a2a }
    .ls-flag-missing{ background: #3a2010; color: #c84; border: 1px solid #5a3010 }
    .ls-state-ind   { font-size: 0.72rem; flex-shrink: 0 }
    .ls-dim         { color: #555 }
    .ls-spacer      { flex: 1 }
    .ls-input {
        background: #0d0d14; border: 1px solid #333; border-radius: 3px;
        color: #aaa; font-family: monospace; font-size: 0.76rem;
        padding: 0.2rem 0.35rem; outline: none; flex: 1; min-width: 6rem;
    }
    .ls-input:focus  { border-color: #446 }
    .ls-add-btn {
        background: #1a1a2a; border: 1px solid #334; border-radius: 3px;
        color: #88a; cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.4rem;
        white-space: nowrap; flex-shrink: 0;
    }
    .ls-add-btn:hover    { background: #222238; color: #aac }
    .ls-add-btn:disabled { opacity: 0.35; cursor: default }
    .ls-add-btn-sm       { padding: 0.15rem 0.3rem }
    .ls-cancel-btn {
        background: none; border: none; color: #555;
        cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.3rem; flex-shrink: 0;
    }
    .ls-cancel-btn:hover { color: #999 }
    /* ls-icon-btn / ls-del-btn declared :global in Waft.svelte */

    /* surprise_read conflict row */
    .ls-conflict {
        border: 1px solid #5a3010; border-left-width: 3px;
        background: #1a1008; border-radius: 3px;
        padding: 0.25rem 0.4rem; margin: 0.15rem 0;
    }
    .ls-conflict-hdr {
        display: flex; align-items: center; gap: 0.35rem; flex-wrap: wrap;
    }
    .ls-conflict-warn { font-size: 0.72rem; color: #d39; flex: 1; white-space: nowrap; }
    .ls-conflict-btn {
        font-size: 0.72rem; border-radius: 3px; cursor: pointer;
        padding: 0.1rem 0.4rem; white-space: nowrap; flex-shrink: 0;
    }
    .ls-keep { background: #15301a; border: 1px solid #2a5a2a; color: #7c9; }
    .ls-keep:hover { background: #1c3e22; color: #9eb; }
    .ls-take { background: #301512; border: 1px solid #5a2a24; color: #c87; }
    .ls-take:hover { background: #3e1c18; color: #e9a; }
    .ls-conflict-toggle {
        background: none; border: none; color: #888; cursor: pointer;
        font-size: 0.72rem; padding: 0.1rem 0.3rem; flex-shrink: 0;
        text-decoration: underline;
    }
    .ls-conflict-toggle:hover { color: #bbc; }
    .ls-conflict-note { font-size: 0.7rem; color: #976; margin-top: 0.25rem; }
</style>
