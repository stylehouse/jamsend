<script lang="ts">
    // PeelInput.svelte — inline add/edit form for any keyed thing.
    //
    // Layout (idle):   [○] Label: val ,sc
    //   clicking ○ orb: immediately opens edit mode in this row
    //     AND overlays the abs-positioned irow below for add/delete operations.
    //   clicking Label/val/sc: navigates (on_open)
    //
    // Layout (open — edit existing, orb active):
    //   [○] Label: [mainkey input]  [sc input]  [✓]  cancel
    //   + abs irow below:
    //     [C after]   cancel  ×
    //     [C in]  Point ↳Point  Doc ↳Doc  …
    //
    // Layout (open — add-child, no orb):
    //   Label: [mainkey input]  [sc input]  [+]  cancel
    //
    // Controlled — caller owns the values and passes handlers.
    // No $bindable; no undefined bind crashes.
    // display_val: mainkey value — rendered larger/brighter.
    // display_sc:  extras sc string — rendered smaller, muted, comma-prefixed when val present.
    // focus_sc=false (default): focuses mainkey on open.
    // focus_sc=true:            focuses sc field on open (mainkey already obvious or :1).
    //
    // on_crud: present on existing items — renders ○ orb + irow.
    //   on_orb fires on_edit immediately (no intermediate state — edit mode is the orb mode).
    //   irow is abs-positioned: no layout shift, overlays siblings below.
    //
    //   irow C inputs: real text inputs, 2ch wide.
    //     on_start_after(char) — called with the first typed char; caller opens add-after form.
    //     on_start_in(char)    — called with the first typed char; caller opens add-in form.
    //     Caller then takes over with the proper add form in the ls-add-row.
    //     The char is passed so the caller can pre-seed draft_mk.

    import Orb     from "$lib/O/ui/micro/Orb.svelte"
    import DeleteX from "$lib/O/ui/micro/DeleteX.svelte"

    let {
        label        = 'Point',
        mainkey      = '',
        sc_str       = '',
        open         = false,
        display_val  = '',
        display_sc   = '',
        mk_ph        = 'fuzzyName',
        sc_ph        = 'method:Name,call',
        submit_label = '+',
        focus_sc     = false,
        mk_is_one    = false,
        on_mk        = (_v: string) => {},
        on_sc        = (_v: string) => {},
        on_open,
        on_submit,
        on_cancel,
        on_crud,
    }: {
        label?:        string
        mainkey?:      string
        sc_str?:       string
        open?:         boolean
        display_val?:  string
        display_sc?:   string
        mk_ph?:        string
        sc_ph?:        string
        submit_label?: string
        focus_sc?:     boolean
        mk_is_one?:    boolean
        on_mk?:        (v: string) => void
        on_sc?:        (v: string) => void
        on_open?:      () => void
        on_submit:     () => void
        on_cancel:     () => void
        on_crud?: {
            orb_open:        boolean
            on_orb:          () => void       // toggles orb; also calls start_edit immediately
            on_cancel_orb:   () => void       // cancel both edit and irow together
            on_del:          () => void
            // C inputs: real inputs — first char typed triggers the add form
            on_start_after?: (char: string) => void   // open add-sibling form, seed with char
            on_start_in?:    (char: string) => void   // open add-child form, seed with char
            // type shortcut buttons still available for picking without typing
            on_pick_after_type?: (t: string) => void
            on_pick_in_type?:    (t: string) => void
            add_types?:          string[]
        }
    } = $props()

    function handle_keydown(ev: KeyboardEvent) {
        if (ev.key === 'Enter')  { ev.preventDefault(); on_submit() }
        if (ev.key === 'Escape') { ev.preventDefault(); on_cancel() }
    }

    // focus_first(node, yes) — use:focus_first={true/false} as a conditional action.
    //   Svelte always calls the action fn; the boolean gates whether focus fires.
    function focus_first(node: HTMLInputElement, yes: boolean = true) {
        if (yes) node.focus()
        return {}
    }

    // irow C input handlers — capture the first char and hand off to caller
    function irow_input(ev: InputEvent, on_start?: (char: string) => void) {
        const inp = ev.target as HTMLInputElement
        const val = inp.value
        inp.value = ''   // clear immediately — caller's add form takes over
        if (val && on_start) on_start(val)
    }
</script>

<!-- pi-wrap: position:relative anchor for the abs irow -->
<div class="pi-wrap">
    <div class="pi-row">
        {#if on_crud}
            <!-- ○ orb — opens edit mode immediately (no intermediate picker state). -->
            <Orb active={on_crud.orb_open} onclick={on_crud.on_orb} />
        {/if}

        <span class="pi-label">{label}{open ? ':' : mk_is_one ? (display_val ? ',' : '') : ':'}</span>

        {#if open}
            <input class="pi-input pi-main"
                   placeholder={mk_ph}
                   value={mainkey}
                   use:focus_first={!focus_sc}
                   oninput={(ev) => on_mk((ev.target as HTMLInputElement).value)}
                   onkeydown={handle_keydown} />
            {#if sc_ph !== ''}
                <input class="pi-input pi-sc"
                       placeholder={sc_ph}
                       value={sc_str}
                       use:focus_first={focus_sc}
                       oninput={(ev) => on_sc((ev.target as HTMLInputElement).value)}
                       onkeydown={handle_keydown} />
            {/if}
            <button class="pi-submit" onclick={on_submit}>{submit_label}</button>
            <button class="pi-cancel" onclick={on_cancel}>cancel</button>
        {:else}
            <!-- whole label+val area is the navigation click target -->
            <button class="pi-nav-area" onclick={on_open ?? (() => {})}>
                {#if display_val}
                    <span class="pi-display-val">{display_val}</span>
                {/if}
                {#if display_sc}
                    <span class="pi-display-sc">{display_val ? ',' : ''}{display_sc}</span>
                {/if}
                {#if !display_val && !display_sc}
                    <span class="pi-display-val pi-display-empty">·</span>
                {/if}
            </button>
        {/if}
    </div>

    <!-- irow — abs-positioned overlay, no layout shift.
         Two rows, top-to-bottom in document order — an inner child lands before a
         later sibling, so the child row reads first:
           row 1 (child level, stepped in): [C in input]  ↳type buttons
           row 2 (sibling level):           [C after input]  type buttons  cancel  ×
         The visual indent on the child row signals the level difference. -->
    {#if on_crud?.orb_open}
        <div class="pi-irow">
            <!-- row 1: child-level operations — visually stepped in -->
            {#if on_crud.on_start_in || on_crud.on_pick_in_type}
                <div class="pi-irow-row pi-irow-row-in">
                    <input class="pi-input pi-irow-nano"
                           placeholder="C"
                           title="type to add a child inside this"
                           oninput={(ev) => irow_input(ev as InputEvent, on_crud!.on_start_in)} />
                    {#if on_crud.add_types?.length && on_crud.on_pick_in_type}
                        {#each on_crud.add_types as t (t)}
                            <button class="pi-irow-type pi-irow-type-in"
                                    title="add {t} inside"
                                    onclick={() => on_crud!.on_pick_in_type!(t)}>↳{t}</button>
                        {/each}
                    {/if}
                </div>
            {/if}

            <!-- row 2: sibling-level operations — also carries cancel + delete -->
            <div class="pi-irow-row">
                {#if on_crud.on_start_after || on_crud.on_pick_after_type}
                    <input class="pi-input pi-irow-nano"
                           placeholder="C"
                           title="type to add a sibling after this"
                           oninput={(ev) => irow_input(ev as InputEvent, on_crud!.on_start_after)} />
                    {#if on_crud.add_types?.length && on_crud.on_pick_after_type}
                        {#each on_crud.add_types as t (t)}
                            <button class="pi-irow-type"
                                    title="add {t} after"
                                    onclick={() => on_crud!.on_pick_after_type!(t)}>{t}</button>
                        {/each}
                    {/if}
                {/if}
                <button class="pi-irow-cancel" onclick={on_crud.on_cancel_orb}>cancel</button>
                <DeleteX ondelete={on_crud.on_del} />
            </div>
        </div>
    {/if}
</div>

<style>
    .pi-wrap {
        display: flex; flex-direction: column; flex: 1; min-width: 0;
        /* anchor for the abs irow — must not be static */
        position: relative;
    }
    .pi-row {
        display: flex; align-items: center; gap: 0.2rem;
        min-height: 1.4rem;
    }

    .pi-label {
        font-family: monospace; font-size: 0.74rem;
        color: #556; flex-shrink: 0; white-space: nowrap;
    }

    /* nav area — transparent click target covering label+val+sc */
    .pi-nav-area {
        background: none; border: none; padding: 0;
        display: flex; align-items: center; gap: 0.2rem;
        cursor: pointer; flex: 1; min-width: 0;
        text-align: left;
    }
    .pi-nav-area:hover .pi-display-val { color: #c0d8e8 }
    .pi-nav-area:hover .pi-display-sc  { color: #7a9aaa }

    .pi-display-val {
        font-family: monospace; font-size: 0.82rem;
        color: #9ab8cc; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    }
    .pi-display-sc {
        font-family: monospace; font-size: 0.72rem;
        color: #5a7a8a; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        flex: 1;
    }
    .pi-display-empty { color: #335 }

    .pi-input {
        background: #0d0d14; border: 1px solid #333; border-radius: 3px;
        color: #aaa; font-family: monospace; font-size: 0.76rem;
        padding: 0.2rem 0.35rem; outline: none;
    }
    .pi-input:focus { border-color: #446 }
    .pi-main { width: 9rem }
    .pi-sc   { flex: 1; min-width: 5rem }

    .pi-submit {
        background: #1a1a2a; border: 1px solid #334; border-radius: 3px;
        color: #88a; cursor: pointer; font-size: 0.76rem;
        padding: 0.15rem 0.3rem; white-space: nowrap; flex-shrink: 0;
    }
    .pi-submit:hover { background: #222238; color: #aac }
    /* cancel always lives at the right end */
    .pi-cancel {
        background: none; border: none; color: #555;
        cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.3rem;
        margin-left: auto; flex-shrink: 0;
    }
    .pi-cancel:hover { color: #999 }

    /* irow — absolute overlay, no layout shift.
       top: 100% puts it flush below the pi-row.
       z-index clears it above the next sibling rows. */
    .pi-irow {
        position: absolute; top: 100%; left: 0;
        z-index: 10;
        display: flex; flex-direction: column; gap: 0;
        background: #0e0e1a; border: 1px solid #2a2a40; border-radius: 3px;
        padding: 0.15rem 0.3rem 0.18rem;
        min-width: max-content;
        box-shadow: 0 3px 10px #0008;
    }

    /* each row in the irow is a flex line */
    .pi-irow-row {
        display: flex; align-items: center; gap: 0.2rem;
    }
    /* child row sits first now (document order); its padding-left reads as indent */
    .pi-irow-row-in {
        padding-left: 0.5rem;   /* echo the .ls-items indent */
    }
    /* the gap that reads as the level step belongs between child row and the
       sibling row that follows it */
    .pi-irow-row-in + .pi-irow-row {
        margin-top: 0.2em;
    }

    /* nano inputs — 2ch wide, real inputs */
    .pi-irow-nano {
        width: 2ch; min-width: 0;
        font-size: 0.72rem; padding: 0.08rem 0.2rem;
    }

    .pi-irow-cancel {
        background: none; border: none; color: #556;
        cursor: pointer; font-size: 0.72rem; padding: 0.05rem 0.2rem;
    }
    .pi-irow-cancel:hover { color: #999 }

    /* type shortcut buttons */
    .pi-irow-type {
        background: none; border: 1px solid #2a3344; border-radius: 3px;
        color: #557; cursor: pointer; font-family: monospace; font-size: 0.66rem;
        padding: 0.06rem 0.22rem; white-space: nowrap;
    }
    .pi-irow-type:hover      { color: #99b; border-color: #446 }
    /* in-type buttons slightly cooler tint to distinguish after vs in */
    .pi-irow-type-in         { border-color: #223344; color: #446 }
    .pi-irow-type-in:hover   { color: #7ab; border-color: #336 }
</style>
