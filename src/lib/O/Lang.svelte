<script lang="ts">
    // Lang.svelte — ghost for Language / CodeMirror / Lezer integration.
    //
    // This is the high-level "join" ghost.  Most of the compilation guts live
    // in LangCompiling.svelte (Lang_compile / Lang_compile_step / …); Lang.svelte
    // keeps the per-doc lifecycle (plan / whatsthis / bookmark actions) and
    // threads the compile trigger + reply-polling into that lifecycle.
    //
    // ── Language goals ───────────────────────────────────────────────────────
    //
    //   Receivers (X i …, X o …)
    //     A bareword before the verb is the call receiver:
    //       A i %prefixy:'sivi'   →  A.i({prefixy: 'sivi'})
    //       w i a/b               →  this._i_drill(w, …)   (w made explicit)
    //     JS keywords (return, let, …) are never treated as receivers, so
    //     "let la = i a/b" keeps its "let la = " prefix verbatim.  The older
    //     "$name" leg-0 hint (o $la/x → la.o(…)) still works too.
    //
    //   Captures (name$, name$:var)
    //     A trailing $ on the last leg captures the matched row:
    //       o with$        →  let with = w.o({with:1})[0]
    //       o with$:vish   →  let vish = w.o({with:1})[0]   (named target)
    //     A colon-value after the $ names the target variable rather than
    //     filtering.  Multi-leg captures route through _o_drill1.
    //
    //   let-declaration sugar ($name = expr)
    //       $its = 'ferv'   →  let its = 'ferv'
    //     A single "=" (not ==, not +=) after a leading $name declares a local.
    //
    //   Puddle values (%key:'string literal')
    //     % before a PeelKey means the colon-value is a raw TS expression.
    //     Currently StringVal handles 'single', "double", `backtick` strings.
    //     The compiler emits the value verbatim; no exactly filter is applied.
    //     Next: multi-token puddle blocks for arithmetic / function calls.
    //
    //   Ampersand calls (&method,arg,arg,…)
    //     Compiles to this.method(arg,arg,…), bracket/string-aware so object
    //     literal args keep their own commas:
    //       &nothinging,A,w,{x:3}   →  this.nothinging(A,w,{x:3})
    //     Works standalone and inside if/elsif conditions, including the
    //     pythonic colon form (the trailing ":" is dropped — indent marks the
    //     block) and the &&-continuation form:
    //       if &m,A,w:               if &m,A,w
    //           && 6          and        && 6      →  if (this.m(A,w) && 6) {
    //     The arg list is raw text — no inner stho parsing of each arg.
    //
    //   Loosely-binding "and" block (LHS and <io>)
    //       !0 and w i wibble   →  if (!0) { w.i({wibble: 1}) }
    //     LHS becomes the condition; the IO expression is the single-statement
    //     body.  The body side is a block, so it can hold a ";".
    //
    //   async on method defs
    //     "async name(…)" stamps async:1 on the def's word-index entry.  A
    //     future pass can read that index to decide whether a matching &call /
    //     bare call needs an `await` in front.
    //     < the await-injection itself is not wired up yet.
    //
    // ── Deferred / infirm syntax (parses, but not yet compiled) ───────────────
    //
    //   .$ tight value-capture (key.$ , key.$:var , key:val.$)
    //     Intent: "." binds tightly to its key and grabs that key's VALUE
    //     (rather than the whole row), assigning it inline among other peel
    //     items — destructure/tuple style:
    //       o prefixy,with.$:ang   "grab with's value into ang, keep querying"
    //       w i …/so:ont.$         "so is auto-named from the key"
    //     The "." currently produces an error node, so the .$ tail is dropped
    //     and the leg compiles as if it weren't there (valid but incomplete).
    //     Needs a grammar "." token + a PeelItem tail rule before it's safe to
    //     emit — a wrong guess here is worse than none.
    //     < not implemented; emits the leg without the capture.
    //
    //   Block verbs (r / roai / oai / replace with a trailing {} block)
    //     Intent: expose what is normally
    //       await w.r({key:'ing',field:'s'}, {})
    //     as a squishy verb line, e.g.  w r key:ing,field:s {}  and the
    //     multi-leg capture form  w oai docs/doc,$path$dock  (where $path is a
    //     {variable}-style shorthand keyed by its own name, and the trailing
    //     $dock assigns the result to dock).
    //     Open questions before this can land:
    //       · these verbs are async — we'd want the def/method async index
    //         (groundwork above) to know when to inject `await`.
    //       · bareword values: "key:ing" wants 'ing' as a STRING here, which
    //         diverges from the i/o convention where a bareword is an
    //         identifier.  That value-semantics fork is unresolved.
    //       · the $path$dock jammed double-sigil form needs grammar support;
    //         the clean capture today is name$ / name$:var.
    //     < not implemented; the verb set would extend IOness (or a sibling
    //       IOverb token) and reuse the Leg machinery once semantics are fixed.
    //
    // ── Document registry ────────────────────────────────────────────────────
    //
    //   w/{docks: 1}/{dock: path} — one particle per open document.
    //     c: { view, state, addBookmarkMark, clearAllBookmarks, saveEffect,
    //          last_whatsthis_dock }
    //     sc: { doc:path, active:1? }
    //     {bookmark:'bm_…', from, to, label}
    //     {Compile:1}
    //       {Output:1, name, source, dige}
    //       {Pending:1}
    //     {req:'Languish'}        — per-dock mind: text_loaded → compile.
    //
    //   Bookmarks, compile, and Languish live on dock, not w, so they can be r()'d per doc.
    //
    // ── Understanding hold ───────────────────────────────────────────────────
    //
    //   w/{LE:1}                  — one Understanding for the Lang instance; stable.
    //     /%State                 — synthesised: armed/changey/stale
    //     // %push_dirty          — fault; present only when push didn't land clean
    //     /%Seem:origin / /%Seem:working
    //
    //   w/{req:'workon'}          — open-ended; one per Lang instance.
    //     c.src                   latest cursored TheC (stashed by e_Lang_workon_update)
    //     do_fn = req_workon — the thin per-tick driver: roai's each stage
    //       with its input signature (un-finishing a %permanent stage on drift),
    //       then pumps the pipeline.  Invalidation cascades forward through keys.
    //     /{req:'understanding',maz:3,permanent}  — re-arm LE + flush; sets %Interest
    //       c.armed_src            identity-keyed re-arm gate (memoised)
    //       sc.what                cursored What|path label for the snap
    //     /{req:'ingredients',maz:2,permanent}    — the wanted %Goods, from %Interest
    //       /{req:'furnishing',path,permanent}     — one per wanted dock; gate + ttlilt
    //                                                + dock_askies pull.  Finished when
    //                                                its dock has content_dige.
    //     /{req:'instrumentation',maz:1,permanent} — compile + graft on the active dock
    //       sc.have_Map, sc.n_pmirrors          convergence markers (results on dock)
    //
    //   w/{Languinio:1}           — Lang's one focus object enrolled in ave.
    //     c.w                     back-ref to w:Lang
    //     // ordered by volatility — LE arms rarely, dock on doc-switch, Interest on every checkout
    //     /{LE:1}                  — same-object hold → w/{LE:1}; installed at plan.
    //                                Unarmed until first cursor move; readers gate on LE.sc.target.
    //     /{dock:path}             — same-object hold  on the active CM doc.
    //                                Re-pointed by Lang_set_active_dock on every doc switch.
    //     /{Interest:1}            — sc.src = working clone root; c.LE = nav handle.
    //                                c.What = live %What object; sc.in_Doc|in_Point —
    //                                the C-side address mirroring Lies' %Spotlight.
    //                                in_Doc keys ingredients AND selects the active dock.
    //                                Dropped + recreated by Lang_set_interest on each checkout.
    //
    // ── Reactive text sync ───────────────────────────────────────────────────
    //
    //   dock/{Text:1} — one per doc, holds sc.dige, sc.disk_dige, sc.disk_rev.
    //   dock.c.text holds the source string (hidden from snap).
    //   Lang_plan seeds it with default text on first run.
    //   Langui (keyed by `doc` prop) watches its own particle.
    //
    // ── Active doc ───────────────────────────────────────────────────────────
    //
    //   w.c.active_dock_path — routing concern (not business state, not r()'able).
    //   Lang_active_dock(w) resolves it to the {dock: path} particle.
    //   Lang_set_active_dock(w, path) sets it and marks dock.sc.active.
    //
    // ── DRY state update ─────────────────────────────────────────────────────
    //
    //   All CM events carry { doc:path, view, state } in e.sc.
    //   Lang_dock_from_event(w, e) finds-or-creates the dock particle and
    //   writes dock.c.view / dock.c.state in exactly one place — eliminating
    //   the scattered w.c.editorState = e.sc.state pattern.
    //
    // ── whatsthis cache ──────────────────────────────────────────────────────
    //
    //   dock.c.last_whatsthis_dock — the EditorState.doc rope from the last
    //   whatsthis() call.  CM doc ropes are immutable value objects; identity
    //   equality is O(1) and reliable.  Skipped when doc and bookmarks haven't
    //   changed since last tick.
    //
    // ── Deposits ─────────────────────────────────────────────────────────────
    //
    //   whatsthis(state, container, bookmarks, opt)
    //     — walks the EditorState's Lezer parse tree and i()s TheC nodes
    //       (Line, node, texts, text) into `container`.
    //
    // Consumed by w:Lang, which runs one whatsthis() call per w/%bookmark
    // into a per-bookmark subcontainer under model/**.
    //
    // ── State flows ──────────────────────────────────────────────────────────
    //
    //   e:Lang_workon_update  ← Lies_i_Spotlight, every cursor move
    //     takes  e%src (cursored %What or %Doc from Spotlight)
    //     makes  workon.c.src; pokes think → the driver re-keys req:understanding
    //
    //   req_workon (req:workon do_fn, the per-tick driver)
    //     takes  workon.c.src, %LE working version + U_serial, active dock + dige
    //     makes  a signature per stage; roai's it (un-finishes %permanent on drift)
    //            then pumps understanding → ingredients → instrumentation
    //
    //   req:understanding  — the %Waft|%LE boundary stage
    //     takes  workon.c.src, %LE, origin_dirty
    //     makes  %Languinio/%Interest (sc.src clone root, c.LE handle, in_* address)
    //            %LE/%State.changey (via LE_encode_compare), auto-push on working drift
    //            understanding.c.armed_src (memoised — skipped on same src)
    //
    //   e:mark / e:LE_mark  ← NaviCado, test snaps
    //     takes  e%LE (particle or sentinel 1), op, spec
    //     makes  C.c.U.sc.unshowing | unaccepted (or clone.sc for add|edit);
    //            LE.c.U_serial++
    //            → driver's understanding sig (…:U_serial:…) drifts → re-encode →
    //              %State.changey → auto-push (LE_push flushes clone tree → OC)
    //
    //   e:Lies_waft_mutated  ← Lies watch_c(waft), on any Waft OC change
    //     takes  e%waft_key
    //     makes  LE.c.origin_dirty when our target lives in that Waft
    //            → driver's understanding sig (…:origin_dirty) drifts → re-pull
    //              origin; in-scope drift (%State.stale) auto-pulls (re-arm +
    //              re-clone working off the new origin)
    //
    //   e:dock_content  ← Lies drain (push) | dock_askies (pull), with the %Good
    //     takes  e%Good (bytes off-snap, dige on /known)
    //     makes  the dock (Lang_open_dock), dock.c.content_dige; pokes think
    //            → the waiting req:furnishing finishes; driver re-keys instrumentation
    //
    //   e:LE_operate%op=push  ← NaviCado / DocMinimap
    //     makes  req:push|encode|replace|verify cluster under workon/%LE
    //
    //   e:Lang_editorBegins  ← Langui on CM mount
    //     takes  e%dock, view, state, updates (live bookmark positions)
    //     makes  dock.c.view, dock.c.state; reconciles %bookmark from/to
    //            → feebly_ponder wakes req:text_loaded monitor in Languish
    //
    //   e:dock_content    ← Lies, with the dock %Good (push|pull); mints the dock
    //     takes  e%path, e%text
    //     makes  req:Languish (text_loaded → compile phases)
    //
    //   Lang_update_change  (each tick, active dock known)
    //     takes  dock/{Text:1}, dock/{Compile}/{Output}
    //     makes  %Languinio/%Change/{backend|storage|compile} (roai → new C ref
    //            → Svelte re-renders Langui's three-leg change strip)
    //


    import { _C, TheC } from "$lib/data/Stuff.svelte"
    import { dig }       from "$lib/Y.svelte"
    import { syntaxTree } from "@codemirror/language"
    import type { EditorState } from "@codemirror/state"
    import { onMount, tick } from "svelte"

    import Langui from "$lib/O/Langui.svelte"
    import type { House } from "$lib/O/Housing.svelte";
    import { EditorView } from "codemirror";
    import LangWhatwhere from "./LangWhatwhere.svelte";
    import LangCompiling from "./LangCompiling.svelte";
    import LangSion from "./LangSion.svelte";
    import LangRegions from "./LangRegions.svelte";
    import LangLang from "./LangLang.svelte";
    import LangGraft from "./LangGraft.svelte";
    import LangPoint from "./LangPoint.svelte";

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#endregion
//#region plan

    async Lang_plan(A: House, w: TheC) {
        const H = this

        // ── the permanent viewable model ────────────────────────────
        // w/{model:1} — a stable TheC we hand to Cyto as Scannable.
        const model = w.i({ model: 1, cyto_dir:1 })
        w.c.model = model

        // UI registration — Otro mounts this alongside Cytui for H:Lang
        const uis = H.oai_enroll(H, { watched: 'UIs' })
        uis.oai({ UI: 'Langui' }, { component: Langui })

        const wa = H.oai_enroll(H, { watched: 'actions' })
        wa.oai({ action: 1, role: 'debookmark'   },
            { label: '-marks', fn: () => this.Lang_debookmark(w) })
        wa.oai({ action: 1, role: 'enbookmark'   },
            { label: '+marks', fn: () => this.Lang_enbookmark(w) })
        // compile trigger — translates the doc and writes the resulting
        // module to src/lib/gen/Somewhere.svelte via the Wormhole, then
        // notifies Pantheate.  Machinery provides Lang_compile.
        wa.oai({ action: 1, role: 'compile'      },
            { label: 'compile', fn: () => this.i_elvisto(w, 'Lang_compile') })

        // header dropdown + grammar-gen button — registered by LangLang so
        // the per-tick LangLang_tick can update them in place.
        await this.LangLang_plan(A, w)

        // ── doc registry ────────────────────────────────────────────
        // w/{docks: 1} — container for all open document particles.
        // Individual {dock: path} particles are created lazily via
        // e_Lang_dock_content when Lies hands us the dock %Good.
        w.oai({docks: 1})

        // Declare req spaces so i_Story_o_req_ttlilt finds reqs on %dock particles.
        H.i_scheme_req(w, [{docks: 1}, {dock: 1}])

        // ── reach across to Story's Styles ──────────────────────────
        // Story persists Styles under its w.c.The/{Styles:1}.
        // We call The_Styles(storyw) so we get the same TheC.
        const topH    = H.top_House()
        let stylesC: TheC | null = null
        try {
            const storyw = topH.o({H:'Story'})[0].Awo('Story', 'Story')
            stylesC = H.The_Styles(storyw)
        } catch {
            console.warn(`Lang: H:Story not present yet — Cyto will palette-fallback`)
        }

        // ── commission our own Cyto ─────────────────────────────────
        // Scannable = the permanent model C.
        // client_w  = w:Lang itself, so animation_done events come here.
        const commission = new TheC({ c: {}, sc: {
            Scannable:            w.c.model,
            Styles:               stylesC,
            client_w:             w,
            supports_constraints: true,
            supports_seek:        false,
            supports_takeTurns:   false,
            wants_wave_done:      false,
            wants_animation_done: false,
        }})
        // target our local A:Cyto/w:Cyto, not H:Story's
        H.i_elvisto(`Cyto/Cyto`, 'Cyto_commission', { req: commission })

        // ── %Languinio — Lang's reactive signal particle ────────────
        // Parallel to %examining on w:Lies.  Enrolled in ave so UItime
        // (Langui, DocMinimap) can read it without a new prop.  c.w is a
        // back-ref so a reader can climb to w:Lang.
        // Holds %LE / %dock / %Interest in volatility order (see comment above).
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const languinio = w.oai({ Languinio: 1 })
        ave.i(languinio)
        languinio.c.w = w

        // ── w/{LE:1} — one Understanding for the Lang instance ───────
        // Stable: not inside a replace(), so LE/* and LE.c.* survive every checkout.
        // Unarmed until first cursor move; readers gate on LE.sc.target.
        // Same-object hold in %Languinio installed once here — place() so
        // re-plan never piles a second %LE.
        const LE = w.oai({ LE: 1 })
        await languinio.place({ LE: 1 }, LE)

        // ── req:workon — the convergence home ────────────────────────
        // Open-ended anchor.  Its do_fn (req_workon) is the thin per-tick
        // driver: it computes each stage's input signature, roai's any stage
        // whose signature drifted (→ %permanent de-finish), then pumps the stage
        // pipeline.  The three stages are keyed (mutated-on) volatility lanes:
        //   req:understanding  — src → re-arm LE + flush; sets %Interest
        //   req:ingredients    — %Interest → req:furnishing per wanted %Doc
        //   req:instrumentation — active dock + dige → compile + graft + decorate
        // Each stage holds wants + convergence-markers only; its durable output
        // lives elsewhere (%LE/%Seem, %Good, the dock) so de-finishing loses nothing.
        const rq_w   = H.reqy(w)
        const workon = await rq_w.roai({ req: 'workon' }, { LE, w })
        workon.sc.following = 1   // track group cursor (default)
        // < following:0 = diverged; thought-balloon on breadcrumb

        // auto_push on by default — changey working drift with a stable origin
        //   flushes straight back to the Waft, so the OC is the working set and
        //   touring sheds nothing.  This is the everyday "swing around the code,
        //   pile bookmark trails, reset the file via real git" mode.  Opt nopush
        //   turns it off so a test can exercise the underlying changey|push
        //   truthiness without the flush hiding it.
        workon.sc.auto_push = !!H.o_Opt_val(w, 'nopush') ? 0 : 1

        // Stage reqs — %permanent so a signature roai un-finishes them with a
        // fresh lease.  maz orders the pipeline: understanding (3) before
        // ingredients (2) before instrumentation (1); a stage that bows out on a
        // ttlilt stops do() at its level, gating the lanes below it.
        const wsub = H.reqy(workon)
        await wsub.roai({ req: 'understanding',  maz: 3, permanent: 1 })
        await wsub.roai({ req: 'ingredients',    maz: 2, permanent: 1 })
        await wsub.roai({ req: 'instrumentation', maz: 1, permanent: 1 })

        w.c.plan_done = true
    },

//#region doc routing helpers

    // ── Lang_dock_from_event ──────────────────────────────────────────────────
    //
    //   DRY central router called at the top of every CM event handler.
    //   Every event from Langui carries { doc:path, view, state } in e.sc.
    //   This creates-or-finds the {dock: path} particle under w/{docks: 1} and
    //   updates dock.c.view / dock.c.state in exactly one place.
    //
    //   Returns the dock so the caller can operate on it directly.
    Lang_dock_from_event(w: TheC, e: TheC): TheC {
        // e.sc.dock is stamped by Langui's Lang_i_elvis on every CM-sourced event.
        // Internally-fired events (e.g. e_Lang_i_bookmark → Lang_add_bookmark,
        // or automated test macros) don't go through Langui, so fall back to
        // the active doc — which is always the right target in that case.
        const path = (e.sc.dock as string) || (w.c.active_dock_path as string)
        if (!path) throw 'Lang_dock_from_event: no doc and no active doc yet'
        const docks = w.oai({docks: 1})
        const dock = docks.oai({dock: path})
        // update view + state in exactly one place
        if (e.sc.view)  dock.c.view  = e.sc.view
        if (e.sc.state) dock.c.state = e.sc.state
        return dock
    },

    // ── Lang_active_dock ─────────────────────────────────────────────────────
    //
    //   Returns the {dock: path} particle for the currently active doc, or
    //   undefined if no doc has been registered yet (pre-editorBegins).
    Lang_active_dock(w: TheC): TheC | undefined {
        const path = w.c.active_dock_path as string | undefined
        if (!path) return undefined
        const docks = w.o({docks: 1})[0] as TheC | undefined
        return docks?.o({dock: path})[0] as TheC | undefined
    },

    // ── Lang_set_active_dock ──────────────────────────────────────────────────
    //
    //   Marks a path as active. Stamps dock.sc.active so a tabs UI can see which
    //   doc is foregrounded, re-points the same-object %Languinio/%dock hold so
    //   every Languinio reader (Langui, DocMinimap) reaches the live dock, and
    //   tells w:Lies the foreground changed.
    //
    //   ave/%active_dock is gone — %Languinio/%dock is the single foreground-doc
    //   truth; Langui watches %Languinio (already in ave).
    //   w.c.active_dock_path stays as a cheap routing string.
    async Lang_set_active_dock(w: TheC, path: string) {
        const H = this as House
        w.c.active_dock_path = path
        const docks = w.o({docks: 1})[0] as TheC | undefined
        if (docks) {
            for (const d of docks.o({dock: 1}) as TheC[]) {
                if (d.sc.dock === path) d.sc.active = 1
                else delete d.sc.active
            }
        }
        // Re-point the same-object hold on the active dock into %Languinio so
        // consumers reach it via languinio.o({dock:1})[0] (its bookmarks, view,
        // state, Pmirrors) without any ave round-trip.
        //
        // place() is the right primitive here: the dock is a same-object hold
        // whose X (with %Compile, %Pmirrors etc.) belongs to the dock itself,
        // not to %Languinio.  r() would go through replace()/resolve() and flag
        // those children as "n have /*", which is a diagnostic for new nodes that
        // would silently lose children — not for an existing hold being re-pointed.
        //   < was r({dock:1},{}).then(() => i(dock)) — the .then() put i() into a
        //     new microtask outside Atime; the two-step await r + i form and now
        //     place() are both safe because Svelte effects are on setTimeout and
        //     can't observe any gap between drop and insert while we're in Atime.
        const dock = docks?.o({dock: path})[0] as TheC | undefined
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        if (languinio && dock) {
            await languinio.place({ dock: 1 }, dock)
        }
        // Tell w:Lies the foregrounded doc changed — direct Atime elvis.
        // (The notify stays; only the ave storage went.)
        H.i_elvisto('Lies/Lies', 'Lies_active_doc_changed', { path })
    },

//#endregion
//#region e

//#region e cm -> Lang
    // ── e:Lang_editorBegins ──────────────────────────────────────────────────────
    //
    //   CM has mounted a new editor view.  Registers view+state via the DRY
    //   router and reconciles any live bookmark positions from the CM state.
    async e_Lang_editorBegins(A, w, e) {
        // Register view + state via the DRY router.
        const dock = this.Lang_dock_from_event(w, e)

        // CM StateEffects are per-view, so they live on dock.c — not w.c.
        dock.c.addBookmarkMark    = e.sc.addBookmarkMark
        dock.c.removeBookmarkMark = e.sc.removeBookmarkMark
        dock.c.clearAllBookmarks  = e.sc.clearAllBookmarks
        dock.c.saveEffect         = e.sc.saveEffect
        // Pmirror graft marks live in their own StateField with parallel
        // effects.  LangGraft dispatches these to install/remove graft
        // marks as Pmirrors are minted and reaped.
        dock.c.addGraftMark       = e.sc.addGraftMark
        dock.c.removeGraftMark    = e.sc.removeGraftMark
        dock.c.clearAllGrafts     = e.sc.clearAllGrafts
        // Point decoration + fold handles — Lang_show_pmirrors dispatches through
        //   these.  setPointDecorations is the StateEffect for the glow|enlarge field;
        //   setPointFonts is the StateEffect for the per-line font field LangPoint
        //   uses to grow surviving headers as bodies fold; setPointFolds is a
        //   function(view, showing, hiding) that dispatches foldEffect|unfoldEffect
        //   for the unshowing + crunch set; unfoldAllFolds lifts every fold (used
        //   when no Points govern the view, and on wipe).
        dock.c.setPointDecorations = e.sc.setPointDecorations
        dock.c.setPointFonts       = e.sc.setPointFonts
        dock.c.setPointFolds       = e.sc.setPointFolds
        dock.c.unfoldAllFolds      = e.sc.unfoldAllFolds
        // seek(view, from, to) — unfold what hides the span, select + centre it.
        // Mapule.c.goto rides this so navigation needs no CM imports outside Langui.
        dock.c.seek                = e.sc.seek
        // foldToggle(view, from, to) — fold|unfold one body range; Mapule.c.fold rides it.
        dock.c.foldToggle          = e.sc.foldToggle

        // Only activate if we have a real path — empty string means the dock
        // isn't known yet and Lies hasn't handed back the dock %Good yet.
        if (!w.c.active_dock_path && e.sc.dock) {
            await this.Lang_set_active_dock(w, e.sc.dock as string)
        }
        // The dock hold lives on %Languinio.  On the first open the hold
        // may have been re-pointed before the dock particle existed;
        // Lang_set_active_dock above (when it fired) already installs the real
        // particle, so re-point here only if active and the hold is missing or stale.
        if (w.c.active_dock_path === dock.sc.dock) {
            const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
            const held = languinio?.o({ dock: 1 })[0] as TheC | undefined
            if (languinio && held !== dock) {
                // Same-object hold re-point — see Lang_set_active_dock for the why.
                await languinio.place({ dock: 1 }, dock)
            }
        }

        w.i({ received: 1, editorBegins: 1, doc: dock.sc.dock })

        // The shared view has just arrived on this dock (Langui re-registers on
        //   every switch): clear orphan graft marks left in this state by other
        //   docks' pre-gating grafts and install this dock's own set; also
        //   forces a decoration|fold repaint (show_fp reset inside).
        this.Lang_reassert_graft_marks(dock)

        // ── Bookmark position sync ────────────────────────────────────────────
        //
        // Langui passes `updates` (live CM positions) on every editorBegins,
        // including after each doc switch.  Reconcile them against the dock
        // particles so whatsthis() never starts from stale from/to values.
        //
        // Also re-dispatch addBookmarkMark for any bookmarks that exist in
        // dock but are absent from the restored CM state (can happen when a
        // bookmark was created programmatically and the dock was switched
        // before the StateField had a chance to capture it).
        const updates = e.sc.updates as Array<{id:string,from:number,to:number}> | undefined
        if (updates) {
            const seen = new Set(updates.map((u: any) => u.id))
            for (const u of updates) {
                const bm = dock.o({ bookmark: u.id })[0] as TheC | undefined
                if (!bm) continue
                if (bm.sc.from !== u.from || bm.sc.to !== u.to) {
                    bm.sc.from = u.from; bm.sc.to = u.to; bm.bump_version()
                }
            }
            // Re-apply bookmarks present in dock but absent from CM's live set.
            for (const bm of dock.o({ bookmark: 1 }) as TheC[]) {
                if (!seen.has(bm.sc.bookmark as string) && !bm.sc.vanished) {
                    dock.c.addBookmarkMark && dock.c.view?.dispatch({ effects: dock.c.addBookmarkMark.of({
                        id:   bm.sc.bookmark as string,
                        from: bm.sc.from     as number,
                        to:   bm.sc.to       as number,
                    })})
                }
            }
        }

        // dock.c.state has just been stamped (by Lang_dock_from_event above).
        // A req:text_loaded phase may be holding Story open waiting for exactly
        // this — wake a think so its monitor re-checks and descends to compile.
        ;(this as House).feebly_ponder()
    },
    // ── e:Lang_texting ───────────────────────────────────────────────────────────
    //
    //   Text arrived from the UI (80ms throttle) or from e_Lang_i_alterationStation
    //   (machine:true, fires immediately alongside the CM dispatch).
    //   Updates dock.c.text and dock/{Text:1}, then drives the Languish pipeline.
    //
    //   machine:true → compile_ready fires after 30ms (test / programmatic edits).
    //   machine:false (default) → compile_ready fires after 6s of quiet typing.
    //   Esc in the editor still calls Lang_compile directly, bypassing the timer.
    //
    //   e.sc: { dock_path: string, text: string, machine?: true }
    async e_Lang_texting(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) throw "!A"
        const path = e.sc.dock_path as string | undefined
        if (!path) throw "!path"
        const text = e?.sc.text as string | undefined
        if (text == null) throw "!text"
        const machine = !!e.sc.machine

        // update the dock's text + Text metadata.  dock.c.text holds the
        // string silently (hidden from snap); Text child carries the dige so
        // Langui can track changes without the giant string in the snap.
        const docks  = w.o({ docks: 1 })[0] as TheC | undefined
        const dock   = docks?.o({ dock: path })[0] as TheC | undefined
        if (!dock) return
        if (dock.c.text === text) return
        dock.c.text = text
        const new_dige = await dig(text)
        await dock.moai({ Text: 1 }, { dige: new_dige })

        // find req:Languish on the dock (not on w anymore) and drive text_mutated
        const languish = dock.o({ req: 'Languish' })[0] as TheC | undefined
        if (!languish) return
        const tm = languish.o({ req: 'text_mutated' })[0] as TheC | undefined
        if (tm) this.reqyoncile(tm, { text, ...(machine ? { machine: 1 } : {}) })
        // reqyoncile Languish itself so sub.do() runs in this same pass,
        //   driving text_mutated without needing a separate Lang think()
        this.reqyoncile(languish, {})
    },
    async req_text_mutated(req: TheC, q: any) {
        const H      = this as House
        const La     = req.c.up as TheC
        const dock   = La.c.up as TheC
        const w      = dock.c.up?.c.up as TheC   // dock → docks → w (c.up wired where the dock is minted)
        req.sc.eternal = 1
        if (!req.sc.mutated) return

        // machine mode: test or programmatic edit wants compile immediately.
        // normal: wait for a quiet period so rapid typing doesn't re-compile every keystroke.
        const machine    = !!(req.sc.machine as any) || !!H.o_Opt_val(w, 'Langui-machine-texting')
        const delay_ms   = machine ? 30 : 6_000
        // dock is La.c.up (languish lives on dock now)
        if (!dock) return

        // coalesce rapid text changes — only the trailing edge triggers compile
        clearTimeout(dock.c.compile_timer as ReturnType<typeof setTimeout>)
        if (machine) {
            // no wait: flag immediately, ponder will pick it up
            dock.c.compile_ready = true
            H.feebly_ponder()
        } else {
            dock.c.compile_timer = setTimeout(() => {
                dock.c.compile_ready = true
                H.feebly_ponder()
            }, delay_ms)
        }
    },


//#endregion
//#region e etc
    // ── e:Dock_open ──────────────────────────────────────────────────────────────
    //
    //   Fired by Liesui / Waft / DocRow when the user clicks a Doc label or a
    //   Point inside one.  Switches the active doc to `path`.
    //
    //   e.sc.point (optional) — the Point value to navigate to once the doc is
    //   active.  Finding + scrolling to it is handled here on the w:Lang side;
    //   the UI just passes the raw Point sc value and forgets about it.
    //
    //   e.sc: { path, point? }
    async e_Dock_open(A: TheC, w: TheC, e: TheC) {
        const path  = e.sc.path  as string | undefined
        const point = e.sc.point as string | undefined
        if (!path) return

        // Switch active doc — Langui's $effect on %Languinio/%dock reacts.
        await this.Lang_set_active_dock(w, path)

        // Point navigation: resolve the point spec against the compiled methods
        // index, apply region-based openness (fold/unfold), and scroll the view.
        // e_Lang_point_navigate (in LangRegions) handles the full cycle and
        // reports issues back to Lies via e:Lies_point_issues.
        if (point) {
            this.i_elvisto('Lang/Lang', 'Lang_point_navigate', { point, doc: path })
        }

        this.i_elvisto(w, 'think')
    },

    // ── Lang_open_dock ────────────────────────────────────────────────────
    //
    //   Mint-or-refresh the per-dock req:Languish and drive one do() pass.
    //   Returns the dock so callers can resolve their RPC immediately once the
    //   dock particle exists (which is guaranteed — caller passes it in).
    //
    //   A re-open of an already-finished Languish drops it and its phase subtree,
    //   then remints fresh so every phase re-runs against the newer source.
    //
    //   Languish lives on the dock — `dock.o({req:'Languish'})[0]`.
    //   dock.c.up = docks, docks.c.up = w (stamped where the dock is minted) so
    //   reqyoncile's %w walk and i_req_ttlilt both reach w:Lang correctly.
    async Lang_open_dock(w: TheC, dock: TheC, text: string): Promise<TheC> {
        const H = this as House
        const rq = H.reqy(dock)
        let languish = await rq.roai({ req: 'Languish' })
        if (languish.sc.finished) {
            dock.drop(languish)
            languish = await rq.roai({ req: 'Languish' })
        }
        languish.c.open_text = text

        const path = dock.sc.dock as string
        console.log(`📄 Lang open_dock → req:Languish ${path}`)
        await rq.do()

        return dock
    },

    // ── e:Lang_workon_update ────────────────────────────────────────────
    //
    //   Fired by Lies_i_Spotlight on every cursor move.  Stashes the new src
    //   on workon.c.src and pokes a think — the workon driver converges from there.
    //   All checkout | furnish | graft | encode logic lives in the workon stages.
    //
    //   < design direction: replace with e:operate{LE,op:'pull',src} so cursor
    //     moves and LE resync share one event.  A pull on an already-armed src
    //     is a cheap noop in req:understanding (armed_src identity check), so the
    //     extra specificity of this dedicated handler buys little.
    //
    //   e.sc: { src: TheC }
    async e_Lang_workon_update(A: TheC, w: TheC, e: TheC) {
        const H      = this as House
        const src    = e.sc.src as TheC | undefined
        if (!src) return
        const workon = H.reqy(w).o({ req: 'workon' })[0] as TheC | undefined
        if (!workon) return
        workon.c.src = src
        H.i_elvisto(w, 'think')
    },

    // ── e:Lies_waft_mutated ──────────────────────────────────────────────
    //
    //   Fired by Lies' watch_c(waft) whenever a loaded Waft OC changes (a UI
    //   CRUD, a rename, or a test edit).  If our armed target lives in that
    //   Waft, Seem:origin is now stale — stamp LE.c.origin_dirty (off-snap) and
    //   poke a think.  The driver's understanding sig picks up origin_dirty,
    //   re-pulls origin, and (when the drift falls inside the checked-out extent)
    //   auto-pulls the change into the working clone tree.
    //
    //   Gated on target membership: an edit elsewhere in the same Waft still
    //   fires the watcher, but the re-pull then finds no origin drift and is a
    //   cheap no-op — which is exactly the out-of-scope case.
    //
    //   e.sc: { waft_key: string }
    async e_Lies_waft_mutated(A: TheC, w: TheC, e: TheC) {
        const H        = this as House
        const waft_key = e.sc.waft_key as string | undefined
        if (!waft_key) return
        const LE     = w.o({ LE: 1 })[0] as TheC | undefined
        const target = LE?.sc.target as TheC | undefined
        if (!LE || !target) return
        if (H.waft_key_of(target) !== waft_key) return
        // < orphan case (target's c.up no longer reaches the Waft — deleted out
        //   from under us) is not handled here; it is the natural home for the
        //   Merge UI, which picks up an edit that lands inside something dropped.
        LE.c.origin_dirty = 1
        H.feebly_ponder()
    },

    // climb req.c.up until a node has %w on its sc, return that w.
    //   workon carries %w directly; stages above carry it one|two hops up.
    upto_w(req: TheC): TheC {
        let node: TheC = req
        while (node && !node.sc.w) node = node.c.up as TheC
        if (!node?.sc.w) throw "upto_w: no %w in c.up chain"
        return node.sc.w as TheC
    },

    // ── req_workon — the thin per-tick driver ─────────────────────────
    //
    //   do_fn for req:workon.  Holds no work itself: it computes each stage's
    //   input signature, roai's any stage whose signature drifted (which
    //   un-finishes the %permanent stage with a fresh lease), then pumps the
    //   stage pipeline once.  Invalidation cascades forward through the keys —
    //   understanding sets %Interest, which is ingredients' key; ingredients
    //   settles the active dock, which feeds instrumentation's key — so no stage
    //   ever reaches forward to wake another.  The driver does one uniform
    //   compare-and-wake; the stages do the work, off live state, when woken.
    //
    //   A signature is a short string on stage%sig.  maybe_mutate_sc fires its
    //   %mutated (and the %permanent un-finish) only when sig actually changes,
    //   so a settled tick re-drives nothing — every stage sits finished.
    async req_workon(req: TheC, q: any) {
        const H      = this as House
        const workon = req
        const w      = H.upto_w(req)
        const LE     = workon.sc.LE as TheC
        const wsub   = H.reqy(workon)

        // understanding — re-arm + flush whenever src, the working tree, or origin
        //   drift moves.  src identity rides as a stable serial bumped on change;
        //   the LE flush keys (working.version, U_serial, origin_dirty) ride too,
        //   so an e:mark edit or an origin mutation wakes the same stage.
        //   roai (not reqyoncile) carries the sig: it routes through maybe_mutate_sc,
        //   which un-finishes a quiescent %permanent stage on a real sig change and
        //   no-ops when unchanged — reqyoncile bails on already-finished reqs.
        const src        = workon.c.src as TheC | undefined
        const wv         = LE.o({ Seem: 'working' })[0]?.version ?? 0
        const u_serial   = (LE.c.U_serial as number | undefined) ?? 0
        const od         = LE.c.origin_dirty ? 1 : 0
        const src_serial = H.Lang_src_serial(workon, src)   // bumps on every What move
        const u_sig      = `${src_serial}:${wv}:${u_serial}:${od}`
        await wsub.roai({ req: 'understanding' }, { sig: u_sig })

        // ingredients — the wanted-%Doc set.  want_doc derives DIRECTLY from the
        //   live src via Waft_src_doc_path — the same resolution Lang_set_interest
        //   publishes onto %Interest/in_Doc, but computed here from the source of
        //   truth.  Reading %Interest instead lagged one tick: these sigs are
        //   built before understanding (which updates Interest) runs in this same
        //   pump, so a doc move keyed the stages stale and the new doc only loaded
        //   on the NEXT tick — visible as "poised until one more trickle".
        //   in_Doc is the only field that changes which %Goods we want; a
        //   Point-only move within the same Doc leaves it untouched, so the dock
        //   isn't re-fetched.
        const want_doc = src ? H.Waft_src_doc_path(src) : undefined
        const g_sig    = want_doc ?? ''
        await wsub.roai({ req: 'ingredients' }, { sig: g_sig })

        // instrumentation — the doc the CURSOR wants (want_doc above), its content
        //   dige, the cursor identity, and the Understanding's own version.  Keying
        //   on the wanted doc rather than the foregrounded one is what lets a hop
        //   back to an already-furnished doc re-run the stage and re-point the active
        //   dock — the furnish/open path only ever activated a doc once.  Compile keys
        //   on dige; graft keys on the working clone, so the stage re-runs on any
        //   cursor move (a different What, even on the SAME Doc → different Points)
        //   and on in-What working edits.  src_serial catches the cross-What-same-Doc
        //   move; LE.version is bumped by LE_arm (re-aim) and e_LE_mark (in-What edit),
        //   so it subsumes the in-What case the old wv term missed (a clone-root
        //   child-add never bumps the Seem's wv).  The wanted dock's content_dige
        //   rides along so a not-yet-furnished doc re-wakes us the moment its content
        //   lands — no waiting ttlilt of instrumentation's own.  The graft's own
        //   fingerprint then decides whether to actually rebuild — a redundant wake
        //   is a cheap no-op.
        const want_dock = want_doc
            ? (w.o({ docks: 1 })[0]?.o({ dock: want_doc })[0] as TheC | undefined)
            : undefined
        const n_sig  = `${want_doc ?? ''}:${(want_dock?.c.content_dige as string | undefined) ?? ''}:${src_serial}:${LE.version}`
        await wsub.roai({ req: 'instrumentation' }, { sig: n_sig })

        // pump the pipeline — maz orders understanding → ingredients → instrumentation.
        await wsub.do()
    },

    // ── Lang_src_serial — stable per-src identity for the understanding sig ────
    //   src is a TheC; we want a sig token that changes only when the cursored
    //   src object changes.  Stash the last src on workon.c and bump a counter on
    //   identity change — cheaper and snap-clean versus stringifying the src.
    Lang_src_serial(workon: TheC, src: TheC | undefined): number {
        if (workon.c.last_src !== src) {
            workon.c.last_src    = src
            workon.c.src_serial  = ((workon.c.src_serial as number | undefined) ?? 0) + 1
        }
        return (workon.c.src_serial as number | undefined) ?? 0
    },

    // ── req_understanding — the %Waft|%LE boundary stage ─────────────────────
    //
    //   %permanent; woken by the driver when src, the working tree, or origin
    //   drift moves.  Owns checkout (re-arm the Understanding on src change) and
    //   the two-direction flush (origin drift → re-pull; working drift → push).
    //   Sets %Interest (c.What, in_Doc, in_Point) — the C-side address the rest
    //   of the pipeline keys off.  Touches no dock and no compile index, so it
    //   converges independently of editor readiness.
    async req_understanding(req: TheC, q: any) {
        const H      = this as House
        const workon = req.c.up as TheC         // understanding.c.up = workon
        const w      = H.upto_w(req)
        const LE     = workon.sc.LE as TheC
        const want   = workon?.c.src as TheC | undefined

        // checkout — re-arm when the cursored src changes (identity memoised).
        if (want && req.c.armed_src !== want) {
            H.LE_arm(LE, want)
            await H.LE_pull(LE)
            req.c.armed_src = want
            req.sc.what     = (want.sc as any).What ?? (want.sc as any).path ?? '?'
            console.log(`🔗 understanding checkout: ${req.sc.what}`)
            H.Lang_set_interest(w, LE, want)
        }
        if (!req.c.armed_src) { q.finish(req); return }   // nothing cursored yet
        const armed = req.c.armed_src as TheC

        // origin drift — the Waft OC moved under us (e:Lies_waft_mutated stamped
        //   LE.c.origin_dirty).  Re-pull origin; if it touched our extent
        //   (%State.stale) re-clone working off the new origin.  With autopush
        //   on, working held no unflushed edits, so re-cloning loses nothing;
        //   the editor's own edits already landed on the OC and arrive as the
        //   new origin we re-clone from.
        if (LE.c.origin_dirty) {
            delete LE.c.origin_dirty
            await H.LE_pull(LE)
            if (LE.o({ State: 1 })[0]?.sc.stale) {
                H.LE_arm(LE, armed)
                await H.LE_pull(LE)
                req.c.last_encode_key = undefined   // force the re-encode below
            }
            H.Lang_set_interest(w, LE, armed)        // re-point %Interest at fresh clone
        }

        // encode — gated on working.version + U_serial so enWaft is not called
        //   every wake.  LE_encode_compare stamps %State.changey and bumps LE.version
        //   on the edge so NaviCado's ~ bar wakes.
        //   auto_push: when workon.sc.auto_push is set, working drift with stable origin
        //   immediately pushes back to the Waft OC.  Off by default — edits are staged
        //   for explicit push via the ~ bar.  The !stale guard remains so an origin edit
        //   never gets clobbered by a now-superseded auto-push even when the flag is on.
        const wv         = LE.o({ Seem: 'working' })[0]?.version
        const u_serial   = (LE.c.U_serial as number | undefined) ?? 0
        const encode_key = `${wv}:${u_serial}`
        if (req.c.last_encode_key !== encode_key) {
            const { dirty } = await H.LE_encode_compare(LE)   // stamps %State.changey
            req.c.last_encode_key = encode_key
            if (dirty && workon.sc.auto_push && !LE.o({ State: 1 })[0]?.sc.stale) {
                await H.LE_push(LE)
            }
        }

        q.finish(req)   // converged for this signature; driver wakes on drift
    },

    // ── Lang_set_interest — publish the C-side address ────────────────────────
    //
    //   %Interest mirrors Lies' %Spotlight on the Lang side.  Dropped + rebuilt so
    //   it never points at a stale clone.  c.LE is the nav handle LangGraft reads;
    //   sc.src is the clone root NaviCado reads; c.What is the live %What object;
    //   in_Doc is ingredients' key and the active-dock selector; in_Point is the
    //   focus spec.
    async Lang_set_interest(w: TheC, LE: TheC, armed: TheC) {
        const H         = this as House
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        if (!languinio) return

        await languinio.r({ Interest: 1 }, {})
        const interest  = languinio.oai({ Interest: 1 })
        const working_C = LE.o({ Seem: 'working' })[0]?.sc.C as TheC | undefined
        interest.sc.src = working_C
        interest.c.LE   = LE

        // the live %What rides as the object on c.What — readers reach the real
        //   particle (its Points, their c.Doc) without a name lookup.  in_Doc stays
        //   a string: it is the dock-map key, and docks are keyed by path.
        const sc = armed.sc as any
        interest.c.What = armed
        const in_Doc   = H.Waft_src_doc_path(armed)
        const in_Point = sc.method as string | undefined
        if (in_Doc   != null) interest.sc.in_Doc   = in_Doc
        if (in_Point != null) interest.sc.in_Point = in_Point

        interest.bump_version()

        // stale spinner — origin pull drifted; cleared once encode is clean.
        const stale = LE.o({ State: 1 })[0]?.sc.stale
        if (stale) languinio.oai({ spinner: 'stale' })
        else       languinio.o({ spinner: 'stale' }).forEach((s: TheC) => languinio.drop(s))
    },

    // ── req_ingredients — the raw %Goods we need ─────────────────────────────
    //
    //   %permanent; woken when %Interest's in_Doc moves.  Ensures one
    //   req:furnishing per wanted %Doc and drives them; finished when every
    //   furnishing is.  MVP wants exactly the active What's %Doc; the structure
    //   holds more, so a look-ahead furnishing further along the Waft trail drops
    //   in here later with no instrumentation churn (in_Doc, not "ingredients
    //   changed", is what keys instrumentation).
    async req_ingredients(req: TheC, q: any) {
        const H        = this as House
        const w        = H.upto_w(req)
        // want derives from the live src (workon.c.src is this stage's parent's
        //   cursor hold), same as the driver's sig — NOT from %Interest, which
        //   only refreshes when understanding re-runs and so can trail a Waft
        //   edit (a Doc added to the cursored What) by a tick.
        const src      = (req.c.up as TheC | undefined)?.c.src as TheC | undefined
        const want_doc = src ? H.Waft_src_doc_path(src) : undefined

        // a title-page %What with no %Doc needs no dock — nothing to furnish.
        if (!want_doc) { q.finish(req); return }

        const rq = H.reqy(req)
        // ensure a furnishing for each wanted path; MVP set is just want_doc.
        //   drop furnishings whose path is no longer wanted (path moved on) —
        //   and clear the furnish spinner they may have left spinning; the fresh
        //   furnishing re-sets it if the new dock also needs loading.
        for (const f of rq.o({ req: 'furnishing' }) as TheC[]) {
            if (f.sc.path !== want_doc) {
                req.drop(f)
                H.Langspinner(w, 'furnish', true)
            }
        }
        await rq.roai({ req: 'furnishing', path: want_doc, permanent: 1 })

        await rq.do()
        rq.unify_finished()   // ← finished when every furnishing is
    },

    // ── req_furnishing — bring one dock %Good into being ─────────────────────
    //
    //   %permanent; pure gate + ttlilt + pull-trigger.  Never carries content:
    //   the dock is minted solely by e_Lang_dock_content (the one content-writer).
    //   This req only asks (dock_askies, the pull half) and reports furnished.
    //
    //   do_fn:  dock present with current content?  → drop ttlilt, finish
    //           else not asked yet → i_elvisto dock_askies%path ; arm ttlilt
    //           else still waiting (ttlilt holds Story awake; speculative push or
    //             pull will land via e_Lang_dock_content, which reqyoncile's us)
    //
    //   The %Good arriving (push or pull) de-finishes us via the dock_content
    //   handler; on a later inotify re-land it would wake us again — the dock as a
    //   standing push|pull boundary.
    async req_furnishing(req: TheC, q: any) {
        const H    = this as House
        const w    = H.upto_w(req)   // furnishing → ingredients → workon
        const path = req.sc.path as string
        if (!path) { q.finish(req); return }

        const dock = w.o({ docks: 1 })[0]?.o({ dock: path })[0] as TheC | undefined
        if (dock && dock.c.content_dige !== undefined) {
            H.Langspinner(w, 'furnish', true)   // dock landed — loading is over
            q.finish(req)   // finish() drops the waiting:dock ttlilt — no dangler
            return
        }

        // dock loading — the spinner Liesui|DocMinimap show while content is in
        //   flight; cleared above when the %Good lands (or by ingredients when the
        //   cursor moves on and this furnishing is dropped).
        H.Langspinner(w, 'furnish')

        // not furnished — ask once (pull), then hold on a ttlilt.  The ask is
        //   idempotent against the speculative push: both land on the one %Good.
        if (!req.sc.asked) {
            req.sc.asked = 1
            H.i_elvisto('Lies/Lies', 'dock_askies', { path })
        }
        H.i_req_ttlilt(req, 2.5, { waiting: 'dock' })
    },

    // ── e:dock_content — the one dock content-writer ──────────────────────────
    //
    //   Lies/Lies -> e:dock_content%Good -> Lang/Lang
    //
    //   The %Good rides back whole (off-snap bytes on good.c.content, dige on
    //   /known).  This is the sole place a dock is minted|refreshed from content,
    //   so there is one writer and no multipath.  After installing the text we
    //   reqyoncile the matching req:furnishing (its finish trigger) and poke a
    //   think so the driver re-keys instrumentation on the new active dock+dige.
    //
    //   Sanity: assert the %Good's path matches what understanding is aimed at;
    //   a stale push (a newer cursor already moved on) is dropped, not installed.
    async e_Lang_dock_content(A: TheC, w: TheC, e?: TheC) {
        const H = this as House
        for (const ev of H.o_elvis(w, 'dock_content')) {
            const good = ev.sc.Good as TheC | undefined
            if (!good) continue
            const path = good.sc.path    as string
            const text = (good.c.content as string | null) ?? ''
            const dige = good.o({ known: 1 })[0]?.sc.dige as string | undefined

            // mint|refresh the dock and stamp the content dige (instrumentation key).
            const docks = w.oai({ docks: 1 })
            docks.c.up  ??= w
            const dock  = docks.oai({ dock: path })
            dock.c.up   ??= docks
            await H.Lang_open_dock(w, dock, text)
            dock.c.content_dige = dige ?? ''

            // first dock furnished becomes the active one (MVP: active = wanted Doc).
            if (!w.c.active_dock_path) await H.Lang_set_active_dock(w, path)

            // poke a think — the furnishing waiting on this path is still needs_work
            //  (it bowed out on a ttlilt, never finished), so the next drive re-runs
            //   it, it sees content_dige, and finishes; the driver then re-keys
            //    instrumentation on the new active dock+dige.  No explicit wake: a
            //     reqyoncile would bail on an already-finished req anyway, and the
            //      furnishing isn't finished while it waits.
            H.i_elvisto(w, 'think')
        }
    },

    // ── req_instrumentation — foreground + compile + graft the cursor's doc ───
    //
    //   %permanent; woken when the cursor's wanted doc, its content dige, the
    //   cursor identity, or the Understanding version moves.  Owns the ONE place a
    //   cursor move re-points the active dock — reading it from %Interest/in_Doc
    //   rather than letting it ride the furnish/open side-effect, which only ever
    //   activated a doc once and so left a hop back to an already-furnished doc
    //   stuck on the old one (the minimap painting the wrong Points).
    //
    //   Then the things-we-build-on-the-dock: the compile %Map index and the
    //   grafted %Pmirrors.  Holds convergence-markers only — the index and Pmirrors
    //   live on the dock — so de-finishing loses nothing; it re-checks and no-ops
    //   when the dock is already current at this dige.
    async req_instrumentation(req: TheC, q: any) {
        const H        = this as House
        const w        = H.upto_w(req)
        // want derives from the live src, like ingredients above — %Interest is
        //   the published address for UI readers, not the pipeline key.
        const src       = (req.c.up as TheC | undefined)?.c.src as TheC | undefined
        const want      = src ? H.Waft_src_doc_path(src) : undefined
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        if (!want) {
            // docless What — a title page.  Wipe the previously foregrounded
            //   dock's Pmirrors (drops graft marks, clears decorations, unfolds —
            //   Lang_wipe_pmirrors) and stamp %Languinio sc.no_doc so Langui
            //   blanks the editor behind the no-doc shell.  Also drop a grafted
            //   spinner a prior What's methods-wait may have left spinning.
            const prev = H.Lang_active_dock(w)
            if (prev) await H.Lang_wipe_pmirrors(prev)
            if (languinio && !languinio.sc.no_doc) {
                languinio.sc.no_doc = 1
                languinio.bump_version()
            }
            H.Langspinner(w, 'grafted', true)
            q.finish(req)
            return
        }

        const dock = w.o({ docks: 1 })[0]?.o({ dock: want })[0] as TheC | undefined
        if (!dock || dock.c.content_dige === undefined) {
            // ingredients is still furnishing the wanted dock.  Finish — the
            //   content_dige term in our sig (req_workon) re-wakes us the instant
            //   e_Lang_dock_content lands it, so no waiting ttlilt of our own.
            //   (furnish, not grafted, is the spinner for this window; no_doc
            //   stays as-is so a title page keeps its blank while loading.)
            H.Langspinner(w, 'grafted', true)
            q.finish(req)
            return
        }

        // a doc is wanted and furnished — the editor shows it; lift the blank.
        if (languinio?.sc.no_doc) {
            delete languinio.sc.no_doc
            languinio.bump_version()
        }

        // foreground the doc the cursor wants.  e_Lies_active_doc_changed early-
        //   returns while the cursor sits on a %What, so this drives no feedback.
        if (w.c.active_dock_path !== want) await H.Lang_set_active_dock(w, want)

        // compile — Languish builds %Compile/%Map; the graft needs the index.
        //   compile_error is terminal — fall through so graft mints unresolved
        //   Pmirrors the minimap can surface; otherwise hold for the index.
        //   The grafted spinner (DocMinimap's gold ⟳) spins across this hold —
        //   set here, cleared on finish; when methods are already in, set+clear
        //   land within one tick and the UI correctly never sees it.
        const job = dock.o({ Compile: 1 })[0] as TheC | undefined
        const err = dock.oa({ compile_error: 1 }) || job?.oa({ compile_error: 1 })
        req.sc.have_Map = job?.oa({ Map: 1 }) ? 1 : 0
        if (!req.sc.have_Map && !err) {
            H.Langspinner(w, 'grafted')
            H.i_req_ttlilt(req, 3.0, { waiting: 'methods' })
            return
        }
        // the waiting:methods ttlilt is dropped by q.finish below (finish() clears
        //  all ttlilts on the req) — we always finish in this same pass once methods
        //   are ready, so no separate drop is needed.

        // graft — self-caching via dock.c.graft_cache_key; cheap every wake.
        await H.Lang_graft_points_once(w, dock)
        req.sc.n_pmirrors =
            (dock.o({ Pmirrors: 1 })[0]?.o({ Pmirror: 1 }) as TheC[] ?? []).length

        // settle %Compile/%Map into %Interest/%MapReport for the minimap —
        // content-gated, so an edit that recompiles to the same structure leaves
        // the report (and the minimap) untouched.
        await H.Lang_Map_report(w, dock)

        // build the generic overview layer next to %Compile — the minimap and the
        // capsule strip navigate Mapulen, not %Map.  Rebuilt every compile so its
        // goto offsets track the latest text.
        H.Lang_build_mapules(w, dock)

        H.Langspinner(w, 'grafted', true)
        q.finish(req)
    },

    // ── Lang_Map_report — %Compile/%Map → %Interest/%MapReport ────────────────
    //
    //   The minimap reads a settled summary here instead of re-deriving it from
    //   the raw index on every wake.  Lives on %Interest (Lang side, per-checkout|
    //   Lang_set_interest drops + rebuilds %Interest each checkout, so the report
    //   is naturally scoped to the current working clone).
    //
    //   Content-gated by a digest of the Map's entries.  %Map's version bumps on
    //   every recompile even when the source structure is unchanged (the common
    //   edit→recompile case), so a version gate would rebuild the report need-
    //   lessly|the digest is stable across those, and only moves when defs,
    //   calls, controlflows or regions actually change.
    //
    //   The digest is NOT an enWaft.  enWaft speaks only Waft vocabulary
    //   (%What|%Doc|%Point) and faults on the def|call|region|controlflow main-
    //   keys the Map holds, so we serialise the entries deterministically and
    //   dig that.  If enWaft ever learns the Map vocabulary this can become
    //   dig(enWaft(Map).snap) with no change to the gate.
    //   < stored on report.c (off-snap identity, like dock.c.content_dige), so
    //     the digest never rides the snap.
    async Lang_Map_report(w: TheC, dock: TheC) {
        const H         = this as House
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        const interest  = languinio?.o({ Interest: 1 })[0] as TheC | undefined
        if (!interest) return
        const Map_C = dock.o({ Compile: 1 })[0]?.o({ Map: 1 })[0] as TheC | undefined
        if (!Map_C) return

        // serialise every entry as line|kind|key|via|class|title, sorted by line
        // then kind then key so a reordered-but-equal index still digests equal.
        const rows = (Map_C.o({}) as TheC[]).map(e => {
            const s    = e.sc
            const kind = s.def ? 'def' : s.call ? 'call'
                       : s.region ? 'region' : s.controlflow ? 'cf' : '?'
            const key  = (s.method ?? s.label ?? s.keyword ?? '') as string
            return { line: (s.line as number) ?? 0, kind, key,
                     via:   (s.via   ?? '') as string,
                     cls:   (s.class ?? '') as string,
                     title: (s.title ?? '') as string }
        })
        rows.sort((a, b) => a.line - b.line
            || a.kind.localeCompare(b.kind) || a.key.localeCompare(b.key))
        const serial = rows.map(r =>
            `${r.line}|${r.kind}|${r.key}|${r.via}|${r.cls}|${r.title}`).join('\n')
        const dige = await dig(serial)

        const report = interest.oai({ MapReport: 1 })
        if (report.c.Map_dige === dige) return   // same structure — leave it

        report.c.Map_dige  = dige
        report.sc.n_def    = rows.filter(r => r.kind === 'def').length
        report.sc.n_call   = rows.filter(r => r.kind === 'call').length
        report.sc.n_region = rows.filter(r => r.kind === 'region').length
        report.sc.n_cf     = rows.filter(r => r.kind === 'cf').length
        report.bump_version()
    },

    // ── Lang_build_mapules — %Compile/%Map → dock/%Navicade (the Mapulen) ──────
    //
    //   The generic overview layer.  One Mapule per Map entry — a %kind,key,path,depth
    //   tuple (path on .c, it's an array) plus off-snap closures — so a UI can render
    //   and navigate the doc knowing nothing Lang: the minimap and the capsule strip
    //   both read Mapulen, never %Map.  Sits next to %Compile on the dock and is
    //   rebuilt each compile (offsets move every edit), so the closures it carries on
    //   .c are never stale.
    //     m.c.goto()              — look at this entry: unfold + select + centre, via
    //                               dock.c.seek (Langui owns the CM dispatch).
    //     m.c.is_pointedat(specs) — is this entry one of the working Points.  The UI
    //                               passes the pointed-spec set it derived from LE.vers,
    //                               so a Point change re-derives in the Mapulen without
    //                               rebuilding them — the Mapulen stay put across Point
    //                               toggles, only the derive re-runs.
    //   Region Mapulen additionally carry the finished band geometry so the minimap
    //   parses no //#region and maps no lines to chars itself:
    //     sc.end_line             — last line of the region body (extent for the band).
    //     m.c.fold()              — toggle-fold the region body in the editor.
    Lang_build_mapules(w: TheC, dock: TheC) {
        const Map_C    = dock.o({ Compile: 1 })[0]?.o({ Map: 1 })[0] as TheC | undefined
        const navicade = dock.oai({ Navicade: 1 })
        navicade.empty()
        if (!Map_C) { navicade.bump_version(); return }

        // doc geometry — char offset of each line's end, and the line count.  The
        // minimap holds none of this Lang-side|the Mapulen carry the finished spans
        // so the UI never parses //#region or maps lines to chars itself.
        const text  = (dock.c.text as string) ?? ''
        const lines = text.split('\n')
        const total = lines.length || 1
        const line_end = new Array<number>(total + 2)   // 1-indexed; [n] = end char of line n
        {
            let off = 0
            for (let i = 0; i < lines.length; i++) { off += lines[i].length; line_end[i + 1] = off; off += 1 }
        }

        // region extents — a region's last line.  Honours //#endregion (a nested
        // region can close back to its parent before any sibling opens, which pure
        // depth+line ordering would miss), falling back to "next region at depth ≤
        // mine, else EOF" for regions left implicitly open.  Lang owns the //#region
        // syntax|the minimap just reads sc.end_line.
        const region_entries = (Map_C.o({ region: 1 }) as TheC[])
            .map(r => ({ depth: (r.sc.depth as number) ?? 0, line: (r.sc.line as number) ?? 1 }))
            .sort((a, b) => a.line - b.line)
        const end_of = new Map<number, number>()
        for (const r of region_entries) end_of.set(r.line, total)
        {
            const ENDREGION_RE = /^[\t ]*\/\/#endregion\b/
            const stack: typeof region_entries = []
            let next = 0
            for (let i = 0; i < lines.length; i++) {
                const line_num = i + 1
                while (next < region_entries.length && region_entries[next].line === line_num) {
                    // a new region at depth ≤ an open one closes that open one here
                    while (stack.length && stack[stack.length - 1].depth >= region_entries[next].depth) {
                        const c = stack.pop()!
                        if (end_of.get(c.line) === total) end_of.set(c.line, line_num - 1)
                    }
                    stack.push(region_entries[next++])
                }
                if (ENDREGION_RE.test(lines[i]) && stack.length) {
                    const c = stack.pop()!
                    end_of.set(c.line, line_num)   // body includes the //#endregion line
                }
            }
        }

        for (const e of Map_C.o({}) as TheC[]) {
            const s    = e.sc
            const kind = s.def ? 'def' : s.call ? 'call'
                       : s.region ? 'region' : s.controlflow ? 'cf' : '?'
            const key  = String(s.method ?? s.label ?? s.keyword ?? '')
            if (!key) continue
            // capture per-Mapule so the goto closure carries this entry's own span
            const from  = (s.from as number) ?? 0
            const to    = (s.to   as number) ?? from
            const depth = (s.depth as number) ?? 0
            const line  = (s.line  as number) ?? 0
            const m = navicade.i({
                Mapule: 1, kind, key, depth, line, from, to,
                ...(s.class ? { cls: s.class as string } : {}),
            })
            m.c.path = (e.c.region_path as string[] | undefined) ?? []
            m.c.goto = () => {
                const view = dock.c.view
                if (view && dock.c.seek) (dock.c.seek as Function)(view, from, to)
            }
            m.c.is_pointedat = (specs: Set<string>) => specs.has(key)

            if (kind === 'region') {
                // body span for the fold and the band extent — header line stays
                // visible, the body below folds (matches Lang_apply_openness).
                const end_line  = end_of.get(line) ?? total
                const body_from = line_end[line] ?? text.length
                const body_to   = line_end[end_line] ?? text.length
                m.sc.end_line   = end_line
                m.c.body_from   = body_from
                m.c.body_to     = body_to
                m.c.fold = () => {
                    const view = dock.c.view
                    if (view && dock.c.foldToggle && body_from < body_to)
                        (dock.c.foldToggle as Function)(view, body_from, body_to)
                }
            }
        }
        navicade.bump_version()
    },

    // ── Lang_pointed_specs — the set of working-Point specs ────────────────────
    //
    //   The specs of the Points in the current working checkout, the membership a
    //   Mapule's is_pointedat tests against.  Same spec read as NaviCado's capsules
    //   (method ?? label ?? Point) so the strip and the minimap agree on what's a
    //   Point.  Derives from LE — the caller sensitises on LE.vers so it re-runs as
    //   Points toggle.
    Lang_pointed_specs(LE: TheC | undefined): Set<string> {
        const specs = new Set<string>()
        if (!LE || !LE.oa({ Seem: 'working' })) return specs
        for (const clone of (this.LE_clones(LE) as TheC[])) {
            const raw = clone.sc.method ?? clone.sc.label ?? clone.sc.Point
            if (raw == null) continue
            specs.add(String(raw))
        }
        return specs
    },

    // Doc-from-src resolution lives in LiesEnd as Waft_src_doc_path — one body
    //   shared with Lies and LangGraft so the three can't drift.




//#region Languish


    // see e:Lang_texting where CodeMirror pushes text

    // ── req:Languish — Lang's per-dock mind
    //
    //   Lives on dock ({dock:$path}/{req:'Languish'}).  Stages two maz-ordered
    //   phase reqs and runs them; unify_finished finishes Languish when both done.
    //   Multi-maz do() descends through levels in one pass on a fast (soft) compile.
    //
    //     req:text_loaded, maz:3   install text + wait for CM mount
    //     req:compile,     maz:2   build the methods index; hold for hard-write
    //
    //   Grafting is no longer Languish's concern — req:instrumentation owns it.
    //   Languish builds; the settler wires.
    //
    //   c.up chain: req.c.up = languish, languish.c.up = dock, dock.c.up = docks,
    //   docks.c.up = w — wired where the dock is minted so reqyoncile and i_req_ttlilt
    //   both climb correctly to w:Lang.
    async req_Languish(req: TheC, q: any) {
        const H = this as House

        const sub = H.reqy(req)
        await sub.roai({ req: 'text_loaded', maz: 3 })
        await sub.roai({ req: 'text_mutated', maz: 2 })
        await sub.roai({ req: 'compile',     maz: 2 })
        // grafted dropped — req:instrumentation owns all grafting; Languish builds the
        //   compile index; the settler wires the rest.

        await sub.do()
        sub.unify_finished(q)
    },

    // ── req:text_loaded, maz:3 ────────────────────────────────────────────────
    //
    //   reqonce: install text into the dock (already minted by e_Lang_dock_content),
    //   seed Text metadata and dock.c.text, set the doc active.
    //   gen_path derived at compile time — not stamped here.
    //
    //   The genuinely-async wait is the CodeMirror round-trip: Lang writes the
    //   dock.c.text → Langui renders → CM mounts → e_Lang_editorBegins stamps
    //   dock.c.state and feebly_ponders.  We hold Story open with a ttlilt until
    //   dock.c.state appears; the feebly_ponder wakes this monitor precisely
    //   when it lands.
    async req_text_loaded(req: TheC, q: any) {
        const H        = this as House
        const languish = req.c.up as TheC
        const dock     = languish.c.up as TheC          // set by reqy
        const w        = dock.c.up?.c.up as TheC        // dock → docks → w (c.up wired where the dock is minted)
        const path     = dock.sc.dock as string

        if (H.reqonce(req, 'opening')) {
            // one chance: install text into the dock (already minted by e_Lang_dock_content).
            H.Langspinner(w, 'text_load')

            const text = (languish.c.open_text as string) ?? ''

            // gen_path derived at compile time — not stamped here.
            dock.c.initial_text = text   // Langui reads this before the Text dige arrives

            // seed Text metadata; dock.c.text holds the string silently.
            // Langui reaches dock via ave/Languinio/dock — Lang_set_active_dock
            // (called below) places this dock into Languinio, already in ave.
            const initial_dige = text ? await dig(text) : ''
            dock.c.text = text
            await dock.moai({ Text: 1 }, {
                dige:      initial_dige,
                disk_dige: initial_dige,
                disk_rev:  ((dock.o({ Text: 1 })[0]?.sc.disk_rev as number) ?? 0) + 1,
            })

            // always activate — Lies owns doc order, last open wins for now
            await this.Lang_set_active_dock(w, path)
            w.i({ received: 1, doc_opened: 1, doc: path })
        }

        // monitor: CM has mounted and handed us its EditorState.  Until then
        // there is nothing to compile.  e_Lang_editorBegins feebly_ponders when
        // it stamps dock.c.state, which re-enters here.
        if (!dock.c.state) {
            H.i_req_ttlilt(req, 3.0, { waiting: 'cm_mount' })
            return
        }
        // CM mounted — the text_load phase is over; clear its spinner.
        H.Langspinner(w, 'text_load', true)
        q.finish(req)
    },
    // ── Langspinner — one named spinner under %Languinio ──────────────────────
    //
    //   Each {spinner:$name} particle is an independent in-flight indicator —
    //   set|clear touches only the named one, so text_load + furnish + compile
    //   can all spin at once.  oai|drop is the same per-name model the %stale
    //   spinner uses in Lang_set_interest.
    //   (The previous r({spinner:name}) form collapsed its pattern to the
    //    {spinner:1} has-key wildcard, so setting any spinner replaced ALL of
    //    them and clearing one cleared all — every overlapping phase broke.)
    //
    //   DocMinimap renders the live set; unknown names get the default style.
    Langspinner(w: TheC, spinner: string, not = false) {
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        if (!languinio) return
        if (not) for (const s of languinio.o({ spinner }) as TheC[]) languinio.drop(s)
        else     languinio.oai({ spinner })
        languinio.bump_version()
    },

    // ── req:compile, maz:2 ────────────────────────────────────────────────────
    //
    //   reqonce: run the synchronous index build (Lang_compile_dock) once.  With
    //   multi-maz do(), this fires in the same tick text_loaded finishes.
    //
    //   %Compile/%Map is populated synchronously by Lang_compile_dock, so a
    //   soft-compile finishes this phase immediately.  For a hard-compile,
    //   %Compile/sc.pending stays set while Lies writes the gen file; we hold Story
    //   open with a ttlilt until it clears, so the gen file exists before the snap.
    //   Either way %Map — the only thing grafting needs — is present the
    //   instant Lang_compile_dock returns.
    async req_compile(req: TheC, q: any) {
        const H        = this as House
        const languish = req.c.up as TheC
        const dock     = languish.c.up as TheC
        const w        = dock.c.up?.c.up as TheC   // dock → docks → w (c.up wired where the dock is minted)

        if (H.reqonce(req, 'firing')) {
            // one chance: state is in — build the index.
            H.Langspinner(w,'compile')
            await this.Lang_compile_dock(w, dock)
        }

        const job = dock.o({ Compile: 1 })[0] as TheC | undefined

        // compile error is a terminal: methods will never appear and Pending
        // never clears, so don't ttlilt forever — finish and let grafting find
        // nothing (the minimap surfaces unresolved Pmirrors).
        if (dock.oa({ compile_error: 1 }) || job?.oa({ compile_error: 1 })) {
            H.Langspinner(w,'compile',true)
            q.finish(req)
            return
        }

        // index missing → compile hasn't run yet; methods present is the graft
        // gate.  hold until it appears.
        if (!job || !job.oa({ Map: 1 })) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'methods' })
            return
        }
        if (job.sc.pending) {
            // methods ready but gen-file write still in flight — hold Story open
            // so the gen file exists before the snap; %Compile/sc.pending is now
            // snapped so the wait is visible.
            H.i_req_ttlilt(req, 0.5, { waiting: 'gen_write' })
            return
        }
        H.Langspinner(w,'compile',true)
        q.finish(req)
    },




// ── Lang_update_change ───────────────────────────────────────────────────────
    //
    //   Writes the three-leg change strip into w/{Languinio:1}/{Change:1}.
    //   Three child particles, one per leg:
    //
    //     /{backend:1}  sc.dige — current editor-text dige (from dock/{Text:1})
    //     /{storage:1}  sc.dige — last dige confirmed written to disk
    //                   sc.dim  — text has moved ahead (unsaved edits exist)
    //     /{compile:1}  sc.dige — source_dige of last Compile/Output
    //                   sc.dim  — compile is pending or disk is ahead of it
    //                   sc.secs — %Compile/%time.sc.compile (synchronous cost)
    //
    //   Each leg uses roai with the sc payload as second arg.  roai replaces the
    //   particle when its sc doesn't match, producing a fresh C reference.
    //   Langui holds _backend/_storage/_compile as $state() C refs — only a new
    //   reference triggers a Svelte re-render, so oai+bump_version isn't enough.
    //
    //   Called from the Lang tick each time the active dock is known.
    async Lang_update_change(w: TheC, dock: TheC) {
        const H   = this as House
        const path = dock.sc.dock as string

        // Read current dige values from dock/Text.
        // Text is absent until req_text_loaded's moai resolves — bail rather
        // than blanking Change with empty strings.  The tick will re-run once
        // e_Lang_dock_content lands and populates Text.
        const Text      = dock.o({ Text: 1 })[0] as TheC | undefined
        if (!Text) return
        const text_dige  = (Text.sc.dige      as string ?? '').slice(0, 5)
        const disk_dige  = (Text.sc.disk_dige as string ?? '').slice(0, 5)

        const job           = dock.o({ Compile: 1 })[0] as TheC | undefined
        const output        = job?.o({ Output: 1 })[0]  as TheC | undefined
        const compiled_dige = ((output?.sc.source_dige as string) ?? '').slice(0, 5)
        // sc.compile from %time is the synchronous cost — what the compiler actually spent.
        const compile_cost  = (job?.o({ time: 1 })[0] as TheC | undefined)?.sc.compile as number ?? 0
        const pending       = !!job?.sc.pending

        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        if (!languinio) return
        const change = languinio.oai({ Change: 1 })

        // roai replaces the particle when sc doesn't match → new C ref → Svelte re-renders.
        await change.roai({ backend: 1 }, { dige: text_dige })

        const disk_dim = !!text_dige && !!disk_dige && text_dige !== disk_dige
        await change.roai({ storage: 1 }, { dige: disk_dige, dim: disk_dim })

        if (output) {
            const compile_dim = pending || (!!compiled_dige && !!disk_dige && compiled_dige !== disk_dige)
            await change.roai({ compile: 1 }, { dige: compiled_dige, dim: compile_dim, secs: compile_cost })
        } else {
            for (const old_c of change.o({ compile: 1 }) as TheC[]) change.drop(old_c)
        }
    },

//#region w:Lang

    async Lang(A: TheC, w: TheC) {
        const H = this

        if (!w.c.plan_done) await this.Lang_plan(A, w)
        // these go every time so their toggle state can visually change
        let on_change = () => this.main()
        // whether Lang-Cyto does compound_nodes
        await this.i_actions_to_c(w, 'compo',{ stashed: true, on_change })

        const dock = this.Lang_active_dock(w)

        // compile reply polling — drives Lang_compile_step while job.c.pending
        // is set (transient); when Lies_compile_settled lands, step clears it.
        if (dock?.o({ Compile: 1 })[0]?.sc.pending) {
            await this.Lang_compile_step(A, w)
        }

        // language picker + gen button — registered fresh each tick so the
        // dropdown reflects the active doc's current language override.
        await this.LangLang_tick(A, w)

        // ── drive dock landing + Languish + workon ───────────────────────────
        // Drain dock_content first — the one content-writer mints|refreshes any
        //  dock whose %Good just arrived (push or pull).
        await this.e_Lang_dock_content(A, w)

        // Drive each dock's Languish (text_loaded → compile) BEFORE the workon
        //  driver, so a dock minted this tick has its %Map ready when
        //  instrumentation re-keys — same-tick convergence, no extra round-trip.
        //  Languish lives on dock — rq.do() on w no longer reaches it.
        const docks_C = w.o({ docks: 1 })[0] as TheC | undefined
        if (docks_C) {
            for (const d of docks_C.o({ dock: 1 }) as TheC[]) {
                const languish = d.o({ req: 'Languish' })[0] as TheC | undefined
                if (languish && !languish.sc.finished) await H.reqy(d).do()
            }
        }

        // Drive w-level reqs.  req:workon is open-ended; its do_fn (req_workon)
        //  is the per-tick driver — it re-keys the three stages and pumps them via
        //  its own reqy(workon).do().  No separate settle|push driving here: the LE
        //  flush (push) runs inside req_understanding, the dock pipeline inside the
        //  stages.  Cheap when settled — every stage sits finished, no key drifts.
        const rq = H.reqy(w)
        await rq.do()

        // re-decorate from the U sphere after graft has minted Pmirrors.
        // Cache-key-independent: a fold-toggle or class change repaints here
        // without a re-graft (Lang_show_pmirrors short-circuits on no change).
        if (dock?.o({ Pmirrors: 1 })[0]) this.Lang_show_pmirrors(w, dock)

        const model     = w.c.model as TheC
        const state     = dock?.c.state
        const opt       = {compound_nodes: !!w.c.compo}
        const bookmarks = (dock?.o({ bookmark: 1 }) ?? []) as TheC[]

        // ── whatsthis cache check ────────────────────────────────────
        // CM doc ropes are immutable — identity equality is O(1) and reliable.
        // dock.version covers everything on the doc particle: bookmark adds,
        // removes, position updates, compile state — no need to sum child
        // versions (they all start at 0 anyway, making a sum unreliable).
        const dock_unchanged  = state && state.doc === dock?.c.last_whatsthis_dock
        const docC_unchanged = dock?.version === dock?.c.last_dock_version

        if (state && bookmarks.length && !(dock_unchanged && docC_unchanged)) {
            if (0) {
                // Cyto path — flat Line/{node,text} model + cyto_fold constraints
                model.empty()
                this.whatsthis(state, model, bookmarks, opt)
                this.wherewhatis(model, opt)
                if (dock) {
                    dock.c.last_whatsthis_dock = state.doc
                    dock.c.last_dock_version  = dock.version
                }
                H.i_elvisto('Cyto/Cyto', 'Cyto_animation_request', { Langy: 1 })
            }
            else if (H.o_Opt_val(w, 'txtsyntaxdump')) {
                // txt path — nested Lezer hierarchy under model/Line:N/<NodeName>/...
                // built for the Story snap to render as plain text.  No Cyto ping.
                model.empty()
                this.whatsthis_txt(state, model, bookmarks)
                // bump so DocPoint's $derived(model.ob()) re-fires
                model.bump_version()
                if (dock) {
                    dock.c.last_whatsthis_dock = state.doc
                    dock.c.last_dock_version  = dock.version
                }
            }
        }
        if (!bookmarks.length) model.empty()

        w.i({ see: `🟦 tiles ${bookmarks.length} bookmarks` })

        // ── compile_ready gate ────────────────────────────────────────────────
        // req_text_mutated sets dock.c.compile_ready after the quiet period
        //   (30ms for machine edits, 6s for keyboard typing).  We reset the
        //   reqonce on compile so req_compile re-fires with fresh text.
        if (dock?.c.compile_ready) {
            delete dock.c.compile_ready
            clearTimeout(dock.c.compile_timer as ReturnType<typeof setTimeout>)
            dock.c.compile_timer = null
            // Languish lives on dock — no path lookup needed
            const languish = dock.o({ req: 'Languish' })[0] as TheC | undefined
            const com      = languish?.o({ req: 'compile' })[0] as TheC | undefined
            if (com && languish) {
                // reset the reqonce so Lang_compile_dock runs again for the new text
                delete com.sc.firing
                if (com.c.oncelers) delete (com.c.oncelers as any).firing
                delete com.sc.finished
                // re-drive Languish so sub.do() picks up the un-finished compile
                this.reqyoncile(languish, {})
            }
        }

        // Push the three-leg change strip into Languinio/Change for Langui.
        if (dock) await this.Lang_update_change(w, dock)

        // first compile per doc: Languish req:compile phase.
        //   Re-compile on text edit: req_text_mutated timer → compile_ready → above gate.
        //   Manual re-compile: the Lang_compile action / Esc key (direct).
    },

    // Helper function to check if r2 is contained by r1
    range_contained (r1: {from: number, to: number}, r2: {from: number, to: number}) {
        return r1.from <= r2.from && r1.to >= r2.to;
    },
    // Helper function to check if r2 overlaps r1
    range_overlaps (r1: {from: number, to: number}, r2: {from: number, to: number}) {
        return r1.from <= r2.to-1 && r1.to-1 >= r2.from;
    },



//#region caving

    caving() {
        ` // < this
system of diving into spaces that are developing
 for slowly opening a hive of realities into one over-place
  floating through the landscape of eg assail()
   dealing with some of the language across it all
 this shall be the collective attentions at things
 generalisable tech
  basically deriving openness from journey, see Dierarchy
   and that openness affects whatever its connected to, perhaps
    pigmenting? now with the html overlay each node can have crazy details
     to be more human readable while being a dense cluster of info

uses:

in this first use of this possibly generalisable tech
 we shall split the text by indent
  which promotes leaders
  which have among them more and less novel text... see assail()
 and give Wip, similar to Dip
  it implies ordering
   if we want to put something before 1.1,
    we put it at 1.1.0.1
    another at "before 1.1" at 1.1.0.2
     then something before that at 1.1.0.2.0.1
   but why?
    I cant remember right now.
  the dialectics these Wip schemes exist on should have the equivalent of
   Cyto_wipe
 
   
> for splitting types that emerge over time
 the shrine of types
 has a cell division process for eg a type of Se and what ever could be in it
  pieces of identity can go to one|both|neither of the new pair
 so those Se statements are collected and indexed somewhere.
  as would all the functions defined?
 
endless zooming through walls covered in code graffiti
 handles the open and close of the wormhole
 node gets bigger until it ruptures into being a very folded codemirror
  the folds look like paper planes crashed in from the right
  hovering along their tails projects|enlarges whats there behind it

having a new Cyto cluster spawn within (by location trickery) another
 and grow continuously like an embryo?
  panning through dimensions of being (clusters of language)
 so that each architectural subsystem of anything can be made to flash when executed,
  or reveal itself as a sentence|society momentarily
   in a hairball of over-connected everything with everySuch<->everySuch


`

        
    },



//#region assail

    assail() {
        ` // < this
sauntering up to some code
 look at subsets of the objects (regions+funcs+calls) in eg Housing.svelte.ts
 > do lexing stemming and text search with sqlite?
 pull it apart with regexes?
    no time to parse every language
    keep scoped to one show grammar
    is my code as typescript AST hard to find function calls and definitions...?
    its got to learn how to learn a new language
 
collect all words, make them linkable to each other?
 even to see all 1915 ifs, a bundle of 113 ifs leading into src/lib/O/Housing.svelte.ts
 style the rare words as such

threads of inquiry stack up on the left
 there's a + button that spawns one where we are
  name after their start
  and then they'll wander off, looking at various things with varying intensity+duration
   or along them, perhaps.
 the most concrete representations should hover on the right, ie lines in places...
 the set of them we're looking at should roll over
  depending on how well tacked-down each thing is
 



`

        
    },

//#region regroup

    regroup() {
        ` // < this
done:
 - Expression Translation, its Selection.process(), if ok can write the gen/*
 - Sunpit-as-iteration and pythonic indentation
todo:
 - Map building, persisting and exchanging the meaningful bits
< &somefunc,A,w -> this.somefunc(A,w)
definitely not in the next phase:
 - Sunpit as Travel underneath
 - all Sunpits contribute clues to the local Selection...
    Se/* becomes its configuration and state.


to continuously compile this code we're editing
 it should respond efficiently to changes by reusing whole unchanged chunks
perhaps we need loads of marks, on every Line, so we can see very well what changes?
 though we'll also be resolving changes often, in small batches
 the kind of thing diff-match-patch could be used for
  but codemirror can can give us the most efficient diffing between two states
   moreover there are times when we have several states from several events,
    which must have any data relative to each state
     eg the from,to position of something at some time
     translated into unison with the other states...
     like how our bookmarks are separate to codemirror
      so we have to sync their new positions
 the Map
  keep a bunch of the meaningful syntax in a Selection.process()
   which is function calls, io expressions
  brings in knowing what $lib/Ghost/* we are editing
   so Langui could expand a bit at this point.
    and CRUD a flat list of Ghosts to know.
    just a sorted dropdown, one option being +
     via action buttons with type=dropdown.
  to generate a Map.
   dexie tables of... items, calls, notes
   hold off interacting with the others yet
   and in fact this thing we're working on isn't on disk anywhere...
    which is how it's supposed to be.
    do a one-off write of src/lib/gen/Example.go
     I think it should misrepresent itself as being go to github's languages measurer.
  to tell if certain things come+go,
   eg use of a database table, which we could automatically add a bit of schema for
    since our schema definition will be in this society of objects we're maintaining
     and we can connect definitions to calls, etc, supposing we parse them as such later.

`

        
    },



//#region bm
    // onMount() ONLY, automate the test

    async Lang_enbookmark(w) {
        // +marks button: place a bookmark on line 6 via the generic handler
        this.i_elvisto('Lang/Lang', 'Lang_i_bookmark', { from: 98, to: 132 })
    },
    async Lang_debookmark(w) {
        const dock = this.Lang_active_dock(w)
        const view = dock?.c.view
        if (view && dock?.c.clearAllBookmarks) {
            view.dispatch({ effects: dock.c.clearAllBookmarks.of(null) })
        }
        // r() on the dock particle — bookmarks live there, not on w
        if (dock) await dock.r({ bookmark: 1 }, {})
        this.i_elvisto(w, 'think', {})
    },

    // ── e:Lang_i_bookmark ────────────────────────────────────────────────────
    //
    //   Generic Plan/Prep action: place a bookmark at a given char range.
    //   No action button — params must come from the Prep/esc children.
    //   from / to are char offsets into the doc.  If omitted or equal, the
    //   handler expands to the enclosing line (same as Ctrl+B on empty selection).
    async e_Lang_i_bookmark(A, w, e) {
        const dock = this.Lang_active_dock(w)
        const view = dock?.c.view
        if (!view) throw new Error("e_Lang_i_bookmark — no editor view")
        await new Promise(resolve => setTimeout(resolve, 30))
        await tick()

        let from = e?.sc.from as number | undefined
        let to   = e?.sc.to   as number | undefined
        // expand to enclosing line if range is absent or zero-width
        if (from == null || to == null || from === to) {
            const pos  = from ?? 0
            const line = view.state.doc.lineAt(pos)
            from = line.from
            to   = line.to
        }
        view.dispatch({ selection: { anchor: from, head: to } })
        await tick()
        const label = view.state.doc.sliceString(from, to).slice(0, 24).replace(/\s+/g, ' ')
        this.i_elvisto('Lang/Lang', 'Lang_add_bookmark', {
            from, to, label, view, state: view.state,
        })
    },

    // ── e:Lang_i_alterationStation ───────────────────────────────────────────
    //
    //   Generic Plan/Prep action: surgically replace a substring within a line.
    //   Operates within the existing text so CM can remap any bookmark decorations
    //   that span the edit — a whole-line replace would destroy them.
    //   No action button — params must come from the Prep/esc children:
    //
    //     Prep:4
    //       i_elvisto:Lang,e:Lang_i_alterationStation
    //         esc:line_n,v:6
    //         esc:sanity,v:    o hut/although:1,they,can,be,mixed
    //         esc:match,v:",they,can,be,mixed"
    //         esc:replacement,v:"/they,can,be,mixed"
    //
    //   line_n      — 1-based CodeMirror line number
    //   sanity      — expected full line text; warns on mismatch but still proceeds
    //   match       — JSON-encoded string: substring to find within that line (first occurrence)
    //   replacement — JSON-encoded string: what to replace it with (may be different length)
    //
    //   match and replacement are JSON-encoded so commas in values don't collide
    //   with the snap key:value,key:value delimiter format.
    async e_Lang_i_alterationStation(A, w, e) {
        const dock = this.Lang_active_dock(w)
        const view = dock?.c.view
        if (!view) throw new Error("e_Lang_i_alterationStation — no editor view")

        const line_n      = e?.sc.line_n      as number
        const sanity      = e?.sc.sanity      as string | undefined
        const match   = e?.sc.match       as string
        const replacement    = e?.sc.replacement as string
        if (!line_n || match == null || replacement == null)
            throw "e_Lang_i_alterationStation — needs line_n, match, and replacement"

        const line = view.state.doc.line(line_n)
        if (sanity != null && line.text !== sanity) {
            // warn but still proceed — test is re-runnable after the first replacement
            console.warn(`Lang_i_alterationStation — line ${line_n} sanity mismatch\n  expected: ${JSON.stringify(sanity)}\n  got:      ${JSON.stringify(line.text)}`)
        }

        const idx = line.text.indexOf(match)
        if (idx < 0) {
            console.warn(`Lang_i_alterationStation — match ${JSON.stringify(match)} not found in line ${line_n}: ${JSON.stringify(line.text)}`)
            return
        }

        // Surgical replace — CM remaps any decoration whose range spans this
        // position, so bookmarks within the line survive intact.
        // updateListener fires Lang_texting (dock updated) and arms the 80ms timer.
        view.dispatch({ changes: { from: line.from + idx, to: line.from + idx + match.length, insert: replacement } })

        // saveEffect flushes bookmark positions immediately — updateListener cancels
        // the debounce and fires Lang_update_bookmarks with the fresh editorState.
        view.dispatch({ effects: dock.c.saveEffect.of(null) })
        console.log(`Lang_i_alterationStation — line ${line_n} [${match}] → [${replacement}], saveEffect dispatched`)

        // machine-texting: bypass the 80ms push throttle and compile immediately
        //   rather than waiting 6s.  The Langui timer will also fire (80ms) but
        //   will be a no-op since the text is already in ave.
        this.i_elvisto(w, 'Lang_texting', {
            dock_path: dock.sc.dock as string,
            text:      view.state.doc.toString(),
            machine:   true,
        })
    },


//#region bm e
    // ── e:Lang_add_bookmark ──────────────────────────────────────────────────────
    //
    //   Ctrl+B from the editor — create a w/{dock}/%bookmark at the current
    //   selection.  CM marks the range so from/to track edits automatically.
    //   Periodic e:Lang_update_bookmarks pushes live positions back here.
    //
    //   e.sc: { doc, from, to, label?, view, state }
    async e_Lang_add_bookmark(A: TheC, w: TheC, e: TheC) {
        const dock = this.Lang_dock_from_event(w, e)

        let from  = e?.sc.from  as number | undefined;
        let to    = e?.sc.to    as number | undefined;
        const label = (e?.sc.label as string | undefined) ?? '';
        const view  = e?.sc.view  as EditorView | undefined;
        const state = e?.sc.state as EditorState | undefined;

        if (from == null || to == null || !view || !state) {
            console.warn("Missing required fields in e_Lang_add_bookmark");
            return;
        }
        if (from === to) {
            const line = view.state.doc.lineAt(from);
            from = line.from;
            to = line.to;
        }

        // bookmarks live on dock, not w, so they can be r()'d per doc
        const existingBookmark = dock.o({ bookmark: 1 }).find((bm: TheC) =>
            bm.sc.from === from && bm.sc.to === to
        ) as TheC | undefined;
        if (existingBookmark) {
            // Ctrl+B on an already-bookmarked range removes it
            view.dispatch({ effects: dock.c.removeBookmarkMark.of({ id: existingBookmark.sc.bookmark }) })
            await dock.r({ bookmark: existingBookmark.sc.bookmark }, {})
            console.log(`🔖 remove_bookmark id=${existingBookmark.sc.bookmark} [${from}..${to}]`)
            this.i_elvisto(w, 'think', {})
            return
        }

        // Deterministic id keyed on position — same range always gets the same id,
        // so TheC keys and CodeMirror decoration ids survive reloads and round-trips.
        const id = `bm_${from}_${to}`;
        view.dispatch({
            effects: dock.c.addBookmarkMark.of({ id, from, to }),
        });

        dock.i({ bookmark: id, from, to, label });

        // Name it after the MethodLike on this line, if the compile index is in|
        // a bookmark on `async o_elvis_Idzeugnosis(A,w) {` becomes that Point.
        // No index yet → stays positional; e:Lang_point_fuzzify upgrades it later.
        const method = this.Lang_def_at_offset(dock, from)
        if (method) {
            const bm = dock.o({ bookmark: id })[0] as TheC | undefined
            if (bm) { bm.sc.method = method; bm.bump_version() }
        }

        console.log(`🔖 add_bookmark id=${id} [${from}..${to}] ${method ? `method:${method}` : label}`);
        this.i_elvisto(w, 'think', {});
    },


    // Fired by the editor after the debounce (or immediately via saveEffect).
    //
    // Carries the live from/to for every bookmark still present in the CM
    // decoration set, plus a fresh editorState so whatsthis() sees the updated
    // ── e:Lang_update_bookmarks ──────────────────────────────────────────────────
    //
    //   Fired by the editor after the debounce (or immediately via saveEffect).
    //   Carries live from/to for every bookmark in CM's decoration set plus
    //   a fresh editorState.  Bookmarks absent from updates[] have vanished —
    //   their decoration was wiped by an edit that fully replaced the span.
    //
    //   e.sc: { doc, updates=[{id,from,to}], view, state }
    async e_Lang_update_bookmarks(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) throw "!A"
        const doc = this.Lang_dock_from_event(w, e)
        const updates = e?.sc.updates as Array<{ id: string, from: number, to: number }> | undefined
        if (updates) {
            const seen = new Set(updates.map(u => u.id))
            for (const u of updates) {
                const bm = doc.o({ bookmark: u.id })[0] as TheC | undefined
                if (!bm) continue
                if (bm.sc.from === u.from && bm.sc.to === u.to) continue
                bm.sc.from = u.from
                bm.sc.to   = u.to
                bm.bump_version()
            }
            // detect vanished bookmarks — present in doc but absent from CM's live set
            for (const bm of doc.o({ bookmark: 1 }) as TheC[]) {
                if (!seen.has(bm.sc.bookmark)) {
                    this.Lang_bookmark_vanished(doc, bm)
                }
            }
        }
        // state already updated by Lang_dock_from_event above
        this.i_elvisto(w, 'think', {})
    },

    // ── e:Lang_update_grafts ─────────────────────────────────────────────────
    //
    //   Counterpart to e_Lang_update_bookmarks for Pmirror grafts.  Carries
    //   the live from/to for every graft mark in CM's graftMarkField.  The
    //   actual update logic lives in %LangGraft.Lang_update_grafts — this
    //   is just the elvis entry point.
    //
    //   < graft vanishing (mark wiped by full-span edit) is not yet
    //     handled.  The next graft pass will see the spec doesn't resolve
    //     anymore (or resolves to a different place) and the Pmirror's
    //     identity machinery will sort it out — possibly with a momentary
    //     unresolved state visible in the minimap.
    async e_Lang_update_grafts(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) throw "!A"
        const updates = e?.sc.updates as Array<{ id: string, from: number, to: number }> | undefined
        if (updates) this.Lang_update_grafts(w, updates)
        this.i_elvisto(w, 'think', {})
    },

    // ── Lang_bookmark_vanished ───────────────────────────────────────────────
    //
    //   Called when a bookmark's CM decoration is absent from the live set —
    //   meaning an edit fully replaced or deleted the span it was anchored to.
    //
    //   < STUB: eventually this should attempt re-anchoring by scanning the
    //     parse tree for the nearest surviving syntactic landmark (same Line:N,
    //     same node type, same label text) and re-dispatching addBookmarkMark
    //     at the recovered position.
    //
    //   < Copy+paste tracking: when a paste lands, compare incoming text chunks
    //     against the label/content of vanished bookmarks and re-anchor any that
    //     appear in the new location.
    Lang_bookmark_vanished(doc: TheC, bm: TheC) {
        console.warn(`🔖 bookmark vanished: ${bm.sc.bookmark} was [${bm.sc.from}..${bm.sc.to}] "${bm.sc.label}"`)
        bm.i({ vanished: 1 })
        // < re-anchor attempt goes here
        // < copy+paste recovery pass goes here
    },

    // ── e:Lang_remove_bookmark ───────────────────────────────────────────────
    //
    //   Remove one bookmark by id.  Dispatches removeBookmarkMark to CM
    //   and drops the particle from the doc.  Wired to DocPoint's delete button.
    //
    //   e.sc: { bookmark_id }
    async e_Lang_remove_bookmark(A: TheC, w: TheC, e: TheC) {
        const doc = this.Lang_active_dock(w)
        if (!doc) return
        const id = e.sc.bookmark_id as string | undefined
        if (!id) return
        const bm = doc.o({ bookmark: id })[0] as TheC | undefined
        if (!bm) return
        if (doc.c.view && doc.c.removeBookmarkMark) {
            doc.c.view.dispatch({ effects: doc.c.removeBookmarkMark.of({ id }) })
        }
        await doc.r({ bookmark: id }, {})
        console.log(`🔖 remove_bookmark id=${id}`)
        this.i_elvisto(w, 'think', {})
    },

    // ── e:Lang_point_fuzzify ─────────────────────────────────────────────────
    //
    //   Resolve a bookmark's char-offset range to the enclosing method name
    //   from the compile index.  Stamps bm.sc.method, upgrading from a
    //   positional anchor to a named method pointer.
    //   No-op with a hint when the compile index is absent.
    //
    //   e.sc: { bookmark_id }
    async e_Lang_point_fuzzify(A: TheC, w: TheC, e: TheC) {
        const doc = this.Lang_active_dock(w)
        if (!doc) return
        const bm = doc.o({ bookmark: e.sc.bookmark_id })[0] as TheC | undefined
        if (!bm) return
        const method = this.Lang_def_at_offset(doc, bm.sc.from as number)
        if (method) {
            bm.sc.method = method
            bm.bump_version()
            console.log(`🔖 fuzzified ${bm.sc.bookmark} → method:'${method}'`)
        } else {
            w.i({ see: `⚠ fuzzify: no def at ${bm.sc.from} — run compile first` })
        }
        this.i_elvisto(w, 'think', {})
    },

    // ── e:Lang_stamp_bookmark_serial ─────────────────────────────────────────
    //
    //   Stamp a global Point serial onto a bookmark after it has been exported
    //   to a Waft Doc via e_Lies_export_point.  The DocPoint UI shows this to
    //   signal the bookmark is already persisted.
    //
    //   e.sc: { bookmark_id, serial }
    async e_Lang_stamp_bookmark_serial(A: TheC, w: TheC, e: TheC) {
        const doc = this.Lang_active_dock(w)
        if (!doc) return
        const bm = doc.o({ bookmark: e.sc.bookmark_id })[0] as TheC | undefined
        if (!bm) return
        bm.sc.point_serial = e.sc.serial as number
        bm.bump_version()
        this.i_elvisto(w, 'think', {})
    },


//#region text measurement

    // ── measureText ──────────────────────────────────────────────────────
    // Monospace text measurement via OffscreenCanvas (or hidden canvas).
    // Returns { width, height } in px for a given string at a given font size.
    //
    // Since we use a monospace font, the per-char width is constant —
    // we cache the char width per fontSize and multiply by str.length.
    // Non-printable / tab chars get a fixed slot width.
    //
    // The measurement canvas is created once and reused across all calls.
    // Font: 'Berkeley Mono', 'Fira Code', monospace — same as Cytui.
    _measure_cache: {} as Record<number, number>,
    _measure_ctx: null as CanvasRenderingContext2D | null,

    measureText(str: string, fontSize = 12): { width: number, height: number } {
        if (!str) return { width: 0, height: 0 }

        if (!this._measure_ctx) {
            const canvas = document.createElement('canvas')
            canvas.width = 300; canvas.height = 40
            this._measure_ctx = canvas.getContext('2d')!
        }
        const ctx = this._measure_ctx
        const FONT = `${fontSize}px Berkeley Mono,Fira Code,monospace`

        let charW = this._measure_cache[fontSize]
        if (!charW) {
            ctx.font = FONT
            // measure a reference character — 'M' is widest in most fonts
            charW = ctx.measureText('M').width
            this._measure_cache[fontSize] = charW
        }

        // padding: 8px left + 8px right internal to the node
        const PAD = 16
        const width  = Math.ceil(str.length * charW) + PAD
        const height = Math.ceil(fontSize * 1.6) + 8  // line-height ~1.6 + vertical pad
        return { width, height }
    },



    })
    })
</script>

<LangWhatwhere {M} />
<LangCompiling {M} />
<LangSion {M} />
<LangRegions {M} />
<LangLang {M} />
<LangGraft {M} />
<LangPoint    {M} />