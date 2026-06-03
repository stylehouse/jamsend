<script lang="ts">
    // PeelInput.svelte — inline add/edit form for any keyed thing.
    //
    // Layout (collapsed):   Label: display  [✎] [×] [+]?  [open-btn]?
    // Layout (open):        Label: [mainkey]  [sc_str]  [✓/+]  cancel
    //
    // Controlled — caller owns the values and passes handlers.
    // No $bindable; no undefined bind crashes.
    // Focused on mount when open becomes true (use:focus_first on mainkey input).
    //
    // on_edit / on_del / on_add are optional — when present, the ✎ × + buttons
    //  render here in the idle state so every call site is one <PeelInput />.

    let {
        label        = 'Point',
        mainkey      = '',
        sc_str       = '',
        open         = false,
        display      = '',
        mk_ph        = 'fuzzyName',
        sc_ph        = 'method:Name,call',
        submit_label = '+',
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
        display?:      string
        mk_ph?:        string
        sc_ph?:        string
        submit_label?: string
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

    function focus_first(node: HTMLInputElement) {
        node.focus()
        return {}
    }
</script>

<div class="pi-row">
    <span class="pi-label">{label}:</span>
    {#if open}
        <input class="pi-input pi-main"
               placeholder={mk_ph}
               value={mainkey}
               use:focus_first
               oninput={(ev) => on_mk((ev.target as HTMLInputElement).value)}
               onkeydown={handle_keydown} />
        {#if sc_ph !== ''}
            <input class="pi-input pi-sc"
                   placeholder={sc_ph}
                   value={sc_str}
                   oninput={(ev) => on_sc((ev.target as HTMLInputElement).value)}
                   onkeydown={handle_keydown} />
        {/if}
        <button class="pi-submit" onclick={on_submit}>{submit_label}</button>
        <button class="pi-cancel" onclick={on_cancel}>cancel</button>
    {:else}
        {#if display}
            <span class="pi-display">{display}</span>
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
    .pi-display {
        font-family: monospace; font-size: 0.74rem;
        color: #7a9ab0; flex: 1; white-space: nowrap; overflow: hidden;
        text-overflow: ellipsis;
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
