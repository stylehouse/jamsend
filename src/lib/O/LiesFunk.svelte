<script lang="ts">
// LiesFunk.svelte — the dynamic web on Waft** (was LiesWaft; "Waft" the name now
//   belongs to the document model in Lies.svelte, not this Funkcion-host runtime).
//
//   A Waft is the editable web; the live, interactive stuff that rides ON it —
//   the Funkcions (monitor cells and action drum-pads), the Waft address space
//   they key against, and the editor↔runner verdict wire a Funkcion cell fires
//   and reads — all gathers here, gathered out of the Lies* modules that used to
//   each own a slice (LiesStore, LiesHold, LiesCurse, LiesLies).  The Funk kinds
//   themselves live under O/Funk/ (kinds.ts + one module per kind); this is the
//   HOST runtime that instantiates, pumps, and strikes them, plus the Waft-shaped
//   plumbing underneath.
//
//   Like its siblings this is a House mixin: no JS classes, methods on `this`,
//   mixed into the one H.* table by M.eatfunc.  Mounted by Lies.svelte alongside
//   LiesStore/LiesHold/LiesCurse/LiesLies — file placement is purely organisational.
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

// HAVOC_LIMBS — the havoc drum-machine's reusable behaviours, keyed by limb kind.
//  Each limb pops a different part of the Lies/Store plumbing.  A Ballistics pad
//  (Funkcion:Ballistics,kind:…) authored in a Waft is the per-test config; this is the
//  shared behaviour the strike runs.  Add a limb by adding an entry — the inline pad
//  (Waft.svelte) and e_Lies_strike both dispatch by kind, so nothing else needs touching.
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
//  Ballistics pad c (its params).  Shared by the manual strike (e_Lies_strike)
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

        // Inline suggestion: a What full of Funkcions (e.g. a Credence group) reads best as its
        //  illusions flowed inline, not a bullet list of structural rows.  Stamp c.inlined on such
        //   a What so the Waft UI lays it out inline by default (off-snap, a hint the author can
        //    force with %What,inline and the user can flip per-session).  Re-run on every load /
        //     in-place edit, so it self-corrects when a non-Funkcion child is added or removed.
        const mark_inlined = (c: TheC) => {
            for (const k of c.o() as TheC[]) {
                if (k.sc.What !== undefined) {
                    const kids = k.o() as TheC[]
                    const funkfull = kids.length > 0 &&
                        kids.every(x => x.sc.Funkcion !== undefined)
                    if (funkfull) k.c.inlined = 1; else delete k.c.inlined
                }
                mark_inlined(k)
            }
        }
        mark_inlined(waft)
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

    // ── Lens — the ambient hoisted-UI bag (dock + InterestStrip pop-outs) ──────────
    //   A Lens is plural by design: Lens:<LensKind>,of_Funkcion:<funk-kind>.  The Lens-KIND is
    //   the slot|intensity — Panel rides the bottom dock (the presence:always accreting stack
    //   over Lies), InterestSmall|InterestBig pop in the InterestStrip.  of_Funkcion names the
    //   source; LensHost mounts that Funkcion's comp_<LensKind> face.  A Lens is suggested by a
    //   Funkcion (from its pumped run, or a strike) or a system poke (the Id hatch, a server
    //   log, a peer's status), and held in the session ave on the TOP House (off-snap, never
    //   pumped: no c.up in the A/w spine, ave is outside the snap tree).  Identity is
    //   (LensKind, of_Funkcion), so re-suggesting lands on the same held particle — an oai merge
    //   + bump is how a live face notices change.
    Lies_lens_bag(): TheC {
        return (this as House).top_House().ave.oai({ Lenses: 1 })
    },
    //   Suggest (or refresh) a hoisted face.  sc carries altitude + any face state; funk (if
    //   given) backlinks the suggesting Funkcion cell so the face reads the same C its inline
    //   face does.  Returns the held Lens particle.
    Lies_lens_suggest(lensKind: string, of_Funkcion: string, sc: Record<string, any> = {}, funk?: TheC): TheC {
        const bag  = (this as any).Lies_lens_bag() as TheC
        const lens = bag.oai({ Lens: lensKind, of_Funkcion }, sc)
        if (funk) lens.c.funk = funk
        lens.bump_version(); bag.bump_version()
        return lens
    },
    //   Un-hoist a face — drop the held Lens.  A monitor that simply stops suggesting is the
    //   other retirement (sweep it when its reason passes); this is the explicit close.
    Lies_lens_dismiss(lensKind: string, of_Funkcion: string): void {
        const bag  = (this as any).Lies_lens_bag() as TheC
        const lens = bag.o({ Lens: lensKind, of_Funkcion })[0] as TheC | undefined
        if (lens) { bag.drop(lens); bag.bump_version() }
    },
    //   Toggle — the user's hand on a face (e.g. the Id-hatch action).
    Lies_lens_toggle(lensKind: string, of_Funkcion: string, sc: Record<string, any> = {}): void {
        const H = this as any
        if ((H.Lies_lens_bag() as TheC).oa({ Lens: lensKind, of_Funkcion })) H.Lies_lens_dismiss(lensKind, of_Funkcion)
        else H.Lies_lens_suggest(lensKind, of_Funkcion, sc)
    },

    // ── %Upkeep — the machine's background work-ledger (the opposite pole of %Interest) ──────
    //   %Upkeep is the quality of work the machine owes ITSELF — keeping endpoints up, Books green,
    //    ghosts compiled — surfaced at the Brink, never courting attention the way an %Interest does.
    //     Its units are %Errands: transient work-items (a ghost-compile in flight, a StoryTimes sweep
    //      grinding to green) that show while live and fade once settled.  Distinct from the cluster
    //       %Aim layer (Runner/Relay endpoint watch) on purpose — build churn stays out of that.
    //   The ledger is ambient on top_House().ave.{Upkeep} — off-snap like the Lenses bag (no c.up in
    //    the A/w spine, outside the snap tree).  An Errand is keyed Errand:<key> so a repeated report
    //     (a compile re-firing, a sweep ticking) lands on the same item.
    Upkeep_bag(): TheC {
        return (this as House).top_House().ave.oai({ Upkeep: 1 })
    },
    //   Upsert an Errand by key.  phase: running (live) | ok | failed (settled — fades, then GC'd).
    //    A settled report stamps `settled` so Lies_upkeep can reap it after it's shown a moment.
    Upkeep_errand(key: string, sc: Record<string, any>): TheC {
        const bag     = (this as any).Upkeep_bag() as TheC
        const settled = sc.phase && sc.phase !== 'running'
        const e = bag.oai({ Errand: key }, { ...sc, at: Date.now(), ...(settled ? { settled: Date.now() } : {}) })
        e.bump_version(); bag.bump_version()
        return e
    },
    //   Hoist/retire the Upkeep Brink by whether any Errand is live-or-recently-settled, GC'ing the
    //    long-settled ones.  Called every heartbeat (from any w — the ledger is global, one Brink).
    Lies_upkeep(_w: TheC): void {
        const H   = this as any
        const bag = H.Upkeep_bag() as TheC
        const now = Date.now()
        let live = 0, gc = false
        for (const e of bag.o({ Errand: 1 }) as TheC[]) {
            const settled = Number(e.sc.settled ?? 0)
            if (settled && now - settled > 8000) { bag.drop(e); gc = true; continue }
            live++
        }
        if (gc) bag.bump_version()
        if (live) {
            if (!(H.Lies_lens_bag() as TheC).oa({ Lens: 'Brink', of_Funkcion: 'Upkeep' }))
                H.Lies_lens_suggest('Brink', 'Upkeep', { altitude: 10 })   // atop Runner(20)/Relay(25)
        } else H.Lies_lens_dismiss('Brink', 'Upkeep')
    },

    // ── %Aim (naive) — the cluster-awareness Waft + its hoisted Brink faces ──────────
    //   The first, deliberately-thin %Aim: a Waft:Cluster,Aim holding two watcher Funkcions —
    //    Funkcion:Runner (the peer ping, %channel_peer) and Funkcion:Relay (the relay carrier,
    //     channel_up) — each a pumped run (kinds.ts) that stamps its latest transition, surfaced
    //      as a Lens:Brink hoisted into the Liesui-pinned dock.  Mature %Aim (a traffic-light
    //       aggregate, the relay control:log ring-buffer, a navigable fixture) layers onto this.
    //   The Waft is a runtime fixture (dontSnap) for now, reconstructed each boot from setup.
    async Lies_aim_setup(w: TheC): Promise<void> {
        const H = this as House
        const cluster = w.oai({ Waft: 'Cluster' }, { Aim: 1 })
        cluster.sc.dontSnap ??= 1
        for (const kind of ['Runner', 'Relay']) cluster.oai({ Funkcion: kind })
        await (H as any).Lies_instantiate_funkcions(w, cluster)   // binds each kind's run + registers the pump
    },
    //   Hoist (or retire) the cluster Brinks by role — called every heartbeat.  editor|runner
    //    means a remote relationship exists, so the endpoint faces are worth showing; otherwise
    //     they're dropped.  Each Brink backlinks its w (the monitored Lies) + funk cell, so the
    //      face reads the live state and the watcher's funk.c.latest.  Setup runs once (guarded).
    Lies_aim(w: TheC): void {
        const H = this as any
        if (!w.c.aim_setup) { w.c.aim_setup = true; void H.Lies_aim_setup(w) }
        const on = H.Lies_role(w) === 'editor' || H.Lies_role(w) === 'runner'
        const cluster = w.o({ Waft: 'Cluster' })[0] as TheC | undefined
        const kinds = ['Runner', 'Relay']
        for (let i = 0; i < kinds.length; i++) {
            const kind = kinds[i]
            if (on) {
                if (!(H.Lies_lens_bag() as TheC).oa({ Lens: 'Brink', of_Funkcion: kind })) {
                    const funk = cluster?.o({ Funkcion: kind })[0] as TheC | undefined
                    const lens = H.Lies_lens_suggest('Brink', kind, { altitude: 20 + i * 5 }, funk) as TheC
                    lens.c.w = w
                }
            } else H.Lies_lens_dismiss('Brink', kind)
        }
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
        // every file lists (a .md spec opens read-only just like a non-.g dock — no compile,
        //  no Point-nav yet, but visible and gotoable); the hive clusters on the filename
        //   minus its source suffix, so Lang*|Lies* fold onto shared stems rather than all
        //    sharing `.svelte` (and Peeroleum.g → Peeroleum). A non-source name (Peeroleum_spec.md)
        //     keeps its extension, since stripping nothing is the honest stem.
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
                    } else {                                         // any file — click gotos it
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
//  havoc.  A "limb" is authored as content — a Ballistics pad (Funkcion:Ballistics,
//  kind:…) dropped anywhere in a Waft tree (Waft.svelte renders it inline as a
//  strikeable pad; a switcheroo Waft in raw mode shows the bare particle instead).
//  The pad is pure config (kind:<…>, + any params); the *behaviour* lives here, in
//  HAVOC_LIMBS, keyed by kind — so the drum-machine is reusable while each test
//  authors which limbs it carries.  Struck via e_Lies_strike (not auto-pumped like
//  w:Lies/Funkcions).
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
    //   *engaged What* changes, strike every Ballistics pad marked %arm authored in that
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
            // a Ballistics pad (Funkcion:Ballistics,kind:…) marked %arm self-fires;
            //  limb name = its kind.
            each_fn: async (n: TheC) => {
                const ballistic = n.sc.Funkcion === 'Ballistics'
                if (ballistic && n.sc.arm) limbs.push(n)
            },
        })
        let fired = false
        for (const c of limbs)
            if (await run_limb(H, w, c.sc.kind as string, c)) fired = true
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
//          as the Creduler matures (spec/Editron.md §4 + TODO).

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

        // Lies_become_book_drive — open the durable run-record (Lies_runner_begin), stash the
        //  awaiting_verdict{book} (so the finish reports a verdict for this Book), and resetStory onto it.
        Lies_become_book_drive(w: TheC, book: string) {
            const H = this as House
            w.c.awaiting_verdict = { book }
            H.Lies_runner_begin(w, book)   // open the durable run-record (the become_book twin of rungo)
            H.top_House().i_elvisto('Auto/Auto', 'resetStory', { Book: book })
            H.Lies_runner_phase(w, 'story_begun', { book })   // blip: Run kicked (Book sweep / cell click)
            H.tlog(`🎬 become_book drive → ${book}`)
        },

        // Lies_report_result — runner emit, after a run settles.  The editor's handler
        //  re-attaches it so the staging chrome lights up.
        Lies_report_result(w: TheC, sc: { path?: string, dige?: string, ok?: boolean, errors?: any[], snap_dige?: string, ok_pct?: number, done?: number, caveat?: number, book?: string }) {
            const H = this as House
            if (!H.Lies_is_runner(w)) return
            const pier = (w.o({ Peering: 1 })[0] as TheC | undefined)?.o({ Pier: 1 })[0] as TheC | undefined
            if (!pier || !H.Lies_channel_live(w)) return
            ;(H as any).Peeroleum_send_consumer(w, 'run_result', { path: sc.path, dige: sc.dige, ok: sc.ok, errors: sc.errors, snap_dige: sc.snap_dige, ok_pct: sc.ok_pct, done: sc.done, caveat: sc.caveat, book: sc.book })
            H.tlog(`📤 run_result → editor: ${sc.path} ${sc.ok ? 'green' : 'red'}${sc.done != null ? ` ${Math.round((sc.ok_pct ?? 0) * sc.done)}/${sc.done}` : ''}`)
        },

        // Lies_runner_phase — runner emit, a transient progress blip up the channel so the editor
        //  can FEEL the run bouncing rather than wait blind for the verdict.  The arc is
        //   rungo_ack (got the authority) → story_begun (kicked the Run) → step_done×N (n/total)
        //    → all_done (steps finished, the real run_result is right behind it); step_stall fires
        //     while a single step drags (>2s, re-blipped each second) so a wedge is visible.
        //   Unlike run_result this is NOT a verdict and NOT persisted: the runner stamps nothing,
        //    the editor keeps the latest blip off-snap on w.c.run_phase.  No-op for a bare|editor
        //     Lies or a down channel — same gate as Lies_report_result, so it's safe to call from
        //      anywhere a run progresses (Story stepping included).
        Lies_runner_phase(w: TheC, phase: string, extra?: { n?: number, total?: number, secs?: number, book?: string, path?: string, seq?: number }) {
            const H = this as House
            // write the step's feedback THROUGH onto the durable run-record first — role-agnostic, so
            //  the snap (and any client) reads live progress even with the channel down or on a bare
            //   dev Lies.  The record is the durable sink; the channel blip below is the live echo.
            H.Lies_runner_track(w, phase, extra)
            if (!H.Lies_is_runner(w)) return
            const pier = (w.o({ Peering: 1 })[0] as TheC | undefined)?.o({ Pier: 1 })[0] as TheC | undefined
            if (!pier || !H.Lies_channel_live(w)) return
            ;(H as any).Peeroleum_send_consumer(w, 'run_phase', { phase, ...extra })
        },

        // Lies_runner_begin — open a fresh durable run-record (Storyrun:<ident>) for a run the runner
        //  is about to drive: the runner-side noun a rungo (ident = dock path) or become_book (ident =
        //   Book) produces, on-snap beside req:Cortex.  Phase walks begun → stepping (n/total fill in
        //    as steps land) → done|failed.  One run at a time (v1 is sequential), so it drops any prior
        //     record first.  This is the durable CLIENT that holds each step's feedback — not the
        //      fire-and-forget blip the under-designed rungo/become_book pair shipped before.
        Lies_runner_begin(w: TheC, ident: string) {
            for (const old of w.o({ Storyrun: 1 }) as TheC[]) w.drop(old)
            w.i({ Storyrun: ident, phase: 'begun', at: Date.now() })
        },

        // Lies_runner_track — fold a transient progress blip onto the durable Storyrun record (the
        //  runner-side noun a rungo / become_book produces; opened by Lies_runner_begin).  Maps the
        //   blip arc onto a settled phase + n/total so a client reads "running PereStaple, 4/9"
        //    straight off the snap.  No-op when no record is up (a stray blip).
        //   rungo_ack/story_begun → begun; step_done/step_stall → stepping; all_done → all_done
        //    (the verdict stamp in Lies_runner_verdict lands the final done|failed right behind it).
        Lies_runner_track(w: TheC, phase: string, extra?: { n?: number, total?: number }) {
            const sr = w.o({ Storyrun: 1 })[0] as TheC | undefined
            if (!sr) return
            sr.sc.phase = phase === 'step_done' || phase === 'step_stall' ? 'stepping'
                        : phase === 'all_done'                            ? 'all_done'
                        : phase === 'rungo_ack' || phase === 'story_begun' ? 'begun'
                        : phase
            if (extra?.n     != null) sr.sc.n     = extra.n
            if (extra?.total != null) sr.sc.total = extra.total
            sr.bump_version()
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
            const outcome = (H as any).Cred_run_outcome() as { ok: boolean, ok_pct: number, done: number, caveat: number } | null
            if (!outcome) return
            w.c.awaiting_verdict = undefined
            // all_done precedes the real run_result: the steps are in, the verdict is one frame
            //  behind.  Carries the final n/total so the panel lands on a complete count.
            H.Lies_runner_phase(w, 'all_done', { n: outcome.done, total: outcome.done, book: book ?? aw.book, path: aw.path })
            // land the run-record done — phase done|failed wins over the all_done the blip just wrote,
            //  so `Lies%runner/Storyrun` shows the completed verdict, not a frozen 'stepping'.
            const sr = w.o({ Storyrun: 1 })[0] as TheC | undefined
            if (sr) {
                sr.sc.phase = outcome.ok ? 'done' : 'failed'
                sr.sc.done  = outcome.done
                if (outcome.caveat) sr.sc.caveat = outcome.caveat
                sr.bump_version()
            }
            // a Rungo run carries a {path,dige}; a become-Book run carries {book} only.  Either
            //  way the report carries the Book (storyFinished's bname), so a Book cell can match.
            //   caveat rides along (§10): forgiven steps are green but tagged "passed, N forgiven".
            H.Lies_report_result(w, { path: aw.path, dige: aw.dige, ok: outcome.ok, ok_pct: outcome.ok_pct, done: outcome.done, caveat: outcome.caveat, book: book ?? aw.book })
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
                ...(frame.caveat != null ? { caveat: frame.caveat } : {}),
                ...(frame.book   != null ? { book: frame.book }     : {}),
            })
            H.tlog(`📥 run_result: ${path} ${frame.ok ? 'green' : 'red'}${frame.done != null ? ` ${Math.round((frame.ok_pct ?? 0) * frame.done)}/${frame.done}` : ''}`)
            return true
        },

        // Lies_run_phase_recv — editor receives a runner progress blip and keeps the LATEST one
        //  off-snap on w.c.run_phase (transient — a fresh value each step; persisting it would be
        //   pure snap noise).  A version bump wakes Liesui's runner panel; all_done clears the slot
        //    after a beat so the panel goes quiet between runs rather than freezing on the last step.
        async Lies_run_phase_recv(w: TheC, frame: any): Promise<boolean> {
            const H = this as House
            const phase = frame?.phase as string | undefined
            if (!phase) return false
            w.c.run_phase = { phase, n: frame.n, total: frame.total, secs: frame.secs, book: frame.book, path: frame.path, seq: frame.seq, at: Date.now() }
            w.bump_version()
            H.tlog(`📥 run_phase: ${phase}${frame.n != null ? ` ${frame.n}/${frame.total ?? '?'}` : ''}${frame.book ? ` [${frame.book}]` : ''}`)
            return true
        },

//#endregion
//#region StoryTimes — the run-all sweep (Editron §5f, the Credulation stationing)

        // ── Lies_storytimes_drive — the sweep sequencer (%Upkeep: the run-til-green Errand) ──────
        //   A StoryTimes station (Funkcion:StoryTimes) is struck → its component arms
        //    funk.c.sweep={phase:'arm'}; the central Funkcions pump ticks storytimes_run, which lands
        //     here.  We run every %of_Book Storying cell in the station's scope, but as an %Upkeep
        //      ERRAND that pursues a green: pass 0 attempts every Book once IN ORDER, never spinning on
        //       the first !ok (it moves on); then up to `retries` passes re-attempt only the not-green
        //        ones — "try the later ones, then come back to the earlier".  The runs are jettisoned
        //         from memory at the source: each dispatch is a become_book, which Story_resets (tears
        //          down + rebuilds) the runner's prior Story — so shooting the next Storying frees the
        //           last one and runs don't pile up.  We KEEP the editor-side run_result verdicts (the
        //            Storying cells read them).  One Book in flight at a time (the runner-addressing
        //             limit); the sweep rides off-snap on funk.c.sweep and mirrors to the Brink as
        //              Errand:sweep:<scope>.
        async Lies_storytimes_drive(host: TheC, funk: TheC, w: TheC) {
            const H = this as House
            const s = funk.c.sweep as any
            if (!s || s.phase === 'idle' || s.phase === 'done') return

            if (s.phase === 'arm') {                                   // build the roster once, then run
                const books = H.Lies_storytimes_books(funk, host)
                const scope = funk.sc.all ? 'all' : H.Lies_storytimes_scope(funk)
                funk.c.sweep = { phase: books.length ? 'running' : 'done', scope,
                                 books: [...books], queue: [...books], inflight: [], results: {},
                                 pass: 0, retries: 2, total: books.length, started: Date.now() }
                funk.bump_version()
                H.tlog(`⇶ StoryTimes ${scope}: ${books.length} Book(s) — ${books.join(', ')}`)
                H.Upkeep_errand(`sweep:${scope}`, { kind: 'sweep', label: scope, pass: 0, green: 0, total: books.length, phase: books.length ? 'running' : 'ok' })
                return
            }
            if (s.phase !== 'running') return

            let changed = false
            // reap settled / timed-out dispatches.  A Book is green when a run_result newer than its
            //  dispatch lands OK; an !ok (or a 60s stall) is left not-green for a later retry pass.  The
            //   verdict run_result is kept either way — the Storying cell shows it; the run itself was
            //    already jettisoned on the runner by the next become_book's Story_reset.
            const still: any[] = []
            for (const f of s.inflight) {
                const rr = (w.o({ run_result: 1 }) as TheC[])
                    .filter(r => r.sc.book === f.book)
                    .sort((a, b) => Number(b.sc.at ?? 0) - Number(a.sc.at ?? 0))[0]
                const fresh = !!rr && Number(rr.sc.at ?? 0) > f.at
                if (fresh)                     { s.results[f.book] = rr!.sc.ok ? 'pass' : 'fail'; changed = true; continue }
                if (Date.now() - f.at > 60000) { s.results[f.book] = 'fail';                      changed = true; continue }
                still.push(f)
            }
            s.inflight = still

            // dispatch this pass's queue, one Book in flight (Editron §7: a become_book is a single-
            //  address broadcast today; firing two resets the one runner mid-run).  No mid-pass retry —
            //   a failed Book waits for the next pass, so we never spin in the first spot of trouble.
            const width = H.Lies_storytimes_width(w)
            while (s.inflight.length < width && s.queue.length) {
                const book = s.queue.shift() as string
                H.Lies_storytimes_dispatch(w, book)
                s.inflight.push({ book, at: Date.now() })
                changed = true
            }

            // pass complete: open a retry pass over just the not-green (up to s.retries), else settle.
            if (!s.queue.length && !s.inflight.length) {
                const notgreen = (s.books as string[]).filter(b => s.results[b] !== 'pass')
                if (notgreen.length && s.pass < s.retries) {
                    s.pass += 1; s.queue = [...notgreen]; changed = true
                    H.tlog(`↻ StoryTimes ${s.scope} retry ${s.pass}/${s.retries}: ${notgreen.length} not-green — ${notgreen.join(', ')}`)
                } else {
                    s.phase = 'done'; changed = true
                    const green = (s.books as string[]).filter(b => s.results[b] === 'pass').length
                    H.tlog(`🏁 StoryTimes ${s.scope} done: ${green}/${s.total} green${notgreen.length ? ` · ${notgreen.length} stuck (${notgreen.join(', ')})` : ''}`)
                }
            }
            // mirror to the Brink as an %Upkeep Errand (live while running, settles ok|failed).
            {
                const green = (s.books as string[]).filter(b => s.results[b] === 'pass').length
                H.Upkeep_errand(`sweep:${s.scope}`, { kind: 'sweep', label: s.scope, pass: s.pass, green, total: s.total,
                    phase: s.phase === 'done' ? (green === s.total ? 'ok' : 'failed') : 'running' })
            }
            if (changed) funk.bump_version()
            // keep the loop alive at a brisk cadence while the sweep is in flight — otherwise it
            //  advances only on the idle 3s heartbeat (seconds dead per Book, on top of the run).  One
            //   timer per w, re-armed each running tick, abandoned once every sweep on this w settles
            //    (cf the creduler / req_rungo trickle); a verdict thus reaps within ~150ms, not a beat.
            if (s.phase === 'running' && !w.c.sweep_trickle) {
                w.c.sweep_trickle = setTimeout(() => { w.c.sweep_trickle = undefined; H.i_elvisto(w, 'think') }, 150)
            }
        },

        // the Books this station sweeps: every %of_Book Storying cell under its scope.  Scope is the
        //  station's containing What (its group), or the whole Waft when it rides the root or carries
        //   %all — the board-wide run-everything (§5f: "a StoryTimes at the Waft root that walks all
        //    Whats").  Order = snap order; dedup so an of_Book listed twice runs once.
        Lies_storytimes_books(funk: TheC, host: TheC): string[] {
            const scope = (this as House).Lies_storytimes_scope_c(funk, host)
            const out: string[] = []
            const walk = (c: TheC) => { for (const k of c.o() as TheC[]) {
                if (k.sc.Funkcion === 'Storying' && k.sc.of_Book) out.push(k.sc.of_Book as string); walk(k) } }
            if (scope) walk(scope)
            return [...new Set(out)]
        },
        Lies_storytimes_scope_c(funk: TheC, host: TheC): TheC {
            if (funk.sc.all) return host                              // %all → the whole Waft
            let node: any = funk.c.up
            while (node && node.sc?.What === undefined && node.sc?.Waft === undefined) node = node.c?.up
            return (node ?? host) as TheC
        },
        Lies_storytimes_scope(funk: TheC): string {                  // the scope's name, for logging
            let node: any = funk.c.up
            while (node && node.sc?.What === undefined && node.sc?.Waft === undefined) node = node.c?.up
            return (node?.sc?.What as string) ?? 'all'
        },

        // dispatch one become_book the way a Storying Book-cell click does — editor ships the frame,
        //  a bare/co-resident Lies drives locally.
        Lies_storytimes_dispatch(w: TheC, book: string): boolean {
            const H = this as House
            if (H.Lies_is_editor(w)) {
                const sent = H.Lies_send_become_book(w, book)
                H.tlog(`🎟 StoryTimes → ${book} ${sent ? '(sent)' : '(channel down — no runner)'}`)
                return sent
            }
            H.Lies_become_book_drive(w, book)                        // bare dev Lies with a co-resident Run
            return true
        },

        // Lies_runner_count — however many runners are on the phone (connected runner Piers on the
        //  editor's channel).  Surfaced on the station so you can see the fleet.
        Lies_runner_count(w: TheC): number {
            const peering = (w.o({ Peering: 1 })[0]) as TheC | undefined
            return peering ? (peering.o({ Pier: 1 }) as TheC[]).length : 0
        },
        // Lies_storytimes_width — how many Books we keep in flight.  A become_book today is a
        //  single-address broadcast to the one bridged runner (no per-runner `to` in the frame yet,
        //   Editron §7) — firing two at once would reset that runner's Story mid-run — so the sweep
        //    drives ONE at a time however many runners are detected.  When the channel carries a
        //     runner address, lift ADDRESSABLE to Lies_runner_count(w) and the same driver fans out.
        Lies_storytimes_width(w: TheC): number {
            const ADDRESSABLE = 1
            return Math.min(Math.max(1, (this as House).Lies_runner_count(w)), ADDRESSABLE)
        },

//#endregion

})
})
</script>
