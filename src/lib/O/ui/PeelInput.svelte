<script lang="ts">
    // PeelInput.svelte — inline add/edit form for any keyed thing.
    //
    // Layout (idle):   [○] Label: val ,sc
    //   clicking Label/val/sc navigates (on_open)
    //   clicking ○ orb opens the irow for CRUD
    //
    // Layout (open — edit existing):
    //   [○] Label: [mainkey input]  [sc input]  [✓]  cancel
    //   + irow beneath: [after input] [in input]  Point Doc What  [×]
    //
    // Layout (open — add-child):
    //   Label: [mainkey input]  [sc input]  [+]  cancel
    //   (no orb, no irow — caller controls the full row)
    //
    // Controlled — caller owns the values and passes handlers.
    // No $bindable; no undefined bind crashes.
    // display_val: mainkey value — rendered larger/brighter.
    // display_sc:  extras sc string — rendered smaller, muted, comma-prefixed when val present.
    // focus_sc=false (default): focuses mainkey on open.
    // focus_sc=true:            focuses sc field on open (mainkey already obvious or :1).
    //
    // on_crud: when present, renders the ○ orb and irow controls.
    //   on_crud.on_edit/on_del/on_add_after/on_add_in carry the actions.
    //   on_add_in_types: ItemType[] for the type shortcut buttons in the irow.

    let {
        label        = 'Point',
        mainkey      = '',
        sc_str       = '',
        open         = false,
        display_val  = '',             // idle: mainkey value (big)
        display_sc   = '',             // idle: extras sc string (small)
        mk_ph        = 'fuzzyName',
        sc_ph        = 'method:Name,call',
        submit_label = '+',
        focus_sc     = false,          // focus sc field on open instead of mainkey
        mk_is_one    = false,          // mainkey value is :1 — show label as comma-key
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
        on_open?:      () => void       // navigate — fires on label/val/sc click
        on_submit:     () => void
        on_cancel:     () => void
        on_crud?: {
            orb_open:        boolean           // is the irow currently visible
            on_orb:          () => void        // toggle orb/irow
            on_edit:         () => void        // open edit form for this item
            on_del:          () => void        // delete this item
            on_add_after?:   () => void        // create a sibling after this item
            on_add_in?:      () => void        // create a child inside this item
            add_in_types?:   string[]          // type shortcut labels for on_add_in picker
            on_pick_type?:   (t: string) => void  // pick a type from add_in_types
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
</script>

<div class="pi-wrap">
    <div class="pi-row">
        {#if on_crud}
            <!-- ○ orb — floats at the indent edge, opens irow for CRUD -->
            <button
                class="pi-orb"
                class:pi-orb-active={on_crud.orb_open}
                title="edit / delete / add"
                onclick={on_crud.on_orb}
            >○</button>
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

    <!-- irow — appears beneath the header when orb is active, for CRUD -->
    {#if on_crud?.orb_open}
        <div class="pi-irow">
            {#if on_crud.on_add_after}
                <input class="pi-input pi-irow-input"
                       placeholder="after…"
                       title="create a sibling after this"
                       onfocus={on_crud.on_add_after} />
            {/if}
            {#if on_crud.on_add_in}
                <input class="pi-input pi-irow-input"
                       placeholder="in…"
                       title="create a child inside this"
                       onfocus={on_crud.on_add_in} />
            {/if}
            {#if on_crud.add_in_types?.length && on_crud.on_pick_type}
                {#each on_crud.add_in_types as t (t)}
                    <button class="pi-irow-type" onclick={() => on_crud!.on_pick_type!(t)}>{t}</button>
                {/each}
            {/if}
            <button class="pi-irow-edit" title="edit" onclick={on_crud.on_edit}>✎</button>
            <button class="pi-irow-del"  title="delete" onclick={on_crud.on_del}>×</button>
        </div>
    {/if}
</div>

<style>
    .pi-wrap {
        /* full-width column so irow sits below without pushing siblings */
        display: flex; flex-direction: column; flex: 1; min-width: 0;
    }
    .pi-row {
        display: flex; align-items: center; gap: 0.2rem;
        min-height: 1.4rem;
    }

    /* ○ orb — sits just before the label, about button-sized */
    .pi-orb {
        background: none;
        border: 1px solid #334; border-radius: 50%;
        color: #334;
        cursor: pointer;
        font-size: 0.6rem; line-height: 1;
        width: 0.85rem; height: 0.85rem;
        padding: 0; flex-shrink: 0;
        display: flex; align-items: center; justify-content: center;
        transition: border-color 0.1s, color 0.1s;
        /* the ○ glyph itself is the border — hide the text, show the shape */
        color: transparent;
    }
    .pi-orb:hover        { border-color: #668; box-shadow: 0 0 3px #446a }
    .pi-orb-active       { border-color: #88a; box-shadow: 0 0 4px #446a }

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
    .pi-display-empty { color: #335; }

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

    /* irow — the CRUD tray that floats beneath the header */
    .pi-irow {
        display: flex; align-items: center; gap: 0.25rem;
        padding: 0.15rem 0 0.1rem 1.05rem;   /* indent past the orb */
        flex-wrap: wrap;
    }
    .pi-irow-input {
        width: 5.5rem; min-width: 0; font-size: 0.72rem;
        padding: 0.1rem 0.25rem;
    }
    /* type shortcut buttons — Point Doc What etc */
    .pi-irow-type {
        background: none; border: 1px solid #334; border-radius: 3px;
        color: #668; cursor: pointer; font-family: monospace; font-size: 0.68rem;
        padding: 0.08rem 0.25rem;
    }
    .pi-irow-type:hover { color: #99b; border-color: #558 }
    .pi-irow-edit {
        background: none; border: none; color: #445;
        cursor: pointer; font-size: 0.8rem; padding: 0 0.15rem;
        margin-left: auto;
    }
    .pi-irow-edit:hover { color: #aac }
    .pi-irow-del {
        background: none; border: none; color: #445;
        cursor: pointer; font-size: 0.8rem; padding: 0 0.15rem;
    }
    .pi-irow-del:hover { color: #f66 }
</style>
