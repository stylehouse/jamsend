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
    import { fly, fade } from "svelte/transition"
    import { quintOut } from "svelte/easing"

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
            <div class="butler" out:fade={{ duration: 420 }}>
                <div class="aurora" aria-hidden="true"></div>
                <div class="card" in:fly={{ y: 14, duration: 480, easing: quintOut }}>
                    {#if gate.wanted}
                        <!-- THE TAP. One big orange button and one plain word for what it does (the
                             owner: *"I actually want it to just say 'open share' and be one big
                             orange button, like we had in the prototype"*). No situation talk — it is
                             either needFSA or needAC and naming either is noise (the 2026-07-19
                             ruling, still true). -->
                        <h2 class="ask">open your music</h2>
                        <button class="orange" onclick={gate.open_share} disabled={gate.opening}>
                            <span class="glint" aria-hidden="true"></span>
                            {gate.opening ? 'opening…' : 'open share'}
                        </button>
                        {#if gate.error}<p class="err" transition:fade>{gate.error}</p>{/if}
                    {:else}
                        <div class="rings" aria-hidden="true"><span></span><span></span></div>
                        {#key headline}
                            <h2 in:fly={{ y: 8, duration: 320, easing: quintOut }} out:fade={{ duration: 120 }}>
                                {headline}{#if left}<span class="secs"> · {left}s</span>{/if}
                            </h2>
                        {/key}
                    {/if}

                    <!-- THE ARC, in the order it happens — not by severity, which is what put the
                         finished first step at the bottom. Done rows STAY, dimmed and ticked: the
                         list is a story of the machine coming up, and a story that deletes its first
                         line reads as a machine that never did anything. -->
                    {#if view.lines.length}
                        <ul class="arc">
                            {#each view.lines as l, i (l.key)}
                                <li class={l.tone} class:done={l.done}
                                    in:fly={{ y: 6, duration: 260, delay: i * 40, easing: quintOut }}>
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
            </div>
        {/snippet}
    </FaceSucker>
{/if}

<style>
    .butler {
        position: absolute;
        inset: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        overflow: hidden;
        color: #e8f3ff;
        padding: 2rem;
        font-family: -apple-system, "Segoe UI", Arial, Helvetica, sans-serif;
        background: radial-gradient(ellipse at 50% 30%, #0d1b2e 0%, #060c16 70%);
    }
    /* a slow drifting glow behind the card — the app is arriving, not just loading */
    .aurora {
        position: absolute;
        inset: -20%;
        background:
            radial-gradient(38% 30% at 22% 28%, rgba(127, 199, 255, .16), transparent 65%),
            radial-gradient(30% 26% at 78% 68%, rgba(255, 140, 26, .10), transparent 65%),
            radial-gradient(26% 22% at 65% 18%, rgba(159, 216, 168, .08), transparent 65%);
        filter: blur(40px);
        animation: butler-drift 16s ease-in-out infinite alternate;
    }
    @keyframes butler-drift {
        0%   { transform: translate3d(0, 0, 0) scale(1); }
        100% { transform: translate3d(-2%, 2%, 0) scale(1.06); }
    }
    .card {
        position: relative;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 1.1rem;
        text-align: center;
        max-width: 30em;
        padding: 2.4rem 2.2rem;
        border-radius: 1.1rem;
        background: linear-gradient(180deg, rgba(255,255,255,.05), rgba(255,255,255,.015));
        border: 1px solid rgba(255,255,255,.09);
        box-shadow: 0 24px 70px -20px rgba(0,0,0,.6), inset 0 1px 0 rgba(255,255,255,.06);
        backdrop-filter: blur(14px);
    }
    h2 { font-weight: 400; font-size: 1.35rem; margin: 0; max-width: 22em; line-height: 1.4;
         letter-spacing: .01em; }
    h2.ask { font-size: 1.7rem; font-weight: 300; }
    .secs { opacity: .5; font-variant-numeric: tabular-nums; }
    .orange {
        position: relative;
        overflow: hidden;
        font-size: 1.55rem;
        padding: .75em 1.8em;
        cursor: pointer;
        color: #2b1500;
        background: linear-gradient(180deg, #ffb156, #ff8c1a);
        border: none;
        border-radius: .6rem;
        font-weight: 600;
        letter-spacing: .01em;
        box-shadow: 0 10px 34px -6px rgba(255, 140, 26, .55), inset 0 1px 0 rgba(255,255,255,.4);
        transition: transform 160ms ease, box-shadow 160ms ease, background 160ms ease;
    }
    .orange:hover:not(:disabled) {
        background: linear-gradient(180deg, #ffc172, #ffa040);
        transform: translateY(-1px);
        box-shadow: 0 14px 40px -6px rgba(255, 140, 26, .65), inset 0 1px 0 rgba(255,255,255,.5);
    }
    .orange:active:not(:disabled) { transform: translateY(0); }
    .orange:disabled { opacity: .55; cursor: default; }
    /* a slow sweep of light across the button — purely decorative, a "this is alive" cue */
    .glint {
        position: absolute; inset: 0;
        background: linear-gradient(115deg, transparent 40%, rgba(255,255,255,.55) 50%, transparent 60%);
        background-size: 220% 100%;
        animation: butler-glint 3.2s ease-in-out infinite;
        pointer-events: none;
    }
    @keyframes butler-glint {
        0%, 55%  { background-position: 140% 0; }
        100%     { background-position: -40% 0; }
    }
    .err { color: #ff8a8a; font-size: .9rem; margin: 0; }
    .rings {
        position: relative;
        width: 2.4rem; height: 2.4rem;
    }
    .rings span {
        position: absolute; inset: 0;
        border-radius: 50%;
        border: 2.5px solid transparent;
    }
    .rings span:first-child {
        border-top-color: #7fc7ff; border-right-color: #7fc7ff44;
        animation: butler-spin 1100ms cubic-bezier(.5,0,.5,1) infinite;
    }
    .rings span:last-child {
        inset: 5px;
        border-bottom-color: #ffb156; border-left-color: #ffb15644;
        animation: butler-spin 850ms cubic-bezier(.5,0,.5,1) infinite reverse;
    }
    @keyframes butler-spin { to { transform: rotate(360deg); } }
    @media (prefers-reduced-motion: reduce) {
        .rings span, .glint, .aurora { animation: none; }
        .rings span:first-child { opacity: .8; }
    }
    .arc { list-style: none; padding: 0; margin: .3rem 0 0; font-size: .95rem;
           width: 100%; display: flex; flex-direction: column; gap: .3em; text-align: left; }
    .arc li { display: flex; gap: .6em; align-items: baseline;
              padding: .2em .3em; border-radius: .35em; transition: opacity 300ms ease; }
    .arc .m { width: 1em; flex: 0 0 auto; text-align: center; }
    .arc .s { flex: 1 1 auto; }
    .arc li.done    { opacity: .35; }
    .arc li.good    { color: #9fd8a8; }
    .arc li.waiting { color: #ffd08a; background: rgba(255, 208, 138, .06); }
    .arc li.bad     { color: #ff9b8a; }
    .arc li.todo    { color: #cfd8e0; }
    .arc li.blind   { color: #9aa5b5; }
    .carry {
        margin-top: .3rem; background: none; color: #8fb6d0; cursor: pointer;
        border: 1px solid #33505f; border-radius: .5rem; padding: .45em 1.1em; font-size: .88rem;
        transition: color 140ms ease, border-color 140ms ease, background 140ms ease;
    }
    .carry:hover { color: #e8f3ff; border-color: #6ea3bf; background: rgba(255,255,255,.04); }
</style>
