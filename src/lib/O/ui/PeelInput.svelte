<script lang="ts">
    // PeelInput.svelte — inline add/edit form for any keyed thing.
    //
    // Layout (collapsed):   Label: [val] [,sc]  [✎] [×] [+]?  [open-btn]?
    // Layout (open):        Label: [mainkey input]  [sc input]  [✓/+]  cancel
    //
    // Controlled — caller owns the values and passes handlers.
    // No $bindable; no undefined bind crashes.
    // display_val: mainkey value — rendered larger/brighter.
    // display_sc:  extras sc string — rendered smaller, muted, comma-prefixed when val present.
    // focus_sc=false (default): focuses mainkey on open.
    // focus_sc=true:            focuses sc field on open (mainkey already obvious or :1).
    //
    // on_edit / on_del / on_add are optional — when present, the ✎ × + buttons
    //  render here in the idle state so every call site is one <PeelInput />.

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
        on_mk        = (_v: string) => {},   // mainkey changed
        on_sc        = (_v: string) => {},   // sc_str changed
        on_open,
        on_submit,
        on_cancel,
        on_edit,
        on_del,
        on_add,
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
        on_edit?:      () => void   // renders ✎ when idle
        on_del?:       () => void   // renders × when idle
        on_add?:       () => void   // renders + when idle (What header only)
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

<div class="pi-row">
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
        {#if display_val}
            <span class="pi-display-val">{display_val}</span>
        {/if}
        {#if display_sc}
            <span class="pi-display-sc">{display_val ? ',' : ''}{display_sc}</span>
        {/if}
        {#if on_open}
            <button class="pi-add-btn" onclick={on_open}>+</button>
        {/if}
        {#if on_edit}
            <button class="ls-icon-btn" title="edit {label}" onclick={on_edit}>✎</button>
        {/if}
        {#if on_del}
            <button class="ls-icon-btn ls-del-btn" title="delete {label}" onclick={on_del}>×</button>
        {/if}
        {#if on_add}
            <button class="ls-icon-btn ls-add-btn-icon" title="add child" onclick={on_add}>+</button>
        {/if}
    {/if}
</div>

<style>
    .pi-row {
        display: flex; align-items: center; gap: 0.2rem;
        min-height: 1.4rem; flex-wrap: wrap;
    }
    .pi-label {
        font-family: monospace; font-size: 0.74rem;
        color: #556; flex-shrink: 0; white-space: nowrap;
    }
    .pi-display-val {
        font-family: monospace; font-size: 0.82rem;
        color: #9ab8cc; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    }
    .pi-display-sc {
        font-family: monospace; font-size: 0.72rem;
        color: #5a7a8a; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        flex: 1;
    }
    .pi-add-btn {
        background: none; border: none; color: #448;
        cursor: pointer; font-size: 0.8rem; padding: 0 0.15rem; flex-shrink: 0;
    }
    .pi-add-btn:hover { color: #88a }
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
</style>
