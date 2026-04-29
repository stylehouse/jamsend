<script lang="ts">
    // Liesui.svelte — reactive UI for Lies.
    //
    // Reactivity strategy
    // ───────────────────
    //   H.ave fires every think() tick (Housing reassigns the array whenever any
    //   enrolled particle bumps its version, which Lies does on every tick).
    //   The $effect runs on every such reassignment, but update_from_Lies is
    //   throttled so the actual $state writes (and thus DOM updates) happen at
    //   most once per interval — keeping focused inputs stable between ticks.
    //
    //   The Waft tree renders <WaftComp> components.  Components survive parent
    //   re-renders as long as their key (waft.sc.Waft) is stable.  All form state
    //   lives inside WaftComp.
    //
    //   Doc header rows use DocRow.svelte, which reads doc.version and w.version
    //   directly — so loaded/pending state stays live without Liesui re-rendering.
    //   (Previously they were a snippet capturing stale closure state.)

    import type { House }   from "$lib/O/Housing.svelte"
    import type { TheC }    from "$lib/data/Stuff.svelte"
    import { throttle }     from "$lib/Y.svelte"
    import WaftComp         from "$lib/O/ui/Waft.svelte"
    import DocRow           from "$lib/O/ui/DocRow.svelte"

    let { H }: { H: House } = $props()

    // ── state ─────────────────────────────────────────────────────────
    let Lies:        TheC | undefined = $state()
    let loaded_docs: TheC[]           = $state([])
    let errors:      TheC[]           = $state([])
    let all_wafts:   TheC[]           = $state([])
    // pending_paths removed — DocRow derives pending state from w.version directly

    // Throttled updater — reads structural arrays from Lies's w at most
    // once per interval rather than on every think() tick.  This prevents
    // rapid $state writes from rebuilding DOM nodes and yanking focus.
    //
    // Async: waits for the top House's beliefs mutex to release before reading.
    // Without this, H.ave fires mid-think() and we'd read partial state while
    // ghosts are still mid-tick.  The mutex promise resolves as soon as the
    // current beliefs() call finishes, at which point w/* is in a sane state.
    const update_from_Lies = throttle(async (found: TheC) => {
        // < not sure this is needed
        //    and throttle() should check we're not waiting ages
        //   throttle(fn,delay,{notnow:1}) should be perfected, called delay_throttle()
        //    right now it breaks this component completely if notnow is on.
        // await H.all_clear()
        loaded_docs = found.o({ loaded_doc: 1 })     as TheC[]
        errors      = found.o({ compile_error: 1 })  as TheC[]
        all_wafts   = found.o({ Waft: 1 })           as TheC[]
    }, 150)

    $effect(() => {
        const ave = H.ave
        if (!ave?.length) return
        const found = ave.find((n: TheC) => n.sc.w === 'Lies') as TheC | undefined
        if (!found) return
        if (found !== Lies) {
            console.log(`🔪 Liesui: Lies found`)
            Lies = found
        }
        update_from_Lies(found)
    })

    // ── header state ─────────────────────────────────────────────────
    let waft_input_open = $state(false)
    let new_waft_path   = $state('')

    function toggle_waft_input() {
        waft_input_open = !waft_input_open
        if (!waft_input_open) new_waft_path = ''
    }
    function submit_new_waft() {
        const path = new_waft_path.trim()
        if (!path) return
        H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path })
        new_waft_path = ''
        waft_input_open = false
    }
    function fire_now_waft() {
        H.i_elvisto('Lies/Lies', 'Lies_now_Waft', {})
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

    <!-- ── header ── -->
    <div class="ls-header">
        <span class="ls-title">🔪 Lies</span>
        <div class="ls-header-btns">
            <button class="ls-hdr-btn" class:ls-hdr-btn-active={waft_input_open}
                    onclick={toggle_waft_input}>+ Waft</button>
            <button class="ls-hdr-btn" onclick={fire_now_waft} title="Spawn hourly Look waft">+ Now</button>
        </div>
    </div>

    {#if waft_input_open}
        <div class="ls-waft-input-row">
            <input class="ls-input ls-waft-path-input" bind:value={new_waft_path}
                onkeydown={(ev) => { if (ev.key==='Enter') submit_new_waft(); if (ev.key==='Escape') toggle_waft_input() }}
                use:focus_on_mount />
            <button class="ls-add-btn" onclick={submit_new_waft} disabled={!new_waft_path.trim()}>+</button>
        </div>
    {/if}

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

    <!-- ── loaded docs flat list ── -->
    <!-- Shows w/{loaded_doc:1} entries — confirmation that Lies handed each
         doc to Lang.  DocRow reads w.version directly so pending state is live. -->
    {#if loaded_docs.length}
        <div class="ls-loaded-section">
            {#each loaded_docs as ld (ld.sc.path)}
                <DocRow w={Lies} doc={ld} />
            {/each}
        </div>
    {:else}
        <div class="ls-empty">no docs open</div>
    {/if}

    <!-- ── Waft tree ── -->
    <!-- Pass Lies (the w particle) as w so DocRow inside WaftComp has live state. -->
    {#if all_wafts.length}
        <div class="ls-waft-section">
            {#each all_wafts as waft (waft.sc.Waft)}
                <WaftComp {H} w={Lies} {waft} depth={0}
                    on_active={set_waft_active}
                    on_delete={delete_waft} />
            {/each}
        </div>
    {/if}

    {/if}
</div>

<script module>
    export function focus_on_mount(node: HTMLElement) {
        node.focus()
        if (node instanceof HTMLInputElement) node.select()
        return {}
    }
</script>

<style>
    .ls-ui {
        font-size: 0.83rem; padding: 0.5rem;
        border: 1px solid #444; border-radius: 4px;
        background: #111; color: #ccc; min-width: 360px;
    }
    .ls-header { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.3rem }
    .ls-title  { font-weight: bold; flex-shrink: 0 }
    .ls-header-btns { display: flex; gap: 0.25rem; margin-left: auto }
    .ls-hdr-btn {
        background: #1a1a28; border: 1px solid #334; border-radius: 3px;
        color: #88a; cursor: pointer; font-size: 0.74rem; padding: 0.15rem 0.4rem;
    }
    .ls-hdr-btn:hover     { background: #222238; color: #aac }
    .ls-hdr-btn-active    { background: #222238; border-color: #556; color: #aac }
    .ls-waft-input-row    { display: flex; gap: 0.25rem; margin-bottom: 0.3rem }
    .ls-waft-path-input   { flex: 1 }
    .ls-errors {
        background: #300; border: 1px solid #c44; border-radius: 3px;
        padding: 0.3rem 0.5rem; margin-bottom: 0.4rem;
        color: #f88; display: flex; flex-wrap: wrap; gap: 0.2rem; align-items: flex-start;
    }
    .ls-dismiss   { margin-left: auto; background: none; border: none; color: #f88; cursor: pointer; font-size: 1rem; line-height: 1 }
    .ls-error-msg { width: 100%; font-size: 0.76rem; font-family: monospace }
    .ls-loaded-section { margin-bottom: 0.4rem }
    .ls-empty  { color: #666; padding: 0.2rem 0; font-style: italic }
    .ls-waft-section { margin-top: 0.4rem; border-top: 1px solid #222; padding-top: 0.3rem }

    .ls-input {
        background: #0d0d14; border: 1px solid #333; border-radius: 3px;
        color: #aaa; font-family: monospace; font-size: 0.76rem;
        padding: 0.2rem 0.35rem; outline: none;
    }
    .ls-input:focus { border-color: #446 }
    .ls-add-btn {
        background: #1a1a2a; border: 1px solid #334; border-radius: 3px;
        color: #88a; cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.4rem;
        white-space: nowrap; flex-shrink: 0;
    }
    .ls-add-btn:hover    { background: #222238; color: #aac }
    .ls-add-btn:disabled { opacity: 0.35; cursor: default }
</style>
