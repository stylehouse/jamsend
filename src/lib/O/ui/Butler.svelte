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
    //    thing you want"*).  So the ONE automatic exit is ARRIVAL — `Supervisor_arrived`, the milestone
    //     the commissioner declared, whose probe is a positive ladder (a frame · a commission ·
    //      grapples · mirror cells · nothing missing · and the analyser actually hearing sound).  There
    //       is no clock in this file that lifts it and there must never be one again: FOUR have been
    //        tried and removed (1.8s, 6s elapsed, a 40s ceiling, then 6s of roster stillness), and each
    //         one handed a listener a half-built machine on a timer and told them nothing about it.
    //      When arrival CANNOT happen, the model says so — `Supervisor_arrived → 'gaveup'`, off the
    //       patience the REGISTRAR armed on its own milestone — and this screen changes what it says
    //        rather than vanishing, because that is the moment its advice becomes true.
    //
    //  IT MAY NOT TRAP THE LISTENER — and it does that WITHOUT A CLOCK and now without a tap of its
    //   own.  The way out is ▦, which the PAGE draws, fixed in the top-right corner at z-index 999999,
    //    deliberately over this FaceSucker, on every room and at all times.  This file only READS that
    //     pref (see GUTS); it owns no switch of its own.
    //   THE *CARRY ON* TAP IS GONE (the owner 2026-08-10).  It was this file's second door onto an exit
    //    the page already draws better — always present, differently labelled, and it dismissed the
    //     screen without doing anything about the state that put it there.  Worse, its loud form said
    //      *carry on in and pick something to hear* at exactly the moment that advice is unfollowable
    //       (see RELOAD below).  One door, drawn once, by whoever owns it — the same ruling that took
    //        the guts switch off this card and the second ▦ out of the peek.
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
    //    only automatic lift is ARRIVAL; the only other way out is ▦, which the PAGE draws in every
    //     room, at all times, above this FaceSucker. That is what keeps "may not trap the listener"
    //      true without a timer: there is always a way out, and a person chooses it.
    //  (If a tab can reach a state where arrival never comes and ▦ is the only exit, that is a BUG IN
    //    THE ROSTER worth seeing, not a reason to put the clock back. The give-up ladder this doc is
    //     named for is about saying so, not about quietly stepping aside.)
    // `IMPATIENT_MS` (12s) went with the carry-on tap, and it is worth a headstone beside the four
    //  clocks above because it was NOT one of them: it never lifted the screen, it only grew a button.
    //   With the tap gone it had no reader, and a constant that styles a control that no longer exists
    //    is exactly the "in case" helper this file keeps deleting. What it was for — *stop pretending
    //     the wait is normal* — is now the MODEL's job and always should have been: `gaveup` says it
    //      in words, on the registrar's own patience, and the reload offer appears with it.
    // THERE IS NO SECOND CONSTANT ANY MORE, and the one that was here is worth a headstone. `STILL_MS`
    //  lifted the screen after 6s of a roster not changing its mind, as the fallback for a page where
    //   nobody declares an arrival. It was the fourth impatience exit in a row to be wrong, and it was
    //    wrong in a way none of the earlier ones were: it measured the right quantity (progress, not
    //     elapsed time — §2) and still fired mid-boot, because A YOUNG ROSTER IS PERFECTLY STILL. The
    //      owner, 2026-08-10: *"Butler quits very soon, only one goal is listed"*, then *"it quits
    //       right after 'friend comes online' which I can only just see as it fades out"*. One goal is
    //        the whole diagnosis: `Sounditron_supervise` registers all seven watches AND the arrival in
    //         BEAT 2, and until the Creduler has loaded the spine and the Book has started, the board
    //          holds only Radio's one row — done, still, and indistinguishable from a finished machine.
    //  SO THE FALLBACK IS GONE RATHER THAN RETUNED. Every version of it was one question — "is an
    //   arrival ever coming?" — being answered by a face that is forbidden to know. The model answers
    //    it now (`Supervisor_arrived → 'gaveup'`, off the patience its registrar armed), and this file
    //     waits. `none` means NOT YET, in every case this screen can be up for.
    const GUTS = 'guts'         // THE ONE SEMI-HIDDEN PERSISTENT SWITCH (the owner: *"one semi-hidden
                                //  persistent-state toggle, like we used to have, quit_fullscreen or
                                //   so"*, then 2026-08-10: *"we want that button hidden within our app
                                //    — that and the Butler-overlay-exiting control should be one and
                                //     the same"*). It means I WANT THE MACHINE, and one control sets it
                                //      — the page's fixed ▦. This screen stands down, and BigSoundland
                                //       appears. A listener never sees either. A particle + the House
                                //        stash, both owned by Supervisor_pref — NOT a `$state` here,
                                //         which would forget itself on the very reload it is for.
                                //  It replaced `butler.quiet`, which said only "skip the loading
                                //   screen" and left the ▦ on a listener's screen with nothing to do.

    const gate = boot_gate(H, { proactive: true })
    onMount(gate.start)

    // Everything below rides one 250ms poll. Deliberate, and the same trade BootGate always made:
    //  `.c.deadline` is a wall clock (a timestamp in sc would churn every downstream fixture forever)
    //   and `.c.notices` is a plain array, so neither announces itself through a version bump. For a
    //    surface that lives ten seconds and shows a countdown, polling is simply the honest mechanism.
    let tick = $state(0)
    let mounted_at = 0
    let done = $state(false)          // the latch — once down, never up again this tab
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
    let guts = $state(false)
    $effect(() => {
        void tick
        if (guts) return
        const w = sup_w()
        if (!w || !H?.Supervisor_pref) return
        if (H.Supervisor_pref(w, GUTS)) guts = true
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
        // the REMEDY KIND of whatever gave up — the registrar's word, never our reading of its
        //  sentence.  Only 'gesture' has a meaning here today; anything else falls to the reload.
        const remedy = lines.filter((l: any) => l.gaveup && l.remedy).map((l: any) => l.remedy)[0] || ''
        // THE NOTICE RING — what actually HAPPENED, newest last (the order it happened in, which is
        //  the order a log reads in). This is the log half of "log-looking": the arc says what must
        //   become true, the ring says what turned. Entirely `.c`, so it costs the snap nothing.
        return {
            lines,
            waiting,
            unfinished,
            advice,
            remedy,
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

    // HAVE WE SETTLED FOR LESS? The model's ruling, not ours: the declared arrival is unmet and the
    //  patience its own registrar armed has run out. Nothing more is going to happen on its own.
    //  IT DOES NOT LIFT THE SCREEN, and that is the point of showing it. Lifting here would delete the
    //   advice at the instant it became true — and that advice IS the owner's *"it should also explain
    //    clearly that no friend is online and you can play local music instead"*. So the screen stops
    //     pretending to load (no spinner) and the way out goes loud instead. A person leaves when they
    //      have read why, which is the difference between being told and being timed out.
    let settled = $derived(view.arrived === 'gaveup')

    // THE RELOAD OFFER — the one control this card draws, and only once the model has given up.
    //  The owner, 2026-08-10: *"we may give them a page reload button if we think it might be that
    //   time"*. `gaveup` IS that time, and it is the registrar's ruling rather than this file's guess,
    //    which is the only reason a face is allowed to draw it at all.
    //  IT IS OFFERED BECAUSE THE PAGE CAN GENUINELY BE UNRECOVERABLE FROM INSIDE, and that is not a
    //   hypothetical — it is the state this button was written next to. `Radio_go` sets 'playing'
    //    BEFORE it awaits `Sound_gat`, which pends forever on a tab that never got its audio gesture:
    //     the radio then sits in 'playing' with no device, no record and a suspended AudioContext.
    //      In THAT state `Radio_toggle` reads 'playing' and calls `Radio_pause`, so the play button
    //       pauses, and `Radio_nudge`'s pump gate refuses to restart for the same reason. There is
    //        nothing on the page a person can press that starts the music. A reload is the honest
    //         remedy, so offer it rather than leaving them to find it in a browser menu.
    //  NOT WHILE A PERMISSION OR AN INVITE IS PENDING (the same two guards the old tap carried): a
    //   reload would throw away a granted permission's gesture and re-fire an unspent ?Iz, and in both
    //    cases the thing to do is the thing already on the card.
    let offer_reload = $derived(settled && !gate.wanted && !landing)

    // the exit, evaluated on every poll. An $effect and not a $derived because it LATCHES — the whole
    //  point is that the answer is one-way.
    //  THERE IS EXACTLY ONE AUTOMATIC EXIT AND IT IS ARRIVAL. Everything else on this list is a person
    //   or a preference: the ▦ guts switch, or a machine tab. That is the whole shape of the file now,
    //    and every line of it was paid for by a version that lifted on a clock instead.
    //   (`carried_on` went with the tap. It was the only lift a person could reach from this card, and
    //     it is now ▦ — one control, drawn by the page, setting a pref that PERSISTS, which the tap
    //      never did: dismissing the Butler taught the tab nothing and the next reload asked again.)
    $effect(() => {
        void tick
        if (done) return
        if ((H?.c as any)?.butler_done) { done = true; return }    // already lifted earlier this tab
        if (machine_tab || guts) { lift(); return }
        if (gate.wanted) return                                   // a permission is not progress
        if (landing) return                                       // …and neither is an unspent invite
        if (view.arrived === 'arrived') { lift(); return }        // ★ THE ONLY AUTOMATIC EXIT
        // 'none' — NOT YET. No registrar has declared a finish line, which on this page always means
        //  the spine is still loading and the Book has not reached its registration beat. It is the
        //   reading of the first seconds of every boot, and treating it as "there will never be one"
        //    is what four separate impatience exits did. We hold. If the board never fills at all the
        //     machine truly never started, and ▦ is on screen the whole time — silence with a way out
        //      always drawn beats a gate that lies about being up.
        // 'coming' / 'gaveup' — hold too. `gaveup` changes what this screen SAYS (see `settled`), not
        //  whether it is up: the sentence it exists to deliver arrives at exactly that moment.
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
    //  …EXCEPT ONCE THE MODEL HAS GIVEN UP, where the next unfinished sentence would be the arrival
    //   claim itself — "the glass is up and music is playing" over a card that exists to say it isn't.
    //    This one sentence is the screen talking about ITSELF, not a second opinion about a row: the
    //     rows keep their own marks in the arc below, and the registrar's advice says what to do.
    let headline = $derived(
        settled ? 'this is as far as it goes on its own'
        : view.waiting[0]?.sentence
        || view.unfinished[0]?.sentence
        || 'starting up')
    let left = $derived(view.waiting[0]?.left ?? 0)

    // ms from page start, as a person reads it: sub-10s keeps a decimal (the difference between 1.2s
    //  and 8.9s is the whole diagnosis), past that it is noise.
    function secs(ms: number) {
        const s = ms / 1000
        return '+' + (s < 10 ? s.toFixed(1) : Math.round(s)) + 's'
    }

    // (`ago()` went with the notice ring — it had no other reader, and a helper kept "in case" is how
    //  a file grows a second surface nobody asked for.)

    // THE STATUS BRACKET — the owner 2026-08-10: *"must say less junk in the meantime… perhaps just
    //  make it look like Linux starting up `[ OK ] friend is online: $randompick`"*.  Everyone who has
    //   ever watched a machine come up already knows how to read this column, which is the whole
    //    argument for it: no legend, no glyph to learn, and a listener who does not care can ignore a
    //     tidy left margin far more easily than a row of symbols.
    //  IT RE-DECIDES NOTHING.  `tone` is the model's word (Supervisor_tone's six), and this maps word →
    //   appearance, which is exactly the half a face is allowed to own.  A tone with no case here falls
    //    to the blank bracket rather than inventing a seventh meaning.
    //  All six are SIX CHARACTERS between the brackets so the sentences line up in a monospace column;
    //   a ragged margin is the thing that stops a list reading as a boot log.
    const BRACKET: Record<string, string> = {
        good:    '  OK  ',
        bad:     'FAILED',
        todo:    '      ',
        waiting: ' .... ',
        moot:    ' SKIP ',
        blind:   '  ??  ',
    }
    function bracket(tone: string) {
        return '[' + (BRACKET[tone] ?? '      ') + ']'
    }

    // NO WRITER HERE. This file only ever READS `guts` — the one control that sets it is ▦, which the
    //  page fixes in its top-right corner above this FaceSucker. Two writers onto one pref is how a
    //   state ends up with two meanings, and the previous cut had exactly that.
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
                        <!-- THE SPINNER IS A CLAIM: "something is still happening". Once the model has
                             given up on the arrival that claim is false, and a spinner over a machine
                             that has stopped trying is the single most dishonest thing this file could
                             draw. So it goes, and the advice below carries the card instead. -->
                        <!-- LESS JUNK IN THE MEANTIME (the owner 2026-08-10). A spinner and a headline
                             restating the row the log is already showing were two more things moving on
                             a screen whose whole job is to be read. The log below says what is
                             happening, line by line, and says it better.
                             The headline survives for the ONE case the log cannot state, which is the
                             screen talking about itself: the model has given up and there is no next
                             line coming. That is not a row and never was. -->
                        {#if settled}
                            <h2 in:fly={{ y: 8, duration: 320, easing: quintOut }}>{headline}</h2>
                        {/if}
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
                                    <span class="m">{bracket(l.tone)}</span>
                                    <span class="s">
                                        {l.sentence}
                                        <!-- THE NOTE IS WHAT MAKES THIS MID-COMPLEXITY. The cell has
                                             room for a sentence; this has room for the sentence AND
                                             its evidence ("no A:Vyto in any of 2 House(s)", "12
                                             records"). §5: attribution before action — a claim with
                                             no evidence under it is a riddle, and the panel should
                                             not be the only place a person can read one. -->
                                        {#if l.note}<span class="note">: {l.note}</span>{/if}
                                    </span>
                                    <!-- THE WATERFALL. `won` is ms from page start to the moment this
                                         claim came true — the efficiency ledger, on the listener's own
                                         screen and on every boot rather than in a profiling session
                                         somebody has to arrange. A slow leg names itself here. -->
                                    {#if l.waiting && l.left}<span class="secs">{l.left}s</span>
                                    {:else if l.won}<span class="won">{secs(l.won)}</span>{/if}
                                </li>
                            {/each}
                        </ul>
                    {/if}

                    <!-- THE NOTICE RING IS GONE FROM THIS SURFACE (2026-08-10, "less junk"). It said
                         the same things the arc above says, in a different order, under a second set of
                         timestamps — so a listener read every fact twice and had to work out which list
                         was which. Two lists is not more information, it is more reading.
                         Nothing is lost: the ring is `.c` on the model, SupervisorPanel still shows all
                         twelve, and `runner_ask supervisor` prints it as "what turned, oldest first".
                         It was always the developer's half of this screen. -->

                    <!-- THE GIVE-UP, IN WORDS. A wait that quietly expires tells a listener nothing;
                         this is the whole of the owner's *"it should also explain clearly that no
                         friend is online and you can play local music instead"*. Calm, not red — it
                         is not a fault, it is the machine being honest about what it settled for. -->
                    {#if view.advice.length && !landing}
                        <div class="advice" transition:fade={{ duration: 240 }}>
                            {#each view.advice as a}<p>{a}</p>{/each}
                        </div>
                    {/if}

                    <!-- THE ONE CONTROL THIS CARD DRAWS, and only once the model has given up (see
                         `offer_reload`). Not a dismiss — a dismiss is ▦, which the page draws above
                         this FaceSucker at all times and which PERSISTS the choice. This is the
                         remedy for the state `gaveup` actually describes: a boot that cannot finish
                         on its own, which on this page can mean a radio wedged in 'playing' with no
                         audio device, where every control the listener can reach does the wrong
                         thing. Placed under the advice because the advice is what makes it make
                         sense; a reload button above the reason is just a scary button. -->
                    <!-- A TAP IS THE CURE, SO OFFER A TAP (2026-08-11). Watched live: the model gave
                         up with `why=… the press is parked on a gesture` — exactly right — and this
                         card offered a page RELOAD, which would have worked only by accident, via the
                         click that dismisses it. The owner instead left the Butler and hit next track
                         and the music started. So when the registrar says `remedy:'gesture'`, draw the
                         button whose PRESS IS THE REMEDY: the click satisfies the AudioContext resume
                         that everything is parked on, and `Radio_toggle` (which no longer pauses a
                         radio with no device) turns it on in the same gesture. Self-curing, and it
                         keeps the session instead of throwing it away to achieve the same tap.
                         WE DO NOT DECIDE THIS — `remedy` is the registrar's word. A face reading the
                         advice SENTENCE for keywords would be the second opinion this file refuses. -->
                    {#if offer_reload && view.remedy === 'gesture'}
                        <button class="reload" transition:fade={{ duration: 240 }}
                                onclick={() => H?.Sounditron_press_play?.()}>
                            ▶ start the music
                        </button>
                    {:else if offer_reload}
                        <button class="reload" onclick={() => location.reload()}
                                transition:fade={{ duration: 240 }}>
                            reload the page ↻
                        </button>
                    {/if}
                    <!-- THERE IS NO SWITCH ON THIS CARD (the owner 2026-08-10: *"lose `show me the
                         guts`"*). The persistent one is ▦, fixed in the page's top-right corner and
                         drawn ABOVE this FaceSucker, so it is reachable from here without this file
                         owning a second door onto the same state — which is `boot_gate`'s lesson. -->

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
    /* (the spinner went with the headline — the `[ .... ]` bracket on the row we are actually waiting
        for says the same thing, in the place the eye is already reading.) */
    @media (prefers-reduced-motion: reduce) {
        .glint, .aurora { animation: none; }
    }
    /* LOG-LOOKING: left-aligned, one row per fact, marks and clocks in a fixed gutter so the eye
       scans a column rather than re-reading centred prose. The card is wider for the same reason. */
    /* MONOSPACE THROUGHOUT, because the bracket only works as a column. In a proportional font
       `[  OK  ]` and `[FAILED]` are different widths and the sentences no longer start at the same
       x — which is precisely the thing that makes a boot log scannable and a list of sentences not. */
    .arc { list-style: none; padding: 0; margin: .3rem 0 0; font-size: .88rem;
           width: 100%; display: flex; flex-direction: column; gap: .1em; text-align: left;
           font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
    .arc li { display: flex; gap: .6em; align-items: baseline;
              padding: .12em .3em; border-radius: .35em; transition: opacity 300ms ease; }
    .arc .m { flex: 0 0 auto; white-space: pre; letter-spacing: -.02em; }
    .arc .s { flex: 1 1 auto; min-width: 0; }
    /* the note runs ON THE SAME LINE now (": Righto", ": 12 records") — the owner's
       `[ OK ] friend is online: $randompick`. It was a block, which made every row two rows and
       turned a nine-line log into an eighteen-line wall. */
    .arc .note { opacity: .55; }
    .arc li.done    { opacity: .35; }
    .arc li.good    { color: #9fd8a8; }
    .arc li.waiting { color: #ffd08a; background: rgba(255, 208, 138, .06); }
    .arc li.bad     { color: #ff9b8a; }
    .arc li.todo    { color: #cfd8e0; }
    .arc li.blind   { color: #9aa5b5; }
    /* moot — nobody asked for this, so it is the quietest row on the card.  Dimmer than `blind`:
       "I could not look" is worth a glance, "nothing is asking" is not. */
    .arc li.moot    { color: #7b8794; opacity: .55; }
    /* +3.2s — when this claim came true, measured from page start.  Right-hand gutter, tabular, so a
       boot reads as a waterfall down the column rather than as prose. */
    .arc .won { opacity: .45; font-variant-numeric: tabular-nums; font-size: .82em;
                font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
    /* (`.log` went with the notice ring.) */
    /* the door — the panel brings its own chrome, so this only gives it the card's full width and
       an honest left edge to read down. Deliberately no `:global` restyling of the panel: it is the
       same door as the strip's and the cell's, and a Butler-only skin would be a fourth opinion. */
    .door { width: 100%; text-align: left; }
    .advice { margin: .1rem 0 0; display: flex; flex-direction: column; gap: .25em;
              max-width: 24em; color: #cfe0ee; font-size: .95rem; line-height: 1.45;
              padding: .55em .8em; border-radius: .5rem;
              background: rgba(127, 199, 255, .07); border: 1px solid rgba(127, 199, 255, .14); }
    .advice p { margin: 0; }
    /* the reload offer — only ever on screen with the give-up advice above it, so it is sized like
       the one thing left to do rather than like a dismiss.  (`.carry` and its `.big` variant were
        here; they went with the tap.) */
    .reload {
        margin-top: .3rem; background: none; color: #e8f3ff; cursor: pointer;
        border: 1px solid #6ea3bf; border-radius: .5rem; padding: .6em 1.4em; font-size: 1rem;
        transition: color 140ms ease, border-color 140ms ease, background 140ms ease;
    }
    .reload:hover { border-color: #9ccbe4; background: rgba(255,255,255,.06); }
</style>
