<script lang="ts">
    // ThangShelf.svelte — UI rack for every w:Thangs worker on a House.
    //
    // ── what shows ──────────────────────────────────────────────────────────
    //   For each {w:'Thangs', thangs:'<table>'} found anywhere under H,
    //   one section: header (table name + count), list of thang particles
    //   rendered through {@render thang(t)} (or a default name+× card),
    //   and an Add input.
    //
    // ── usage ───────────────────────────────────────────────────────────────
    //   <ThangShelf {H} />
    //   or with a custom per-thang renderer:
    //     <ThangShelf {H}>
    //       {#snippet thang(t)}
    //         …whatever, t.sc.stashed is your bag…
    //       {/snippet}
    //     </ThangShelf>
    //
    // ── what's not here ─────────────────────────────────────────────────────
    //   Start/stop buttons (the old Thingness.svelte). Per-thang lifecycle
    //   belongs to whatever class concretes a thang (eg DirectoryShare),
    //   not to the storage ghost. Add it in the snippet when needed.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import type { Snippet } from "svelte"
    import Thang from "./Thang.svelte"

    let { H, thang }: { H: House, thang?: Snippet<[TheC]> } = $props()

    // collect all w:Thangs workers across all agencies on H
    //  (purely derived — no stashing on H, this re-runs as workers arrive)
    let workers = $derived(
        (H.o({ A: 1 }) as TheC[]).flatMap(A =>
            (A.o({ w: 'Thangs' }) as TheC[]).map(w => ({ A, w }))
        )
    )

    // input state, keyed by A.sc.A + '/' + table — survives across workers
    let inputs = $state<Record<string, string>>({})

    async function add(A: TheC, w: TheC) {
        const key = `${A.sc.A}/${w.sc.thangs}`
        const name = (inputs[key] ?? '').trim()
        if (!name) return
        try {
            await H.thang_add(w, name)
            inputs[key] = ''
        } catch (err) {
            console.warn(`thang_add ${name}:`, err)
            // surface inline rather than alert — UI re-derives if w changes
            const wNow = w as TheC
            wNow.oai({ error: String(err) })
        }
    }

    async function remove(w: TheC, name: string) {
        if (!confirm(`Remove "${name}"?`)) return
        await H.thang_remove(w, name)
    }
</script>

{#each workers as { A, w } (A.sc.A + '/' + w.sc.thangs)}
    {@const table = w.sc.thangs as string}
    {@const k = `${A.sc.A}/${table}`}
    {@const thangs = w.ob({ thang: 1 })}
    <section class="shelf">
        <header>
            <strong>{table}</strong>
            <small class="count">{thangs.length}</small>
            {#if w.oa({ error: 1 })}
                <small class="err" title={String(w.oa({ error: 1 })?.sc.error)}>!</small>
            {/if}
        </header>

        <ul class="rack">
            {#each thangs as t (t.sc.name)}
                <li>
                    <Thang {t} on_remove={() => remove(w, t.sc.name as string)}>
                        {#if thang}{@render thang(t)}{/if}
                    </Thang>
                </li>
            {/each}
        </ul>

        <div class="add">
            <input
                bind:value={inputs[k]}
                onkeydown={(e) => e.key === 'Enter' && add(A, w)}
                placeholder="Add to {table}…"
            />
            <button
                onclick={() => add(A, w)}
                disabled={!inputs[k]?.trim()}
            >Add</button>
        </div>
    </section>
{/each}

<style>
    .shelf {
        border: 1px solid #ddd;
        border-radius: 6px;
        padding: 0.5rem 0.75rem;
        margin: 0.5rem 0;
        background: rgba(255, 255, 255, 0.05);
    }
    header {
        display: flex;
        gap: .5rem;
        align-items: baseline;
        margin-bottom: .5rem;
    }
    .count { opacity: .55; font-size: .85em; }
    .err {
        color: #c33;
        font-weight: bold;
        margin-left: .25rem;
        cursor: help;
    }
    .rack {
        list-style: none;
        padding: 0;
        margin: 0 0 .5rem;
        display: flex;
        flex-direction: column;
        gap: .35rem;
    }
    .add {
        display: flex;
        gap: .5rem;
    }
    .add input {
        flex: 1;
        padding: .4rem .5rem;
        border: 1px solid #ccc;
        border-radius: 4px;
        background: #091409;
        color: lightslategray;
        font-size: .9rem;
    }
    .add input:focus { outline: none; border-color: #4CAF50; }
    .add button {
        padding: .4rem .9rem;
        background: #4CAF50;
        color: #fff;
        border: 0;
        border-radius: 4px;
        cursor: pointer;
        font-size: .9rem;
    }
    .add button:hover:not(:disabled) { background: #45a049; }
    .add button:disabled { background: #ccc; cursor: not-allowed; }
</style>
