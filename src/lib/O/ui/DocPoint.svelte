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

    let { H, bm, doc_path }: {
        H:        House
        bm:       TheC
        doc_path: string
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
</script>

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

<style>
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
</style>
