<script lang="ts">
    // DocRow.svelte — reactive doc header row used in both the Liesui flat list
    // and inside WaftComp for each Doc entry.
    //
    // Why a component and not a snippet:
    //   Snippets capture their outer closure at definition time.  When Liesui
    //   throttles its $state writes, pending_paths / loaded_docs go stale inside
    //   the snippet and don't update.  As a component, $derived tracks
    //   doc.version (for path / flags) and w.version (for Lies-wide state)
    //   independently and always reflects the current particle state.
    //
    // Props:
    //   w         — Lies's w particle (compile_pending, loaded_doc live here)
    //   doc       — Doc TheC (sc.path, sc.new?, sc.not_found?) or a loaded_doc
    //   waft      — parent Waft particle; null in the flat loaded-docs list
    //   on_del    — deletion callback; omit in flat list (shows no × button)
    //   on_rename — (old_path, new_path) → void; omit in flat list (no ✎ button)
    //               Caller is responsible for mutating doc.sc.path and cleaning
    //               up the old open_req/loaded_doc via e:Lies_rename_doc.

    import type { TheC } from "$lib/data/Stuff.svelte"

    let { w, doc, waft = null, on_del, on_rename }: {
        w:          TheC
        doc:        TheC
        waft?:      TheC | null
        on_del?:    (doc: TheC) => void
        on_rename?: (old_path: string, new_path: string) => void
    } = $props()

    // ── reactive reads ────────────────────────────────────────────────
    // void doc.version subscribes to any mutation on the doc particle
    // (path rename, flag changes).  void w.version subscribes to Lies-wide
    // changes (new loaded_doc, compile_pending settle).

    let path      = $derived((() => { void doc.version; return doc.sc.path as string })())
    let is_new    = $derived((() => { void doc.version; return !!doc.sc.new })())
    let show_nf   = $derived((() => { void doc.version; return !!doc.sc.not_found && !doc.sc.new })())
    let thang     = $derived((() => { void doc.version; return doc.sc.thang })())
    let codetype  = $derived(ls_codetype(path))

    // Look up loaded / pending state from w every time w changes.
    let is_loaded  = $derived((() => {
        void w.version
        return !!(w.o({ loaded_doc: 1, path }) as object[])[0]
    })())
    let is_pending = $derived((() => {
        void w.version
        return (w.o({ compile_pending: 1 }) as TheC[]).some(p => !p.sc.done && p.sc.path === path)
    })())

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

    // ── rename state ──────────────────────────────────────────────────
    // Local to this component — survives Liesui and Waft re-renders because
    // DocRow is keyed on doc.sc.path in the parent {#each}.
    // Note: when a rename commits, the key changes and this instance is
    // destroyed/replaced — that's fine; state has been flushed by then.
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
        <!-- rename input replaces the entire row while active -->
        <input class="ls-input ls-rename-input"
            value={renaming}
            oninput={(ev) => renaming = (ev.target as HTMLInputElement).value}
            onkeydown={(ev) => {
                if (ev.key === 'Enter')  commit_rename()
                if (ev.key === 'Escape') cancel_rename()
            }}
            use:focus_on_mount />
        <button class="ls-icon-btn" onclick={cancel_rename}>×</button>
    {:else}
        <span class="ls-doc-path">{path}</span>
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

<script module>
    // focus_on_mount: imperative focus for rename inputs.
    // Rename inputs are inside {#if renaming !== null} so they are genuinely
    // once-mounted — this action fires exactly once per rename session.
    export function focus_on_mount(node: HTMLElement) {
        node.focus()
        if (node instanceof HTMLInputElement) node.select()
        return {}
    }
</script>

<style>
    /* These class names match the :global declarations in Liesui.svelte so
       that shared styles (ls-spacer, ls-icon-btn, etc) apply here too. */
    .ls-doc-hdr {
        display: flex; align-items: center; gap: 0.25rem;
        flex-wrap: wrap; min-height: 1.4rem;
        border-bottom: 1px solid #1c1c1c; padding: 0.1rem 0;
    }
    .ls-doc-path  { font-family: monospace; font-size: 0.76rem; color: #9ab; flex: 1 }
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
        padding: 0.2rem 0.35rem; outline: none;
    }
    .ls-input:focus  { border-color: #446 }
    .ls-rename-input { flex: 1; min-width: 6rem }
    /* ls-icon-btn / ls-del-btn / ls-icon-btn:hover declared :global in Liesui */
</style>
