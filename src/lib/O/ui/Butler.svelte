<script lang="ts">
    // Butler — THE ARRIVAL.  One fullscreen surface from page load until the machine is ready, which
    //  carries BOTH the boot permission tap and the Supervisor's progress (the owner 2026-08-10:
    //   *"there's a from-page-load FaceSucker that says 'starting up', then it vanishes but then
    //    another FaceSucker comes for 'one tap to open the music'… the second one of those FaceSuckers
    //     needs keeping out of happening by the first, which shall become endowed with Supervisor
    //      progress reporting very elegantly"*).
    //
    //  THE SPLIT, all three surfaces:
    //     SupervisorFace  — the Vyto cell.  Tiny, and quiet while all is well.
    //     SupervisorPanel — UIs:'Supervisor'.  Everything, probe names included.  Devs.
    //     this            — the arrival.  One thing at a time, in the order it happens, and the tap.
    //
    //  IT JUDGES NOTHING.  Every mark, tone and ordering comes from `Supervisor_lines` — the model is
    //   the one authority on what a row means, and a face that re-decides it is the second opinion
    //    that eventually disagrees.  This file chooses only what to SHOW and how it looks.  It names
    //     no subsystem, so a watch registered tomorrow appears here tomorrow with no edit.
    //
    //  IT MAY NOT TRAP THE LISTENER.  Progress is held for at most CAP_MS, and the *carry on* tap is
    //   there from the first frame.  Once it lifts it LATCHES DOWN for the tab: minting an invite
    //    mid-session arms an expectation too, and a fullscreen gate dropping over somebody's music
    //     because they showed a friend a QR code would be the worst bug in this file.
    //   THE ONE THING THAT IS NOT CAPPED is a pending PERMISSION.  A share or an audio gesture is not
    //    news about progress, it is the thing blocking everything, and timing out of it would just
    //     hand the screen back to BootGate — two gates in a row, in the other order.
    import FaceSucker from "$lib/p2p/ui/FaceSucker.svelte"
    import { boot_gate } from "$lib/O/ui/boot_gate.svelte.ts"
    import { onMount } from "svelte"

    let { H = null }: { H?: any } = $props()

    const CAP_MS   = 12000   // the ceiling on holding for PROGRESS — past this the app beats the gate
    const GRACE_MS = 1800    // …and this long before believing "nothing to wait for": the station arms
                             //  its expectation a beat or two after mount, and letting go at t=0 would
                             //   mean the gate never showed on exactly the boot it is for

    const gate = boot_gate(H, { proactive: true })
    onMount(gate.start)

    // Everything below rides one 250ms poll. Deliberate, and the same trade BootGate always made:
    //  `.c.deadline` is a wall clock (a timestamp in sc would churn every downstream fixture forever)
    //   and `.c.notices` is a plain array, so neither announces itself through a version bump. For a
    //    surface that lives ten seconds and shows a countdown, polling is simply the honest mechanism.
    let tick = $state(0)
    let mounted_at = 0
    let done = $state(false)          // the latch — once down, never up again this tab
    let carried_on = $state(false)
    onMount(() => {
        mounted_at = Date.now()
        const iv = setInterval(() => { tick++ }, 250)
        return () => clearInterval(iv)
    })

    // A BOOK MUST NEVER BE COVERED. A Story run on this page is a machine watching a machine; a
    //  listener's loading screen over it hides the run UI and every diagnostic on it — the one
    //   situation where the guts are the point. `H.c.book` is the tell BigQualand stamps.
    let for_a_book = $derived(!!H?.c?.book)

    let view = $derived.by(() => {
        void tick
        const M = H?.top_House ? H.top_House() : H
        const w = M?.o?.({ A: 'Supervisor' })[0]?.o?.({ w: 'Supervisor' })[0] ?? null
        // ONE call, and the model has already ordered, marked and toned every row.
        const lines = (w && H?.Supervisor_lines) ? H.Supervisor_lines(w) : []
        const waiting = lines.filter((l: any) => l.waiting)
        const unfinished = lines.filter((l: any) => !l.done)
        return {
            lines,
            waiting,
            unfinished,
            since: mounted_at ? Date.now() - mounted_at : 0,
            holding: !!unfinished.length,
        }
    })

    // the exit, evaluated on every poll. An $effect and not a $derived because it LATCHES — the whole
    //  point is that the answer is one-way.
    $effect(() => {
        void tick
        if (done) return
        if (carried_on || for_a_book) { done = true; return }
        if (gate.wanted) return                                   // a permission is not progress
        if (view.since > CAP_MS) { done = true; return }
        if (view.since > GRACE_MS && !view.holding) done = true
    })

    let up = $derived(!done && !for_a_book)

    // TELL BOOTGATE TO STAND DOWN while we hold the screen — it carries the same button, and two
    //  fullscreen gates in a row is the bad arrival this was built to remove. On plain `.c` because
    //   BootGate reads it through its own poll; nothing needs to react to it.
    $effect(() => {
        if (!H?.c) return
        if (up) H.c.butler_up = 1
        else delete H.c.butler_up
    })

    // one headline: what we are waiting for, else the next unfinished thing, else the honest nothing —
    //  we are up before the machine is, and saying so beats a blank hold.
    let headline = $derived(
        view.waiting[0]?.sentence
        || view.unfinished[0]?.sentence
        || 'starting up')
    let left = $derived(view.waiting[0]?.left ?? 0)
</script>

{#if up}
    <!-- altitude 55: UNDER BootGate's 77 on purpose, even though we suppress it — if the suppression
         ever fails, the permission tap must still come out on top of the news about progress. -->
    <FaceSucker altitude={55} fullscreen={true}>
        {#snippet content()}
            <div class="butler">
                {#if gate.wanted}
                    <!-- THE TAP. One big orange button and one plain word for what it does (the owner:
                         *"I actually want it to just say 'open share' and be one big orange button,
                         like we had in the prototype"*). No situation talk — it is either needFSA or
                         needAC and naming either is noise (the 2026-07-19 ruling, still true). -->
                    <h2 class="ask">open your music</h2>
                    <button class="orange" onclick={gate.open_share} disabled={gate.opening}>
                        {gate.opening ? 'opening…' : 'open share'}
                    </button>
                    {#if gate.error}<p class="err">{gate.error}</p>{/if}
                {:else}
                    <div class="spin" aria-hidden="true"></div>
                    <h2>{headline}{#if left}<span class="secs"> · {left}s</span>{/if}</h2>
                {/if}

                <!-- THE ARC, in the order it happens — not by severity, which is what put the
                     finished first step at the bottom. Done rows STAY, dimmed and ticked: the list is
                     a story of the machine coming up, and a story that deletes its first line reads
                     as a machine that never did anything. -->
                {#if view.lines.length}
                    <ul class="arc">
                        {#each view.lines as l (l.key)}
                            <li class={l.tone} class:done={l.done}>
                                <span class="m">{l.mark}</span>
                                <span class="s">{l.sentence}</span>
                                {#if l.waiting && l.left}<span class="secs">{l.left}s</span>{/if}
                            </li>
                        {/each}
                    </ul>
                {/if}

                {#if !gate.wanted}
                    <button class="carry" onclick={() => carried_on = true}>carry on →</button>
                {/if}
            </div>
        {/snippet}
    </FaceSucker>
{/if}

<style>
    .butler {
        position: absolute;
        inset: 0;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 1rem;
        text-align: center;
        color: #d7edff;
        padding: 2rem;
        font-family: Arial, Helvetica, sans-serif;
    }
    h2 { font-weight: 400; font-size: 1.35rem; margin: 0; max-width: 22em; line-height: 1.35; }
    h2.ask { font-size: 1.6rem; }
    .secs { opacity: .5; font-variant-numeric: tabular-nums; }
    .orange {
        font-size: 1.6rem;
        padding: .7em 1.6em;
        cursor: pointer;
        color: #2b1500;
        background: #ff8c1a;
        border: none;
        border-radius: .4rem;
        font-weight: 600;
        box-shadow: 0 0 2.5rem rgba(255, 140, 26, .35);
    }
    .orange:hover { background: #ffa040; }
    .orange:disabled { opacity: .55; cursor: default; }
    .err { color: #ff8a8a; font-size: .9rem; }
    .spin {
        width: 1.6rem; height: 1.6rem; border-radius: 50%;
        border: 2px solid #2f4a5e; border-top-color: #7fc7ff;
        animation: butler-spin 900ms linear infinite;
    }
    @keyframes butler-spin { to { transform: rotate(360deg); } }
    @media (prefers-reduced-motion: reduce) { .spin { animation: none; opacity: .5; } }
    .arc { list-style: none; padding: 0; margin: .4rem 0 0; font-size: .95rem;
           max-width: 30em; display: flex; flex-direction: column; gap: .25em; text-align: left; }
    .arc li { display: flex; gap: .55em; align-items: baseline; }
    .arc .m { width: 1em; flex: 0 0 auto; text-align: center; }
    .arc .s { flex: 1 1 auto; }
    .arc li.done    { opacity: .38; }
    .arc li.good    { color: #9fd8a8; }
    .arc li.waiting { color: #ffd08a; }
    .arc li.bad     { color: #ff9b8a; }
    .arc li.todo    { color: #cfd8e0; }
    .arc li.blind   { color: #9aa5b5; }
    .carry {
        margin-top: .6rem; background: none; color: #8fb6d0; cursor: pointer;
        border: 1px solid #33505f; border-radius: 4px; padding: .4em 1em; font-size: .9rem;
    }
    .carry:hover { color: #d7edff; border-color: #57808f; }
</style>
