<script lang="ts">
// LiesFunk.svelte — the dynamic web on Waft** (was LiesWaft; "Waft" the name now
//   belongs to the document model in Lies.svelte, not this Funkcion-host runtime).
//
//   A Waft is the editable web; the live, interactive stuff that rides ON it —
//   the Funkcions (monitor cells and action drum-pads), the Waft address space
//   they key against, and the editor↔runner verdict wire a Funkcion cell fires
//   and reads — all gathers here, gathered out of the Lies* modules that used to
//   each own a slice (LiesStore, LangHold, LiesCurse, LiesLies).  The Funk kinds
//   themselves live under O/Funk/ (kinds.ts + one module per kind); this is the
//   HOST runtime that instantiates, pumps, and strikes them, plus the Waft-shaped
//   plumbing underneath.
//
//   Like its siblings this is a House mixin: no JS classes, methods on `this`,
//   mixed into the one H.* table by M.eatfunc.  Mounted by Lies.svelte alongside
//   LiesStore/LangHold/LiesCurse/LiesLies — file placement is purely organisational.
//
//   The four regions:
//     Waft_dip            — the Waft address space (c.Dip), the per-Waft** id
//     Funkcions           — instantiate / bind / one req:Waftica carrier per Waft
//     Ballistics          — the action Funkcions: strike-on-demand + self-arm
//     editor↔runner       — run intent (Esc / Book cell) + the verdict wire back
//                            (may grow into Cred*_result|verdict|instruct, §Editron)

import { _C, REACTAP, type TheC } from "$lib/data/Stuff.svelte"
import { Selection, Travel } from "$lib/mostly/Selection.svelte"
import { type House } from "$lib/O/Housing.svelte"
import { FUNK_KINDS } from "$lib/O/Funk/kinds"
import { storying_run } from "$lib/O/Funk/Storying.svelte"
import { SoundSystem } from "$lib/p2p/ftp/Audio.svelte"
import { mint_grant, verify_grant, type GrantAtom } from "$lib/O/Funk/Grant"
import { browserTrustedPubs, prepubOf } from "$lib/p2p/cluster_trust"
import { RemoteWormholeNav } from "$lib/O/RemoteWormholeNav.svelte"
import { Dexie } from "dexie"
import { onMount } from "svelte"

let { M } = $props()

// ── test-music generator engine (for the MusuGenerateTestsMusic Book — a one-off dev-setup Book, not a node script) ──
//  Pure-tone tracks: the FREQUENCY IS THE LABEL, so the real-time race test decodes back which track
//   played each 50ms.  Musical + well-spaced (≥110Hz apart) so an FFT bin never confuses two.  artist-title
//    rides the filename ("Artist - Title.wav") — exactly what Crate_meta_from_name reads back.
//  Real-length (60-80s each) so streaming/preview/restock behave against a proper track, not a 4s stub.
//  Loudness: the shared 0.6 amplitude measures ~-7.5 LUFS on these tones (a sine's 3 dB crest factor
//   is loud for its peak) — so RaStock already gains the whole set DOWN ~6 dB to its -14 target and the
//    attenuate path is well covered.  Dorian D is laid down much quieter (amp) so it lands BELOW -14 and
//     RaStock has to gain it UP instead: the one track that exercises the boost direction (positive gain).
const TEST_TONES: Array<{ artist: string, title: string, freq: number, secs: number, amp?: number }> = [
    { artist: 'The Sines',    title: 'Deep A',   freq: 220.00, secs: 72 },
    { artist: 'The Sines',    title: 'Middle A', freq: 440.00, secs: 64 },
    { artist: 'The Sines',    title: 'High A',   freq: 1760.0, secs: 80 },
    { artist: 'Fourier Four', title: 'Query E',  freq: 329.63, secs: 68 },
    { artist: 'Fourier Four', title: 'Echo E',   freq: 1318.5, secs: 60 },
    { artist: 'DJ Oscillo',   title: 'Dorian D', freq: 587.33, secs: 76, amp: 0.2 },   // ~-17 LUFS, below target — RaStock's boost-direction proof track
    { artist: 'DJ Oscillo',   title: 'Groove G', freq: 783.99, secs: 66 },
    { artist: 'DJ Oscillo',   title: 'Cosmic C', freq: 1046.5, secs: 78 },
]

// pcm_sine — mono PCM of a pure sine (20ms fade in/out to avoid clicks).  Binary encode is
//  DSL-hostile, so it lives here (break-glass) and the .g Book orchestrates.  decodeAudioData reads it.
//  8kHz sample rate is DELIBERATE, not a stub: the highest tone is 1760Hz, so Nyquist (4kHz) keeps 2.3x
//   headroom — the sines are captured losslessly, yet the files are ~6x smaller than 48kHz (a 70s track is
//    ~1.1MB, not ~6.7MB).  That matters because these tracks travel the beat-latency wormhole to the
//     consumer Books (MusuReco/MusuBounce) and a fat file overruns a step's budget.  Consumers decodeAudioData
//      + resample to the context rate anyway, and MusuBounce's peak still lands on the true fundamental.
//  amp is the sine's linear amplitude (0.6 = the shared default, ~-7.5 LUFS on these tones — RaStock
//   gains that DOWN to -14); a caller passes a quieter value to lay down a below-target track (Dorian D)
//    that RaStock has to gain UP to -14 instead, proving the boost direction.
//  (Was wav_bytes, which ALSO wrapped the samples in a bare RIFF container — the reason every generated
//   test file carried NO tags.  The container now comes from Crate_wav_with_tags — the ghost's hand-rolled
//    LIST/INFO writer — so every file carries IART/INAM tags agreeing with its filename, and the synth
//     here returns just the PCM.)
function pcm_sine(freq: number, secs: number, sr = 8000, amp = 0.6): Float32Array {
    const n = Math.floor(sr * secs)
    const fade = Math.min(Math.floor(sr * 0.02), Math.floor(n / 2))
    const out = new Float32Array(n)
    for (let i = 0; i < n; i++) {
        let env = 1
        if (i < fade) env = i / fade
        else if (i > n - fade) env = (n - i) / fade
        out[i] = Math.sin(2 * Math.PI * freq * i / sr) * amp * env
    }
    return out
}

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

    // ── Funkcions — one carrier per Waft (req:Waftica) ─────────────────────────
    //   A Funkcion is behaviour on funk.c.run riding a Waft directly (Waft/Funkcion:$name —
    //    no Seem, no req inside the Waft).  It is NOT itself req-like: a Storying light or a
    //     peer ping is plain synchronous behaviour, not a tree of handshake moves — so a
    //      Funkcion gets NO req of its own.  Instead each Waft has exactly one carrier,
    //       req:Waftica,waft:<path>, in Lies/Funkcions; its do_fn walks the Waft subtree once
    //        per tick and runs every funk.c.run it finds.  (Was: one req:Funkcion per Funkcion
    //         — a board of 48 cells snapped 48 eternal reqs; this collapses them to one per
    //          Waft, and a migration drops the stale req:Funkcion on first ensure.)
    //   The carrier also carries main:<kind> — the Waft's dominant Funkcion, for the face|Lens
    //    layer — and is the home a later %Lango/excitement layer hangs on (the Waft's attention
    //     I/O).  run is (host, funk, w) — host is the Waft, w the world it lists against.
    async Lies_ensure_waftica(w: TheC, waft: TheC): Promise<TheC> {
        const funks = w.oai({ Funkcions: 1 })
        // funks is a plain container, so the A/w-spine c.up wiring never reaches it; point it
        //  at w so funks.do()'s _req_do_one can climb to the House (funks → w → A → House).
        funks.c.up = w
        // migration: drop the legacy per-Funkcion reqs — the Waftica subsumes them.  Fires on
        //  the first ensure of any Waft (funks is shared per-w); idempotent once they are gone.
        const stale = funks.o({ req: 'Funkcion' }) as TheC[]
        if (stale.length) { for (const old of stale) funks.drop(old); funks.bump_version() }
        const path = waft.sc.Waft as string
        const wf   = await funks.oai({ req: 'Waftica', waft: path, eternal: 1 })
        wf.c.waft  = waft
        // main:<kind> — the dominant Funkcion's kind: a flagged %Funkcion,main child, else the
        //  cell whose kind matches the Waft's snapped kind (P1); absent → a pure base carrier.
        const funkc = waft.o({ Funkcion: 1 }) as TheC[]
        const main  = (funkc.find(f => f.sc.main) ?? funkc.find(f => f.sc.Funkcion === waft.sc.kind))?.sc.Funkcion
        if (main) wf.sc.main = main as string; else delete wf.sc.main
        // the carrier's pump — walk the Waft subtree, run each bound funk.c.run once.  Wired
        //  once (doai no-ops on re-ensure); reads req.c.waft so a reload refreshes the host ref.
        ;(await funks.doai({ req: 'Waftica', waft: path, eternal: 1 }))?.(async (req: TheC) => {
            const host = req.c.waft as TheC | undefined
            if (host) {
                const run_all = async (c: TheC) => {
                    for (const k of c.o() as TheC[]) {
                        const run = k.c.run as ((h: TheC, f: TheC, ww: TheC) => void | Promise<void>) | undefined
                        if (run) await run(host, k, w)
                        await run_all(k)
                    }
                }
                await run_all(host)
            }
            req.sc.ok = 1   // pass-local; eternal carrier re-arms next tick
        })
        return wf
    },

    // ── lango — the universal attention-event setter (Backbone_plan P3 "The Lango channel") ──
    //   A %Lango = an intent to do something with a piece of the source, tracked over time.
    //    lango mints it onto the SOURCE Waft's one carrier (req:Waftica) — the source terminal,
    //     i_elvis_req-shaped: where i_elvis_req hangs a req the reply rides back on, this hangs
    //      the %Lango itself.  what.kind sub-types it (Cursor = "move the show here" | Lens | mode);
    //       what.to = the target locator (P2 Lies_resolve_locator-resolvable), the doc's `target`.
    //   OUT-COMPETE: a new Lango of the same kind on this terminal drops the prior — newest-wins
    //    (the same-Interest supersede); the cross-Interest race is the receiver's (req:Langoer).
    //   seq — a per-w monotonic ordering token (the counter rides off-snap on w.c.lango_seq;
    //    the value is SNAPPED on the Lango so it's observable).  It is what lets the receiver pick
    //     the globally-NEWEST Cursor across DIFFERENT carriers (out-compete only orders within one
    //      carrier).  Its base churns with boot cursor activity → munged in fixtures, the standard
    //       age/at pattern (Story.svelte story_matching), so structure stays the gate, value forgiven.
    //   READ BY req:Langoer (Lies_langoer_focus) — the receiver hat reads the observable Cursor
    //    Langos and derives focus from them.  Still ADDITIVE on the live path: lango only mints +
    //     records; Langoer only records its verdict (req:Langoer,focus), neither yet writes the
    //      session .sc.active (that cut is owner-supervised).  The carrier's per-tick walk steps
    //       over a %Lango (no funk.c.run), so the Lango itself never "runs".
    //   The /landing,req ack (the remote's reqyoncile-back) + yoink (a source cancel — likely a
    //    close-button on an Interest) are DESIGNED but unbuilt (Backbone_plan P3): wait until a
    //     consumer needs them, don't scaffold ahead.
    async lango(w: TheC, source: TheC, what: { kind: string, to?: string, cold?: boolean }): Promise<TheC> {
        const H = this as House
        const carrier = await H.Lies_ensure_waftica(w, source)
        for (const prior of carrier.o({ Lango: what.kind }) as TheC[]) carrier.drop(prior)   // out-compete
        const lango = carrier.i({ Lango: what.kind })
        if (what.to) lango.sc.to = what.to
        if (what.cold) lango.sc.cold = 1 as any                  // a resume/boot move (not deliberate): the
        else delete lango.sc.cold                                //  receiver ranks it BELOW any deliberate
        //                                                          Cursor regardless of seq (the boomerang rule)
        w.c.lango_seq = ((w.c.lango_seq as number) ?? 0) + 1     // global ordering source, off-snap
        lango.sc.seq  = w.c.lango_seq as any                     // snapped (observable); munged in fixtures
        lango.c.source = source                                  // origin backlink, off-snap
        carrier.bump_version()
        return lango
    },

    async Lies_pump_funkcions(w: TheC) {
        const funks = w.o({ Funkcions: 1 })[0] as TheC | undefined
        if (funks) await funks.do()
    },

    // ── Lies_reflect_storying — push a Storying cell's verdict on a run_result EVENT ──────
    //   storying_run computes a cell's light from the latest matching run_result.  It used to
    //    be PUMPED: the carrier re-ran it on every Credence cell each tick, every one re-deriving
    //     the same light and bailing unchanged — a poll faking an event.  Now it is event-driven —
    //      when a run_result lands (Lies_run_result_recv) we restamp only the cells bound to it,
    //       and on Waft load (Lies_instantiate_funkcions) we restamp that Waft's cells once from
    //        the results already present.  Same verdict logic, fired on the change, not on a clock.
    //   sel filters by the landed result (of_dock===path | of_Book===book); absent = every cell.
    //    Walks every Waft in w — a Storying cell nests under a What / a CreduFunk, anywhere on it.
    Lies_reflect_storying(w: TheC, sel?: { path?: string, book?: string }): void {
        const H = this as House
        const match = (f: TheC) =>
            !sel ? true
            : (sel.path != null && f.sc.of_dock === sel.path) ||
              (sel.book != null && f.sc.of_Book === sel.book)
        const walk = (host: TheC, c: TheC) => {
            for (const k of c.o() as TheC[]) {
                if (k.sc.Funkcion === 'Storying' && match(k)) {
                    storying_run(host, k, w)
                    // brand_new clears on the FIRST green verdict — a Book proven for the first time is no
                    //  longer new.  Fired here (the run_result EVENT), NOT in storying_run (off-snap) nor a
                    //   pump; delete is query+snap-safe.  Then PERSIST the vanish: enWaft+save the host Waft
                    //    so the ✦NEW stays gone across a reload instead of waiting on a hand-commit of the
                    //     board.  Lies_waft_save throttles per Waft path, so a board that greens several
                    //      cells in one pass collapses to a single write.
                    if (k.sc.brand_new && (k.c.verdict as any)?.phase === 'good') {
                        delete k.sc.brand_new; k.bump_version()
                        H.Lies_waft_save(w, host)
                    }
                }
                walk(host, k)
            }
        }
        for (const waft of w.o({ Waft: 1 }) as TheC[]) walk(waft, waft)
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
    //   The Aim watcher Funkcions are runtime fixtures (dontSnap, rebuilt each boot); the Waft itself
    //    PERSISTS — Waft:Cluster /%HostedIdentity is the durable registry of who's claimed/been seen.
    Lies_aim_setup(w: TheC): void {
        const H = this as House
        // Cluster is a FIRST-CLASS PERSISTED Waft — open it through the Good pipeline
        //  (LiesPersist loads wormhole/Cluster/toc.snap, or creates-from-nothing + registers
        //   its watch_c save), exactly like the GhostList|Keep.  Decoration (equip, the runtime
        //    watcher Funkcions, the self-claim) lands on the LOADED Waft in Lies_cluster_decorate —
        //     NOT a second oai'd copy: a directly-minted Cluster had no Good|watch_c, so the Good
        //      load's fresh empty place() clobbered its equip + /%HostedIdentity and no save ever
        //       fired (nothing reached disk).  One creation path, one watch_c, one home.
        H.i_elvisto(w, 'Lies_open_Waft', { path: 'Cluster' })
    },

    // ── Lies_cluster_decorate ────────────────────────────────────────────────────────
    //   Idempotent dressing of the LOADED Cluster Waft (per-tick from Lies_aim, once it
    //    arrives from the Good pipeline).  equip PERSISTS — a backstage fixture (no nib|focus),
    //     yet its /%HostedIdentity registry is durable.  The Runner|Relay watcher Funkcions are
    //      dontSnap runtime fixtures (rebuilt each boot, live state on .c) so only the registry
    //       persists, not their volatile transitions; minting one binds its run on the watch_c,
    //        and we kick instantiate at once so the Brink face reads funk.c.latest this tick.
    Lies_cluster_decorate(w: TheC, cluster: TheC): void {
        const H = this as House
        cluster.sc.equip ??= 'Cluster'
        let changed = false, minted = false
        // Runner was never a cluster singleton — it is a FACET of each %HostedIdentity (role:runner),
        //  and the Brink faces derive from the advertise roster (the %Runner liveness + the registry).
        //   The old autoviv'd Funkcion:Runner was just proto-%Aim noise; drop a stale one a prior build
        //    left (self-healing migration — the save then drops its snap line) and never re-mint it.
        //     Keep ONLY Relay: the relay carrier's own health, legitimately of-the-cluster.
        for (const stale of cluster.o({ Funkcion: 'Runner' }) as TheC[]) { cluster.drop(stale); changed = true }
        const f = cluster.oai({ Funkcion: 'Relay' }) as TheC
        if (!f.sc.dontSnap) { f.sc.dontSnap = 1; changed = minted = true }
        if (changed) cluster.bump_version()   // tracked so the drop|mint reaches watch_c → the snap
        if (minted)  void H.Lies_instantiate_funkcions(w, cluster)
    },

    // Lies_cluster_claim_self — name OURSELVES in the Waft:Cluster /%HostedIdentity registry, keyed by
    //  our prepub via Lies_self (ALL identity tiers — the ?I= %Identity OR the legacy stashed key — so an
    //   un-migrated tab still names itself).  We stamp our ROLE (editor|runner — "who's a runner") + friendly.
    //  `self` is NOT stored: the registry is ONE shared directory (everyone we know), so WHO-is-me is
    //   viewer-relative — it depends on which identity THIS tab runs as, and that changes (a stashed key,
    //    then an ?I=).  Readers derive it live (entry.HostedIdentity === Lies_self(w).prepub).  We also SCRUB
    //     any stale persisted `self` an older build left — the "everyone thinks they're self" mess (two tabs,
    //      or one tab across two identities, each writing self to the shared file).  Peers are NOT minted here:
    //       a Pier is keyed by the peer ROLE in the local mock (LiesLies:207 `pub: peer`), not a real prepub —
    //        mirroring Piers spawned the spurious HostedIdentity:runner|editor.  Real peers arrive via the
    //         advertise beacon (Lies_advertise_recv, real prepubs).
    Lies_cluster_claim_self(w: TheC): void {
        const H = this as House
        const cluster = w.o({ Waft: 'Cluster' })[0] as TheC | undefined
        if (!cluster) return
        let changed = false
        for (const hi of cluster.o({ HostedIdentity: 1 }) as TheC[]) if (hi.sc.self) { delete hi.sc.self; changed = true }
        const self = (H as any).Lies_self?.(w) as { prepub?: string } | undefined
        if (self?.prepub) {
            const me   = cluster.oai({ HostedIdentity: self.prepub }) as TheC   // oai mints+bumps on first sight
            const role = H.Lies_role(w)
            if (me.sc.role !== role) { me.sc.role = role; changed = true }
        }
        if (changed) cluster.bump_version()   // tracked: a raw delete|assign alone wouldn't fire watch_c → no save
    },

    // ── remote Wormhole (method:remoteWormhole) — the editor proxies its disk to begging runners ──
    //   A &remoteWormhole=1 runner has NO local tree (headless Chrome, DirectoryAccess off the table, OPFS
    //    illegal under a dev boot).  It BEGS the editor through the channel; the operator GRANTS it a
    //     signed %Grant (Funk/Grant.ts) off the editor's Rundar rack; the runner holds the grant and
    //      presents it back with every rw-op, which the editor re-verifies and serves against its OWN
    //       handle.  See spec/Cluster_spec.md "beg through the Brink".  All four verbs are additive
    //        Peeroleum frames (no .g spine change); bytes ride base64 for now (TODO: binary frame).

    // the held grant atom for THIS runner.  ONE durable home: local .stashed (per Chrome profile,
    //  readable on restart WITHOUT a working nav — the Waft:Cluster copy can't bootstrap, it loads
    //   THROUGH the very Wormhole the grant unlocks, and it can be wiped by an empty registry read).
    //    So .stashed is the sole authority; the registry is display-only and NEVER read back as a
    //     grant (that fallback was the second home whose wipe made the grant "disappear").
    Lies_wormhole_grant(w: TheC): GrantAtom | undefined {
        const H = this as House
        const held = (H.top_House()?.stashed as any)?.wormhole_grant as GrantAtom | undefined
        return held?.sign ? held : undefined
    },

    // ── the crypto VERDICT on a HELD grant — the "does it work or not" signal, computed LOCALLY ──
    //   Three-valued, no round-trip: absent (nothing held) · invalid (fails crypto — untrusted issuer
    //    or bad signature) · valid.  verify_grant checks the ed25519 sig for the claimed `by`;
    //     browserTrustedPubs asserts `by` is one of OUR editors (a valid sig from a stranger is not a
    //      grant WE honour — though the editor also serves only grants it signed itself, so this is belt).
    //   DELIBERATELY IDENTITY-STABLE: it does NOT re-check `for` (which runner it was granted TO).  That
    //    belongs at ACCEPTANCE (grant_offer_recv), ONCE.  Re-litigating it here every heartbeat DISCARDED
    //     a perfectly good grant the instant Lies_self/Clustation_self blipped to a different|undefined
    //      prepub — the "begs forever, never stores" flap.  Reconcile must only ask "is the grant I hold
    //       still cryptographically real", never "who am I this millisecond".
    async Lies_wormhole_verdict(_w: TheC, atom: GrantAtom | undefined): Promise<{ status: 'absent' | 'invalid' | 'valid', reason?: string }> {
        if (!atom?.sign) return { status: 'absent' }
        const trusted = browserTrustedPubs()
        if (trusted.length && !trusted.includes(atom.by))
            return { status: 'invalid', reason: `issuer ${String(atom.by).slice(0, 8)}… is not a trusted editor` }
        try { await verify_grant(atom) } catch { return { status: 'invalid', reason: 'bad signature' } }
        return { status: 'valid' }
    },

    // ── stamp the crypto verdict where the UI + the acquire loop read it — honestly ──────────────
    //   Two axes, never merged (owner call): wormhole_grant_status is the CRYPTO axis (absent|invalid|
    //    valid); liveness (channel up? ops landing?) stays separate on the badge.  wormhole_state is
    //     derived DOWNSTREAM of the verdict — 'ready' ONLY for a cryptographically valid grant, so the
    //      badge can never say "granted" over a dead grant.  Idempotent: writes + a version bump only on
    //       a real change, with a one-line console trail on transitions (the signal, logged somewhere).
    Lies_wormhole_status_set(w: TheC, status: 'absent' | 'invalid' | 'valid', reason?: string): void {
        const prev = w.c.wormhole_grant_status as string | undefined
        if (prev === status && w.c.wormhole_grant_reason === reason) return
        w.c.wormhole_grant_status = status
        w.c.wormhole_grant_reason = reason
        w.c.wormhole_state = status === 'valid' ? 'ready' : 'begging'   // honest: 'ready' ⇒ crypto-valid, full stop
        w.bump_version()
        if (prev && prev !== status)
            console.log(`🛰️ remoteWormhole grant: ${prev} → ${status}${reason ? ` (${reason})` : ''}`)
    },

    // EDITOR: mint+sign a remoteWormhole %Grant for a runner (by its roster prepub) and offer it.
    //  Triggered from the Rundar rack's per-runner grant control.  by === our cluster pub, so our own
    //   serve later trusts it.  mode 'rw' (default) | 'ro'.  No `until` — grants are infinite by design.
    async Lies_grant_wormhole(w: TheC, runner_prepub: string, mode: string = 'rw'): Promise<void> {
        const H = this as House
        const idento = H.Lies_cluster_idento(w)
        if (!idento) { (H as any).tlog?.('🛰️ cannot grant remoteWormhole — editor has no cluster key (🪪 hatch)'); return }
        const row = w.o({ Runner: runner_prepub })[0] as TheC | undefined
        // Grant against the runner's FULL pub when its beacon advertised one (Organ 4 part 3): a full-pub
        //  `for` is cryptographically verifiable + form-matches `by`, and routing still derives
        //   prepubOf(for) at send.  Fall back to the prepub for an OLD runner (no pub on its beacon) — the
        //    runner's for-check tolerates both, so this is a clean feature-detect, no fleet-wide flag day.
        const grantee = (row?.sc.pub as string) || runner_prepub
        const atom = await mint_grant(idento, grantee, 'remoteWormhole', { mode })
        // Offer ADDRESSED to the grantee (we hold its prepub — it's the roster key): a role-broadcast
        //  offer is ONE relay slot, so with two runners the wrong one eats it and "grant" silently does
        //   nothing for the runner you clicked (roles-divide/addresses-deliver).  Broadcast only as the
        //    no-Pier fallback (channel down mid-click); the runner's `for`-filter still guards either way.
        if ((H as any).Lies_runner_pier(w, runner_prepub))
            (H as any).Peeroleum_send_to(w, runner_prepub, 'grant_offer', { grant: atom })
        else
            H.Peeroleum_send_consumer(w, 'grant_offer', { grant: atom })
        w.oai({ Runner: runner_prepub }, { granted_wormhole: 1 })      // reflect on the rack (dontSnap roster row)
        if (row?.sc.begs_wormhole) { delete row.sc.begs_wormhole; w.bump_version() }
    },

    // RUNNER: receive an offered %Grant — verify it crypto-first, then persist it to the ONE durable
    //  home (.stashed) and reconcile.  We never durably store a grant that doesn't verify (no forged
    //   atom in our store), and we no longer write a registry copy — .stashed is the sole authority;
    //    Lies_wormhole_reconcile re-derives everything (badge, nav, re-beg) from it each heartbeat.
    async Lies_grant_offer_recv(w: TheC, frame: any): Promise<void> {
        const H = this as House
        const atom = frame?.grant as GrantAtom | undefined
        if (!atom?.sign) return
        // ADDRESSED-TO-US filter — the ONE place `for` is checked (grant_offer is a role-broadcast).  `for`
        //  is now the grantee's FULL pub (new editor) or its prepub (old); prepubOf collapses both to our
        //   routing address, which Lies_self derives from the same signing key the relay bound us under —
        //    so ONE comparison covers every tier (Organ 4: the old "tolerate both Clustation/legacy tiers"
        //     union is retired).  Done HERE, once, not in the per-heartbeat verdict (see Lies_wormhole_verdict).
        const me = (H as any).Lies_self?.(w)?.prepub as string | undefined
        if (me && atom.for && prepubOf(atom.for) !== me) return          // a grant for a different runner
        const { status, reason } = await H.Lies_wormhole_verdict(w, atom)   // issuer + signature
        if (status !== 'valid') { if (status === 'invalid') (H as any).tlog?.(`🛰️⚠ ignored offered grant — ${reason}`); return }
        const top = H.top_House()
        if (top?.stashed) (top.stashed as any).wormhole_grant = atom     // durable, survives restart
        else w.c.pending_grant = atom                                    // .stashed not loaded yet — reconcile flushes it
        void H.Lies_remote_wormhole_reconcile(w)                         // verify+install now (don't wait a heartbeat)
    },

    // EDITOR: a runner begs for access — flag its roster row so the rack offers a grant control.
    Lies_wormhole_beg_recv(w: TheC, frame: any): void {
        const from = String(frame?.from ?? '').trim()   // the beacon prepub (body), matching advertise_recv
        if (from) w.oai({ Runner: from }, { begs_wormhole: 1 })
    },

    // Lies_send_binary_to — an ADDRESSED binary frame: bytes ride frame.buffer (the [header]\n[raw buffer]
    //  wire, body_hash-integrity — NO base64), app meta + corr ride the header.  Mirrors the spine's own
    //   addressed emit (Peeroleum_send_to) + a binary frame (Peeroleum_body_digest + Pier_next_seq, the
    //    test_binary pattern).  to = the recipient's prepub; needs the post-promote spine (send_to era).
    async Lies_send_binary_to(w: TheC, to: string, type: string, meta: Record<string, unknown>, buf: ArrayBuffer): Promise<boolean> {
        const H = this as House
        const pier = H.Lies_runner_pier(w, to)
        if (!pier) return false
        const me    = (w.o({ Peering: 1 })[0] as TheC | undefined)?.sc.name
        const bytes = buf instanceof Uint8Array ? buf : new Uint8Array(buf)
        const body_hash = await (H as any).Peeroleum_body_digest(bytes)
        const seq = (H as any).Pier_next_seq(pier)
        ;(H as any).Peeroleum_send(w, { header: { type, from: me, to, seq, body_hash, body_len: bytes.length, ...meta }, buffer: bytes })
        return true
    },

    // Lies_send_binary_consumer — the RUNNER→editor CONSUMER twin of Lies_send_binary_to.  The runner has
    //  ONE consumer Pier (pointed at the editor, the same one wormhole_req/grant_beg ride), so there is no
    //   `to` to choose — send over pier[0], to = its pub.  Bytes ride frame.buffer (raw, body_hash-integrity,
    //    OFF-snap); app meta (corr, grant, op, dir_path, filename) rides the header, exactly as the editor's
    //     addressed binary reply does.  This is the write direction the JSON consumer body can't carry without
    //      a base64 tax + a bloated snapped outbox emit — used by RemoteWormholeNav.bin_write.
    //  Returns the emit's seq (like Peeroleum_send_consumer) so the caller can watch its %outbox/emit go
    //   %acked — the nav's ack-gated re-emit reads it; undefined if there's no Pier yet.
    async Lies_send_binary_consumer(w: TheC, type: string, meta: Record<string, unknown>, buf: ArrayBuffer | Uint8Array): Promise<number | undefined> {
        const H = this as House
        const peering = w.o({ Peering: 1 })[0] as TheC | undefined
        const pier    = peering?.o({ Pier: 1 })[0] as TheC | undefined
        if (!peering || !pier) return undefined
        const me    = peering.sc.name
        const to    = (pier.sc as any).pub
        const bytes = buf instanceof Uint8Array ? buf : new Uint8Array(buf)
        const body_hash = await (H as any).Peeroleum_body_digest(bytes)
        const seq = (H as any).Pier_next_seq(pier) as number
        ;(H as any).Peeroleum_send(w, { header: { type, from: me, to, seq, body_hash, body_len: bytes.length, ...meta }, buffer: bytes })
        return seq
    },

    // EDITOR: serve one rw-op for a runner — verify the presented grant, then run it against OUR nav.
    //  Replies are ADDRESSED to the grantee (claim.for) via the post-promote send_to; bytes ride a binary
    //   frame (Lies_send_binary_to), never base64.  Only the no-grantee-pub degenerate falls back to b64.
    async Lies_wormhole_req_recv(w: TheC, frame: any): Promise<void> {
        const H = this as House
        // A JSON wormhole_req carries its app meta at the top level (Peeroleum_send_consumer Object.assigns
        //  the body beside `header`).  A BINARY req (op:'bin_write') carries the bytes on frame.buffer and
        //   its meta on the HEADER instead (Lies_send_binary_consumer) — so read either, header as the
        //    fallback.  One handler then serves both shapes; only the bin_write branch touches frame.buffer.
        const hdr = frame?.header || {}
        const grant    = (frame?.grant ?? hdr.grant) as GrantAtom | undefined
        const corr     = frame?.corr ?? hdr.corr
        const op       = frame?.op ?? hdr.op
        const dir_path = frame?.dir_path ?? hdr.dir_path
        const filename = frame?.filename ?? hdr.filename
        // WHO asked — the reply address, in the roles-divide/ADDRESSES-DELIVER model (Cluster_spec
        //  §3.2a/b).  Best: the corr's leading segment IS the asker's LIVE prepub (RemoteWormholeNav
        //   mints corr = `${Lies_self.prepub}-${ts}-${n}`) — the hello-bound identity of the exact tab
        //    asking NOW, bridge-routable, immune to an Id switch since the grant was minted.  Fallback:
        //     prepubOf(grant.for) (the minted-for identity; prepubOf is a pure prefix so it handles a
        //      full-pub or prefix `for` alike).  NEVER the role slot: `to:"runner"` is ONE relay
        //       binding, and with two runners the OTHER one silently eats every reply (the 2026-07-05
        //        starvation: bridge runner wedged at `begun`, all 286 replies delivered to the local
        //         role-thief as unknown-corr drops).
        const corr0 = String(corr ?? '').split('-')[0]
        const asker = /^[0-9a-f]{16}$/.test(corr0) ? corr0 : undefined
        const to = asker ?? (grant?.for ? prepubOf(grant.for as string) : undefined)
        const cc = String(corr ?? '').slice(-6)
        console.log(`🛰️← wormhole_req op=${op} ${[dir_path, filename].filter(Boolean).join('/')} corr=…${cc} for=${String(to ?? '?').slice(0, 8)}`)   // DIAG: did the serve handler fire?
        // Reply ADDRESSED to the asker (`to:<asker prepub>`, corr-matched) — never the role slot.  The
        //  historical consumer-broadcast here was a workaround for the pre-collapse tier drift ("to:claim.for
        //   routed to NOBODY"), and it leaned on an assumption the relay never honoured: that a role frame
        //    fans out to ALL runner sockets ("other runners drop an unknown corr").  The relay binds ONE
        //     socket per addr — so the moment a second runner bound `runner` locally, it ate every reply and
        //      the bridge runner starved at `begun` (2026-07-05).  Addressed delivery is the become_book
        //       path, proven across the bridge.  Broadcast survives ONLY as the identity-less-asker fallback
        //        (an old runner minting 'r-…' corrs on a single-runner grid).
        const replyJSON = (body: Record<string, unknown>) => {
            console.log(`🛰️→ wormhole_reply ${asker ? `@${asker.slice(0, 8)}` : 'broadcast'} corr=…${cc} ${body.error ? `ERROR ${body.error}` : body.not_found ? 'not_found' : body.ok ? 'ok' : body.entries ? `${(body.entries as any[]).length} entries` : `content ${String(body.content ?? '').length}c`}`)   // DIAG: what did we answer, and to whom?
            if (asker && (H as any).Lies_runner_pier(w, asker))
                return (H as any).Peeroleum_send_to(w, asker, 'wormhole_reply', { corr, ...body })
            return H.Peeroleum_send_consumer(w, 'wormhole_reply', { corr, ...body })
        }
        // Binary replies ride the same address (`to` = asker-first, grant-derived fallback) on the raw-
        //  bytes frame.  With the asker's LIVE prepub off the corr, JSON and binary replies now route
        //   identically — the H1 residue (a frozen minted-for atom addressing the binary) is gone; the
        //    only remaining exposure is an identity-less asker ('r-…' corr) whose grant.for is ALSO
        //     stale — a peer that can't happen post-collapse (Lies_self always derives).
        const replyBIN = (meta: Record<string, unknown>, buffer: ArrayBuffer) =>
            to ? H.Lies_send_binary_to(w, to, 'wormhole_reply', { corr, ...meta }, buffer)
               : replyJSON({ error: 'grant has no for — cannot address binary reply' })
        try {
            const idento = H.Lies_cluster_idento(w)
            if (!idento) return void replyJSON({ error: 'editor has no cluster key' })
            const claim = await verify_grant(grant as GrantAtom)        // throws on a bad/forged sig
            if (claim.to !== 'remoteWormhole') return void replyJSON({ error: `grant is for ${claim.to}` })
            if (claim.by !== idento.pub)        return void replyJSON({ error: 'grant not issued by this editor' })
            // TODO: revocation-corpus check (a signed %NotGrant for {by, for, remoteWormhole})
            const nav = H.top_House().o({ A: 'Wormhole' })[0]?.c.nav as any
            if (!nav) return void replyJSON({ error: 'editor wormhole nav not ready' })
            if (op === 'read') {
                const c = await nav.read_file(dir_path, filename)
                replyJSON(c != null ? { content: c } : { not_found: true })
            } else if (op === 'bin') {
                const b = nav.bin_read ? await nav.bin_read(dir_path, filename) : null
                b ? replyBIN({ bytes: b.byteLength }, b) : replyJSON({ not_found: true })
            } else if (op === 'read_range') {
                const off = Number(frame.offset ?? 0)
                const len = frame.len ? Number(frame.len) : undefined
                const r = nav.read_range ? await nav.read_range(dir_path, filename, off, len) : null
                r ? replyBIN({ size: String(r.size) }, r.buffer) : replyJSON({ not_found: true })
            } else if (op === 'list') {
                const dl = await nav.dir(...String(dir_path).split('/').filter(Boolean))
                if (!dl) replyJSON({ not_found: true })
                else {
                    await dl.expand()
                    replyJSON({ entries: [
                        ...dl.directories.map((d: any) => ({ name: d.name, is_dir: true })),
                        ...dl.files.map((f: any) => ({ name: f.name, is_dir: false })),
                    ] })
                }
            } else if (op === 'write') {
                if (claim.mode === 'ro') return void replyJSON({ error: 'grant is read-only' })
                await nav.write_file(dir_path, filename, frame.data)
                replyJSON({ ok: true })
            } else if (op === 'bin_write') {
                // the binary write direction: the runner sent a raw frame (frame.buffer), we lay it on OUR
                //  disk via the same nav.bin_write a local generator would use.  Reply is a tiny JSON {ok}.
                if (claim.mode === 'ro') return void replyJSON({ error: 'grant is read-only' })
                if (!nav.bin_write)      return void replyJSON({ error: 'editor nav cannot bin_write' })
                const buf = frame.buffer
                if (buf == null)         return void replyJSON({ error: 'bin_write: frame carried no buffer' })
                const bytes = buf instanceof Uint8Array ? buf : new Uint8Array(buf)
                await nav.bin_write(dir_path, filename, bytes)
                replyJSON({ ok: true })
            } else if (op === 'bin_append') {
                // bin_write's STREAMING twin over the wire: the runner streams a big asset chunk-at-a-time
                //  (Radio_todo §10.2 #1).  DELEGATE to OUR nav.bin_append when it has one (FSA/OPFS — they
                //   position a write at EOF, so the editor never assembles the whole file).  When our own nav
                //    lacks bin_append (an FSA build older than the append contract), keep the WIRE contract
                //     honest by doing the append SERVER-side: bin_read the current bytes, concat the chunk,
                //      bin_write the whole — slower and memory-heavy, but correct, so the client can trust
                //       bin_append against any editor that speaks the op.  A nav that can't even bin_write is
                //        a real refusal (no honest append possible).
                if (claim.mode === 'ro') return void replyJSON({ error: 'grant is read-only' })
                if (!nav.bin_write)      return void replyJSON({ error: 'editor nav cannot bin_write' })
                const buf = frame.buffer
                if (buf == null)         return void replyJSON({ error: 'bin_append: frame carried no buffer' })
                const bytes = buf instanceof Uint8Array ? buf : new Uint8Array(buf)
                if (nav.bin_append) {
                    await nav.bin_append(dir_path, filename, bytes)
                } else {
                    // read+concat+bin_write fallback: absent file ⇒ read null ⇒ append from 0 (the create).
                    const prev = nav.bin_read ? await nav.bin_read(dir_path, filename) : null
                    const head = prev ? new Uint8Array(prev) : new Uint8Array(0)
                    const whole = new Uint8Array(head.byteLength + bytes.byteLength)
                    whole.set(head); whole.set(bytes, head.byteLength)
                    await nav.bin_write(dir_path, filename, whole)
                }
                replyJSON({ ok: true })
            } else replyJSON({ error: `unknown op ${op}` })
        } catch (e) { replyJSON({ error: String(e) }) }
    },

    // RUNNER: a reply landed — hand it to the pending request on our remote nav (matched by corr).  A
    //  binary reply carries corr in the HEADER (app meta rides there beside body_hash); a JSON reply on
    //   the body — read both.  The whole frame (incl. frame.buffer) goes to the nav, which unpacks it.
    Lies_wormhole_reply_recv(w: TheC, frame: any): void {
        const H = this as House
        const nav = H.top_House().o({ A: 'Wormhole' })[0]?.c.nav as any
        const corr = frame?.corr ?? frame?.header?.corr
        if (nav?.is_remote && corr) nav._resolve(corr, frame)
    },

    // RUNNER: wire the method:remoteWormhole nav onto A:Wormhole.  Idempotent.  The grant is assumed
    //  already crypto-VALID (the reconcile verifies before calling here) — install no longer sets
    //   wormhole_state (that's the verdict's job, via Lies_wormhole_status_set), so state can never
    //    drift from crypto truth.
    Lies_remote_wormhole_install(w: TheC): boolean {
        const H = this as House
        const A = H.top_House().o({ A: 'Wormhole' })[0] as TheC | undefined
        if (!A) return false
        // PREFER a granted local share.  A real directory handle (A.c.DL, set by DirectoryOpener when
        //  the operator opens a share) is strictly MORE capable than the editor proxy — direct disk, the
        //   FULL nav contract (incl. bin_write, which RemoteWormholeNav lacks), lower latency.  So if a
        //    local share is open on this &remoteWormhole=1 tab, stand the proxy DOWN: tear any remote nav
        //     so the Wormhole worker rebuilds WormholeNav(DL) over the local handle, and never re-install
        //      the proxy on top of it.  Without this the heartbeat reconcile clobbered a just-granted local
        //       nav every tick — "granting FSA on a remoteWormhole tab did nothing" (Robustness_plan Organ 5).
        if (A.c.DL) {
            if ((A.c.nav as any)?.is_remote) { A.c.nav = undefined; A.bump_version(); H.main(true) }
            return true   // local share owns the nav; WormholeNav(DL) (re)builds in the Wormhole worker
        }
        if ((A.c.nav as any)?.is_remote) return true
        A.c.nav = new RemoteWormholeNav(H, w, () => H.Lies_wormhole_grant(w))
        H.main(true)                                                  // nav appeared — re-pump parked reads
        return true
    },

    // RUNNER: tear the remote nav back down (a grant died / was refused).  Reads then PARK on a missing
    //  nav — the same pre-grant gum-up — instead of a zombie nav presenting a dead grant into 20s timeouts.
    Lies_remote_wormhole_uninstall(w: TheC): void {
        const H = this as House
        const A = H.top_House().o({ A: 'Wormhole' })[0] as TheC | undefined
        if (A && (A.c.nav as any)?.is_remote) { A.c.nav = undefined; A.bump_version() }
    },

    // RUNNER: the acquire RECONCILER, pumped from Lies_aim each heartbeat while &remoteWormhole=1.
    //  ONE honest state machine off the crypto verdict — no sticky "installed once" flag:
    //    valid   → nav installed, state 'ready'.
    //    absent  → nav torn down, state 'begging', beg the editor (throttled).
    //    invalid → nav torn down, the forged/stale grant DISCARDED from .stashed (owner call: refuse +
    //               re-beg, don't keep presenting it), state 'begging', beg for a fresh one.
    //  So a wiped/expired/foreign grant self-heals: it flips the badge back, drops the nav, re-begs, and
    //   the operator's next grant lands durably — no reload.  Async (verify is ed25519); a re-entrancy
    //    guard + a verify-cache (skip re-verifying an unchanged atom) keep it cheap on the heartbeat.
    async Lies_remote_wormhole_reconcile(w: TheC): Promise<void> {
        const H = this as House
        if (w.c.wh_reconciling) return
        w.c.wh_reconciling = true
        try {
            // flush a grant that arrived before .stashed had loaded
            const top = H.top_House()

            // A granted LOCAL share supersedes the whole remote dance — prefer it and skip begging.
            //  install() tears any remote nav so WormholeNav(DL) rebuilds; the badge says so honestly
            //   ('local' — a THIRD crypto-axis value beside absent|invalid|valid) rather than "begging"
            //    while the local share quietly works (Robustness_plan Organ 5, nav precedence).
            const A = top?.o({ A: 'Wormhole' })[0] as TheC | undefined
            if (A?.c.DL) {
                H.Lies_remote_wormhole_install(w)
                if (w.c.wormhole_grant_status !== 'local') {
                    w.c.wormhole_grant_status = 'local'
                    w.c.wormhole_grant_reason = 'local share open — remote proxy stood down'
                    w.c.wormhole_state = 'ready'
                    w.bump_version()
                    console.log('🛰️→📁 remoteWormhole: local share open — preferring it over the editor proxy')
                }
                return
            }

            const pending = w.c.pending_grant as GrantAtom | undefined
            if (pending?.sign && top?.stashed && !(top.stashed as any).wormhole_grant) {
                (top.stashed as any).wormhole_grant = pending; delete w.c.pending_grant
            }
            const atom = H.Lies_wormhole_grant(w)

            // verify-cache: an unchanged, already-valid atom skips the re-verify — just keep the nav wired.
            if (atom && w.c.wh_verified_sign === atom.sign && w.c.wormhole_grant_status === 'valid') {
                H.Lies_remote_wormhole_install(w)
                return
            }
            const { status, reason } = await H.Lies_wormhole_verdict(w, atom)
            w.c.wh_verified_sign = atom?.sign
            H.Lies_wormhole_status_set(w, status, reason)

            if (status === 'valid') { H.Lies_remote_wormhole_install(w); return }

            if (status === 'invalid') {
                if ((top?.stashed as any)?.wormhole_grant) delete (top!.stashed as any).wormhole_grant
                delete w.c.wh_verified_sign
                console.warn(`🛰️⚠ discarding INVALID remoteWormhole grant — ${reason}; re-begging`)
            }
            H.Lies_remote_wormhole_uninstall(w)                      // no valid grant → park reads, don't zombie-serve

            if (!H.Lies_channel_live(w)) return
            const now = Date.now()
            if (now - Number(w.c.wormhole_beg_at ?? 0) < 4000) return
            w.c.wormhole_beg_at = now
            // carry our prepub in the BODY (as the advertise beacon does) so the editor flags the SAME
            //  %Runner roster row the rack renders — keyed on the beacon prepub, not header.from.
            const me = (H as any).Clustation_self?.()?.prepub ?? (H as any).Lies_self?.(w)?.prepub
            H.Peeroleum_send_consumer(w, 'wormhole_beg', { want: 'remoteWormhole', from: me })
        } finally {
            w.c.wh_reconciling = false
        }
    },

    //   Hoist (or retire) the cluster Brinks by role — called every heartbeat.  editor|runner
    //    means a remote relationship exists, so the endpoint faces are worth showing; otherwise
    //     they're dropped.  Each Brink backlinks its w (the monitored Lies); the Relay face also
    //      carries its funk cell (the carrier-health watcher's funk.c.latest), while the Runner
    //       faces read state straight off w|the roster — no singleton funk.  Setup runs once (guarded).
    Lies_aim(w: TheC): void {
        const H = this as any
        if (!w.c.aim_setup) { w.c.aim_setup = true; void H.Lies_aim_setup(w) }
        const role = H.Lies_role(w)
        const on = role === 'editor' || role === 'runner'
        const cluster = w.o({ Waft: 'Cluster' })[0] as TheC | undefined
        const bag = H.Lies_lens_bag() as TheC
        // dress + self-claim the LOADED Cluster (both idempotent, both no-op until it arrives from
        //  the Good pipeline).  equip is stamped here so it survives the place() that the Good load
        //   does; no longer seeded minimised — an equip registry shows its /* (the %HostedIdentity
        //    children, who we + the cluster claim to be) like any Waft.
        if (cluster) { H.Lies_cluster_decorate(w, cluster); H.Lies_cluster_claim_self(w); if (role === 'editor') H.Lies_runner_roster(w, cluster) }

        // &remoteWormhole=1 runner: reconcile the remote-Wormhole grant (verify → install | re-beg) HERE,
        //  where the channel + .stashed live; DirectoryOpener only reflects A.c.nav.  Honest every tick —
        //   a grant that dies flips the badge back and re-begs, no sticky "granted".  Fire-and-forget (async).
        if (role === 'runner' && H.top_House().c.remote_wormhole) void H.Lies_remote_wormhole_reconcile(w)

        // Relay — a single face, both roles (the relay carrier's own health).
        if (on) {
            if (!bag.oa({ Lens: 'Brink', of_Funkcion: 'Relay' })) {
                const funk = cluster?.o({ Funkcion: 'Relay' })[0] as TheC | undefined
                const lens = H.Lies_lens_suggest('Brink', 'Relay', { altitude: 25 }, funk) as TheC
                lens.c.w = w
            }
        } else H.Lies_lens_dismiss('Brink', 'Relay')

        // Sound — the "tap for sound" audio-gate beg, on BOTH roles' Brinks: an AudioContext grant is
        //  per-TAB (the resume must ride a gesture IN the tab that owns the context), so each tab can
        //   only beg for ITSELF — the editor for its own audio (the central control panel, where the
        //    human sits), and a runner for its needAC runs (its old surface, the Otro fullscreen gate,
        //     is suppressed under dev boots — without this beg a blocked runner has NO grant surface
        //      and needAC just times out).  Self-gates: the face stays invisible until a gat fires
        //       AudioContext_wanted.  altitude 5 = leftmost/interior-most in the mini row.
        if (role === 'editor' || role === 'runner') {
            if (!bag.oa({ Lens: 'Brink', of_Funkcion: 'Sound' }))
                H.Lies_lens_suggest('Brink', 'Sound', { altitude: 5 })
        } else H.Lies_lens_dismiss('Brink', 'Sound')

        // Rundar — the runner RADAR (renamed from Runner: it started point-to-point, then we sludged the
        //  fleet rack into it; the new name carries the multiplicity).  TWO modes off ONE kind:
        //   • runner role: one single-pair face →EDITOR (the one peer it reports to), no rack.
        //   • editor role: ONE rack face reading the whole snapped w:Lies/%Runner roster (1:1 with the
        //      %HostedIdentity registry) — every runner the editor can dispatch to, each with its identity.
        //   Self-migration: any legacy of_Funkcion:'Runner' lens a prior build left is dropped here so the
        //    old name never lingers beside the new (Lies_aim drops|remints every tick, so a reload isn't
        //     even needed).
        for (const l of bag.o({ Lens: 'Brink', of_Funkcion: 'Runner' }) as TheC[]) { bag.drop(l); bag.bump_version() }   // legacy name → gone
        const allRundar = () => bag.o({ Lens: 'Brink', of_Funkcion: 'Rundar' }) as TheC[]
        if (role === 'runner') {
            for (const l of allRundar()) if (l.sc.pub || l.sc.rack) { bag.drop(l); bag.bump_version() }   // editor crumbs, if any
            if (!allRundar().some(l => !l.sc.pub && !l.sc.rack)) {
                const lens = H.Lies_lens_suggest('Brink', 'Rundar', { altitude: 20 }) as TheC   // no singleton funk
                lens.c.w = w
            }
        } else if (role === 'editor') {
            // the editor ALWAYS shows the RUNNER rack — the roster it dispatches to — even when empty.
            //  Never the single-pair →RUNNER face: that's a runner's view of ITS editor, meaningless on
            //   an editor (the "editor →RUNNER" banality).  rack:'all' is a STRING discriminator — a
            //    numeric 1 here is a query wildcard that never persisted as a literal, so the face read
            //     lens.sc.rack as absent and fell through to the single-pair face.  A connected
            //      no-identity ?B= runner (can't advertise a pub) still shows: the rack folds in the live
            //       single-pair peer as an anonymous row.
            for (const l of allRundar()) if (l.sc.rack !== 'all') { bag.drop(l); bag.bump_version() }   // drop legacy single + per-pub
            let lens = (bag.o({ Lens: 'Brink', of_Funkcion: 'Rundar', rack: 'all' })[0]) as TheC | undefined
            if (!lens) { lens = bag.oai({ Lens: 'Brink', of_Funkcion: 'Rundar', rack: 'all' }, { altitude: 20 }) as TheC; bag.bump_version() }
            lens.c.w = w                                                // the rack reads the whole %Runner roster off w itself
        } else for (const l of allRundar()) { bag.drop(l); bag.bump_version() }
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
            funk.c.run = kind.run                                  // bind only — the carrier's walk runs it
        }
        await H.Lies_ensure_waftica(w, waft)                       // one carrier per Waft (was: one req per funk)
        // Storying cells are NOT pumped (event-driven); seed each one's light once, now, from any
        //  run_result already present — a freshly-loaded (or re-edited) board lights up immediately
        //   instead of waiting on the next run.  Live updates come via Lies_reflect_storying on recv.
        for (const funk of all) if (funk.sc.Funkcion === 'Storying') storying_run(waft, funk, w)
    },

    // ── GhostList_funkcion ──────────────────────────────────────────────────────
    //   Install the GhostList's dirlist behaviour on funk.c.run (off-snap), riding the
    //   Waft directly (Waft/Funkcion:dirlist — no Seem), and ensure its Waft's Waftica
    //   carrier in Lies/Funkcions.  Idempotent — installs|ensures once.
    async GhostList_funkcion(gl: TheC, w: TheC): Promise<TheC> {
        const funk = gl.oai({ Funkcion: 'dirlist' })
        funk.sc.interval_ms ??= 8000
        funk.sc.main        ??= 1   // it is the GhostList Waft's main Funkcion — its FACE (DocGhostList) is the Waft body

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
                    // a mid-write atomic-rename artifact (NAME.EXT.tmp.PID.HEX) is never a Doc —
                    //  skipping it here (not just pruning later) means it never even flashes in
                    if (/\.tmp\.\d+\.[0-9a-f]+$/i.test(e.name)) continue
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
                // prune the goners — a file|dir that left the listing leaves the list (a deleted
                //  spec was lingering as a phantom Doc, feeding the search index dead paths).
                //   The dirlist REFLECTS the disk; it is not a ledger.
                const on_disk = new Set(entries.map(e => `${dir}/${e.name}`))
                for (const d of group.o({ Doc: 1 }) as TheC[])
                    if (!on_disk.has(d.sc.Doc as string)) { group.drop(d); changed = true }
                for (const s of group.o({ sub: 1 }) as TheC[])
                    if (!on_disk.has(s.sc.sub as string)) { group.drop(s); changed = true }
            }
            if (!pending) {
                funk.sc.walked_at = now
                if (!host.sc.seeded) host.sc.seeded = now   // first full walk = baseline; nothing glows
                if (changed) host.bump_version()            // bump|render only on real change
            }
        }
        await H.Lies_ensure_waftica(w, gl)   // the GhostList Waft's carrier walks + runs this dirlist
        return funk
    },

//#endregion
//#region WaftMap — the Plank grouping model (pure read; DocWaftMap + Book:LakeWaftMap share it)
//
//  The corpus grouped by ATTENTION.  Every Known|Loaded Waft becomes either a BURST row — the
//   interesting ones: the foreground, any cursor-TOUCHED Waft (its carrier holds a %Lango,Cursor,
//    the global cursor feed every resolved want mints), or one the UI forces (scrolled-to |
//     pinned) — showing the cursor's shaft of light: the nearest ≤3 Docs as titled chips, the
//      rest one +N tail; or it packs two-by-two into a STACK of non-interesting Wafts.
//  Above the rows rides the crumb HARVEST — each touched Waft's cursor Doc in discovery order
//   (carrier Lango seq), the foreground's first: the Waft** path and its breadcrumbs.
//  A chip BUDGET decides bursting-at-the-seams: over budget, non-fg burst rows demote (light
//   off, count on) bottom-up until it fits; still over ⇒ the seams flag stands and the UI shows
//    the strain.  All shallow reads (no Point descent) — $derived-able off the version bumps the
//     model touches internally, and deterministic inside a Story Run (no Keep, no clock).

    // ── Lies_waftmap_title — a Doc|Waft path as a nice horizontal title ──────────────────────
    //   The last LETTERED segment, not the bare tail — Ting/2026-07-02/160434 is "Ting", not
    //    "160434" (the numbery date|time bits are the address, not the name — InterestStrip's
    //     tail_name rule).
    Lies_waftmap_title(path: string): string {
        const segs = (path ?? '').split('/').filter(Boolean)
        let base = segs[segs.length - 1] ?? '·'
        for (let i = segs.length - 1; i >= 0; i--) if (/[a-z]/i.test(segs[i])) { base = segs[i]; break }
        return base.replace(/\.[A-Za-z0-9]+$/, '').replace(/[_\-]+/g, ' ')
    },

    // ── Lies_waftmap_model — the one grouping pass ───────────────────────────────────────────
    //   opts.budget — the chip budget the Plank can hold before it is bursting at the seams.
    Lies_waftmap_model(w: TheC, opts?: { budget?: number }) {
        const H      = this as House
        const budget = opts?.budget ?? 18
        void w.version

        // Attention — Languinio Interests: the fg Waft + the hot set (ordering|styling only)
        const ave       = (H as any).ave ?? H.top_House().ave
        const languinio = ave?.ob({ Languinio: 1 })[0] as TheC | undefined
        void languinio?.vers
        const fg  = languinio?.ob({ ActiveInterest: 1 })[0]?.sc.waft as string | undefined
        const hot = new Set<string>()
        for (const it of (languinio?.ob({ Interest: 1 }) ?? []) as TheC[])
            if (it.sc.presence === 'active' && it.sc.state !== 'gone' && it.sc.waft) hot.add(it.sc.waft as string)

        // The live cursor (%Spotlight) + the per-Waft touch memory (carrier %Lango,Cursor)
        const spot_src  = w.o({ examining: 1 })[0]?.o({ Spotlight: 1 })[0]?.sc.src as TheC | undefined
        const spot_waft = spot_src ? H.waft_key_of(spot_src) as string | undefined : undefined
        const funks     = w.o({ Funkcions: 1 })[0] as TheC | undefined
        void funks?.version
        const touch = new Map<string, { to: string | undefined, seq: number }>()
        for (const carrier of (funks?.o({ req: 'Waftica' }) ?? []) as TheC[]) {
            const cur = carrier.o({ Lango: 'Cursor' })[0] as TheC | undefined
            if (cur) touch.set(carrier.sc.waft as string,
                               { to: cur.sc.to as string | undefined, seq: (cur.sc.seq as number) ?? 0 })
        }

        // Known (the Keep ledger — editor only, empty in a Run) + Loaded
        const known = new Map<string, number | undefined>()
        const keep  = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        void keep?.version
        for (const wt of (keep?.o({ WaftTimes: 1 }) ?? []) as TheC[])
            if (wt.sc.of_Waft) known.set(wt.sc.of_Waft as string, wt.sc.accessed_at as number | undefined)
        const live = new Map<string, TheC>()
        for (const wf of w.o({ Waft: 1 }) as TheC[]) live.set(wf.sc.Waft as string, wf)

        // Docs per drillable Waft (discovery order, deduped) + the cross-Waft share index
        type MDoc = { path: string, title: string, cursor?: 1, shared?: number }
        const docWafts = new Map<string, Set<string>>()
        const waftDocs = new Map<string, MDoc[]>()
        for (const [path, wf] of live) {
            if (wf.sc.equip || wf.sc.takes) continue
            void wf.version
            const seen = new Set<string>(); const docs: MDoc[] = []
            H.Lies_walk_docs(wf, (d: TheC) => {
                const dp = d.sc.Doc as string | undefined
                if (dp && !seen.has(dp)) {
                    seen.add(dp)
                    docs.push({ path: dp, title: H.Lies_waftmap_title(dp) })
                    let s = docWafts.get(dp); if (!s) docWafts.set(dp, s = new Set()); s.add(path)
                }
                return false
            })
            waftDocs.set(path, docs)
        }
        const shared = new Map<string, Set<string>>()
        for (const [dp, s] of docWafts) if (s.size >= 2) shared.set(dp, s)
        for (const docs of waftDocs.values())
            for (const d of docs) { const s = shared.get(d.path); if (s) d.shared = s.size }

        // The cursor Doc of a Waft: the live Spotlight when it sits here, else the touch memory
        //  (a Lango `to` that is a doc path — `to` equal to the waft key is a bare Waft land).
        const cursor_of = (path: string): string | undefined => {
            if (path === spot_waft && spot_src) {
                const dp = H.Waft_src_doc_path(spot_src) as string | undefined
                if (dp) return dp
            }
            const to = touch.get(path)?.to
            return to && to !== path ? to : undefined
        }

        // Column chunking — Docs stack in columns of 3-ish; 4 when it packs better (4 → one
        //  of 4, 7 → 4+3, 8 → 4+4, 12 → 4+4+4)
        const colh_of = (n: number) => n > 3 && (n % 3 === 1 || n % 4 === 0) ? 4 : 3

        // Rows — classify to an OPENINGNESS ladder (how many Docs are listed from where you
        //  are), light the shaft, order by it.
        //  enth 3 = every Doc up to CAP (the fg default; past CAP the window + grow-by-3 edges
        //   take over) · 2 = the 3-window from the cursor (a touched content Waft) · 1 = a single
        //    discernible calm row, title + count (plain content + the board) · 0 = stackable,
        //     reserved for BORING equipment and cold/closed Wafts.  burst = enth ≥ 2.
        const CAP = 30
        // Equipment that is BORING by name — always-present machinery, never content.  (A Waft
        //  can also carry an explicit %boring; the backstage stances count too — see below.)
        const BORING_WAFTS = new Set(['GhostList', 'NormalEntropy'])
        type MRow = { kind: 'waft', path: string, title: string, loaded: boolean,
                      stance: 'doc' | 'fixture' | 'sink' | 'cold',
                      fg: boolean, hot: boolean, touched: boolean, boring: boolean,
                      board: boolean, enth: number, seq: number, burst: boolean,
                      cursor: string | undefined, show_all: boolean, colh: number,
                      docs: MDoc[], lo: number, hi: number, above: number, below: number }
        type MStack = { kind: 'stack', wafts: { path: string, title: string, loaded: boolean }[] }
        const paths = new Set<string>([...live.keys(), ...known.keys()])
        const rows: MRow[] = [...paths].map(path => {
            const wf     = live.get(path)
            const stance: MRow['stance'] = !wf ? 'cold' : wf.sc.equip ? 'fixture' : wf.sc.takes ? 'sink' : 'doc'
            const docs   = waftDocs.get(path) ?? []
            const t      = touch.get(path)
            const is_fg  = fg === path
            const board  = !!wf && !!(wf.o({ Funkcion: 'StoryTimes' })[0] ?? wf.o({ Funkcion: 'Storying' })[0])
            // BORING = the equipment that just sits there, sort of like a ghost of infrastructure:
            //  the ghost index (GhostList), the shared entropy profile (NormalEntropy), the
            //   backstage stances (the Ting sink, the equip fixtures like Keep), or anything
            //    explicitly marked %boring.  Boring Wafts — and cold/closed ones — are the ONLY
            //     things that stack; real CONTENT is always at least a discernible calm row, so a
            //      plain Waft (Ality) never shrinks to a GhostList-sized nub.  (hot — an active
            //       Interest — is NOT in the ladder: every open Waft goes presence:active,
            //        separating nothing; it stays styling only.)
            const boring = !!wf?.sc.boring || BORING_WAFTS.has(path) || stance === 'sink' || stance === 'fixture'
            //  fg → all Docs · a touched content Waft → the 3-window · plain content + the board →
            //   a discernible calm row · boring equipment or a cold/closed Waft → stacked.
            const enth   = is_fg ? 3 : (!wf || boring) ? 0 : t ? 2 : 1
            const cpath  = cursor_of(path)
            // the shaft of light — a 3-Doc window around the cursor; soft start = the first 3
            const ci = cpath ? docs.findIndex(d => d.path === cpath) : -1
            const lo = ci <= 0 ? 0 : Math.min(ci - 1, Math.max(0, docs.length - 3))
            const hi = Math.min(docs.length, lo + 3)
            if (ci >= 0) docs[ci].cursor = 1
            const show_all = enth >= 3 && docs.length <= CAP
            return { kind: 'waft', path, title: H.Lies_waftmap_title(path), loaded: !!wf, stance,
                     fg: is_fg, hot: hot.has(path), touched: !!t, boring,
                     board, enth, seq: t?.seq ?? 0, burst: enth >= 2, cursor: cpath,
                     show_all, colh: colh_of(docs.length),
                     docs, lo, hi,
                     above: show_all ? 0 : lo, below: show_all ? 0 : docs.length - hi }
        })
        rows.sort((a, b) =>
            (+b.fg - +a.fg) || (+b.burst - +a.burst) || (b.enth - a.enth) || (b.seq - a.seq)
            || (+b.hot - +a.hot)
            || (+(b.docs.length > 0) - +(a.docs.length > 0)) || a.path.localeCompare(b.path))

        // The seams — chips over budget demote burst rows bottom-up to calm (enth 1); never the
        //  fg.  A chip is a WIDTH unit now that Docs ride in columns: title 1 + a chip per column
        //   + the grow edge — a grand show-all cluster costs its column count, not its Doc count
        //    (12 Docs = 3 cols).  A stacked enth-0 row (boring|cold) is compact — it costs
        //     nothing, so a shelf full of equipment never trips the seams by itself.
        const chips_of = (r: MRow) => {
            if (r.enth === 0) return 0
            if (!r.burst) return 1
            const shown = r.show_all ? r.docs.length : (r.hi - r.lo)
            return 1 + Math.ceil(shown / r.colh) + (r.above + r.below ? 1 : 0)
        }
        let chips    = rows.reduce((n, r) => n + chips_of(r), 0)
        let bursting = false
        for (let i = rows.length - 1; chips > budget && i >= 0; i--) {
            const r = rows[i]
            if (!r.burst || r.fg) continue
            chips -= chips_of(r) - 1; r.burst = false; r.enth = 1
            bursting = true
        }
        if (chips > budget) bursting = true

        // Emit: every enth ≥ 1 row stands alone (a burst cluster, or a discernible calm content
        //  row); only the enth-0 BORING equipment and cold/closed Wafts pack into stacks of two
        const out: Array<MRow | MStack> = []
        let pend: MStack | undefined
        for (const r of rows) {
            if (r.enth >= 1) { out.push(r); continue }
            if (!pend) { pend = { kind: 'stack', wafts: [] }; out.push(pend) }
            pend.wafts.push({ path: r.path, title: r.title, loaded: r.loaded })
            if (pend.wafts.length >= 2) pend = undefined
        }

        // The crumb harvest — touched Wafts' cursor Docs, discovery order (seq asc), fg's first
        const crumbs = rows
            .filter(r => r.cursor)
            .sort((a, b) => (+b.fg - +a.fg) || (a.seq - b.seq))
            .slice(0, 7)
            .map(r => ({ waft: r.path, path: r.cursor as string, title: H.Lies_waftmap_title(r.cursor as string) }))

        return { rows: out, crumbs, shared, chips, budget, bursting }
    },

    // ── e_Lies_waftmap_implant — the search bar's "into the substrate" drop ───────────────────
    //   Plant a repo file INTO the working Waft (the fg Interest's, else the first plain one) as
    //    a fresh moment %What holding the %Doc, then cursor in — the search hit stops being a
    //     visitor (that's Lies_ghost_pick's Aside) and joins the Waft under work.  e.sc: { path }
    async e_Lies_waftmap_implant(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = e.sc.path as string | undefined
        if (!path) return
        const ave  = (H as any).ave ?? H.top_House().ave
        const fg   = ave?.ob({ Languinio: 1 })[0]?.ob({ ActiveInterest: 1 })[0]?.sc.waft as string | undefined
        const waft = (fg ? w.o({ Waft: fg })[0] as TheC | undefined : undefined)
            ?? (w.o({ Waft: 1 }) as TheC[]).find(wf => !wf.sc.equip && !wf.sc.takes)
        if (!waft) return
        const what = waft.i({ What: H.Lies_waftmap_title(path) })
        what.c.up   = waft
        what.c.waft = waft
        what.i({ Doc: path })
        waft.bump_version()
        H.Lies_waft_save(w, waft)
        H.i_elvisto(w, 'Lies_want', { src: what, kind: 'click' })
    },

//#endregion
//#region Stemdex — scan|stem every Doc for the universal search (methods · properties · freetext)
//
//  The corpus, readable by TEXT.  A lazy index over every Doc the machine knows — the loaded
//   Waft trees plus the whole GhostList roster — fed from the %Good disk cache (req:Store), so
//    it never reaches into the Lang docks and covers docs nobody has opened.  Three vocabularies
//     per doc, extracted in one scan of its text:
//      defs   — method|function definitions (line-start `name(…) {`, `function name`, arrow
//                consts; .md headings ride as defs too, so a spec's sections hit by name)
//      props  — the particle vocabulary: `sc.key` | `.c.key` accessors and `%Notation` marks
//      stems  — every camel|snake-split token, lightly stemmed (plural|ing|ed|er stripped)
//  All off-snap on w.c.stemdex (Maps are runtime brain, never truth; an object in sc is an
//   encode fatal).  A scan PASS is polite: it indexes whatever %Goods have landed and requests
//    at most READ_BUDGET new reads — the searchbar nudges passes while it's open, so the index
//     converges over a few seconds the first time and is dige-gated per doc after that.
//  A Dexie table (db 'stemdex', one projection row per doc, dige inside) makes that first
//   time ONCE PER REPO, not once per session: the first pass warms the whole index from IDB,
//    then disk truth re-scans only the dige-movers.  Strictly an accelerator — absent or
//     failing IDB (node runner) degrades to the old cold scan, never to an error.
//  Known drift: an open dock's unsaved buffer isn't seen (disk truth only).  The precise live
//   layer for open docks — their compiled %Map defs — is the follow-up, not this pass.

    // ── Lies_stem — one word to its light stem ────────────────────────────────────────────────
    //   Lowercase + a conservative suffix strip (ies→y; ings|ers|eds|es|s).  The scan and the
    //    query both stem with THIS, so internal consistency is the contract, not linguistics.
    Lies_stem(word: string): string {
        let s = word.toLowerCase()
        if (s.length > 4) {
            if (/ies$/.test(s)) s = s.slice(0, -3) + 'y'
            else s = s.replace(/(?:ings?|ers?|eds?|es|s)$/, '')
        }
        return s
    },

    // ── Lies_stemdex — the index handle (no scan here; e_Lies_stemdex_scan feeds it) ──────────
    Lies_stemdex(w: TheC): any {
        const c = w.c as any
        c.stemdex ??= {
            docs:  new Map(),   // path → { dige, title, lines[clipped], stems[], defs[], props[] }
            post:  new Map(),   // stem → Map<path, line[]>            (the freetext postings)
            defs:  new Map(),   // name.toLowerCase() → [{ name, kind, path, line }]
            props: new Map(),   // prop.toLowerCase() → [{ name, path, lines[] }]
            total: 0, done: 0, missing: 0, pass: 0,   // (+ scanning, warmed — pass-machinery flags)
        }
        return c.stemdex
    },

    // ── Lies_stemdex_db — the Dexie cache: one row per doc, the SAME projection row that
    //    Lies_stemdex_scan_text builds, keyed by path with the dige inside — so a fresh
    //     session's first search warms from IDB instantly instead of re-reading the repo
    //      through the store.  Browser-only ACCELERATOR: no indexedDB (a node runner) →
    //       undefined, and every caller try/catches — the cache can slow a first search
    //        when absent, never break one.  (When Stemdex_spec §3 lands, the row unit
    //         shrinks from doc to region shard; same table, same shape-per-row idea.)
    Lies_stemdex_db(): any {
        if (typeof indexedDB === 'undefined') return undefined
        const g = globalThis as any                        // one handle across HMR remixes
        if (!g.__stemdex_db) {
            const db = new Dexie('stemdex') as any
            db.version(1).stores({ doc: 'path' })          // PK only; the row body is the projection
            g.__stemdex_db = db
        }
        return g.__stemdex_db
    },

    // ── Lies_stemdex_drop — remove one doc's projection from every index map ─────────────────
    Lies_stemdex_drop(dex: any, path: string) {
        const old = dex.docs.get(path)
        if (!old) return
        for (const s of old.stems) { const p = dex.post.get(s); p?.delete(path); if (p && !p.size) dex.post.delete(s) }
        for (const k of old.defs)  { const l = (dex.defs.get(k)  ?? []).filter((e: any) => e.path !== path); l.length ? dex.defs.set(k, l)  : dex.defs.delete(k) }
        for (const k of old.props) { const l = (dex.props.get(k) ?? []).filter((e: any) => e.path !== path); l.length ? dex.props.set(k, l) : dex.props.delete(k) }
        dex.docs.delete(path)
    },

    // ── Lies_stemdex_adopt — splice ONE projection row into the index (drop-then-insert,
    //    one sync block per doc: swap-don't-clear at the row grain).  The row is the
    //     persistable shape — a fresh scan and a Dexie cache hit adopt IDENTICALLY.
    Lies_stemdex_adopt(dex: any, row: any) {
        this.Lies_stemdex_drop(dex, row.path)
        const doc = { dige: row.dige, title: row.title, lines: row.lines,
                      stems: Object.keys(row.post ?? {}), defs: [] as string[], props: [] as string[] }
        for (const d of row.defs_e ?? []) {
            const k = String(d.name).toLowerCase()
            if (!doc.defs.includes(k)) doc.defs.push(k)
            const l = dex.defs.get(k) ?? []
            l.push({ name: d.name, kind: d.kind, path: row.path, line: d.line })
            dex.defs.set(k, l)
        }
        for (const p of row.props_e ?? []) {
            const k = String(p.name).toLowerCase()
            if (!doc.props.includes(k)) doc.props.push(k)
            const l = dex.props.get(k) ?? []
            l.push({ name: p.name, path: row.path, lines: p.lines })
            dex.props.set(k, l)
        }
        for (const s of doc.stems) {
            let pm = dex.post.get(s)
            if (!pm) dex.post.set(s, pm = new Map())
            pm.set(row.path, row.post[s])
        }
        dex.docs.set(row.path, doc)
    },

    // ── Lies_stemdex_scan_text — index ONE doc's text; returns the projection ROW ────────────
    //   Tokenises into a plain, structured-cloneable row (path, dige, title, clipped lines,
    //    postings, def|prop entries), then adopts it — the caller persists the same row to
    //     the Dexie cache, so what IDB replays later is literally what this scan produced.
    Lies_stemdex_scan_text(dex: any, path: string, dige: string, text: string): any {
        const H = this as House
        const TOKEN    = /[A-Z]+(?![a-z])|[A-Z][a-z]+|[a-z]+|[0-9]+/g   // StemHive's camel|snake splitter
        const RESERVED = new Set(['if', 'for', 'while', 'switch', 'catch', 'return', 'else', 'do',
            'new', 'typeof', 'await', 'async', 'function', 'super', 'import', 'export', 'const',
            'let', 'var', 'delete', 'void', 'in', 'of', 'case', 'throw', 'try', 'yield', 'with'])
        const lines_in = text.split('\n')
        const row = { path, dige, title: H.Lies_waftmap_title(path), lines: [] as string[],
                      post: {} as Record<string, number[]>,
                      defs_e:  [] as { name: string, kind: string, line: number }[],
                      props_e: [] as { name: string, lines: number[] }[] }
        const my_post  = new Map<string, number[]>()
        const my_props = new Map<string, { name: string, lines: number[] }>()
        const push_def  = (name: string, line: number, kind: string) => row.defs_e.push({ name, kind, line })
        const push_prop = (name: string, line: number) => {
            const k = name.toLowerCase()
            let e = my_props.get(k)
            if (!e) my_props.set(k, e = { name, lines: [] })
            if (e.lines.length < 4 && e.lines[e.lines.length - 1] !== line) e.lines.push(line)
        }
        const is_md = /\.md$/i.test(path)
        for (let i = 0; i < lines_in.length; i++) {
            const raw = lines_in[i], ln = i + 1
            row.lines.push(raw.length > 120 ? raw.slice(0, 120) : raw)   // clipped, for snippets
            for (const m of raw.matchAll(TOKEN)) {
                const word = m[0]
                if (word.length < 2 || /^\d+$/.test(word)) continue
                const s = H.Lies_stem(word)
                if (s.length < 2) continue
                let arr = my_post.get(s)
                if (!arr) my_post.set(s, arr = [])
                if (arr.length < 6 && arr[arr.length - 1] !== ln) arr.push(ln)
            }
            if (is_md) {
                const h = /^#{1,6}\s+(.+)/.exec(raw)
                if (h) push_def(h[1].trim(), ln, 'heading')
            } else {
                const m = /^\s*(?:export\s+)?(?:async\s+)?function\s+([A-Za-z_$][\w$]*)/.exec(raw)
                    ?? /^\s*(?:export\s+)?(?:public\s+|private\s+|static\s+|async\s+)*([A-Za-z_$][\w$]*)\s*\([^)]*\)\s*(?::[^{;=\n]+)?\{\s*$/.exec(raw)
                    ?? /^\s*(?:export\s+)?(?:const|let)\s+([A-Za-z_$][\w$]*)\s*=\s*(?:async\s*)?\(/.exec(raw)
                if (m && !RESERVED.has(m[1])) push_def(m[1], ln, 'def')
            }
            for (const m of raw.matchAll(/(?:\bsc|\.c)\.([A-Za-z_$][\w$]*)/g)) push_prop(m[1], ln)
            for (const m of raw.matchAll(/(?<![\w%$])%([A-Za-z]\w+)/g))        push_prop(m[1], ln)
        }
        for (const [s, ls] of my_post) row.post[s] = ls
        row.props_e = [...my_props.values()]
        this.Lies_stemdex_adopt(dex, row)
        return row
    },

    // ── e_Lies_stemdex_scan — one polite pass: index landed %Goods, request a few more ────────
    //   Nudge this repeatedly (the searchbar does, while open); each pass indexes every
    //    text/Doc %Good that has landed since the last one, and asks the store for at most
    //     READ_BUDGET unseen paths — so a whole-repo first scan converges over a few passes
    //      without flooding the store pump.  e.sc: {} — idempotent, dige-gated per doc.
    async e_Lies_stemdex_scan(A: TheC, w: TheC, e: TheC) {
        const H   = this as House
        const dex = H.Lies_stemdex(w)
        if (dex.scanning) return
        dex.scanning = true
        try {
            const db = H.Lies_stemdex_db()
            // WARM once per session: starting to search touches the whole cache — every
            //  projection row loads in one bulk IDB read and adopts as-is, so the very
            //   first query answers from yesterday's index; disk truth then trickles in
            //    and any doc whose dige moved re-scans below.  A stale cache heals, an
            //     absent|failing one only means a slower first search.
            if (!dex.warmed && db) {
                dex.warmed = true
                try {
                    const rows = await db.doc.toArray()
                    for (const row of rows) if (!dex.docs.has(row.path)) H.Lies_stemdex_adopt(dex, row)
                } catch (err) { console.warn('🐝 stemdex cache warm failed', err) }
            }

            // the roster: every Doc in every loaded Waft + the whole GhostList
            const paths = new Set<string>()
            for (const waft of w.o({ Waft: 1 }) as TheC[])
                H.Lies_walk_docs(waft, (d: TheC) => { if (d.sc.Doc) paths.add(d.sc.Doc as string); return false })
            const gl = w.o({ Waft: 'GhostList' })[0] as TheC | undefined
            for (const g of (gl?.o({ group: 1 }) ?? []) as TheC[])
                for (const d of g.o({ Doc: 1 }) as TheC[]) if (d.sc.Doc) paths.add(d.sc.Doc as string)
            for (const p of [...paths])                                  // generated output is not source
                if (p.includes('/gen/') && p.endsWith('.go')) paths.delete(p)

            // Two budgets keep a pass polite: READ_BUDGET new store reads (IO), SCAN_BUDGET
            //  fresh text scans (CPU — a whole-file split+regex is the thumpy part; the
            //   region-partitioned incremental scan is Stemdex_spec.md's destination).
            //  Reads are AWAITED — a floating promise mutates the store outside Atime
            //   (reactivity_docs: keep your limbs within Atime), which is exactly the
            //    vanish-for-an-instant class of bug.
            const READ_BUDGET = 24, SCAN_BUDGET = 8
            const store = await H.LiesStore_req(w)
            let asked = 0, scanned = 0, done = 0, missing = 0
            const fresh: any[] = []                                      // this pass's rows → the cache
            for (const path of paths) {
                const good    = store.o({ Good: 1, type: 'text/Doc', path })[0] as TheC | undefined
                const content = good?.c.content as string | null | undefined
                if (content === undefined) {                             // not landed — maybe ask
                    if (asked < READ_BUDGET) { asked++; await H.LiesStore_read_good(w, 'text/Doc', path) }
                    continue
                }
                if (content === null || content.length > 400_000) { missing++; continue }
                const dige  = ((good!.o({ known: 1 })[0] as TheC | undefined)?.sc.dige as string) ?? ''
                const prior = dex.docs.get(path)
                if (!prior || prior.dige !== dige) {
                    if (scanned >= SCAN_BUDGET) continue                 // not yet done — next pass
                    scanned++
                    fresh.push(H.Lies_stemdex_scan_text(dex, path, dige, content))
                }
                done++
            }
            dex.total = paths.size; dex.done = done; dex.missing = missing; dex.pass++

            // persist this pass's work; prune cache rows whose doc left the corpus — but
            //  only against a REAL roster (a half-booted GhostList must not empty the cache)
            if (db) try {
                if (fresh.length) await db.doc.bulkPut(fresh)
                if (paths.size > 50) {
                    const gone = [...dex.docs.keys()].filter(p => !paths.has(p))
                    for (const p of gone) H.Lies_stemdex_drop(dex, p)
                    if (gone.length) await db.doc.bulkDelete(gone)
                }
            } catch (err) { console.warn('🐝 stemdex cache save failed', err) }

            // Seemables Slice 0 (spec/Seemables_todo.md §6): a READ-ONLY %Seem mirror stood
            //  BESIDE the hand-rolled prune above, changing NO verdict.  It mirrors the INDEX
            //   side (dex.docs) — the same independent set the prune sweeps (:1468) — so its
            //    per-pass goners reproduce the docs that fell out of the index, honestly, and
            //     can DIVERGE from a naive roster delta (cache-warm/budget-lag).  Gated on the
            //      SAME size>50 real-roster guard the prune uses (a half-booted GhostList must
            //       not read as a mass departure).  Fully guarded — it can never throw the scan.
            if (paths.size > 50)
                try { await H.Stemdex_seem_mirror(w, dex) }
                catch (err) { console.warn('🐝 stemdex seem mirror failed', err) }
        } finally { dex.scanning = false }
    },

    // ── Stemdex_seem_mirror — Seemables Slice 0 read-only mirror of the INDEX diff ────────────
    //   The scan (e_Lies_stemdex_scan) hand-rolls survivor/neu/goner and then PRUNES the index:
    //    `[...dex.docs.keys()].filter(p => !paths.has(p))` sweeps the docs that fell out of the
    //     corpus (:1468).  This mirror tracks the INDEX side — dex.docs.keys() — the independent
    //      set the prune reads, NOT the roster it reads it against; so its per-pass goners are the
    //       docs that actually LEFT the index (arrivals = docs the scan just adopted).  Because it
    //        mirrors the index and not the roster, it can DIVERGE from a naive roster delta exactly
    //         where the two disagree (a warm-cache doc not yet in the roster, a budget-lagged
    //          arrival), which is the honesty the roster-vs-roster mirror lost.  o_Seem returns
    //           that diff for free WITH identity.  Modelled on Voro.g's proven Voro_census_mirror
    //            (i_Seem/o_Seem): the Seem is snap-hostile (a live Selection + fns ride its sc), so
    //             it parks on a free off-snap C** kept once on w.c and reused — resolve() needs a
    //              "last beat" to diff against.  The index mirror C** carries ONE child per indexed
    //               path (its identity = the goner/neu unit); synced to dex.docs each pass.
    //   Purely additive: touches no dex map, no index, no search — only w.c.* runtime fields.
    async Stemdex_seem_mirror(w: TheC, dex: any) {
        const H = this as House
        // off-snap homes, minted ONCE and reused so the Seem has a previous beat to diff.
        //  _C({sc}) is LiesFunk's runtime twin of Voro.g's `new TheC({...})` (TheC is a type-only
        //   import here; _C is the imported runtime factory that returns a fresh free particle).
        const wc = w.c as any
        if (!wc.stemdex_seem_home) wc.stemdex_seem_home = _C({ c: {}, sc: { stemdex_seem_home: 1 } })
        const home: TheC = wc.stemdex_seem_home
        if (!wc.stemdex_index) wc.stemdex_index = _C({ c: {}, sc: { stemdex_index: 1 } })
        const index: TheC = wc.stemdex_index

        // sync the mirror to exactly THIS pass's INDEX membership — add arrivals (oai = stable
        //  slot, so a survivor keeps its identity), drop docs no longer indexed.  An indexed path
        //   is the child identity; a distinct sanitized sc value keeps keys clean of slashes/dots
        //    that the peel splits on.
        const key_of = (p: string) => p.replace(/[^A-Za-z0-9]+/g, '_')
        const indexed = [...dex.docs.keys()] as string[]
        const want = new Set(indexed.map(key_of))
        for (const p of indexed) index.oai({ doc: key_of(p) }, { path: p })
        for (const c of index.o({ doc: 1 }).slice() as TheC[])
            if (!want.has(c.sc.doc as string)) index.drop(c)

        // one walk over the index mirror — {goners, neus} is the last-beat-vs-this-beat diff.
        const seem: TheC = home.o({ Seem: 'stemdex' })[0]
            ?? H.i_Seem(home, { Seem: 'stemdex', C: index })
        seem.sc.C = index
        const news = await H.o_Seem(seem)

        // project a SMALL distilled reading onto .c runtime (NEVER .sc — the Seem is snap-hostile
        //  and this whole limb is off-snap).  A Book %see reads these beside the live prune (:1468).
        wc.stemdex_seem = {
            goners: news.goners.length,   // docs that LEFT the index this pass (= the :1468 `gone` drops)
            neus:   news.neus.length,     // docs the scan just ADDED to the index this pass
            rows:   index.o({ doc: 1 }).length,
        }
    },

    // ── Lies_search — the universal query: methods ▸ properties ▸ freetext ────────────────────
    //   Pure sync read over the stemdex (fire Lies_stemdex_scan to feed it).  Grouped, ranked,
    //    capped; every hit carries {path, title, line} so a click can Dock_open straight to it.
    Lies_search(w: TheC, q: string, cap = 8): any {
        const H   = this as House
        const dex = (w.c as any).stemdex
        const out = { defs: [] as any[], props: [] as any[], texts: [] as any[],
                      done: dex?.done ?? 0, total: dex?.total ?? 0 }
        const needle = q.trim().toLowerCase()
        if (!dex || needle.length < 2) return out

        // names — exact ▸ prefix ▸ substring tiers, stable within a tier
        const pick_names = (m: Map<string, any[]>, into: any[], flat: (e: any) => any) => {
            const tiers: any[][] = [[], [], []]
            for (const [k, l] of m) {
                const t = k === needle ? 0 : k.startsWith(needle) ? 1 : k.includes(needle) ? 2 : -1
                if (t >= 0) tiers[t].push(...l)
            }
            for (const tier of tiers) for (const e of tier) { if (into.length >= cap) return; into.push(flat(e)) }
        }
        const title_of = (path: string) => dex.docs.get(path)?.title ?? path
        const snip_at  = (path: string, line: number) => (dex.docs.get(path)?.lines[line - 1] ?? '').trim()
        pick_names(dex.defs,  out.defs,  (e) => ({ name: e.name, kind: e.kind, path: e.path,
            title: title_of(e.path), line: e.line, snippet: snip_at(e.path, e.line) }))
        pick_names(dex.props, out.props, (e) => ({ name: e.name, path: e.path,
            title: title_of(e.path), line: e.lines[0], lines: e.lines }))

        // freetext — every query token must land in a doc (stem exact | prefix); rank by hit mass
        const tokens = [...needle.matchAll(/[a-z0-9]+/g)].map(m => H.Lies_stem(m[0])).filter(s => s.length >= 2)
        if (tokens.length) {
            let per_doc: Map<string, { count: number, line: number }> | undefined
            for (const tok of tokens) {
                const docs_for = new Map<string, { count: number, line: number }>()
                for (const [s, posting] of dex.post) {
                    if (s !== tok && !(tok.length >= 3 && s.startsWith(tok))) continue
                    for (const [path, ls] of posting) {
                        const got = docs_for.get(path)
                        if (got) got.count += ls.length
                        else docs_for.set(path, { count: ls.length, line: ls[0] })
                    }
                }
                if (!per_doc) { per_doc = docs_for; continue }
                for (const p of [...per_doc.keys()]) {                   // AND across tokens
                    const v = docs_for.get(p)
                    if (!v) per_doc.delete(p)
                    else per_doc.get(p)!.count += v.count
                }
            }
            const ranked = [...(per_doc ?? new Map())].sort((a: any, b: any) => b[1].count - a[1].count).slice(0, cap)
            for (const [path, v] of ranked as any)
                out.texts.push({ path, title: title_of(path), line: v.line, count: v.count, snippet: snip_at(path, v.line) })
        }
        return out
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
    //     (e:Lang_lango → Dock_open), which settles over later req:Store
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
            const needAC   = !!e.sc.needAC     // carried from the Credence cell (of_Book,needAC:1) → secured pre-run
            const needsFSA = !!e.sc.needsFSA   // ditto (of_Book,needsFSA:1) → routes to an fsa-live runner, proxy refuses
            if (H.Lies_is_editor(w)) {
                const pick = H.Lies_dispatch_target(w, needAC, needsFSA)   // {to} ▸ {} broadcast ▸ {exhausted} preempt-our-runner; needAC/needsFSA prefer a capable runner
                if (pick.exhausted) {
                    // A single click means "run THIS now" — don't queue behind a run we've moved past.  Preempt
                    //  the runner we already drove: send it the new book, its Story_reset cancels the old run.
                    //   (StoryTimes keeps the hold/parallel-acquire path — that's the multi-run sweep, below.)
                    const pre = (H as any).Lies_preempt_target(w) as string | undefined
                    if (pre) {
                        const sent = H.Lies_send_become_book(w, book, pre, needAC, needsFSA)
                        H.tlog(`↻ all runners busy — preempting @${pre.slice(0, 8)} → ${book} ${sent ? '(re-instructed, prior run canceled)' : '(channel down)'}`)
                        return
                    }
                    H.Lies_queue_run(w, book); H.tlog(`⏸ all runners busy + none to preempt — held ${book}`); return
                }
                if (pick.to === undefined) {
                    // No live runner to individuate.  If ANY runner is KNOWN (registry or roster), this is the
                    //  post-reconnect fold lag, NOT a lone runner — HOLD the run (Lies_drain_runs ships it the
                    //   instant one goes live) rather than spray EVERY runner bound under 'runner' (the both-ran-it
                    //    bug).  Only when NOTHING is known at all do we broadcast (a lone, possibly keyless,
                    //     unregistered runner reachable only by the role address).
                    const known   = (w.o({ Runner: 1 }) as TheC[]).length
                    const cluster = w.o({ Waft: 'Cluster' })[0] as TheC | undefined
                    const reg     = cluster ? (cluster.o({ HostedIdentity: 1 }) as TheC[]).filter(h => h.sc.role === 'runner').length : 0
                    if (known || reg) {
                        H.Lies_queue_run(w, book)
                        H.tlog(`⏸ become_book held — runners known (${known}/${reg}) but none live yet: ${book}`)
                        return
                    }
                    H.Lies_relay_note(w, `⚠ no runner known at all — broadcasting ${book} (lone/unregistered runner)`, true)
                }
                const sent = H.Lies_send_become_book(w, book, pick.to, needAC, needsFSA)
                H.tlog(`🎬 editor become_book → ${book} ${pick.to ? `@${pick.to.slice(0, 8)}` : '(broadcast)'} ${sent ? '(sent)' : '(channel down — no runner)'}`)
            } else {
                H.Lies_become_book_drive(w, book, needAC, needsFSA)   // runner, or a bare dev Lies with a co-resident Run
            }
        },

        // Lies_send_become_book — editor emit, mirrors Lies_send_rungo (same direction, the
        //  rungo channel).  Returns false when the channel is down so the caller can say so.
        //   `to` (a runner prepub, Engage_integration C2) addresses ONE runner on the grid: promote a
        //    Pier for it and ship to:<prepub>; absent, the legacy single-address role broadcast.
        Lies_send_become_book(w: TheC, book: string, to?: string, needAC = false, needsFSA = false): boolean {
            const H = this as House
            if (!H.Lies_is_editor(w) || !H.Lies_channel_live(w)) return false
            const pins   = H.Lies_ledger_pins(w)   // the editor's recompiled drift-surface, pinned INLINE so the gate never waits on the (Phase C) whole-ledger push
            const ledger = pins.length ? { ledger_dige: H.Lies_ledger_head(w), pins } : {}
            const caps = { ...(needAC ? { needAC: 1 } : {}), ...(needsFSA ? { needsFSA: 1 } : {}) }   // capability facets carried to the runner
            if (to) {
                if (!H.Lies_runner_pier(w, to)) return false
                ;(H as any).Peeroleum_send_to(w, to, 'become_book', { book, ...caps, ...ledger })
                // light the ☎ on this runner's rack slot — a job in flight, awaiting its ack.  Cleared when
                //  the runner advertises a `book` (it picked up + started → ▶), in Lies_advertise_recv.
                const r = w.oai({ Runner: to }) as TheC          // snapped now (1:1 with the registry); the ☎ rides off-snap
                r.c.sent = book; r.c.sent_at = Date.now(); w.bump_version()
                w.c.rungo_runner = to   // a later recompile-rungo STICKS to the runner this book was started on (Lies_rungo_target)
                H.tlog(`📤 become_book → runner ${to}: ${book}`)
                return true
            }
            const pier = (w.o({ Peering: 1 })[0] as TheC | undefined)?.o({ Pier: 1 })[0] as TheC | undefined
            if (!pier) return false
            ;(H as any).Peeroleum_send_consumer(w, 'become_book', { book, ...caps, ...ledger })
            H.tlog(`📤 become_book → runner: ${book}`)
            return true
        },

        // Lies_runner_pier — find-or-PROMOTE the editor's Pier to a specific runner (by prepub), so an
        //  addressed become_book/rungo has a Pier to allocate seq on and route to.  Mirrors Lies_channel_up's
        //   seed (oai Pier + c.up + Ud) but keyed by the runner's identity, not the role string 'runner'.
        //    Trust-everything-v1 over the reliable relay ⇒ no handshake: stamp Ud and the inbox accepts.
        Lies_runner_pier(w: TheC, pub: string): TheC | undefined {
            const peering = w.o({ Peering: 1 })[0] as TheC | undefined
            if (!peering || !pub) return undefined
            let pier = (peering.o({ Pier: 1 }) as TheC[]).find(p => p.sc.pub === pub)
            if (!pier) {
                pier = peering.oai({ Pier: 1, pub }) as TheC
                pier.c.up = peering
                pier.c.promoted_at = Date.now()   // birth stamp (off-snap) — the roster's transport reaper
                                                  //  won't cull a just-rung Pier whose runner hasn't answered yet
                pier.oai({ Ud: 1 })   // satisfy the inbox pre-Ud gate (trust-everything v1, no handshake)
            }
            return pier
        },

        // Lies_become_book_recv — runner receives the command and drives the run.
        async Lies_become_book_recv(w: TheC, frame: any): Promise<boolean> {
            const H    = this as House
            const book = frame?.book as string | undefined
            if (!book) return false
            H.tlog(`📥 become_book recv: ${book}`)
            H.Lies_become_book_drive(w, book, !!frame?.needAC, !!frame?.needsFSA, frame?.ledger_dige, frame?.pins)
            return true
        },

        // RUN-BEGIN 1/2 — become_book: run a named Book at whatever's live (loose, fires now).  The other
        //  is req_rungo (LiesLies): currency-gated, waits for an exact compiled dige.  Two begin-paths is a
        //   dev ugliness — converge ~mid-Jul 2026 by folding this into a req:rungo,book branch.
        // Lies_become_book_drive — the runner's single run FRONT DOOR (become_book AND runner_ask both
        //  land here).  When the authority says this Book needAC (from Waft:Credence), SECURE the real
        //   voice FIRST — before the run begins — so the AC-wait is never inside a step's clock.  Then
        //    open the durable run-record, stash awaiting_verdict{book}, and resetStory onto it.
        async Lies_become_book_drive(w: TheC, book: string, needAC = false, needsFSA = false, ledger_dige?: string, pins?: { name: string, dige: string }[]) {
            const H = this as House
            // the needsFSA gate (FIRST — a proxy-only runner can secure nothing usefully): a disk-heavy Book
            //  must run on a LOCAL FSA share, never the remoteWormhole proxy (each read/write there crosses a
            //   belief-loop beat, so a per-beat Book overruns its budget).  Only the proxy here ⇒
            //    REFUSE cleanly (nothing tried, not a failure) so the authority re-routes to an fsa-live runner.
            if (needsFSA && !H.Lies_has_fsa(w)) {
                H.Lies_runner_phase(w, 'fsa_blocked', { book })
                H.tlog(`⌛ become_book ${book} blocked — needs a local FSA share; this runner has only the remote proxy (nothing tried)`)
                return
            }
            if (needAC && !(await H.Lies_secure_audio(w, book))) {
                // not granted within the window — refuse to begin.  Nothing was tried; report blocked so
                //  the run authority (%rungo / editor Brink) reads "couldn't run here", not a failure.
                H.Lies_runner_phase(w, 'audio_blocked', { book })
                H.tlog(`⌛ become_book ${book} blocked — AudioContext not granted (nothing tried)`)
                return
            }
            // the needMusic twin: a real-music Book needs its testsounds collection on disk BEFORE it begins
            //  (the walk takes a while / a stalled remote share must not sit inside a step's clock).  Refuse
            //   cleanly with the EXACT reason (no_share | stalled | no_directory) — nothing tried, not a failure.
            if (H.Lies_book_needmusic(w, book)) {
                const sec = await H.Lies_secure_collection(w, book, 'testsounds', 1)
                if (!sec.ok) {
                    H.Lies_runner_phase(w, 'collection_blocked', { book })
                    H.Upkeep_errand(`needMusic:${book}`, { kind: 'disk', label: `${book} — ${sec.why}`, phase: 'failed' }); H.Lies_upkeep(w)
                    H.tlog(`⌛ become_book ${book} blocked — ${sec.why} (${sec.reason}; nothing tried)`)
                    return
                }
            }
            // the VERSION GATE — HOLD (pre-run, before any step clock) until this runner has every ghost the
            //  editor pinned live; else refuse cleanly with a named Ghost_version_ledger_timeout.  A stale
            //   runner can no longer give a silent green — it catches up (pushed gen lands) or reddens.
            if (!(await H.Lies_ledger_secure(w, book, ledger_dige, pins))) return
            w.c.awaiting_verdict = { book }
            H.Lies_runner_begin(w, book)   // open the durable run-record (the become_book twin of rungo)
            H.top_House().i_elvisto('Auto/Auto', 'resetStory', { Book: book })
            H.Lies_runner_phase(w, 'story_begun', { book })   // blip: Run kicked (Book sweep / cell click)
            H.tlog(`🎬 become_book drive → ${book}`)
        },

        // Lies_ledger_secure — the PRE-RUN VERSION gate (become_book's twin of Lies_secure_audio).  The
        //  editor pinned the ghost versions this Book must run against (INLINE on the frame — robust, no
        //   dependence on the whole-ledger push); HOLD here, BEFORE the run-record opens so no step clock
        //    is ticking, until every pin is LIVE on this runner (Lies_ledger_check empty).  Met at once (or
        //     nothing pinned — a no-edit editor / legacy frame) → true, run now.  Behind → sit + poll while
        //      the pushed gen lands (Vite HMR / rungo → Ghost_version_checkin), self-reporting up the Brink.
        //       Lapse → a named Storyproblem: report a FAILED run_result (Ghost_version_ledger_timeout) so
        //        runner_ask goes red WITH the reason, + raise the editor Brink errand.  Never a stale green.
        async Lies_ledger_secure(w: TheC, book: string, ledger_dige?: string, pins?: { name: string, dige: string }[]): Promise<boolean> {
            const H = this as House
            // resolve the pins to gate on: INLINE (an editor become_book) → else the pushed replica HEAD, so a
            //  runner_ask run (which carries none of its own) still self-checks its live ghosts against the
            //   editor's head over the cheap CLI — the whole no-VNC point.
            if (!pins?.length) {
                const rep = (w.c as any).ledger_replica as { head?: string, versions?: any[] } | undefined
                if (rep?.head) {
                    const hv = (rep.versions ?? []).find(v => v.dige === rep.head)
                    if (hv) { pins = hv.pins as { name: string, dige: string }[]; ledger_dige = rep.head }
                }
            }
            // a referenced version we cannot resolve AT ALL (thin frame + no matching replica version) — the
            //  "super weird, shouldn't happen" case: fail LOUD with a distinct fatal, never a silent run.
            if (ledger_dige && !pins?.length) {
                H.Lies_runner_phase(w, 'ledger_missing', { book })
                H.Lies_report_result(w, { book, ok: false, errors: [`Ghost_version_ledger_missing — ledger ${String(ledger_dige).slice(0, 12)} carries no pins and no matching replica version on this runner`] })
                H.tlog(`✗ become_book ${book} — Ghost_version_ledger_missing: ${String(ledger_dige).slice(0, 12)}`)
                return false
            }
            if (!ledger_dige || !pins?.length) return true   // nothing pinned → nothing to gate
            let unmet = H.Lies_ledger_check(pins)
            if (!unmet.length) return true
            H.Lies_runner_phase(w, 'awaiting_ledger', { book })
            H.Upkeep_errand(`ledger:${book}`, { kind: 'version', label: `${book} — ${unmet.length} ghost(s) behind`, phase: 'running' }); H.Lies_upkeep(w)
            const deadline = Date.now() + 20000
            while (Date.now() < deadline) {
                await new Promise(r => setTimeout(r, 200))
                unmet = H.Lies_ledger_check(pins)
                if (!unmet.length) break
            }
            const ok = unmet.length === 0
            H.Upkeep_errand(`ledger:${book}`, { kind: 'version', label: book, phase: ok ? 'ok' : 'failed' }); H.Lies_upkeep(w)
            if (ok) { H.Lies_runner_phase(w, 'ledger_secured', { book }); return true }
            const behind = unmet.map(p => `${String(p.name).split('/').pop()} live=${String(p.live ?? 'none').slice(0, 8)}≠${String(p.dige).slice(0, 8)}`).join(', ')
            H.Lies_runner_phase(w, 'ledger_timeout', { book })
            H.Lies_report_result(w, { book, ok: false, errors: [`Ghost_version_ledger_timeout — runner behind on ${unmet.length} ghost(s): ${behind}`] })
            H.tlog(`⌛ become_book ${book} — Ghost_version_ledger_timeout: ${behind}`)
            return false
        },

        // Lies_secure_audio — the PRE-RUN AC gate.  Surfaces the request two ways (the user's split):
        //  FaceSucker on THIS runner tab (AudioContext_wanted → Otro's "open share" gate) + a Brink-
        //   complain up to the editor (the awaiting_audio phase up the run channel).  Then SITS up to 60s
        //    for a human to grant the gesture — this is BEFORE the run, so no step clock is running.
        //     Returns true once the voice is live, false if the window lapses (caller refuses to begin).
        async Lies_secure_audio(w: TheC, book: string): Promise<boolean> {
            const H = this as House
            if (typeof AudioContext === 'undefined') return false   // no Web Audio here (jsdom) — can't
            const top = H.top_House()
            let gat = (top.c as any).musu_gat
            if (!gat) { gat = new SoundSystem({}); (top.c as any).musu_gat = gat }
            if (gat.AC_ready) return true
            if (typeof window !== 'undefined') window.dispatchEvent(new CustomEvent('AudioContext_wanted', { detail: { gat } }))
            H.Lies_runner_phase(w, 'awaiting_audio', { book })   // Brink-complain up to the editor
            H.Upkeep_errand(`needAC:${book}`, { kind: 'audio', label: book, phase: 'running' }); H.Lies_upkeep(w)   // 🎤 on the Brink while we beg
            // spin the tab title so this runner announces itself in the tab strip while it begs — the
            //  reliable cross-tab attention-grab when the editor can't focus a sibling it didn't spawn.
            const spin = ['⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏']
            const title0 = typeof document !== 'undefined' ? document.title : ''
            let f = 0
            const deadline = Date.now() + 60000
            let live = false
            while (Date.now() < deadline) {
                if (gat.AC_ready) { live = true; break }
                if (typeof document !== 'undefined') document.title = `${spin[f++ % spin.length]} needs audio · ${book}`
                await new Promise(r => setTimeout(r, 300))
            }
            if (typeof document !== 'undefined') document.title = title0   // restore
            if (live) H.Lies_runner_phase(w, 'audio_secured', { book })   // UNBEG — clear the editor's beg the moment AC lands
            H.Upkeep_errand(`needAC:${book}`, { kind: 'audio', label: book, phase: live ? 'ok' : 'failed' }); H.Lies_upkeep(w)
            return live || !!gat.AC_ready
        },

        // Lies_book_needmusic — does this Book need the testsounds collection on disk? the needMusic twin of
        //  Lies_book_needac.  Reads %Storying,of_Book:<book>,needMusic off the loaded Credence board; absent
        //   ⇒ false (no gate).  Same board-walk as needAC so held/swept runs (bare Book name) re-read it here.
        Lies_book_needmusic(w: TheC, book: string): boolean {
            let found = false
            const walk = (c: TheC) => { for (const k of c.o() as TheC[]) {
                if (k.sc.Funkcion === 'Storying' && k.sc.of_Book === book && k.sc.needMusic) { found = true; return }
                walk(k); if (found) return } }
            for (const waft of w.o({ Waft: 1 }) as TheC[]) { walk(waft); if (found) break }
            return found
        },

        // Lies_book_needsfsa — does this Book need a LOCAL FSA share (fast disk), not the slow remoteWormhole
        //  proxy?  The needsFSA twin of Lies_book_needac / needmusic: reads %Storying,of_Book:<book>,needsFSA
        //   off the loaded Credence board.  A disk-heavy, timing-sensitive Book (bin_read/bin_write per beat —
        //    each hop across the proxy costs a belief-loop beat, so a per-beat Book overruns its budget, cf
        //     MusuGenerateTestsMusic) declares it, so dispatch routes it to an fsa-live runner and a
        //      proxy-only runner REFUSES it rather than dragging every read through the ~beat-latency wormhole.
        Lies_book_needsfsa(w: TheC, book: string): boolean {
            let found = false
            const walk = (c: TheC) => { for (const k of c.o() as TheC[]) {
                if (k.sc.Funkcion === 'Storying' && k.sc.of_Book === book && k.sc.needsFSA) { found = true; return }
                walk(k); if (found) return } }
            for (const waft of w.o({ Waft: 1 }) as TheC[]) { walk(waft); if (found) break }
            return found
        },

        // Lies_has_fsa — does THIS runner hold a real local FSA share (a granted DirectoryHandle on A:Wormhole,
        //  A.c.DL → WormholeNav(DL)), as opposed to the RemoteWormholeNav proxy (is_remote) or no nav at all?
        //   The capability behind needsFSA: the advertise beacon publishes it (fsa:1) and the become gate reads it.
        Lies_has_fsa(_w: TheC): boolean {
            const H = this as House
            return !!(H.top_House().o({ A: 'Wormhole' })[0] as TheC | undefined)?.c.DL
        },

        // Lies_secure_collection — the PRE-RUN COLLECTION gate, the needMusic twin of Lies_secure_audio: a
        //  real-music Book must have decodable tracks on disk BEFORE it begins (the walk takes a while, and a
        //   stalled remote share must never sit inside a step's clock — same reason needAC secures audio first).
        //    Returns {ok}, or a STANDARD reason — three DISTINCT conditions, never merged into one fuzzy line:
        //     no_share     — no nav/share granted at all (open a share)
        //     stalled      — the walk timed out: a remote atime_async proxy not answering (bounded, never hangs)
        //     no_directory — the walk ANSWERED but the collection isn't there (< need tracks → run the generator)
        async Lies_secure_collection(w: TheC, book: string, base: string, need: number): Promise<{ ok: boolean, reason?: string, why?: string }> {
            const H = this as House
            const nav = (H as any).Crate_nav?.()
            if (!nav) return { ok: false, reason: 'no_share', why: 'no disk share granted — open a share first' }
            const timer = new Promise<null>(res => setTimeout(() => res(null), 8000))
            const paths = await Promise.race([(H as any).Crate_nav_paths(nav, base) as Promise<string[]>, timer])
            if (paths == null)       return { ok: false, reason: 'stalled', why: `the ${base} share is not responding (remote proxy timed out) — check the share/editor` }
            if (paths.length < need) return { ok: false, reason: 'no_directory', why: `no ${base} collection (${paths.length}/${need} tracks) — run Story:MusuGenerateTestsMusic first` }
            return { ok: true }
        },

        // Lies_audio_probe — one-shot fleet question: does an online AudioContext actually RUN here
        //  (state, and does currentTime tick at WALL-CLOCK rate) and can an AnalyserNode HEAR a tone with
        //   NO output device and NO gesture (the --autoplay-policy flag case)?  If yes to both, the real
        //    delivery-race test can run on the flagged fleet unattended — no human, no gate.  If the
        //     context stays suspended or doesn't tick real-time, the race needs a gesture (the gate).
        //   Pure report — attempts resume() once but never begs; closes the context after ~1.5s.
        async Lies_audio_probe(): Promise<any> {
            if (typeof AudioContext === 'undefined') return { ok: 0, why: 'no AudioContext (jsdom/headless-node)' }
            let ac: AudioContext | null = null
            try {
                ac = new AudioContext()
                const t0 = ac.currentTime
                // resume() PENDS FOREVER on a gestureless tab (autoplay policy resolves it only on a
                //  user gesture) — an un-raced await here deadlocked a caller that held the beliefs
                //   mutex (the Sounditron step-6 wedge).  Race it: after 1s carry on and report the
                //    state honestly ('suspended' IS the answer the probe exists to give).
                try { await Promise.race([ac.resume(), new Promise(r => setTimeout(r, 1000))]) } catch {}
                const state = ac.state
                const osc = ac.createOscillator()
                const an  = ac.createAnalyser(); an.fftSize = 2048
                osc.frequency.value = 440
                osc.connect(an); an.connect(ac.destination)
                osc.start()
                const wall0 = performance.now()
                await new Promise(r => setTimeout(r, 1500))
                const acEl   = ac.currentTime - t0
                const wallEl = (performance.now() - wall0) / 1000
                const buf = new Float32Array(an.fftSize)
                an.getFloatTimeDomainData(buf)
                let sumSq = 0; for (let i = 0; i < buf.length; i++) sumSq += buf[i] * buf[i]
                const rms = Math.sqrt(sumSq / buf.length)
                try { osc.stop() } catch {}
                const realtime = acEl > 0.5 && Math.abs(acEl - wallEl) < 0.4
                return {
                    ok: 1, state,
                    ac_elapsed: +acEl.toFixed(3), wall_elapsed: +wallEl.toFixed(3), realtime: realtime ? 1 : 0,
                    rms: +rms.toFixed(5), heard: rms > 0.001 ? 1 : 0, sampleRate: ac.sampleRate,
                }
            } catch (e) { return { ok: 0, why: String(e) } }
            finally { try { await ac?.close() } catch {} }
        },

        // Musu_gen_testsounds — the MusuGenerateTestsMusic Book's engine: synth every TEST_TONE as a WAV
        //  into testsounds/ — write to the REAL dir (FSA won't follow the static/ symlink).  JUST the WAVs:
        //   a real music collection is a folder of files, no sidecar.  Crate DISCOVERS it by walking the
        //    Wormhole nav (Crate_nav_paths), and the freq↔track map lives in code (TEST_TONES) — so neither
        //     a manifest.json nor a tones.json is needed.  This REPLACES the collection deterministically.
        //      bin_write on the granted share; held by an expecting() ttlilt so Story snaps only once every
        //       file is written.  Needs a writable share (no headless).
        Musu_gen_testsounds(w: TheC): TheC {
            const H = this as House
            // 120s budget (generous): the eight WAV writes now fire as ONE parallel window (below), so the
            //  batch settles in ~a single wormhole round-trip, well under budget — the ceiling only catches a
            //   genuinely dead share.  (The old SERIAL loop cost eight belief-loop beats and overran even 120s
            //    on a freshly-reloaded runner paying the seq-collision retry tax — a live ttlilt in the snap,
            //     no `generated`.  A live ttlilt in ANY snap means an expecting() TIMED OUT — never the normal path.)
            return H.expecting(w, 'gen_testsounds', 120, async () => {
                const nav = H.top_House().o({ A: 'Wormhole' })[0]?.c.nav as any
                // Honest diagnosis: a MISSING nav is "grant a share"; a nav that just lacks bin_write is a
                //  CAPABILITY gap, not a permission one — say which, so a &remoteWormhole runner (share IS
                //   granted, can write text, no binary) isn't told to "open a share" it already has.
                if (!nav)           { w.i({ gen_error: 'no writable share — grant one (open share) first' }); return }
                if (!nav.bin_write) { w.i({ gen_error: `${nav.label ?? 'this backend'} can't write binary yet (remote Wormhole has no bin_write) — run on a local-share runner, or wire bin_write through the wormhole` }); return }
                const dir = 'testsounds'
                // A DEAD share handle (the dir deleted out from under a granted FSA share, or a grant lost
                //  across a reload) makes bin_write HANG — neither resolve nor throw — which used to surface
                //   only as an opaque timed-out ttlilt with zero files.  Bound each write so a stall becomes a
                //    NAMED gen_error (re-open the share), and one bad write can't wedge the whole batch.
                const bounded = (p: Promise<any>, what: string) => Promise.race([
                    p, new Promise((_r, rej) => setTimeout(() => rej(new Error(`${what} did not complete in 15s`)), 15_000)),
                ])
                // ONE window, not a serial round-trip per file.  Over the wormhole each write settles a
                //  belief-loop beat LATER (transport frames ride post_do — a do_fn can't observe a round trip
                //   intra-beat), so eight SERIAL awaits cost eight beats of latency — enough to overrun the
                //    budget once the fresh-reload seq-collision retry tax is added on top.  Fire all eight at
                //     once (each its own corr; the editor drains them serially but the RUNNER waits ONE window,
                //      not eight) so the whole batch settles in ~a single round-trip.  allSettled so a single
                //       dead write names itself in the gen_error without sinking the ones that landed.
                // A live DESCRIPTIVE anchor, stamped BEFORE the first await (this microtask, which drains
                //  before Story's next poll) so EVERY snap taken while the batch is in flight tells the story
                //   — N files being written into `dir` — instead of the bare `ttlilt` it showed before.  The
                //    root cause of "why isn't this rendering": the callback used to stamp nothing until the
                //     very end (`generated`, gated behind ALL eight writes landing after the allSettled await),
                //      so an in-progress or timed-out snap looked empty though the Book was working fine.  Each
                //       write, as it lands, names itself under here (%file_written:<name>), so the anchor's
                //        children ARE the live progress bar — `generating:8` with three %file_written under it
                //         reads "8 wanted, 3 down".  On completion the anchor is retired for the durable
                //          `generated` the witness gates on.  (The general shape — surfacing progress from
                //           inside a mid-flight req rather than a bare hold — is the %see-everywhere sweep
                //            sketched in spec/Story_future_directions.md.)
                const prog = w.i({ generating: TEST_TONES.length, dir })
                const writes = TEST_TONES.map(t => {
                    const name = `${t.artist} - ${t.title}.wav`
                    // the container comes from the ghost's tag writer, so every generated file carries real
                    //  RIFF INFO tags (IART/INAM) that AGREE with its filename — the collection is
                    //   tagged-by-default now, and the census reads tags first, path as fallback.  (The one
                    //    deliberately DISAGREEING file stays MusuHeist's plant — its specialness sharpens.)
                    const body = (H as any).Crate_wav_with_tags(pcm_sine(t.freq, t.secs, undefined, t.amp), 8000, { artist: t.artist, title: t.title })
                    const run = bounded(nav.bin_write(dir, name, body), `bin_write ${name}`)
                        .then(r => { prog.i({ file_written: name }); return r })
                    return { name, run }
                })
                const settled = await Promise.allSettled(writes.map(x => x.run))
                const failed  = writes.filter((_, i) => settled[i].status === 'rejected')
                if (failed.length) {
                    // retire the live anchor and say WHICH writes died (a `stalled:<name>` child each), not a
                    //  bare count — so a re-open/re-grant is targeted, not guesswork.
                    w.drop(prog)
                    const e = w.i({ gen_error: `${failed.length}/${settled.length} writes stalled — the disk share looks dead; re-open/re-grant it (open share) and re-run` })
                    for (const f of failed) e.i({ stalled: f.name })
                    return
                }
                // done: retire the live `generating` anchor and stamp the durable completion the witness gates
                //  on — count, dir, and each file by name — so the SETTLED snap is fully descriptive too.
                //  PROVE the tags landed (not just that writes settled): read ONE file back off the disk and
                //   scan its header for the IART/INAM fourccs — markers only the tagged container carries.
                //    This is the empirical gate for the whole re-tagging: a `generated` row LACKING `tagged`
                //     means the old bare-WAV code ran (a stale module — reload the tab), never a half-write.
                let tagged = 0
                try {
                    const back = await bounded(nav.bin_read(dir, writes[0].name), `bin_read ${writes[0].name}`)
                    const u8 = new Uint8Array(back).slice(0, 512)
                    let head = ''
                    for (let i = 0; i < u8.length; i++) head += String.fromCharCode(u8[i])
                    if (head.includes('IART') && head.includes('INAM')) tagged = 1
                } catch {}
                w.drop(prog)
                const row: any = { generated: settled.length, dir }
                if (tagged) row.tagged = 1
                const g = w.i(row)
                for (const x of writes) g.i({ file_written: x.name })
            })
        },

        // Musu_test_tones — the reference frequency set MusuBounce quantises a measured analyser peak back to
        //  a stable tone label with.  SINGLE source of truth = TEST_TONES (what the generator laid down), so
        //   the collection and the meter can never drift apart.  Just the freqs, ascending.
        Musu_test_tones(): number[] {
            return TEST_TONES.map(t => t.freq).sort((a, b) => a - b)
        },

        // Lies_runner_ask_recv — the runner answers an addr-less CLI's runner_ask (scripts/runner_ask.mjs):
        //  a request/reply RPC over the relay, the real-time twin of become_book + the READ side the
        //   headless runner gave through file-writings, now a live-browser query.  Dispatch by ask.op —
        //    ping  → liveness {role,channel,running}
        //    run   → drive a Book on the wall clock (Lies_become_book_drive) → {accepted,book}
        //    state → the just|now-running verdict (Cred_run_outcome) + the Storyrun phase/n/total
        //    steps → per-Step {n,ok,caveat,dige}
        //    snap  → one Step's got_snap (the live world serialisation — the "examine the writings" read)
        //    rungos→ the held runs, each addressable by uid (the runner "hangs in there" after a run)
        //   Any READ op (steps/snap/snaps/diff/trace) takes an optional ask.uid → served from that run's
        //    FROZEN pins instead of the live This; absent → the live/active run.  `run` hands back the uid.
        //   Reply is a raw {control:'runner_ack',corr} frame down the relay socket (mirrors
        //    Lies_ghost_compile_ack); the relay routes it back to the CLI by corr.  v1 unsigned/trust-
        //     everything like gen_write-when-unconfigured — a run executes already-compiled gen, dev-only
        //      on localhost; signing mirrors ghost_compile once CLUSTER_TRUSTED_PUBS deploys.
        async Lies_runner_ask_recv(w: TheC, frame: any): Promise<boolean> {
            const H    = this as House
            const corr = (frame?.corr ?? frame?.header?.corr) as string | undefined
            const ask  = (frame?.ask ?? {}) as { op?: string, book?: string, n?: number, ns?: number[], on?: boolean, uid?: string, client?: string }
            const op   = ask.op
            if (!corr || !op) return false
            // reactap — the reactivity census, forwarded to the shared handler: NO lease touch (a
            //  census only READS the tree; everything below is run-driving and stays engagement-gated).
            if (op === 'reactap') return (H as any).Lies_reactap_recv(w, frame)
            // who's asking — the client's stable cluster id (ask.client, from .env.cluster-claude) when it
            //  identifies itself, else the relay `from` addr.  Drives the engagement lease (don't-steal).
            const client = String(ask.client ?? frame?.header?.from ?? 'anon')
            let ok = true
            let result: any = {}
            try {
                H.Lies_engage_touch(w, client)   // any activity from the holder keeps its lease alive
                if (op === 'ping') {
                    const sr = H.Lies_rungo_record(w)
                    result = {
                        role:    H.Lies_is_runner(w) ? 'runner' : 'editor',
                        channel: H.Lies_channel_live(w) ? 'up' : 'down',
                        running: sr ? { book: sr.sc.Storyrun, phase: sr.sc.phase, uid: sr.sc.uid } : null,
                        favourite_client: (H.top_House().c.favourite_client as string) ?? '',
                        engagement: H.Lies_engagement(w) ?? null,   // who holds the lease (don't-steal)
                        // identity + advertise diagnostics.  self = the ADDRESSABLE prepub we advertise as
                        //  (Lies_self: the ?I= %Identity, else the stashed/env cluster key behind the relay
                        //   hello) — NOT Clustation_self, which is null for a stashed/env-key runner that is
                        //    nonetheless fully addressable + now advertising.  No prepub ⇒ truly no identity
                        //     (can't be individuated).  advertising = would the beacon fire now.
                        self:           (H as any).Lies_self?.(w)?.prepub ?? null,
                        advertising:    !!(H.Lies_is_runner(w) && H.Lies_channel_live(w) && (H as any).Lies_self?.(w)?.prepub),
                        last_advertise: (w.c.last_advertise as number) ?? null,
                        clustation_self: (H as any).Clustation_self?.()?.prepub ?? null,   // the active %Identity's ?I= face — null iff on a stashed/env key (no ?I=); a split from `self` is the signal
                    }
                } else if (op === 'probe') {
                    result = await H.Lies_audio_probe()   // real-audio one-shot: real-time? analyser-heard? (fleet capability)
                } else if (op === 'run') {
                    // engage the runner for THIS client first (the don't-steal gate): refuse if another
                    //  client holds a live lease; else stamp our lease (GC'ing any prior client's runs) and
                    //   drive the Book.  Hand back the fresh run's uid — the addressable `@uid` handle the
                    //    CLI keeps for snap/diff/trace once it lands (the record opens now, the run is async).
                    if (!ask.book) { ok = false; result = { error: 'run needs a Book' } }
                    else {
                        const chk = H.Lies_engage_check(w, client)
                        if (!chk.ok) { ok = false; result = { error: chk.reason, engagement: H.Lies_engagement(w) ?? null } }
                        else {
                            H.Lies_engage(w, client, ask.book)
                            H.Lies_become_book_drive(w, ask.book, !!ask.needAC, !!ask.needsFSA)   // CLI-carried caps → secure AC / gate FSA pre-run (it read Credence for us)
                            result = { accepted: true, book: ask.book, uid: H.Lies_rungo_record(w)?.sc.uid ?? null, engaged: client, needAC: !!ask.needAC, needsFSA: !!ask.needsFSA }
                        }
                    }
                } else if (op === 'release') {
                    // a clean hang-up: mark the lease released (kept, so "was it you?" still answers), GC the
                    //  runs, and tear the Story world down to H:Mundo — the runner idles, reusable by anyone.
                    H.Lies_engage_release(w, client)
                    result = { released: 1, engagement: H.Lies_engagement(w) ?? null }
                } else if (op === 'state') {
                    const sr = H.Lies_rungo_record(w)
                    result = {
                        outcome: (H as any).Cred_run_outcome() ?? null,
                        run: sr ? { book: sr.sc.Storyrun, phase: sr.sc.phase, uid: sr.sc.uid, n: sr.sc.n ?? null, total: sr.sc.total ?? null, done: sr.sc.done ?? null } : null,
                        engagement: H.Lies_engagement(w) ?? null,
                    }
                } else if (op === 'rungos') {
                    // the runs the runner is "hanging in there" with — each addressable by uid.  pinned =
                    //  how many step snaps are frozen on it (0 = still live / not yet landed); active marks
                    //   the one the no-uid reads follow.
                    result = { rungos: (w.o({ Storyrun: 1 }) as TheC[]).map(s => ({
                        uid: s.sc.uid, book: s.sc.Storyrun, phase: s.sc.phase,
                        n: s.sc.n ?? null, total: s.sc.total ?? null, done: s.sc.done ?? null,
                        pinned: s.c.pins ? Object.keys(s.c.pins).length : 0,
                        active: s.sc.uid === w.c.active_rungo ? 1 : 0,
                    })) }
                } else if (op === 'retain') {
                    // keep middle steps' got_snap inspectable on a churning runner: set the Story world's
                    //  keep_snaps, which suppresses the 5-step got_snap trim (Story.svelte:2008).  Rides
                    //   w:Story.c (long-lived — survives resetStory), so `retain on` once sticks across runs.
                    const stW = H.Lies_runner_story_w()
                    if (!stW) { ok = false; result = { error: 'no Story world yet — run a Book first' } }
                    else {
                        const on = ask.on !== false   // default on
                        if (on) stW.c.keep_snaps = 1; else delete stW.c.keep_snaps
                        result = { retain: on ? 1 : 0 }
                    }
                } else if (op === 'accept') {
                    // re-record from the LIVE runner: fire the same Accept-All the UI button does
                    //  (Storui's i_elvisto 'story_accept_all') — every !ok step's live got_snap is promoted
                    //   to the canonical NNN.snap and story_save writes it into the Book's wormhole dir.
                    //    Closes the headless-only re-record gap (CLAUDE.md bans the Story_cli bubble): a
                    //     Lake* gate now records against the real runner it must match.  Deferred (elvis),
                    //      so the accept lands a tick later — re-run the Book to verify green.  Run one first.
                    const stW = H.Lies_runner_story_w()
                    if (!stW) { ok = false; result = { error: 'no Story world yet — run a Book first' } }
                    else {
                        const This = stW.c.This as TheC | undefined
                        const bad  = (This ? (This.o({ Step: 1 }) as TheC[]) : []).filter(s => !s.sc.ok || s.sc.disk_ok === false)
                        H.i_elvisto('Story/Story', 'story_accept_all', {})
                        result = { accepting: bad.length, book: (stW.sc.Book as string) ?? null, note: 'dispatched — re-run to verify' }
                    }
                } else if (op === 'steps' || op === 'snap' || op === 'diff' || op === 'snaps' || op === 'trace') {
                    // the READ ops, served from ONE uniform per-step view: ask.uid → the record's frozen
                    //  pins (a past run that's "hanging in there"); no uid → the live This.  So every read
                    //   below is uid-agnostic — point it at a held run or the running one with the same code.
                    const rec   = H.Lies_rungo_record(w, ask.uid)
                    const book  = rec?.sc.Storyrun ?? null
                    const uid   = rec?.sc.uid ?? null
                    const steps = H.Lies_rungo_steps(w, ask)
                    if (ask.uid && !steps.length) {
                        // a uid that matches a record but has no pins = the run is still going (pins land at
                        //  verdict); a uid that matches nothing = a typo, or a GC'd run — if a hang-up/re-engage
                        //   reaped it, say so (and by whom + when), not a bare miss.
                        ok = false
                        const gc = H.top_House().c.last_gc as { by?: string, at?: number } | undefined
                        result = rec
                            ? { error: `run "${ask.uid}" (${rec.sc.Storyrun}) is ${rec.sc.phase} — not pinned yet; drop @uid for the live run, or wait for it to land` }
                            : (gc
                                ? { error: `run "${ask.uid}" was garbage-collected — the runner was re-engaged${gc.by ? ` by ${String(gc.by).slice(0, 8)}` : ''}${gc.at ? ` ${Math.round((Date.now() - gc.at) / 1000)}s ago` : ''}; its snaps are gone (try op:rungos for current runs)` }
                                : { error: `no held run "${ask.uid}" (try op:rungos)` })
                    }
                    else if (op === 'steps') {
                        // desc joins from the The side (the toc step line) — Book-stable, so the same
                        //  join serves a held uid's pins and the live run alike.  Raw C read, not a
                        //   Story method (those live on the Story House, not this one).
                        const stW = H.Lies_runner_story_w()
                        const the_steps = ((stW?.c.The as TheC | undefined)?.o({ step: 1 }) ?? []) as TheC[]
                        const desc_of = (n: number) => the_steps.find(s => s.sc.step === n)?.sc.desc
                        result = {
                            book, uid,
                            steps: steps.map(s => ({ n: s.n, ok: s.ok, caveat: s.caveat, untried: s.untried, error: s.error, dige: s.dige, desc: desc_of(s.n) })),
                            done: steps.length, ok: steps.length > 0 && steps.every(s => !!s.ok),
                        }
                    } else if (op === 'snaps') {
                        // atomic multi-step read: every requested got_snap from ONE view, so a temporal pair
                        //  (diff n prev) is coherent even while the runner churns between calls.  On a uid the
                        //   pins are already frozen, so the pair is doubly stable.
                        const snaps: Record<number, any> = {}
                        for (const n of (Array.isArray(ask.ns) ? ask.ns : []).map(Number)) {
                            const s = steps.find(st => st.n === n)
                            snaps[n] = s ? { n, ok: s.ok, dige: s.dige, got_snap: s.got_snap } : null
                        }
                        result = { book, uid, snaps }
                    } else {
                        const s = steps.find(st => st.n === Number(ask.n))
                        if (!s) { ok = false; result = { error: `no Step ${ask.n}`, have: steps.map(st => st.n) } }
                        else if (op === 'snap') result = { n: s.n, ok: s.ok, dige: s.dige, got_snap: s.got_snap }
                        else if (op === 'trace') {
                            // the step's "why", not just OK|NOT-OK: the beliefs-cycle trace carries the
                            //  quiescent label (causal vs timeout — what held the step) + the cycle walk.
                            result = { n: s.n, ok: s.ok, caveat: s.caveat, dige: s.dige, cycles: s.trace?.length ?? 0, trace: s.trace }
                        } else {
                            // diff: got + the expected, BOTH over the wire (1c).  exp_snap is the per-step
                            //  view's value = Step.sc.exp_snap (UI lazy load) ?? w:Story.c.exp_snaps[n] (the
                            //   check-mode preload, every step in memory).  So a diskless CLI needs no
                            //    `wormhole/` fixture; the CLI still falls back to disk only if exp is null
                            //     (a non-check run, or a Book with no fixture for that step).
                            result = { n: s.n, ok: s.ok, dige: s.dige, book, uid, got_snap: s.got_snap, exp_snap: s.exp_snap }
                        }
                    }
                } else if (op === 'assertions') {
                    // the CONTRACT vs the EVIDENCE (Seen_split rulings 2026-07-18): contract = toc
                    //  `The/step=N/%Assertion` children (+ the flat legacy bucket during the churn);
                    //   evidence = the ave/%Assertioning,Story:<book> shelf where story_harvest_sworn
                    //    lands every latched %sworn — n: the first-latch step, c.microsnap what the
                    //     assertion pointed at, encoded at go-off time.  Uncontracted evidence rides
                    //      too (the achievements).  Raw C reads — Story methods live on another House.
                    const stW = H.Lies_runner_story_w()
                    if (!stW) { ok = false; result = { error: 'no Story world yet — run a Book first' } }
                    else {
                        const The  = stW.c.The as TheC | undefined
                        const book = (stW.sc.Book as string) ?? null
                        const contract: any[] = []
                        for (const st of (The?.o({ step: 1 }) ?? []) as TheC[])
                            for (const a of st.o({ Assertion: 1 }) as TheC[])
                                contract.push({ slug: a.sc.Assertion, sentence: a.sc.sentence, n: st.sc.step })
                        for (const a of ((The?.o({ Assertions: 1 })[0]?.o({ Assertion: 1 }) ?? []) as TheC[]))
                            contract.push({ slug: a.sc.Assertion, sentence: a.sc.sentence, n: Number(a.sc.by_n) || 0, legacy: 1 })
                        const shelf = (stW.c.ave as TheC | undefined)?.o({ Assertioning: 1, Story: book })[0] as TheC | undefined
                        const sworn = ((shelf?.o({ sworn: 1 }) ?? []) as TheC[]).map(s => ({
                            sentence: s.sc.sworn, n: s.sc.n,
                            microsnap: ((s.c as any).microsnap as string) ?? null,
                            contracted: contract.some(c => c.sentence === s.sc.sworn) ? 1 : 0,
                        }))
                        const gaps = contract.filter(c => c.sentence && !sworn.some(s => s.sentence === c.sentence))
                        result = { book, contract, sworn, gaps }
                    }
                } else if (op === 'shot') {
                    // a live PNG of the Cyto canvas (scripts/runner_shot.mjs).  The ONE fault class a
                    //  snap can NOT carry: pixels never round-trip a fixture, so a headless caller could
                    //   never SEE cells-not-drawn / everything-Stuffing / the diagonal collapse.  cy is
                    //    stashed on top_House by Cytui onMount; the base64 rides straight back on the ack.
                    const cy = (H.top_House().c as any).cy
                    if (!cy || typeof cy.png !== 'function') { ok = false; result = { error: 'no Cytoscape canvas — is a useCyto Book mounted + this tab reloaded since the shot handler landed?' } }
                    else {
                        const a = ask as any   // shot-only knobs, off the typed ask
                        const png = cy.png({ output: 'base64', bg: a.bg ?? '#111', full: a.full !== false, scale: a.scale ?? 1, maxWidth: a.maxWidth ?? 1600, maxHeight: a.maxHeight })
                        result = { png, full: a.full !== false, w: cy.width(), h: cy.height(), nodes: cy.nodes().length, edges: cy.edges().length,
                            diag_cures: ((H.top_House().c as any).cy_diag_cures as number) ?? 0,   // the diagonal-satan tally (Cytui diag_check) — >0 = it appeared and was auto-cured
                            render: ((H.top_House().c as any).cy_render as any) ?? null }            // the over-time model→cells telemetry (Cytui vlog) — the film strip beside the frame
                    }
                } else if (op === 'why') {
                    // the render pipeline's over-time story (scripts/runner_shot.mjs --why): what turned
                    //  the model into cells since the last layout settle — the gate + its inputs + a ring
                    //   of wave/armed/remorph/morph/settle/diag events.  Render-side telemetry (NEVER
                    //    snapped — metaphysics #2), the Cyto twin of reactap; mirrored on top_House.c by
                    //     Cytui's vlog.  A `stuff:0` wave every beat = an empty world (the seed never fired).
                    const cr = (H.top_House().c as any).cy_render
                    if (!cr) { ok = false; result = { error: 'no render telemetry — is a useCyto Book mounted + the tab reloaded since this landed?' } }
                    else result = cr
                } else if (op === 'svg') {
                    // the GLASS itself (scripts/runner_shot.mjs --svg): serialize the voronoi SVG layer —
                    //  cells, tuple regions, sub-graph labels — the layer cy.png() can never carry (it
                    //   captures only the cy canvas).  The component's scoped CSS is baked in (every rule
                    //    mentioning a cytui-/vsub- selector rides an embedded style block, and the svelte
                    //     scoping classes travel on the elements), xmlns + explicit size added, so the
                    //      file stands alone in a viewer — AND the text stays TEXT, so a headless caller
                    //       can grep geometry + labels instead of eyeballing pixels.
                    //  A tab can hold MORE THAN ONE voronoi svg (an HMR-lingering mount, a second
                    //   Cytui face) — prefer the one actually SPEAKING (most <text> labels), then
                    //    the most-populated; `cands` reports every candidate's children/labels so a
                    //     wrong pick is visible from the caller side instead of a silent blank glass.
                    const cands = Array.from(document.querySelectorAll('svg.cytui-voronoi')) as SVGSVGElement[]
                    const el = cands.sort((a, b) =>
                        (b.querySelectorAll('text').length - a.querySelectorAll('text').length)
                        || (b.childElementCount - a.childElementCount))[0]
                    if (!el || !el.childElementCount) { ok = false; result = { error: 'no populated .cytui-voronoi svg — is a useCyto Book mounted with ◈ armed?' } }
                    else {
                        let css = ''
                        for (const sh of Array.from(document.styleSheets)) {
                            let rules: CSSRuleList | undefined
                            try { rules = sh.cssRules } catch { continue }   // cross-origin sheet — none of ours
                            for (const r of Array.from(rules ?? []))
                                if (/cytui-voronoi|cytui-veil|cytui-subgraph|vsub-/.test((r as CSSStyleRule).selectorText ?? '')) css += r.cssText + '\n'
                        }
                        const wpx = Math.round(el.clientWidth || el.getBoundingClientRect().width)
                        const hpx = Math.round(el.clientHeight || el.getBoundingClientRect().height)
                        const svg = `<svg xmlns="http://www.w3.org/2000/svg" class="${el.getAttribute('class') ?? ''}"`
                            + ` width="${wpx}" height="${hpx}" viewBox="0 0 ${wpx} ${hpx}"`
                            + ` style="background:#070707;font-family:ui-monospace,monospace;font-size:11px">`
                            + `<style>${css}</style>${el.innerHTML}</svg>`
                        const cr = (H.top_House().c as any).cy_render
                        result = { svg, w: wpx, h: hpx,
                            paths: el.querySelectorAll('path').length, labels: el.querySelectorAll('text').length,
                            groups: el.querySelectorAll('.cytui-subgraph').length,     // vsub <g> in THIS svg's DOM
                            state_vsubs: cr?.vsubs ?? null,                            // the render's own vsubs count
                            svgs: cands.length,
                            cands: cands.map(c => `${c.childElementCount}c/${c.querySelectorAll('text').length}t`) }
                    }
                } else if (op === 'face') {
                    // the remote FACE-ARM (runner_shot --arm): flip this tab's ◈/▧/▦ prefs so a
                    //  headless caller can SEE a face nobody armed here — the prefs are per-tab
                    //   stashes, unreachable from outside before this.  The hook is Cytui's
                    //    (top_House.c.cy_face, exposed beside .cy); an old tab says so honestly.
                    const fn = (H.top_House().c as any).cy_face
                    if (typeof fn !== 'function') { ok = false; result = { error: 'no cy_face hook — this tab runs an old Cytui; reload it' } }
                    else result = fn((ask as any).faces ?? { voronoi: 1, regions: 1, subgraph: 1 })
                } else if (op === 'reload') {
                    // the remote TAB RELOAD — the fleet's wedge-healer.  Every "tab broken" class
                    //  (HMR-wedged template flush, dead Vite socket, frozen-boot husk) ends the same
                    //   way: reload the tab — which until now only the human at the browser could do.
                    //    RUNNER TABS ONLY: an editor holds the human's live work, a machine must not
                    //     reload it out from under them.  Reply rides out first; the reload follows a
                    //      breath later so the ack survives the socket.
                    if (!H.Lies_is_runner(w)) { ok = false; result = { error: 'not a runner — refusing to reload an editor tab' } }
                    else { result = { reloading: true }; setTimeout(() => location.reload(), 400) }
                } else { ok = false; result = { error: `unknown op ${op}` } }
            } catch (e) { ok = false; result = { error: String((e as Error).message) } }
            const port = (w.o({ transport: 1, type: 'websocket' })[0] as TheC | undefined)?.c.port as any
            const ws   = port?.ws as any
            if (ws && ws.readyState === 1 /* OPEN */) {
                try { ws.send(JSON.stringify({ control: 'runner_ack', corr, op, ok, result })) } catch { /* CLI falls back to timeout */ }
            }
            H.tlog(`📥 runner_ask ${op}${ask.book ? ` ${ask.book}` : ''} → ${ok ? 'ok' : 'err'}`)
            return true
        },

        // Lies_reactap_recv — the REACTIVITY census (scripts/reactap.mjs): arm the Stuff.svelte.ts
        //  bump tap (REACTAP) for a bounded window, then report which particles' versions moved —
        //   per-habitat (nearest Waft) totals + the top bumpers, each with the first-sighting stack
        //    naming WHO bumps it.  For chasing idle churn: over an idle window a fat count IS the
        //     re-render driver.
        //  Rides the runner_ask/runner_ack corr rails (relay.ts corr-remembers only ghost_compile +
        //   runner_ask asks; an own frame type would mean a relay edit + dev-server restart) — the
        //    EDITOR registers on('runner_ask') serving ONLY this op (LiesLies), the runner forwards
        //     op:'reactap' here from Lies_runner_ask_recv.  No engagement lease: a census only reads.
        //  The report walk reads X.z raw OFF the beliefs mutex — a mid-transaction replace() could
        //   momentarily hide a subtree and mislabel a path.  Diagnostics-grade; acceptable.
        async Lies_reactap_recv(w: TheC, frame: any): Promise<boolean> {
            const H    = this as House
            const corr = (frame?.corr ?? frame?.header?.corr) as string | undefined
            if (!corr) return false
            const ms = Math.min(Math.max(Number(frame?.ask?.ms ?? 5000), 250), 30000)
            let ok = true
            let result: any = {}
            try {
                if (REACTAP.on) { ok = false; result = { error: 'a reactap window is already armed' } }
                else {
                    REACTAP.counts = new Map(); REACTAP.thinks = 0; REACTAP.on = 1
                    await new Promise(r => setTimeout(r, ms))
                    REACTAP.on = 0
                    const counts = REACTAP.counts!; REACTAP.counts = null
                    // parent map — ONE walk down the C tree (X.z = the member rows) from Mundo + the
                    //  watch channels (H.ave & co are roots of their own, beside the Mundo tree).
                    const roots: any[] = [H.top_House(), (H as any).ave, (H as any).UIs, (H as any).actions, (H as any).graph].filter(Boolean)
                    const parent = new Map<any, any>()
                    const seen = new Set<any>(roots)
                    const walk = [...roots]
                    while (walk.length) {
                        const n = walk.pop()
                        for (const ch of (n?.X?.z ?? [])) {
                            if (!ch?.sc || seen.has(ch)) continue
                            seen.add(ch); parent.set(ch, n); walk.push(ch)
                        }
                    }
                    const label = (n: any) => {
                        const k = n?.sc ? Object.keys(n.sc)[0] : undefined
                        if (!k) return '?'
                        const v = n.sc[k]
                        return v === 1 || v == null ? `%${k}` : `${k}:${String(v).slice(0, 32)}`
                    }
                    const path = (n: any) => {
                        const parts = [label(n)]
                        for (let p = parent.get(n), d = 0; p && d < 12; p = parent.get(p), d++) parts.unshift(label(p))
                        return parts.join('/') + (seen.has(n) ? '' : ' (off-tree)')
                    }
                    // habitat — the census rollup: WHICH WAFT keeps bumping.  Nearest Waft ancestor;
                    //  else the nearest w; else the topmost label (H:Mundo | a watch channel | off-tree).
                    const habitat = (n: any) => {
                        let w_ = '', root = label(n)
                        for (let p = n, d = 0; p && d < 24; p = parent.get(p), d++) {
                            if (p.sc?.Waft) return 'Waft:' + p.sc.Waft
                            if (p.sc?.w) w_ = label(p)
                            root = label(p)
                        }
                        return w_ || (seen.has(n) ? root : '(off-tree)')
                    }
                    // the sample stack, trimmed to the caller frames: drop the tap's own, strip the
                    //  dev-server origin + the vite ?t= cache-bust so lines read file.svelte:line:col.
                    const frames = (s?: string) => (s ?? '').split('\n')
                        .filter(l => / at /.test(' ' + l) && !/bump_version|REACTAP|Xify/.test(l))
                        .slice(0, 4)
                        .map(l => l.trim().replace(/https?:\/\/[^/\s]+/g, '').replace(/\?t=\d+/g, ''))
                    const rows = [...counts.entries()]
                        .map(([n, e]) => ({ count: e.count, path: path(n), habitat: habitat(n), who: frames(e.stack) }))
                        .sort((a, b) => b.count - a.count)
                    const wafts: Record<string, number> = {}
                    for (const r of rows) wafts[r.habitat] = (wafts[r.habitat] ?? 0) + r.count
                    result = {
                        ms, thinks: REACTAP.thinks,
                        bumps: rows.reduce((s, r) => s + r.count, 0),
                        particles: rows.length,
                        wafts: Object.entries(wafts).sort((a, b) => b[1] - a[1]).map(([habitat, count]) => ({ habitat, count })),
                        rows: rows.slice(0, 60),
                        dropped: Math.max(0, rows.length - 60),   // no silent caps — the CLI narrates
                    }
                }
            } catch (e) {
                ok = false; result = { error: String((e as Error)?.message ?? e) }
                REACTAP.on = 0; REACTAP.counts = null
            }
            const port = (w.o({ transport: 1, type: 'websocket' })[0] as TheC | undefined)?.c.port as any
            const ws   = port?.ws as any
            if (ws && ws.readyState === 1 /* OPEN */) {
                try { ws.send(JSON.stringify({ control: 'runner_ack', corr, op: 'reactap', ok, result })) } catch { /* CLI falls back to timeout */ }
            }
            H.tlog(`📥 reactap ${ms}ms → ${ok ? `${result.bumps} bumps / ${result.particles} particles / ${result.thinks} thinks` : `err ${result.error}`}`)
            return true
        },

        // ── runner engagement: the loose, EXCLUSIVE lease a client holds over a runner (the "don't run
        //   into each other's runners" gate).  A singular `Engagement` PARTICLE on Mundo —
        //    `top/Engagement,client,status,at,of_Book` (of_$k convention) — VISIBLE in the tree, not a
        //     hidden .c blob: whose-runner-this-is is meant to be observable.  A child of Mundo, so it
        //      outlives a Story_reset — a hang-up tears down the run, not the representation.  Exclusive
        //       by VISIBILITY (others see whose it is), not a hard lock: easy to break out of, the
        //        completed Storyrun objects are the durable truth, the orchestrator handles contention.
        //         status: 'active'|'released' (+ 'timed_out' folded in lazily — no timer, an 'active'
        //          lease older than the TTL (10min, room for Claude to think between runs) reads stale,
        //           so a new client may take it).  favourite_client is the SEPARATE soft-prefer (→ the
        //            Waft:Cluster/%HostedIdentity registry, the Lies-agent's); this is the don't-steal.
        Lies_engage_ttl(): number { return 10 * 60 * 1000 },   // the think-between-runs window

        // Lies_engage_c — the singular Engagement particle on Mundo (find; mint when create=true).
        Lies_engage_c(create = false): TheC | undefined {
            const top = (this as House).top_House()
            const e = top.o({ Engagement: 1 })[0] as TheC | undefined
            if (e || !create) return e
            const fresh = top.i({ Engagement: 1 }) as TheC
            top.bump_version()
            return fresh
        },

        // Lies_engagement — the lease as the runner sees it NOW, with timed_out folded in (read-only).
        Lies_engagement(w: TheC): { client: string, status: string, at: number, book?: string, age_ms: number, stale: boolean } | undefined {
            const H = this as House
            const e = H.Lies_engage_c()
            const client = e?.sc.client as string | undefined
            if (!e || !client) return undefined
            const at     = Number(e.sc.at ?? 0)
            const status = (e.sc.status as string) || 'active'
            const book   = e.sc.of_Book as string | undefined
            const age    = Date.now() - at
            const stale  = status === 'active' && age > H.Lies_engage_ttl()
            return { client, status: stale ? 'timed_out' : status, at, book, age_ms: age, stale }
        },

        // Lies_engage_check — may `client` take the runner now?  Free unless ANOTHER client holds a
        //  still-live (non-stale) active lease.  released | timed_out | same-client all → free.
        Lies_engage_check(w: TheC, client: string): { ok: boolean, reason?: string } {
            const H = this as House
            const e = H.Lies_engagement(w)
            if (!e || e.status !== 'active' || e.client === client) return { ok: true }
            const left = Math.max(0, H.Lies_engage_ttl() - e.age_ms)
            return { ok: false, reason: `runner busy — engaged by ${String(e.client).slice(0, 8)} ${Math.round(e.age_ms / 1000)}s ago${e.book ? ` (${e.book})` : ''}; frees in ${Math.ceil(left / 60000)}m if idle` }
        },

        // Lies_engage — stamp client's active lease.  If the client CHANGED, GC the prior client's runs
        //  (their uids go unreachable → the GC'd-run message) so the newcomer starts clean.
        Lies_engage(w: TheC, client: string, book?: string): void {
            const H  = this as House
            const ec = H.Lies_engage_c(true)!
            const prev = ec.sc.client as string | undefined
            if (prev && prev !== client) H.Lies_engage_gc(w, prev)
            ec.sc.client = client
            ec.sc.status = 'active'
            ec.sc.at     = Date.now()
            if (book) ec.sc.of_Book = book; else delete ec.sc.of_Book
            H.top_House().bump_version()
        },

        // Lies_engage_touch — heartbeat: any activity from the holder refreshes the lease clock, so it
        //  only times out after the TTL of genuine silence.  No-op from a non-holder.  No bump — a clock
        //   nudge read on demand by the next runner_ask, not a structural change worth a snap.
        Lies_engage_touch(w: TheC, client: string): void {
            const e = (this as House).Lies_engage_c()
            if (e && e.sc.client === client && e.sc.status === 'active') e.sc.at = Date.now()
        },

        // Lies_engage_release — a clean hang-up: mark released (KEPT, so "was it you?" still answers),
        //  GC the runs, and tear the Story world down to H:Mundo via quitStory.  The runner idles, reusable.
        Lies_engage_release(w: TheC, client: string): void {
            const H = this as House
            const e = H.Lies_engage_c()
            if (!e || e.sc.client !== client) return
            e.sc.status = 'released'
            e.sc.at     = Date.now()
            H.top_House().bump_version()
            H.Lies_engage_gc(w, client)
            H.top_House().i_elvisto('Auto/Auto', 'quitStory', {})
        },

        // Lies_engage_gc — drop every held run-record (+ its pins) and record WHO triggered it, so a
        //  later `@uid` on a vanished run gets a precise "garbage-collected by <who>" message, not a miss.
        //   (last_gc stays a transient .c breadcrumb — diagnostic, not lease state; the Engagement
        //    particle is overwritten with the new client the same tick.)
        Lies_engage_gc(w: TheC, by: string): void {
            for (const s of w.o({ Storyrun: 1 }) as TheC[]) w.drop(s)
            delete w.c.active_rungo
            ;(this as House).top_House().c.last_gc = { by, at: Date.now() }
        },

        // Lies_runner_story_w — the live w:Story world (where This/Steps + the run state live, the same
        //  nav Cred_run_outcome walks).  null before any run.  Long-lived (survives resetStory), so
        //   keep_snaps rides here.  for runner_ask retain/state/steps/snap.
        Lies_runner_story_w(): TheC | undefined {
            const H     = this as House
            const story = H.o({ H: 'Story' })[0] as House | undefined
            return story?.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0] as TheC | undefined
        },

        // Lies_runner_this — the live Story This container (where each Step's got_snap/ok lands).  Read-only.
        Lies_runner_this(): TheC | undefined {
            return (this as House).Lies_runner_story_w()?.c.This as TheC | undefined
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
        //    as steps land) → done|failed.  This is the durable CLIENT that holds each step's feedback —
        //     not the fire-and-forget blip the under-designed rungo/become_book pair shipped before.
        //   Each record carries a short `uid` — the addressable handle the CLI talks to (runner_ask
        //    `@uid`): after the run lands, Lies_runner_verdict PINS the produced step snaps onto the
        //     record (sr.c.pins, off-snap), so the run "hangs in there" and stays queryable by uid even
        //      as later runs churn the live This.  We keep a bounded HISTORY (last KEEP finished) so a
        //       few past runs stay addressable, and drop any stale never-finished record (superseded).
        //        active_rungo marks the live one — the no-uid reads (ping/state) follow it.
        Lies_runner_begin(w: TheC, ident: string): TheC {
            const KEEP = 3
            for (const old of w.o({ Storyrun: 1 }) as TheC[]) {
                const fin = old.sc.phase === 'done' || old.sc.phase === 'failed'
                if (!fin) w.drop(old)                                  // a superseded begun/stepping — drop
            }
            const held = w.o({ Storyrun: 1 }) as TheC[]               // re-read: the finished survivors
            for (const old of held.slice(0, Math.max(0, held.length - (KEEP - 1)))) w.drop(old)   // oldest beyond cap
            const uid = (globalThis.crypto?.randomUUID?.() ?? `r${Date.now()}`).replace(/-/g, '').slice(0, 8)
            const sr = w.i({ Storyrun: ident, uid, phase: 'begun', at: Date.now() }) as TheC
            w.c.active_rungo = uid
            return sr
        },

        // Lies_rungo_record — the addressable run-record.  A uid (PREFIX-matched, so the CLI can type the
        //  first few chars) picks a held one; absent picks the active/latest.  null if none yet.
        Lies_rungo_record(w: TheC, uid?: string): TheC | undefined {
            const all = w.o({ Storyrun: 1 }) as TheC[]
            if (uid) return all.find(s => String(s.sc.uid ?? '').startsWith(uid))
            const act = w.c.active_rungo as string | undefined
            return (act && all.find(s => s.sc.uid === act)) || all[all.length - 1]
        },

        // Lies_rungo_steps — the uniform per-step view {n,ok,caveat,dige,got_snap,exp_snap,trace} the
        //  read ops (steps/snap/snaps/diff/trace) share.  With ask.uid: serve the record's FROZEN pins
        //   (deterministic — survives the live This churn + the 5-step trim).  Without: the live This
        //    (a run still going, or the just-finished one before the next begin).  Empty when a uid is
        //     given but the run isn't pinned yet (still running / unknown uid) — the caller errors.
        Lies_rungo_steps(w: TheC, ask: { uid?: string }): Array<{ n: number, ok: number, caveat: number, dige: any, got_snap: any, exp_snap: any, trace: any }> {
            const H = this as House
            if (ask.uid) {
                const pins = H.Lies_rungo_record(w, ask.uid)?.c.pins as Record<number, any> | undefined
                return pins ? Object.values(pins) : []
            }
            // exp source (1c — over the wire, no disk): w:Story.c.exp_snaps is the check-mode preload —
            //  EVERY step's expected, read into memory ONCE at run start (Story.svelte:1451), so the diff's
            //   expected travels the socket with no `wormhole/` fixture on the CLI side.  Per-step
            //    `Step.sc.exp_snap` (the UI diff-panel's lazy load) wins when present; else the Record.
            const stW   = H.Lies_runner_story_w()
            const exps  = (stW?.c.exp_snaps ?? {}) as Record<number, string | null>
            const steps = ((stW?.c.This as TheC | undefined)?.o({ Step: 1 }) ?? []) as TheC[]
            return steps.map(s => {
                const n = Number(s.sc.Step)
                return {
                    n, ok: s.sc.ok ? 1 : 0, caveat: s.sc.caveat ? 1 : 0, dige: s.sc.dige,
                    untried: s.sc.untried ? 1 : 0, error: s.sc.error ?? null,
                    got_snap: s.sc.got_snap ?? null, exp_snap: s.sc.exp_snap ?? exps[n] ?? null,
                    trace: Array.isArray(s.sc.Run_trace) ? s.sc.Run_trace : null,
                }
            })
        },

        // Lies_runner_track — fold a transient progress blip onto the durable Storyrun record (the
        //  runner-side noun a rungo / become_book produces; opened by Lies_runner_begin).  Maps the
        //   blip arc onto a settled phase + n/total so a client reads "running PereStaple, 4/9"
        //    straight off the snap.  No-op when no record is up (a stray blip).
        //   rungo_ack/story_begun → begun; step_done/step_stall → stepping; all_done → all_done
        //    (the verdict stamp in Lies_runner_verdict lands the final done|failed right behind it).
        Lies_runner_track(w: TheC, phase: string, extra?: { n?: number, total?: number }) {
            const sr = (this as House).Lies_rungo_record(w)   // the active run, not a stale history entry
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
            const sr = H.Lies_rungo_record(w)
            if (sr) {
                sr.sc.phase = outcome.ok ? 'done' : 'failed'
                sr.sc.done  = outcome.done
                if (outcome.caveat) sr.sc.caveat = outcome.caveat
                // PIN the produced steps onto the record (off-snap, .c — never encoded, no snap bloat) so
                //  the runner "hangs in there": the CLI can pull this run's snap/diff/trace by uid long
                //   after, even as later runs reset This.  Pins whatever survived the live trim — pair with
                //    `retain on` (keep_snaps) BEFORE a long run to pin every step, not just the last 5.
                const live = (H.Lies_runner_this()?.o({ Step: 1 }) ?? []) as TheC[]
                // capture exp too (1c): exp_snaps is wiped at the NEXT run's toc-load (Story.svelte:1409),
                //  so pin it now or a held @uid diff loses its expected.  string ref, not a copy.
                const exps = (H.Lies_runner_story_w()?.c.exp_snaps ?? {}) as Record<number, string | null>
                if (live.length) {
                    const pins: Record<number, any> = {}
                    for (const s of live) {
                        const n = Number(s.sc.Step)
                        pins[n] = {
                            n, ok: s.sc.ok ? 1 : 0, caveat: s.sc.caveat ? 1 : 0, dige: s.sc.dige,
                            untried: s.sc.untried ? 1 : 0, error: s.sc.error ?? null,
                            got_snap: s.sc.got_snap ?? null, exp_snap: s.sc.exp_snap ?? exps[n] ?? null,
                            trace: Array.isArray(s.sc.Run_trace) ? s.sc.Run_trace : null,
                        }
                    }
                    sr.c.pins = pins
                }
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
            // event-push the verdict onto the Storying cells bound to this result (replaces the
            //  per-tick poll storying_run once was).  A dock run keys of_dock===path; a Book run
            //   keys of_Book===book.  Cheap: only matching cells restamp, and only when one lands.
            H.Lies_call_connected(w, frame.book)   // a verdict is the definitive ack — clears the ☎ if a fast Story's story_begun was dropped
            H.Lies_reflect_storying(w, { path, book: frame.book })
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
            H.Lies_call_connected(w, frame.book)   // any phase blip (story_begun leads) proves the ☎'d call picked up → clear it
            w.c.run_phase = { phase, n: frame.n, total: frame.total, secs: frame.secs, book: frame.book, path: frame.path, seq: frame.seq, at: Date.now() }
            w.bump_version()
            H.tlog(`📥 run_phase: ${phase}${frame.n != null ? ` ${frame.n}/${frame.total ?? '?'}` : ''}${frame.book ? ` [${frame.book}]` : ''}`)
            // Brink-complain (editor): a runner begging for AudioContext pre-run surfaces on the Upkeep
            //  Brink so the operator can go grant it.  awaiting_audio → 🎤 live; any later phase for the
            //   same book settles it (story_begun = secured, audio_blocked = lapsed).  (Which runner: still
            //    the single w.c.run_phase slot — per-runner attribution + the jump-link need the from:<pub> demux.)
            const acKey = `needAC:${frame.book ?? ''}`
            if (phase === 'awaiting_audio') {
                H.Upkeep_errand(acKey, { kind: 'audio', label: frame.book ?? 'runner', phase: 'running' }); H.Lies_upkeep(w)
            } else if ((H.Upkeep_bag() as TheC).oa({ Errand: acKey })) {
                H.Upkeep_errand(acKey, { kind: 'audio', label: frame.book ?? 'runner', phase: phase === 'audio_blocked' ? 'failed' : 'ok' }); H.Lies_upkeep(w)
            }
            return true
        },

        // Lies_call_connected — the runner we rang for `book` has now PROVEN it picked up: a run_phase
        //  blip (story_begun first, then step_done×N) or the final run_result landed.  Clear the ☎
        //   (r.c.sent) on its rack slot at once — it disappears the moment the Story starts, not after
        //    the 30s ring-out.  The advertise path clears it too (a beacon that catches the runner
        //     running the book → ▶), but advertise is a ~15s LAST-WRITER-WINS snapshot: a FAST Story
        //      (e.g. PortPlan, a quick req test) starts AND finishes between beacons, so the snapshot
        //       never catches `book` set and the ☎ rings the full timeout.  A phase|result frame is the
        //        definitive non-coalescing ack; dispatch is 1 book → 1 runner (w.c.rungo_runner sticks),
        //         so match the ☎ by book.
        Lies_call_connected(w: TheC, book?: string): void {
            if (!book) return
            let changed = false
            for (const r of w.o({ Runner: 1 }) as TheC[]) {
                if (r.c.sent === book) { delete r.c.sent; delete r.c.sent_at; changed = true }
            }
            if (changed) w.bump_version()
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
            // %unusual cells (data-migration, test-data-seeding) are skipped by the bulk sweep —
            //  they have side effects too dangerous to run at random.  A deliberate cell CLICK
            //   still runs them (Storying.svelte); only "run all" leaves them alone.
            const walk = (c: TheC) => { for (const k of c.o() as TheC[]) {
                if (k.sc.Funkcion === 'Storying' && k.sc.of_Book && !k.sc.unusual) out.push(k.sc.of_Book as string); walk(k) } }
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

        // Lies_book_needac — does this Book need a live AudioContext?  The durable fact rides its
        //  %Storying cell (Funkcion:Storying,of_Book:<book>,needAC:1 — the Credence board), which a
        //   cell CLICK carries on the event (Storying.svelte) — but a held (Lies_drain_runs) or swept
        //    (StoryTimes) run carries only the Book's name, so those paths re-read the board here at
        //     dispatch time and get the same pre-run securing.  Absent cell ⇒ false (no gate).
        Lies_book_needac(w: TheC, book: string): boolean {
            let found = false
            const walk = (c: TheC) => { for (const k of c.o() as TheC[]) {
                if (k.sc.Funkcion === 'Storying' && k.sc.of_Book === book && k.sc.needAC) { found = true; return }
                walk(k); if (found) return } }
            for (const waft of w.o({ Waft: 1 }) as TheC[]) { walk(waft); if (found) break }
            return found
        },

        // dispatch one become_book the way a Storying Book-cell click does — editor ships the frame,
        //  a bare/co-resident Lies drives locally.
        Lies_storytimes_dispatch(w: TheC, book: string): boolean {
            const H = this as House
            const needAC   = H.Lies_book_needac(w, book)     // the sweep queue holds bare names — the board says which need AC
            const needsFSA = H.Lies_book_needsfsa(w, book)   // …and which need a local FSA share (proxy runners refuse)
            if (H.Lies_is_editor(w)) {
                const pick = H.Lies_dispatch_target(w, needAC, needsFSA)
                if (pick.exhausted) { H.Lies_queue_run(w, book); H.tlog(`⏸ all runners busy — held ${book}`); return false }
                if (pick.to === undefined) {
                    // no live runner yet — HOLD if any is known (post-reconnect fold lag), don't spray all (see e_Lies_become_book)
                    const known = (w.o({ Runner: 1 }) as TheC[]).length
                    const cluster = w.o({ Waft: 'Cluster' })[0] as TheC | undefined
                    const reg = cluster ? (cluster.o({ HostedIdentity: 1 }) as TheC[]).filter(h => h.sc.role === 'runner').length : 0
                    if (known || reg) { H.Lies_queue_run(w, book); H.tlog(`⏸ StoryTimes held — runners known (${known}/${reg}) but none live yet: ${book}`); return false }
                }
                const sent = H.Lies_send_become_book(w, book, pick.to, needAC, needsFSA)
                H.tlog(`🎟 StoryTimes → ${book} ${pick.to ? `@${pick.to.slice(0, 8)}` : '(broadcast — no runner known)'} ${sent ? '(sent)' : '(channel down — no runner)'}`)
                return sent
            }
            H.Lies_become_book_drive(w, book, needAC, needsFSA)      // bare dev Lies with a co-resident Run
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
