<script lang="ts">
    // ui/DocPoint.svelte — CRUD for a single bookmark / Point.
    //
    // A bookmark starts as a raw char-range anchor {from,to,label} on docC.
    // Here the user can:
    //   rename       — edit bm.sc.label and optionally bm.sc.method
    //   fuzzify  (~) — resolve the offset range to the enclosing def name
    //                  via e:Lang_point_fuzzify → stamps bm.sc.method
    //   export   (↑) — push bookmark up to the active Waft as a proper Point
    //                  via e:Lies_export_point → stamps bm.sc.point_serial
    //   delete   (×) — remove from docC and CM via e:Lang_remove_bookmark
    //
    // bm.sc layout:
    //   bookmark:string     — unique id (bm_${from}_${to})
    //   from, to:number     — char offsets (remapped by CM's RangeSet.map)
    //   label:string        — user-editable display name
    //   method?:string      — set by fuzzify: enclosing def name
    //   point_serial?:number — set after export: Point serial across all Waft
    //   vanished?:1         — decoration was destroyed by a text edit
    //
    // < local/global toggle (turn bookmark into free-text search via Lies)
    //   is a future operation; left as a stub comment here.

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H, bm, doc_path, lang_model }: {
        H:          House
        bm:         TheC
        doc_path:   string
        lang_model?: TheC
    } = $props()

    let editing     = $state(false)
    let label_val   = $state('')
    let input_el: HTMLInputElement | undefined = $state()

    // Auto-focus the label input whenever editing flips on.
    $effect(() => { if (editing && input_el) { input_el.focus(); input_el.select() } })

    function start_edit() {
        label_val = ((bm.sc.method || bm.sc.label) as string | undefined) ?? ''
        editing = true
    }
    function commit_edit() {
        const v = label_val.trim()
        if (v) {
            bm.sc.label = v
            // A label with no whitespace plausibly names a method.
            if (!/\s/.test(v)) bm.sc.method = v
            bm.bump_version()
            H.main()
        }
        editing = false
    }
    function cancel_edit() { editing = false }

    function remove() {
        H.i_elvisto('Lang/Lang', 'Lang_remove_bookmark', {
            doc: doc_path, bookmark_id: bm.sc.bookmark,
        })
    }

    // Resolve the positional anchor to the enclosing def name from the
    // compile index.  No-op and shows a hint if index is absent.
    function fuzzify() {
        H.i_elvisto('Lang/Lang', 'Lang_point_fuzzify', {
            doc: doc_path, bookmark_id: bm.sc.bookmark,
        })
    }

    // Export this bookmark as a Point under the active Waft Doc.
    // Lies will find-or-create the Doc row and assign a serial.
    function export_to_doc() {
        H.i_elvisto('Lies/Lies', 'Lies_export_point', {
            path:        doc_path,
            bookmark_id: bm.sc.bookmark as string,
            from:        bm.sc.from     as number,
            to:          bm.sc.to       as number,
            method:      (bm.sc.method || bm.sc.label || '') as string,
            label:       (bm.sc.label ?? '') as string,
        })
    }

    // < toggle_local / toggle_global: convert between positional, local-doc,
    //   and global (free-text search via Lies) Point kinds.
    //   Left as future work — the three Point kinds need schema design first.

    // Reading bm.version inside $derived subscribes to bookmark mutations
    // (label changes, fuzzify, export stamp) so the display updates live.
    let pos_hint  = $derived(`${bm.sc.from}…${bm.sc.to}`)
    let display   = $derived(((void bm.version),
        (bm.sc.method || bm.sc.label || pos_hint) as string))
    let exported  = $derived(((void bm.version), bm.sc.point_serial != null))
    let is_fuzzy  = $derived(((void bm.version), !!bm.sc.method))
    let vanished  = $derived(((void bm.version), !!bm.sc.vanished))

    // ── inline syntax tree ───────────────────────────────────────────────────
    //
    // When txt mode is active, model/Line:N holds the Lezer hierarchy for the
    // line this bookmark sits on.  The eye button toggles it open.
    //
    // show_tree initialises from H.c.dp_show_tree (true when unset) so new
    // bookmarks open at whatever state the last toggle left things.
    // toggle_tree writes back to H.c.dp_show_tree so the next new instance
    // picks up the current preference on its own init.

    let show_tree = $state((H.c as Record<string,unknown>).dp_show_tree !== false)
    function toggle_tree() {
        show_tree = !show_tree
        ;(H.c as Record<string,unknown>).dp_show_tree = show_tree
    }

    // sc keys that are positional / bookmarking noise — hidden in the render
    const HIDDEN = new Set(['from','to','line_from','line_to'])
    const is_bm_tag = (k: string) => k.startsWith('the_bm_')

    // Line:N particle whose range contains this bookmark's `from`.
    // lang_model is derived in Langui (where H is reliably H:Lang) and passed
    // down — no House navigation needed here.
    // ob() subscribes to lang_model.version so line_c re-derives after each
    // whatsthis_txt rebuild (which calls model.bump_version()).
    let line_c = $derived.by((): TheC | undefined => {
        if (!show_tree || !lang_model) return undefined
        const from  = bm.sc.from as number
        const lines = lang_model.ob({ Line: 1 }) as TheC[]
        return lines.find(l =>
            (l.sc.line_from as number) <= from && from < (l.sc.line_to as number)
        )
    })

    // ── node display helpers ─────────────────────────────────────────────────

    // FNV-1a hash → hue/lightness — same idiom as Storui's trace colouring.
    // Deterministic: same node type name always maps to the same colour.
    function _nhash(s: string): number {
        let h = 0x811c9dc5
        for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193) >>> 0
        return h
    }
    function _hsl(name: string): string {
        const hue = _nhash(name) % 360
        const lit = 44 + (_nhash(name + '~') % 24)   // 44–67
        return `hsl(${hue},68%,${lit}%)`
    }

    // First non-positional, non-bm-tag, non-str sc key — the node's type name.
    // Line:N has value 1144 (not 1), MemberExpression has value 1; we take any.
    function type_key(node: TheC): string {
        return Object.keys(node.sc)
            .find(k => !HIDDEN.has(k) && !is_bm_tag(k) && k !== 'str') ?? '?'
    }

    // Type+value portion only — no str.  Used for the coloured half of each line.
    function type_part(node: TheC): string {
        const tk  = type_key(node)
        const val = node.sc[tk]
        return val === 1 ? tk : `${tk}:${val}`
    }

    // One-line label: type key (with value if not 1), then str after a tab.
    // Used for clipboard text; from/to coords are in HIDDEN and never shown.
    // No truncation here — the tree_to_text caller sees the full strings.
    function node_label(node: TheC): string {
        const str = node.sc.str as string | undefined
        return str !== undefined
            ? `${type_part(node)}\t${String(str)}`
            : type_part(node)
    }

    // True when %str === target exists on any leaf in node's subtree.
    // Drives the topmost-vs-leaf str trimming logic below.
    function str_reaches_leaf(node: TheC, target: string): boolean {
        const kids = node.o() as TheC[]
        if (kids.length === 0) return (node.sc.str as string | undefined) === target
        return kids.some(kid => str_reaches_leaf(kid, target))
    }

    // Whether this node should display its %str in the rendered tree.
    //   leaf                → always show (deepest natural anchor)
    //   same str as parent  → hide (parent is already the topmost)
    //   topmost, non-leaf   → show only when str does NOT reach any leaf below;
    //                         if it does, the leaf will carry it instead
    function should_show_str(node: TheC, parent_str: string | undefined): boolean {
        const str  = node.sc.str as string | undefined
        if (str === undefined) return false
        const kids = node.o() as TheC[]
        if (kids.length === 0) return true
        if (str === parent_str)  return false
        return !str_reaches_leaf(node, str)
    }

    // Flatten the TheC subtree into {indent, type_part, str_part, color} lines.
    // type_part and str_part are rendered in separate spans with separate colours.
    // Actual space characters so copy-paste preserves the tree shape.
    // depth 0 is always the Line node — its str is the complete source line and
    // always shown, even when the same text reaches a leaf below.
    type FlatLine = { indent: string, type_part: string, str_part: string | undefined, color: string }
    function flatten_tree(node: TheC, depth = 0, parent_str: string | undefined = undefined): FlatLine[] {
        const tk   = type_key(node)
        const str  = node.sc.str as string | undefined
        const show = depth === 0 ? str !== undefined : should_show_str(node, parent_str)
        const lines: FlatLine[] = [{
            indent:    '  '.repeat(depth),
            type_part: type_part(node),
            str_part:  show && str !== undefined ? String(str) : undefined,
            color:     _hsl(tk),
        }]
        for (const kid of node.o() as TheC[]) {
            for (const l of flatten_tree(kid, depth + 1, str)) lines.push(l)
        }
        return lines
    }

    // Plain text version for clipboard — same indentation, labels stripped of colour.
    function tree_to_text(node: TheC, depth = 0): string {
        const prefix = '  '.repeat(depth)
        const kids   = node.o() as TheC[]
        const self   = prefix + node_label(node)
        if (!kids.length) return self
        return self + '\n' + kids.map(c => tree_to_text(c, depth + 1)).join('\n')
    }

    async function copy_tree() {
        if (!line_c) return
        try { await navigator.clipboard.writeText(tree_to_text(line_c)) }
        catch { /* clipboard blocked */ }
    }
</script>

<div class="dp-wrap">

<!-- ── main bookmark row ───────────────────────────────────────────────── -->
<div class="dp"
     class:dp-vanished={vanished}
     class:dp-exported={exported}
     class:dp-fuzzy={is_fuzzy}>

    <span class="dp-pos" title="char range">{pos_hint}</span>

    {#if editing}
        <input
            class="dp-input"
            bind:value={label_val}
            bind:this={input_el}
            onkeydown={(ev) => {
                if (ev.key === 'Enter')  commit_edit()
                if (ev.key === 'Escape') cancel_edit()
            }}
            onfocusout={commit_edit} />
    {:else}
        <span class="dp-label"
              title={vanished ? 'anchor lost — text range was overwritten' : 'click to rename'}
              onclick={start_edit}>{display}</span>
    {/if}

    {#if vanished}
        <span class="dp-warn" title="anchor lost">⚠</span>
    {/if}

    <div class="dp-btns">
        <!-- 👁 tree toggle — shows the syntax hierarchy for this line.
             State lives on w.c.show_tree so it persists across bookmark add/remove. -->
        <button class="dp-btn dp-btn-eye" class:dp-btn-eye-on={show_tree}
                onclick={toggle_tree}
                title={show_tree ? 'hide syntax tree' : 'show syntax tree'}>👁</button>

        <!-- ~ fuzzify: only shown when no method name yet -->
        {#if !is_fuzzy}
            <button class="dp-btn dp-btn-fuzzy" onclick={fuzzify}
                    title="resolve to method name from compile index">~</button>
        {/if}

        <!-- ↑ export / serial badge -->
        {#if !exported}
            <button class="dp-btn dp-btn-export" onclick={export_to_doc}
                    title="export to active Waft Doc as a Point">↑</button>
        {:else}
            <span class="dp-serial" title="Point serial #{bm.sc.point_serial}">
                #{bm.sc.point_serial}
            </span>
        {/if}

        <!-- < local / global toggle goes here -->

        <button class="dp-btn dp-btn-del" onclick={remove}
                title="delete bookmark">×</button>
    </div>
</div>

<!-- ── inline syntax tree ───────────────────────────────────────────────── -->
{#if show_tree}
<div class="dp-tree">
    {#if line_c}
        {@const flat = flatten_tree(line_c)}
        <div class="dp-tree-actions">
            <button class="dp-tree-copy" onclick={copy_tree} title="copy tree as text">⎘ copy</button>
        </div>
        <!-- Each .dp-tn is a flex row: left cell holds indent + type (min-width
             so str values form their own right-hand column), right cell holds
             the raw str value with no prefix label.  Indent in the left span
             pushes deeper nodes' str values rightward — indentation is visible
             in the str column for free. -->
        <div class="dp-tree-pre">{#each flat as fl}<div class="dp-tn"><span class="dp-tn-left" style="color:{fl.color}">{fl.indent}{fl.type_part}</span>{#if fl.str_part !== undefined}<span class="dp-str">{fl.str_part}</span>{/if}</div>{/each}</div>
    {:else}
        <span class="dp-tree-empty">no tree — add Opt/txtsyntaxdump:1 to w:Lang</span>
    {/if}
</div>
{/if}

</div>

<style>
    /* ── wrapper ────────────────────────────────────────────────────────── */
    .dp-wrap {
        display: flex; flex-direction: column;
    }

    /* ── bookmark row (unchanged layout) ───────────────────────────────── */
    .dp {
        display: flex; align-items: center; gap: 4px;
        padding: 2px 6px; border-radius: 3px;
        font-size: 0.74rem; font-family: monospace;
        background: #0d0d16; border: 1px solid transparent;
        transition: border-color 0.1s;
    }
    .dp:hover         { border-color: #1e2230 }
    .dp-vanished      { opacity: 0.45 }
    .dp-exported      { border-left: 2px solid #2a4a6a }
    .dp-fuzzy .dp-label { font-style: italic; color: #6090b0 }

    .dp-pos {
        color: #2a3040; flex-shrink: 0; font-size: 0.66rem;
        user-select: none;
    }
    .dp-label {
        flex: 1; color: #7a9ab4; cursor: pointer;
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
        min-width: 0;
    }
    .dp-label:hover { color: #a0c4d8 }

    .dp-input {
        flex: 1; min-width: 0;
        background: #0a0a14; border: 1px solid #2a3050;
        border-radius: 2px; color: #9ab0c8;
        font-family: monospace; font-size: 0.74rem;
        padding: 0 4px; outline: none;
    }
    .dp-input:focus { border-color: #3a5080 }

    .dp-warn   { color: #8a4040; flex-shrink: 0; font-size: 0.8rem }
    .dp-serial { color: #2a4060; font-size: 0.66rem; flex-shrink: 0 }

    .dp-btns { display: flex; gap: 2px; flex-shrink: 0; margin-left: auto }
    .dp-btn {
        background: #111120; border: 1px solid #1a1a30;
        border-radius: 2px; color: #3a4460; cursor: pointer;
        font-size: 0.68rem; line-height: 1.4; padding: 0 4px;
    }
    .dp-btn:hover         { background: #181828; color: #7090b0; border-color: #2a3050 }
    .dp-btn-export:hover  { color: #50a070 }
    .dp-btn-del:hover     { color: #a05050 }
    .dp-btn-fuzzy:hover   { color: #8070b0 }

    .dp-btn-eye         { font-size: 0.75rem; opacity: 0.3 }
    .dp-btn-eye:hover   { opacity: 0.7 }
    .dp-btn-eye-on      { opacity: 1; background: #0d1020 }

    /* ── tree panel ─────────────────────────────────────────────────────── */
    .dp-tree {
        padding: 4px 6px 5px 8px;
        background: #080810;
        border-top: 1px solid #111120;
        font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
        font-size: 0.68rem;
        overflow-x: auto;
    }

    .dp-tree-actions {
        display: flex; justify-content: flex-end;
        margin-bottom: 2px;
    }
    .dp-tree-copy {
        background: none; border: 1px solid #1a2030;
        border-radius: 2px; color: #334455; cursor: pointer;
        font-size: 0.64rem; padding: 0 5px;
    }
    .dp-tree-copy:hover { color: #5080a0; border-color: #2a4060 }

    .dp-tree-empty { color: #2a3040; font-style: italic; }

    /* font and selection only — whitespace preservation lives on .dp-tn-left */
    .dp-tree-pre {
        margin: 0; padding: 0;
        background: transparent;
        font: inherit;
        user-select: text;
    }
    /* flex row: left cell (type + indent) sets the column boundary */
    .dp-tn      { display: flex; align-items: baseline; line-height: 1.15; }
    /* white-space:pre lives here so indent spaces in the left cell are rendered */
    .dp-tn-left { min-width: 6em; white-space: pre; flex-shrink: 0; }
    /* str value — no label prefix, just the raw string in its own column */
    .dp-str     { color: #a08040; white-space: pre; padding-left: 0.75em; }
</style>
