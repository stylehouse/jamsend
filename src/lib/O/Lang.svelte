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
    //
    //   Bookmarks and compile live on dock, not w, so they can be r()'d per doc.
    //
    // ── Understanding hold ───────────────────────────────────────────────────
    //
    //   w/{req:'workon'}          — permanent; one per Lang instance.
    //     /{req:'awaiting'}       — one-shot; satisfied on first src, installs
    //                               Languinio/%LE hold, then stays finished.
    //     /{req:'maneuvre'}       — reset on each cursor move; the per-src cluster.
    //       /{req:'checkout'}     — LE_arm + LE_pull on workon's own /{LE:1}.
    //       /{req:'furnish'}       — wait for the dock Lies' Furnishing mints.
    //       /{req:'graft'}        — drive Lang_graft_points_once on the active dock.
    //       /{req:'encode'}       — LE_encode_compare after graft; sets %State.changey.
    //     /{LE:1}                 — stable on workon across all cursor moves.
    //       /%State               — synthesised: armed/changey/stale
    //       // %push_dirty — fault; present only when push didn't land clean
    //       /%Seem:origin / /%Seem:working
    //
    //   w/{Languinio:1}           — Lang's one focus object (§3b).
    //     /{LE:1}                  — same-object hold → workon/{LE:1}.
    //     /{Interest:1}            — sc.src = working clone root; c.LE → /{LE:1}.
    //                                Recreated per cursor move by req:checkout;
    //                                the render/edit end of the checkout.
    //     /{dock:path}             — same-object hold on the active dock (§3d:
    //                                replaces ave/%active_dock).
    //   Installed once by req:awaiting on first src arrival.
    //   Langui reads LE_clones() and %State directly from it without a
    //   cross-world round-trip.
    //
    // ── Reactive text sync ───────────────────────────────────────────────────
    //
    //   ave/{lang_dock:path} — one per doc, holds sc.text.
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
    import LangGen from "./LangGen.svelte";
    import LangGraft from "./LangGraft.svelte";

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

        // header dropdown + grammar-gen button — registered by LangGen so
        // the per-tick LangGen_tick can update them in place.
        await this.LangGen_plan(A, w)

        // ── doc registry ────────────────────────────────────────────
        // w/{docks: 1} — container for all open document particles.
        // Individual {dock: path} particles are created lazily via
        // e_Lang_open_dock when Lies hands us a loaded file.
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
        // (Langui, DocMinimap) can read it without a new prop.  Languish
        // phase handlers oai/drop %spinner children on it; at rest it is
        // empty.  c.w is a back-ref so a reader can climb to w:Lang.
        // %LE is inserted as a same-object hold (languinio.i(LE)) each time
        // e_Lang_workon_update fires — req:awaiting's do_fn does that insertion.
        // Langui reads it via languinio.o({LE:1})[0] to check %State without
        // a cross-world round-trip.
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const languinio = w.oai({ Languinio: 1 })
        ave.i(languinio)
        languinio.c.w = w

        // ── req:workon — cursor-driven Understanding checkout ────────────
        // Open-ended; one per Lang instance.  Seeded here so the reqcon
        // do_fn is wired before the first e_Lang_workon_update arrives.
        // /{LE:1} is created lazily in e_Lang_workon_update (workon.oai).
        // req:awaiting and req:maneuvre are seeded there too, per update.
        const rq_w = H.reqy(w)
        ;(await rq_w.doai({ req: 'workon' }))?.(async (_workon: TheC) => {
            // do_fn body intentionally empty — workon is open-ended (w:true analog).
            // e_Lang_workon_update drives the inner cluster directly.
        })

        // Seed following flag on workon after doai resolves it.
        const workon_seed = rq_w.o({ req: 'workon' })[0] as TheC | undefined
        if (workon_seed) {
            workon_seed.sc.following = 1   // track group cursor (default)
            // < following:0 = diverged; thought-balloon on breadcrumb
        }

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
    //   §3d: ave/%active_dock is gone — %Languinio/%dock is the single
    //   foreground-doc truth, and Langui watches %Languinio (already in ave).
    //   w.c.active_dock_path stays as a cheap routing string.
    Lang_set_active_dock(w: TheC, path: string) {
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
        const dock = docks?.o({dock: path})[0] as TheC | undefined
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        if (languinio && dock) {
            languinio.r({ dock: 1 }, {}).then(() => {
                languinio.i(dock)
                languinio.bump_version()
            })
        }
        // Tell w:Lies the foregrounded doc changed — direct Atime elvis.
        // (The notify stays; only the ave storage went.)
        H.i_elvisto('Lies/Lies', 'Lies_active_doc_changed', { path })
    },

//#region e

    async e_Lang_editorBegins(A, w, e) {
        // Register view + state via the DRY router.
        const doc = this.Lang_dock_from_event(w, e)

        // CM StateEffects are per-view, so they live on doc.c — not w.c.
        doc.c.addBookmarkMark    = e.sc.addBookmarkMark
        doc.c.removeBookmarkMark = e.sc.removeBookmarkMark
        doc.c.clearAllBookmarks  = e.sc.clearAllBookmarks
        doc.c.saveEffect         = e.sc.saveEffect
        // Pmirror graft marks live in their own StateField with parallel
        // effects.  LangGraft dispatches these to install/remove graft
        // marks as Pmirrors are minted and reaped.
        doc.c.addGraftMark       = e.sc.addGraftMark
        doc.c.removeGraftMark    = e.sc.removeGraftMark
        doc.c.clearAllGrafts     = e.sc.clearAllGrafts

        // Only activate if we have a real path — empty string means the doc
        // isn't known yet and Lies hasn't fired e_Lang_open_dock yet.
        // The $effect in Langui re-fires editorBegins once active_path is real.
        if (!w.c.active_dock_path && e.sc.dock) {
            this.Lang_set_active_dock(w, e.sc.dock as string)
        }
        // §3d — the dock hold lives on %Languinio, not ave/%active_dock.  On the
        // first open the hold may have been re-pointed before the doc particle
        // existed; Lang_set_active_dock above (when it fired) already installs the
        // real particle, so re-point here only if this is the active path and the
        // hold is missing or stale.
        if (w.c.active_dock_path === doc.sc.dock) {
            const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
            const held = languinio?.o({ dock: 1 })[0] as TheC | undefined
            if (languinio && held !== doc) {
                languinio.r({ dock: 1 }, {}).then(() => {
                    languinio.i(doc)
                    languinio.bump_version()
                })
            }
        }

        w.i({ received: 1, editorBegins: 1, doc: doc.sc.dock })

        // ── Bookmark position sync ────────────────────────────────────────────
        //
        // Langui passes `updates` (live CM positions) on every editorBegins,
        // including after each doc switch.  Reconcile them against the doc
        // particles so whatsthis() never starts from stale from/to values.
        //
        // Also re-dispatch addBookmarkMark for any bookmarks that exist in
        // doc but are absent from the restored CM state (can happen when a
        // bookmark was created programmatically and the doc was switched
        // before the StateField had a chance to capture it).
        const updates = e.sc.updates as Array<{id:string,from:number,to:number}> | undefined
        if (updates) {
            const seen = new Set(updates.map((u: any) => u.id))
            for (const u of updates) {
                const bm = doc.o({ bookmark: u.id })[0] as TheC | undefined
                if (!bm) continue
                if (bm.sc.from !== u.from || bm.sc.to !== u.to) {
                    bm.sc.from = u.from; bm.sc.to = u.to; bm.bump_version()
                }
            }
            // Re-apply bookmarks present in doc but absent from CM's live set.
            for (const bm of doc.o({ bookmark: 1 }) as TheC[]) {
                if (!seen.has(bm.sc.bookmark as string) && !bm.sc.vanished) {
                    doc.c.addBookmarkMark && doc.c.view?.dispatch({ effects: doc.c.addBookmarkMark.of({
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

    // ── e_Dock_open ───────────────────────────────────────────────────────────
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
        this.Lang_set_active_dock(w, path)

        // Point navigation: resolve the point spec against the compiled methods
        // index, apply region-based openness (fold/unfold), and scroll the view.
        // e_Lang_point_navigate (in LangRegions) handles the full cycle and
        // reports issues back to Lies via e:Lies_point_issues.
        if (point) {
            this.i_elvisto('Lang/Lang', 'Lang_point_navigate', { point, doc: path })
        }

        this.i_elvisto(w, 'think')
    },

    // ── e_Lang_open_dock ──────────────────────────────────────────────────────
    //
    //   §3i — doc-open is now an RPC.  Lies owns the intent (w:Lies/req:Furnishing)
    //   and couriers the req particle here via i_elvis_req; we drain it with
    //   o_elvis_req.  Each carried req has { path, text, gen_path? }; we mint (or
    //   refresh) the per-doc req:Languish — Lang's mind for one doc, staging
    //   text_loaded → compile → grafted so the first graft beats the snap — then
    //   finish({ path, ready:1 }) once the dock is minted, which pings Lies back
    //   with reqturn:1 so its Furnishing phase resolves.
    //
    //   The doc payload (text, gen_path) rides on the Languish req so text_loaded
    //   can install it: gen_path on sc (small, snap-visible), text on .c (large,
    //   kept out of the snap).  A fresher open of the same path overwrites the
    //   payload — newest source wins.  gen_path absent means soft-compile only.
    //
    //   e.sc: { req }  (the Furnishing req, carrying path/text/gen_path)
    async e_Lang_open_dock(A: TheC, w: TheC, e?: TheC) {
        const H = this as House
        for (const { req: furnishing, finish } of H.o_elvis_req(w, 'Lang_open_dock')) {
            const path     = furnishing.sc.path as string
            const gen_path = furnishing.sc.gen_path as string | undefined   // optional
            const text     = (furnishing.sc.text as string) ?? ''
            if (!path) continue

            const dock = await H.Lang_drive_languish(w, path, text, gen_path)

            // Resolve the RPC once the dock particle exists — Lies' req:Furnishing
            // phase then finds dock-exists on its own re-think.  The remaining
            // Languish phases (compile, grafted) run on Lang's own thinking; the
            // maneuvre's furnish phase guards on the same dock-exists, and graft
            // gates on compile separately.
            if (dock) finish({ path, ready: 1 })
        }
    },

    // ── Lang_drive_languish ────────────────────────────────────────────────────
    //
    //   Mint-or-refresh the per-doc req:Languish and drive one do() pass.
    //   Returns the dock particle once text_loaded has minted it (may be undefined
    //   on the very first pass before the dock exists — the caller's RPC stays
    //   unresolved and re-fires on the next think).
    //
    //   A re-open of an already-finished Languish drops it and its phase subtree,
    //   then remints fresh so every phase re-runs against the newer source.
    async Lang_drive_languish(w: TheC, path: string, text: string, gen_path?: string): Promise<TheC | undefined> {
        const H = this as House
        const rq = H.reqy(w)
        let languish = await rq.roai({ req: 'Languish', path })
        if (languish.sc.finished) {
            w.drop(languish)
            languish = await rq.roai({ req: 'Languish', path })
        }
        if (gen_path) languish.sc.gen_path = gen_path
        languish.c.open_text = text

        console.log(`📄 Lang open_dock → req:Languish ${path}`)
        await rq.do()

        const docks = w.o({ docks: 1 })[0] as TheC | undefined
        return docks?.o({ dock: path })[0] as TheC | undefined
    },

    // ── e_Lang_LE_drop ────────────────────────────────────────────────────────
    //
    //   Mark a clone as a virtual deletion by setting U%unaccepted.
    //   The clone stays in the working tree; LE_push and encode-compare skip it.
    //   DocMinimap's × demote button fires this instead of local demote().
    //
    //   e.sc: { spec: string }
    async e_Lang_LE_drop(A: TheC, w: TheC, e: TheC) {
        const H      = this as House
        const rq     = H.reqy(w)
        const workon = rq.o({ req: 'workon' })[0] as TheC | undefined
        if (!workon) return
        const LE = workon.o({ LE: 1 })[0] as TheC | undefined
        if (!LE) return
        const spec  = e.sc.spec as string | undefined
        if (!spec) return
        const clone = (H.LE_clones(LE) as TheC[]).find(c => (c.sc as any).method === spec)
        if (!clone) return
        H.LE_drop_clone(LE, clone)
        H.feebly_ponder()
    },

    // ── e_Lang_LE_add ─────────────────────────────────────────────────────────
    //
    //   Append a fresh clone to the working tree.
    //   maneuvre reset will re-encode on next cursor tick.
    //
    //   e.sc: { sc: Record<string, any> }   — the sc for the new Point
    async e_Lang_LE_add(A: TheC, w: TheC, e: TheC) {
        const H      = this as House
        const rq     = H.reqy(w)
        const workon = rq.o({ req: 'workon' })[0] as TheC | undefined
        if (!workon) return
        const LE = workon.o({ LE: 1 })[0] as TheC | undefined
        if (!LE) return
        const sc = e.sc.sc as Record<string, any> | undefined
        if (!sc) return
        H.LE_add_clone(LE, sc)
        H.feebly_ponder()
    },

    // ── e_Lang_LE_edit ────────────────────────────────────────────────────────
    //
    //   Patch a clone's sc in place.  maneuvre reset will re-encode on next tick.
    //
    //   e.sc: { spec: string, patch: Record<string, any> }
    async e_Lang_LE_edit(A: TheC, w: TheC, e: TheC) {
        const H      = this as House
        const rq     = H.reqy(w)
        const workon = rq.o({ req: 'workon' })[0] as TheC | undefined
        if (!workon) return
        const LE = workon.o({ LE: 1 })[0] as TheC | undefined
        if (!LE) return
        const spec  = e.sc.spec  as string | undefined
        const patch = e.sc.patch as Record<string, any> | undefined
        if (!spec || !patch) return
        const clone = (H.LE_clones(LE) as TheC[]).find(c => (c.sc as any).method === spec)
        if (!clone) return
        Object.assign(clone.sc, patch)
        H.feebly_ponder()
    },

    // ── e_Lang_LE_push ─────────────────────────────────────────────────────────
    //
    //   The push machine — a coherent, resumable, desire-independent cluster
    //   (Spotlight-Interest-trajectory §3h).  maz bottoms at 1, three phases:
    //     maz:3  encode   — LE_encode_compare; clean → finish (nothing to push)
    //     maz:2  replace   — LE_replace_back, skipping U%unaccepted (the
    //                        irreversible step; reqonce-gated so a re-entry on
    //                        "push anyway" never replaces twice)
    //     maz:1  verify    — LE_pull + re-encode; clean → finish; dirty → stamp
    //                        req:push/%dirty (the fault) and leave open
    //
    //   "Push anyway" re-enters from verify: drop the cluster's %dirty + re-do()
    //   and the encode/replace reqonce gates keep it from re-running.  The cached
    //   encode snaps dumped on working.c.encode (by LE_encode_compare) resume the
    //   push-state across a reload without re-deriving from the live ropeways.
    //
    //   < the spec houses this at w:Lies/req:git so a push reads as a Waftlet
    //     commit on the showy end; that needs a Lies→Lang bridge to the clones,
    //     which isn't built.  Lives on w:Lang for now — where the %LE and its
    //     clone tree actually are — wired to this elvis from DocMinimap's push.
    async e_Lang_LE_push(A: TheC, w: TheC, e: TheC) {
        const H      = this as House
        const rq     = H.reqy(w)
        const workon = rq.o({ req: 'workon' })[0] as TheC | undefined
        if (!workon) return
        const LE = workon.o({ LE: 1 })[0] as TheC | undefined
        if (!LE) return

        // The push cluster hangs off workon (stable for the Lang instance), one
        // per attempt.  Durable + inspectable: phases collapse to %finished, the
        // fault lands as req:push/%dirty.
        const pq = H.reqy(workon)
        ;(await pq.doai({ req: 'push' }))?.(async (push: TheC) => {
            const psub = H.reqy(push)

            ;(await psub.doai({ req: 'encode', maz: 3 }))?.(async (encode: TheC) => {
                const { dirty } = await H.LE_encode_compare(LE)
                if (!dirty) {
                    // nothing to push — finish the whole cluster cleanly.
                    psub.finish(encode)
                    push.sc.clean = 1
                }
                else psub.finish(encode)
            })

            ;(await psub.doai({ req: 'replace', maz: 2 }))?.(async (replace: TheC) => {
                // skip the replace when encode found nothing — clean attempt.
                if (push.sc.clean) { psub.finish(replace); return }
                if (H.reqonce(replace, 'replaced')) {
                    await H.LE_replace_back(LE)
                }
                psub.finish(replace)
            })

            ;(await psub.doai({ req: 'verify', maz: 1 }))?.(async (verify: TheC) => {
                if (push.sc.clean) { psub.finish(verify); return }
                // Post-push: re-pull and re-encode.  The structural goners/neus
                // diff would false-positive on what we just pushed (additions land
                // as neus, unaccepted deletions as goners), so encode-compare is
                // the trustworthy signal — same shallow extent on both sides.
                await H.LE_pull(LE)
                const { dirty } = await H.LE_encode_compare(LE)
                if (dirty) {
                    // fault: push didn't land clean.  Stamp the fault child and
                    // leave verify OPEN so a "push anyway" re-enters here.
                    push.oai({ dirty: 1 })
                    // < req:push/%dirty not yet surfaced in the reqy fault UI.
                    // < vanish: an unaccepted clone's absence lands as a goner on
                    //   this re-pull and reads as dirty.  The pending fix stamps
                    //   bD/was_disincluded:1 before LE_replace_back so resolved_fn
                    //   recognises the expected goner and suppresses it.
                    return   // no finish — stays open
                }
                psub.finish(verify)
            })

            await psub.do()
            psub.unify_finished(pq)
        })

        await pq.do()
        H.i_elvisto(w, 'think')
    },

    // ── e_Lang_workon_update ──────────────────────────────────────────────────
    //
    //   Fired by Lies' cursor seam on every cursor move (Lang_workon_update).
    //
    //   Layout on w:Lang:
    //     /req:workon               — permanent; holds /{LE:1}
    //       /req:awaiting           — one-shot; satisfied on first src arrival,
    //                                 installs Languinio/%LE hold, then stays finished.
    //       /req:maneuvre           — reset on each cursor move; the per-src cluster.
    //         /req:checkout         — LE_arm + LE_pull; (re)create %Interest
    //         /req:furnish          — wait for the dock Lies' Furnishing mints
    //         /req:graft            — Lang_graft_points_once + LE_encode_compare tail
    //       /req:push               — per push attempt (§3h); encode→replace→verify
    //
    //   /{LE:1} and /req:awaiting are never dropped — workon and awaiting are
    //   stable for the lifetime of the Lang instance.  /req:maneuvre is the
    //   resettable shell: dropped and re-seeded on each update so checkout,
    //   furnish, and graft re-run clean against the new src.
    //
    //   e.sc: { src: TheC }
    async e_Lang_workon_update(A: TheC, w: TheC, e: TheC) {
        const H   = this as House
        const src = e.sc.src as TheC | undefined
        if (!src) return

        // req:workon seeded in Lang_plan; find it.
        const rq     = H.reqy(w)
        const workon = rq.o({ req: 'workon' })[0] as TheC | undefined
        if (!workon) return

        // /{LE:1} — stable on workon across all cursor moves.
        const LE = workon.oai({ LE: 1 })

        const sub = H.reqy(workon)

        // req:awaiting — install the Languinio same-object hold exactly once.
        //   reqonce('satisfied') gates the body; finish() keeps it out of do()'s
        //   active set forever after.  Subsequent updates skip straight past it.
        ;(await sub.doai({ req: 'awaiting' }))?.(async (awaiting: TheC) => {
            if (!H.reqonce(awaiting, 'satisfied')) { sub.finish(awaiting); return }
            const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
            if (languinio) {
                await languinio.r({ LE: 1 }, {})
                languinio.i(LE)
            }
            sub.finish(awaiting)
            console.log(`🔗 workon: awaiting satisfied — Languinio/%LE installed`)
        })

        // req:maneuvre — drop any live one, then seed a fresh cluster for this src.
        //   Finished maneuvres are left in place (visible in snap as evidence);
        //   only the live (unfinished) one is dropped so the new src runs clean.
        for (const old of sub.o({ req: 'maneuvre' }) as TheC[]) {
            if (!old.sc.finished) workon.drop(old)
        }
        ;(await sub.doai({ req: 'maneuvre' }))?.(async (maneuvre: TheC) => {
            const msub = H.reqy(maneuvre)

            // Three phases in maz order — do() descends 3→2→1 only when each level
            // finishes.  maz bottoms at 1 (Spotlight-Interest-trajectory §3h), so the
            // old maz:0 encode is folded into the graft tail.
            //   maz:3  checkout  — LE_arm + LE_pull; (re)create %Interest at the clones
            //   maz:2  furnish   — wait for the dock Lies' req:Furnishing mints (no fire)
            //   maz:1  graft     — Pmirror pass once dock + compile index are ready,
            //                      then LE_encode_compare in the same phase tail

            ;(await msub.doai({ req: 'checkout', maz: 3 }))?.(async (checkout: TheC) => {
                H.LE_arm(LE, src)
                await H.LE_pull(LE)
                console.log(`🔗 workon checkout: LE armed at ${(src.sc as any).path ?? (src.sc as any).What ?? '?'}`)

                // §3b — %Interest is Lang's one focus object: the working clone
                // root (its render/edit end) plus a c.LE handle for navigation.
                // Drop + recreate per move, the same discipline LE runs on its
                // Seems, so a stale Interest never points at an old clone tree.
                const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
                if (languinio) {
                    await languinio.r({ Interest: 1 }, {})
                    const working_C = LE.o({ Seem: 'working' })[0]?.sc.C as TheC | undefined
                    const interest  = languinio.oai({ Interest: 1 })
                    interest.sc.src = working_C   // the clone root — the Understanding-pointer
                    interest.c.LE   = LE          // handle for nav: LE.sc.target is the original
                    interest.bump_version()
                }

                // Show a stale spinner in Languinio while the remote has drifted
                // (origin pull returned neus/goners) — cleared when encode finds clean.
                const languinio2 = w.o({ Languinio: 1 })[0] as TheC | undefined
                const state = LE.o({ State: 1 })[0] as TheC | undefined
                if (state?.sc.stale) languinio2?.oai({ spinner: 'stale' })
                else languinio2?.o({ spinner: 'stale' }).forEach((s: TheC) => languinio2.drop(s))
                msub.finish(checkout)
            })

            // req:furnish — wait for the CM dock for this src's path.  Lies owns
            //   doc-open now (req:Furnishing RPC, §3i): the wants resolver seeds it
            //   when the new Spotlight has a doc path, Lies wreads + hands the text
            //   to Lang_open_dock, which mints the dock via req:Languish.  This
            //   phase no longer *fires* anything — it only guards on dock-exists
            //   with a ttlilt backstop; the real re-check rides Lang's own think
            //   when Languish completes (feebly_ponder).  Title-page (no doc_path):
            //   finish immediately — valid, no CM doc needed.
            ;(await msub.doai({ req: 'furnish', maz: 2 }))?.(async (furnish: TheC) => {
                const doc_path = H.Lang_src_doc_path(src)
                furnish.sc.doc_path = doc_path ?? null
                if (!doc_path) { msub.finish(furnish); return }

                const docks = w.o({ docks: 1 })[0] as TheC | undefined
                const dock  = docks?.o({ dock: doc_path })[0] as TheC | undefined
                if (!dock) {
                    // backstop only — holds the snap open while waiting; it does not
                    // re-think.  Lies' Furnishing → Languish completion pokes us.
                    H.i_req_ttlilt(furnish, 0.5, { waiting: 'dock' })
                    return
                }

                H.Lang_set_active_dock(w, doc_path)
                msub.finish(furnish)
            })

            ;(await msub.doai({ req: 'graft', maz: 1 }))?.(async (graft: TheC) => {
                const doc_path = H.Lang_src_doc_path(src)
                if (doc_path) {
                    const docks = w.o({ docks: 1 })[0] as TheC | undefined
                    const dock  = docks?.o({ dock: doc_path })[0] as TheC | undefined
                    if (dock?.o({ Compile: 1 })[0]?.oa({ methods: 1 })) {
                        await H.Lang_graft_points_once(w, dock)
                    }
                }
                // encode folded into the graft tail (§3h: maz bottoms at 1).
                //   LE_encode_compare sets %State.changey; NaviCado reads it to
                //   decide whether a push is meaningful.  One-shot per maneuvre.
                const working = LE.o({ Seem: 'working' })[0] as TheC | undefined
                if (working?.sc.C !== undefined) {
                    await H.LE_encode_compare(LE)
                }
                msub.finish(graft)
            })

            await msub.do()
            msub.unify_finished(sub)
        })

        await sub.do()
        H.i_elvisto(w, 'think')
    },

    // ── Lang_src_doc_path ─────────────────────────────────────────────────────
    //
    //   Derive the CM doc path from a src that may be a %What or a %Doc.
    //     %Doc src: sc.path directly.
    //     %What src: first %Doc child's sc.path (Lies_what_first_doc_path logic).
    //     Pure time-slice %What with only direct %Points and no %Doc child:
    //       returns undefined — no CM doc to open; valid title-page state.
    Lang_src_doc_path(src: TheC): string | undefined {
        const sc = src.sc as any
        // %Doc has sc.path set (by Waft convention)
        if (sc.path) return sc.path as string
        // %What may hold %Doc children
        const doc = (src.o({ Doc: 1 }) as TheC[])[0]
        return doc?.sc.path as string | undefined
    },

//#region Languish

    // ── req:Languish — Lang's mind for one doc ────────────────────────────────
    //
    //   The do_fn for a /req:Languish.  Stages three maz-ordered phase reqs on
    //   the Languish particle and runs them; unify_finished finishes Languish
    //   when all three are done.  Multi-maz do() descends through the levels in
    //   one pass when each fully finishes, so on a fast (soft) compile all three
    //   phases can complete in a single tick.
    //
    //     req:text_loaded, maz:3   mint dock + install text; wait for CM mount
    //     req:compile,     maz:2   build the methods index; hold for hard-write
    //     req:grafted,     maz:1   resolve Pmirrors against the index
    //
    //   Phases hang off the Languish req (c.up = languish), so a ttlilt on a
    //   phase climbs languish → w:Lang and sets w:Lang.c.has_req_ttlilt — no
    //   scheme:req extension needed for the phase subtree.
    async req_Languish(req: TheC, q: any) {
        const H = this as House

        const sub = H.reqy(req)
        await sub.roai({ req: 'text_loaded', maz: 3 })
        await sub.roai({ req: 'compile',     maz: 2 })
        await sub.roai({ req: 'grafted',     maz: 1 })

        await sub.do()
        sub.unify_finished(q)
    },

    // ── req:text_loaded, maz:3 ────────────────────────────────────────────────
    //
    //   reqonce: mint the dock particle, stamp gen_path, install the source into
    //   the ave/{lang_dock:path} text particle, set the doc active.  Records
    //   languish.sc.dock so the later phases find it without re-deriving.
    //
    //   The genuinely-async wait is the CodeMirror round-trip: Lang writes the
    //   ave text → Langui renders → CM mounts → e_Lang_editorBegins stamps
    //   dock.c.state and feebly_ponders.  We hold Story open with a ttlilt until
    //   dock.c.state appears; the feebly_ponder wakes this monitor precisely
    //   when it lands.
    async req_text_loaded(req: TheC, q: any) {
        const H = this as House
        const languish = req.c.up as TheC
        const w        = languish.c.up as TheC
        const path     = languish.sc.path as string
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined

        if (H.reqonce(req, 'opening')) {
            // one chance: mint dock + install text.  Replaces the old inline
            // e_Lang_open_dock body.
            languinio?.oai({ spinner: 'text_load' })

            const gen_path = languish.sc.gen_path as string | undefined
            const text     = (languish.c.open_text as string) ?? ''

            const docks = w.oai({docks: 1})
            const dock = docks.oai({dock: path})
            if (gen_path) dock.sc.gen_path = gen_path
            languish.sc.dock = dock

            const ave = H.oai_enroll(H, { watched: 'ave' })
            const docTextC = ave.oai({ lang_dock: path })
            // disk_dige / text_dige: both start equal to the on-disk content.
            // They diverge once the user edits (text_dige moves, disk_dige stays
            // until LiesStore confirms the write).  disk_rev marks disk-origin
            // installs so Langui's disk-reload $effect can gate on them.
            const initial_dige = text ? await dig(text) : ''
            docTextC.sc.disk_dige = initial_dige
            docTextC.sc.text_dige = initial_dige
            if (docTextC.sc.text !== text) {
                docTextC.sc.text = text
                docTextC.sc.disk_rev = ((docTextC.sc.disk_rev as number) ?? 0) + 1
                docTextC.bump_version()
            }

            // always activate — Lies owns doc order, last open wins for now
            this.Lang_set_active_dock(w, path)
            w.i({ received: 1, doc_opened: 1, doc: path })
        }

        // monitor: CM has mounted and handed us its EditorState.  Until then
        // there is nothing to compile.  e_Lang_editorBegins feebly_ponders when
        // it stamps dock.c.state, which re-enters here.
        const dock = languish.sc.dock as TheC | undefined
        if (!dock?.c.state) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'cm_mount' })
            return
        }
        languinio?.o({ spinner: 'text_load' }).map(s => languinio.drop(s))
        q.finish(req)
    },

    // ── req:compile, maz:2 ────────────────────────────────────────────────────
    //
    //   reqonce: run the synchronous index build (Lang_compile_dock) once.  With
    //   multi-maz do(), this fires in the same tick text_loaded finishes.
    //
    //   %Compile/%methods is populated synchronously by Lang_compile_dock, so a
    //   soft-compile finishes this phase immediately.  For a hard-compile the
    //   %Pending flag stays set while Lies writes the gen file; we hold Story
    //   open with a ttlilt until %Pending clears, so the gen file exists before
    //   the snap.  Either way %methods — the only thing grafting needs — is
    //   present the instant Lang_compile_dock returns.
    async req_compile(req: TheC, q: any) {
        const H = this as House
        const languish = req.c.up as TheC
        const w        = languish.c.up as TheC
        const dock     = languish.sc.dock as TheC
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined

        if (H.reqonce(req, 'firing')) {
            // one chance: state is in — build the index.
            languinio?.oai({ spinner: 'compile' })
            await this.Lang_compile_dock(w, dock)
        }

        const job = dock.o({ Compile: 1 })[0] as TheC | undefined

        // compile error is a terminal: methods will never appear and Pending
        // never clears, so don't ttlilt forever — finish and let grafting find
        // nothing (the minimap surfaces unresolved Pmirrors).
        if (dock.oa({ compile_error: 1 }) || job?.oa({ compile_error: 1 })) {
            languinio?.o({ spinner: 'compile' }).map(s => languinio.drop(s))
            q.finish(req)
            return
        }

        // index missing → compile hasn't run yet; methods present is the graft
        // gate.  hold until it appears.
        if (!job || !job.oa({ methods: 1 })) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'methods' })
            return
        }
        if (job.oa({ Pending: 1 })) {
            // methods are ready (grafting could proceed) but the hard-compile
            // gen-file write is still in flight — hold Story so the file lands
            // before the snap, then re-check next think.
            H.i_req_ttlilt(req, 0.5, { waiting: 'gen_write' })
            return
        }
        languinio?.o({ spinner: 'compile' }).map(s => languinio.drop(s))
        q.finish(req)
    },

    // ── req:grafted, maz:1 ────────────────────────────────────────────────────
    //
    //   reqonce: run the graft pass once against the now-ready index.  Always
    //   finishes — unresolved Pmirrors are a valid terminal state (DocMinimap
    //   surfaces them), not a reason to hold Story open.
    async req_grafted(req: TheC, q: any) {
        const H = this as House
        const languish = req.c.up as TheC
        const w        = languish.c.up as TheC
        const dock     = languish.sc.dock as TheC
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined

        if (H.reqonce(req, 'ran')) {
            languinio?.oai({ spinner: 'grafted' })
            await this.Lang_graft_points_once(w, dock)
        }
        languinio?.o({ spinner: 'grafted' }).map(s => languinio.drop(s))
        q.finish(req)
    },

//#endregion

    async e_Lang_set_doc(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) throw "!A"
        const path = e.sc.dock as string | undefined
        if (!path) return
        // update the ave text-sync particle for this doc path
        const ave = this.oai_enroll(this as House, { watched: 'ave' })
        const docTextC = ave.oai({ lang_dock: path })
        const text = e?.sc.text as string | undefined
        if (text == null) return
        if (docTextC.sc.text === text) return
        docTextC.sc.text = text
        docTextC.sc.text_dige = await dig(text)
        docTextC.bump_version()
        // no main() — UI initiated this, no one else needs waking
    },

// ── Lang_update_change ───────────────────────────────────────────────────────
    //
    //   Writes the three-leg change strip into w/{Languinio:1}/{Change:1}.
    //   Three child particles, one per leg:
    //
    //     /{backend:1}  sc.dige — current editor-text dige (from ave/lang_dock)
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
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const path = dock.sc.dock as string

        // Read current dige values.
        // lang_dock is absent until req_text_loaded's dig() resolves — bail rather
        // than blanking Change with empty strings.  The tick will re-run once
        // e_Lang_open_dock lands and populates the text particle.
        const lang_dock      = ave.o({ lang_dock: path })[0] as TheC | undefined
        if (!lang_dock) return
        const text_dige     = (lang_dock.sc.text_dige as string ?? '').slice(0, 5)
        const disk_dige     = (lang_dock.sc.disk_dige as string ?? '').slice(0, 5)

        const job           = dock.o({ Compile: 1 })[0] as TheC | undefined
        const output        = job?.o({ Output: 1 })[0]  as TheC | undefined
        const compiled_dige = ((output?.sc.source_dige as string) ?? '').slice(0, 5)
        // sc.compile from %time is the synchronous cost — what the compiler actually spent.
        const compile_cost  = (job?.o({ time: 1 })[0] as TheC | undefined)?.sc.compile as number ?? 0
        const pending       = !!job?.oa({ Pending: 1 })

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
        console.log(`Lang!`)

        if (!w.c.plan_done) await this.Lang_plan(A, w)
        // these go every time so their toggle state can visually change
        let on_change = () => this.main()
        // whether Lang-Cyto does compound_nodes
        await this.i_actions_to_c(w, 'compo',{ stashed: true, on_change })

        const dock = this.Lang_active_dock(w)

        // compile reply polling — re-polls i_elvis_req while w/{dock}/Compile/Pending
        // is set; when the Wormhole reply lands, notifies Pantheate.
        if (dock?.oa({ Compile: 1 })) {
            await this.Lang_compile_step(A, w)
        }

        // language picker + gen button — registered fresh each tick so the
        // dropdown reflects the active doc's current language override.
        await this.LangGen_tick(A, w)

        // ── drive Languish + workon + Furnishing + push ──────────────
        // Languish stages text_loaded → compile → grafted for each open doc.
        // workon/maneuvre drives checkout → furnish → graft per cursor move.
        // do() is cheap (skip) once reqs are finished; reqy_recurse drives nested.
        const rq = H.reqy(w)
        await rq.do()

        // §3i — drain Lies' Furnishing RPC each tick.  o_elvis(self-declares the
        // type) so the courier elvis routes to this main method, not an e_ handler;
        // the first drain enrols 'Lang_open_dock' so subsequent ones land here too.
        await this.e_Lang_open_dock(A, w)

        // Drive workon's inner cluster (maneuvre + push + their phases) from the
        // tick so a furnish-phase ttlilt re-checks the dock on each think, and a
        // verify-phase re-entry (push anyway) re-runs.
        const workon = rq.o({ req: 'workon' })[0] as TheC | undefined
        if (workon) {
            const sub = H.reqy(workon)
            await sub.do()
            const maneuvre = sub.o({ req: 'maneuvre' })[0] as TheC | undefined
            if (maneuvre && !maneuvre.sc.finished) {
                const msub = H.reqy(maneuvre)
                await msub.do()
            }
            const push = sub.o({ req: 'push' })[0] as TheC | undefined
            if (push && !push.sc.finished) {
                const psub = H.reqy(push)
                await psub.do()
            }
        }

        // §3g — re-decorate from the U sphere after graft has minted Pmirrors.
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

        // Push the three-leg change strip into Languinio/Change for Langui.
        if (dock) await this.Lang_update_change(w, dock)

        // < first compile per doc is now Languish's req:compile phase, not a
        //   tick-time ever_compiled guard.  Re-compile on edit / manual compile
        //   still flows through the Lang_compile action.
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

    // ── e_Lang_i_bookmark ────────────────────────────────────────────────────
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

    // ── e_Lang_i_alterationStation ───────────────────────────────────────────
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
        // updateListener fires Lang_set_doc (dock updated) and arms the 800ms timer.
        view.dispatch({ changes: { from: line.from + idx, to: line.from + idx + match.length, insert: replacement } })

        // saveEffect flushes bookmark positions immediately — updateListener cancels
        // the debounce and fires Lang_update_bookmarks with the fresh editorState.
        view.dispatch({ effects: dock.c.saveEffect.of(null) })
        console.log(`Lang_i_alterationStation — line ${line_n} [${match}] → [${replacement}], saveEffect dispatched`)
    },


//#region bm e
    // Ctrl+B from the editor — create a w/{dock}/%bookmark at the current selection.
    //
    // The editor marks the range with a CodeMirror Decoration.mark so from/to
    // track document edits automatically. Periodic e_Lang_update_bookmarks
    // calls push the live mark positions (and a fresh editorState) back here.
    //
    // e.sc carries: doc, from, to, label?, view, state
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
        console.log(`🔖 add_bookmark id=${id} [${from}..${to}] ${label}`);
        this.i_elvisto(w, 'think', {});
    },


    // Fired by the editor after the debounce (or immediately via saveEffect).
    //
    // Carries the live from/to for every bookmark still present in the CM
    // decoration set, plus a fresh editorState so whatsthis() sees the updated
    // parse tree.  Any known bookmark id absent from updates[] has vanished —
    // its decoration was wiped by an edit that fully replaced its span.
    //
    // e.sc carries: doc, updates=[{id, from, to}], view, state
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

    // ── e_Lang_update_grafts ─────────────────────────────────────────────────
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

    // ── e_Lang_remove_bookmark ───────────────────────────────────────────────
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

    // ── e_Lang_point_fuzzify ─────────────────────────────────────────────────
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

    // ── e_Lang_stamp_bookmark_serial ─────────────────────────────────────────
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
<LangGen {M} />
<LangGraft {M} />