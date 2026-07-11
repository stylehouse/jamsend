<script lang="ts">
    // ui/DocStorying.svelte — an INLINE Credence light, mounted right in the code editor at a
    //  Run_A_<Book> def (placed by Langui's bookRunField).  It reuses the Storying Funkcion face
    //   verbatim; this wrapper only:
    //     (a) holds an OFF-TREE view-model funk cell (never enters the snap),
    //     (b) refreshes that cell's verdict from the editor's ambient w:Lies run_results, and
    //     (c) shows the STALE badge — the anti-brain-rot rule: a green light is trustworthy ONLY
    //          for the ghost version ON SCREEN, so we compare the run's ghost_dige (verdict.dige)
    //           to the dock's LIVE ghost_dige (Lies_ghost_get).  Both are the full source⊗compiler
    //            identity minted in compile.ts:ghost_dige_of.  Mismatch → ⧗ stale (re-run to trust).
    import type { House } from "$lib/O/Housing.svelte"
    import { _C, type TheC } from "$lib/data/Stuff.svelte"
    import Storying, { storying_run } from "$lib/O/Funk/Storying.svelte"

    let { H, of_Book, dock_path }: { H: House, of_Book: string, dock_path: string } = $props()

    // Off-tree view-model: a Storying funk cell that lives only for this widget.  storying_run
    //  stamps its c.verdict; Storying.svelte renders off funk.version.  Minted once per mount.
    const funk: TheC = _C({ Funkcion: "Storying", of_Book })

    // The editor's ambient w:Lies — where run_result frames land and Lies_become_book routes.
    //  (Storying.strike() reaches Lies via elvisto, needing only H; storying_run needs this w.)
    let liesW = $derived.by(() => {
        const A = (H.o({ A: "Lies" })[0] ?? H.top_House().o({ A: "Lies" })[0]) as TheC | undefined
        return A?.o({ w: "Lies" })[0] as TheC | undefined
    })

    // Refresh the verdict whenever a run_result may have landed — w:Lies bumps its version on
    //  every inbound frame, so this re-runs the (dedup-guarded) verdict computer.
    $effect(() => {
        const w = liesW
        if (!w) return
        void w.version
        storying_run(funk, funk, w)   // storying_run(_host, funk, ww) — host arg is unused
    })

    // STALE: the run's ghost_dige vs the dock's live ghost_dige.  Unknown (no run yet, or a
    //  become_book run that carried no version) → NOT stale, just not-yet-knowable.  Re-derives
    //   on a fresh verdict (funk.version) and on channel activity (liesW.version) so a recompile
    //    that moves the live version is noticed within a beat.
    let stale = $derived.by(() => {
        void funk.version
        void liesW?.version
        const run  = (funk.c.verdict as any)?.dige as string | undefined
        const live = H.Lies_ghost_get?.(dock_path) as string | undefined
        return !!(run && live && run !== live)
    })
</script>

<span class="doc-storying" class:stale>
    <Storying {H} {funk} />
    {#if stale}
        <span class="ds-stale" title="this verdict is for an OLDER ghost version than the code on screen — re-run to trust it">⧗ stale</span>
    {/if}
</span>

<style>
    .doc-storying {
        display: inline-flex; align-items: center; gap: 0.3rem;
        vertical-align: middle; margin-left: 0.5rem;
    }
    .doc-storying.stale { filter: saturate(0.4) brightness(0.85); }
    .ds-stale {
        font-family: monospace; font-size: 0.6rem; font-weight: bold;
        letter-spacing: 0.03em; color: #e8c07a;
        background: rgba(180, 130, 40, 0.18);
        border: 1px solid rgba(180, 130, 40, 0.4);
        padding: 0.02rem 0.3rem; border-radius: 3px;
    }
</style>
