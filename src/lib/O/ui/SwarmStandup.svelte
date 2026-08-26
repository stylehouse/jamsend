<script lang="ts">
    // SwarmStandup — the front door's STANDUP, with no face on it.
    //
    //  Until 2026-08-09 these three effects lived inside InvitePanel, which was fine only because
    //   InvitePanel was mounted unconditionally in BigSoundland's strip.  Now that invite management
    //    has moved INTO the glass (DoorFace), that is no longer true: a face mounts when its cell is
    //     drawn, and a Vyto cell crushed to the icon register draws no face at all.  Left in the
    //      panel, the standup would have become conditional on the Door cell happening to be roomy —
    //       i.e. the station would silently not stand, nobody could dial you, and the tell would be a
    //        friend's scan timing out with everything on this side looking healthy.
    //
    //  So it moves here and is mounted like the spine shims: hidden, outside the view switch, so no
    //   view choice can starve it (the same doctrine, and the same hazard, BigSoundland's
    //    `spine_shims` comment already records).  Renders nothing.
    //
    //  Three things, in dependency order — each retries on H.version bumps until it takes:
    //   · the live self  — the one signing key Auto's Clustation_concrete stood up
    //   · the station    — the prepub-addressed relay socket + armed swarm frame kinds; the inviter
    //                       must be dialable BEFORE anyone scans
    //   · the share      — the standing music session: my stock serves every Music-granted friend,
    //                       their casts fill per-friend %MusuThem crates
    //  …plus the boast on every new seal, which belongs with them for exactly the same reason.
    let { H }: { H: any } = $props()

    // THE WALL-CLOCK TICK (2026-08-11).  These effects used to ride H.version alone, on the belief
    //  "the belief loop's idle cadence keeps this effect re-running" — MEASURED FALSE during the
    //   arrival Book: the run steps in its OWN House, Mundo held still for ~10s stretches, and the
    //    share armed only when the Book's completion finally bumped Mundo (share-asks n=1..16 in the
    //     first 1.6s, then silence to step 9 — the reload jam).  A standup must not trust the world
    //      it is standing up to keep waking it, so every effect below also rides this 750ms tick.
    //  Not a clock that LIFTS anything (the Butler's law) — it only re-asks idempotent gates.
    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 750)
        return () => clearInterval(iv)
    })

    // LATCHED plain $state, not $derived (reactivity_docs): Swarm_live_self() can THROW transiently
    //  mid-Atime and return null.  Assign only on a truthy, CHANGED ref; never back to null — the
    //   identity never un-exists, so the latch is honest.
    let self = $state<any>(null)
    $effect(() => {
        void H?.version
        void tick
        if (typeof H?.Swarm_live_self !== 'function') return
        let v: any = null
        try { v = H.Swarm_live_self() } catch { v = null }
        if (v && v !== self) self = v
    })

    // THE COHORT STANDS FIRST (Portability §10, the 2026-08-27 burn): before this tab binds ANY
    //  relay address it asks "am I alone in this profile?" — the Web Lock decides, the
    //   BroadcastChannel census names the taken addresses and registers siblings on the %Sibling
    //    roster (its first app-path caller). Fire-and-forget with its own latch; the station
    //     effect below GATES on the answer (top.c.cohort), which cohort_stand always produces
    //      within its 250ms census budget — lockless browsers and jsdom get {primary:true,
    //       lockless:1} immediately, so nothing here can hang a boot.
    let cohorted = $state(false)
    $effect(() => {
        void tick
        if (cohorted || !self || typeof H?.Swarm_cohort_stand !== 'function') return
        cohorted = true
        H.Swarm_cohort_stand(self)
    })

    let stood = $state(false)
    $effect(() => {
        void H?.version
        void tick
        if (stood || !self || typeof H?.Swarm_station_up !== 'function') return
        if (!(H.top_House?.()?.c?.cohort)) return   // census still inside its 250ms budget
        const w = H.Swarm_station_world?.()
        if (w && H.Swarm_station_up(w, self)) {
            stood = true
            // TRACE the latch (diagnosis 2026-08-11: share-up lands ~10s after radio-w stands, and
            //  the only live caller of Swarm_share_up is the effect below — so the ring must date
            //   when this chain could first have run, and how often it actually does).
            try { H.Radio_trace?.(null, { ev: 'standup-stood' }) } catch {}
        }
    })

    // the radio world stands later (Stoker_ensure stamps it), so this retries until it appears
    let shared = $state(false)
    let share_asks = 0
    $effect(() => {
        void H?.version
        void tick
        if (!stood || shared || !self || typeof H?.Swarm_share_up !== 'function') return
        const w = H.Swarm_station_world?.()
        // exponentially-thinned ask trace (1st, 2nd, 4th, 8th…): the ring must show the RETRY
        //  CADENCE — a share that arms late is either "asked and refused" (the gate's fault) or
        //   "never asked" (this effect starved of version bumps), and those want opposite fixes.
        share_asks++
        if ((share_asks & (share_asks - 1)) === 0) {
            try { H.Radio_trace?.(null, { ev: 'share-ask', n: share_asks }) } catch {}
        }
        if (w && H.Swarm_share_up(w, self)) shared = true
    })

    // BOAST on every NEW seal (Radio_todo §9.1c).  Zeros send too — an empty shelf is an honest
    //  boast.  `gossiped` is a MONOTONIC high-water: a mid-Atime read can catch transacting state
    //   and flicker friends 1→0→1, and resetting the mark on shrink turned every flicker into a
    //    fresh boast (the 2026-07-18 ive_got storm, seq 300+).  Never lower it.
    let friends = $derived.by(() => {
        void H?.version
        void tick
        try {
            if (!self || typeof H?.Swarm_peering !== 'function') return []
            return (H.Swarm_peering(self)?.o({ Pier: 1 }) ?? []) as any[]
        } catch { return [] }
    })
    let gossiped = 0
    $effect(() => {
        const n = friends.length
        if (n <= gossiped) return
        gossiped = n
        try {
            const w = H.Swarm_station_world?.()
            if (w && typeof H?.Swarm_gossip_music === 'function') H.Swarm_gossip_music(w, self)
        } catch {}
    })

    // THE FRIEND COUNT, published for the Butler (Supervisor_todo §0 — "should the Butler show the
    //  door whenever the person has no friends yet?").  The Butler may name no subsystem, so it
    //   cannot ask Swarm_*; and InvitePanel — the door's face — is only SOMETIMES mounted, so its
    //    beacon cannot carry a fact the Butler needs before any door is drawn.  This file is the
    //     door's STANDUP, mounted outside the view switch on every music page: the always-on half
    //      of the same subsystem, which makes it the one honest publisher.
    //  ITS OWN KEY, not a field on `H.c.door` — the panel REPLACES that object wholesale every pass,
    //   and two writers onto one state is boot_gate's lesson.  ABSENT means CANNOT KNOW YET (the
    //    ghosts are still depositing, or no self stands): only a COUNTED zero may ever open a door,
    //     because a pre-ghost zero would flash the join offer at every established user on every
    //      boot.  Plain `.c` — the Butler polls, nothing needs to react, and it must never snap.
    //  A ZERO MUST OUTLAST A HOLD TO BE BELIEVED (reactivity_docs' transacting-read rule, and this
    //   file's own gossip comment: a mid-Atime read can flicker friends 1→0→1).  A transient zero
    //    stamped here opens a fullscreen door on an established tab, so: a positive count publishes
    //     at once and NEVER lowers to zero this session (piers retire via %NotGrant, they are never
    //      deleted — the count is monotonic in truth, so the latch is honest, the same argument as
    //       `gossiped` above); a zero publishes only once it has stood for 5s of re-reads.  The
    //        wall-clock tick above keeps this effect re-running (NOT the belief loop's idle cadence
    //         — measured still for ~10s stretches during the arrival Book), so a genuine zero still
    //          lands well inside a new user's first patient moments.
    let zero_since = 0
    $effect(() => {
        void H?.version
        void tick
        if (!H?.c) return
        if (!self || typeof H?.Swarm_peering !== 'function') return
        const n = friends.length
        if (n > 0) { zero_since = 0; (H.c as any).door_friends = n; return }
        if ((H.c as any).door_friends > 0) return
        if (!zero_since) { zero_since = Date.now(); return }
        if (Date.now() - zero_since >= 5000) (H.c as any).door_friends = 0
    })

    // …AND WHETHER THE OLD GARDEN SENT THEM, published the same way and for the same reason
    //  (2026-08-12, the owner asking whether the Invite is *"totally robust"* — this was the hole).
    //  A relic invite is `#<pad><prepub>-<advice>-<sign>` in the URL FRAGMENT, so `boot_param`
    //   cannot see it and the Butler's `landing` — which reads `?Iz=` — is false for one.  A
    //    brand-new person got the door anyway, by the accident of having no friends; anyone who
    //     ALREADY had a friend and followed an old link landed on nothing at all.  No door, no
    //      notice, not even the name of whoever sent it.  The app simply said nothing.
    //  IT IS AN OFFER, NEVER A HOLD, and the distinction is load-bearing.  `landing` holds the
    //   screen until the token resolves; a relic CANNOT resolve here yet (rung 1 parses it, but the
    //    old key and spend ledger are still in the old garden's Dexie), so holding on one would be a
    //     trap with no exit — the exact permanent-trap shape the door's own notes keep warning about.
    //      The Butler therefore reads this at the `friendless` rung, where the door is an offer the
    //       arrival lift can still walk past.
    //  STAMPED ONCE: the URL does not change under us and the parse is pure, so the first pass that
    //   can see the verb settles it forever.  Absent still means CANNOT KNOW YET (Swarm not
    //    deposited), which is the same three-valued reading `door_friends` uses above.
    $effect(() => {
        void H?.version
        if (!H?.c) return
        const c = H.c as any
        if (c.door_relic !== undefined) return
        if (typeof location === 'undefined' || typeof H?.Swarm_legacy_of_url !== 'function') return
        let r: any = null
        try { r = H.Swarm_legacy_of_url(location.href) } catch { r = null }
        c.door_relic = r ? 1 : 0
    })
</script>
