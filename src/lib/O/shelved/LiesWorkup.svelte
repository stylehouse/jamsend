<script lang="ts">
// LiesWorkup.svelte — the retarget-transcendent pool, and the commit road out of it.
//
//   LiesEnd gives one Understanding at one target.  This file gives the
//   Understanding a memory of where it has been: %LE/%workup holds a
//   clearly-documented %Seemed per visited-and-modified %What — the parked
//   Seem:working clone tree, its encode receipt, its address in Waft** — so
//   touring the What** slope accumulates change instead of shedding it.
//
//   The road out:
//     park     — retargeting away from a changey target stashes it in %workup
//     resume   — re-arming at a parked address adopts the parked tree back
//     leg      — ascending above the floor of pooled change presents it all
//                as the batch that rides the NEXT move
//     commit   — that next move replaces-back every %Seemed and files a
//                %Waftlet receipt on w:Lies' req:git; the last two Waftlets
//                stay soft (revertable | mergeable); older ones harden into
//                the spool
//
//   The Waft address space underneath: Waft_dip (in LiesWaft now) runs a
//   Selection over the whole Waft** and stamps a session-stable c.Dip on
//   every particle — the
//   rename-proof identity %Seemed keys on, clones carry, and svelte #each
//   blocks key by.  Same Dip protocol as Cyto's scanid|cytoid, persisted in
//   the D sphere via resume_X.
//
//   Mounting: like LiesEnd — mounted by BOTH Lies.svelte and Lang.svelte;
//   eatfunc mixes everything into the one H.* table.  The w:Lang-side
//   handlers (e_workup) and the w:Lies-side handlers (e_workup_filed,
//   e_waftlet) live together here because they are two ends of one protocol.

import { _C, type TheC } from "$lib/data/Stuff.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { onMount } from "svelte"

// One level above the shallowest pooled change presents the leg.
//   depth(destination) <= floor - LEG_ASCENT  →  present
// A constant, not a setting — the African-village clearing is always
// one terrace up from the deepest field you worked.
const LEG_ASCENT = 1

let { M } = $props()

onMount(async () => {
await M.eatfunc({

//#region addressing — c.Dip → Workup_at
//
//   Waft** is an address space: every What|Doc|Point carries a session-stable
//   c.Dip, the rename-proof identity %Seemed keys on and clones carry.  The
//   dip pass that mints and stamps it (Waft_dip) lives in LiesWaft; this file
//   only reads the stamped value through Workup_at.

    // address of a particle in the space; the spec-string fallback covers a
    // particle the dip pass hasn't seen yet (a just-added clone, a Waft from
    // a snap that predates linking).
    Workup_at(C: TheC): string {
        const sc = C.sc as any
        return (C.c.Dip as string)
            ?? `${sc.Waft ?? sc.What ?? sc.path ?? sc.method ?? sc.label ?? '?'}`
    },

//#endregion
//#region park | resume — %workup/%Seemed
//
//   %LE/%workup — retarget-transcendent, session-lived.  %LE is stable and
//   LE_arm only drops %Seem children, so the workup rides through every
//   re-aim untouched.
//
//   /%workup
//     /%leg                       — present only while a gathered batch is
//                                   riding the next move; sc.t, sc.n
//     /%Seemed,$at                — at = target's c.Dip
//       sc.at | what | waft | depth | t
//       sc.live                   — this address is the armed target right now
//       c.target → OC %What       — live ref for the eventual replace-back
//       c.C      → parked working clone root (U meanings ride each clone.c.U)
//       /%encode  snap_origin | snap_working | dirty   — the receipt at park
//
//   Meanings survive parking because they ride clone.c.U object refs; the
//   D|U sphere particles are dropped with the Seems but the U objects live
//   on, and _Seem_CDUsive carries their sc forward into the fresh sphere on
//   the resume walk (the meaning-carry patch in the spec).

    Workup_of(LE: TheC): TheC {
        return LE.oai({ workup: 1 })
    },

    // shallowest depth among pooled change; Infinity when nothing is pooled.
    Workup_floor(workup: TheC): number {
        let floor = Infinity
        for (const s of workup.o({ Seemed: 1 }) as TheC[]) {
            const d = s.sc.depth as number | undefined
            if (d != null && d < floor) floor = d
        }
        return floor
    },

    // ── LE_park ─────────────────────────────────────────────────────────────
    // Stash the current Understanding's working state at its address.
    //   changey → write|refresh %Seemed,$at (the whole clone tree by ref —
    //             while still armed here it IS the live working tree)
    //   clean   → drop any %Seemed,$at (a resumed change the user reset to
    //             clean leaves nothing behind)
    //
    // Runs its own encode-compare first: the driver encodes after edits, but
    // an edit and a cursor move can land between thinks, and req_understanding
    // does checkout before encode — so the parked receipt must not trust the
    // last %State.
    async LE_park(LE: TheC) {
        const H       = this as House
        const target  = LE.sc.target as TheC | undefined
        const working = LE.o({ Seem: 'working' })[0] as TheC | undefined
        if (!target || !working?.sc.C) return   // armed-never-pulled, or unarmed

        const { dirty } = await H.LE_encode_compare(LE)
        const at     = H.Workup_at(target)
        const workup = H.Workup_of(LE)
        const prior  = workup.o({ Seemed: at })[0] as TheC | undefined

        if (!dirty) {
            if (prior) workup.drop(prior)
            return
        }

        const seemed = workup.oai({ Seemed: at })
        const sc = target.sc as any
        seemed.sc.at    = at
        seemed.sc.what  = (typeof sc.What === 'string' ? sc.What : undefined)
            ?? sc.label ?? sc.Waft ?? sc.path ?? '?'
        seemed.sc.waft  = H.waft_key_of(target)
        seemed.sc.depth = sc.Waft !== undefined ? -1 : H.LE_what_depth(target)
        seemed.sc.t     = Date.now() / 1000
        delete seemed.sc.live
        seemed.c.target = target
        seemed.c.C      = working.sc.C

        // copy the encode receipt — %LE/%encode belongs to whichever target
        // is armed and is about to be overwritten by the next one.
        const enc = LE.o({ encode: 1 })[0] as TheC | undefined
        await seemed.r({ encode: 1 }, {
            snap_origin:  (enc?.sc.snap_origin  as string) ?? '',
            snap_working: (enc?.sc.snap_working as string) ?? '',
            dirty:        '1',
        })
        LE.bump_version()
    },

    // ── LE_retarget ─────────────────────────────────────────────────────────
    // The full move: park the outgoing, commit a presented leg | maybe present
    // one, arm at the destination, resume a parked tree if one waits there.
    //
    //   This replaces the bare LE_arm + LE_pull pair at both req_understanding
    //   call sites — the src-change checkout AND the origin-dirty re-baseline.
    //   On the re-baseline (want === armed target) park-then-resume means
    //   working edits survive the re-arm: resume wins over the moved origin,
    //   %State carries stale ∧ changey, and the encode shows what a push
    //   would clobber.
    //   < merge of resumed edits against a moved origin — resume-wins for now.
    async LE_retarget(LE: TheC, want: TheC) {
        const H      = this as House
        const workup = H.Workup_of(LE)

        // the address space first — park keys on the OLD target's Dip (minted
        // when we armed there); the destination needs its Dip before resume.
        const waft = (want.sc as any).Waft !== undefined ? want : H.LE_what_waft(want)
        await H.Waft_dip(waft)

        await H.LE_park(LE)

        // a presented leg + a move = the push moment
        const leg = workup.o({ leg: 1 })[0] as TheC | undefined
        if (leg) {
            await H.Workup_commit(LE, { rebaseline: false })
        }
        else {
            // ascent past the floor presents the pooled change as next-move cargo
            const seemeds = workup.o({ Seemed: 1 }) as TheC[]
            if (seemeds.length) {
                const depth = (want.sc as any).Waft !== undefined ? -1 : H.LE_what_depth(want)
                if (depth <= H.Workup_floor(workup) - LEG_ASCENT) {
                    const fresh = workup.oai({ leg: 1 })
                    fresh.sc.t = Date.now() / 1000
                    fresh.sc.n = seemeds.length
                }
                // < time-trigger: a quiet-minutes ttlilt that presents the leg
                //   without an ascent — "as time|landscape goes by"; landscape
                //   is built, time is not.
            }
        }

        H.LE_arm(LE, want)

        // resume — adopt the parked tree as Seem:working%C before the pull so
        // was_fresh stays false and the walk wires D|U onto OUR clones.
        const at     = H.Workup_at(want)
        const seemed = workup.o({ Seemed: at })[0] as TheC | undefined
        if (seemed?.c.C) {
            const working = LE.oai({ Seem: 'working' })
            working.sc.C = seemed.c.C
            seemed.sc.live = 1
        }

        await H.LE_pull(LE)
        if (seemed) await H.LE_encode_compare(LE)   // resurface changey immediately
        LE.bump_version()
    },

//#endregion
//#region leg → commit — %Waftlet
//
//   The commit replaces-back every pooled %Seemed into its OC target.  The
//   Waft watcher (watch_c in Lies) sees each mutation and does the saving and
//   the e:Lies_waft_mutated notify itself — commit owes no IO.
//
//   The receipt then crosses to w:Lies as plain rows (no live req reach —
//   this is the Lies|Lang bridge the spec wanted for req:git): each row is
//   { at, what, waft, depth, snap_origin, snap_working, target, C, origin_C }
//   and e_workup_filed hangs them as a %Waftlet under req:git.

    // replace-back for any (target, clone root) pair — LE_replace_back
    //   generalised off %LE so parked trees can land without re-arming.
    //   U%unaccepted clones are omitted (virtual deletions); c.Dip carries
    //   onto pushed particles so the address survives the replace.
    async Workup_replace_back(target: TheC, C: TheC) {
        await target.replace({}, async () => {
            for (const k of C.o({}) as TheC[]) {
                if (k.c.U?.sc.unaccepted) continue
                const fresh = target.i({ ...k.sc })
                fresh.c.Dip = k.c.Dip
            }
        })
    },

    // sc-deep-enough copy of an OC's children — the revert base a soft
    //   %Waftlet holds.  Shallow like the clone protocol: a nested %What
    //   keeps its line; its deep Points resume on the eventual revert replace.
    Workup_keep_origin(target: TheC): TheC {
        const keep = _C({ ...target.sc })
        for (const k of target.o({}) as TheC[]) {
            const kk = keep.i({ ...k.sc })
            kk.c.Dip = k.c.Dip
        }
        return keep
    },

    // ── Workup_commit ───────────────────────────────────────────────────────
    // Land every pooled %Seemed, file the %Waftlet, empty the workup.
    //   rebaseline re-arms the live target on the just-pushed origin so its
    //   Understanding reads clean; LE_retarget passes false because it is
    //   about to arm at the destination anyway.
    async Workup_commit(LE: TheC, opt: { rebaseline?: boolean } = {}) {
        const H       = this as House
        const workup  = H.Workup_of(LE)
        const seemeds = workup.o({ Seemed: 1 }) as TheC[]
        const leg     = workup.o({ leg: 1 })[0] as TheC | undefined
        if (!seemeds.length) {
            if (leg) workup.drop(leg)
            return
        }

        const rows: any[] = []
        for (const s of seemeds) {
            const target = s.c.target as TheC | undefined
            const C      = s.c.C as TheC | undefined
            if (!target || !C) continue
            const origin_C = H.Workup_keep_origin(target)
            await H.Workup_replace_back(target, C)
            const enc = s.o({ encode: 1 })[0] as TheC | undefined
            rows.push({
                at:           s.sc.at,
                what:         s.sc.what,
                waft:         s.sc.waft,
                depth:        s.sc.depth,
                snap_origin:  (enc?.sc.snap_origin  as string) ?? '',
                snap_working: (enc?.sc.snap_working as string) ?? '',
                target, C, origin_C,
            })
        }

        // the workup empties — the change lives in the Waft and the Waftlet now
        if (leg) workup.drop(leg)
        for (const s of seemeds) workup.drop(s)

        H.i_elvisto('Lies/Lies', 'workup_filed', { rows })

        if (opt.rebaseline !== false && LE.sc.target) {
            H.LE_arm(LE, LE.sc.target as TheC)
            await H.LE_pull(LE)
        }
        LE.bump_version()
    },

    // ── e:workup ────────────────────────────────────────────────────────────
    //   The strip's ops on the pool, on w:Lang where %LE lives.
    //   e.sc: { LE: TheC, op: string, at? }
    //     discard_seemed — drop one %Seemed; a live one also re-arms fresh so
    //                      the discarded edits leave the working tree too
    //     discard_leg    — drop every %Seemed and the %leg; full reset of the pool
    //     dismiss_leg    — drop the %leg only; pooling continues, the next
    //                      ascent re-presents
    //     commit         — park the live target and land everything now
    async e_workup(A: TheC, w: TheC, e: TheC) {
        const H  = this as House
        const LE = (e.sc.LE as TheC | undefined)
            ?? (H.ave as TheC).o({ Languinio: 1 })[0]?.o({ LE: 1 })[0] as TheC | undefined
        if (!LE) return
        const workup = H.Workup_of(LE)
        const op     = e.sc.op as string | undefined

        const rearm_fresh = async () => {
            const target = LE.sc.target as TheC | undefined
            if (!target) return
            H.LE_arm(LE, target)
            await H.LE_pull(LE)
        }
        const drop_leg_if_empty = () => {
            if (!workup.o({ Seemed: 1 }).length)
                for (const l of workup.o({ leg: 1 }) as TheC[]) workup.drop(l)
        }

        switch (op) {
            case 'discard_seemed': {
                const s = workup.o({ Seemed: e.sc.at })[0] as TheC | undefined
                if (!s) break
                if (s.sc.live) await rearm_fresh()
                workup.drop(s)
                drop_leg_if_empty()
                break
            }
            case 'discard_leg': {
                let had_live = false
                for (const s of workup.o({ Seemed: 1 }) as TheC[]) {
                    if (s.sc.live) had_live = true
                    workup.drop(s)
                }
                if (had_live) await rearm_fresh()
                for (const l of workup.o({ leg: 1 }) as TheC[]) workup.drop(l)
                break
            }
            case 'dismiss_leg': {
                for (const l of workup.o({ leg: 1 }) as TheC[]) workup.drop(l)
                break
            }
            case 'commit': {
                await H.LE_park(LE)
                await H.Workup_commit(LE)
                break
            }
            default:
                throw `e_workup: unknown op '${op}'`
        }
        LE.bump_version()
        H.feebly_ponder()
    },

//#endregion
//#region the spool — w:Lies/req:git/%Waftlet
//
//   The git spool is conceptually another Waft** imaged off the top of this
//   one — deeper cuts, revisions, floating fabrics.  Its representation here
//   stays deliberately mute: enough that someone realises they are changing
//   the real memory and can intervene, no more.
//     /req:git
//       /%Waftlet,$id            — id = commit ts (seconds)
//         sc.t | n | label | waft
//         sc.soft                — the last two: revertable | mergeable
//         sc.reverted            — spent by an intervene
//         /%Seemed,$at           — the mute receipt per landed address
//           sc.at | what | waft | depth
//           c.target | c.C | c.origin_C   — soft only; hardened away
//           /%encode  snap_origin | snap_working
//   < enWaft of req:git/* into wormhole/$path/spool.snap — the imaging that
//     makes the spool a real Waft, with the lazy-loaded log riding it.
//   < a visual language for the grapple this makes on the real memory, hung
//     on the starting intention.

    // reqs hang directly on the host now (the reqy() stack is gone), so the
    // %req:git container is a child of w, or of w's req:desire.
    Workup_git_of(w: TheC): TheC | undefined {
        const at_w = w.o({ req: 'git' })[0] as TheC | undefined
        if (at_w) return at_w
        const desire = w.o({ req: 'desire' })[0] as TheC | undefined
        return desire ? desire.o({ req: 'git' })[0] as TheC | undefined : undefined
    },

    // drop the heavy live refs; the receipt (sc + %encode snaps) stays as the
    // raw material of the lazy log.
    Waftlet_harden(W: TheC) {
        delete W.sc.soft
        for (const s of W.o({ Seemed: 1 }) as TheC[]) {
            delete s.c.target
            delete s.c.C
            delete s.c.origin_C
        }
    },

    // ── e:workup_filed ──────────────────────────────────────────────────────
    //   w:Lies receives the commit rows and files the %Waftlet.  Persistence
    //   already happened — the replace-backs tripped watch_c(waft) which saved
    //   and notified.  Soft cap: the newest two stay soft; older harden.
    //   The req:git particle goes into an ave hold so the strip can read the
    //   spool without a w:Lies reach.
    //   e.sc: { rows: [...] }
    async e_workup_filed(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const rows = e.sc.rows as any[] | undefined
        if (!rows?.length) return
        const git = H.Workup_git_of(w)
        if (!git) { console.warn('e_workup_filed: no req:git — Waftlet unfiled'); return }

        const id = Date.now() / 1000
        const W  = git.i({
            Waftlet: id,
            t:       id,
            soft:    1,
            n:       rows.length,
            label:   rows.map(r => r.what).join(' · '),
            waft:    rows[0].waft,
        })
        for (const r of rows) {
            const s = W.i({ Seemed: r.at, at: r.at, what: r.what, waft: r.waft, depth: r.depth })
            s.c.target   = r.target
            s.c.C        = r.C
            s.c.origin_C = r.origin_C
            s.i({ encode: 1, snap_origin: r.snap_origin, snap_working: r.snap_working })
        }

        // the last two soft commits linger; the rest stack beneath
        const softs = (git.o({ Waftlet: 1 }) as TheC[])
            .filter(x => x.sc.soft)
            .sort((a, b) => (b.sc.t as number) - (a.sc.t as number))
        for (const old of softs.slice(2)) H.Waftlet_harden(old)

        const hold = (H.ave as TheC).oai({ git_hold: 1 })
        hold.c.git = git
        git.bump_version()
    },

    // ── e:waftlet ───────────────────────────────────────────────────────────
    //   Intervening on a soft commit, on w:Lies where the spool lives.
    //   e.sc: { op: 'revert' | 'merge', id? }
    //     revert — put each %Seemed's origin_C back as its target's children.
    //              The watcher saves and notifies; an LE armed inside the
    //              reverted extent re-pulls via origin_dirty.  Spent → hardened.
    //     merge  — the newer soft absorbs the older: shared addresses keep the
    //              newer working state over the OLDER revert base, so one
    //              revert undoes both.  Topics keep flowing into one commit.
    async e_waftlet(A: TheC, w: TheC, e: TheC) {
        const H   = this as House
        const git = H.Workup_git_of(w)
        if (!git) return
        const op = e.sc.op as string | undefined

        switch (op) {
            case 'revert': {
                const W = git.o({ Waftlet: e.sc.id })[0] as TheC | undefined
                if (!W || !W.sc.soft || W.sc.reverted) break
                for (const s of W.o({ Seemed: 1 }) as TheC[]) {
                    const target = s.c.target as TheC | undefined
                    const base   = s.c.origin_C as TheC | undefined
                    if (target && base) await H.Workup_replace_back(target, base)
                }
                W.sc.reverted = 1
                H.Waftlet_harden(W)
                break
            }
            case 'merge': {
                const softs = (git.o({ Waftlet: 1 }) as TheC[])
                    .filter(x => x.sc.soft && !x.sc.reverted)
                    .sort((a, b) => (b.sc.t as number) - (a.sc.t as number))
                if (softs.length < 2) break
                const [newer, older] = softs
                for (const so of older.o({ Seemed: 1 }) as TheC[]) {
                    const twin = newer.o({ Seemed: so.sc.Seemed })[0] as TheC | undefined
                    if (twin) {
                        // same address landed twice — the older base is the
                        // deeper revert root; the newer working state stands.
                        if (so.c.origin_C) twin.c.origin_C = so.c.origin_C
                        const te = twin.o({ encode: 1 })[0] as TheC | undefined
                        const oe = so.o({ encode: 1 })[0] as TheC | undefined
                        if (te && oe) te.sc.snap_origin = oe.sc.snap_origin
                    }
                    else {
                        const moved = newer.i({ ...so.sc })
                        moved.c.target   = so.c.target
                        moved.c.C        = so.c.C
                        moved.c.origin_C = so.c.origin_C
                        const oe = so.o({ encode: 1 })[0] as TheC | undefined
                        if (oe) moved.i({ ...oe.sc })
                    }
                }
                newer.sc.label = `${older.sc.label} ⋈ ${newer.sc.label}`
                newer.sc.n     = (newer.o({ Seemed: 1 }) as TheC[]).length
                newer.sc.t_from = older.sc.t   // the merged span begins where the older leg did
                git.drop(older)
                break
            }
            default:
                throw `e_waftlet: unknown op '${op}'`
        }
        git.bump_version()
        H.feebly_ponder()
    },

//#endregion
//#region presentation raw material

    // the raw form of "what this would|did change" — set-difference of snap
    // lines, ± prefixed.  No ordering smarts, no folding.
    // < the coherently folded patch renderer replaces this: search hits and
    //   encode diffs flonking in from 50k-line codebases want region-squished
    //   hunks, and this is the slot they render into.
    Workup_rawdiff(snap_origin: string, snap_working: string): string {
        const O = snap_origin.split('\n').filter(Boolean)
        const W = snap_working.split('\n').filter(Boolean)
        const So = new Set(O), Sw = new Set(W)
        return [
            ...W.filter(l => !So.has(l)).map(l => `+ ${l}`),
            ...O.filter(l => !Sw.has(l)).map(l => `- ${l}`),
        ].join('\n')
    },

    // the capsule's framed body — what the strip shows per clone beyond its
    // name.  kind:'name' is today's whole story; a clone arriving from a text
    // search | encode diff carries c.body = { kind, raw } and springs up here.
    LE_capsule_body(clone: TheC): { spec: string, kind: string, raw: string } {
        const sc   = clone.sc as any
        const raw  = sc.method ?? sc.label ?? sc.Point
        const spec = raw == null || raw === 1 || raw === true ? '?' : String(raw)
        if (clone.c.body) return { spec, ...(clone.c.body as { kind: string, raw: string }) }
        return { spec, kind: 'name', raw: spec }
    },

    // the default LE target for a Waft with nothing in it yet: the %Waft
    // itself.  An armed-at-Waft LE works the same — clones are the Waft's
    // direct children, replace-back lands there, depth reads -1.
    // PeelItem's first add then just throws in a %Point and lets them change it.
    // < that bends the grammar (Waft → (What | Doc)*); promote the bare Point
    //   into a %What once it has company or a name.
    Workup_default_target(waft: TheC): TheC {
        return (waft.o({ What: 1 })[0] as TheC | undefined) ?? waft
    },

//#endregion

})
})
</script>
