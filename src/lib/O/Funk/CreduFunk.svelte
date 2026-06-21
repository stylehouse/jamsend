<script module lang="ts">
    import type { TheC } from "$lib/data/Stuff.svelte"

    // credufunk_run — the RECEIVER (a monitor, pumped centrally by Lies).  CreduFunk is a
    //  container: it holds a clutch of child Funkcion:Storying cells (the Books that fly by it).
    //   Each tick it captures the editor's current Doc version-set — the GhostInclude ledger off
    //    Ghostmeta (Cred_ghost_versions) — and journals it, per Book, as a %Credulate under
    //     CreduCoherence:latest; when that Book's %run_result is 100%, also under :perfection.
    //   The cell's verdict is COHERENCE: per Book, does latest's version-set equal perfection's
    //    (i.e. is HEAD the last proven version)?  Change-detected (a %vset signature) so the
    //     snapped journal only churns on a genuine change, not every tick.
    //   Structure stamped:  Funkcion:CreduFunk
    //                         CreduCoherence:latest
    //                           %Credulate,of_Book,finished_at,vset
    //                             GhostInclude:<gen>,dige
    //                         CreduCoherence:perfection / …
    export function credufunk_run(_host: TheC, funk: TheC, ww: TheC): void {
        let H: any = ww
        while (H && typeof H.Cred_ghost_versions !== "function") H = H.c?.up
        if (!H) return
        const versions = (H.Cred_ghost_versions() as { name: string; dige: string }[]) ?? []
        const vset = versions.map(v => `${v.name}@${v.dige}`).sort().join("|")   // version-set identity
        const at   = Date.now()

        for (const cell of funk.o({ Funkcion: "Storying" }) as TheC[]) {
            const book = cell.sc.of_Book as string | undefined
            if (!book) continue
            const rr = (ww.o({ run_result: 1 }) as TheC[])
                .filter(r => r.sc.book === book)
                .sort((a, b) => Number(b.sc.at ?? 0) - Number(a.sc.at ?? 0))[0]
            const ok100 = !!rr && Number(rr.sc.ok_pct ?? (rr.sc.ok ? 1 : 0)) >= 1

            credufunk_stamp(funk, "latest", book, versions, vset, at)
            if (ok100) credufunk_stamp(funk, "perfection", book, versions, vset, at)
        }
    }

    // stamp one CreduCoherence:<state> / Credulate(of_Book) / GhostInclude subtree, change-detected.
    function credufunk_stamp(
        funk: TheC, state: string, book: string,
        versions: { name: string; dige: string }[], vset: string, at: number,
    ): void {
        const coh  = funk.oai({ CreduCoherence: state })
        const cred = coh.oai({ Credulate: 1, of_Book: book })   // one Credulate per Book under this state
        if (cred.sc.vset === vset) return                       // unchanged version-set → no churn
        for (const g of cred.o({ GhostInclude: 1 }) as TheC[]) cred.drop(g)
        for (const v of versions) cred.i({ GhostInclude: v.name, dige: v.dige })
        cred.sc.vset        = vset
        cred.sc.finished_at = at
        cred.bump_version()
        coh.bump_version(); funk.bump_version()
    }
</script>

<script lang="ts">
    // CreduFunk.svelte — the container Funkcion KIND.  Reads as a ONELINER usually (a coherence
    //  summary of the Books inside it); click to EXPLODE into both the illusioned child cells (the
    //   Storying lights, hosted through FunkHost) AND the dis-illusioned plain-C journal (the
    //    CreduCoherence / Credulate / GhostInclude tree it stashes inside itself).  The journaling
    //     itself is credufunk_run above; this is only the face.
    import type { House } from "$lib/O/Housing.svelte"
    import FunkHost from "$lib/O/Funk/FunkHost.svelte"
    // TheC is in scope from the module script.

    let { H, w, funk, raw = false, examining }: {
        H: House, w: TheC, funk: TheC, raw?: boolean, examining?: TheC
    } = $props()

    let open  = $state(false)
    let cells = $derived((() => { void funk.version; return funk.o({ Funkcion: "Storying" }) as TheC[] })())

    // per-Book coherence: latest's version-set (vset) equals perfection's → HEAD is proven.
    let books = $derived((() => {
        void funk.version
        const latest = funk.o({ CreduCoherence: "latest" })[0] as TheC | undefined
        const perf   = funk.o({ CreduCoherence: "perfection" })[0] as TheC | undefined
        return cells.map(c => {
            const book = c.sc.of_Book as string
            const lv = latest?.o({ Credulate: 1, of_Book: book })[0]?.sc.vset as string | undefined
            const pv = perf?.o({ Credulate: 1, of_Book: book })[0]?.sc.vset as string | undefined
            return { book, coherent: !!lv && lv === pv, proven: !!pv }
        })
    })())
    let coherent = $derived(books.length > 0 && books.every(b => b.coherent))
    let phase    = $derived(books.length === 0 ? "working" : coherent ? "good" : "bad")

    // the dis-illusioned journal: flat lines of the CreduCoherence/Credulate/GhostInclude tree.
    let journal = $derived((() => {
        void funk.version
        const out: { depth: number; text: string }[] = []
        for (const coh of funk.o({ CreduCoherence: 1 }) as TheC[]) {
            out.push({ depth: 0, text: `CreduCoherence:${coh.sc.CreduCoherence}` })
            for (const cred of coh.o({ Credulate: 1 }) as TheC[]) {
                out.push({ depth: 1, text: `Credulate of_Book:${cred.sc.of_Book}` })
                for (const gi of cred.o({ GhostInclude: 1 }) as TheC[])
                    out.push({ depth: 2, text: `GhostInclude:${gi.sc.GhostInclude} ${String(gi.sc.dige ?? "").slice(0, 8)}` })
            }
        }
        return out
    })())
</script>

{#if raw}
    <div class="cf-raw-line">Funkcion:CreduFunk — {books.length} book(s), {phase}</div>
{:else}
    <button class="cf cf-{phase}" onclick={() => open = !open}
        title="CreduFunk · {coherent ? 'HEAD is proven' : 'drifted from last green'} · click to {open ? 'fold' : 'explode'}">
        <span class="cf-ico">{open ? "▾" : "▸"}</span>
        <span class="cf-ico">{phase === "good" ? "⊚" : phase === "bad" ? "⊙" : "◌"}</span>
        <span class="cf-name">CreduFunk</span>
        <span class="cf-sum">{books.filter(b => b.coherent).length}/{books.length} coherent</span>
    </button>
    {#if open}
        <div class="cf-body">
            <!-- exploded: the illusioned child cells (each Book's Storying light) … -->
            <div class="cf-illusions">
                {#each cells as c (c)}<FunkHost {H} {w} funk={c} {examining} />{/each}
            </div>
            <!-- … and the dis-illusioned C** journal it stashes inside itself. -->
            {#if journal.length}
                <div class="cf-journal">
                    {#each journal as ln}
                        <div class="cf-jl" style="padding-left:{ln.depth * 0.8 + 0.2}rem">{ln.text}</div>
                    {/each}
                </div>
            {/if}
        </div>
    {/if}
{/if}

<style>
    .cf {
        display: inline-flex; align-items: center; gap: 0.35rem; margin: 0.15rem 0;
        padding: 0.2rem 0.6rem; border-radius: 5px; cursor: pointer;
        border: 1px solid #2c3450; background: #121624;
        font-family: monospace; font-size: 0.76rem; color: #9aa6cc;
        transition: filter 0.1s, border-color 0.12s;
    }
    .cf:hover { filter: brightness(1.3); border-color: #44609e; }
    .cf-ico  { font-size: 0.85rem; line-height: 1; }
    .cf-name { color: #c4ccea; }
    .cf-sum  { font-variant-numeric: tabular-nums; color: #889; }
    .cf-good { border-color: rgba(106, 208, 160, 0.4); background: rgba(106, 208, 160, 0.07); }
    .cf-good .cf-name { color: #8fe4c0; }
    .cf-bad  { border-color: rgba(214, 170, 90, 0.4); background: rgba(214, 170, 90, 0.06); }
    .cf-bad  .cf-name { color: #d8b86a; }
    .cf-working { border-color: #3a3420; color: #c4a86a; }
    .cf-body {
        margin: 0.1rem 0 0.2rem 0.4rem; padding-left: 0.5rem;
        border-left: 1px solid #2a2a3a;
    }
    .cf-illusions { display: flex; flex-wrap: wrap; gap: 0.3rem; }
    .cf-journal { margin-top: 0.25rem; }
    .cf-jl {
        font-family: monospace; font-size: 0.68rem; color: #6a7088; line-height: 1.35;
    }
    .cf-raw-line {
        font-family: monospace; font-size: 0.72rem; color: #6a7a9a; padding: 0.1rem 0.2rem;
    }
</style>
