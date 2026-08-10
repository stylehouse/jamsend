<script lang="ts">
    // Butler — THE ARRIVAL.  One fullscreen surface from page load until the machine is ready, which
    //  carries BOTH the boot permission tap and the Supervisor's progress (the owner 2026-08-10:
    //   *"there's a from-page-load FaceSucker that says 'starting up', then it vanishes but then
    //    another FaceSucker comes for 'one tap to open the music'… the second one of those FaceSuckers
    //     needs keeping out of happening by the first, which shall become endowed with Supervisor
    //      progress reporting very elegantly"*).
    //
    //  THE SPLIT, all three surfaces — RE-AIMED 2026-08-10 by the owner, and the middle one is this
    //   file: *"I kind of want that as the mid-complexity, LOG-LOOKING version of the Supervisor
    //    business, whereas the Supervisor cell is smaller and simpler — perhaps not even there if
    //     nothing is out of line — and the Supervisor UI itself is the bull bollocking"*:
    //     SupervisorFace  — the Vyto cell.  Smallest.  ABSENT when nothing is out of line.
    //     this            — MID-COMPLEXITY, and it should LOOK LIKE A LOG: the arc with its notes, and
    //                        the notice ring under it — what must be true, and what actually happened,
    //                         in the order it happened.  Plus the tap.
    //     SupervisorPanel — UIs:'Supervisor'.  The whole bollocking: probe names, kinds, latches,
    //                        patience clocks, prefs, the reporting ladder.  Devs.
    //  MID-COMPLEXITY IS A REAL CONSTRAINT, not a hedge.  What separates this from the panel is that
    //   every line here is a SENTENCE a listener could read — the claim, its note, the things that
    //    happened.  A probe method name is not one, and the day one appears here this file has become
    //     the panel and the panel has become redundant.
    //
    //  IT JUDGES NOTHING.  Every mark, tone and ordering comes from `Supervisor_lines` — the model is
    //   the one authority on what a row means, and a face that re-decides it is the second opinion
    //    that eventually disagrees.  This file chooses only what to SHOW and how it looks.  It names
    //     no subsystem, so a watch registered tomorrow appears here tomorrow with no edit.
    //
    //  IT CARRIES YOU ALL THE WAY (the owner 2026-08-10: *"the Butler is supposed to carry you all the
    //   way, letting you know what's happening, until the Vyto glass is up and running AND playing the
    //    thing you want"*).  So the exit this screen is FOR is ARRIVAL — `Supervisor_arrived`, the
    //     milestone the commissioner declared — and the clock below is the GIVE-UP, not the success.
    //      Every earlier cut had it the other way round: three impatience exits and no arrival at all,
    //       so a listener was handed a half-built machine on a timer and told nothing about it.
    //
    //  IT MAY NOT TRAP THE LISTENER — and it does that WITHOUT A CLOCK (there is no GIVEUP_MS any
    //   more; see below).  The *carry on* tap is there from the first frame and grows at IMPATIENT_MS,
    //    and a listener who never wants this screen again has one small persistent switch (see QUIET).
    //     Once it lifts it LATCHES DOWN for the tab — `H.c.butler_done`, the tab and not this
    //      component — because minting an invite mid-session arms an expectation too, and a fullscreen
    //       gate dropping over somebody's music because they showed a friend a QR code would be the
    //        worst bug in this file.
    //   WHAT IS NOT NEWS ABOUT PROGRESS is a pending PERMISSION or an unspent INVITE.  Neither is
    //    something to wait out: they are the thing blocking everything, and lifting off them would
    //     just hand the screen back to BootGate (two gates in a row, in the other order) or hide the
    //      join door behind a boot log.
    import FaceSucker from "$lib/p2p/ui/FaceSucker.svelte"
    import InvitePanel from "$lib/O/ui/InvitePanel.svelte"
    import { boot_gate } from "$lib/O/ui/boot_gate.svelte.ts"
    import { boot_param } from "$lib/boot"
    import { onMount } from "svelte"
    import { fly, fade } from "svelte/transition"
    import { quintOut } from "svelte/easing"

    let { H = null }: { H?: any } = $props()

    // THERE IS NO CLOCK THAT LIFTS THIS. The owner, 2026-08-10, watching it fade with the glass still
    //  coming up: *"has to not de-facesuck UNTIL arrive.playing"*. A 40s ceiling was tried first and it
    //   is exactly the impatience exit this screen was rebuilt to remove — it just fired later. The
    //    only automatic lift is ARRIVAL; the only other way out is the listener's own tap, which is on
    //     screen from the first frame and grows at IMPATIENT_MS. That is what keeps "may not trap the
    //      listener" true without a timer: there is always a way out, and a person chooses it.
    //  (If a tab can reach a state where arrival never comes and the tap is the only exit, that is a
    //    BUG IN THE ROSTER worth seeing, not a reason to put the clock back. The give-up ladder this
    //     doc is named for is about saying so, not about quietly stepping aside.)
    const IMPATIENT_MS = 12000  // past this we stop pretending the wait is normal: the carry-on tap
                                //  grows and names itself. Silence is the trap, not duration.
    const STILL_MS     = 6000   // …and this long of NOTHING MOVING before believing "nothing to wait
                                //  for", which is only ever the NO-ARRIVAL fallback below. Note what it
                                //   measures: not how long we have been up (that was the bug, twice
                                //    over — 1.8s, then 6s, both lifting mid-boot because a young roster
                                //     had nothing outstanding YET), but how long since the roster last
                                //      changed its mind. §2, in this file: elapsed time cannot tell
                                //       SLOW from STUCK, only "has anything advanced" can.
    const QUIET = 'butler.quiet' // the persistent switch (the owner: *"one semi-hidden persistent-state
                                 //  toggle, like we used to have, quit_fullscreen or so"*). A particle
                                 //   + the House stash, both owned by Supervisor_pref — NOT a `$state`
                                 //    here, which would forget itself on the very reload it is for.

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
    // …AND THE LATCH IS THE TAB'S, NOT THE COMPONENT'S. A `$state` latch only promises "never up again
    //  for this component instance"; a remount (a view switch that ever wraps this in an `{#if}` or a
    //   `{#key}`) hands back a fresh `false` and the loading screen drops over somebody's music, which
    //    this file calls its own worst bug. `H.c` is the tab: new on every reload, shared by every
    //     mount within one. Plain `.c` — nothing reacts to it, and it must never reach a snap.
    function lift() {
        done = true
        if (H?.c) (H.c as any).butler_done = 1
    }
    onMount(() => {
        mounted_at = Date.now()
        const iv = setInterval(() => { tick++ }, 250)
        return () => clearInterval(iv)
    })

    // A MACHINE TAB MUST NEVER BE COVERED. A Story run driven on this page is a machine watching a
    //  machine; a listener's loading screen over it hides the run UI and every diagnostic on it — the
    //   one situation where the guts are the point.
    //
    //  THE FIRST CUT OF THIS READ `!!H?.c?.book`, AND IT KILLED THE WHOLE FILE (found 2026-08-10 by
    //   the owner: *"the Butler closes when the interface is still at 'nothing mounted yet'"*).
    //    `BigQualand.svelte.ts:57` stamps `h.c.book = opts.book` on EVERY qualand page — /BigSoundland's
    //     resident Book IS Sounditron — so `c.book` is set on every listener tab there has ever been.
    //      Worse, it read as FALSE for the first frames (boot_qualand assigns `H` inside an `$effect`,
    //       so the Butler mounts with `H` null), which is why it appeared to flash up and then vanish
    //        rather than never showing: it latched shut the instant H arrived. **The Butler had never
    //         once done its job.** Nothing about arrival or the clock was ever reached.
    //
    //  THE HONEST TELL IS `humdinger` — the flag BigQualand stamps for role word|sound, i.e. "this is
    //   an end-user room", the same flag the arrival milestone and the /log reporter already gate on.
    //    Plus an EXPLICIT `?B=`: someone who deliberately drives a Book from their own music page is
    //     asking to watch the machine, and covering that with a loading screen would be the original
    //      worry made real. A null H reads FALSE here and the Butler holds — which is right: "we do not
    //       know yet" is the one answer that must not latch a gate shut.
    let machine_tab = $derived(!!H?.c && (!(H.c as any).humdinger || !!boot_param('B')))

    // the world, the way the model finds it (Supervisor_w) rather than a hardcoded House.
    function sup_w() {
        const M = H?.top_House ? H.top_House() : H
        return M?.o?.({ A: 'Supervisor' })[0]?.o?.({ w: 'Supervisor' })[0] ?? null
    }

    // THE PERSISTENT SWITCH, read through the model so the stash and the particle can never disagree.
    //  Read in an $effect rather than the $derived below because the first read MINTS (it mirrors a
    //   stashed `on` into a particle), and a derived that mutates is a derived that will one day loop.
    //    It stops asking the moment it reads on — there is nothing to un-latch here, the panel is
    //     where it gets turned back off.
    let quiet = $state(false)
    $effect(() => {
        void tick
        if (quiet) return
        const w = sup_w()
        if (!w || !H?.Supervisor_pref) return
        if (H.Supervisor_pref(w, QUIET)) quiet = true
    })

    let view = $derived.by(() => {
        void tick
        const w = sup_w()
        // ONE call, and the model has already ordered, marked and toned every row.
        const lines = (w && H?.Supervisor_lines) ? H.Supervisor_lines(w) : []
        const waiting = lines.filter((l: any) => l.waiting)
        const unfinished = lines.filter((l: any) => !l.done)
        // WHAT TO SAY WHEN WE GAVE UP ON SOMETHING — the registrar's sentence, carried on the line
        //  (Supervisor_line's `advice`). This is the "no friend is online — you can listen to your own
        //   music" the owner asked for, and the reason it is not written here is that this file has no
        //    business knowing that friends, invites or local music exist.
        const advice = lines.filter((l: any) => l.gaveup && l.advice).map((l: any) => l.advice)
        // THE NOTICE RING — what actually HAPPENED, newest last (the order it happened in, which is
        //  the order a log reads in). This is the log half of "log-looking": the arc says what must
        //   become true, the ring says what turned. Entirely `.c`, so it costs the snap nothing.
        const notices = (w && H?.Supervisor_noticed) ? H.Supervisor_noticed(w).slice(-6) : []
        return {
            lines,
            waiting,
            unfinished,
            advice,
            notices,
            arrived: (w && H?.Supervisor_arrived) ? H.Supervisor_arrived(w) : 'none',
            since: mounted_at ? Date.now() - mounted_at : 0,
            holding: !!unfinished.length,
        }
    })

    // ── THE LANDING — somebody opened this tab from a scanned invite ──────────────────────────────
    //  (the owner 2026-08-10: *"is this going to contain all the Invite onboarding UI as well? it'll
    //   focus the UX of entering their username and hitting join."*  Yes — and it had become a real
    //    bug rather than a feature the moment this screen started holding until arrival: the join door
    //     lives in `BigSoundland.svelte`'s strip, and a fullscreen arrival screen over it hides the
    //      invite funnel behind news about a machine the person has no reason to care about yet.)
    //  IT MOUNTS THE EXISTING PANEL. `InvitePanel` is the ONE implementation of mint→parse→seal→spent
    //   (Book SwarmInvite proves that arc); a second join button written here would be `boot_gate`'s
    //    lesson repeated — two doors onto one permission, with the gesture rules to get wrong twice.
    //  THE TOKEN IS THE STATE, and it is in the URL: `?Iz=` is single-use and `strip_iz()` removes it
    //   the moment it is redeemed or refused, so `boot_param` (which reads `location` live) tells us
    //    "still to do" with no subsystem knowledge and no second copy of the panel's state machine.
    //  AND ONLY ONE PANEL MAY BE MOUNTED AT A TIME — see the strip's `!butler_up` gate. Two live
    //   instances both auto-join a scan-landing (`landed_url && !auto_fired`, latched per instance),
    //    and a single-use token redeemed twice comes back as a rebuff: the invite would refuse itself.
    let landing = $derived.by(() => { void tick; return !!boot_param('Iz') })
    // …and once shown it STAYS shown for the life of this screen, even after the token is spent: the
    //  panel is mid-`join()` when that happens ("… hello delivered — waiting for the seal"), and
    //   unmounting it there would delete the only report of whether the friendship sealed.
    let landing_seen = $state(false)
    $effect(() => { if (landing) landing_seen = true })

    // past this we stop looking patient — the tap grows and says what it is for.
    let impatient = $derived(view.since > IMPATIENT_MS && !gate.wanted && !landing)

    // HAS ANYTHING ADVANCED? The whole state of the roster in one string — how many claims exist, how
    //  many have turned, how many things have happened, and whether an arrival is on the board. Any of
    //   those moving means the machine is still coming up. Deliberately COARSE: a note churning under
    //    a line ("37 folders walked") must not read as progress here, or nothing would ever be still.
    let sig = $derived(view.lines.length + '/' + view.lines.filter((l: any) => l.done).length
                       + '/' + view.notices.length + '/' + view.arrived)
    let last_sig = ''
    let still_since = $state(0)
    $effect(() => {
        void tick
        if (sig === last_sig) return
        last_sig = sig
        still_since = Date.now()
    })

    // the exit, evaluated on every poll. An $effect and not a $derived because it LATCHES — the whole
    //  point is that the answer is one-way.
    //  THE ORDER IS THE DESIGN. Arrival is the reason this screen exists; the clock is the apology for
    //   when arrival never comes. A `none` arrival (no registrar has declared one — a bare tab, a
    //    half-loaded spine) falls back to the old reading, because holding a listener behind a finish
    //     line nobody will ever cross is the one failure mode worse than lifting early.
    $effect(() => {
        void tick
        if (done) return
        if ((H?.c as any)?.butler_done) { done = true; return }    // already lifted earlier this tab
        if (carried_on || machine_tab || quiet) { lift(); return }
        if (gate.wanted) return                                   // a permission is not progress
        if (landing) return                                       // …and neither is an unspent invite
        if (view.arrived === 'arrived') { lift(); return }        // ★ THE ONLY AUTOMATIC EXIT
        // …and the fallback for a page where NOBODY EVER DECLARES AN ARRIVAL — not a clock, a
        //  different question. `none` means no registrar has a finish line at all (a host that is not
        //   BigSoundland, a spine that never loaded Sounditron), and there holding forever would be
        //    waiting on something that cannot happen. Where an arrival IS declared this never fires,
        //     however long it takes.
        //  IT WAITS FOR STILLNESS, NOT FOR TIME. A booting tab reaches this line with a roster that is
        //   half-registered and momentarily has nothing outstanding — every watch so far ok, the
        //    arrival not commissioned yet — and any elapsed-time reading lifts right there, which is
        //     the "bust open at the wrong time" the owner kept seeing. While registrations keep
        //      landing, watches keep turning or notices keep arriving, this is a machine coming up.
        //  AND AN EMPTY ROSTER IS NOT "NOTHING TO WAIT FOR" — it is "nobody has spoken YET", which is
        //   the unknown-is-first-class rule again (the same one that makes a null `H` hold above). A
        //    still, EMPTY board is the most common shape of the first seconds on this page: the world
        //     is minted by the registrar itself, so before `Sounditron_machine` reaches its
        //      registration beat there are no lines, no notices and no arrival — perfectly still, and
        //       every clock-or-stillness reading lifts right there, mid-spine-load. The fallback is
        //        for a page whose registrars HAVE spoken and none of them declared a finish line.
        //   The Butler mounts on one page (`BigSoundland.svelte`) and that page's Book declares an
        //    arrival in beat 2, so "hold on an empty board" cannot strand anybody who is booting; if
        //     the board never fills the machine truly never started, and the carry-on tap has grown
        //      and named itself by then. Silence with a way out beats a gate that lies about being up.
        if (view.arrived === 'none' && view.lines.length && !view.holding
            && still_since && Date.now() - still_since > STILL_MS) lift()
    })

    let up = $derived(!done && !machine_tab)

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

    // elapsed, log-style: how long ago it turned. Seconds while a boot is still a boot.
    function ago(at: number) {
        const s = Math.max(0, Math.round((Date.now() - at) / 1000))
        return s < 60 ? '+' + s + 's' : '+' + Math.round(s / 60) + 'm'
    }

    // hush — the switch, written through the model (particle + stash in one place) and taking effect
    //  at once: a control that only worked NEXT time would look broken the moment it was pressed.
    function hush() {
        const w = sup_w()
        if (w && H?.Supervisor_pref_set) H.Supervisor_pref_set(w, QUIET, 1)
        quiet = true
    }
</script>

{#if up}
    <!-- altitude 55: UNDER BootGate's 77 on purpose, even though we suppress it — if the suppression
         ever fails, the permission tap must still come out on top of the news about progress. -->
    <FaceSucker altitude={55} fullscreen={true}>
        {#snippet content()}
            <div class="butler" out:fade={{ duration: 420 }}>
                <div class="aurora" aria-hidden="true"></div>
                <div class="card" in:fly={{ y: 14, duration: 480, easing: quintOut }}>
                    <!-- THE DOOR. While the token is UNSPENT it is the only thing on this card: a
                         person who followed a friend's QR is here to type their name and hit join, and
                         a boot log underneath it is this screen talking over the one thing it is
                         supposed to be helping with. Once the token is spent the panel STAYS — it is
                         mid-`join()` at that moment and holds the only report of whether the
                         friendship sealed — and the news comes back underneath it, which is also the
                         first thing that person has any reason to read: what happens next. -->
                    {#if landing_seen}
                        {#if landing}<h2 class="ask">you were invited</h2>{/if}
                        <div class="door"><InvitePanel {H} /></div>
                    {/if}

                    {#if landing}
                        <!-- nothing else while they are at the door -->
                    {:else if gate.wanted}
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
                    {#if view.lines.length && !landing}
                        <ul class="arc">
                            {#each view.lines as l, i (l.key)}
                                <li class={l.tone} class:done={l.done}
                                    in:fly={{ y: 6, duration: 260, delay: i * 40, easing: quintOut }}>
                                    <span class="m">{l.mark}</span>
                                    <span class="s">
                                        {l.sentence}
                                        <!-- THE NOTE IS WHAT MAKES THIS MID-COMPLEXITY. The cell has
                                             room for a sentence; this has room for the sentence AND
                                             its evidence ("no A:Vyto in any of 2 House(s)", "12
                                             records"). §5: attribution before action — a claim with
                                             no evidence under it is a riddle, and the panel should
                                             not be the only place a person can read one. -->
                                        {#if l.note}<span class="note">{l.note}</span>{/if}
                                    </span>
                                    {#if l.waiting && l.left}<span class="secs">{l.left}s</span>{/if}
                                </li>
                            {/each}
                        </ul>
                    {/if}

                    <!-- THE LOG TAIL — the notice ring: every watch or dial that CHANGED ITS MIND,
                         in the order it happened. The arc above says what must become true; this says
                         what turned. Together they are the "log-looking" half of this surface, and
                         neither alone reads as a machine coming up. Last six only — a loading screen
                         is not a scrollback, and the panel holds the full twelve. -->
                    {#if view.notices.length && !landing}
                        <ul class="log">
                            {#each view.notices as ev (ev.at + ev.sentence)}
                                <li transition:fade={{ duration: 200 }}>
                                    <span class="when">{ago(ev.at)}</span>
                                    <span class="s">{ev.sentence}{#if ev.n > 1} ×{ev.n}{/if}</span>
                                </li>
                            {/each}
                        </ul>
                    {/if}

                    <!-- THE GIVE-UP, IN WORDS. A wait that quietly expires tells a listener nothing;
                         this is the whole of the owner's *"it should also explain clearly that no
                         friend is online and you can play local music instead"*. Calm, not red — it
                         is not a fault, it is the machine being honest about what it settled for. -->
                    {#if view.advice.length && !landing}
                        <div class="advice" transition:fade={{ duration: 240 }}>
                            {#each view.advice as a}<p>{a}</p>{/each}
                        </div>
                    {/if}

                    {#if !gate.wanted}
                        <!-- the way out stays on the card even at the door: dismissing it drops the
                             listener onto the page whose strip carries the SAME panel (the strip's
                             gate is `!butler_up`), so nobody can be stranded away from their invite
                             by tapping the one button that is always there. -->
                        <button class="carry" class:big={impatient} onclick={() => carried_on = true}>
                            {impatient ? 'this is taking a while — carry on →' : 'carry on →'}
                        </button>
                        <!-- THE SEMI-HIDDEN SWITCH. Deliberately the quietest thing on the card: it
                             costs a listener their arrival screen forever, so it must never be the
                             easiest thing to hit. It is turned back ON from the Supervisor panel —
                             the off-switch is where you are annoyed, the on-switch where you are
                             looking for it. Persistent because it is a particle + the House stash.
                             NOT AT THE DOOR: "don't wait for me" is an answer to a loading screen,
                             and offering it to somebody mid-join is offering to hide the join. -->
                        {#if !landing}
                            <button class="quiet" title="don't show this arrival screen again — turn it back on in the Supervisor panel"
                                    onclick={hush}>don't wait for me</button>
                        {/if}
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
        /* wider than the old 30em: a log wants a line long enough to hold a sentence and its note
           without wrapping every row into three. */
        max-width: 38em;
        width: 100%;
        max-height: 84vh;
        overflow-y: auto;
        padding: 2.2rem 2.2rem;
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
    /* LOG-LOOKING: left-aligned, one row per fact, marks and clocks in a fixed gutter so the eye
       scans a column rather than re-reading centred prose. The card is wider for the same reason. */
    .arc { list-style: none; padding: 0; margin: .3rem 0 0; font-size: .95rem;
           width: 100%; display: flex; flex-direction: column; gap: .25em; text-align: left; }
    .arc li { display: flex; gap: .6em; align-items: baseline;
              padding: .2em .3em; border-radius: .35em; transition: opacity 300ms ease; }
    .arc .m { width: 1em; flex: 0 0 auto; text-align: center; }
    .arc .s { flex: 1 1 auto; min-width: 0; }
    .arc .note { display: block; opacity: .5; font-size: .85em; line-height: 1.35;
                 font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
    .arc li.done    { opacity: .35; }
    .arc li.good    { color: #9fd8a8; }
    .arc li.waiting { color: #ffd08a; background: rgba(255, 208, 138, .06); }
    .arc li.bad     { color: #ff9b8a; }
    .arc li.todo    { color: #cfd8e0; }
    .arc li.blind   { color: #9aa5b5; }
    /* the log tail — dimmer than the arc on purpose: the arc is what must happen, this is what did */
    .log { list-style: none; padding: .4em 0 0; margin: .2rem 0 0; width: 100%;
           border-top: 1px solid rgba(255,255,255,.07); text-align: left;
           display: flex; flex-direction: column; gap: .1em;
           font-size: .82rem; opacity: .62;
           font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
    .log li { display: flex; gap: .6em; align-items: baseline; }
    .log .when { flex: 0 0 3em; text-align: right; opacity: .6;
                 font-variant-numeric: tabular-nums; }
    .log .s { flex: 1 1 auto; min-width: 0; }
    /* the door — the panel brings its own chrome, so this only gives it the card's full width and
       an honest left edge to read down. Deliberately no `:global` restyling of the panel: it is the
       same door as the strip's and the cell's, and a Butler-only skin would be a fourth opinion. */
    .door { width: 100%; text-align: left; }
    .advice { margin: .1rem 0 0; display: flex; flex-direction: column; gap: .25em;
              max-width: 24em; color: #cfe0ee; font-size: .95rem; line-height: 1.45;
              padding: .55em .8em; border-radius: .5rem;
              background: rgba(127, 199, 255, .07); border: 1px solid rgba(127, 199, 255, .14); }
    .advice p { margin: 0; }
    .carry {
        margin-top: .3rem; background: none; color: #8fb6d0; cursor: pointer;
        border: 1px solid #33505f; border-radius: .5rem; padding: .45em 1.1em; font-size: .88rem;
        transition: color 140ms ease, border-color 140ms ease, background 140ms ease;
    }
    .carry:hover { color: #e8f3ff; border-color: #6ea3bf; background: rgba(255,255,255,.04); }
    .carry.big { color: #e8f3ff; border-color: #6ea3bf; font-size: 1rem; padding: .6em 1.4em; }
    /* the semi-hidden one: legible if you look, invisible if you don't */
    .quiet {
        margin-top: -.35rem; background: none; border: none; cursor: pointer;
        color: #6d8496; font-size: .74rem; letter-spacing: .02em; padding: .3em .5em;
        text-decoration: underline dotted; text-underline-offset: .25em;
        transition: color 140ms ease;
    }
    .quiet:hover { color: #b9cede; }
</style>
