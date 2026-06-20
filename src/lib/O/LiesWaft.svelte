<script lang="ts">
// LiesWaft.svelte — the dynamic web on Waft**.
//
//   A Waft is the editable web; the live, interactive stuff that rides ON it —
//   the Funkcions (monitor cells and action drum-pads), the Waft address space
//   they key against, and the editor↔runner verdict wire a Funkcion cell fires
//   and reads — all gathers here, gathered out of the Lies* modules that used to
//   each own a slice (LiesStore, LiesEnd, LiesCurse, LiesLies).  The Funk kinds
//   themselves live under O/Funk/ (kinds.ts + one module per kind); this is the
//   HOST runtime that instantiates, pumps, and strikes them, plus the Waft-shaped
//   plumbing underneath.
//
//   Like its siblings this is a House mixin: no JS classes, methods on `this`,
//   mixed into the one H.* table by M.eatfunc.  Mounted by Lies.svelte alongside
//   LiesStore/LiesEnd/LiesCurse/LiesLies — file placement is purely organisational.
//
//   The four regions:
//     Waft_dip            — the Waft address space (c.Dip), what funk_id keys on
//     Funkcions           — instantiate / register / central per-tick pump
//     Ballistics          — the action Funkcions: strike-on-demand + self-arm
//     editor↔runner       — run intent (Esc / Book cell) + the verdict wire back
//                            (may grow into Cred*_result|verdict|instruct, §Editron)

import { _C, type TheC } from "$lib/data/Stuff.svelte"
import { Selection, Travel } from "$lib/mostly/Selection.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { FUNK_KINDS } from "$lib/O/Funk/kinds"
import { onMount } from "svelte"

let { M } = $props()

// HAVOC_LIMBS — the havoc drum-machine's reusable behaviours, keyed by %havoc kind.
//  Each limb pops a different part of the Lies/Store plumbing.  A %havoc:<kind>
//  particle authored in a Waft is the per-test config; this is the shared behaviour
//  the strike runs.  Add a limb by adding an entry — the inline pad (Waft.svelte) and
//  e_Lies_strike both dispatch by kind, so nothing else needs touching.
const HAVOC_LIMBS: Record<string, { run: (H: House, w: TheC, c?: TheC) => Promise<void> }> = {
    // 💥 fabricate a surprise_read (disk diverged under the open edit) on the active
    //  doc.  Active-doc truth is w:Lang.c.active_dock_path (set by Lang_set_active_dock).
    surprise_read: {
        run: async (H, w) => {
            let path: string | undefined
            try { path = H.Awo('Lang').c.active_dock_path as string | undefined } catch { /* no w:Lang yet */ }
            if (!path) { console.warn('🥁 surprise_read: no active doc open'); return }
            if (await H.Lies_fabricate_surprise_on(w, path))
                console.warn(`🥁 surprise_read on ${path}`)
        },
    },
}

// Run one havoc limb by kind against w:Lies, optionally carrying the authored
//  %havoc particle c (its params).  Shared by the manual strike (e_Lies_strike)
//  and the self-arming scan (Lies_arm_engaged).  Returns whether a limb ran.
async function run_limb(H: House, w: TheC, kind: string, c?: TheC): Promise<boolean> {
    const limb = HAVOC_LIMBS[kind]
    if (!limb) { console.warn(`🥁 no havoc limb '${kind}'`); return false }
    await limb.run(H, w, c)
    return true
}

onMount(async () => {
await M.eatfunc({

//#region Waft_dip — the Waft address space (c.Dip)

    async Waft_dip(waft: TheC | undefined) {
        const H = this as House
        if (!waft) return
        const Se: Selection = waft.c.dip_Se ??= new Selection()
        Se.sc.topD ??= (() => {
            const topD = _C({ Dipping: waft.sc.Waft })
            // Dip must begin on the topD — children claim slots from the
            // nearest ancestor Dip, and without this seed every depth-1 child
            // would mint the same first slot.
            topD.i({ Dip: 'waftid', value: 'w', i: 0 })
            return topD
        })()
        // fresh Travel each pass; D|** (the %Dip particles) resume via resume_X
        Se.sc.topD.c.T = undefined

        await Se.process({
            n:          waft,
            process_D:  Se.sc.topD,
            match_sc:   {},
            loop_but_no_further: 1,
            trace_sc:   { dipping: 1 },
            // Doc-association — stamp each particle's governing %Doc onto C.c.Doc
            //   as we walk, so anyone (LangGraft, Waft_src_doc) reads "which Doc
            //   serves this" as a direct ref instead of re-deriving it.
            //   The context is per-parent: each Travel carries sc.cur_Doc, seeded
            //   from its parent's slot, and a %Doc child updates its parent's slot
            //   for the siblings after it.  That gives both grammar cases at once:
            //     Doc → What → Point   inherits the enclosing ancestor Doc, and
            //     What:[Doc:X, Point]  the Point takes the preceding sibling Doc
            //   (snap-line order — Doc written before the Points it serves, which
            //   enWaft always honours), while a Doc inside one What never leaks to
            //   that What's siblings.  A particle with no context in scope gets
            //   c.Doc:undefined — a title page.
            //   each_fn runs pre-order, parent before child, which is what makes
            //   the slot seeding correct.
            each_fn:    async (_D: TheC, C: TheC, T: any) => {
                const uT = T.sc.up
                const sc = C.sc as any
                if (sc.Doc !== undefined) {
                    C.c.Doc      = C
                    T.sc.cur_Doc = C
                    if (uT) uT.sc.cur_Doc = C   // serves the siblings after us
                } else {
                    const ctx    = uT?.sc.cur_Doc as TheC | undefined
                    T.sc.cur_Doc = ctx
                    C.c.Doc      = ctx
                }
            },
            trace_fn:   async (uD: TheC, C: TheC) => uD.i({ dipping: 1, ...C.sc }),
            traced_fn:  async (D: TheC, _bD: TheC, C: TheC) => {
                C.c.Dip = H.Dip_assign('waftid', D)
            },
        })
    },

//#endregion
//#region Funkcions — instantiate / register / central per-tick pump

    // ── Funkcions — Lies-side, no LE ──────────────────────────────────────────
    //   A Funkcion is behaviour on funk.c.run riding a Waft directly
    //   (Waft/Funkcion:$name — no Seem, no req inside the Waft).  Its hosting req
    //   lives centrally in Lies/Funkcions as req:Funkcion (one per Funkcion); the
    //   Funkcion spawns|knows its own req via Lies_register_funkcion.  Lies_pump_-
    //   funkcions runs them all once per tick (funks.do()).  A Funkcion isn't really
    //   req-like — it's behaviour hung on a req host — so the per-tick driver is wired
    //   as an explicit do_fn (doai), NOT the req_$name convention: it runs funk.c.run
    //   and sets sc.ok, re-running every tick but staying inspectable.  run is
    //   (host, funk, ...args) — host is the Waft, args carry through (e.g. the w a
    //   walker lists against), all read off req.c so a re-register refreshes them.
    async Lies_register_funkcion(w: TheC, host: TheC, funk: TheC, ...args: any[]): Promise<TheC> {
        const funks = w.oai({ Funkcions: 1 })
        // funks is a plain container, so the A/w-spine c.up wiring never reaches it;
        //  point it at w so funks.do()'s _req_do_one can climb to the House to reach
        //  do_fn_for, which returns the req's wired do_fn (funks → w → A → House).
        funks.c.up = w
        // funk_id keys the req — a plain scalar, NOT the Waft|Funkcion mainkeys (those
        //  are type-tags a tree-walk reads to detect wafts|funkcions; using them as req
        //  sc keys makes the walk misread this req).  The waft|funk are .c refs.
        //  Identity is the funk's structural **Dip** (`c.Dip`, the waftid slot Waft_dip
        //   stamps on every Waft** particle) — reliably present, since Waft_dip runs right
        //    before instantiate on both the load and the UI-add path.  Generic and
        //     collision-free for sibling cells of one kind (a board of Funkcion:Storying),
        //      with no kind-specific keys leaking into this host.  Fall back to kind (+ any
        //       binding) for a funk whose host isn't a dipped Waft — e.g. the trail Funkcion,
        //        which rides a Seem.
        const dip     = funk.c.Dip as string | undefined
        const bind    = (funk.sc.of_Book ?? funk.sc.of_dock ?? '') as string
        const funk_id = `${host.sc.Waft}/${dip ?? (funk.sc.Funkcion + (bind ? '/' + bind : ''))}`
        const fr = await funks.oai({ req: 'Funkcion', funk_id, eternal: 1 })
        fr.c.host = host
        fr.c.funk = funk
        fr.c.run_args = args
        // wire the behaviour as a do_fn (one-shot; doai no-ops on re-register, but the
        //  .c refs above are refreshed each call so the wired closure reads current).
        ;(await funks.doai({ req: 'Funkcion', funk_id, eternal: 1 }))?.(async (req: TheC) => {
            const run = (req.c.funk as TheC | undefined)?.c.run as
                ((host: TheC, funk: TheC, ...a: any[]) => void | Promise<void>) | undefined
            if (run && req.c.host) await run(req.c.host as TheC, req.c.funk as TheC, ...((req.c.run_args as any[]) ?? []))
            req.sc.ok = 1   // pass-local; eternal req re-arms next tick
        })
        return fr
    },
    async Lies_pump_funkcions(w: TheC) {
        const funks = w.o({ Funkcions: 1 })[0] as TheC | undefined
        if (funks) await funks.do()
    },

    // ── Lies_instantiate_funkcions ────────────────────────────────────────────────
    //   Generalise GhostList's hand-wired bind (Waft_spec §201's ⛑️): on Waft load —
    //   and on a later in-place edit — every embedded %Funkcion whose KIND (its mainkey
    //   value: Funkcion:Storying, …) is registered in FUNK_KINDS gets that kind's `run`
    //   bound and registered into the central host.  The kind owns the behaviour; this
    //   only wires it.  Idempotent: a funk already carrying a run (the dirlist, or a prior
    //   pass) is skipped, so re-calling on every mutation is cheap.  Walks the whole Waft
    //   subtree so a cell can ride anywhere (a row under a group, not just a top child).
    async Lies_instantiate_funkcions(w: TheC, waft: TheC): Promise<void> {
        const H   = this as House
        const all: TheC[] = []
        const walk = (c: TheC) => { for (const k of c.o() as TheC[]) { all.push(k); walk(k) } }
        walk(waft)
        for (const funk of all) {
            if (funk.sc.Funkcion === undefined) continue          // only %Funkcion embeds
            if (funk.c.run) continue                               // already bound (dirlist / prior load)
            const kind = FUNK_KINDS[funk.sc.Funkcion as string]   // the kind owns the behaviour
            if (!kind?.run) continue                               // unknown, or an action kind (no pumped run)
            funk.c.run = kind.run
            await H.Lies_register_funkcion(w, waft, funk, w)
        }
    },

    // ── GhostList_funkcion ──────────────────────────────────────────────────────
    //   Install the GhostList's dirlist behaviour on funk.c.run (off-snap), riding the
    //   Waft directly (Waft/Funkcion:dirlist — no Seem), and register its central
    //   req:Funkcion in Lies/Funkcions.  Idempotent — installs|registers once.
    async GhostList_funkcion(gl: TheC, w: TheC): Promise<TheC> {
        const funk = gl.oai({ Funkcion: 'dirlist' })
        funk.sc.interval_ms ??= 8000
        if (funk.c.run) return funk
        delete funk.sc.walked_at   // a fresh install (incl. after a load) walks at once
        const H = this as House

        // src/lib/O is open by default — seed its %open_dir exactly once per list (tracked by
        //  sc.O_defaulted) so a brand-new OR an already-persisted GhostList shows the O/ ghosts
        //   without a click, while a later user collapse still sticks (the one-shot never re-seeds).
        if (!gl.sc.O_defaulted) { gl.oai({ open_dir: 'src/lib/O' }); gl.sc.O_defaulted = 1 }

        // the roots are always listed; the user opens deeper dirs by clicking (each becomes an
        //  %open_dir child), and those get listed too — a navigable tree. Ghost/ holds the .g
        //   docks; src/lib/O rides in as the default-open subdir of src/lib (seeded above), not a root.
        const ROOTS = ['src/lib', 'Ghost']
        const SRC   = /\.(svelte|svelte\.ts|ts|g)$/
        // the hive clusters on the filename minus its source suffix, so Lang*|Lies* fold onto
        //  shared stems rather than all sharing `.svelte` (and Peeroleum.g → Peeroleum).
        const stem  = (name: string) => name.replace(/\.(svelte\.ts|svelte|ts|g)$/, '')

        funk.c.run = async (host: TheC, _fk: TheC, ww: TheC) => {
            const now = Date.now()
            const interval = (funk.sc.interval_ms as number) ?? 8000
            // throttle re-walks; a finished walk goes quiet until the interval lapses
            if (funk.sc.walked_at && now - (funk.sc.walked_at as number) < interval) return

            const seeded = !!host.sc.seeded   // a baseline walk has happened → newer files glow
            const opened = (host.o({ open_dir: 1 }) as TheC[]).map(o => o.sc.open_dir as string)
            const dirs   = [...new Set([...ROOTS, ...opened])]

            let pending = false, changed = false
            for (const dir of dirs) {
                const lreq = await H.LiesStore_listing(ww, dir)
                if (!lreq.sc.finished) { pending = true; continue }   // come back next tick
                const reply   = lreq.sc.reply as { entries?: { name: string, is_dir: boolean }[] } | undefined
                const entries = reply?.entries ?? []
                const group   = host.oai({ group: dir })             // GhostList/<dir>/…
                group.sc.dir  = dir
                for (const e of entries) {
                    const path = `${dir}/${e.name}`
                    if (e.is_dir) {                                  // a subdir — click opens it
                        if (!group.oa({ sub: path })) changed = true
                        group.oai({ sub: path }).sc.name = e.name
                    } else if (SRC.test(e.name)) {                   // a ghost file — click gotos it
                        const fresh = !group.oa({ Doc: path })
                        const d = group.oai({ Doc: path })
                        d.sc.name = stem(e.name)
                        // noticed_at = first seen AFTER the baseline; the UI glows it for 24h.
                        //  (not created_at — that's a stripped SESSION_KEY, never persists.)
                        if (fresh) { changed = true; if (seeded) d.sc.noticed_at = now }
                    }
                }
                // < prune sub|Doc entries whose dir|file vanished; oai-only is fine for now.
            }
            if (!pending) {
                funk.sc.walked_at = now
                if (!host.sc.seeded) host.sc.seeded = now   // first full walk = baseline; nothing glows
                if (changed) host.bump_version()            // bump|render only on real change
            }
        }
        await H.Lies_register_funkcion(w, gl, funk, w)   // the Funkcion spawns its central req
        return funk
    },

//#endregion
//#region Ballistics — action Funkcions: strike-on-demand + self-arm
//
//  havoc.  A "limb" is authored as content — a %havoc particle dropped anywhere in
//  a Waft tree (Waft.svelte renders it inline as a strikeable pad; a switcheroo Waft
//  in raw mode shows the bare particle instead).  The particle is pure config
//  (havoc:<kind>, + any params); the *behaviour* lives here, in HAVOC_LIMBS, keyed
//  by kind — so the drum-machine is reusable while each test authors which limbs it
//  carries.  Struck via e_Lies_strike (not auto-pumped like w:Lies/Funkcions).
//
//  A pad is struck by hand (e_Lies_strike).  A pad authored with `arm:1` also
//   *self-arms*: Lies_arm_engaged strikes it the moment its What is looked at.

    // ── e_Lies_strike ────────────────────────────────────────────────────
    //   Strike a havoc pad: run the HAVOC_LIMBS behaviour for e.sc.kind, then wake a
    //   tick so whatever state it touched settles.  e.sc: { kind: string }
    async e_Lies_strike(A: TheC, w: TheC, e: TheC) {
        const H = this as House
        if (await run_limb(H, w, e.sc.kind as string)) H.i_elvisto(w, 'think')
    },

    // ── Lies_arm_engaged ─────────────────────────────────────────────────
    //   Self-arming limbs (parked first cut — dormant until a pad opts in with
    //   arm:1).  Called from Lies_i_Spotlight on every cursor move.  When the
    //   *engaged What* changes, strike every %havoc,arm limb authored in that
    //   What's subtree — the test runs itself the moment its What is looked at.
    //   Engagement rides the Spotlight cursor, which Lang opens and scrolls the
    //   What's region into view, so "engaged" already means "not folded away"
    //   (Lang openness + Scrollability) without a second signal.  Edge-triggered
    //   on the What via examining.c.engaged_what: moving the cursor within one
    //   What does not re-fire; leaving and returning re-arms.
    //
    //   < KNOWN RACE / deferred: firing synchronously here races a cold dock
    //     open — the cursor move that engages the What also kicks the dock open
    //     (Lang_workon_update → Dock_open), which settles over later req:Store
    //     ticks, so a limb that reads the active doc (surprise_read) can fire
    //     before the %Good has content and silently no-op with no retry.  The
    //     proper home is the tick pump at a run-level: the Funkcion pump runs in
    //     req:Store Phase 2b, AFTER dock reads land, and re-runs every tick — so
    //     an armed limb hosted there self-gates on readiness and retries until
    //     the dock is up.  Build that (with maz-leveled sequencing = the drum
    //     machine) when self-arming is picked back up; Funkcions come later.
    async Lies_arm_engaged(examining: TheC, src: TheC) {
        const H = this as House
        const w = examining.c.w as TheC | undefined
        if (!w || !src) return
        // climb src → its containing What (or src itself if it is the What)
        let what: TheC | undefined = src
        while (what && (what.sc as any).What === undefined) what = what.c?.up as TheC | undefined
        if (what === examining.c.engaged_what) return   // same What — already armed
        examining.c.engaged_what = what
        if (!what) return
        const limbs: TheC[] = []
        await new Travel().dive({
            n: what,
            match_sc: {},
            // a Ballistics pad — folded form (%Funkcion:Ballistics,kind:…) or legacy (%havoc:…) —
            //  with arm:1 self-fires.  Limb name = the kind either way.
            each_fn: async (n: TheC) => {
                const ballistic = n.sc.Funkcion === 'Ballistics' || n.sc.havoc !== undefined
                if (ballistic && n.sc.arm) limbs.push(n)
            },
        })
        let fired = false
        for (const c of limbs)
            if (await run_limb(H, w, (c.sc.kind ?? c.sc.havoc) as string, c)) fired = true
        if (fired) H.i_elvisto(w, 'think')
    },

//#endregion
//#region editor↔runner — run intent & the verdict wire
//
//   What a Funkcion cell FIRES (a Storying cell's click) and what it READS (the
//    verdict that lands back).  The run intent goes out two ways — a dock cell arms
//     a run (Esc's "run it now"), a Book cell commands the runner to become that Book
//      — and the outcome returns as a %run_result the cell colours itself from.  The
//       channel TRANSPORT (Peering/Pier standup, rungo send, gen_write, heartbeat)
//        stays in LiesLies; this is only the run-intent + verdict surface that the
//         dynamic web touches.  May grow into a Cred*_result|verdict|instruct family
//          as the Creduler matures (spec/Editron.md §5/§6).

        // ── e_Lies_run_arm — the "run it now" signal (Esc in the editor) ──────
        //
        //   Esc means "I'm keen to run this now."  The editor compiles + writes the
        //    .go (it never runs the code itself — the Pantheate split), then arms a
        //     run on the runner that shares the Waft.  This is the local-first half
        //      of the editor↔runner channel: the same {path, mode} the Peeroleum
        //       dock_push frame will carry over the wire later (heading 10).
        //
        //   By role:
        //     editor — emit the go-run intent outward.  Locally there is usually no
        //              co-resident runner Run, so this stamps the intent (snapped as
        //               w%run_arm) + logs; the websocket transport (deferred) is what
        //                delivers it cross-instance.  The editor never drives a run.
        //     runner — invalidate the dock's Good so the recompile reads the fresh
        //              source (the good.c.content short-circuit otherwise serves
        //               stale bytes — see LiesStore_read_good's "force a re-read:
        //                delete good.c.content"), then resume (in_place) or, for an
        //                 explicit runner, reset (from_start, the Story_reset path).
        //
        //   e.sc: { path, mode? }   mode falls back to the stored editor preference.
        async e_Lies_run_arm(A: TheC, w: TheC, e: TheC) {
            const H    = this as House
            const path = e.sc.path as string | undefined
            const mode = (e.sc.mode as string) ?? H.Lies_run_mode()

            if (H.Lies_is_editor(w)) {
                // Snap the last arm.  The runner re-runs off the Rungo the compile-write
                //  emits (Lies_send_rungo), so once the channel is live the arm is a record,
                //   not a wait — only call it "awaiting" when the channel is down.
                w.oai({ run_arm: 1 }, { path, mode })
                const live = H.Lies_channel_live(w)
                H.tlog(`🔪 editor arm-run → ${path} [${mode}] ${live ? '(channel live — runner runs on Rungo)' : '(awaiting channel)'}`)
                return
            }

            // runner (or a bare dev Lies): drive the actual run.
            H.Lies_drive_run(w, path, mode as 'in_place' | 'from_start')
            H.tlog(`🔪 runner arm-run → ${path} [${mode}]`)
        },

        // Lies_drive_run — make the runner ACTUALLY run `path`.  The Story Run House is
        //  no_ambient (story_drive owns its clock), so an ambient think on an actor w never
        //   reaches it.  Two cases for "which Run":
        //    • inner Lies (old test path): H itself IS the Run House (%Run).
        //    • Creduler (the runner, outside Story): H is Mundo — find the sibling Run House
        //       (the one carrying %Run) and drive THAT; the dock's %Good lives on the Run's
        //        inner compiler Lies, not on this Creduler's w, so invalidate it there.
        //   from_start: tear down + rebuild via Auto/resetStory (no explicit Book → active one).
        //    in_place: invalidate the inner Good + re-kick the Run (main(true) bypasses no_ambient,
        //     cf Story's own Run.main(true)) + a think to re-pump its compile req-stack.
        Lies_drive_run(w: TheC, path?: string, mode?: 'in_place' | 'from_start') {
            const H   = this as House
            mode = mode ?? H.Lies_run_mode()
            const Run = ((H as any).sc?.Run ? H
                : H.top_House().all_House.find((h: any) => h.sc?.Run)) as House | undefined
            if (path && Run) {
                // the Good lives on the Run's inner compiler Lies (or on H itself for the old path)
                const innerW = ((Run.o({ A: 'Lies' })[0] as TheC | undefined)?.o({ w: 'Lies' })[0]
                    ?? w) as TheC
                const good = (Run as any).LiesStore_good_of(innerW, 'text/Doc', path) as TheC | undefined
                if (good) delete good.c.content   // force the next read off disk
            }
            if (mode === 'from_start') {
                H.top_House().i_elvisto('Auto/Auto', 'resetStory', {})
            } else if (Run) {
                (Run as any).i_elvisto(Run, 'think')   // wake the inner compile req-stack
                Run.main(true)                          // re-kick the no_ambient Story Run
            }
        },

        // ── become-Book — point the runner at a Book and run it (§5e build-order b) ───────
        //   A Credence Book cell's click flows here.  The editor SHIPS the command (it never
        //    runs anything itself — Pantheate split); the runner RESETS its Story onto that
        //     Book.  resetStory works on a runner with no Library (Auto.svelte: Book off the
        //      event), so the path the click needs already fires.  No dock/dige: a Book run is
        //       not a compile-driven Rungo, so we stash awaiting_verdict{book} ourselves and the
        //        same storyFinished → Lies_runner_verdict → run_result loop reports it back, keyed
        //         by the Book (Lies_run_result_recv accepts a Book-keyed result with no path).
        //   LANDMINE (untested): Auto.auto_reset_story still has `throw "forgot A"` in its
        //    existing-H:Story teardown loop — switching Books after one is up may throw until
        //     that's fixed.  First boot is fine.
        async e_Lies_become_book(A: TheC, w: TheC, e: TheC) {
            const H    = this as House
            const book = e.sc.book as string | undefined
            if (!book) return
            if (H.Lies_is_editor(w)) {
                const sent = H.Lies_send_become_book(w, book)
                H.tlog(`🎬 editor become_book → ${book} ${sent ? '(sent)' : '(channel down — no runner)'}`)
            } else {
                H.Lies_become_book_drive(w, book)   // runner, or a bare dev Lies with a co-resident Run
            }
        },

        // Lies_send_become_book — editor emit, mirrors Lies_send_rungo (same direction, the
        //  rungo channel).  Returns false when the channel is down so the caller can say so.
        Lies_send_become_book(w: TheC, book: string): boolean {
            const H = this as House
            if (!H.Lies_is_editor(w)) return false
            const pier = (w.o({ Peering: 1 })[0] as TheC | undefined)?.o({ Pier: 1 })[0] as TheC | undefined
            if (!pier || !H.Lies_channel_live(w)) return false
            ;(H as any).Peeroleum_send_consumer(w, 'become_book', { book })
            H.tlog(`📤 become_book → runner: ${book}`)
            return true
        },

        // Lies_become_book_recv — runner receives the command and drives the run.
        async Lies_become_book_recv(w: TheC, frame: any): Promise<boolean> {
            const H    = this as House
            const book = frame?.book as string | undefined
            if (!book) return false
            H.tlog(`📥 become_book recv: ${book}`)
            H.Lies_become_book_drive(w, book)
            return true
        },

        // Lies_become_book_drive — stash the awaiting_verdict{book} (so the finish reports a
        //  verdict for this Book) and resetStory onto it.
        Lies_become_book_drive(w: TheC, book: string) {
            const H = this as House
            w.c.awaiting_verdict = { book }
            H.top_House().i_elvisto('Auto/Auto', 'resetStory', { Book: book })
            H.tlog(`🎬 become_book drive → ${book}`)
        },

        // Lies_report_result — runner emit, after a run settles.  The editor's handler
        //  re-attaches it so the staging chrome lights up.
        Lies_report_result(w: TheC, sc: { path?: string, dige?: string, ok?: boolean, errors?: any[], snap_dige?: string, ok_pct?: number, done?: number, book?: string }) {
            const H = this as House
            if (!H.Lies_is_runner(w)) return
            const pier = (w.o({ Peering: 1 })[0] as TheC | undefined)?.o({ Pier: 1 })[0] as TheC | undefined
            if (!pier || !H.Lies_channel_live(w)) return
            ;(H as any).Peeroleum_send_consumer(w, 'run_result', { path: sc.path, dige: sc.dige, ok: sc.ok, errors: sc.errors, snap_dige: sc.snap_dige, ok_pct: sc.ok_pct, done: sc.done, book: sc.book })
            H.tlog(`📤 run_result → editor: ${sc.path} ${sc.ok ? 'green' : 'red'}${sc.done != null ? ` ${Math.round((sc.ok_pct ?? 0) * sc.done)}/${sc.done}` : ''}`)
        },

        // Lies_runner_verdict — the REAL verdict, sent from storyFinished on a runner.  The run
        //  fired by req_rungo is async, so its outcome isn't known at FIRE; Cred_run_outcome reads
        //   the just-finished Story's %ok steps / total.  Reports it against the dock the last rungo
        //    fired on (w.c.awaiting_verdict, stashed at FIRE), then clears the slot.  One slot only:
        //     v1 runs are sequential, so the latest FIRE owns the next finish.  A finish with no
        //      awaiting_verdict (the runner's own boot run) reports nothing.
        Lies_runner_verdict(w: TheC, book?: string) {
            const H = this as House
            if (!H.Lies_is_runner(w)) return
            const aw = w.c.awaiting_verdict as { path?: string, dige?: string, book?: string } | undefined
            if (!aw) return
            const outcome = (H as any).Cred_run_outcome() as { ok: boolean, ok_pct: number, done: number } | null
            if (!outcome) return
            w.c.awaiting_verdict = undefined
            // a Rungo run carries a {path,dige}; a become-Book run carries {book} only.  Either
            //  way the report carries the Book (storyFinished's bname), so a Book cell can match.
            H.Lies_report_result(w, { path: aw.path, dige: aw.dige, ok: outcome.ok, ok_pct: outcome.ok_pct, done: outcome.done, book: book ?? aw.book })
        },

        // Lies_run_result_recv — editor receives the runner's outcome and stamps it on
        //  the dock so the staging chrome can read ok/errors/snap_dige off the snap.
        async Lies_run_result_recv(w: TheC, frame: any): Promise<boolean> {
            const H = this as House
            // a dock run keys by its path; a become-Book run has no dock, so key by the Book
            //  (a synthetic `Book:<name>` slot).  Either way `book` rides as a field so a Book
            //   cell matches by it.
            const path = (frame?.path ?? (frame?.book ? `Book:${frame.book}` : undefined)) as string | undefined
            if (!path) return false
            // roai (not oai): bump w:Lies so Liesui's Cred readout re-renders — oai would merge
            //  in place and bump only the %run_result child, which the header $effect doesn't track.
            await w.roai({ run_result: 1, path }, {
                ok: frame.ok ? 1 : 0,
                errors: Array.isArray(frame.errors) ? frame.errors.length : 0,
                snap_dige: frame.snap_dige, dige: frame.dige, at: Date.now(),
                ...(frame.ok_pct != null ? { ok_pct: frame.ok_pct } : {}),
                ...(frame.done   != null ? { done: frame.done }     : {}),
                ...(frame.book   != null ? { book: frame.book }     : {}),
            })
            H.tlog(`📥 run_result: ${path} ${frame.ok ? 'green' : 'red'}${frame.done != null ? ` ${Math.round((frame.ok_pct ?? 0) * frame.done)}/${frame.done}` : ''}`)
            return true
        },

//#endregion

})
})
</script>
