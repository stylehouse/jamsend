<script lang="ts">
    // LangCompiling.svelte — compilation guts for the stho-language.
    //
    // Lang.svelte joins features high-level; the guts live here so translation can grow
    //  (Sunpit bodies, Se, Flug …) without Lang.svelte becoming a mass of helpers. Core model:
    //   walk the doc line-by-line, pass each verbatim, swap only the IOing/Sunpit span for
    //    translated JS — lines the grammar doesn't know pass through. Pantheate (compiled-code
    //     receiver + runner) lives in LiesRun, downstream of the compile.
    //
    // Deposits onto H via M.eatfunc(): Lang_compile (entry), Lang_compile_dock (translate),
    //  Lang_compile_source_state, Lang_drain_compile_settles, req_compiled_is_settled — each at
    //   its own ── block below. Cross-cutting:
    //   Compile state (%Compile, compile_error) lives on DOCK, not w; compile_write moved to
    //    Lies's w (keyed by path). %Compile/sc.pending = in-flight flag, snapped so a hanging
    //     compile shows in the snap. job.c.compile_t0 = job-park start (transient); %time.{compile,
    //      write,all} = finished deltas, snapped.
    //
    //   ── Lies | Lang demarcation ──
    //   Lang is the editor brain; Lies its road manager — Lang asks Lies for every world op
    //    (read source, write gen, learn a write landed). Compilation unpacks HERE because the
    //     editor state + parser live here; the moment a compile makes an artifact, ownership
    //      crosses to Lies/Cortex. The seam is content identity, not file intent: a Codebit is the
    //       pure identity of one compiled ghost (of_dock → source_dige → dige). Editor and runner
    //        may be DIFFERENT Lies instances (parallel workers keyed by the same path:dige) —
    //         nothing here may assume editor and runner share a w.
    //
    //   Runner shape (in LiesRun): req:Rundown (beside the Codebits in req:Cortex) hashes
    //    finished+dige Codebits into a moment id, mints req:BlatDo → fires e:Pantheate_run_method,
    //     holds a %ttlilt so Story stays open, reqyoncile-finished by req_run_method on completion.
    //      Pantheate's req:include confirms versions before H[method](blastA, blastW).
    //   < remote execution (deferred): path:dige identity is location-free, so it's a transport
    //      swap on the Pantheate_run_method dispatch — fire-and-reqyoncile already handles async.
    //
    // Translation helpers (impl in compile.ts / LangSion):
    //     Lang_compile_collect(state)    → per-Line {kind:'translated'|'raw', text}
    //     Lang_compile_IOing             → one TS expression
    //     Lang_compile_Sunpit            → one TS for-of header
    //     Lang_compile_Leg               → {sc_src, exactly_src, receiver_hint?, captures}
    //     Lang_compile_PeelItem          → one sc property (+exactly flag, +capture)
    //     Lang_compile_PeelVal           → value expr (literal number | identifier)
    //     Lang_compile_leg_obj_src(leg)  → {sc, exactly, caps} — JSON-ish shape backends receive
    //
    // Translation rules (regroup() spec, in summary):
    //   Receiver: first leg a single bare-$name key ("$la" in "o $la/something") → that JS var
    //    starts the chain; else receiver is w.
    //   Tier 0 (single-leg, inline native JS):
    //     i foo → receiver.i({foo:1});  o foo$ → let foo = receiver.o({foo:1})[0]
    //     o foo:3 → receiver.o({foo:3}, {exactly:{foo:true}})
    //   Tier 1 (multi-leg → backend fn on H, in LangSion):
    //     o a/b/c → this._o_drill(receiver, [{sc:{a:1}},…]);  o a/b$ → this._o_drill1(…)
    //     S o a/b → for (const b of this._o_iter(receiver,…)) { <indented body, translated> }
    //   Key shapes in an sc: $name→{name} (ES6 shorthand); key:$var→{key:var}; key:3→{key:3};
    //    key:word→{key:"word"}; key→{key:1} (wildcard).
    //   .i DROPS exactly (insertion doesn't filter); .o / Sunpit keep it to pass {exactly} to C.o().
    //
    // Output (render_module): a .svelte ghost wrapping the user's verbatim source (IOing/Sunpit
    //  substituted) in an H.eatfunc({…}) inside onMount. Pantheate dynamic-imports it and picks
    //   up the deposited methods via ghostsHaunt — method names are the user's, comma-separated
    //    in the eatfunc object literal.

    import { TheC } from "$lib/data/Stuff.svelte"
    import { dig } from "$lib/Y.svelte";
    import { syntaxTree, language } from "@codemirror/language"
    import { EditorState } from "@codemirror/state"
    import type { SyntaxNode } from "@lezer/common"
    import { onMount } from "svelte"
    import type { House } from "$lib/O/Housing.svelte"
import { LANG_COMPILE, ghost_dige_of } from "./lang/compile"
import { lang, lang_for_path } from "./lang/lang"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region entry

    // ── e_Lang_compile — beliefs-time entry for the compile button ──
    //   misdirectioner: bounce once so Story wraps the compile in a proper tick; on the
    //    second pass gate on job.c.pending so N queued Esc presses collapse to one cycle.
    //   job.c.pending is transient (not snapped) — dodges the snap-mid-flight problem
    //    %Pending:1 had (arrives slightly earlier in step time).
    async e_Lang_compile(A: TheC, w: TheC, e: TheC) {
        if (!e.sc.misdirectioner) {
            // Stamp live CM state onto dock before bouncing: the 2nd pass carries no
            //  e.sc.state, so without this Lang_compile_dock would compile the ~800ms-stale
            //   bookmark-debounce state — every Esc one push behind the current text.
            this.Lang_dock_from_event(w, e)
            return this.i_elvisto(w,'Lang_compile',{
                misdirectioner: 1,
            })
        }
        const dock = this.Lang_active_dock(w)
        // Drop the compile when one is already in-flight for this doc.
        // < should be in req:Languish
        if (dock?.o({ Compile: 1 })[0]?.sc.pending) {
            console.log(`⏭ Lang_compile: skipped — in-flight for ${dock.sc.dock}`)
            return
        }
        await this.Lang_compile(A, w)

        // This compile ran OUTSIDE the req machine (Esc, or Langui's language-reconfigure
        //  recompile): it filled %Compile/%Map but woke nobody. req:workon only re-derives
        //   the instrumentation sig (rebuilds %Navicade + the %MapReport the minimap reads)
        //    inside its per-tick w.do(), and a language switch has usually quiesced the driver
        //     — so the bumped %Compile version never re-keys it; the minimap stays on the PRIOR
        //      parser's empty index. Poke one think to re-key against the fresh Map. (channel/
        //       headless compile pokes its own; req:compile runs inside the driver tick.)
        this.i_elvisto(w, 'think')
    },

    // ── e_Lang_run_now — Esc's "run it now", beside the compile it just fired ──
    //   Forwards the run intent to Lies, which (per its editor|runner role) signals the
    //    runner or drives a local re-run. Run mode (in-place | from-start) is Lies's own
    //     stored preference — the editor only says "now"; Lies_run_arm fills in the mode.
    e_Lang_run_now(A: TheC, w: TheC, e: TheC) {
        const H    = this as House
        const path = (e.sc.dock as string | undefined) ?? (H.Lang_active_dock(w)?.sc.dock as string | undefined)
        H.i_elvisto('Lies/Lies', 'Lies_run_arm', { path })
    },

    // ── Lang_compile_source_state — the EditorState to COMPILE (not to display) ──
    //   Decoupled from the display buffer (Lang_handover.md §7 role #2): owns its own bytes
    //    AND parser, so the index is right wherever the editor's async language-reconfigure is.
    //     Retires three masks — .md-stranded-on-stho first open, reconfigure lag, and "no
    //      headless compile" (ghost_compile needn't mount a dock to borrow dock.c.state).
    //   `text`: ghost_compile passes freshly-read DISK text (dock.c.state lags the async CM
    //    reseat a round); in-editor passes undefined → compile the live buffer.
    //   Cheap by construction (runs every settled keystroke — a fresh create per settle re-
    //    detonates the boomerang latency): RIGHT grammar (steady state) → reuse, swap doc only
    //     by transaction when `text` differs (text matches → IS dock.c.state, allocates nothing);
    //      WRONG/absent grammar (first-open window, or headless no-view) → the one create, on the
    //       registry parser lang(want), only on a genuine mismatch, never per settle.
    //   Never stamps dock.c.state — this is the compile's own state, also parked as
    //    job.c.source_state (the Map's coordinate frame).
    async Lang_compile_source_state(dock: TheC, text: string | undefined, path: string): Promise<EditorState> {
        const want = (dock.sc.lang_override as string) ?? lang_for_path(path)   // mirrors Langui's reconfigure `want`
        const cur  = dock.c.state as EditorState | undefined
        const body = text ?? cur?.doc.toString() ?? ''
        if (cur && this.Lang_state_lang_is(cur, want)) {
            if (body === cur.doc.toString()) return cur
            return cur.update({ changes: { from: 0, to: cur.doc.length, insert: body } }).state
        }
        const exts = await lang(want)
        return EditorState.create({ doc: body, extensions: exts })
    },

    // ── Lang_compile ──
    //   Resolves the active dock → Lang_compile_dock. The split lets req:compile (Languish)
    //    drive a SPECIFIC dock, not "whatever's active".
    async Lang_compile(A: TheC, w: TheC) {
        const dock = this.Lang_active_dock(w)
        if (!dock) { w.i({ see: '⚠ Lang_compile: no active doc' }); return }
        await this.Lang_compile_dock(w, dock)
    },

    // ── Lang_compile_dock ──
    //   Pure translation: collect → render → dig → stamp %Output. Doesn't decide whether to
    //    write; hands off to Lies (e:Lies_compiled) for all airlock concerns — write, softgen,
    //     Pantheate notify, settle.
    //   gen_path derived here (earliest needed). Absent → no gen/ target: module still rendered
    //    for Output inspection, but Lies settles immediately without writing.
    //   job.sc.pending (snapped) — req_compile checks it to hold Languish; the deferred
    //    req:compiled_is_settled clears it once Lies settles (via Lang_drain_compile_settles).
    //   %time stages: compile = sync cost (collect+render+dig), stamped here; write = gen/
    //    Wormhole round-trip, carried on the settle elvis; all = job-park→settle wall, in step.
    //   %Compile/%Map fully populated before this returns in BOTH paths — a resolver needing
    //    %Map can rely on it the instant this resolves; only the gen write (if any) outlives it.
    async Lang_compile_dock(w: TheC, dock: TheC, stateOverride?: EditorState) {
        const H = this

        // Two compile shapes here. A .g dock GEN-compiles (stho→TS, render module, write .go);
        //  a points-only dock (.md/.ts/.svelte) takes the SOFT path below (build %Map for
        //   Point/region nav, write nothing). Neither (a .png) indexes to nothing — don't park
        //    a job or run a parser (Esc stays a clean no-op).
        const path     = dock.sc.dock as string
        const gen_path = H.Lies_gen_path(path)
        const points   = !gen_path && H.Lang_points_only(path)
        const is_md     = /\.md$/.test(path)
        if (!gen_path && !points) return

        // COMPILE SOURCE = the compile's own EditorState, never dock.c.state raw (§7 role #2):
        //  a channel ghost_compile hands one off fresh disk text (stateOverride); in-editor
        //   builds from the live buffer on the parser lang(path) DEMANDS (so .md indexes as
        //    markdown before Langui's async reconfigure reseats the display). No view yet and
        //     nothing handed in → genuinely nothing to compile, bow out (req_compile only
        //      reaches here past its own parser-gate, so dock.c.state is present then).
        const state = stateOverride
            ?? (dock.c.state ? await this.Lang_compile_source_state(dock, undefined, path) : undefined)
        if (!state) { w.i({ see: '⚠ Lang_compile: no editorState yet' }); return }
        if (state.doc.length === 0) return

        // Park the job; large source stays in .c to keep sc clean.
        const job = dock.oai({ Compile: 1 })
        job.empty()
        // sc.pending: snapped in-flight flag — a hanging compile shows in the snap.
        job.sc.pending   = 1
        // c.compile_t0: wall-clock start for %time accounting (transient).
        job.c.compile_t0 = Date.now()

        // c.source_state: the exact EditorState this %Map is built against — the Map's frozen
        //  coordinate frame (§7 role #3). Index-oracle readers (LangRegions, tap, point-nav,
        //   whatsthis dump) resolve against THIS via Lang_index_state, not live dock.c.state, so
        //    a Map offset is read in the frame it was born in — no drift as you type.
        job.c.source_state = state

        await dock.r({ compile_error: 1 }, {})

        let source = ''
        let source_dige = ''
        let ghost_dige = ''   // source_dige ⊗ compiler version — the currency Ghostmeta bakes (ghost_dige_of)
        try {
            // Refuse to compile with no parser wired: every line passes verbatim (compile.ts
            //  "not found → raw"), so the .go would be uncompiled .g source — and pushed to a
            //   trusting runner over the channel. A caught compile_error writes NOTHING; the job
            //    re-arms once async lang() lands (self-healing, not silent garbage). Same race
            //     blanks a markdown TOC, so the guard fronts both paths.
            if (!this.Lang_has_lang_parser(state))
                throw 'no language parser wired on this dock (lang() not resolved onto its EditorState yet) — refusing to emit raw .g passthrough'

            if (is_md) {
                // Markdown: scan headings into %Map as regions, emit no module → soft close below.
                this.Lang_collect_markdown_regions(state, job)
            } else {
                // stho (.g) or tsstho (.ts/.svelte): one collector indexes both (the tsstho
                //  whole-doc walk picks up Property/VariableDefinition as method+class defs).
                //   Only a gen-able .g renders+validates+writes; points-only keeps %Map, soft-closes.
                const lines = this.Lang_compile_collect(state, job, this.Lang_stho_parser(state))

                if (gen_path) {
                    const { body, header, tail } = this.Lang_split_compiled(lines)
                    // source_dige: dige of the raw source → folded with the compiler version into
                    //  ghost_dige, the value Ghostmeta bakes so Pantheate / req_rungo confirm the live
                    //   version AND that this compiler produced it. Before render, independent of wrapper.
                    source_dige = await dig(state.doc.sliceString(0))
                    ghost_dige  = ghost_dige_of(source_dige)
                    const ghost = { ghostmeta_name: H.Lang_ghostmeta_name(path), ghost_dige }
                    source = this.Lang_compile_render_module(body, ghost, { header, tail })
                    // esbuild parse gate: prove the emitted JS parses before anyone trusts it.
                    //  A raw-JS passthrough can mangle a brace into invalid JS even WITH a parser
                    //   wired (the parser-guard above misses this); a bad .go on disk or over the
                    //    channel is the disease. Failure → compile_error path below (writes nothing).
                    const bad_js = this.Lang_validate_rendered_module(source)
                    if (bad_js) throw bad_js
                }
            }
        } catch (err: any) {
            dock.i({ compile_error: 1, msg: String(err?.message ?? err), stack: err?.stack ?? '' })
            delete job.sc.pending
            return
        }

        const compile_ms = Date.now() - (job.c.compile_t0 ?? Date.now())
        job.oai({ time: 1 }, { compile: +(compile_ms / 1000).toFixed(3) })

        if (gen_path) {
            const dige = await dig(source)   // fingerprints the REAL source, even when it's munged below
            // %Output.source is only read back by the snap (write + runner take `source` off the
            //  Lies_compiled elvis below, not this particle). So a run flagged not-a-compiler-test
            //   (H.c.mungOutputstring, set by Run_A_Editron) redacts it to a marker — hundreds of
            //    generated lines per dock is snap noise; dige still moves, so the compile's witnessed.
            const out_source = H.c.mungOutputstring ? `«munged: ${source.length}c, see dige»` : source
            job.oai({ Output: 1, gen_path, source: out_source, dige, source_dige, ghost_dige })

            // Hand off to Lies (decides write | softgen | nogen): e_Lies_compiled parks
            //  req:Cortex + req:Codebit (Rundown separate). Only hard compiles use the airlock —
            //   e_Lies_compiled throws without a gen_path by design (nothing to write or settle).
            H.i_elvisto('Lies/Lies', 'Lies_compiled', {
                path: dock.sc.dock, gen_path, source,
                dige, source_dige, ghost_dige,
                // dock_source: raw .g text (editor only) the runner re-lands + recompiles over
                //  the channel — the cross-origin runner has no shared disk, so the frame must
                //   CARRY the source, not poke a re-read. Only the editor pays it; omitted elsewhere.
                ...(H.Lies_is_editor(w) ? { dock_source: state.doc.sliceString(0) } : {}),
            })
        } else {
            // soft compile (points-only .ts/.svelte/.md): %Map built, no gen/write, so no settle
            //  elvis arrives — close the job here the way req:compiled_is_settled would (clear
            //   pending, stamp %time.all) so req_compile's waiting:gen_write gate releases.
            delete job.sc.pending
            const all_ms = Date.now() - (job.c.compile_t0 ?? Date.now())
            job.oai({ time: 1 }).sc.all = +(all_ms / 1000).toFixed(3)
        }
        H.i_elvisto(w, 'think')
    },

    // ── Lang_drain_compile_settles — Lies_compile_settled consumer ──
    //   Called UNCONDITIONALLY from Lang(A,w) every tick — NOT gated on active dock: the settle
    //    names its own %path, so a cursorless/UIless compile (loader's heading-0 path) clears its
    //     pending too. The first call also stamps w/{o_elvis:'Lies_compile_settled'} — that
    //      declaration is why a settle routes to the main Lang method, not the (absent)
    //       e_Lies_compile_settled; on the unconditional path it's always present, never the lazy
    //        stamp the old active-dock gate could starve.
    //   Captures cheaply onto a one-shot req:compiled_is_settled (one per settled path); the clear
    //    is deferred to its do_fn, so a not-yet-minted dock retries rather than dropping the settle.
    Lang_drain_compile_settles(A: TheC, w: TheC) {
        const H = this as any
        for (const ev of H.o_elvis(w, 'Lies_compile_settled')) {
            const path = ev.sc.path as string
            if (!path) continue
            const settle = w.oai({ req: 'compiled_is_settled', path })
            if (ev.sc.write_ms != null)     settle.sc.write_ms     = ev.sc.write_ms
            if (ev.sc.source_dige != null)  settle.sc.source_dige  = ev.sc.source_dige
            // ghost_compile verdict-reply: .go landed → tell the asking CLI. gc_acks is on H.c
            //  (shared with the Lies-side recv that stashed it; this drain runs on w:Lang, a
            //   different w); gc.w is the channel w:Lies the reply rides down.
            const acks0 = H.c.gc_acks as Record<string, { corr: string, w: TheC }> | undefined
            const gc = acks0?.[path]
            if (gc) {
                H.Lies_ghost_compile_ack(gc.w, gc.corr, 'done', { path, dige: ev.sc.source_dige }); delete acks0![path]
            }
            H.main()
        }
        // Sweep still-pending ghost_compile acks: an ERRORED dock reports its compile_error (the
        //  signal the CLI's dige-poll can't give — it just times out); a stale entry is dropped so
        //   the map can't grow. Error read is local on w:Lang; reply rides the stashed w:Lies.
        const acks = H.c.gc_acks as Record<string, { corr: string, at: number, w: TheC }> | undefined
        if (acks) for (const path of Object.keys(acks)) {
            const dock = (w.o({ docks: 1 })[0] as TheC | undefined)?.o({ dock: path })[0] as TheC | undefined
            const err  = dock?.o({ compile_error: 1 })[0] as TheC | undefined
            if (err) { H.Lies_ghost_compile_ack(acks[path].w, acks[path].corr, 'error', { path, errors: [String(err.sc.msg ?? 'compile error')] }); delete acks[path] }
            else if (Date.now() - acks[path].at > 60000) delete acks[path]   // survive a manual jiggle / long timeout
        }
    },

    // ── req:compiled_is_settled,path — the deferred pending-clear ──
    //   dock not minted yet → arm a ttlilt and retry: the ONLY reason this is a req not inline,
    //    and rare (dock + job.sc.pending exist before the hand-off to Lies posts the settle, so
    //     it's normally there first pump; the retry covers a snap-reload race).
    //   dock present → clear job %pending (releases req_compile's gate), close %time (all =
    //    job-park→settle, write = carried write_ms), emit ✅, drop this one-shot req so a
    //     re-compile re-mints a fresh one.
    async req_compiled_is_settled(req: TheC) {
        const H    = this as any
        const w    = req.c.up as TheC
        const path = req.sc.path as string
        const dock = w.o({ docks: 1 })[0]?.o({ dock: path })[0] as TheC | undefined
        if (!dock) { H.i_req_ttlilt(req, 2.5, { waiting: 'dock' }); return }

        const job = dock.o({ Compile: 1 })[0] as TheC | undefined
        if (job?.sc.pending) {
            delete job.sc.pending
            const all_ms = Date.now() - (job.c.compile_t0 ?? Date.now())
            const time = job.oai({ time: 1 })
            time.sc.all = +(all_ms / 1000).toFixed(3)
            const write_ms = req.sc.write_ms as number | undefined
            if (write_ms != null) time.sc.write = +(write_ms / 1000).toFixed(3)
            // %Text.disk_dige = the source dige just written — the storage leg of the change
            //  strip (Lang_update_change reads it); bump so Langui's $effect re-derives.
            const source_dige = req.sc.source_dige as string | undefined
            const Text = dock.o({ Text: 1 })[0] as TheC | undefined
            if (source_dige && Text && Text.sc.disk_dige !== source_dige) {
                Text.sc.disk_dige = source_dige
                Text.bump_version()
            }
            // Re-pump Languish: req_compile gates on job.sc.pending, held by a waiting:gen_write
            //  ttlilt — but a ttlilt is a one-shot snap-timing advisor (no re-arm, no re-fire), so
            //   once the gen write outlives it only a fresh think re-runs req_compile. If it already
            //    ran this do()-pass it saw pending set and returned firing → spinner stuck until an
            //     unrelated tickle. Wake one pass so it re-checks the now-clear gate this same beat.
            H.i_elvisto(w, 'think')
        }
        w.i({ see: `✅ compiled ${path}` })
        w.drop(req)
    },

//#endregion

    ...LANG_COMPILE,


    })
    })
</script>
