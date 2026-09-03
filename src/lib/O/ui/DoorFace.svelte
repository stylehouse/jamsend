<script lang="ts">
    import { calm_watch } from "./calm"
    calm_watch()   // measure the fps once; under ~40 the glow below is switched off (calm.ts)
    import { lifewatch } from './micro/lifetell'   // DIAGNOSTIC — strip with the rest of the remount probes
    import InvitePanel from './InvitePanel.svelte'
    import DeleteX from './micro/DeleteX.svelte'   // the confirmey delete (arm → "forget?" → confirm)
    // DoorFace — WHO AM I and WHO'S WITH ME, floating in the glass: the identity + front-door
    //  arc as the prioritised, for-the-user's-eyes face (the human's ?Iz ask, 2026-07-19).
    //   Mounted by Cytui on the %Door particle (glass_kinds.ts).  Everything here reads LIVE
    //    House state — the particle is only the cell anchor:
    //     · the self: Swarm_live_self (nick · prepub8 · born, with a ✨ badge on born-today)
    //     · the door: H.c.door — InvitePanel's landing beacon (a scanned ?Iz verifying,
    //        auto-joining, sealed) — runtime .c, never snapped
    //     · the friends: sealed %Piers with their Music grant, records boast, and the pulse
    //        liveness dot (pier.c.heard_at — green within 12s, dim beyond: a reloaded tab
    //         goes dim HERE, in the other client's glass)
    let { n, H } = $props()

    // DIAGNOSTIC (2026-08-04, the KeepFace remount hunt — strip with the rest of the probes): the
    //  second CONTROL rung, a face whose source particle the DOWNLOAD never touches.  If Door's
    //   serial climbs too, nothing about the churn is Repli-data-driven — it's the glass rebuilding.
    lifewatch(H, 'face:Door', () => 'door')

    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 1000)
        return () => clearInterval(iv)
    })

    let face = $derived.by(() => {
        void H?.version
        void tick
        let self: any = null
        try { self = typeof H?.Swarm_live_self === 'function' ? H.Swarm_live_self() : null } catch { self = null }
        const today = new Date().toISOString().slice(0, 10)
        const door = (H?.c?.door ?? {}) as any
        let friends: any[] = []
        try {
            if (self && typeof H?.Swarm_peering === 'function') {
                const rw = (H as any)?.c?.radio_w
                const playing = !!rw?.o?.({ Radio: 1 })?.[0]?.c?.rec
                // FAMILY SUPERSEDES FRIENDSHIP (owner 2026-08-31: both tabs listed "you" / "captain
                //  Grav you" among the piers — each body seeing its own family, husk included, dressed
                //   as friends).  A pier whose key matches a roster %Body — or my own soul (the redeem
                //    husk) — is a ceremony RAIL: its grants still ground the Posts, but the Door shows
                //     those people in the family box, never the pier list.  Prefix-compare, the
                //      prepub-vs-full-pub law.
                const fam_pubs = ((typeof H?.Swarm_body_roster === 'function' ? H.Swarm_body_roster(self) : []) as any[])
                    .map((b: any) => String(b?.sc?.pub ?? '')).filter(Boolean)
                fam_pubs.push(String(self?.sc?.prepub ?? ''))
                const kin = (p: any) => {
                    const keys = [String(p?.sc?.pub ?? ''), String(p?.o({ Peering: 1 })?.[0]?.sc?.pub ?? '')].filter(Boolean)
                    return keys.some(k => fam_pubs.some(fp => fp && (k.startsWith(fp) || fp.startsWith(k))))
                }
                friends = ((H.Swarm_peering(self)?.o({ Pier: 1 }) ?? []) as any[]).filter((p: any) => !kin(p)).map((p: any) => {
                    // the latest suggestion FROM them (by === their pub), with its mirror rec
                    //  resolved by enid against their crate when the share already carried it —
                    //   resolvable means ▶ plays it right here.
                    const sug = (p.o({ Suggest: 1 }) as any[]).filter(s => s.sc.by === String(p.sc.pub)).at(-1)
                    let sug_rec: any = null
                    if (sug && rw) {
                        try {
                            const shelf = rw.o({ MusuThem: 1, pub: String(p.sc.pub) })[0]?.o({ stock: 1 })?.[0]
                            sug_rec = ((H as any)?.Ra_rec_find
                                ? (H as any).Ra_rec_find(shelf, { Record: 1, id: String(sug.sc.id) })
                                : shelf?.o({ Record: 1, id: String(sug.sc.id) })?.[0]) ?? null
                        } catch { sug_rec = null }
                    }
                    // presence in three honest rungs off heard_at (their pulse heartbeat, ~5s):
                    //  here (<15s ≈ 2 missed pulses) · fading (<45s) · away.  The old 12s window
                    //   flickered on one dropped pulse — "doesn't seem reliable", the human.
                    const ago = p.c?.heard_at ? Math.round((Date.now() - p.c.heard_at) / 1000) : null
                    const rung = ago == null ? 'away' : ago < 15 ? 'here' : ago < 45 ? 'fading' : 'away'
                    // SEAL COMPLETENESS — the half-seal, made visible (Radio_todo §0.9, 2026-08-06).
                    //  A whole %Pier holds BOTH grants: one signed by them, one signed by me.  Hold
                    //   only one and the link SILENTLY half-works — asks leave, answers die on the
                    //    doorstep ("🛰☠ deliver: no Pier"), and both ends read as merely SLOW.  That
                    //     cost a live evening, and `runner_ask world` could see it in one line while
                    //      the glass could not.  So the glass says it too: "sealing — 1 of 2".
                    //  Matched by PREFIX because `by` rides as a prepub here and a full pub elsewhere
                    //   (the grant mint form-matches whichever the beacon carried) — a prefix compare
                    //    is true for both and cannot false-positive across two different keys.
                    const my_pre = String(self?.sc?.prepub ?? '')
                    const their_pre = String(p.sc.pub ?? '')
                    const grants = (p.o({ Grant: 1 }) as any[])
                    const has = (who: string) => !!who && grants.some(g => {
                        const by = String(g.sc.by ?? '')
                        return by.startsWith(who) || who.startsWith(by)
                    })
                    const mine_ok = has(my_pre), theirs_ok = has(their_pre)
                    const seal = (mine_ok && theirs_ok) ? 2 : (mine_ok || theirs_ok) ? 1 : 0
                    return {
                        seal,
                        seal_missing: seal === 1 ? (mine_ok ? 'they never granted back' : 'we never granted back') : null,
                        pub: String(p.sc.pub),
                        name: String(p.sc.friendly || String(p.sc.pub).slice(0, 8)),
                        // split so the row can show "Gwop eed831f1" — friendly prominent, prepub small (owner
                        //  2026-08-31).  friendly '' when unnamed (then only the pub8 shows, once).
                        friendly: p.sc.friendly ? String(p.sc.friendly) : '',
                        pub8: String(p.sc.pub).slice(0, 8),
                        // a MyCave pier is your OWN device (a Cave), not a friend — quietly marked 🔗 so it
                        //  doesn't read as a stranger.  The adopt ceremony itself lives in the Link cell now.
                        cave: !!p.o({ Grant: 'MyCave' })[0],
                        music: !!p.o({ Grant: 'Music' })[0],
                        records: p.o({ IveGot: 1, by: 'records' })[0]?.sc?.count,
                        rung,
                        ago,
                        sug: sug ? { title: sug.sc.title || sug.sc.id, note: sug.sc.note } : null,
                        sug_rec,
                        can_suggest: playing && !!p.o({ Grant: 'Music' })[0],
                        // RETIRED = every feature NotGrant-revoked (Swarm_pier_forget).  The Pier row stays in
                        //  the ledger as history, but the Door stops SHOWING it — "we don't need too much in
                        //   there" (owner 2026-08-29, six dead Incognito link-test piers cluttering the list).
                        retired: !((H as any).Swarm_pier_live?.(p, 'Music') || (H as any).Swarm_pier_live?.(p, 'MyCave')),
                    }
                }).filter((f: any) => !f.retired)
            }
        } catch { friends = [] }
        // SORTED BY TIER THEN STABLE PUB (2026-08-29, fix for the thrash bug).  The original sort
        //  used raw `ago` (seconds since last pulse), which changed every tick for every connected
        //   peer — the comparator produced a new ordering each second and the list shuffled constantly.
        //  The fix: bucket into tiers (here=0 · fading=1 · away=2) from the ALREADY-COMPUTED `rung`
        //   and sort by tier first, then by `pub` (stable string) within a tier.  Peers move between
        //    tiers only when the rung thresholds (15s / 45s) are crossed — a coarser, deliberate
        //     reorder — and within a tier the list never jumps.  The owner's intent (most-recent-first)
        //      is preserved at the tier level.
        const tier = (f: any) => f.rung === 'here' ? 0 : f.rung === 'fading' ? 1 : 2
        friends.sort((a, b) => {
            const dt = tier(a) - tier(b)
            if (dt !== 0) return dt
            return String(a.pub) < String(b.pub) ? -1 : String(a.pub) > String(b.pub) ? 1 : 0
        })
        // MY OWN TIME-ALIVE, folded in beside the peers (the human's §0.9 trim, 2026-08-06: "move
        //  the time-alive/uptime readout INTO the list of Piers — it is networky, it belongs beside
        //   the peers rather than owning a cell").  It reads the SAME `.c.since` the retired
        //    UptimeFace read, off the %Uptime row in the radio world; `.c` so it resets on reload,
        //     which is exactly the point — a near-zero reading right after a reload is the "did my
        //      reload land?" tell, and it now sits next to the friends' own here/fading/away rungs
        //       so the whole liveness picture is ONE reading instead of two cells.
        let up: { label: string, fresh: boolean } | null = null
        try {
            const since = +((H as any)?.c?.radio_w?.o?.({ Uptime: 1 })?.[0]?.c?.since ?? 0)
            if (since) {
                const secs = Math.max(0, Math.round((Date.now() - since) / 1000))
                const h = Math.floor(secs / 3600), m = Math.floor((secs % 3600) / 60), s = secs % 60
                up = { label: h ? `${h}h ${m}m` : (m ? `${m}m ${s < 10 ? '0' : ''}${s}s` : `${s}s`), fresh: secs < 10 }
            }
        } catch { up = null }
        // THE FAMILY ROSTER (facet D — "Captain Grav and Cave Guw"): the soul's %Body rows, each an
        //  INSTANCE (role × name) of the one soul.  Read-only walk (Swarm_body_roster never mints);
        //   Swarm_body_mine marks which row is THIS body (computed off the body key, never a stored
        //    flag).  Shown only once a real division exists (≥2 rows) — a lone body says nothing.
        //     The name is the instance's own (name-gate name), the address its family seat.
        let family: any[] = []
        let flows: any[] = []   // the Plot's Mag-flows (standing %Reach rows), from → to
        // THIS body's own instance (facet D): its role + name-gate name, shown as a title badge so the
        //  header says WHO THIS DEVICE IS ("· CAVE Guw") beside the SOUL name (what friends see + edit).
        //   Null for a lone/undivided body — nothing to distinguish.
        let instance: any = null
        try {
            const roster = (typeof H?.Swarm_body_roster === 'function' ? H.Swarm_body_roster(self) : []) as any[]
            const mineRow = (typeof H?.Swarm_body_mine === 'function' ? H.Swarm_body_mine(self) : null) as any
            const minePub = mineRow?.sc?.pub ? String(mineRow.sc.pub) : ''
            const organsize = (row: any, kind: string) => {
                try { const o = (H as any)?.Swarm_organ_of?.(row, kind); return o ? +(o.sc?.tracks || 0) : null } catch { return null }
            }
            // THE CREW SHELF IS THE LEDGER (Crew_todo §3, live 2026-09-03: the %Body roster listed two
            //  "Captain Grav"s, a "Captain Grewp" that was the Cave's pre-merge self, and three dead Caves —
            //   grow-only gossip union, never a membership).  Once /Crew stands, the Door reads IT: one row
            //    per mate, role off the row, name + presence resolved by Swarm_crew_view; the roster only
            //     lends its organ sizes.  A pre-migration account (no /Crew) keeps the roster view below.
            const crewv = (typeof (H as any)?.Swarm_crew_view === 'function' ? (H as any).Swarm_crew_view(self) : []) as any[]
            const samek = (a: string, b: string) => !!(a && b && (a.startsWith(b) || b.startsWith(a)))
            if (crewv.length) {
                const meRow = crewv.find((m: any) => m.mine)
                if (meRow) instance = { role: meRow.role, name: meRow.name }
                family = crewv.filter((m: any) => !m.mine).map((m: any) => {
                    const brow = roster.find((b: any) => samek(String(b?.sc?.pub || ''), m.prepub) || (m.pub && samek(String(b?.sc?.pub || ''), m.pub)))
                    return {
                        role: m.role, name: m.name, pub: m.pub || m.prepub, pub8: m.pub8, addr: '', mine: false,
                        ago: m.ago, rung: m.rung, cert: !!m.cert, fresh: !!m.fresh,
                        pocket: brow ? organsize(brow, 'pocket') : null,
                        trove: brow ? organsize(brow, 'trove') : null,
                    }
                })
            } else {
            // UNGATED to a lone ROLED row (the owner's ruling): a Post is only ever conferred by a
            //  ceremony, so "CAVE Guw" deserves its badge even while the sibling's row hasn't arrived
            //   — a Cave that can't see its Captain yet should still know WHAT IT IS.  A truly
            //    undivided body has no %Body row at all and shows nothing, as before.
            if (mineRow && (roster.length >= 2 || mineRow.sc?.post)) {
                instance = { role: String(mineRow.sc?.post || 'body'), name: String(mineRow.sc?.name || '') }
            }
            if (roster.length >= 2) {
                // THE OTHERS ONLY (owner 2026-08-31: a greenlit "you" row is noise — the badge already
                //  says who I am).  Each sibling wears a presence rung off %Body `heard` — the standing
                //   particle the sibling pulse stamps — so "can the two of them see each other" has a
                //    visible answer: their dot is green because their pulse is landing HERE.
                const now_s = Math.floor(Date.now() / 1000)
                // THE PLOT (owner 2026-09-01: "the Plot is that box with all the semantics filled in"):
                //  each body a lane carrying its organ sizes (pocket/trove), read straight off the %Body
                //   row it describes.  organ replication (Swarm_organ_absorb) lands a sibling's sizes here,
                //    so the phone lane shows the laptop's trove.
                family = roster
                    .filter((b: any) => !(!!minePub && String(b?.sc?.pub || '') === minePub))
                    .map((b: any) => {
                        const heard = +(b?.sc?.heard || 0)
                        const ago = heard ? now_s - heard : null
                        return {
                            role: String(b?.sc?.post || 'body'),
                            name: String(b?.sc?.name || ''),
                            pub: String(b?.sc?.pub || ''),
                            pub8: String(b?.sc?.pub || '').slice(0, 8),
                            addr: String(b?.sc?.address || ''),
                            mine: false,
                            ago,
                            rung: ago == null ? 'away' : ago < 15 ? 'here' : ago < 45 ? 'fading' : 'away',
                            pocket: organsize(b, 'pocket'),
                            trove: organsize(b, 'trove'),
                        }
                    })
                // primary (bare seat) first, then by role then pub — stable, no per-tick shuffle
                family.sort((a, b) => (a.addr.includes('_') ? 1 : 0) - (b.addr.includes('_') ? 1 : 0)
                    || (a.role < b.role ? -1 : a.role > b.role ? 1 : (a.pub8 < b.pub8 ? -1 : 1)))
            }
            }
            // MY lane's organ (facet D badge grows into the Plot's own-lane sizes)
            if (instance && mineRow) {
                instance.pocket = organsize(mineRow, 'pocket')
                instance.trove = organsize(mineRow, 'trove')
            }
            // THE MAG-FLOWS (the Plot's arrows): the standing %Reach rows read straight off the peering —
            //  each a flow between bodies (from `by` → `to`), carrying its Mag (`of`) and live state.
            //   booked ⋯ / dispatched ⋯ / serving ↯ / arrived ✓ / refused ⚠.  Read-only walk.
            const glyph: Record<string, string> = { booked: '⋯', dispatched: '⋯', serving: '↯', arrived: '✓', refused: '⚠' }
            const nameFor = (key: string) => {
                if (!key) return ''
                const k = String(key)
                const hit = [...family, ...(instance ? [{ ...instance, addr: '', pub: minePub }] : [])]
                    .find((m: any) => (m.pub && (m.pub.startsWith(k) || k.startsWith(m.pub))) || m.role === k || m.addr === k)
                return hit ? (hit.name || hit.role || String(k).slice(0, 6)) : String(k).slice(0, 6)
            }
            const now_r = Math.floor(Date.now() / 1000)
            flows = ((H.Swarm_peering(self)?.o({ Reach: 1 }) ?? []) as any[]).map((r: any) => {
                const st = String(r?.sc?.state || 'booked')
                return {
                    of: String(r?.sc?.of || ''),
                    forv: String(r?.sc?.for || ''),
                    fromName: nameFor(String(r?.sc?.by || '')),
                    toName: nameFor(String(r?.sc?.to || '')),
                    state: st,
                    glyph: glyph[st] || '·',
                    ago: r?.sc?.at ? now_r - (+r.sc.at) : null,
                }
            })
        } catch { family = []; flows = [] }
        return {
            name: (self?.sc?.friendly || self?.sc?.nick) as string | undefined,
            named: !!self?.sc?.friendly,
            family,
            flows,
            instance,
            prepub: self?.sc?.prepub ? String(self.sc.prepub).slice(0, 8) : undefined,
            born: self?.sc?.born as string | undefined,
            newborn: !!self?.sc?.born && self.sc.born === today,
            // 🎧 LISTENING-ONLY (MobilenoFSA_todo §0 #3): this browser can't open a folder, so it's a
            //  radio terminal — and its identity is mortal (Dexie only) until Linked Devices travels
            //   it.  Read live off H.c.listen_only (set in Housing's boot-role branch); the badge is
            //    the one honest place that whisper lives.
            listen_only: !!(H as any)?.c?.listen_only,
            door,
            friends,
            up,
        }
    })

    // ── THE PERSISTENCE ACK (Persistence_todo §5.3) — "an Invite should not be half-done and get
    //  lost": one glyph that says whether everything settled is actually ON DISK.  Reads the health
    //   card (Swarm_persist_diag), re-derived on the 1s tick so "settling…" resolves before your
    //    eyes.  Null (no glyph at all) when there's nothing to say: no identity yet, or a borrowed
    //     body that doesn't own the write (mirror_muted — the bare-name holder answers for disk).
    let settle = $derived.by(() => {
        void tick
        try {
            const d = (H as any)?.Swarm_persist_diag?.()
            if (!d) return null
            // the contested name outranks everything — it is the one state where "settled ✓" would
            //  be a lie twice over (two writers, either one clobbering the other).  §7.4h: DoorFace
            //   is the ruled surface for this warning, and resolution stays the human's.
            if (d.stolen) return { state: 'stolen' as const, why: d.settle_why }
            if (d.mirror_muted) return null
            if (d.mirror_owed) return { state: 'owed' as const, why: d.settle_why }
            if (d.settle_owed || d.stash_saving) return { state: 'settling' as const, why: d.settle_why }
            const at = Math.max(+d.mirror_at || 0, +d.stash_durable_at || 0)
            if (at) return { state: 'settled' as const, at, why: d.settle_why }
            return null
        } catch { return null }
    })

    // ── THE BODIES LINE (Portability_todo §9) — which bodies of this soul stand where.  Three
    //  sources, all live and all soft: the cohort card (`top_House().c.cohort` — the boot census's
    //   one consumer contract: {primary, vessel, taken, lockless, at}; absent = no cohort ran,
    //    which is every Book and any API-less browser), the session address (`Swarm_address` —
    //     bare <prepub> or a <prepub>_N suffix after a Steal Back / non-primary standup), and the
    //      %Sibling roster on the identity's %Peering (cooperative co-holders — family, the thing
    //       that keeps the 👥 alarm honest).  Null unless there is ANOTHER body — a sibling tab or a
    //        division (≥2 %Body rows).  A LONE body is the unremarkable default whatever its address or
    //         primacy, and the Door spends no line on it ("there is no other yet").
    let bodies = $derived.by(() => {
        void H?.version
        void tick
        try {
            const ident = typeof H?.Swarm_live_self === 'function' ? H.Swarm_live_self() : null
            if (!ident) return null
            const coh = (H?.top_House?.()?.c?.cohort ?? null) as any
            const bare = String(ident.sc?.prepub ?? '')
            const addr = String(H?.Swarm_address?.(ident) ?? bare)
            const suffix = addr !== bare && addr.startsWith(bare + '_') ? addr.slice(bare.length) : ''
            const sibs = ((H?.Swarm_peering?.(ident)?.o({ Sibling: 1 }) ?? []) as any[]).map((s: any) => ({
                place: String(s.sc?.Sibling ?? ''),
                address: s.sc?.address ? String(s.sc.address) : '',
                role: s.sc?.duty ? String(s.sc.duty) : '',
            }))
            // NOTHING TO SAY UNTIL THERE IS ANOTHER BODY (the owner: *"there is no other yet"*).  "Which
            //  bodies stand where" is only news when MORE THAN ONE stands — a sibling tab, or a division
            //   (≥2 %Body rows).  A lone body says nothing even if it ran a cohort census, sits at a
            //    suffix, or holds the primary lock: those are its own private standup, not a multiplicity.
            const div = ((typeof H?.Swarm_body_roster === 'function' ? H.Swarm_body_roster(ident) : []) as any[]).length
            if (!sibs.length && div < 2) return null
            return {
                bare,
                addr,
                suffix,
                // PRIMACY IS THE SEAT, NOT THE LOCAL CENSUS (owner 2026-08-31: both tabs read
                //  "primary" — each machine's cohort census is alone in its own browser profile, so
                //   it can only ever crown itself).  The address IS the arbitrated truth: the relay
                //    granted exactly one body the bare name.  Bare seat → primary; a suffix → not.
                primary: addr === bare,
                lockless: !!coh?.lockless,
                vessel: coh?.vessel ? String(coh.vessel) : '',
                sibs,
            }
        } catch { return null }
    })
    // an address, shortened for a tag: bare reads as the prepub8, a suffixed body as …_N —
    //  the suffix is the news, the prepub is already on the title line.
    function short_addr(a: string, bare: string) {
        if (!a) return ''
        if (a === bare) return a.slice(0, 8)
        if (bare && a.startsWith(bare + '_')) return '…' + a.slice(bare.length)
        return a.slice(0, 8)
    }

    // ── THE %Invite ROWS (Portability_todo §7/§9) — a landed invite is a visible THING.  The
    //  vivified %Invite particles live on the station world (Swarm_invite_note homes them there:
    //   export-blind, Book-blind), sc {Invite:<serial>, prepub, to, n, state}, state walking
    //    arrived → redeeming → (sealed|refused land later).  Read with a PURE o()[0] walk, never
    //     `Swarm_station_world()` — that verb is an oai and a probe on a 1s tick must not MINT the
    //      world it is asking about (the Swarm_probe_station ruling: "a probe that collects").
    let invites = $derived.by(() => {
        void H?.version
        void tick
        try {
            const A = H?.top_House?.()?.o?.({ A: 'Clustation' })?.[0]
            const w = A?.o?.({ w: 'Swarm' })?.[0]
            return ((w?.o?.({ Invite: 1 }) ?? []) as any[]).map((inv: any) => ({
                serial: String(inv.sc?.Invite ?? ''),
                prepub: inv.sc?.prepub ? String(inv.sc.prepub).slice(0, 8) : '',
                to: inv.sc?.to ? String(inv.sc.to) : '',
                n: inv.sc?.n ? String(inv.sc.n) : '',
                state: String(inv.sc?.state ?? 'arrived'),
            // a MyCave invite IS the device-link ceremony — that lives whole in the Link cell now, so its
            //  worker row here is a fossil of the earlier course (owner 2026-08-30: "`✉ #65 MyCave …
            //   redeeming` — this line in Door should have been tidied away").  Friend invites still show.
            })).filter((inv: any) => inv.to !== 'MyCave')
        } catch { return [] }
    })

    // ── NAME YOURSELF — the first-time move: the chosen name (friendly) is what invites carry
    //  and what friends see; the auto-nick is only a stand-in.  Persists via Clustation_friendly.
    let naming = $state(false)
    let name_draft = $state('')
    let name_err = $state('')
    function name_open() {
        name_draft = face.named && face.name ? face.name : ''
        name_err = ''
        naming = true
    }
    async function name_save() {
        // the save can REFUSE (identity mid-standup) or THROW (persistence hiccup) — both must
        //  say so here, not strand an open box: the silent-reject was exactly the never-closing
        //   name box of 2026-07-19.
        name_err = ''
        try {
            const ok = await (H as any)?.Clustation_friendly?.(name_draft)
            if (ok) naming = false
            else name_err = 'not saved — try again in a moment'
        } catch (e) { name_err = 'not saved — ' + String(e).slice(0, 50) }
    }

    // ── SUGGEST — "you'd love this": send the PLAYING track to a friend, async to their being
    //  online (Swarm_suggest stashes + re-offers until their suggest_got).  ▶ on an arrived
    //   suggestion tunes the mirror record the share already carried over.
    function suggest(pub: string) {
        try {
            const w = (H as any)?.Swarm_station_world?.()
            const self = (H as any)?.Swarm_live_self?.()
            const rec = (H as any)?.c?.radio_w?.o?.({ Radio: 1 })?.[0]?.c?.rec
            if (w && self && rec) (H as any)?.Swarm_suggest?.(w, self, pub, rec, null)
        } catch {}
    }
    function tune_sug(rec: any) {
        try {
            const rw = (H as any)?.c?.radio_w
            const radio = rw?.o?.({ Radio: 1 })?.[0]
            if (radio && rec) (H as any)?.Radio_tune?.(radio, rec)
        } catch {}
    }

    // (The grantor adopt-confirm + its SAS used to live here — moved to the Link cell 2026-08-28, owner:
    //  "should be on its own in the Link cell. both should be. it's a huge deal copying your account".)

    // ── INVITE MANAGEMENT, IN THE GLASS (2026-08-09, the owner: fullscreen Vyto "with Invite
    //  management in there").  This cell was already WHO AM I and WHO'S WITH ME; the one missing
    //   verb was HOW ANYONE ELSE GETS HERE, and it was parked in a strip above the page — so the
    //    glass could never be the whole app.  InvitePanel comes in whole, in its `inglass` dress:
    //     one implementation, the one Book SwarmInvite proves, not a second copy of the arc.
    //  ALWAYS OPEN (2026-08-11 — this said "FOLDED BY DEFAULT", on the argument that cells are the
    //   scarce resource and the QR only matters in the minute you are inviting someone).  The
    //    scarcity is real and the conclusion was still wrong: the fold hid the cell's own reason for
    //     existing behind a control, and the room it saved was room this cell did not need saving.
    //      Drawing the panel grows the face, which grows the cell's measured need, and the sizing
    //       machinery gives it the space — which is the same mechanism the fold was leaning on,
    //        just without a click in front of it.
    // ── THE POSE (2026-08-10, the owner: *"there are cell positions|poses: Stretched (when Heist is
    //  forming), Big, Small.  Small has only name, maybe the door icon, that's nice"*).  The
    //   commissioner stamps `.c.pose` on the source particle — `big` for the belly, `small` for a
    //    bud — and the face decides how much of itself to draw.  Read live (H.version + the 1s tick
    //     already drive this component), defaulting to `big` so any glass that does not pose its
    //      cells gets exactly today's face.
    let pose = $derived.by(() => { void H?.version; void tick; return String(n?.c?.pose ?? 'big') })
    let small = $derived(pose === 'small')
    // THE INVITE PANEL'S OPEN STATE IS GONE (2026-08-11) — `c.inviting`, `invite_set()` and the
    //  auto-open latch all went with the fold.  Worth its headstone because the flag was carefully
    //   built: it lived on the PARTICLE rather than in component `$state` precisely so the model
    //    could put the panel away (`Sounditron.g`'s `onunmain`) when the Door stopped being the
    //     subject and came back as a bud with its QR still unfolded.  That problem is now solved one
    //      level up — a bud renders the `small` branch and never reaches the panel at all — so the
    //       mechanism has nothing left to protect.
    //  ⚠ `Sounditron.g:278` still deletes `s.c.inviting` in that `onunmain`; it is now a write to a
    //   key nobody reads. Harmless, but it should go on the next compile of that ghost.
    // the pier-list cap ("yay many") — five rows before the +N more toggle takes over.
    const PIERS_SHOWN = 5
    let piers_all = $state(false)
    // THE OUR-BOX SPLIT (owner 2026-08-30: "ourselves and all our Piers that are Linked in a box of
    //  their own … the box is a box").  A 🔗 cave pier is OUR OTHER DEVICE — it belongs beside the
    //   me-row and the Link Device door, not scattered among friends.  Both lists honour the
    //    optimistic-forget set; the cap applies to FRIENDS only (our own devices are few and always shown).
    let cave_piers   = $derived(((face?.friends ?? []) as any[]).filter((f: any) => f.cave && !forgotten.has(f.pub)))
    let friend_piers = $derived(((face?.friends ?? []) as any[]).filter((f: any) => !f.cave && !forgotten.has(f.pub)))
    // OPTIMISTIC FORGET (owner 2026-08-30: "a 'forget…' button lingers for quite a while when I click
    //  delete").  Swarm_pier_forget mints a signed %NotGrant + UnInvites; the retired-filter then drops
    //   the row — but that rides a commission, so the DeleteX sat in its 15s `fired` "forget…" state
    //    meanwhile.  Hide the row LOCALLY the instant it's confirmed so the button unmounts at once; the
    //     real forget proceeds underneath, and the retired filter keeps it gone on the next derive.
    let forgotten = $state(new Set<string>())
</script>

<!-- SMALL IS THE WHOLE FACE, not a folded version of it (*"Small has only name, maybe the door icon,
     that's nice"*).  One early return rather than `{#if !small}` sprinkled down the body: a bud must
     not merely LOOK quiet, it must not mount the friends walk, the QR panel or the 1s work at all —
     and a single branch is the only way to be sure of that by reading it. -->
{#if small}
    <div class="df df-small" title="the front door — press to open it">🚪</div>
{:else if face.prepub && !face.named}
    <!-- THE NAME-GATE (owner 2026-08-30: *"Door should insist you name yourself before partaking
         either end of any Grant-like thing"*).  Until this identity carries a `friendly`, the Door
         shows ONLY this prompt — no InvitePanel (mint / open share), no friends list, no Link Device,
         no suggest/forget.  Every Grant-like initiation, on BOTH ends (the person offering AND the
         person accepting), rides through one of those surfaces, and each is gated by requiring a
         name here first.  The name rides the QR and the seal, so a friend never meets an anon prepub.
         Guarded like the rest of the face: `face.prepub` proves the identity stood up, so this can
         never white-screen before Auto has minted a self (it falls through to the normal branch's
         `standing you up…`).  Once saved (Clustation_friendly bumps the identity), `face.named`
         flips and the ordinary Door returns on the next tick — never nagged again, because the name
         persists to disk under both the prepub and role homes. -->
    <div class="df df-gate">
        <div class="df-gate-title">🚪 welcome</div>
        <div class="df-gate-say">name yourself to begin — your name rides your invites, and it is what friends will see</div>
        <div class="df-naming">
            <input class="df-input" bind:value={name_draft} autocomplete="off" placeholder="what do friends call you?"
                onkeydown={(e) => { if (e.key === 'Enter') name_save() }} />
            <button class="df-edit" onclick={name_save} title="save your name and open the door">✓</button>
        </div>
        {#if name_err}<div class="df-note">⚠ {name_err}</div>{/if}
        {#if face.prepub}<span class="df-pub">{face.prepub}</span>{/if}
    </div>
{:else}
<div class="df">
    <div class="df-title">🚪 {face.name ?? 'standing you up…'}
        {#if face.instance}
            <!-- WHO THIS DEVICE IS (facet D): the soul name above is what FRIENDS see + what the ✎
                 edits; this badge is THIS body's own instance (role + its name-gate name), so a Cave
                 reads "Cave Guw" at the top even though its account is the soul Grav. -->
            <span class="df-instance"
                title={`this device is the ${face.instance.role}${face.instance.name ? ' “' + face.instance.name + '”' : ''} of ${face.name ?? 'this soul'} — one soul, this body's own name`}>
                · {face.instance.role}{#if face.instance.name} {face.instance.name}{/if}</span>
        {/if}
        {#if face.prepub && !naming}
            <button class="df-edit" onclick={name_open} title="name yourself — friends see this">✎</button>
        {/if}
        {#if face.prepub}<span class="df-pub">{face.prepub}</span>{/if}
        {#if face.newborn}<span class="df-born">✨ born today</span>{/if}
        {#if face.listen_only}<span class="df-listen"
            title="listening only — this browser can't open a music folder, so you're a radio terminal. Your identity lives only in this browser: clearing site data forgets you (linked devices will fix that).">🎧 listening only</span>{/if}
        {#if settle?.state === 'stolen'}<span class="df-settle stolen"
            title="another live body of your identity is on the wire — two writers means either can clobber the other's ledger. This body keeps writing; close the other one (or Steal Back to a new address here).">👥 two of you</span>
        {:else if settle?.state === 'settling'}<span class="df-settle busy"
            title={`writing your ledger to disk now${settle.why ? ` (${settle.why})` : ''}…`}>⛁ settling…</span>
        {:else if settle?.state === 'owed'}<span class="df-settle owed"
            title="your ledger changed but no share folder is open to write it to — it lives only in this tab until you open one.">⛁ write owed</span>{/if}
    </div>
    <!-- INVITE SITS ABOVE THE PIER LIST (the owner 2026-08-10) — it was at the bottom, under a list
         that grows, so the one verb a newcomer needs was the one thing that walked off the cell as
         friends arrived.
         NO FOLD AT ALL ANY MORE (the owner 2026-08-11: *"we don't need a `<details>` like situation
          anymore, just have the invite button and hole"*).  This went through the whole argument in
           one sitting and landed past it: first the shut state had no affordance, then a rotating ▸
            marker was the fix, then — correctly — the fold itself was the thing to delete.  The Door
             cell IS the invite door; there was never anything behind the disclosure except the reason
              the cell exists, so every version of the toggle was chrome guarding an empty secret.
         The panel's own two controls (`invite a friend`, and the paste field) are the buttons and the
          hole; nothing needs to be opened to reach them.  A bud is unaffected — the `small` branch
           above returns 🚪 and never reaches this. -->
    {#if face.prepub}
        <div class="df-panel"><InvitePanel {H} inglass /></div>
    {/if}
    {#if naming}
        <div class="df-naming">
            <input class="df-input" bind:value={name_draft} autocomplete="off" placeholder="what do friends call you?"
                onkeydown={(e) => { if (e.key === 'Enter') name_save(); if (e.key === 'Escape') naming = false }} />
            <button class="df-edit" onclick={name_save}>✓</button>
        </div>
        {#if name_err}<div class="df-note">⚠ {name_err}</div>{/if}
    {:else if face.prepub && !face.named}
        <div class="df-note">✎ name yourself — the name rides your invites</div>
    {/if}
    {#if face.door?.landed}
        <div class="df-invite">📨 invite from <b>{face.door.from}</b></div>
    {/if}
    {#if face.door?.note}
        <div class="df-note">{face.door.note}</div>
    {/if}
    <!-- the %Invite rows — each vivified invite is a thing with a lifecycle, shown as one small
         line: which offer (serial + what it grants), whose (prepub8), and where its state walk
         stands.  arrived|redeeming are the live states today; sealed|refused wear their colours
         for when the walk grows those legs. -->
    {#each invites as inv (inv.serial + inv.prepub)}
        <div class="df-invrow" class:sealed={inv.state === 'sealed'} class:refused={inv.state === 'refused'}
            title={`invite #${inv.serial} from ${inv.prepub}${inv.to ? ` — grants ${inv.to}` : ''}${inv.n ? ` (n ${inv.n})` : ''} — ${inv.state}`}>
            <span>✉ #{inv.serial}{inv.to ? ` ${inv.to}` : ''} from {inv.prepub}</span>
            <span class="df-invstate">{inv.state}</span>
        </div>
    {/each}
    <!-- THE OUR-BOX (owner 2026-08-30: "we should have ourselves and all our Piers that are Linked in
         a box of their own: OurPier, Link Device, LinkPier, they could be inliney… but the box is a
         box").  US, bounded: this body's me-row, every 🔗 linked-device pier, and the Link Device
         door — inline chips inside one bordered box.  Friends flow OUTSIDE it (inline too, unboxed):
         the border marks ownership, not rank.  The bodies line rides the box's full width — it is
         the same "where this soul stands" reading, one level deeper. -->
    {#if face.up || face.prepub || cave_piers.length || face.family.length}
        <div class="df-ourbox">
            <!-- ROW ONE, nowrap: me + uptime + the Link Device door.  THIS row sets the box's width
                 (owner: "that first row is the nowrap inline one, so it sets the width") — the caves
                 below wrap inside it rather than stretching the Door into tinytext. -->
            <div class="df-ourrow">
                <!-- ME — one liveness reading, styled DOWN from a friend row (this is context).
                     ALWAYS present: the uptime tag is a detail riding on this row, not its existence
                     condition (owner 2026-08-30: "why can't it see itself" — incognito has no %Uptime
                     row in its radio world, and the whole self-row used to vanish with it). -->
                <div class="df-me" class:fresh={!!face.up?.fresh}
                    title={face.up
                        ? `this tab has been up ${face.up.label} — resets on reload, so a near-zero reading means the reload landed`
                        : 'this tab — no uptime reading here (no %Uptime row in this world)'}>
                    <span class="df-dot here">●</span>
                    <span class="df-name">you</span>
                    {#if face.up}
                        <span class="df-tag dim">up {face.up.label}</span>
                        {#if face.up.fresh}<span class="df-tag">fresh reload</span>{/if}
                    {/if}
                </div>
                {#if face.prepub}
                    <!-- LINK A DEVICE — opens the Link ceremony as a BELLY CELL (owner 2026-08-29: "I want a
                         Cell").  Sounditron_link_open focuses %Link directly; you leave it by "no". -->
                    <button class="df-linkdev" onclick={() => H?.Sounditron_link_open?.()}
                        title="carry this account to another device — opens the Link Device cell, which you dismiss with “no”">
                        🔗 Link Device
                    </button>
                {/if}
            </div>
            {#if face.family.length}
                <!-- THE FAMILY — this soul's bodies by instance name (facet D: "Captain Grav and Cave
                     Guw").  One soul, many bodies; the NAME belongs to each instance (its own name-gate
                     name).  Friends see the one soul; this list is the family's own address book. -->
                <!-- rows are THE OTHERS only (the badge says who I am); the dot is their sibling
                     pulse landing here — the honest "we can see each other". -->
                <div class="df-family">
                    {#each face.family as b (b.pub8)}
                        <div class="df-friend df-body" class:fresh={!!b.fresh}
                            title={`${b.role}${b.name ? ' ' + b.name : ''} — ${b.role === 'Captain' ? 'the Captain of your crew' : 'a Cave in your crew'}${b.cert ? ' · holds the Captain\'s Grant:Crew' : ''}${b.addr ? ' · seat ' + b.addr.slice(0, 12) : ''}`
                                + (b.ago == null ? ' · not heard this session (closed or away)' : ` · heard ${b.ago}s ago`)}>
                            <span class="df-dot" class:here={b.rung === 'here'} class:fading={b.rung === 'fading'}>●</span>
                            <span class="df-name"><span class="df-role">{b.role}</span> {#if b.name}{b.name}{:else}<span class="df-fpub df-fpub-solo">{b.pub8}</span>{/if}</span>
                            {#if b.trove != null || b.pocket != null}
                                <!-- THE PLOT lane's organ (SoundPool §5.5): what this body holds -->
                                <span class="df-organ" title="what this body holds">{#if b.trove != null}{b.trove >= 1000 ? (b.trove / 1000).toFixed(0) + 'k' : b.trove} trove{/if}{#if b.pocket != null}{b.trove != null ? ' · ' : ''}{b.pocket} ready{/if}</span>
                            {/if}
                            {#if true}
                                <!-- EJECT A CREWMATE (owner 2026-09-03: "dropping Piers with the ✕ button as we
                                     do now should eject them from the Crew").  Swarm_pier_forget now runs
                                     Swarm_crew_eject first: a soul-signed NotGrant:Crew stands on the ledger,
                                     the mate's row + Key + cert go, and the ledger gossips — every other mate
                                     drops it, the ejected body leaves the crew, and friends of the soul shut
                                     their doors on it.  Offered for a LIVE mate too now (it is a deliberate,
                                     confirmed act), not only a dead one. -->
                                <DeleteX inline ondelete={() => {
                                    const kin_self = (H as any)?.Swarm_live_self?.()
                                    const kin_piers = ((H as any)?.Swarm_peering?.(kin_self)?.o({ Pier: 1 }) ?? []) as any[]
                                    const kp = kin_piers.find((p: any) => [String(p?.sc?.pub ?? ''), String(p?.o({ Peering: 1 })?.[0]?.sc?.pub ?? '')]
                                        .some(k => k && b.pub && (k.startsWith(b.pub) || b.pub.startsWith(k))))
                                    if (kp) (H as any)?.Swarm_pier_forget?.(null, String(kp.sc.pub))
                                }} confirm="forget?" glyph="✕"
                                    title="eject {b.role} {b.name || b.pub8} from your crew — a signed ejection travels to every crewmate and to friends of your soul; it keeps its own key and can be re-linked later" />
                            {/if}
                        </div>
                    {/each}
                </div>
            {/if}
            <!-- (a "Mag-flows" arrow list of standing %Reach rows lived here 2026-09-01→03 — removed on the
                 owner's call: "this div.df-flows is total hallucination".  The %Reach rows are real; the framing was not.) -->
            {#if cave_piers.length}
                <div class="df-caves">
                    {#each cave_piers as f (f.pub)}
                        <div class="df-friend df-cave">
                            <span class="df-dot" class:here={f.rung === 'here'} class:fading={f.rung === 'fading'} class:half={f.seal === 1 && f.rung !== 'away'}
                                title={(f.ago == null ? `${f.name} — not heard this session (their tab is closed or away)` : `${f.name} — heard ${f.ago}s ago`)
                                    + ' · 🔗 your Cave (a device of yours)'
                                    + (f.seal === 1 ? ` · ⚠ sealing 1 of 2 — ${f.seal_missing}; should heal itself, say so if it sits` : '')}>●</span>
                            <span class="df-name">🔗 {#if f.friendly}{f.friendly}<span class="df-fpub">{f.pub8}</span>{:else}<span class="df-fpub df-fpub-solo">{f.pub8}</span>{/if}</span>
                            {#if f.rung === 'away'}
                                <DeleteX inline ondelete={() => { forgotten.add(f.pub); forgotten = new Set(forgotten); (H as any)?.Swarm_pier_forget?.(null, f.pub) }}
                                    confirm="forget?" glyph="✕"
                                    title="forget {f.name} — retires this device link (it can be re-linked later)" />
                            {/if}
                        </div>
                    {/each}
                </div>
            {/if}
            <!-- the 🧬 this-body line is RETIRED (owner 2026-08-31: "I don't think we'll care in the
                 UI this body etc") — the instance badge (· CAPTAIN Grav / · CAVE Gabo) plus the
                 family rows carry everything it said, in family language instead of plumbing
                 language.  The `bodies` derivation stays for its title facts and diagnostics. -->
            {#if bodies && bodies.lockless}
                <div class="df-bodies">
                    <span class="df-tag dim" title="no Web Locks in this browser — primacy assumed, never arbitrated">🧬 lockless</span>
                </div>
            {/if}
        </div>
    {/if}
    <!-- A PIER ROW IS THE LIGHT AND THE NAME, in that order (the owner 2026-08-09: *"other Piers
         should just say their name and the online light, the online first"*).  Everything the row
         used to SAY — ♪ granted, N records, the half-seal warning — moves into the dot's title and
         colour: the facts stay reachable under the hood, they just stop being furniture.  A
         half-sealed pier wears the amber dot; hover says why.  The ♪→ suggest stays: it is a verb,
         not a saying.  And the list is CAPPED (*"the list shouldn't be more than yay many long"*) —
         five rows, then one dim toggle for the rest. -->
    <!-- friends — "a bit inliney too", but unboxed: wrapping chips (a suggestion row takes the full
         width below its chip).  The 🔗 caves are gone from here — they live in the our-box above. -->
    <div class="df-others">
    {#each (piers_all ? friend_piers : friend_piers.slice(0, PIERS_SHOWN)) as f (f.pub)}
        <div class="df-friend">
            <span class="df-dot" class:here={f.rung === 'here'} class:fading={f.rung === 'fading'} class:half={f.seal === 1 && f.rung !== 'away'}
                title={(f.ago == null ? `${f.name} — not heard this session (their tab is closed or away)` : `${f.name} — heard ${f.ago}s ago`)
                    + (f.cave ? ' · 🔗 your Cave (a device of yours)' : '') + (f.music ? ' · ♪ granted' : '') + (f.records != null ? ` · ${f.records} records` : '')
                    + (f.seal === 1 ? ` · ⚠ sealing 1 of 2 — ${f.seal_missing}; should heal itself, say so if it sits` : '')}>●</span>
            <!-- "Gwop eed831f1" — friendly prominent, prepub small (owner 2026-08-31: "both name and prepub …
                 make the [name] part bigger, the rest pretty small").  Unnamed pier → just the pub8, once. -->
            <span class="df-name">{f.cave ? '🔗 ' : ''}{#if f.friendly}{f.friendly}<span class="df-fpub">{f.pub8}</span>{:else}<span class="df-fpub df-fpub-solo">{f.pub8}</span>{/if}</span>
            {#if f.can_suggest}
                <button class="df-edit" onclick={() => suggest(f.pub)}
                    title="suggest the playing track to {f.name} — lands even if they're away">♪→</button>
            {/if}
            <!-- FORGET (away rows only): retire a pier that will never return — a dead Incognito tab, an
                 abandoned link test.  Swarm_pier_forget mints the standard signed %NotGrant per feature
                 (durable; the row stays in the ledger as history) + UnInvites the pub, and the retired
                 filter above drops it from this list.  Not offered while they're here/fading — forgetting
                 a live friend deserves more ceremony than a hover-✕. -->
            {#if f.rung === 'away'}
                <DeleteX inline ondelete={() => { forgotten.add(f.pub); forgotten = new Set(forgotten); (H as any)?.Swarm_pier_forget?.(null, f.pub) }}
                    confirm="forget?" glyph="✕"
                    title="forget {f.name} — retires this {f.cave ? 'device link' : 'friend'} (it can be re-invited later)" />
            {/if}
        </div>
        {#if f.sug}
            <div class="df-sug">
                {#if f.sug_rec}
                    <button class="df-edit" onclick={() => tune_sug(f.sug_rec)} title="play their suggestion">▶</button>
                {/if}
                <span class="df-tag">suggests: {f.sug.title}</span>
                {#if f.sug.note}<span class="df-tag dim">{f.sug.note}</span>{/if}
                {#if !f.sug_rec}<span class="df-tag dim">arriving with the share…</span>{/if}
            </div>
        {/if}
    {/each}
    {#if friend_piers.length > PIERS_SHOWN}
        <button class="df-more" onclick={() => piers_all = !piers_all}
            title={piers_all ? 'fold the list back to the first few' : 'show every pier'}>
            {piers_all ? '▾ fewer' : `+ ${friend_piers.length - PIERS_SHOWN} more`}
        </button>
    {/if}
    </div>
    {#if !face.friends.length && !face.door?.landed}
        <div class="df-note">{face.newborn ? 'you are new here — the invite is how a friend joins you' : 'no friends yet — the invite is how one arrives'}</div>
    {/if}

    <!-- (the Invite verb + panel moved ABOVE the pier list, 2026-08-10 — see the note up there.) -->
</div>
{/if}

<style>
    /* SMALL — THE ICON, AND LITERALLY NOTHING ELSE (the owner 2026-08-10: *"Door becomes only a Door
       icon"*).  The name came off with it: a bud is one glyph you recognise, and a nowrap line of text
       beside it is what made the box wide and flat rather than a thing.
       NO `height: 100%` HERE — that was a measurement feedback loop, and the owner watched it happen
       (*"the Door is tiny! its box is a good height but far too narrow"*).  The measure pass reads this
       element's offset box as the face's NATURAL size; height:100% makes that height THE MOLD'S OWN
       HEIGHT, so the cell was sized from itself on one axis and from the text on the other — an aspect
       that is not a fact about anything.  An intrinsic box is the only honest thing to hand a measurer:
       the glyph's own size, on both axes, which is square and reads as square. */
    .df.df-small { font-size: 30px; line-height: 1; padding: 2px; }
    /* THE NAME-GATE — the same warm register as the rest of the Door (breathing halo, the rounded
       plum face), but pared to one welcome + one input.  pointer-events go back to auto on the box
       itself here (not just descendants) so the whole small card is live while nothing else is drawn. */
    .df.df-gate { pointer-events: auto; }
    .df-gate-title { font-size: 13px; font-weight: 700; color: #d9a9ef; }
    .df-gate-say { font-size: 10px; color: #cbb8d8; margin: 4px 0; max-width: 220px; line-height: 1.35; }
    .df {
        pointer-events: none;
        width: max-content;
        /* max-width RAISED 300→500 (owner 2026-08-30: "the Door inlay is half the area it should be").
           This is the Door's NATURAL layout width; the cell's --fit trick then scales it to inscribe.
            At 300 the Door topped out near HALF a big cell's inscribed width (~585px), and because it is
             a max-content (non-stretched) face the fit takes min(width,height) — a height-bound Door kept
              that narrow 300px and rendered at ~half area.  500 lets it reach the width-bound regime and
               fill the inlay; the min() fit still inscribes it (never overflows the wall), and a small
                cell just scales the whole thing down as before, so nothing else regresses. */
        /* 20em cap (owner 2026-09-01): without it, a long Pier list grows the max-content Door too wide,
           and the cell's min() fit then renders the whole thing SMALL.  Capping forces the piers to a
            single column (df-others is column now) and lets the fit scale a narrow Door UP — readable. */
        max-width: 28em;
        padding: 8px 12px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #ead9ef;
        text-align: left;
        border-radius: 10px;
        /* the sparkle: a slow-breathing halo — this face is FOR THE USER'S EYES */
        animation: df-breathe 3.2s ease-in-out infinite;
    }
    @keyframes df-breathe {
        0%, 100% { filter: drop-shadow(0 0 3px rgba(196, 130, 224, 0.35)); }
        50%      { filter: drop-shadow(0 0 10px rgba(196, 130, 224, 0.75)); }
    }
    /* the top line — name, ✎, pub, born/listen/settle badges — reads as one centred caption
       (owner 2026-08-30: "center the other stuff on that line").  flex-wrap so a long name + badges
        fall to a second centred row rather than shove off the cell edge. */
    .df-title {
        font-size: 12px; font-weight: 700; color: #d9a9ef;
        display: flex; flex-wrap: wrap; align-items: center; justify-content: center;
        gap: 0.15rem 0.4rem;
    }
    /* the instance badge — "· CAVE Guw", THIS device's own name beside the soul name.  Quieter than
       the soul name (it's context, not the account), cursor:help for the one-soul-many-bodies whisper. */
    .df-instance {
        font-size: 10px; font-weight: 600; color: #b48fc9;
        cursor: help; pointer-events: auto; letter-spacing: 0.02em;
    }
    /* the invite door — a quiet disclosure at the foot of the friends list, not a call to action
       competing with them.  It only shouts (via InvitePanel's own `.ip-go`) once it is open and
        there is actually a stranger to greet. */
    /* (`.df-open` and `.df-tri` went with the fold, 2026-08-11 — the disclosure chip and its rotating
        ▸ existed for about twenty minutes between "you wouldn't know that did anything" and "we don't
         need a <details> like situation anymore". The panel is simply always here now.) */
    /* the panel takes pointer events back — `.df` is pointer-events:none so the cell beneath stays
       draggable/clickable, and every interactive descendant has to opt back in. */
    .df-panel { pointer-events: auto; margin-top: 4px; max-width: 260px; }
    /* the doorway to the Link Device cell — a quiet verb in the Door's register (like ✎ / +N more),
       not a loud call to action: the ceremony has its own cell now, this is just the way in. */
    .df-linkdev {
        pointer-events: auto; cursor: pointer; background: none; border: none;
        margin-top: 4px; padding: 0; text-align: left;
        font-size: 10px; color: #9a86b4;
    }
    .df-linkdev:hover { color: #d9a9ef; }
    .df-edit {
        pointer-events: auto;
        cursor: pointer;
        background: none;
        color: #b48fc9;
        border: none;
        font-size: 10px;
        padding: 0 3px;
    }
    .df-edit:hover { color: #fff; }
    /* forget ✕ — deliberately dim until hovered; red on hover says "this retires it" */
    .df-forget {
        pointer-events: auto;
        cursor: pointer;
        background: none;
        color: #6a5578;
        border: none;
        font-size: 10px;
        padding: 0 3px;
        opacity: .55;
    }
    .df-forget:hover { color: #e66; opacity: 1; }
    .df-naming { display: flex; gap: 3px; margin-top: 3px; }
    .df-input {
        pointer-events: auto;
        background: #241733;
        color: #ead9ef;
        border: 1px solid #8a6fae;
        border-radius: 6px;
        font-size: 10px;
        padding: 2px 6px;
        width: 170px;
    }
    .df-pub { font-size: 8px; opacity: 0.55; font-family: monospace; margin-left: 4px; }
    .df-born {
        font-size: 9px;
        color: #ffd869;
        margin-left: 5px;
        animation: df-twinkle 1.6s ease-in-out infinite;
    }
    @keyframes df-twinkle {
        0%, 100% { opacity: 1; }
        50%      { opacity: 0.45; }
    }
    /* 🎧 the listening-only badge — a quiet, honest tag on the self line, not an alarm: the mode
       works, it just can't hold a share, and hover carries the mortal-identity whisper. */
    .df-listen { font-size: 9px; color: #8fd0e8; margin-left: 5px; cursor: help; pointer-events: auto; }
    .df-settle { font-size: 9px; margin-left: 5px; cursor: help; pointer-events: auto; }
    .df-settle.ok { color: #7fc98a; }
    .df-settle.busy { color: #d8c56b; }
    .df-settle.owed { color: #e0965e; }
    .df-settle.stolen { color: #e06a6a; font-weight: 600; }
    .df-invite { font-size: 10px; margin-top: 3px; }
    .df-note { font-size: 9px; opacity: 0.7; font-style: italic; margin-top: 2px; }
    /* the friends ARE the app — they read at full size, not as a footnote ("friends list is
       tiny", the human 2026-07-19) */
    /* THE OUR-BOX — us, bounded.  Row one (me + Link Device) NEVER wraps and is what SETS the box's
       width (owner 2026-08-30: "that first row is the nowrap inline one, so it sets the width, and
       the other Piers stack up underneath in that width. it gets too wide otherwise") — so the box
       is width:fit-content off that row, and the caves/bodies rows use the width:0 + min-width:100%
       idiom to wrap INSIDE it without ever stretching it.  The border is the point ("the box is a
       box"). */
    .df-ourbox {
        width: fit-content; max-width: 100%;
        margin-top: 6px; padding: 4px 8px 5px;
        border: 1px solid rgba(170, 150, 220, 0.35); border-radius: 8px;
        background: rgba(140, 120, 200, 0.07);
    }
    .df-ourrow { display: flex; flex-wrap: nowrap; align-items: center; gap: 12px; white-space: nowrap; }
    /* width:min-content makes this row's contribution to the box's width the WIDEST SINGLE CHIP
       (chips are nowrap-atomic — never a break between 🔗 and the name), not the whole line of
       them; min-width:100% then hands it whatever width the box resolved (row one, or that widest
       chip when row one is narrower — incognito has no uptime row) and the chips wrap within it. */
    .df-caves {
        display: flex; flex-wrap: wrap; align-items: center; gap: 3px 12px;
        width: min-content; min-width: 100%; margin-top: 3px;
    }
    .df-caves .df-friend { white-space: nowrap; }
    /* THE FAMILY — the soul's bodies by instance name (facet D).  Same wrap idiom as the caves row,
       chips nowrap-atomic; the ROLE reads as a small badge, the name at full weight, self marked. */
    .df-family {
        display: flex; flex-wrap: wrap; align-items: center; gap: 3px 12px;
        width: min-content; min-width: 100%; margin-top: 3px;
    }
    .df-family .df-friend { white-space: nowrap; margin-top: 0; }
    /* THE PLOT — the family box's semantics filled in (owner 2026-09-01) */
    .df-organ {
        font-size: 9px; opacity: 0.65; font-family: monospace; margin-left: 6px;
        color: #9fc9b4; letter-spacing: 0;
    }
    .df-flow {
        display: flex; align-items: center; gap: 6px; font-size: 11px;
        opacity: 0.75; white-space: nowrap;
    }
    .df-flow-glyph { width: 12px; text-align: center; opacity: 0.8; }
    .df-flow.serving { opacity: 1; color: #cbb0e6; }
    .df-flow.serving .df-flow-glyph { color: #b48fc9; }
    .df-flow.arrived { color: #9fc9b4; }
    .df-flow.refused { color: #d69a9a; }
    .df-flow-ends { font-weight: 600; }
    .df-flow-arrow { opacity: 0.5; margin: 0 1px; }
    .df-flow-of { font-family: monospace; font-size: 9px; opacity: 0.55; }
    .df-role {
        font-size: 8px; text-transform: uppercase; letter-spacing: 0.06em;
        color: #b48fc9; background: rgba(170, 150, 220, 0.14);
        padding: 0 4px; border-radius: 3px; margin-right: 4px; font-weight: 600;
    }
    .df-body-mine .df-name { color: #d8c8f0; }
    .df-ourbox .df-me, .df-ourbox .df-friend { margin-top: 0; }
    .df-ourbox .df-linkdev { margin-top: 0; }
    .df-ourbox .df-bodies { width: 0; min-width: 100%; margin-top: 2px; }
    /* friends — inline wrapping chips, unboxed; a suggestion row takes the full width */
    /* SINGLE COLUMN (owner 2026-09-01: "at 20em there's two wobbly columns of them") — a capped-width
       Door wraps a flex list into an uneven grid; stack the piers in one clean column instead. */
    .df-others { display: flex; flex-direction: column; align-items: flex-start; gap: 2px; margin-top: 4px; }
    .df-others .df-friend { margin-top: 0; }
    .df-others .df-sug { flex-basis: 100%; }
    .df-friend { display: flex; align-items: center; gap: 6px; font-size: 13px; margin-top: 4px; }
    /* the prepub tag beside a friendly name — small, dim, monospace (matches .df-pub on the title line). */
    .df-fpub { font-size: 8px; opacity: 0.5; font-family: monospace; font-weight: 400; margin-left: 5px; letter-spacing: 0; }
    /* when the pier is UNNAMED the pub8 is all there is, so it carries the name's own weight (not shrunk). */
    .df-fpub-solo { font-size: 12px; opacity: 0.8; margin-left: 0; }
    /* the me-row: same list, quieter voice — the friends read at full size, this is the context they sit in */
    .df-me { display: flex; align-items: center; gap: 6px; font-size: 11px; margin-top: 4px; opacity: 0.75; }
    .df-me .df-name { font-weight: 600; }
    .df-me.fresh .df-dot { color: #f0c060; text-shadow: 0 0 5px rgba(240, 190, 110, 0.8); }
    /* a crew row sealed in the last few minutes GLOWS — the Door is where a finished link lands, and the new
       mate's row is the receipt (owner 2026-09-03: "dump us off in the Door, and have a glow behind the new Crew Pier") */
    .df-body.fresh { box-shadow: 0 0 14px 3px rgba(240, 190, 110, 0.45); border-radius: 0.6rem; background: rgba(240, 190, 110, 0.10); }
    .df-friend .df-name { font-weight: 600; }
    .df-sug { display: flex; align-items: center; gap: 4px; font-size: 10px; margin-left: 16px; }
    .df-dot { color: #5a4a5f; font-size: 10px; }
    .df-dot.here { color: #7fe8bf; text-shadow: 0 0 4px #7fe8bf; }
    .df-dot.fading { color: #d8b86a; }
    /* the half-seal state now lives ON the dot (the row says only light + name): amber and slightly
       alive, because a silently-half-working link is the one state that looks fine and isn't. */
    .df-dot.half { color: #f0c060; animation: df-halfpulse 2.4s ease-in-out infinite; }
    @keyframes df-halfpulse { 0%, 100% { opacity: 0.6 } 50% { opacity: 1 } }
    .df-tag { font-size: 8px; color: #b48fc9; }
    .df-tag.dim { opacity: 0.6; }
    /* the bodies line — the same voice as a .df-tag row: small, dim, informative.  cursor:help +
       pointer-events:auto so the hover long-form is reachable through the .df pointer shield. */
    .df-bodies {
        display: flex; flex-wrap: wrap; align-items: baseline; gap: 6px;
        margin-top: 3px; cursor: help; pointer-events: auto;
    }
    /* a %Invite row — an arrived offer as a visible thing; the state word carries the colour:
       amber while it is in flight (arrived|redeeming), green sealed, red refused. */
    .df-invrow { display: flex; align-items: center; gap: 6px; font-size: 10px; margin-top: 2px; cursor: help; pointer-events: auto; }
    .df-invstate { font-size: 8px; color: #d8c56b; }
    .df-invrow.sealed .df-invstate { color: #7fc98a; }
    .df-invrow.refused .df-invstate { color: #e06a6a; }
    /* the +N more toggle — the cap's release valve, styled to whisper */
    .df-more {
        pointer-events: auto; cursor: pointer; background: none; border: none;
        font-size: 8px; color: #8a7a94; text-align: left; padding: 0;
    }
    .df-more:hover { color: #cbb8d8; }
    /* CALM (calm.ts, owner 2026-09-03: the glowy effects lag a slow page) — when <html data-calm> is
       stamped, every animation and filter halo in this face stops; the layout is untouched. */
    :global(html[data-calm]) * { animation: none !important; filter: none !important; box-shadow: none !important; }
</style>
