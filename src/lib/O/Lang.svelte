<script lang="ts">
    // Lang.svelte — ghost for Language / CodeMirror / Lezer integration.
    //
    // This is the high-level "join" ghost.  Most of the compilation guts live
    // in LangCompiling.svelte (Lang_compile / Lang_drain_compile_settles / …); Lang.svelte
    // keeps the per-doc lifecycle (plan / whatsthis / bookmark actions) and
    // threads the compile trigger + reply-polling into that lifecycle.
    //
    // ── Language goals (the .g DSL; compiled in LangCompiling/compile.ts) ──────
    //
    //   Receivers (X i …)  — a bareword before the verb is the call receiver
    //       A i %prefixy:'sivi'   →  A.i({prefixy:'sivi'})
    //     JS keywords (return, let, …) are NEVER receivers, so "let la = i a/b" keeps
    //      its "let la = " prefix verbatim.  Older "$name" leg-0 hint still works.
    //
    //   Captures (name$, name$:var)  — trailing $ on the last leg captures the row
    //       o with$:vish   →  let vish = w.o({with:1})[0]   (colon-value names the target
    //                          var, not a filter).  Multi-leg captures route _o_drill1.
    //
    //   let-sugar ($name = expr)  — a single "=" (not ==, +=) after a leading $name
    //       $its = 'ferv'   →  let its = 'ferv'
    //
    //   Puddle values (%key:'string literal')  — % before a PeelKey makes the colon-value
    //     a raw TS expr, emitted VERBATIM (no exactly filter).  StringVal does 'single'|
    //      "double"|`backtick`.  Next: multi-token puddle blocks (arithmetic/calls).
    //
    //   Ampersand calls (&method,arg,…)  → this.method(arg,…), bracket/string-aware so
    //     object-literal args keep their own commas.  Works standalone and in if/elsif
    //      conditions, incl. the pythonic colon form (trailing ":" dropped, indent marks
    //       the block) and the &&-continuation.  The arg list is raw text — no inner stho.
    //
    //   "and" block (LHS and <io>)  — LHS is the condition, the IO expr the single-stmt body
    //       !0 and w i wibble   →  if (!0) { w.i({wibble:1}) }   (body is a block, holds ";")
    //
    //   async on defs  — "async name(…)" stamps async:1 on the word-index entry, for a
    //     future pass to decide await-injection.   < the await-injection isn't wired up.
    //
    //   .$ tight value-capture (key.$ , key.$:var , key:val.$)  — "." binds to its key and
    //     grabs that key's VALUE (not the row), assigned inline among peel items:
    //       o prefixy,wither.$:ang   →  let ang = w.o({prefixy:1,wither:1})[0]?.sc.wither
    //     Built (CaptureDot); LakeTiles.g l.281 is the live example.
    //
    // ── Deferred / infirm syntax (parses, not yet compiled) ───────────────────
    //   Inline {}-block verbs (r/roai/oai/replace + trailing {}).  The pythonic indented-
    //     body form is BUILT (becomes the do_fn, compile_collect's IOing branch):
    //       r %pat   →  await w.replace({pat}, async () => { …body… })
    //     Infirm: the SAME-LINE trailing-{} and the jammed multi-leg capture
    //      (w oai docs/doc,$path$dock) — bareword values want a STRING here (diverges from
    //       i/o's identifier convention) and $path$dock needs grammar support.
    //       < prefer the pythonic body; clean capture today is name$ / name$:var.
    //
    // ── Document registry ────────────────────────────────────────────────────
    //   w/{docks:1}/{dock:path} — one particle per open document.
    //     c: { view, state, addBookmarkMark, clearAllBookmarks, saveEffect, last_whatsthis_dock }
    //     sc: { doc:path, active:1? }
    //     {bookmark:'bm_…',from,to,label} · {Compile:1}/{Output:1,name,source,dige}|{Pending:1}
    //     {req:'Languish'}  — per-dock mind: text_loaded → compile.
    //   Bookmarks, compile, Languish live on dock (not w) so they can be r()'d per doc.
    //
    // ── Understanding hold ───────────────────────────────────────────────────
    //   w/{LE:<waft>}  — one Understanding PER open giver, keyed by its giver Waft so
    //     several coexist; stable (here, outside replace()), held on its Interest's c.LE.
    //      Foreground resolved via %ActiveInterest, NOT a singleton (Lang_active_LE);
    //       switching foreground reuses a giver's preserved working clone — the crossfade.
    //     /%State  — synthesised armed/changey/stale  (//%push_dirty = push-didn't-land fault)
    //     /%Seem:origin / /%Seem:working
    //
    //   w/{req:'workon'}  — open-ended, one per Lang instance.  do_fn req_workon is the thin
    //     per-tick driver: roai's each stage with its input signature (un-finishing a
    //      %permanent stage on drift), then pumps the pipeline; invalidation cascades forward.
    //     c.src  latest cursored TheC (stashed by e:Lang_lango, the cursor Lango)
    //     /{req:'understanding',maz:3}  re-arm LE + flush; sets %Interest.  c.armed_src =
    //        identity-keyed re-arm gate (memoised); sc.what = cursored What|path label.
    //     /{req:'ingredients',maz:2}    the wanted %Goods, from %Interest
    //       /{req:'furnishing',path}    one per wanted dock; gate+ttlilt+dock_askies pull;
    //          finished when its dock has content_dige.
    //     /{req:'instrumentation',maz:1} compile + graft the active dock.  sc.have_Map,
    //        sc.n_pmirrors = convergence markers (results on dock).
    //
    //   w/{Languinio:1}  — Lang's one focus object enrolled in ave; c.w back-refs w:Lang.
    //     Children ordered by volatility (dock on doc-switch, Interest on every checkout).
    //     c.active_LE  — off-snap handle to the foreground giver's w/{LE:<waft>} ("the LE
    //        driving now"); repointed each checkout|foreground.  No singleton {LE:1} hold.
    //     /{ActiveInterest:1}  kind + waft of the foreground LE-bearing Interest.
    //     /{dock:path}  same-object hold on the active CM doc; re-pointed by
    //        Lang_set_active_dock on every doc switch.
    //     /{Interest:1}  sc.src = working clone root; c.LE = its own %LE; c.What = live
    //        %What; sc.in_Doc|in_Point = C-side address mirroring Lies' %Spotlight (in_Doc
    //        keys ingredients AND selects the active dock).  Dropped+recreated by
    //        Lang_set_interest each checkout.
    //
    // ── Reactive text sync ───────────────────────────────────────────────────
    //   dock/{Text:1} — one per doc, holds sc.dige/disk_dige/disk_rev; dock.c.text holds
    //     the source string (hidden from snap).  Langui (keyed by `doc` prop) watches it.
    //
    // ── Active doc ───────────────────────────────────────────────────────────
    //   w.c.active_dock_path — a routing string (not business state, not r()'able).
    //     Lang_active_dock(w) resolves it to the {dock:path} particle;
    //     Lang_set_active_dock(w,path) sets it and marks dock.sc.active.
    //
    // ── DRY state update ─────────────────────────────────────────────────────
    //   Every CM event carries { doc:path, view, state } in e.sc.  Lang_dock_from_event
    //     finds-or-creates the dock and writes dock.c.view/state in exactly one place.
    //
    // ── whatsthis cache ──────────────────────────────────────────────────────
    //   dock.c.last_whatsthis_dock — the EditorState.doc rope from the last whatsthis().
    //     CM ropes are immutable, so identity equality is an O(1) reliable change-skip.
    //
    // ── Deposits ─────────────────────────────────────────────────────────────
    //   whatsthis(state, container, bookmarks, opt) walks the Lezer parse tree and i()s
    //     TheC nodes (Line, node, texts, text); w:Lang runs one call per %bookmark into
    //     a per-bookmark subcontainer under model/**.
    //
    // ── State flows (takes / makes; ← source; "below" = full inline doc at the handler) ──
    //   e:Lang_lango ← Lies_i_Spotlight (each cursor move = a %Lango/%Cursor): e%src → workon.c.src; think
    //   req_workon (per-tick driver): src, %LE ver+U_serial, dock+dige → per-stage sig; roai's
    //     it (un-finishes %permanent on drift); pumps the 3-stage pipeline
    //   req:understanding (the %Waft|%LE boundary): src,%LE,origin_dirty → %Interest (clone root,
    //     c.LE, in_*); %State.changey (LE_encode_compare); auto-push on working drift
    //   e:mark / e:LE_mark ← NaviCado/snaps: e%LE,op,spec → U.sc.unshowing|unaccepted (clone.sc
    //     for add|edit); U_serial++ → understanding sig drifts → re-encode → changey → auto-push
    //   e:Lies_waft_mutated ← watch_c(waft): waft_key → LE.c.origin_dirty → re-pull origin (below)
    //   e:dock_content ← Lies push|pull: e%Good → the dock, content_dige, req:Languish (below)
    //   e:LE_operate%op=push ← NaviCado/DocMinimap → req:push|encode|replace|verify under %LE
    //   e:Lang_editorBegins ← Langui on CM mount → dock.c.view/state, %bookmark sync (below)
    //   Lang_update_change (each tick) → %Languinio/%Change/{backend|storage|compile} (below)
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
    import LiesHold from "./LiesHold.svelte";   // the Understanding home — dual-mounted so req:workon's do_fns are present wherever Lang runs

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

        // ── Styles bucket for Cyto ──────────────────────────────────
        // Share Story's bucket when the full machine is up (same swatches Story persists).
        //  Standalone (Editron|runner) has no H:Story → own a {Styles:1} on w:Lang, which
        //   The_Styles' contract sanctions, so Cyto gets real swatches not a palette-fallback.
        const topH    = H.top_House()
        let stylesC: TheC | null = null
        const storyH = topH.o({ H: 'Story' })[0] as TheC | undefined
        if (storyH) {
            // Full machine: share Story's. A throw here is the transient "Story up but its
            //  .c.The not stamped yet" race — leave null so Cyto palette-falls-back this pass.
            try { stylesC = H.The_Styles((storyH as any).Awo('Story', 'Story')) }
            catch { console.warn(`Lang: H:Story present but no The yet — Cyto palette-fallback`) }
        } else {
            stylesC = w.oai({ Styles: 1 }) as TheC
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
        // feebly so a context with no Cyto ghost (headless runner / non-useCyto Story) no-ops
        //  instead of throwing "no House has A:Cyto".  Lang is a Cyto *client* — it commissions
        //   one if present, never creates it (unlike Story the owner).  Mirrors the other feebly Cyto sites.
        H.feebly_i_elvisto(`Cyto/Cyto`, 'Cyto_commission', { req: commission })

        // ── %Languinio — Lang's reactive signal particle ────────────
        // Parallel to %examining on w:Lies; enrolled in ave so UItime (Langui, DocMinimap)
        //  reads it without a new prop.  c.w back-refs w:Lang.  Holds %LE/%dock/%Interest
        //   in volatility order (see header).
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const languinio = w.oai({ Languinio: 1 })
        // runner-flavoured Lang folds the editor-nav apparatus out of the snap.  Languinio
        //  is in ave, so the w:Lang %dontSnap fold doesn't reach it — stamp Languinio itself
        //   (snap-only; editor still runs).  Role decided in one place via Lies_is_runner.
        if (H.Lies_is_runner(w)) languinio.sc.dontSnap = 1
        ave.i(languinio)
        languinio.c.w = w

        // ── per-Interest Understandings ──────────────────────────────
        // No singleton LE — each giver carries its own %LE, minted on checkout in
        //  Lang_set_interest, held on interest.c.LE, parented here under w (outside any
        //   replace()) so it survives every checkout.  See header "Understanding hold".

        // ── req:workon — the convergence home ────────────────────────
        // Open-ended anchor; do_fn req_workon is the per-tick driver (see header).  Each stage
        //  holds wants + convergence-markers only — its durable output lives elsewhere
        //   (%LE/%Seem, %Good, the dock), so de-finishing a drifted stage loses nothing.
        const workon = await w.oai({ req: 'workon' }, { w })

        // auto_push on by default — changey working drift with a stable origin flushes
        //   straight back to the Waft (the OC is the working set, touring sheds nothing).
        //   Opt nopush turns it off so a test can see the changey|push truthiness unhidden.
        workon.sc.auto_push = !!H.o_Opt_val(w, 'nopush') ? 0 : 1

        // Stage reqs — %permanent so a signature roai un-finishes them with a fresh lease.
        //  maz orders the pipeline understanding(3)→ingredients(2)→instrumentation(1); a stage
        //   that bows out on a ttlilt stops do() at its level, gating the lanes below.
        await workon.oai({ req: 'understanding',  maz: 3, permanent: 1 })
        await workon.oai({ req: 'ingredients',    maz: 2, permanent: 1 })
        await workon.oai({ req: 'instrumentation', maz: 1, permanent: 1 })

        w.c.plan_done = true
    },

//#region doc routing helpers

    // ── Lang_dock_from_event — DRY router at the top of every CM event handler.
    //   Creates-or-finds the {dock:path} under w/{docks:1} and writes dock.c.view/state
    //   in one place; returns the dock.
    Lang_dock_from_event(w: TheC, e: TheC): TheC {
        // e.sc.dock is stamped by Langui on every CM-sourced event.  Internally-fired
        //  events (e_Lang_i_bookmark, test macros) don't go through Langui → fall back to
        //   the active doc, which is the right target in that case.
        const path = (e.sc.dock as string) || (w.c.active_dock_path as string)
        if (!path) throw 'Lang_dock_from_event: no doc and no active doc yet'
        const docks = w.oai({docks: 1})
        const dock = docks.oai({dock: path})
        if (e.sc.view)  dock.c.view  = e.sc.view
        if (e.sc.state) dock.c.state = e.sc.state
        return dock
    },

    // ── Lang_active_dock — the {dock:path} for the active doc, or undefined pre-editorBegins.
    Lang_active_dock(w: TheC): TheC | undefined {
        const path = w.c.active_dock_path as string | undefined
        if (!path) return undefined
        const docks = w.o({docks: 1})[0] as TheC | undefined
        return docks?.o({dock: path})[0] as TheC | undefined
    },


    // ── Lang_set_active_dock ──────────────────────────────────────────────────
    //   Marks `path` active: stamps dock.sc.active, re-points the same-object
    //   %Languinio/%dock hold (so every Languinio reader reaches the live dock), and tells
    //   w:Lies.  %Languinio/%dock is the single foreground-doc truth (ave/%active_dock gone);
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
        // place() re-points the same-object dock hold into %Languinio (consumers reach it via
        //  languinio.o({dock:1})[0] without an ave round-trip).  place() not r(): the dock's X
        //   (%Compile, %Pmirrors) belongs to the dock, and r()→replace()/resolve() would flag
        //    them "n have /*" (a lose-children diagnostic), wrong for re-pointing an existing hold.
        //   < the old r().then(i()) put i() in a microtask outside Atime; place() is gap-safe
        //     since Svelte effects are on setTimeout and can't observe the drop→insert.
        const dock = docks?.o({dock: path})[0] as TheC | undefined
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        if (languinio && dock) {
            await languinio.place({ dock: 1 }, dock)
        }
        // Tell w:Lies the foregrounded doc changed — direct Atime elvis.
        H.i_elvisto('Lies/Lies', 'Lies_active_doc_changed', { path })
    },

//#endregion
//#region e

//#region e cm -> Lang
    // ── e:Lang_editorBegins ── CM mounted a view.  Registers view+state via the DRY
    //   router and reconciles live bookmark positions from the CM state.
    async e_Lang_editorBegins(A, w, e) {
        const dock = this.Lang_dock_from_event(w, e)

        // CM StateEffects are per-view, so they live on dock.c — not w.c.
        dock.c.addBookmarkMark    = e.sc.addBookmarkMark
        dock.c.removeBookmarkMark = e.sc.removeBookmarkMark
        dock.c.clearAllBookmarks  = e.sc.clearAllBookmarks
        dock.c.saveEffect         = e.sc.saveEffect
        // Pmirror graft marks live in their own StateField; LangGraft dispatches these to
        //  install/remove marks as Pmirrors are minted and reaped.
        dock.c.addGraftMark       = e.sc.addGraftMark
        dock.c.removeGraftMark    = e.sc.removeGraftMark
        dock.c.clearAllGrafts     = e.sc.clearAllGrafts
        // Point decoration + fold handles — Lang_show_pmirrors dispatches through these.
        //   setPointDecorations = glow|enlarge field; setPointFonts = per-line font field
        //    (LangPoint grows surviving headers as bodies fold); setPointFolds(view,showing,
        //     hiding) dispatches fold|unfoldEffect; unfoldAllFolds lifts every fold (no Points / wipe).
        dock.c.setPointDecorations = e.sc.setPointDecorations
        dock.c.setPointFonts       = e.sc.setPointFonts
        dock.c.setPointFolds       = e.sc.setPointFolds
        dock.c.unfoldAllFolds      = e.sc.unfoldAllFolds
        // seek(view, from, to) — unfold what hides the span, select + centre it.
        // Mapule.c.goto rides this so navigation needs no CM imports outside Langui.
        dock.c.seek                = e.sc.seek
        // foldToggle(view, from, to) — fold|unfold one body range; Mapule.c.fold rides it.
        dock.c.foldToggle          = e.sc.foldToggle

        // Only activate with a real path — empty string means Lies hasn't handed back the %Good yet.
        if (!w.c.active_dock_path && e.sc.dock) {
            await this.Lang_set_active_dock(w, e.sc.dock as string)
        }
        // The dock hold lives on %Languinio.  On first open it may have been re-pointed
        //  before the dock existed; re-point here only if active and the hold is missing|stale.
        if (w.c.active_dock_path === dock.sc.dock) {
            const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
            const held = languinio?.o({ dock: 1 })[0] as TheC | undefined
            if (languinio && held !== dock) {
                // Same-object hold re-point — see Lang_set_active_dock for the why.
                await languinio.place({ dock: 1 }, dock)
            }
        }

        w.i({ received: 1, editorBegins: 1, doc: dock.sc.dock })

        // Shared view just arrived (Langui re-registers each switch): clear orphan graft marks
        //  left by other docks and install this dock's own set; forces a decoration|fold repaint.
        this.Lang_reassert_graft_marks(dock)

        // ── Bookmark position sync ──
        // Langui passes `updates` (live CM positions) on every editorBegins; reconcile against
        //  the dock so whatsthis() never sees stale from/to.  Also re-dispatch addBookmarkMark for
        //   bookmarks present in dock but absent from the restored CM state (a programmatic add
        //    whose dock was switched before the StateField captured it).
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

        // dock.c.state just got stamped — a req:text_loaded ttlilt may be waiting on exactly
        //  this; wake a think so its monitor re-checks and descends to compile.
        ;(this as House).feebly_ponder()
    },
    // ── e:Lang_texting ── text arrived from the UI (80ms throttle) or from
    //   e_Lang_i_alterationStation (machine:true, fires immediately).  Updates dock.c.text +
    //   dock/{Text:1}, then drives Languish.  machine:true → compile_ready after 30ms; else
    //   after 6s of quiet typing.  Esc calls Lang_compile directly, bypassing the timer.
    //   e.sc: { dock_path, text, machine? }
    async e_Lang_texting(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) throw "!A"
        const path = e.sc.dock_path as string | undefined
        if (!path) throw "!path"
        const text = e?.sc.text as string | undefined
        if (text == null) throw "!text"
        const machine = !!e.sc.machine

        // dock.c.text holds the string silently (hidden from snap); the Text child carries
        //  the dige so Langui tracks changes without the giant string in the snap.
        const docks  = w.o({ docks: 1 })[0] as TheC | undefined
        const dock   = docks?.o({ dock: path })[0] as TheC | undefined
        if (!dock) return
        if (dock.c.text === text) return
        dock.c.text = text
        const new_dige = await dig(text)
        await dock.oai({ Text: 1 }, { dige: new_dige })

        // find req:Languish on the dock (not on w anymore) and drive text_mutated
        const languish = dock.o({ req: 'Languish' })[0] as TheC | undefined
        if (!languish) return
        const tm = languish.o({ req: 'text_mutated' })[0] as TheC | undefined
        if (tm) this.reqyoncile(tm, { text, ...(machine ? { machine: 1 } : {}) })
        // reqyoncile Languish itself so its req.do() runs in this same pass,
        //   driving text_mutated without needing a separate Lang think()
        this.reqyoncile(languish, {})
    },
    async req_text_mutated(req: TheC) {
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
    // ── e:Dock_open ── Liesui/Waft/DocRow click on a Doc label or a Point inside one.
    //   Switches the active doc to `path`.  e.sc.point (optional) — navigate to it once
    //   active (resolved + scrolled here, w:Lang-side; the UI just passes the raw value).
    //   e.sc: { path, point? }
    async e_Dock_open(A: TheC, w: TheC, e: TheC) {
        const path  = e.sc.path  as string | undefined
        const point = e.sc.point as string | undefined
        if (!path) return

        // Switch active doc — Langui's $effect on %Languinio/%dock reacts.
        await this.Lang_set_active_dock(w, path)

        // Point navigation: e_Lang_point_navigate (LangRegions) resolves the spec, applies
        //  region openness, scrolls, and reports issues back to Lies via e:Lies_point_issues.
        if (point) {
            this.i_elvisto('Lang/Lang', 'Lang_point_navigate', { point, doc: path })
        }

        this.i_elvisto(w, 'think')
    },

    // ── Lang_open_dock ── mint-or-refresh the per-dock req:Languish and drive one do() pass;
    //   returns the dock.  A re-open of an already-finished Languish drops it + its phase subtree
    //   and remints, so every phase re-runs against the newer source.  Languish lives on the
    //   dock; dock.c.up=docks, docks.c.up=w (stamped at mint) so reqyoncile's %w walk and
    //   i_req_ttlilt reach w:Lang.
    async Lang_open_dock(w: TheC, dock: TheC, text: string): Promise<TheC> {
        let languish = await dock.oai({ req: 'Languish' })
        if (languish.sc.finished) {
            dock.drop(languish)
            languish = await dock.oai({ req: 'Languish' })
        }
        languish.c.open_text = text

        const path = dock.sc.dock as string
        console.log(`📄 Lang open_dock → req:Languish ${path}`)
        await dock.do()

        return dock
    },


    // ── e:Lies_waft_mutated ── Lies' watch_c(waft) on any loaded-Waft OC change (CRUD,
    //   rename, test edit).  If our armed target lives there, Seem:origin is stale — stamp
    //   LE.c.origin_dirty (off-snap) + poke think; the understanding sig re-pulls origin and,
    //   when the drift is inside the checked-out extent, auto-pulls into the working clone.
    //   Membership-gated: an edit elsewhere in the same Waft re-pulls to a cheap no-op.
    //   e.sc: { waft_key }
    async e_Lies_waft_mutated(A: TheC, w: TheC, e: TheC) {
        const H        = this as House
        const waft_key = e.sc.waft_key as string | undefined
        if (!waft_key) return
        // Per-Interest LEs: stale only the LE(s) checked out into THIS Waft, even when another
        //  giver is foreground.  w.o({LE:1}) wildcards over them all (numeric 1 matches any value).
        let any = false
        for (const LE of w.o({ LE: 1 }) as TheC[]) {
            const target = LE.sc.target as TheC | undefined
            if (!target || H.waft_key_of(target) !== waft_key) continue
            // < orphan case (target's c.up no longer reaches the Waft — deleted under us) is
            //   unhandled; natural home for the Merge UI (an edit inside something dropped).
            LE.c.origin_dirty = 1
            any = true
        }
        if (any) H.feebly_ponder()
    },

    // climb req.c.up until a node has %w on its sc, return that w.
    //   workon carries %w directly; stages above carry it one|two hops up.
    upto_w(req: TheC): TheC {
        let node: TheC = req
        while (node && !node.sc.w) node = node.c.up as TheC
        if (!node?.sc.w) throw "upto_w: no %w in c.up chain"
        return node.sc.w as TheC
    },





    // ── e_Lang_foreground — the Interest-switcher's click ─────────────────────
    //   Foreground one Interest.  Heavy kinds (Trail|Sidetrack) foreground by re-checkout: set
    //    %ActiveInterest eagerly (instant strip feedback), then land the Lies cursor on the Waft
    //     so req_understanding re-arms the LE and Lang_set_interest binds that giver's Trail.
    //      Light kinds (GhostList) are a pure lens swap — no checkout, no LE.
    async e_Lang_foreground(A: TheC, w: TheC, e: TheC) {
        const H         = this as House
        const kind      = e.sc.kind as string | undefined
        const waft      = e.sc.waft as string | undefined
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        if (!languinio || !kind) return
        if (kind === 'Trail' || (kind === 'Aside' && waft)) {
            // Giver Trail (or today's Aside scratch dump, which walks like one): foreground by
            //  real checkout.  The cursor-landing is what moves the dock + claims %active — the
            //   in-place else below never did, so an Aside cap click had left the dock on the old
            //    giver.  Lang_set_interest is stance-aware (binds the Aside row, not a stray Trail).
            const ai = languinio.oai({ ActiveInterest: 1 })
            ai.sc.kind = kind
            if (waft != null) ai.sc.waft = waft
            languinio.bump_version()   // strip + NaviCado re-derive the foreground at once
            if (waft) H.i_elvisto('Lies/Lies', 'Lies_foreground_waft', { path: waft })
        } else {
            // A Sidetrack's cursor is off_what (no What to check out) → foreground in place, as do
            //  light kinds (GhostList).  interest_foreground sets ActiveInterest for the social
            //   decks and engages the lens for the rest.  A real Sidetrack's own LE is future.
            H.interest_foreground(languinio, kind, waft)
        }
    },

    // ── e_Lang_sprout_sidetrack — the reverse arrow's near end ────────────────
    //   Sprout a Sidetrack Lang-side BEFORE its Waft exists: pending, lens chosen, cursor
    //    off-anchor, %from = the anchor it flew off, no subject.  Pairs with Lies
    //     e:Lies_open_sidetrack (opens the tentative Waft); the roster re-push binds this sprout
    //      by %from.  A Story Plan may split the two across Preps to witness the unbound gap.
    async e_Lang_sprout_sidetrack(A: TheC, w: TheC, e: TheC) {
        const H         = this as House
        const from      = e.sc.from as string | undefined
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        if (!languinio || !from) return
        H.interest_sprout_sidetrack(languinio, from)
    },



    // ── e:dock_content — the one dock content-writer (Lies/Lies → e:dock_content%Good).
    //   The %Good rides back whole (off-snap bytes on good.c.content, dige on /known).  Sole
    //   place a dock is minted|refreshed from content, so one writer, no multipath.  After
    //   installing the text, finish the matching req:furnishing and poke think → the driver
    //   re-keys instrumentation on the new active dock+dige.
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
            // force_compile (a cluster peer's ghost_compile) is a BACKGROUND compile: it must not
            //  disturb the human's active dock|Interest, so it SKIPS the interactive req:Languish
            //   lifecycle and compiles headless off disk text below (no mounted editor).  Just
            //    ensure a %Text so the dock lists + carries the dige; a later interactive open mints Languish.
            const background = !!ev.sc.force_compile
            if (background) await dock.oai({ Text: 1 })
            else            await H.Lang_open_dock(w, dock, text)
            dock.c.content_dige = dige ?? ''

            // Re-provide of an already-open dock (e.g. surprise_read "take theirs"): req:Languish
            //  never finishes (eternal text_mutated child), so its recreate-on-finish text install
            //   + disk_rev bump don't re-run.  Push them here so Langui's disk-reload $effect
            //    (gated on disk_rev) reseats the open editor with the incoming text.
            const Text = dock.o({ Text: 1 })[0] as TheC | undefined
            if (Text && dock.c.text !== text) {
                const d = await dig(text)
                dock.c.text       = text
                Text.sc.dige      = d
                Text.sc.disk_dige = d
                Text.sc.disk_rev  = ((Text.sc.disk_rev as number) ?? 0) + 1
                Text.bump_version()
            }

            // first human-opened dock furnished becomes active (MVP: active = wanted Doc).  A
            //  background compile NEVER takes the seat, leaving the human's active dock|Interest untouched.
            if (!background && !w.c.active_dock_path) await H.Lang_set_active_dock(w, path)

            // The background compile has no editor user to press Esc and skipped req:Languish — so
            //  compile here from a state built off the fresh disk `text` (Lang_compile_source_state),
            //   NOT a live dock.c.state: there's no mounted CM, and an open dock's reseat is async so
            //    its state can lag one edit.  Then arm the run (the Esc pair: compile + run), awaited
            //     inline so the verdict the asking CLI waits on settles on this beat.
            if (background) {
                const srcState = await H.Lang_compile_source_state(dock, text, path)
                await H.Lang_compile_dock(w, dock, srcState)
                H.i_elvisto('Lies/Lies', 'Lies_run_arm', { path })
            }

            // poke a think — the furnishing waiting on this path is still needs_work (bowed out on
            //  a ttlilt), so the next drive re-runs it, sees content_dige, finishes; the driver then
            //   re-keys instrumentation.  (No targeted reqyoncile — it'd bail on the already-finished req.)
            H.i_elvisto(w, 'think')
        }
    },


    // ── Lang_Map_report — %Compile/%Map → %Interest/%MapReport ────────────────
    //   A settled summary the minimap reads instead of re-deriving from the raw index each wake.
    //   On %Interest (rebuilt each checkout, so naturally scoped to the working clone).
    //   Content-gated by a digest of the Map's entries: %Map's version bumps on every recompile
    //    even when structure is unchanged, so a version gate would rebuild needlessly; the digest
    //    is stable across those and moves only when defs/calls/cf/regions actually change.
    //   NOT an enWaft — enWaft speaks only Waft vocab (%What|%Doc|%Point) and faults on the Map's
    //    def|call|region|cf mainkeys, so we serialise entries deterministically and dig that.
    //   < stored on report.c (off-snap, like dock.c.content_dige), so the digest never snaps.
    async Lang_Map_report(w: TheC, dock: TheC) {
        const H         = this as House
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        const interest  = H.Lang_active_interest(languinio)   // the foreground giver-Trail
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
    //   The generic overview layer: one Mapule per Map entry (%kind,key,path,depth + off-snap
    //   closures) so a UI navigates knowing nothing Lang — the minimap + capsule strip read
    //   Mapulen, never %Map.  Rebuilt each compile (offsets move every edit), so its .c closures
    //   never go stale.
    //     m.c.goto()              unfold + select + centre, via dock.c.seek (Langui owns dispatch).
    //     m.c.is_pointedat(specs) is this entry a working Point.  The UI passes the spec set it
    //                              derived from LE.vers, so a Point toggle re-derives without
    //                              rebuilding the Mapulen.
    //   Region Mapulen also carry band geometry so the minimap parses no //#region itself:
    //     sc.end_line  last line of the region body;   m.c.fold()  toggle-fold the body.
    Lang_build_mapules(w: TheC, dock: TheC) {
        const Map_C    = dock.o({ Compile: 1 })[0]?.o({ Map: 1 })[0] as TheC | undefined
        const navicade = dock.oai({ Navicade: 1 })
        navicade.empty()
        if (!Map_C) { navicade.bump_version(); dock.bump_version(); return }

        // doc geometry — char offset of each line's end + the line count.  The Mapulen carry
        //  the finished spans so the UI never parses //#region or maps lines to chars itself.
        const text  = (dock.c.text as string) ?? ''
        const lines = text.split('\n')
        const total = lines.length || 1
        const line_end = new Array<number>(total + 2)   // 1-indexed; [n] = end char of line n
        {
            let off = 0
            for (let i = 0; i < lines.length; i++) { off += lines[i].length; line_end[i + 1] = off; off += 1 }
        }

        // region extents — a region's last line.  Honours //#endregion (a nested region can
        //  close to its parent before a sibling opens, which depth+line ordering alone would
        //   miss), falling back to "next region at depth ≤ mine, else EOF" for implicitly-open
        //    regions.  Lang owns the //#region syntax; the minimap just reads sc.end_line.
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

        // map_regions: the anchors def/call/cf entries store rel_from/rel_to against;
        //  Lang_map_span turns each into an absolute span (reads c.abs_* the compile wrote,
        //   reconstructing from rel only for a snap-decoded Map).  Mapulen carry absolute
        //    from/to so minimap nav is unchanged by the rel encoding upstream.
        const map_regions = Map_C.o({ region: 1 }) as TheC[]
        for (const e of Map_C.o({}) as TheC[]) {
            const s    = e.sc
            const kind = s.def ? 'def' : s.call ? 'call'
                       : s.region ? 'region' : s.controlflow ? 'cf' : '?'
            const key  = String(s.method ?? s.label ?? s.keyword ?? '')
            if (!key) continue
            // capture per-Mapule so the goto closure carries this entry's own span
            const span  = this.Lang_map_span(map_regions, e)
            const from  = span.from
            const to    = span.to
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
            // bright(brights) — this entry's trail heat 0..1, keyed $region/$method (region =
            //   region_path tail) exactly as the Ting globulates a tap, so the heatmap rides the
            //    same rail as is_pointedat.  The UI sensitises brights on the Undertaking LE.vers.
            const rpath  = (e.c.region_path as string[] | undefined) ?? []
            const region = rpath.length ? rpath[rpath.length - 1] : ''
            m.c.bright = (brights: Map<string, number>) => brights.get(`${region}\u0000${key}`) ?? 0

            // warm(warms) — same rail, the deliberateness hue: held|long taps pool a
            //   warmth 0..1 (Lang_trail_warm) the minimap tints the glow by, so the
            //   heatmap says not just where attention went but how — lingered vs grazed.
            m.c.warm = (warms: Map<string, number>) =>
                warms.get(region + String.fromCharCode(0) + key) ?? 0

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
        // Also bump the dock: DocMinimap subscribes via `void lang_dock?.vers`, but building
        //  navicade (a child) bumps navicade not the dock — without this the rebuilt Mapulen
        //   don't re-derive the strip until an unrelated dock bump.  Bump the particle readers key on.
        dock.bump_version()
    },

    // ── Lang_pointed_specs — the working-Point specs (membership is_pointedat tests against).
    //   Same spec read as NaviCado's capsules (method ?? label ?? Point) so strip + minimap
    //   agree.  Derives from LE; the caller sensitises on LE.vers so it re-runs as Points toggle.
    Lang_pointed_specs(LE: TheC | undefined): Set<string> {
        const specs = new Set<string>()
        if (!LE || !LE.oa({ Seem: 'working' })) return specs
        for (const clone of (this.LE_clones(LE) as TheC[])) {
            const raw = ((clone.sc as any).text != null && (clone.sc as any).text !== 1)
                ? ('text:' + (clone.sc as any).text)
                : (clone.sc.method ?? clone.sc.label ?? clone.sc.Point)
            if (raw == null) continue
            specs.add(String(raw))
        }
        return specs
    },

    // ── Lang_trail_brights — the heatmap the minimap draws ─────────────────────
    //   $region/$method → brightness 0..1, off the Undertaking Ting globules (the trail Funkcion
    //   keeps bright fresh, decaying each trickle).  Keyed exactly as a Mapule's bright() looks
    //   itself up.  A region band aggregates the hottest globule anywhere in it, so a region
    //   worked through its methods reads warm even with no tap on its header.  Sensitise on LE.vers.
    Lang_trail_brights(): Map<string, number> {
        const H       = this as House
        const brights = new Map<string, number>()
        const NUL     = String.fromCharCode(0)   // key separator — same null join as below
        const LE      = H.LE_for('Undertaking')
        const ting    = LE?.c.ting as TheC | undefined
        if (!ting) return brights
        // per-globule brightness, and the hottest globule pooled in each region
        const region_max = new Map<string, number>()
        for (const g of (ting.o() as TheC[])) {
            if (!('Point' in g.sc)) continue
            const region = (g.sc.region as string | undefined) ?? ''
            const key    = String(g.sc.Point)
            const bright = (g.sc.bright as number) ?? 0
            // roll this globule's heat up to every region band in its path (tail = direct region,
            //  then ancestors) so a parent band warms from a nested method.  Falls back to direct region.
            const path  = g.sc.region_path as string | undefined
            const bands = path ? path.split('/') : (region ? [region] : [])
            for (const r of bands) region_max.set(r, Math.max(region_max.get(r) ?? 0, bright))
            brights.set(`${region}\u0000${key}`, (g.sc.bright as number) ?? 0)
        }
        // light each region band to the hottest thing pooled in it.  max() not sum: bright is
        //  already 0..1, so a band glows as warm as its hottest member, not saturating with how
        //   many defs it holds.  Heat rolled up the path above, so parents carry nested warmth.
        for (const [region, bright] of region_max) {
            const key = region + NUL + region
            brights.set(key, Math.max(brights.get(key) ?? 0, bright))
        }
        return brights
    },

    // ── Lang_trail_warm — the deliberateness hue, the brights' twin rail ───────
    //   $region/$method → warmth 0..1: how much of the pooled attention was a held|long tap
    //   vs a graze, off each globule's sc.warm.  Same keys + ancestor roll-up as Lang_trail_brights;
    //   the minimap tints the heat glow by this — lingered reads a different hue from glanced.
    Lang_trail_warm(): Map<string, number> {
        const H     = this as House
        const warms = new Map<string, number>()
        const LE    = H.LE_for('Undertaking')
        const ting  = LE?.c.ting as TheC | undefined
        if (!ting) return warms
        const NUL = String.fromCharCode(0)
        const region_max = new Map<string, number>()
        for (const g of (ting.o() as TheC[])) {
            if (!('Point' in g.sc)) continue
            const region = (g.sc.region as string | undefined) ?? ''
            const key    = String(g.sc.Point)
            const warm   = (g.sc.warm as number) ?? 0
            warms.set(region + NUL + key, warm)
            const path  = g.sc.region_path as string | undefined
            const bands = path ? path.split('/') : (region ? [region] : [])
            for (const r of bands) region_max.set(r, Math.max(region_max.get(r) ?? 0, warm))
        }
        for (const [r, w] of region_max) warms.set(r + NUL + r, Math.max(warms.get(r + NUL + r) ?? 0, w))
        return warms
    },

    // ── Lang_ting_globules — the attention histogram's bars ─────────────────────
    //   The Undertaking Ting's %Point globules, each pooled attention on a $region/$method:
    //   n taps, weight, decayed heat|bright (recency), warm (held|long share), region.  Sorted
    //   hottest-first.  The UI sensitises on the Undertaking LE.vers (bumped each tap + trickle).
    Lang_ting_globules(): Array<{
        spec: string, region: string, doc: string, n: number, weight: number,
        heat: number, bright: number, warm: number, last: number, held: number,
    }> {
        const H    = this as House
        const ting = (H.LE_for('Undertaking')?.c.ting) as TheC | undefined
        if (!ting) return []
        return (ting.o() as TheC[])
            .filter(g => 'Point' in g.sc)
            .map(g => ({
                spec:   String(g.sc.Point),
                region: (g.sc.region as string) ?? '',
                doc:    (g.sc.doc    as string) ?? '',
                n:      (g.sc.n      as number) ?? 0,
                weight: (g.sc.weight as number) ?? 0,
                heat:   (g.sc.heat   as number) ?? 0,
                bright: (g.sc.bright as number) ?? 0,
                warm:   (g.sc.warm   as number) ?? 0,
                last:   (g.sc.last   as number) ?? 0,
                held:   (g.sc.held   as number) ?? 0,
            }))
            .sort((a, b) => b.heat - a.heat)
    },

    // ── e:Lang_goto_point — jump into a Point by name, resuming there ────────────
    //   Fired by the Ting histogram: a bar carries its $region/$method spec; resolve to a doc
    //   location and seek (unfolds covering folds + centres, so the jump lands on open code).
    //   Region-disambiguated: with e.sc.region, a method named `spec` is sought first among %Map
    //   defs whose region_path TAIL is that region — two same-named methods in different regions
    //   jump to the RIGHT one.  Falls back to Lang_resolve_point (region-globules resolve to the header).
    //   e.sc: { spec, region? }
    async e_Lang_goto_point(A: TheC, w: TheC, e: TheC) {
        const spec   = e.sc.spec   as string | undefined
        const region = e.sc.region as string | undefined
        const doc    = e.sc.doc    as string | undefined
        if (!spec) return
        const dock   = this.Lang_active_dock(w)
        // cross-Doc: the Point lives in another doc — open it there (Dock_open switches
        //  the active doc and navigates to the point by name), then we're done.
        if (doc && doc !== (dock?.sc.dock as string | undefined)) {
            this.i_elvisto('Lang/Lang', 'Dock_open', { path: doc, point: spec })
            return
        }
        if (!dock) return
        const state  = dock.c.state as EditorState | undefined
        const view   = dock.c.view  as EditorView | undefined
        if (!state || !view) return

        let from: number | undefined
        if (region) {
            const job   = dock.o({ Compile: 1 })[0] as TheC | undefined
            const Map_C = job?.o({ Map: 1 })[0]      as TheC | undefined
            const defs    = (Map_C?.o({ def: 1 })    ?? []) as TheC[]
            const regions = (Map_C?.o({ region: 1 }) ?? []) as TheC[]
            const tail  = (d: TheC) => {
                const rp = d.c.region_path as string[] | undefined
                return rp && rp.length ? rp[rp.length - 1] : undefined
            }
            const hit = defs.find(d => d.sc.method === spec && tail(d) === region)
            // def offsets are region-relative (rel_from/rel_to); resolve to an
            //  absolute doc position through the map span, not the dead sc.from.
            if (hit) from = this.Lang_map_span(regions, hit).from
        }
        if (from == null) {
            const r = this.Lang_resolve_point(state, dock, spec)
            if (!r) return
            from = r.from
        }
        ;(dock.c.seek as ((v: EditorView, a: number, b: number) => void) | undefined)
            ?.(view, from, from)
    },

    // Doc-from-src resolution lives in LiesHold as Waft_src_doc_path — one body
    //   shared with Lies and LangGraft so the three can't drift.




//#region Languish


    // see e:Lang_texting where CodeMirror pushes text

    // ── req:Languish — Lang's per-dock mind ── on dock ({dock:$path}/{req:'Languish'}).
    //   Stages maz-ordered phase reqs and pumps them with req.do(); the dock settles Languish
    //   (all_finished) once its phases are.  Multi-maz do() descends in one pass on a soft compile.
    //     req:text_loaded maz:3  install text + wait for CM mount
    //     req:compile     maz:2  build the methods index; hold for hard-write
    //   Grafting is req:instrumentation's now — Languish builds, the settler wires.
    //   c.up chain req → languish → dock → docks → w (wired at mint) so reqyoncile +
    //   i_req_ttlilt climb to w:Lang.
    async req_Languish(req: TheC) {
        const dock = req.c.up as TheC   // Languish → dock (the owner that settles it)

        await req.oai({ req: 'text_loaded', maz: 3 })
        await req.oai({ req: 'text_mutated', maz: 2 })
        await req.oai({ req: 'compile',     maz: 2 })

        await req.do()
        // unify under the dock when every phase is finished.  text_mutated is eternal (never
        //   finishes), so all_finished() never trips and Languish stays open as the per-dock mind.
        if (req.all_finished() && !req.sc.finished) dock.finish(req)
    },

    // ── req:text_loaded, maz:3 ────────────────────────────────────────────────
    //   reqonce: install text into the dock (already minted by e_Lang_dock_content), seed Text
    //   metadata + dock.c.text, set the doc active.  The genuinely-async wait is the CM round-trip:
    //   dock.c.text → Langui renders → CM mounts → e_Lang_editorBegins stamps dock.c.state +
    //   feebly_ponders.  We hold a ttlilt until dock.c.state appears; the ponder wakes this monitor.
    async req_text_loaded(req: TheC) {
        const H        = this as House
        const languish = req.c.up as TheC   // text_loaded → Languish (the host)
        const dock     = languish.c.up as TheC          // set by reqy
        const w        = dock.c.up?.c.up as TheC        // dock → docks → w (c.up wired where the dock is minted)
        const path     = dock.sc.dock as string

        if (H.reqonce(req, 'opening')) {
            // one chance: install text into the dock.
            H.Langspinner(w, 'text_load')

            const text = (languish.c.open_text as string) ?? ''

            dock.c.initial_text = text   // Langui reads this before the Text dige arrives

            // seed Text metadata; dock.c.text holds the string silently.  Langui reaches dock via
            //  ave/Languinio/dock — Lang_set_active_dock (below) places this dock into Languinio.
            const initial_dige = text ? await dig(text) : ''
            dock.c.text = text
            await dock.oai({ Text: 1 }, {
                dige:      initial_dige,
                disk_dige: initial_dige,
                disk_rev:  ((dock.o({ Text: 1 })[0]?.sc.disk_rev as number) ?? 0) + 1,
            })

            // always activate — Lies owns doc order, last open wins for now
            await this.Lang_set_active_dock(w, path)
            w.i({ received: 1, doc_opened: 1, doc: path })
        }

        // monitor: nothing to compile until CM mounts and hands us its EditorState;
        //  e_Lang_editorBegins feebly_ponders when it stamps dock.c.state, re-entering here.
        if (!dock.c.state) {
            H.i_req_ttlilt(req, 3.0, { waiting: 'cm_mount' })
            return
        }
        // CM mounted — the text_load phase is over; clear its spinner.
        H.Langspinner(w, 'text_load', true)
        languish.finish(req)
    },
    // ── Langspinner — one named spinner under %Languinio ──────────────────────
    //   Each {spinner:$name} is an independent in-flight indicator — set|clear touches only the
    //   named one, so text_load + furnish + compile can all spin at once (oai|drop per name).
    //   < the old r({spinner:name}) collapsed to the {spinner:1} has-key wildcard, so setting
    //     any spinner replaced ALL and clearing one cleared all — every overlapping phase broke.
    //   DocMinimap renders the live set; unknown names get the default style.
    Langspinner(w: TheC, spinner: string, not = false) {
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        if (!languinio) return
        if (not) for (const s of languinio.o({ spinner }) as TheC[]) languinio.drop(s)
        else     languinio.oai({ spinner })
        languinio.bump_version()
    },

    // ── req:compile, maz:2 ────────────────────────────────────────────────────
    //   reqonce: run the synchronous index build (Lang_compile_dock) once — fires the same tick
    //   text_loaded finishes (multi-maz do()).  %Compile/%Map is populated synchronously, so a
    //   soft-compile finishes immediately.  A hard-compile leaves %Compile/sc.pending set while
    //   Lies writes the gen file; we hold a ttlilt until it clears, so the gen file exists before
    //   the snap.  Either way %Map (all grafting needs) is present the instant the build returns.
    async req_compile(req: TheC) {
        const H        = this as House
        const languish = req.c.up as TheC   // compile → Languish (the host)
        const dock     = languish.c.up as TheC
        const w        = dock.c.up?.c.up as TheC   // dock → docks → w (c.up wired where the dock is minted)

        // This pump consumes any pending trickle — re-armed below if we bow out still firing.
        if (req.c.trickle_timer) { clearTimeout(req.c.trickle_timer as any); req.c.trickle_timer = undefined }

        // Run for a .g (gen-compile → .go) OR a points-only dock (.md/.ts/.svelte: %Map only,
        //  no .go, soft path).  A dock that is NEITHER has no business here → finish straight away;
        //   this also closes the worst hang (such a type never satisfies the parser gate below).
        const cpath = dock.sc.dock as string
        if (!H.Lies_gen_path(cpath) && !H.Lang_points_only(cpath)) {
            H.Langspinner(w, 'compile', true)
            languish.finish(req)
            return
        }

        // Wait for the language PARSER, not just the state.  Langui mints the EditorState and arms
        //  this req, but editorExtensions is built via `await lang(...)`, so there's a window where
        //   the state exists with no parser on its `language` facet → compiling emits every line as
        //    raw passthrough, which Lang_compile_dock refuses as a (terminal) compile_error.  Hold
        //     here instead (reqonce not consumed), firing once the parser lands.  Guards "NO parser"
        //      only — a WRONG-but-present parser (stho on a just-opened .md) is fine, since
        //       Lang_compile_dock builds its own source on lang(path) and indexes as markdown anyway.
        if (dock.c.state && !H.Lang_has_lang_parser(dock.c.state)) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'parser' })
            return
        }

        if (H.reqonce(req, 'firing')) {
            // one chance: state is in — build the index.
            H.Langspinner(w,'compile')
            await this.Lang_compile_dock(w, dock)
        }

        const job = dock.o({ Compile: 1 })[0] as TheC | undefined

        // compile error is terminal: methods never appear, Pending never clears — finish rather
        //  than ttlilt forever; grafting finds nothing (the minimap surfaces unresolved Pmirrors).
        if (dock.oa({ compile_error: 1 }) || job?.oa({ compile_error: 1 })) {
            H.Langspinner(w,'compile',true)
            languish.finish(req)
            return
        }

        // index missing → compile hasn't run yet (methods present is the graft gate); hold.
        if (!job || !job.oa({ Map: 1 })) {
            H.i_req_ttlilt(req, 0.5, { waiting: 'methods' })
            return
        }
        if (job.sc.pending) {
            // methods ready but gen-file write still in flight — hold so the gen file exists
            //  before the snap (sc.pending is snapped so the wait is visible).
            H.i_req_ttlilt(req, 0.5, { waiting: 'gen_write' })
            // Trickle-think: the ttlilt is snap-timing only and the settle's re-pump can be missed
            //  under fast re-compiles / a Runtime-gated feebly_ponder — wedging req:compile firing
            //   with pending stuck (the "boomerang" hang).  Self-re-check every 150ms until it clears
            //    (cleared at the top of each pump, guarded by !finished).  Same as the runner's req_rungo.
            // Spin counter: a healthy compile clears in a spin or two; a wedged one spins at ~7Hz —
            //  shout every 10th so the CPU burn is visible, not silent.
            req.c.trickle_spins = ((req.c.trickle_spins as number) ?? 0) + 1
            if ((req.c.trickle_spins as number) % 10 === 0)
                console.log(`🔥 req:compile trickle still spinning — ${req.c.trickle_spins} × 150ms (~${Math.round((req.c.trickle_spins as number) * 0.15)}s) burning CPU on stuck pending`)
            req.c.trickle_timer = setTimeout(() => {
                req.c.trickle_timer = undefined
                if (!req.sc.finished) H.i_elvisto(w, 'think')
            }, 150)
            return
        }
        H.Langspinner(w,'compile',true)
        languish.finish(req)
    },




// ── Lang_update_change ── writes the three-leg change strip into w/{Languinio:1}/{Change:1}:
    //     /{backend:1}  sc.dige — current editor-text dige (from dock/{Text:1})
    //     /{storage:1}  sc.dige — last dige written to disk; sc.dim — unsaved edits exist
    //     /{compile:1}  sc.dige — source_dige of last Output; sc.dim — pending or disk-ahead;
    //                   sc.secs — synchronous compile cost (%Compile/%time.sc.compile)
    //   Each leg uses roai, which replaces the particle on sc-mismatch → a fresh C ref.  Langui
    //   holds the legs as $state() C refs, so only a new ref re-renders (oai+bump isn't enough).
    //   Called from the Lang tick each time the active dock is known.
    async Lang_update_change(w: TheC, dock: TheC) {
        const H   = this as House
        const path = dock.sc.dock as string

        // Text is absent until req_text_loaded's oai resolves — bail rather than blanking Change
        //  with empty strings; the tick re-runs once e_Lang_dock_content populates Text.
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

        // Snapped booleans ride as 1-or-ABSENT, never `false` (project policy): `dim:false`
        //  snapped inconsistently (flat key one tick, munged JSON the next).  Build each leg's sc
        //   with only truthy flags as 1; roai's replace drops the key cleanly when a flag goes false.
        await change.roai({ backend: 1 }, { dige: text_dige })

        const disk_dim = !!text_dige && !!disk_dige && text_dige !== disk_dige
        await change.roai({ storage: 1 }, disk_dim ? { dige: disk_dige, dim: 1 } : { dige: disk_dige })

        if (output) {
            const compile_dim = pending || (!!compiled_dige && !!disk_dige && compiled_dige !== disk_dige)
            // pending rides as its own flag (not just folded into dim) so the strip can
            //  tell "actively compiling — strain" from "merely stale — fidget".
            const sc: Record<string, any> = { dige: compiled_dige, secs: compile_cost }
            if (compile_dim) sc.dim     = 1
            if (pending)     sc.pending = 1
            await change.roai({ compile: 1 }, sc)
        } else {
            for (const old_c of change.o({ compile: 1 }) as TheC[]) change.drop(old_c)
        }
    },

//#region w:Lang

    async Lang(A: TheC, w: TheC) {
        const H = this

        if (!w.c.plan_done) await this.Lang_plan(A, w)

        // ── Waft roster subscription — Lang's standing lock-feed from Lies ──────
        //   A standing eternal req Lies pushes the roster onto (req.c.roster) + reqyoncile; its
        //   do_fn reconciles the %Interest family directly into Languinio.  The editing checkout is
        //   unified onto its giver's Trail (Lang_set_interest attaches c.LE), and reconcile's
        //   gone-loop spares any c.LE-bearing Interest — so the family + editor coexist as direct
        //   %Interest children of Languinio.
        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        if (languinio) {
            ;(await w.doai({ req: 'waft_roster', eternal: 1 }))?.((req: TheC) => {
                const roster = (req.c.roster as Array<{ path: string, stance: string, from?: string }> | undefined)
                    ?.filter(e => !H.waft_is_boring(e.path))   // backstage Wafts never become Interests
                if (!roster) return
                const open = new Set(roster.map(e => e.path))
                // Roster epoch — bumped ONLY when the Waft set/stances actually change (a real
                //  push), not on the settle re-runs that re-drive this do_fn each tick.  Lets a
                //   departed row linger exactly one push (the UI's beat to animate out).  Off-snap (.c).
                const sig = roster.map(e => `${e.path}:${e.stance}`).sort().join('|')
                if (languinio.c.roster_sig !== sig) {
                    languinio.c.roster_sig   = sig
                    languinio.c.roster_epoch = ((languinio.c.roster_epoch as number) ?? 0) + 1
                }
                const epoch = (languinio.c.roster_epoch as number) ?? 0
                for (const it of languinio.o({ Interest: 1 }) as TheC[]) {
                    const waft   = it.sc.waft as string | undefined
                    const absent = waft == null || !open.has(waft)
                    // Drop the ghost row a push later: reconcile (below) marks a departed giver
                    //  state:gone and we stamp gone_epoch (after reconcile); a LATER epoch with
                    //   it still gone+absent retires it.  So it shows gone for one push, then goes.
                    if (it.sc.state === 'gone' && absent
                        && it.c.gone_epoch != null && (it.c.gone_epoch as number) < epoch) {
                        languinio.drop(it); continue
                    }
                    // Retire a closed giver's per-Interest %LE.  reconcile's gone-loop spares any
                    //  c.LE-bearing Interest ("alive by being checked out") — but a giver whose Waft
                    //   has LEFT the roster is truly gone, so drop its clone + c.LE here.  That clears
                    //    the guard so reconcile marks it state:gone + the LE leaves the snap.  (Spares
                    //     mid-bind Trails — no sc.waft yet.)
                    const le = it.c.LE as TheC | undefined
                    if (le && waft && !open.has(waft)) {
                        delete it.c.LE
                        if (languinio.c.active_LE === le) delete languinio.c.active_LE
                        w.drop(le)
                    }
                }
                H.interest_reconcile(languinio, roster)
                // Stamp gone_epoch on freshly-gone rows (linger from this epoch); clear it on any
                //  row reconcile kept|resurrected.  Stamped AFTER reconcile so it captures the
                //   epoch the row actually went gone — the drop above then fires a later epoch.
                for (const it of languinio.o({ Interest: 1 }) as TheC[]) {
                    if (it.sc.state === 'gone') it.c.gone_epoch ??= epoch
                    else delete it.c.gone_epoch
                }
            })
            const sub = w.o({ req: 'waft_roster' })[0] as TheC | undefined
            if (sub && !sub.sc.subscribed) {
                sub.sc.subscribed = 1
                H.i_elvisto('Lies/Lies', 'Lies_subscribe_waft_roster', { req: sub })   // hand Lies the req
            }
        }

        // these go every time so their toggle state can visually change
        let on_change = () => this.main()
        // whether Lang-Cyto does compound_nodes
        await this.i_actions_to_c(w, 'compo',{ stashed: true, on_change })

        const dock = this.Lang_active_dock(w)

        // Drain compile settles unconditionally (not gated on the active dock) so a cursorless/
        //  UIless compile clears its own pending (the settle names its dock %path), and the o_elvis
        //   declaration stays present every tick so a settle always routes here.
        this.Lang_drain_compile_settles(A, w)

        // language picker + gen button — registered fresh each tick so the
        // dropdown reflects the active doc's current language override.
        await this.LangLang_tick(A, w)

        // ── drive dock landing + Languish + workon ──
        // Drain dock_content first — the one content-writer mints|refreshes any dock whose %Good arrived.
        await this.e_Lang_dock_content(A, w)

        // Drive each dock's Languish (text_loaded → compile) BEFORE the workon driver, so a dock
        //  minted this tick has its %Map ready when instrumentation re-keys (same-tick convergence).
        //  Languish lives on dock — w.do() no longer reaches it.
        const docks_C = w.o({ docks: 1 })[0] as TheC | undefined
        if (docks_C) {
            for (const d of docks_C.o({ dock: 1 }) as TheC[]) {
                const languish = d.o({ req: 'Languish' })[0] as TheC | undefined
                if (languish && !languish.sc.finished) await d.do()
            }
        }

        // Drive w-level reqs.  req:workon's do_fn re-keys the three stages and pumps them via its
        //  own workon.do() (the LE push runs inside req_understanding).  Cheap when settled.  Kept
        //   inline (not left to reqdo_sweep) because the rest of this tick reads its results —
        //    Pmirrors, the change strip — and must see them this same beat.
        await w.do()

        // re-decorate from the U sphere after graft has minted Pmirrors.
        // Cache-key-independent: a fold-toggle or class change repaints here
        // without a re-graft (Lang_show_pmirrors short-circuits on no change).
        if (dock?.o({ Pmirrors: 1 })[0]) this.Lang_show_pmirrors(w, dock)

        const model     = w.c.model as TheC
        // whatsthis dumps the syntax tree at each bookmark for the Story snap — a parse-tree read,
        //  so it needs the state the Map was compiled against (Lang_index_state, the RIGHT parser),
        //   not the live dock.c.state whose language compartment may be mid-reconfigure.
        const state     = dock ? this.Lang_index_state(dock) : undefined
        const opt       = {compound_nodes: !!w.c.compo}
        const bookmarks = (dock?.o({ bookmark: 1 }) ?? []) as TheC[]

        // ── whatsthis cache check ──
        // CM doc ropes are immutable — identity equality is O(1) reliable.  dock.version covers
        //  everything on the doc particle (bookmark adds/removes/moves, compile state), so no need
        //   to sum child versions (all start at 0, making a sum unreliable).
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
                // feebly: Cyto is opt-in now — when no A:Cyto is stood up there's simply
                //  no graph to animate, so no-op rather than throwing "no House has A:Cyto".
                H.feebly_i_elvisto('Cyto/Cyto', 'Cyto_animation_request', { Langy: 1 })
            }
            else {
                // txt path — nested Lezer hierarchy under model/Line:N/<NodeName>/… for the Story
                //  snap to render as plain text.  No Cyto ping.  Unconditional now (was Opt-gated):
                //   a bookmark always wants its dump, and the outer guard already scopes this work.
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

        // ── compile_ready gate ──
        // req_text_mutated sets dock.c.compile_ready after the quiet period (30ms machine, 6s
        //  typing).  Reset the reqonce on compile so req_compile re-fires with fresh text.
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
                // re-drive Languish so its req.do() picks up the un-finished compile
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

    // ── e:Lang_i_bookmark ── Generic Plan/Prep action: place a bookmark at a char range
    //   (params from the Prep/esc children, no action button).  from/to omitted or equal →
    //   expand to the enclosing line (same as Ctrl+B on an empty selection).
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

    // ── e:Lang_i_alterationStation ── Generic Plan/Prep action: surgically replace a substring
    //   within a line (operates within existing text so CM remaps spanning bookmark decorations —
    //   a whole-line replace would destroy them).  Params from the Prep/esc children:
    //     line_n      — 1-based CodeMirror line number
    //     sanity      — expected full line text; warns on mismatch but still proceeds
    //     match       — JSON-encoded substring to find (first occurrence)
    //     replacement — JSON-encoded replacement (may be a different length)
    //   match/replacement are JSON-encoded so commas in values don't collide with the snap's
    //   key:value,key:value delimiter format.
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

        // Surgical replace — CM remaps decorations spanning this position, so bookmarks survive.
        // updateListener fires Lang_texting (dock updated) and arms the 80ms timer.
        view.dispatch({ changes: { from: line.from + idx, to: line.from + idx + match.length, insert: replacement } })

        // saveEffect flushes bookmark positions immediately — updateListener cancels
        // the debounce and fires Lang_update_bookmarks with the fresh editorState.
        view.dispatch({ effects: dock.c.saveEffect.of(null) })
        console.log(`Lang_i_alterationStation — line ${line_n} [${match}] → [${replacement}], saveEffect dispatched`)

        // machine-texting: bypass the 80ms throttle and compile immediately, not after 6s.  The
        //   Langui timer also fires (80ms) but no-ops since the text is already in ave.
        this.i_elvisto(w, 'Lang_texting', {
            dock_path: dock.sc.dock as string,
            text:      view.state.doc.toString(),
            machine:   true,
        })
    },


//#region bm e
    // ── e:Lang_add_bookmark ── Ctrl+B: create a w/{dock}/%bookmark at the current selection.
    //   CM marks the range so from/to track edits; periodic e:Lang_update_bookmarks pushes live
    //   positions back here.   e.sc: { doc, from, to, label?, view, state }
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

        // Name it after the MethodLike on this line if the compile index is in (→ that Point).
        //  No index yet → stays positional; e:Lang_point_fuzzify upgrades it later.
        const method = this.Lang_def_at_offset(dock, from)
        if (method) {
            const bm = dock.o({ bookmark: id })[0] as TheC | undefined
            if (bm) { bm.sc.method = method; bm.bump_version() }
        }

        console.log(`🔖 add_bookmark id=${id} [${from}..${to}] ${method ? `method:${method}` : label}`);
        this.i_elvisto(w, 'think', {});
    },


    // ── e:Lang_update_bookmarks ── Fired by the editor after the debounce (or immediately via
    //   saveEffect).  Carries live from/to for every bookmark in CM's decoration set + a fresh
    //   editorState.  Bookmarks absent from updates[] have vanished (their decoration wiped by an
    //   edit that fully replaced the span).   e.sc: { doc, updates=[{id,from,to}], view, state }
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

    // ── e:Lang_update_grafts ── Counterpart to e_Lang_update_bookmarks for Pmirror grafts.
    //   Carries live from/to for every graft mark in CM's graftMarkField; the update logic lives
    //   in %LangGraft.Lang_update_grafts — this is just the elvis entry point.
    //   < graft vanishing (mark wiped by full-span edit) isn't handled; the next graft pass sees
    //     the spec no longer resolves and the Pmirror identity machinery sorts it out.
    async e_Lang_update_grafts(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) throw "!A"
        const updates = e?.sc.updates as Array<{ id: string, from: number, to: number }> | undefined
        if (updates) this.Lang_update_grafts(w, updates)
        this.i_elvisto(w, 'think', {})
    },

    // ── Lang_bookmark_vanished ── a bookmark's CM decoration is absent from the live set (an edit
    //   fully replaced|deleted its anchored span).
    //   < STUB: re-anchor by scanning the parse tree for the nearest surviving landmark (same
    //     Line:N, node type, label text) and re-dispatching addBookmarkMark there.
    //   < Copy+paste tracking: on a paste, match incoming chunks against vanished bookmarks' labels
    //     and re-anchor any that reappear.
    Lang_bookmark_vanished(doc: TheC, bm: TheC) {
        console.warn(`🔖 bookmark vanished: ${bm.sc.bookmark} was [${bm.sc.from}..${bm.sc.to}] "${bm.sc.label}"`)
        bm.i({ vanished: 1 })
        // < re-anchor attempt goes here
        // < copy+paste recovery pass goes here
    },

    // ── e:Lang_remove_bookmark ── remove one bookmark by id: dispatch removeBookmarkMark to CM +
    //   drop the particle.  Wired to DocPoint's delete button.   e.sc: { bookmark_id }
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

    // ── e:Lang_point_fuzzify ── resolve a bookmark's char range to the enclosing method name
    //   from the compile index, stamping bm.sc.method (positional anchor → named pointer).
    //   No-op with a hint when the index is absent.   e.sc: { bookmark_id }
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

    // ── e:Lang_stamp_bookmark_serial ── stamp a global Point serial onto a bookmark after it's
    //   exported to a Waft Doc (e_Lies_export_point); DocPoint shows it as "already persisted".
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

    // ── e:Lang_shoot_point ── the real bookmark→Point path: shoot a ripe bookmark into the active
    //   Interest's LE.  The Point is added to the working clone of the foreground What (Trail|
    //   Sidetrack) via the e:mark op:add seam, and the push cluster lands it back on the canonical
    //   Waft — Lang never writes Waft C directly, the LE owns every Waft manipulation here.  No
    //   armed Interest → error (nowhere legitimate to land), don't fall back to a blind path write.
    //   e.sc: { path, bookmark_id, from, to, method, label? }
    async e_Lang_shoot_point(A: TheC, w: TheC, e: TheC) {
        const H        = this as House
        const path     = e.sc.path as string | undefined
        const method   = ((e.sc.method || e.sc.label || '') as string).trim()
        if (!method) { w.i({ see: '⚠ shoot: nameless Point — fuzzify (~) first' }); return }

        const languinio = w.o({ Languinio: 1 })[0] as TheC | undefined
        const LE        = H.Lang_active_LE(languinio)
        if (!LE) {
            w.i({ see: '⚠ shoot: no active Interest to receive the Point — foreground one first' })
            return
        }

        // The bookmark's dock must be the doc this Interest is checked out
        //  against, or the Point would land in the wrong What.
        const src_path = H.Waft_src_doc_path(LE.sc.target as TheC)
        if (src_path && path && src_path !== path) {
            w.i({ see: `⚠ shoot: bookmark dock '${path}' ≠ Interest dock '${src_path}'` })
            return
        }

        // Method only — a label that just repeats the method is redundant noise
        //  on the Point, so keep it only when it says something different.
        const sc: Record<string, unknown> = { Point: 1, method }
        const label = e.sc.label as string | undefined
        if (label && label !== method) sc.label = label
        H.i_elvisto('Lang/Lang', 'mark', { LE, op: 'add', sc })

        // Light the bookmark as shot so DocPoint shows the serial badge.
        w.c.point_serial_next ||= Date.now()
        H.i_elvisto('Lang/Lang', 'Lang_stamp_bookmark_serial', {
            bookmark_id: e.sc.bookmark_id, serial: w.c.point_serial_next++,
        })
    },


//#region text measurement

    // ── measureText ── monospace text measurement via a hidden canvas → { width, height } px.
    //   Monospace, so per-char width is constant: cache it per fontSize and multiply by length.
    //   Canvas created once and reused.  Font: 'Berkeley Mono','Fira Code',monospace (same as Cytui).
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
<LiesHold {M} />