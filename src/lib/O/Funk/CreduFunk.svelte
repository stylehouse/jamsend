<script module lang="ts">
    import type { TheC } from "$lib/data/Stuff.svelte"
    import { ghost_ledger_of } from "$lib/O/lang/compile"

    // credufunk_run — a Funkcion kind's run; Lies pumps it centrally each tick.
    //   holds Storying cells — the Books flying past it.
    //   each tick, per %Book:
    //     capture the version-set from Cred_ghost_versions()  (the %GhostInclude ledger off Ghostmeta)
    //     journal it as a %Credulate  → CreduCoherence:latest
    //       if run_result is 100%     → CreduCoherence:perfection  too
    //     skip if vset unchanged      — snap churns only on real change
    //   verdict = coherence: latest's version-set == perfection's?  (is HEAD proven?)
    //   structure stamped:
    //     Funkcion:CreduFunk
    //       CreduCoherence:latest
    //         %Credulate,of_Book,finished_at,vset
    //           GhostInclude:<gen>,dige
    //       CreduCoherence:perfection / …
    export function credufunk_run(_host: TheC, funk: TheC, ww: TheC): void {
        let H: any = ww
        while (H && typeof H.Cred_ghost_versions !== "function") H = H.c?.up
        if (!H) return
        const versions = (H.Cred_ghost_versions() as { name: string; dige: string }[]) ?? []
        const vset = versions.map(v => `${v.name}@${v.dige}`).sort().join("|")   // version-set identity
        const at   = Date.now()

        credufunk_ledger(funk, H, ww, at)   // editor-centralised GhostLedger mint (pins the recompiled Codebit set)

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

    // credufunk_ledger — mint the editor's authoritative GhostLedger version for its RECOMPILED set.
    //  A Ledger version PINS {dock path → shipped ghost_dige} over the editor's req:Codebit children —
    //   exactly the docks it has compiled this session, i.e. the ONLY drift surface: an un-recompiled
    //    ghost is byte-identical committed-disk on editor and runner, so it can never be stale and is
    //     deliberately NOT pinned (a fresh editor with no edits pins nothing → every Book fires).  The
    //      editor's own Lies_ghost_get is stale (it rides pinned_stable), so the pins MUST come from the
    //       Codebit's ghost_dige, which is what a runner's Lies_ghost_get returns once it loads that gen.
    //   Editor-centralised — the sole authoritative minter; a runner has no Credence and learns versions
    //    only via the (Phase B) ledger stream.  Monotonic seq (runner uses it to tell behind→timeout from
    //     absent→fatal).  Appended only when the set moves (head guard) → one entry per real change.  Pins
    //      reuse the %GhostInclude,dige shape verbatim so the ledger maps onto whatever reads includes.
    function credufunk_ledger(funk: TheC, H: any, ww: TheC, at: number): void {
        if (H.Lies_is_editor && !H.Lies_is_editor(ww)) return   // authoritative mint is editor-only
        if (typeof H.Lies_ledger_pins !== "function") return
        const entries = H.Lies_ledger_pins(ww) as { name: string; dige: string }[]   // the recompiled Codebit set (single source)
        const { dige: ledger_dige, vset } = ghost_ledger_of(entries)
        const led = funk.oai({ GhostLedger: 1 })
        if (led.sc.head === ledger_dige) return                 // set unchanged → no new version
        const seq = Number(led.sc.next_seq ?? 0)
        const ver = led.i({ Ledger: ledger_dige, seq, at, vset })
        for (const e of entries) ver.i({ GhostInclude: e.name, dige: e.dige })
        led.sc.head     = ledger_dige
        led.sc.next_seq = seq + 1
        // whittle to a bounded recent window (keep newest by seq)
        const keep = 64
        const all  = (led.o({ Ledger: 1 }) as TheC[]).sort((a, b) => Number(a.sc.seq) - Number(b.sc.seq))
        for (const old of all.slice(0, Math.max(0, all.length - keep))) led.drop(old)
        led.bump_version(); funk.bump_version()
        // refresh the WHOLESALE export (head + every kept version's pins) and push it now.  The funk is in
        //  hand HERE, so serialising needs no fragile walk to re-find the ledger particle; the editor ships
        //   the whole thing (never a delta) and a per-runner head-guard keeps the broadcast cheap.
        const versions = (led.o({ Ledger: 1 }) as TheC[]).map(v => ({
            dige: v.sc.Ledger as string,
            seq:  Number(v.sc.seq),
            pins: (v.o({ GhostInclude: 1 }) as TheC[]).map(p => ({ name: p.sc.GhostInclude as string, dige: p.sc.dige as string })),
        }))
        ;(ww.c as any).ledger_export = { head: ledger_dige, versions }
        if (typeof H.Lies_ledger_broadcast === "function") H.Lies_ledger_broadcast(ww)
    }
</script>

<script lang="ts">
    // UI:CreduFunk — the container Funkcion kind's face; the journaling is credufunk_run above.
    //   collapsed: a oneliner — coherence summary of the Books inside.
    //   click to EXPLODE into:
    //     the illusioned child cells   — Storying lights, hosted through FunkHost
    //     the dis-illusioned journal   — the CreduCoherence / Credulate / GhostInclude tree it stashes
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"
    import MiniWaft from "$lib/O/ui/MiniWaft.svelte"
    // TheC is in scope from the module script.

    // FunkHost loaded DYNAMICALLY, not statically: CreduFunk is a kind registered in kinds.ts,
    //  and FunkHost imports that same kinds.ts (FUNK_KINDS) — a static import here would close a
    //   kinds → CreduFunk → FunkHost → kinds runtime cycle, which makes Vite full-reload the whole
    //    app on any edit to those modules instead of hot-swapping.  The async edge is its own HMR
    //     boundary, so the cycle dissolves; the child cells just mount one tick after the explode.
    let FunkHost = $state<any>(undefined)
    onMount(async () => { FunkHost = (await import("$lib/O/Funk/FunkHost.svelte")).default })

    let { H, w, funk, raw = false, examining }: {
        H: House, w: TheC, funk: TheC, raw?: boolean, examining?: TheC
    } = $props()

    let open  = $state(false)
    let cells = $derived((() => { void funk.version; return funk.o({ Funkcion: "Storying" }) as TheC[] })())
    // the CreduCoherence** roots — fed to a MiniWaft as a short, openable Travel.
    let cohRoots = $derived((() => { void funk.version; return funk.o({ CreduCoherence: 1 }) as TheC[] })())

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
                {#if FunkHost}{#each cells as c (c)}<FunkHost {H} {w} funk={c} {examining} />{/each}{/if}
            </div>
            <!-- … and the dis-illusioned C** it stashes inside itself, as a MiniWaft: a short
                 Travel whose top orb pings orbs through the whole thing and makes it editable. -->
            {#if cohRoots.length}
                <div class="cf-journal">
                    <MiniWaft roots={cohRoots} top="bolocks**" />
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
    .cf-raw-line {
        font-family: monospace; font-size: 0.72rem; color: #6a7a9a; padding: 0.1rem 0.2rem;
    }
</style>
