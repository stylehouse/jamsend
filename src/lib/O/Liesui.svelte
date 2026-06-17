<script lang="ts">
    // Liesui.svelte — reactive UI for Lies.
    //
    // Reactivity strategy
    // ───────────────────
    //   H.ave fires every think() tick (Housing reassigns the array whenever any
    //   enrolled particle bumps its version, which Lies does on every tick).
    //   The $effect runs on every such reassignment, but H.clear throttles the
    //   actual $state writes (and thus DOM updates) — keeping focused inputs
    //   stable between ticks.
    //
    //   The Waft tree renders <WaftComp> components.  Components survive parent
    //   re-renders as long as their key (waft.sc.Waft) is stable.  All form state
    //   lives inside WaftComp.
    //
    //   Doc header rows use DocRow.svelte, which reads doc.version and w.version
    //   directly — so loaded/pending state stays live without Liesui re-rendering.

    import type { House }   from "$lib/O/Housing.svelte"
    import type { TheC }    from "$lib/data/Stuff.svelte"
    import WaftComp         from "$lib/O/ui/Waft.svelte"
    import DocRow           from "$lib/O/ui/DocRow.svelte"
    import PeelInput        from "$lib/O/ui/PeelInput.svelte"

    let { H }: { H: House } = $props()

    // ── state ─────────────────────────────────────────────────────────
    let Lies:        TheC | undefined = $state()
    let loaded_docs: TheC[]           = $state([])
    let errors:      TheC[]           = $state([])
    let all_wafts:   TheC[]           = $state([])

    // examining — the %examining particle from Lies's w, placed in watched:ave.
    // Passed down to Waft and DocRow; DocRow derives is_examining from it.
    // examining.sc.active_path mirrors Lang's active_doc so DocRow glows without
    // needing a Liesui re-render — DocRow's $derived tracks examining.version directly.
    let examining: TheC | undefined = $state()

    $effect(() => {
        const ex = H.ave.ob({ examining: 1 })[0] as TheC | undefined
        if (!ex) return
        ex.ob()   // track examining.version; re-runs when w:Lies bumps via watch_c
        const lies_w = ex.c?.w as TheC | undefined
        if (!lies_w) return
        if (lies_w !== Lies) Lies = lies_w
        H.clear(async () => {
            loaded_docs = lies_w.o({ loaded_doc: 1 })   as TheC[]
            errors      = lies_w.o({ compile_error: 1 }) as TheC[]
            all_wafts   = lies_w.o({ Waft: 1 })          as TheC[]
            examining   = ex
        })
    })

    // ── + Waft form ──────────────────────────────────────────────────
    let waft_form_open = $state(false)
    let new_waft_path  = $state('')

    function submit_new_waft() {
        const path = new_waft_path.trim()
        if (!path) return
        H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path })
        new_waft_path  = ''
        waft_form_open = false
    }

    // ── active / delete (need Lies to touch siblings) ─────────────────
    function set_waft_active(waft: TheC) {
        if (!Lies) return
        for (const w of Lies.o({ Waft: 1 }) as TheC[]) delete w.sc.active
        waft.sc.active = 1
        Lies.bump_version()
    }
    function delete_waft(waft: TheC) {
        if (!Lies) return
        Lies.drop(waft)
        Lies.bump_version()
    }

    // ── errors ───────────────────────────────────────────────────────
    function dismiss_errors() {
        if (!Lies) return
        for (const e of errors) Lies.drop(e)
        Lies.bump_version()
    }
</script>

<div class="ls-ui">

    <!-- header — just the + Waft PeelInput row; no title, no + Now -->
    <div class="ls-header">
        <PeelInput
            label="Waft"
            open={waft_form_open}
            mk_ph="path/to/waft"
            sc_ph=""
            mainkey={new_waft_path}
            on_mk={(v) => new_waft_path = v}
            submit_label="+"
            on_open={() => { waft_form_open = true }}
            on_submit={submit_new_waft}
            on_cancel={() => { waft_form_open = false; new_waft_path = '' }} />
    </div>

    {#if !Lies}
        <div class="ls-empty">waiting for Lies…</div>
    {:else}

    {#if errors.length}
        <div class="ls-errors">
            <strong>⛔ compile errors</strong>
            <button class="ls-dismiss" onclick={dismiss_errors}>×</button>
            {#each errors as err}
                <div class="ls-error-msg">{err.sc.path ?? ''} — {err.sc.msg}</div>
            {/each}
        </div>
    {/if}

    <!-- loaded docs flat list — w/{loaded_doc:1} entries confirm Lies handed
         each doc to Lang.  DocRow reads w.version directly so pending/active
         state is live without Liesui re-rendering. -->
    {#if loaded_docs.length}
        <div class="ls-loaded-section">
            {#each loaded_docs as ld (ld.sc.path)}
            Yeah!
                <DocRow {H} w={Lies} doc={ld} {examining} />
            Yeah!111111
            {/each}
        </div>
    {/if}

    <!-- Waft tree — pass Lies (w particle) as w so DocRow inside WaftComp has
         live state.  WaftComp is keyed by waft.sc.Waft so it survives re-renders. -->
    {#if all_wafts.length}
        <div class="ls-waft-section">
            {#each all_wafts as waft (waft.sc.Waft)}
                <WaftComp {H} w={Lies} {waft} depth={0}
                    {examining}
                    on_active={set_waft_active}
                    on_delete={delete_waft} />
            {/each}
        </div>
    {:else}
        <div class="ls-empty">no wafts</div>
    {/if}

    {/if}
</div>

<style>
    .ls-ui {
        font-size: 0.83rem; padding: 0.5rem;
        border: 1px solid #444; border-radius: 4px;
        background: #111; color: #ccc; min-width: 360px;
    }
    .ls-header { margin-bottom: 0.3rem }
    .ls-errors {
        background: #300; border: 1px solid #c44; border-radius: 3px;
        padding: 0.3rem 0.5rem; margin-bottom: 0.4rem;
        color: #f88; display: flex; flex-wrap: wrap; gap: 0.2rem; align-items: flex-start;
    }
    .ls-dismiss   { margin-left: auto; background: none; border: none; color: #f88; cursor: pointer; font-size: 1rem; line-height: 1 }
    .ls-error-msg { width: 100%; font-size: 0.76rem; font-family: monospace }
    .ls-loaded-section { margin-bottom: 0.4rem }
    .ls-empty  { color: #666; padding: 0.2rem 0; font-style: italic }
    .ls-waft-section { margin-top: 0.2rem }
</style>
