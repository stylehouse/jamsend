<script module lang="ts">
    import type { TheC } from "$lib/data/Stuff.svelte"

    // storytimes_run — the StoryTimes station's BEHAVIOUR.  StoryTimes is a *station*, not a
    //  test-light: one button that runs ALL the %of_Book cells in its scope, in sequence,
    //   never stopping for an !ok — the Credulation sweep (Editron §5f).  Unlike Ballistics
    //    (a struck action that fires once), the sweep must be DRIVEN: the runner is a single
    //     sequential Story Run, so the station chains become_book→run_result, advancing on each
    //      verdict.  That driving lives where the channel methods live (LiesFunk,
    //       Lies_storytimes_drive); this shim is the pumped tick — it climbs to the House and
    //        hands off.  Registered as a kind WITH a run, so Lies_instantiate_funkcions binds it
    //         and the central Funkcions pump ticks it every beat (idle until struck).
    export function storytimes_run(host: TheC, funk: TheC, ww: TheC): void {
        let H: any = ww
        while (H && typeof H.Lies_storytimes_drive !== "function") H = H.c?.up
        if (H) H.Lies_storytimes_drive(host, funk, ww)
    }

    // the What this station sweeps (its group), or "all" when it rides the Waft root /
    //  carries %all — the board-wide run-everything.  Used only for the label.
    function scope_name(funk: TheC): string {
        if (funk.sc.all) return "all"
        let node: any = funk.c?.up
        while (node && node.sc?.What === undefined && node.sc?.Waft === undefined) node = node.c?.up
        return (node?.sc?.What as string) ?? "all"
    }
</script>

<script lang="ts">
    // StoryTimes.svelte — the StoryTimes Funkcion KIND: the run-all station.  A click arms a
    //  sweep (funk.c.sweep = {phase:'arm'}); the pumped storytimes_run / Lies_storytimes_drive
    //   builds the queue from this station's scope and chains the become_book runs, settling each
    //    Storying cell beside it.  This component is only the face: a button + the live tally,
    //     read off the off-snap funk.c.sweep the driver stamps.
    import type { House } from "$lib/O/Housing.svelte"

    let { H, w, funk, raw = false }: { H: House, w: TheC, funk: TheC, raw?: boolean } = $props()

    // funk.c.sweep is stamped off-snap by the driver; track funk.version.
    let s = $derived((() => { void funk.version; return (funk.c.sweep as any) ?? { phase: "idle" } })())
    let scope = $derived(scope_name(funk))
    // how many runners are on the phone (connected runner Piers).  The sweep fans out across
    //  them as the channel gains per-runner addressing; today it drives one at a time.
    let runners = $derived((() => { void w?.version; return (H as any).Lies_runner_count?.(w) ?? 0 })())

    let pass = $derived(Object.values((s.results ?? {}) as Record<string, string>).filter(v => v === "pass").length)
    let fail = $derived(Object.values((s.results ?? {}) as Record<string, string>).filter(v => v === "fail").length)
    let done = $derived(pass + fail)
    let running = $derived(s.phase === "arm" || s.phase === "running")
    let stopped = $derived(s.stopped === true)

    function strike() {
        if (running) return                 // a sweep is already underway — ignore re-clicks
        funk.c.sweep = { phase: "arm" }
        funk.bump_version()
    }

    // turn the sweep off mid-run: settle the station as done-but-stopped, keeping whatever verdicts
    //  already landed and dropping the rest of the queue so nothing more dispatches.  One become_book
    //   already on a runner finishes on its own — we only stop sequencing.  The driver early-returns
    //    on phase:'done', so the pump goes quiet; a later click re-arms a fresh sweep.
    function stop(e: MouseEvent) {
        e.stopPropagation()
        funk.c.sweep = { phase: "done", results: s.results ?? {}, total: s.total ?? 0, stopped: true }
        funk.bump_version()
    }
</script>

{#if raw}
    <div class="st-raw">Funkcion:StoryTimes{funk.sc.all ? " (all)" : ` → ${scope}`}</div>
{:else}
    <span class="st-wrap">
    <button class="st" class:st-running={running} class:st-done={s.phase === "done"} class:st-stopped={stopped}
        onclick={strike}
        title="StoryTimes · sweep every Book in {funk.sc.all ? 'this board' : `What:${scope}`}, in sequence, recording each verdict — on {runners || 'no'} runner{runners === 1 ? '' : 's'}">
        <span class="st-ico">{running ? "◴" : stopped ? "⊘" : s.phase === "done" ? "✓" : "⇶"}</span>
        <span class="st-name">{funk.sc.all ? "run all" : `run ${scope}`}</span>
        {#if running}
            <span class="st-prog">{done}/{s.total ?? "?"}</span>
        {:else if s.phase === "done"}
            <span class="st-tally"><span class="st-pass">✓{pass}</span> <span class="st-fail">✗{fail}</span>{#if stopped}<span class="st-stopnote"> ⊘ stopped</span>{/if}</span>
        {/if}
        <span class="st-runners" title="{runners} runner{runners === 1 ? '' : 's'} on the phone">⌥{runners}</span>
    </button>
    {#if running}
        <button class="st-stop" onclick={stop} title="turn this sweep off — stop dispatching more Books">✕</button>
    {/if}
    </span>
{/if}

<style>
    /* a StoryTimes station — a run-all sweep button; cooler/wider than a single test-light. */
    .st {
        display: inline-flex; align-items: center; gap: 0.4rem; margin: 0.15rem 0;
        padding: 0.2rem 0.6rem; border-radius: 5px; cursor: pointer;
        border: 1px solid #2c3450; background: #121624;
        font-family: monospace; font-size: 0.76rem; color: #9aa6cc;
        transition: filter 0.1s, transform 0.06s, border-color 0.12s;
    }
    .st:hover  { filter: brightness(1.3); border-color: #44609e; }
    .st:active { transform: translateY(1px); }
    .st-ico    { font-size: 0.95rem; line-height: 1; }
    .st-name   { color: #c4ccea; }
    .st-prog   { font-variant-numeric: tabular-nums; color: #c4a86a; }
    .st-tally  { font-variant-numeric: tabular-nums; }
    .st-pass   { color: #6ad0a0; }
    .st-fail   { color: #f88; }
    .st-runners { color: #5a6a8a; font-size: 0.7rem; }
    .st-running { border-color: #3a3420; color: #c4a86a; }
    .st-running .st-name { color: #d8c490; }
    .st-done    { border-color: rgba(106, 208, 160, 0.4); background: rgba(106, 208, 160, 0.06); }
    .st-wrap    { display: inline-flex; align-items: center; gap: 0.2rem; }
    /* the off control — only shown while a sweep is underway. */
    .st-stop {
        display: inline-flex; align-items: center; justify-content: center;
        width: 1.3rem; height: 1.3rem; padding: 0; border-radius: 4px; cursor: pointer;
        border: 1px solid #5a2c34; background: #1c1216; color: #f88;
        font-family: monospace; font-size: 0.8rem; line-height: 1;
        transition: filter 0.1s, transform 0.06s;
    }
    .st-stop:hover  { filter: brightness(1.35); border-color: #9e4450; }
    .st-stop:active { transform: translateY(1px); }
    /* a stopped sweep — overrides .st-done's green (later rule, equal specificity). */
    .st-stopped { border-color: rgba(248, 136, 136, 0.35); background: rgba(248, 136, 136, 0.05); }
    .st-stopnote { color: #c88; }
    .st-raw {
        font-family: monospace; font-size: 0.74rem; color: #6a7a9a; padding: 0.1rem 0.2rem;
    }
</style>
