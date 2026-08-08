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

    // LATCHED plain $state, not $derived (reactivity_docs): Swarm_live_self() can THROW transiently
    //  mid-Atime and return null.  Assign only on a truthy, CHANGED ref; never back to null — the
    //   identity never un-exists, so the latch is honest.
    let self = $state<any>(null)
    $effect(() => {
        void H?.version
        if (typeof H?.Swarm_live_self !== 'function') return
        let v: any = null
        try { v = H.Swarm_live_self() } catch { v = null }
        if (v && v !== self) self = v
    })

    let stood = $state(false)
    $effect(() => {
        void H?.version
        if (stood || !self || typeof H?.Swarm_station_up !== 'function') return
        const w = H.Swarm_station_world?.()
        if (w && H.Swarm_station_up(w, self)) stood = true
    })

    // the radio world stands later (Stoker_ensure stamps it), so this retries until it appears
    let shared = $state(false)
    $effect(() => {
        void H?.version
        if (!stood || shared || !self || typeof H?.Swarm_share_up !== 'function') return
        const w = H.Swarm_station_world?.()
        if (w && H.Swarm_share_up(w, self)) shared = true
    })

    // BOAST on every NEW seal (Radio_todo §9.1c).  Zeros send too — an empty shelf is an honest
    //  boast.  `gossiped` is a MONOTONIC high-water: a mid-Atime read can catch transacting state
    //   and flicker friends 1→0→1, and resetting the mark on shrink turned every flicker into a
    //    fresh boast (the 2026-07-18 ive_got storm, seq 300+).  Never lower it.
    let friends = $derived.by(() => {
        void H?.version
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
</script>
