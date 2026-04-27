<script lang="ts">
    // LieSurgerui.svelte — reactive UI for LieSurgery.
    //
    // Mounted by Otro via H/{watched:UIs}/{UI:'LieSurgery'}.
    // Receives H (the root Mundo house).
    //
    // Shows:
    //   • loaded docs — path, gen_path (or "soft only"), compile state.
    //   • pending compiles — in-flight write indicator.
    //   • compile errors surfaced from w/{compile_error:1}.
    //
    // Opt toggles (write / run) are registered as stashed actions in LieSurgery
    // and appear in the generic actions bar — no bespoke buttons here.
    //
    // < doc tabs (switch active doc)
    // < per-doc opt overrides
    // < compile history log

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H }: { H: House } = $props()

    // ── locate LieSurgery's w via H.ave ───────────────────────────────────
    // LieSurgery places its w into H.ave in setup (ave.i(w)).
    // w carries sc.w:'LieSurgery' so we can find it reliably even before
    // it exists — the $effect re-runs whenever ave changes.
    let LS: TheC | undefined = $state()

    $effect(() => {
        const ave = H.ave
        if (!ave?.length) return
        for (const p of ave) void p.version   // touch all to track additions
        LS = ave.find((n: TheC) => n.sc.w === 'LieSurgery') as TheC | undefined
    })

    let loaded_docs = $derived(LS ? LS.o({ loaded_doc: 1 }) as TheC[] : [])
    let pending     = $derived(LS ? (LS.o({ compile_pending: 1 }) as TheC[]).filter(p => !p.sc.done) : [])
    let errors      = $derived(LS ? LS.o({ compile_error: 1 }) as TheC[] : [])

    function dismiss_errors() {
        if (!LS) return
        for (const e of LS.o({ compile_error: 1 }) as TheC[]) LS.drop(e)
        LS.bump_version()
    }
</script>

<div class="ls-ui">
    <div class="ls-header">
        <span class="ls-title">🔪 LieSurgery</span>
    </div>

    {#if !LS}
        <div class="ls-empty">waiting for LieSurgery…</div>
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
</style>
