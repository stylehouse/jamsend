<script lang="ts">
    // Liesui.svelte — reactive UI for Lies.
    //
    // Mounted by Otro via H/{watched:UIs}/{UI:'Lies'}.
    // Receives H (the root Mundo house).
    //
    // Shows:
    //   • loaded docs — path, gen_path (or "soft only"), compile state.
    //   • pending compiles — in-flight write indicator.
    //   • compile errors surfaced from w/{compile_error:1}.
    //   • W:Such containers — wormhole-backed doc sets with full CRUD.
    //       Each W:Such (w/{W:path}) shows its open_doc list.
    //       Add path → wuch.oai({open_doc:1,path}); remove → wuch.drop(p).
    //       Mutations are detected by watch_c in Lies and throttle-saved.
    //       A new W:Such is opened via e:Lies_open_wuch {path} elvised to Lies.
    //
    // Opt toggles (write / run) are registered as stashed actions in Lies
    // and appear in the generic actions bar — no bespoke buttons here.
    //
    // < doc tabs (switch active doc)
    // < per-doc opt overrides
    // < compile history log
    // < full close on open_doc removal (drop loaded_doc, tell Lang)
    // < W:Such rename / delete

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H }: { H: House } = $props()

    // ── locate Lies's w via H.ave ───────────────────────────────────
    // Lies places its w into H.ave in setup (ave.i(w)).
    // w carries sc.w:'Lies' so we can find it reliably even before
    // it exists — the $effect re-runs whenever ave changes.
    let LS: TheC | undefined = $state()

    $effect(() => {
        const ave = H.ave
        if (!ave?.length) return
        for (const p of ave) void p.version   // touch all to track additions
        LS = ave.find((n: TheC) => n.sc.w === 'Lies') as TheC | undefined
    })

    let loaded_docs = $derived(LS ? LS.o({ loaded_doc: 1 }) as TheC[] : [])
    let pending     = $derived(LS ? (LS.o({ compile_pending: 1 }) as TheC[]).filter(p => !p.sc.done) : [])
    let errors      = $derived(LS ? LS.o({ compile_error: 1 }) as TheC[] : [])

    // W:Such containers — all {W:1} particles on the Lies w.
    // Each re-read tracks version so child mutations are reactive.
    let wuchs = $derived((() => {
        if (!LS) return []
        void LS.version
        return LS.o({ W: 1 }) as TheC[]
    })())

    function dismiss_errors() {
        if (!LS) return
        for (const e of LS.o({ compile_error: 1 }) as TheC[]) LS.drop(e)
        LS.bump_version()
    }

    // ── W:Such CRUD ──────────────────────────────────────────────────
    // add_open_doc / remove_open_doc mutate the wuch particle directly.
    // watch_c in Lies detects the change and throttle-saves to wormhole.

    let new_doc_path: Record<string, string> = $state({})  // keyed by wuch path
    let new_wuch_path = $state('')

    function add_open_doc(wuch: TheC) {
        const path = new_wuch_path_for(wuch).trim()
        if (!path) return
        wuch.oai({ open_doc: 1, path })
        wuch.bump_version()
        new_doc_path[wuch.sc.path as string] = ''
    }

    function remove_open_doc(wuch: TheC, doc: TheC) {
        wuch.drop(doc)
        wuch.bump_version()
    }

    function new_wuch_path_for(wuch: TheC): string {
        return new_doc_path[wuch.sc.path as string] ?? ''
    }

    function set_new_doc_path(wuch: TheC, v: string) {
        new_doc_path[wuch.sc.path as string] = v
    }

    // Open a brand-new W:Such by elvising Lies — same as a Plan Prep would.
    function open_new_wuch() {
        const path = new_wuch_path.trim()
        if (!path || !LS) return
        H.i_elvisto('Lies/Lies', 'e_Lies_open_wuch', { path })
        new_wuch_path = ''
    }
</script>

<div class="ls-ui">
    <div class="ls-header">
        <span class="ls-title">🔪 Lies</span>
    </div>

    {#if !LS}
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

    <!-- ── loaded docs ── -->
    {#if !loaded_docs.length}
        <div class="ls-empty">no docs open</div>
    {:else}
        <table class="ls-table">
            <thead>
                <tr>
                    <th>source path</th>
                    <th>gen path</th>
                    <th>state</th>
                </tr>
            </thead>
            <tbody>
                {#each loaded_docs as doc (doc.sc.path)}
                    {@const isPending = pending.some((p: TheC) => p.sc.path === doc.sc.path)}
                    <tr class:ls-pending={isPending}>
                        <td class="ls-path">{doc.sc.path}</td>
                        <td class="ls-gen">{doc.sc.gen_path ?? '— soft only'}</td>
                        <td class="ls-state">
                            {#if isPending}
                                <span class="ls-writing">⏳ writing…</span>
                            {:else}
                                <span class="ls-ok">✓</span>
                            {/if}
                        </td>
                    </tr>
                {/each}
            </tbody>
        </table>
    {/if}

    <!-- ── W:Such containers ── -->
    {#if wuchs.length}
        <div class="ls-wuch-section">
            <div class="ls-wuch-label">W:Such</div>
            {#each wuchs as wuch (wuch.sc.path)}
                {@const wdocs = wuch.o({ open_doc: 1 }) as TheC[]}
                {@const wmungs = wuch.o({ mung_error: 1 }) as TheC[]}
                <div class="ls-wuch">
                    <div class="ls-wuch-header">
                        <span class="ls-wuch-path">wormhole/{wuch.sc.path}/toc.snap</span>
                        <span class="ls-wuch-count">{wdocs.length} doc{wdocs.length === 1 ? '' : 's'}</span>
                    </div>

                    {#if wmungs.length}
                        <div class="ls-wuch-errors">
                            {#each wmungs as m}<div class="ls-error-msg">⛔ {m.sc.msg}</div>{/each}
                        </div>
                    {/if}

                    {#if wdocs.length}
                        <ul class="ls-wuch-docs">
                            {#each wdocs as doc (doc.sc.path)}
                                <li class="ls-wuch-doc">
                                    <span class="ls-path">{doc.sc.path}</span>
                                    <button class="ls-remove" title="remove" onclick={() => remove_open_doc(wuch, doc)}>×</button>
                                </li>
                            {/each}
                        </ul>
                    {:else}
                        <div class="ls-empty">no open_docs yet</div>
                    {/if}

                    <!-- add a doc path to this W:Such -->
                    <div class="ls-wuch-add">
                        <input
                            class="ls-input"
                            placeholder="Ghost/path/to/file.g"
                            value={new_wuch_path_for(wuch)}
                            oninput={(ev) => set_new_doc_path(wuch, (ev.target as HTMLInputElement).value)}
                            onkeydown={(ev) => ev.key === 'Enter' && add_open_doc(wuch)}
                        />
                        <button class="ls-add-btn" onclick={() => add_open_doc(wuch)}>+ add doc</button>
                    </div>
                </div>
            {/each}
        </div>
    {/if}

    <!-- ── open a new W:Such ── -->
    <div class="ls-new-wuch">
        <input
            class="ls-input"
            placeholder="Ghost/Tour  (new W:Such path)"
            bind:value={new_wuch_path}
            onkeydown={(ev) => ev.key === 'Enter' && open_new_wuch()}
        />
        <button class="ls-add-btn" onclick={open_new_wuch}>+ W:Such</button>
    </div>

    {/if}
</div>

<style>
    .ls-ui {
        font-size: 0.83rem;
        padding: 0.5rem;
        border: 1px solid #444;
        border-radius: 4px;
        background: #111;
        color: #ccc;
        min-width: 340px;
    }
    .ls-header {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        margin-bottom: 0.4rem;
    }
    .ls-title { font-weight: bold; flex: 1 }
    .ls-errors {
        background: #300;
        border: 1px solid #c44;
        border-radius: 3px;
        padding: 0.3rem 0.5rem;
        margin-bottom: 0.4rem;
        color: #f88;
        display: flex;
        flex-wrap: wrap;
        gap: 0.2rem;
        align-items: flex-start;
    }
    .ls-dismiss {
        margin-left: auto;
        background: none;
        border: none;
        color: #f88;
        cursor: pointer;
        font-size: 1rem;
        line-height: 1;
    }
    .ls-error-msg { width: 100%; font-size: 0.76rem; font-family: monospace }
    .ls-empty { color: #666; padding: 0.2rem 0; font-style: italic }
    .ls-table { width: 100%; border-collapse: collapse }
    .ls-table th { text-align: left; color: #888; font-weight: normal; padding: 0.1rem 0.3rem; border-bottom: 1px solid #333 }
    .ls-table td { padding: 0.2rem 0.3rem; border-bottom: 1px solid #1c1c1c; vertical-align: middle }
    .ls-pending td { background: #1a1a2a }
    .ls-path { font-family: monospace; font-size: 0.76rem; color: #9ab }
    .ls-gen  { font-family: monospace; font-size: 0.76rem; color: #777 }
    .ls-state { white-space: nowrap }
    .ls-writing { color: #aa8; font-style: italic }
    .ls-ok      { color: #4a8 }

    /* W:Such */
    .ls-wuch-section {
        margin-top: 0.6rem;
        border-top: 1px solid #333;
        padding-top: 0.4rem;
    }
    .ls-wuch-label {
        font-size: 0.72rem;
        color: #666;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        margin-bottom: 0.3rem;
    }
    .ls-wuch {
        background: #161620;
        border: 1px solid #2a2a3a;
        border-radius: 3px;
        padding: 0.3rem 0.4rem;
        margin-bottom: 0.3rem;
    }
    .ls-wuch-header {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        margin-bottom: 0.2rem;
    }
    .ls-wuch-path {
        font-family: monospace;
        font-size: 0.76rem;
        color: #8ab;
        flex: 1;
    }
    .ls-wuch-count { font-size: 0.72rem; color: #555 }
    .ls-wuch-errors { margin-bottom: 0.2rem }
    .ls-wuch-docs {
        list-style: none;
        margin: 0 0 0.3rem;
        padding: 0;
    }
    .ls-wuch-doc {
        display: flex;
        align-items: center;
        gap: 0.3rem;
        padding: 0.1rem 0;
        border-bottom: 1px solid #1c1c28;
    }
    .ls-wuch-doc .ls-path { flex: 1 }
    .ls-remove {
        background: none;
        border: none;
        color: #655;
        cursor: pointer;
        font-size: 0.9rem;
        line-height: 1;
        padding: 0 0.1rem;
        transition: color 0.1s;
    }
    .ls-remove:hover { color: #f66 }
    .ls-wuch-add {
        display: flex;
        gap: 0.3rem;
        margin-top: 0.2rem;
    }
    .ls-new-wuch {
        display: flex;
        gap: 0.3rem;
        margin-top: 0.5rem;
        padding-top: 0.4rem;
        border-top: 1px solid #222;
    }
    .ls-input {
        flex: 1;
        background: #0d0d14;
        border: 1px solid #333;
        border-radius: 3px;
        color: #aaa;
        font-family: monospace;
        font-size: 0.76rem;
        padding: 0.2rem 0.4rem;
        outline: none;
    }
    .ls-input:focus { border-color: #446 }
    .ls-add-btn {
        background: #1a1a2a;
        border: 1px solid #334;
        border-radius: 3px;
        color: #88a;
        cursor: pointer;
        font-size: 0.76rem;
        padding: 0.2rem 0.4rem;
        white-space: nowrap;
    }
    .ls-add-btn:hover { background: #222238; color: #aac }
</style>
