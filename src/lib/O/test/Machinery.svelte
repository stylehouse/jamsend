<script lang="ts">
    import { _C, keyser, objectify, TheC, TheX } from "$lib/data/Stuff.svelte";
    import { Selection } from "$lib/mostly/Selection.svelte";
    import { WormholeNav, type House } from "$lib/O/Housing.svelte";
    import { Peerily, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts";
    import { armap, depeel, Idento, nex, peel, sex } from "$lib/Y.svelte";
    import { onMount } from "svelte";
    import MachPeerily from "../MachPeerily.svelte";
    import MachReactivity from "./MachReactivity.svelte";
    import MachReqy from "./MachReqy.svelte";
    import Mundane from "./Mundane.svelte";
    import Understandity from "./Understandity.svelte";
    import Understandium from "./Understandium.svelte";
    import Understandication from "./Understandication.svelte";
    import TextLinestests from "./TextLinestests.svelte";
    import Diffmatication from "../D/Diffmatication.svelte";

    let {M} = $props()

    onMount(async () => {
    await M.eatfunc({


















//#endregion
//#region AwFloat

    // AwFloat — a TOY: look at a reasonable amount of the LIVE A/w/** (like MiniWaft, bounded) as
    //  Stuffings floating in Cyto.  Each `peek` node is a LEAF in the scanned tree (no children of its
    //   own → no cyto explosion); its `c.stuff_of` points at a live top_House world, so the stuff-overlay
    //    mounts a live Stuffing of THAT world's contents (Cyto reads source_n = n.c.stuff_of ?? n).
    //  `useCyto` in the Book's toc.snap commissions the Run house, so the peek nodes render as floating
    //   Stuffings.  < v1: a flat capped sweep of top_House's A/w; deepen (MiniWaft budget walk) + node titles next.

    Run_A_AwFloat(this: House) {
        const H = this
        const A = H.o({ A: 'AwFloat' })[0] || H.i({ A: 'AwFloat' })
        if (!A.o({ w: 'AwFloat' }).length) A.i({ w: 'AwFloat' })
        console.log(`🔭 ${H.name} AwFloat wired`)
    },

    async AwFloat(A: TheC, w: TheC) {
        // build once — a peek node per live world, capped to a reasonable amount
        if (w.c.built) return
        w.c.built = 1
        const H = this as House
        const top = H.top_House()
        const CAP = 12
        let count = 0
        for (const Ac of top.o({ A: 1 }) as TheC[]) {
            for (const wc of Ac.o({ w: 1 }) as TheC[]) {
                const node = w.i({ peek: 1, idx: count, of: String(wc.sc.w ?? '?'), stuff: 1 })
                node.c.stuff_of = wc   // the stuff-overlay shows THIS live world's contents
                if (++count >= CAP) { w.i({ see: `🔭 ${count} worlds (capped)` }); return }
            }
        }
        w.i({ see: `🔭 ${count} worlds` })
    },

//#endregion
//#region LakeTiles

    // LakeTiles ghost — a second test-case game with its own Cyto instance.
    //
    // ── eithery commissioning ───────────────────────────────────────────────
    //
    //   H:Story commissions its Cyto with Scannable=H (everything), giving the
    //   low-frequency overview wave.  H:LakeTiles commissions its own Cyto
    //   with Scannable=w.c.model — a permanent TheC it owns — for a tighter,
    //   higher-detail wave of just the Lang viewable model.
    //
    //   Both Cytos share the same Styles bucket: Story's The/Styles.  We reach
    //   across via top_House().Awo('Story','Story').c.The and call The_Styles.
    //   Any matstyle edit from either Cytui writes to the same place and both
    //   graphs restyle.  Story's watch_c on stylesC handles save-on-change.
    //
    //   Client for LakeTiles's Cyto is w:Lang itself, so Cyto_animation_done
    //   etc. route back here.  Story's Cyto still talks to w:Story.
    //


    // Called from Auto (same path Story uses) with Book=name of a LakeTiles book.
    // Auto spawns H:LakeTiles as a subHouse and calls Run_A_LakeTiles on it.
    Run_A_LakeTiles(this: House) {
        const H = this
        H.i({ A: 'Lies' }).i({ w: 'Lies' })
        H.i({ A: 'Lang' }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate' }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LakeTiles wired`)
    },


//#endregion
//#region LakeSurfer
    // growing the Lies-Lang system


    Run_A_LakeSurfer(this: House) {
        const H = this
        H.i({ A: 'Lies' }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LakeSurfer wired`)
    },






//#endregion
//#region LakeNets
    // growing Peeroleum, the Peerily reboot


    Run_A_LakeNets(this: House) {
        const H = this
        H.i({ A: 'Lies' }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LakeNets wired`)
    },


    // the %Interest channel on the REAL wire — the regression gate for the channel
    //  (it retired Book:Interesting's InterLies/InterLang stand-ins; see
    //   spec/Interest.md).
    //  No worker body: the real Lies/Lang/Pantheate ghosts run; the scenario is
    //   driven from the Story Plan's Preps (Lies_open_Waft, now_Ting, Lang mark)
    //    and recorded as the regression gate.
    Run_A_LakeSurprise(this: House) {
        const H = this
        H.i({ A: 'Lies' }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟪 ${H.name} LakeSurprise wired`)
    },






//#endregion


//#region LakeFlush
    // altering Waft, push|pull through LE


    Run_A_LakeFlush(this: House) {
        const H = this
        H.i({ A: 'Lies' }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LakeFlush wired`)
    },


//#endregion
//#region LakeLocate
    // P2 keystone gate — the one loose locator resolver (Lies_resolve_locator, Keeping_spec #7).
    //  In-system Story, NOT a scratch spec: a Prep fires e_Lies_locate_selftest, which builds a tiny
    //   Waft tree on w:Lies, resolves each of the three locator forms + a rename, and emits a %see
    //    self-describing claim per truth that holds.  The snap-fixture diff is the gate — a resolver
    //     regression drops a %see line.

    Run_A_LakeLocate(this: House) {
        const H = this
        H.i({ A: 'Lies'       }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LakeLocate wired`)
    },

    // the Prep handler — drive Lies_resolve_locator through its three forms + a rename, witnessing
    //  each passing claim as a DURABLE marker under LocateGate (a `see` particle is the transient
    //   Lies status line — it gets swept; a plain child snaps like any C).  Each marker's mainkey IS
    //    the claim; the snap-fixture diff is the gate (a resolver regression drops a marker line).
    e_Lies_locate_selftest(this: House, _A: TheC, w: TheC, _e: TheC) {
        const H = this
        const R = (loc: string, scope?: TheC) => H.Lies_resolve_locator(w, loc, scope)
        // fold the auto-loaded GhostList — its Doc list is volatile (it drifts with every src file
        //  add|remove) and this gate doesn't test it; dontSnap keeps the header line, hides the list.
        const gl = w.o({ Waft: 'GhostList' })[0] as TheC | undefined
        if (gl) gl.sc.dontSnap = 1
        const gate = w.oai({ LocateGate: 1 })
        // tree:  Waft:LocFoo / What:bar / Doc:baz   (+ sibling What:qux for the text form).  equip so
        //  the test Wafts stay backstage — no Lang Interest sprouts around them, and their subtree
        //   folds from the snap (the live tree the resolver walks is intact; LocateGate is the gate).
        const foo = w.oai({ Waft: 'LocFoo' }, { equip: 'LocGate' })
        const bar = foo.oai({ What: 'bar' }); bar.oai({ Doc: 'baz' })
        foo.oai({ What: 'qux' })
        if (R('What:bar', foo)?.sc.What === 'bar')              gate.i({ tail_resolves_What_in_scope: 1 })
        if (R('Waft:LocFoo/Doc:baz')?.sc.Doc === 'baz')         gate.i({ path_resolves_nested_Doc: 1 })
        if (R('text:qu', foo)?.sc.What === 'qux')               gate.i({ text_substring_matches: 1 })
        // rename = drop + recreate under a new key (index-safe); the stale locator must DEGRADE
        w.drop(foo)
        const ren = w.oai({ Waft: 'LocRenamed' }, { equip: 'LocGate' }); ren.oai({ What: 'bar' })
        if (R('Waft:LocFoo/What:bar') === undefined)            gate.i({ stale_locator_degrades_not_throws: 1 })
        if (R('Waft:LocRenamed/What:bar')?.sc.What === 'bar')   gate.i({ renamed_key_resolves: 1 })
        gate.bump_version(); w.bump_version()
    },
//#endregion
//#region LakeKeep
    // P1 verify gate — the kind foundation, reconciled to the %equip collapse + Chunk 1.  P1's goal
    //  ("background kinds get a carrier they'd otherwise never get, before any focus") is met by the
    //   per-Waft req:Waftica carrier: this drives the REAL instantiate→ensure_waftica path on a fresh
    //    background (equip) Waft and witnesses the carrier, plus the equip focus-classification.  Same
    //     in-system Story shape as LakeLocate; markers under KeepGate, snap-fixture diff is the gate.

    Run_A_LakeKeep(this: House) {
        const H = this
        H.i({ A: 'Lies'       }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LakeKeep wired`)
    },

    async e_Lies_keep_selftest(this: House, _A: TheC, w: TheC, _e: TheC) {
        const H  = this
        const gate = w.oai({ KeepGate: 1 })
        const gl = w.o({ Waft: 'GhostList' })[0] as TheC | undefined
        if (gl) gl.sc.dontSnap = 1                                  // fold a volatile GhostList IF a headless boot loaded one
        // (1) the P1 goal — a fresh BACKGROUND (equip) Waft, run through the real instantiate path,
        //     gets a req:Waftica carrier (Chunk 1's per-Waft carrier; no focus needed).
        const back = w.oai({ Waft: 'KeepBack' }, { equip: 'Back' })
        await H.Lies_instantiate_funkcions(w, back)
        // a PLAIN (non-equip) loaded Waft, SELF-MANUFACTURED so carrier-at-load (2) + equip-classification
        //  (3) fire on a LIVE ?B= runner too — the ambient GhostList only auto-loads under the (now-banned)
        //   headless boot, so leaning on it made the gate headless-only.  KeepLoad stands in for it.
        const load = w.oai({ Waft: 'KeepLoad' })
        await H.Lies_instantiate_funkcions(w, load)
        const funks = w.o({ Funkcions: 1 })[0] as TheC | undefined
        if (funks?.oa({ req: 'Waftica', waft: 'KeepBack' }))  gate.i({ background_Waft_gets_a_carrier: 1 })
        // (2) carrier-at-load fires generally — the plain loaded Waft has its carrier too.
        if (funks?.oa({ req: 'Waftica', waft: 'KeepLoad' })) gate.i({ loaded_Waft_gets_a_carrier: 1 })
        // (3) %equip classification — the background Waft is OUT of the focus set, a plain one (KeepLoad) is IN.
        const focusable = (w.o({ Waft: 1 }) as TheC[]).filter(wf => !wf.sc.equip)
        if (!focusable.includes(back) && focusable.includes(load)) gate.i({ equip_out_plain_in_focus: 1 })
        // (4) P5 — the (scope,id,key) LAYOUT SERVICE round-trips on the Keep, one per scope.  Ensure
        //     a Keep exists (Persist owns it live; here we mint the equip particle), set one value per
        //      scope, then read it back through a FRESH (reopen-like) raw get — the value rides snapped
        //       Keep sc, so the same get a post-reload client runs returns it.
        const keep = w.oai({ Waft: 'Keep' }, { equip: 'Keep' })
        H.Lies_keep_layout_set(w, 'waft',   'KeepLoad', 'minimised',    1)
        H.Lies_keep_layout_set(w, 'lens',   'Brink',    'pose',         'TR')
        H.Lies_keep_layout_set(w, 'global', '',         'lte_expanded', 1)
        if (H.Lies_keep_layout_get(w, 'waft',   'KeepLoad', 'minimised')    === 1)    gate.i({ layout_waft_round_trips: 1 })
        if (H.Lies_keep_layout_get(w, 'lens',   'Brink',    'pose')         === 'TR') gate.i({ layout_lens_round_trips: 1 })
        if (H.Lies_keep_layout_get(w, 'global', '',         'lte_expanded') === 1)    gate.i({ layout_global_round_trips: 1 })
        // (5) the set is COALESCED — re-setting the SAME value is a no-op (no ROOT bump), so an
        //     ave→Keep mirror can't feed a write loop back.
        const keep_v = keep.version
        H.Lies_keep_layout_set(w, 'global', '', 'lte_expanded', 1)
        if (keep.version === keep_v) gate.i({ layout_set_coalesces: 1 })
        // (6) P6 CURSOR-MEMORY mechanism — the Keep records WHERE in a Waft the cursor sat
        //     (Lies_keep_note_cursor) and resolves it back on re-open (Lies_keep_resume_what), so a
        //      re-foreground re-lands on the LAST What, not the Waft's first.  The LIVE wiring is
        //       role-gated to the editor (Lies_role is undefined inside a Story Run), so the gate
        //        drives the two Keep functions directly, proving the record→resolve mechanism the
        //         foreground leans on (Lies.svelte e_Lies_foreground_waft, the resume branch).
        const memw = w.oai({ Waft: 'KeepMem' })
        const mw1  = memw.i({ What: 'first' })
        const mw2  = memw.i({ What: 'second' })
        H.Lies_keep_note(w, 'KeepMem')                         // mint the WaftTimes the %Cursor rides
        H.Lies_keep_note_cursor(w, 'KeepMem', mw2)             // the cursor last sat on the SECOND What
        const resumed = H.Lies_keep_resume_what(w, memw, 'KeepMem')
        if (resumed === mw2) gate.i({ cursor_memory_resumes_last_what: 1 })
        if (resumed !== mw1) gate.i({ cursor_memory_not_first_what:   1 })
        gate.bump_version(); w.bump_version()
    },
//#endregion
//#region LakeSearch
    // Universal-search gate — the Stemdex index + Lies_search driven end to end on a coined,
    //  collision-proof corpus seeded straight into the store: NO disk read fires (content rides
    //   good.c.content so the scan takes the already-loaded branch; a fixed known.sc.dige takes
    //    the dige gate).  Three synthetic %Good text/Docs under one backstage equip Waft (folds
    //     from the snap); markers under SearchGate, snap-fixture diff is the gate.  Corpus tuned
    //      to the live stemmer (Lies_stem: lowercase + strip ings?/ers?/eds?/es/s, ies→y, len>4):
    //       recorded|recording|records → record, frobnitz unchanged.  brand_new — needs a first
    //        --accept to mint 001.snap + the real step dige; some beats may want live tuning.

    Run_A_LakeSearch(this: House) {
        const H = this
        H.i({ A: 'Lies'       }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LakeSearch wired`)
    },

    async e_Lies_search_selftest(this: House, A: TheC, w: TheC, e: TheC) {
        const H = this
        const gate = w.oai({ SearchGate: 1 })
        const gl = w.o({ Waft: 'GhostList' })[0] as TheC | undefined
        if (gl) gl.sc.dontSnap = 1                                  // fold a volatile GhostList (headless boot only)
        // ── the coined corpus: each doc is a roster %Doc + a fully-loaded %Good (no disk read) ──
        const store = await H.LiesStore_req(w)
        const back  = w.oai({ Waft: 'SearchW' }, { equip: 'Search' })   // backstage → folds from the snap
        const seed = (name: string, path: string, dige: string, text: string) => {
            back.oai({ What: name }).oai({ Doc: path })                 // roster: Lies_walk_docs collects sc.Doc
            const good = store.oai({ Good: 1, type: 'text/Doc', path }) as TheC
            good.c.content = text                                       // OFF-SNAP → content !== undefined
            good.oai({ known: 1 }).sc.dige = dige                       // fixed dige → dige gate, no re-hash
            return path
        }
        // zorble.md: frobnitz on three LINES (postings count lines, not occurrences — ≤6/stem) so it
        //  strictly outranks quux's single frobnitz line for the beat-4 AND-density claim (no tie).
        const ZORBLE   = seed('zorble',   'SearchW/zorble.md',  'seed-zorble-1',
            '# Zorblender overview\n\nA recording of the zorbler.\nfrobnitz opens the set.\nfrobnitz keeps the groove.\nfrobnitz closes the night.\n')
        const FROBNITZ = seed('frobnitz', 'SearchW/frobnitz.ts', 'seed-frobnitz-1',
            'function frobnicate(x) {\n  const zorbler = (n) => n\n  // sc.gleeb .c.wibble %Zorblet\n  return frobnitz\n}\n')
        const QUUX     = seed('quux',     'SearchW/quux.ts',    'seed-quux-1',
            'records the frobnitz once\n')

        // ── beat 0: seed + one real scan pass → every SEEDED doc converged (indexed, none missing).
        //   Scoped to the three SearchW paths, NOT the global roster total: the toc's
        //    Opt/dontSnapGhostList gates the GhostList out of the WORK (Lies.svelte:849 — a bare
        //     in-Story Lies would otherwise keep that chrome), so never gate on `total`. ──
        await H.e_Lies_stemdex_scan(A, w, e)
        const dex = H.Lies_stemdex(w)
        const seeded_indexed = [ZORBLE, FROBNITZ, QUUX].every(p => dex.docs.has(p))
        if (seeded_indexed && dex.missing === 0) gate.i({ index_converged: 1 })

        // ── beat 1: a method search finds the def by name with file + line ──
        const d1 = (H.Lies_search(w, 'frobnicate', 24).defs as any[]).find(d => d.name === 'frobnicate')
        if (d1 && d1.path === FROBNITZ && d1.line > 0) gate.i({ method_search_finds_def: 1 })

        // ── beat 2: a property search covers an sc key AND a %Notation mark alike ──
        const p2a = (H.Lies_search(w, 'gleeb',   24).props as any[]).some(p => p.path === FROBNITZ)
        const p2b = (H.Lies_search(w, 'Zorblet', 24).props as any[]).some(p => p.path === FROBNITZ)
        if (p2a && p2b) gate.i({ prop_search_covers_sc_and_notation: 1 })

        // ── beat 3: a freetext query matches on a shared stem (recorded → recording) ──
        if ((H.Lies_search(w, 'recorded', 24).texts as any[]).some(t => t.path === ZORBLE))
            gate.i({ freetext_matches_on_shared_stem: 1 })

        // ── beat 4: two-token AND keeps only docs holding BOTH stems, ranks the denser first.
        //   frobnitz recording: zorble(frobnitz×3 + recording) outranks quux(frobnitz + records);
        //    frobnitz.ts holds frobnitz but no record-stem, so AND drops it. ──
        const t4 = H.Lies_search(w, 'frobnitz recording', 24).texts as any[]
        if (t4[0]?.path === ZORBLE && t4.some(t => t.path === QUUX) && !t4.some(t => t.path === FROBNITZ))
            gate.i({ two_token_and_ranks_denser_first: 1 })

        // ── beat 5: a word nowhere in the corpus returns nothing — no false hit ──
        const r5 = H.Lies_search(w, 'xyloburst', 24)
        if (!(r5.defs as any[]).length && !(r5.props as any[]).length && !(r5.texts as any[]).length)
            gate.i({ absent_word_returns_nothing: 1 })

        // ── beat 6: editing a doc + moving its dige reindexes only that doc ──
        const zg = store.o({ Good: 1, type: 'text/Doc', path: ZORBLE })[0] as TheC
        zg.c.content = (zg.c.content as string) + 'snarfle\n'
        ;(zg.o({ known: 1 })[0] as TheC).sc.dige = 'seed-zorble-2'
        await H.e_Lies_stemdex_scan(A, w, e)
        if ((H.Lies_search(w, 'snarfle', 24).texts as any[]).some(t => t.path === ZORBLE))
            gate.i({ dige_move_reindexes: 1 })

        gate.bump_version(); w.bump_version()
    },
//#endregion
//#region LakeTtlilt
    // ttlilt retract-on-drop gate — proves the belief-loop fix (Hovercraft.svelte:548): a req dropped
    //  WITHOUT finishing (host.drop → c.drop=1, no %finished) must have its published Run-root ttlilt
    //   copy RETRACTED by the Story poll, not held to wall-clock timeout.  This is the Sounditron 4→5
    //    stall in isolation (expecting() hangs its req directly on w).  Claims under TtliltGate; the
    //     dropped_req_ttlilt_retracts claim is the one that FAILED before the fix.

    Run_A_LakeTtlilt(this: House) {
        const H = this
        H.i({ A: 'Lies'       }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LakeTtlilt wired`)
    },

    async e_Lies_ttlilt_selftest(this: House, A: TheC, w: TheC, e: TheC) {
        const H = this
        const gate = w.oai({ TtliltGate: 1 })
        const gl = w.o({ Waft: 'GhostList' })[0] as TheC | undefined
        if (gl) gl.sc.dontSnap = 1
        // a req hung directly on w (the expecting()-on-w shape); c.up stamped so i_req_ttlilt's climb
        //  reaches the sc.w world and publishes the flat Run-root copy that the poll reads.
        const req = w.i({ req: 'ttldrop' }); req.c.up = w
        H.i_req_ttlilt(req, 300)                                      // arm — far-future deadline
        const my_copy = () => (H.o({ ttlilt: 1 }) as TheC[]).some((t) => t.sc.req === req)
        // (1) armed → a live published ttlilt copy exists for this req (the world is held)
        if (my_copy()) gate.i({ armed_ttlilt_holds: 1 })
        // (2) THE FIX: drop the req WITHOUT finishing, then run one poll pass — the poll must retract
        //     the published copy on sight (req.c.drop), not hold it to timeout.
        w.drop(req)
        H.o_Story_req_ttlilt(H)                                       // one poll pass (retract side-effect)
        if (!my_copy()) gate.i({ dropped_req_ttlilt_retracts: 1 })
        gate.bump_version(); w.bump_version()
    },
//#endregion
//#region LakeFunk
    // Chunk-2 gate — Storying is EVENT-DRIVEN, not pumped.  Drops `run` from FUNK_KINDS.Storying so
    //  instantiate binds no per-tick poll; instead Lies_reflect_storying restamps a cell's verdict
    //   when a run_result lands (Lies_run_result_recv's push).  This builds a Storying cell, confirms
    //    it is unpumped, lands a green then a red run_result through reflect, and witnesses the verdict
    //     flips — markers under FunkGate, snap-fixture diff is the gate.

    Run_A_LakeFunk(this: House) {
        const H = this
        H.i({ A: 'Lies'       }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LakeFunk wired`)
    },

    async e_Lies_funk_selftest(this: House, _A: TheC, w: TheC, _e: TheC) {
        const H = this
        const gate = w.oai({ FunkGate: 1 })
        const gl = w.o({ Waft: 'GhostList' })[0] as TheC | undefined
        if (gl) gl.sc.dontSnap = 1
        // a Waft holding a Storying cell bound to a dock path (equip → backstage, folds from the snap)
        const waft = w.oai({ Waft: 'FunkW' }, { equip: 'Funk' })
        const cell = waft.oai({ Funkcion: 'Storying', of_dock: 'FunkW/dockA' })
        await H.Lies_instantiate_funkcions(w, waft)
        // (1) NOT pumped — instantiate binds no funk.c.run on a Storying cell (Chunk 2 dropped it).
        if (!cell.c.run) gate.i({ storying_cell_is_not_pumped: 1 })
        // (2) a GREEN run_result lands → reflect restamps the verdict good (3/3).
        await w.roai({ run_result: 1, path: 'FunkW/dockA' }, { ok: 1, ok_pct: 1, done: 3, at: 1 })
        H.Lies_reflect_storying(w, { path: 'FunkW/dockA' })
        const vg = cell.c.verdict as { phase?: string, total?: number } | undefined
        if (vg?.phase === 'good' && vg?.total === 3) gate.i({ green_result_event_marks_verdict_good: 1 })
        // (3) a RED run_result lands → reflect flips the verdict bad.
        await w.roai({ run_result: 1, path: 'FunkW/dockA' }, { ok: 0, ok_pct: 0, done: 3, at: 2 })
        H.Lies_reflect_storying(w, { path: 'FunkW/dockA' })
        if ((cell.c.verdict as { phase?: string } | undefined)?.phase === 'bad') gate.i({ red_result_event_flips_verdict_bad: 1 })
        gate.bump_version(); w.bump_version()
    },
//#endregion
//#region LakeLango
    // P3 gate — the %Lango channel AND its receiver (Backbone_plan P3 "The Lango channel" +
    //  "req:Langoer").  In-system Story, NOT a scratch spec: a Prep fires e_Lies_lango_selftest,
    //   which mints %Langos via H.lango onto each source Waft's req:Waftica carrier, then drives
    //    req:Langoer (req:Keeping's receiver hat) over them.  Proves BOTH halves:
    //     SOURCE  — mint · same-kind out-compete (newest-wins) · different-kind coexist.
    //     RECEIVER — a Cursor Lango BECOMES focus (req:Langoer,focus); an %equip source never wins
    //                even when its Cursor is newer (background never steals the foreground); the
    //                globally-newest foregroundable Cursor wins across carriers (the seq tiebreak).
    //   Langoer STANDS BESIDE the old .sc.active path — it records its verdict, writes no live focus
    //    (that cut is owner-supervised, :9091).  Markers under LangoGate; the snap-fixture diff —
    //     with the per-Lango `seq` munged (its base churns) and equip Wafts folded — is the gate.

    Run_A_LakeLango(this: House) {
        const H = this
        H.i({ A: 'Lies'       }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LakeLango wired`)
    },

    async e_Lies_lango_selftest(this: House, _A: TheC, w: TheC, _e: TheC) {
        const H = this
        const gate = w.oai({ LangoGate: 1 })
        const gl = w.o({ Waft: 'GhostList' })[0] as TheC | undefined
        if (gl) gl.sc.dontSnap = 1                                  // fold the volatile GhostList list
        const carrier_of = (waft: string) =>
            (w.o({ Funkcions: 1 })[0]?.o({ req: 'Waftica', waft }) ?? [])[0] as TheC | undefined

        // a FOREGROUNDABLE source first (no equip) — its Cursor is the OLDEST of the run (seq-low),
        //  so the later equip Cursor is strictly NEWER: the equip filter, not recency, is what must
        //   keep it out of focus below.
        const fore = w.oai({ Waft: 'LangoFore' })
        await H.lango(w, fore, { kind: 'Cursor', to: 'Waft:LangoFore/What:a' })

        // the SOURCE half, on an %equip Waft (backstage → its OWN subtree folds, but its carrier's
        //  Langos still snap): mint · out-compete · coexist.
        const src = w.oai({ Waft: 'LangoW' }, { equip: 'Lango' })
        // (1) mint — H.lango puts ONE %Lango,Cursor on the source's carrier, carrying its target.
        await H.lango(w, src, { kind: 'Cursor', to: 'Waft:LangoW/What:x' })
        const cur1 = carrier_of('LangoW')?.o({ Lango: 'Cursor' }) as TheC[] | undefined
        if (cur1?.length === 1 && cur1[0].sc.to === 'Waft:LangoW/What:x') gate.i({ lango_mints_on_carrier: 1 })
        // (2) out-compete — a newer Cursor Lango supersedes: still ONE, target updated (newest-wins).
        await H.lango(w, src, { kind: 'Cursor', to: 'Waft:LangoW/What:y' })
        const cur2 = carrier_of('LangoW')?.o({ Lango: 'Cursor' }) as TheC[] | undefined
        if (cur2?.length === 1 && cur2[0].sc.to === 'Waft:LangoW/What:y') gate.i({ same_kind_out_competes: 1 })
        // (3) a different kind coexists — a %Lango,Lens sits beside the Cursor (a level-set sub-type).
        await H.lango(w, src, { kind: 'Lens', to: 'Runner' })
        const c3 = carrier_of('LangoW')
        if ((c3?.o({ Lango: 'Cursor' }) as TheC[]).length === 1 && (c3?.o({ Lango: 'Lens' }) as TheC[]).length === 1)
            gate.i({ different_kind_coexists: 1 })

        // the RECEIVER half — seed req:Langoer (req:Keeping's receiver hat) and drive it over the
        //  observable Langos.  {w} so upto_w resolves; the do_fn is req_Langoer (name convention).
        const langoer = w.oai({ req: 'Langoer', eternal: 1 }, { w })
        await H.req_Langoer(langoer)
        // a Cursor Lango BECOMES focus: the foregroundable LangoFore is the verdict.
        if (langoer.sc.focus === 'LangoFore') gate.i({ cursor_lango_drives_focus: 1 })
        // LangoW's Cursor (seq-high, the NEWEST so far) is on an %equip source → it must NOT win:
        //  background never steals the foreground, even when newer (the resume-want boomerang).
        const langoW_has_cursor = (carrier_of('LangoW')?.o({ Lango: 'Cursor' }) as TheC[] | undefined)?.length === 1
        if (langoW_has_cursor && langoer.sc.focus !== 'LangoW') gate.i({ equip_source_never_focuses: 1 })

        // the seq tiebreak ACROSS carriers — a second foregroundable Cursor, now the globally-newest,
        //  takes the foreground (out-compete only orders within one carrier; seq orders between them).
        const fore2 = w.oai({ Waft: 'LangoFore2' })
        await H.lango(w, fore2, { kind: 'Cursor', to: 'Waft:LangoFore2/What:b' })
        await H.req_Langoer(langoer)
        if (langoer.sc.focus === 'LangoFore2') gate.i({ newest_fg_cursor_wins: 1 })

        // THE boomerang policy — a `cold` resume Cursor, even the NEWEST of all, must NOT unseat a
        //  deliberate move: a background re-open can't steal the user's focus.  Mint a cold Cursor
        //   on a fresh fg Waft with the highest seq; the verdict must STAY LangoFore2 (the deliberate
        //    leader).  This is the receiver's half of the boomerang fix, proven before the live cut.
        const resume = w.oai({ Waft: 'LangoResume' })
        await H.lango(w, resume, { kind: 'Cursor', to: 'Waft:LangoResume/What:c', cold: true })
        await H.req_Langoer(langoer)
        if (langoer.sc.focus === 'LangoFore2') gate.i({ deliberate_beats_newer_cold: 1 })

        // THE CUT (Move 4) — req_Langoer now DRIVES the session focus from its verdict: the
        //  winning Waft actually HOLDS .sc.active (and Lies_focus_waft + the desire/acquire lock
        //   follow it), not just the recorded req:Langoer,focus.  The boomerang fix observable
        //    end-to-end — the foreground follows the deliberate verdict, LangoFore2, where before
        //     the lock froze on the arbitrary first Waft while the verdict said otherwise.
        const won = w.o({ Waft: 'LangoFore2' })[0] as TheC | undefined
        if (won?.sc.active && langoer.sc.focus === 'LangoFore2') gate.i({ cut_drives_active: 1 })

        gate.bump_version(); w.bump_version()
    },
//#endregion
//#region LakeWaftMap
    // The Plank gate — WATCH Lies_waftmap_model group things (burst rows / shafts of light /
    //  stacks of two / crumbs / seams), snap by snap, while Preps play the cursor and the
    //   foreground around two fixture Wafts (TestEasy, TestDeep — they share LakeAntecedents.g,
    //    the ×2 Doc) plus seeded calm ones.  The dump is a per-beat WORKER on its own
    //     w:LakeWaftMap (a snap boundary): each beat it recomputes the model off the sibling
    //      w:Lies and rebuilds the dump ONLY when the fingerprint changed, so the world
    //       quiesces and the step snap always holds the grouping as-at quiesce — no Prep-order
    //        race against want resolution.  The snap-fixture diff is the gate AND the design
    //         surface: iterate the grouping algorithm by reading these snaps.

    Run_A_LakeWaftMap(this: House) {
        const H = this
        H.i({ A: 'Lies'        }).i({ w: 'Lies' })
        H.i({ A: 'Lang'        }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'   }).i({ w: 'Pantheate' })
        H.i({ A: 'LakeWaftMap' }).i({ w: 'LakeWaftMap' })   // the dump worker's world (w-name dispatch)
        console.log(`🟦 ${H.name} LakeWaftMap wired`)
    },

    // the per-beat dump worker — dispatched by the w-name.  Reads the sibling w:Lies.
    async LakeWaftMap(A: TheC, w: TheC) {
        const H  = this as House
        const wl = H.o({ A: 'Lies' })[0]?.o({ w: 'Lies' })[0] as TheC | undefined
        if (!wl) return
        const m = H.Lies_waftmap_model(wl, { budget: 12 })
        // fingerprint — rebuild only on real change, else the version churn never quiesces
        const fp = JSON.stringify({
            rows: m.rows.map((r: any) => r.kind === 'stack'
                ? ['stack', r.wafts.map((s: any) => s.title)]
                : [r.title, +r.burst, +r.fg, +r.hot, +r.touched, +r.boring, +r.board, r.enth,
                   r.above, r.below, r.lo, r.hi, +r.show_all, r.colh,
                   r.docs.map((d: any) => [d.title, d.cursor ? 1 : 0, d.shared ?? 0])]),
            crumbs: m.crumbs.map((c: any) => c.title),
            seams:  +m.bursting, chips: m.chips,
        })
        if (w.c.fp === fp) return
        w.c.fp = fp
        const gate = w.oai({ WaftMapGate: 1 })
        const old  = gate.o({ plank: 1 })[0] as TheC | undefined
        if (old) gate.drop(old)
        const plank = gate.i({ plank: 1 })
        plank.sc.chips = m.chips as any
        for (const r of m.rows as any[]) {
            if (r.kind === 'stack') { plank.i({ stack: r.wafts.map((s: any) => s.title).join('|') }); continue }
            const sc: any = { row: r.title }
            if (r.enth >= 2) sc.enth = r.enth   // 1|0 are legible from calm|stack; a snapped 1 rides as a bare flag

            if (r.fg)      sc.fg = 1
            if (r.hot)     sc.hot = 1
            if (r.touched) sc.touched = 1
            if (r.boring)  sc.boring = 1
            if (r.board)   sc.board = 1
            if (!r.burst)  sc.calm = 1
            if (!r.loaded) sc.cold = 1
            const rc = plank.i(sc)
            if (r.burst) {
                // the cluster shape: big Waft name + the Doc list (the UI folds it into
                //  columns of r.colh) — ALL Docs when show_all (≤ the cap), the lit window
                //   keyed `lit`, the rest `doc`; a capped list dumps only its window between
                //    glowing above|below edges.  (The What** breadcrumb was ripped from the
                //     map — keep it simple.)
                if (r.above) rc.i({ above: r.above })
                const docs: any[] = r.show_all ? r.docs : r.docs.slice(r.lo, r.hi)
                const base       = r.show_all ? 0 : r.lo
                docs.forEach((d: any, k: number) => {
                    const i   = base + k
                    const key = i >= r.lo && i < r.hi ? 'lit' : 'doc'
                    const dsc: any = { [key]: d.title }
                    if (d.cursor) dsc.cursor = 1
                    if (d.shared) dsc.x = d.shared
                    rc.i(dsc)
                })
                if (r.below) rc.i({ below: r.below })
            } else if (r.docs.length) rc.sc.n = r.docs.length as any
        }
        for (const c of m.crumbs as any[]) plank.i({ crumb: c.title, of: H.Lies_waftmap_title(c.waft) })
        if (m.bursting) plank.i({ seams: 1 })
        gate.bump_version(); w.bump_version()
    },

    // the seed Prep — a touch memory on TestDeep (a carrier %Lango,Cursor, the same feed a real
    //  cursor land mints, so TestDeep's shaft lights WITHOUT foregrounding it) + calm Wafts of
    //   both kinds: CalmA|CalmB are plain CONTENT (each a discernible calm row), CalmC|CalmD
    //    carry %boring (equipment that recedes into a stack) — so one snap shows both the
    //     content-never-shrinks rule and the boring-only-stacks rule.
    async e_Lies_waftmap_seed(this: House, _A: TheC, w: TheC, _e: TheC) {
        const H = this
        for (const name of ['CalmA', 'CalmB']) w.oai({ Waft: `Calm/${name}` })
        for (const name of ['CalmC', 'CalmD']) w.oai({ Waft: `Calm/${name}` }, { boring: 1 })
        const deep = w.o({ Waft: 'Story/LakeWaftMap/TestDeep' })[0] as TheC | undefined
        if (deep) await H.lango(w, deep, { kind: 'Cursor', to: 'Ghost/test/Story/Lake/WaftMapPacked.g' })
        w.bump_version()
        H.i_elvisto(w, 'think')
    },

//#endregion
//#region Engage
    // Engage gate — the runner-engagement layer (Engage_integration C2 + C1).  Same in-system Story
    //  shape as LakeKeep: a Prep fires e_Lies_engage_selftest, which stands up the PRODUCTION dispatch
    //   topology (one Peering, two Piers — the shape no swarm Book exercises, since the co-resident
    //    swarm runs one Pier per Peering) plus a Waft:Cluster/%HostedIdentity registry, drives the
    //     addressed-dispatch primitive + the favoured-runner lookup, and emits a marker per truth that
    //      holds.  Markers under EngageGate; the snap-fixture diff is the gate.  (C3's busy/free is a
    //       role-gated advertise + a Svelte Brink — browser-verified, not gated here.)  Peeroleum is a
    //        Creduler-acquired spine, so the C2 block guards on its presence — live runner ⇒ present.

    Run_A_Engage(this: House) {
        const H = this
        H.i({ A: 'Lies'       }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} Engage wired`)
    },

    async e_Lies_engage_selftest(this: House, _A: TheC, w: TheC, _e: TheC) {
        const H = this
        const gate = w.oai({ EngageGate: 1 })
        const gl = w.o({ Waft: 'GhostList' })[0] as TheC | undefined
        if (gl) gl.sc.dontSnap = 1
        // ── C2: addressed dispatch.  One Peering (a single identity), two Piers (two runners on the
        //     grid).  dontSnap the Peering so the topology + its outbox emit fold from the fixture —
        //      the EngageGate markers are the gate, the plumbing is just scaffolding.
        if (typeof (H as any).Peeroleum_send_to === 'function') {
            const peering = w.oai({ Peering: 1, name: 'editor' }, { dontSnap: 1 }) as TheC; peering.c.up = w
            const pa = peering.oai({ Pier: 1, pub: 'AAA' }) as TheC; pa.c.up = peering
            const pb = peering.oai({ Pier: 1, pub: 'BBB' }) as TheC; pb.c.up = peering
            const seq    = (H as any).Peeroleum_send_to(w, 'BBB', 'become_book', { book: 'X' })
            const emitsB = (pb.o({ outbox: 1 })[0]?.o({ emit: 1 }) ?? []) as TheC[]
            const emitsA = (pa.o({ outbox: 1 })[0]?.o({ emit: 1 }) ?? []) as TheC[]
            if (seq === 1 && pb.c.seq === 1 && emitsB.length === 1) gate.i({ send_to_routes_to_addressed_pier: 1 })
            if ((pa.c.seq ?? 0) === 0 && emitsA.length === 0)       gate.i({ send_to_leaves_other_pier_untouched: 1 })
            if ((H as any).Peeroleum_send_to(w, 'ZZZ', 'become_book', { book: 'X' }) === undefined) gate.i({ send_to_unknown_pub_is_undefined: 1 })
            // promotion — Lies_runner_pier mints a Ud-stamped Pier keyed by prepub, c.up wired, idempotent.
            const cc = H.Lies_runner_pier(w, 'CCC') as TheC | undefined
            if (cc?.sc.pub === 'CCC' && !!cc?.oa({ Ud: 1 }) && cc?.c.up === peering)            gate.i({ runner_pier_promotes_trusted: 1 })
            if (H.Lies_runner_pier(w, 'CCC') === cc && H.Lies_runner_pier(w, 'BBB') === pb)      gate.i({ runner_pier_idempotent: 1 })
        }
        // ── C1: the favoured-runner lookup over the Waft:Cluster/%HostedIdentity registry — a READ,
        //     no frame, no receiver.  Set favourite_client directly (advertise_recv mirrors it live).
        //      equip the Cluster Waft so the registry folds from the fixture like the real one.
        const cl = w.oai({ Waft: 'Cluster' }, { equip: 'Engage' }) as TheC
        ;(cl.oai({ HostedIdentity: 'RUNX' }) as TheC).sc.favourite_client = 'CLIENTY'
        cl.oai({ HostedIdentity: 'RUNZ' })   // unclaimed — favours nobody
        if (H.Lies_favoured_runner(w, 'CLIENTY') === 'RUNX')   gate.i({ favoured_runner_resolves_host: 1 })
        if (H.Lies_favoured_runner(w, 'NOBODY') === undefined) gate.i({ favoured_runner_unfavoured_undefined: 1 })
        gate.bump_version(); w.bump_version()
    },
//#endregion











































//#region TextInca
// TextInca — unit-test book for encode_wh_lines / decode_wh_lines / enLine / lematch.
//
// Historical particles drawn from antiquity give the codec a realistic spread
// of sc shapes: negative integers (founding dates), multi-word strings that
// stay in peel format, comma-bearing values that force JSON fallback, and multi-line
// block scalars tested through enLine + blockquote_these_sc.
//
// ── story_matching entry required (add to Story.svelte story_matching array) ────────
//
//   { matching_any: [{ sc_has: { w: 'TextInca' } }],
//     means: { thence_matching: [
//       { matching_any: [{ sc_has: { enc_test: 1 } }],
//         means: { blockquote_these_sc: { snap_output: 1 } } },
//     ]}},
//
//   Without this, snap_output (multi-line snap text) encodes as a JSON-escaped
//   blob.  With it, each enc_test/{snap_output} appears as a YAML block scalar
//   directly in Story's snap — readable and diffable.
//
// ── tests ────────────────────────────────────────────────────────────────────
//
//   1. round_trip          3-level empire tree: encode + decode, verify counts and values
//   2. peel_vs_json        a comma in a value forces JSON; a colon in a value rides through peel
//   3. bq_encode           enLine with blockquote_these_sc emits key: | lines; parent line omits the key
//   4. bq_roundtrip        decode_wh_lines recovers block-scalar string verbatim, including trailing \n
//   5. bq_no_newline       value not ending \n → bq_errors entry, key falls through to inline
//   6. mung_cycle          enLine with munging rules marks key in objecties.mung;
//                          decode_wh_lines refuses to load a mung-marked line
//   7. ref_inline          object ref in sc → objecties.ref in snap (no error from enLine itself;
//                          auto_save_library pre-strips objects before encode_wh_lines for this reason)
//   8. dupe_impossible     encode_wh_lines copies sc into fresh _C per node —
//                          the seen-set dupe guard cannot fire through the normal API
//   9. decode_errors       empty snap / second root / depth jump / BQ key with no body
//  10. lematch             sc_has wildcard, sc_has value, sc_only exact, sc_only inexact,
//                          skip, thence propagation, thence dedup, deprecated 'sc' key throws

Run_A_TextInca(this: House) {
    const H = this
    H.i({ A: 'TextInca' }).i({ w: 'TextInca' })
    console.log(`📜 ${H.name} TextInca wired`)
},

async TextInca(A: TheC, w: TheC) {
    const H = this as House
    // run once — tests are stateless, a second pass would double-i() into w
    if (w.c.TextInca_ran) return
    w.c.TextInca_ran = true
 
    const record = (
        label:       string,
        ok:          boolean,
        extra:       Record<string, any> = {},
        snap_output?: string,
    ) => {
        const sc: Record<string, any> = { enc_test: label, ok: ok ? 1 : 0, ...extra }
        if (snap_output) sc.snap_output = snap_output
        return w.i(sc)
    }
 
    // ── 1. round_trip ─────────────────────────────────────────────────────
    // Two empires, each with Emperor and Event children.
    // Some labels carry a colon, which rides through peel (decode splits each
    //  comma-field on its first colon); every line stays peel and must round-trip.
    // Visible in snap_output.
    {
        const romanC = _C({ Empire: 'Roman', founded: -753, fell: 476, capital: 'Rome' })
        romanC.i(_C({ Emperor: 1, name: 'Augustus',  reign_start: -27,  reign_end: 14  }))
        romanC.i(_C({ Emperor: 1, name: 'Trajan',    reign_start: 98,   reign_end: 117, note: 'Optimus' }))
        romanC.i(_C({ Emperor: 1, name: 'Hadrian',   reign_start: 117,  reign_end: 138 }))
        romanC.i(_C({ Event: 1,   year: 79,  label: 'Vesuvius' }))
        // colon in label rides through peel (no comma to break the field)
        romanC.i(_C({ Event: 1,   year: 476, label: 'Romulus Augustulus deposed: end of Western Empire' }))
 
        const mongolC = _C({ Empire: 'Mongol', founded: 1206, fell: 1368, capital: 'Karakorum' })
        mongolC.i(_C({ Emperor: 1, name: 'GenghisKhan', reign_start: 1206, reign_end: 1227 }))
        mongolC.i(_C({ Emperor: 1, name: 'KublaiKhan',  reign_start: 1260, reign_end: 1294 }))
        // colon again — still peel
        mongolC.i(_C({ Event: 1, year: 1258, label: 'Sack of Baghdad: House of Wisdom destroyed' }))
 
        const rootC = _C({ Civilization: 1 })
        rootC.i(romanC)
        rootC.i(mongolC)
 
        const { snap, errors: enc_errors } = await H.encode_wh_lines(rootC)
        const { C: decoded, errors: dec_errors } = H.decode_wh_lines(snap)
 
        const empires      = (decoded?.o({ Empire: 1 }) ?? []) as TheC[]
        const roman_C      = empires.find(e => e.sc.Empire === 'Roman')
        const mongol_C     = empires.find(e => e.sc.Empire === 'Mongol')
        const roman_emp    = (roman_C?.o({ Emperor: 1 }) ?? []) as TheC[]
        const mongol_emp   = (mongol_C?.o({ Emperor: 1 }) ?? []) as TheC[]
 
        const rt_ok = !enc_errors.length && !dec_errors.length
            && empires.length === 2
            && roman_emp.length === 3
            && mongol_emp.length === 2
            && roman_C?.sc.founded === -753
            && roman_C?.sc.capital === 'Rome'
            && roman_emp[1]?.sc.note === 'Optimus'
 
        record('round_trip', !!rt_ok, {
            empires:         empires.length,
            roman_emperors:  roman_emp.length,
            mongol_emperors: mongol_emp.length,
            enc_errors:      enc_errors.length,
            dec_errors:      dec_errors.length,
        }, snap)
    }
 
    // ── 2. peel_vs_json ───────────────────────────────────────────────────
    // encode_stringies forces JSON only when a VALUE carries , \t \n (a KEY also
    //  on :).  A colon INSIDE a value rides through peel — decode splits each
    //   comma-field on its first colon only, so it can't mis-split.
    // Marathon's comma forces JSON; Thermopylae's colon-in-value and Hastings stay peel.
    {
        const rootC = _C({ BattleLog: 1 })
        rootC.i(_C({ Battle: 'Thermopylae', year: -480, desc: 'Leonidas: 300 Spartans vs Xerxes' }))
        rootC.i(_C({ Battle: 'Marathon',    year: -490, desc: 'Athenians, Plataeans vs Persians' }))
        rootC.i(_C({ Battle: 'Hastings',    year: 1066, victor: 'Norman' }))
 
        const { snap, errors } = await H.encode_wh_lines(rootC)
        const lines = snap.split('\n').filter(Boolean)
        // lines[0] = 'BattleLog:1', lines[1..3] = the battles
        const thermo_peel = lines[1]?.trimStart().startsWith('Battle:Thermopylae')
        const mara_json   = lines[2]?.trimStart().startsWith('{')
        const hast_peel   = lines[3]?.trimStart().startsWith('Battle:Hastings')
 
        record('peel_vs_json', !errors.length && !!thermo_peel && !!mara_json && !!hast_peel, {
            thermo_peel: thermo_peel ? 1 : 0,
            mara_json:   mara_json   ? 1 : 0,
            hast_peel:   hast_peel   ? 1 : 0,
            enc_errors:  errors.length,
        }, snap)
    }
 
    // ── 3 + 4. bq_encode and bq_roundtrip ────────────────────────────────
    // enLine called directly with blockquote_these_sc:{source:1} on an Output
    // particle.  This tests the BQ machinery in isolation; for a tree encode
    // with BQ, opt.matching would carry the same rule into encode_wh_lines.
    //
    //   Parent line: Output:1 name:Cannae.txt dige:abc123   (no source here)
    //    source: |                                           (3 spaces = 2*d+1, d=1)
    //      Hannibal Barca crossed the Alps...               (5 spaces = 2*d+3)
    {
        const source_text =
`Hannibal Barca crossed the Alps with thirty-seven war elephants in 218 BC.
At Cannae in 216 BC he encircled a Roman army of seventy thousand men.
The double-envelopment became the template for every subsequent battle of annihilation.
`
        const n = _C({ Output: 1, name: 'Cannae.txt', dige: 'abc123', source: source_text })
        const rules = [{
            matching_any: [{ sc_has: { Output: 1 } }],
            means: { blockquote_these_sc: { source: 1 } },
        }]
        const q: any = { d: 1, rules }
        const lines = H.enLine(n, q) ?? []
 
        const parent_line    = lines[0] ?? ''
        const has_bq_key     = lines.some(l => l.trim() === 'source: |')
        const has_bq_body    = lines.some(l => l.includes('Hannibal'))
        const parent_no_src  = !parent_line.includes('source')
 
        record('bq_encode', parent_no_src && has_bq_key && has_bq_body, {
            line_count:    lines.length,
            bq_key:        has_bq_key    ? 1 : 0,
            bq_body:       has_bq_body   ? 1 : 0,
            parent_clean:  parent_no_src ? 1 : 0,
        }, lines.join('\n') + '\n')
 
        // round-trip: wrap in a root so decode_wh_lines sees a valid tree
        const full_snap = `BQ_wrap:1\n` + lines.join('\n') + '\n'
        const { C: bq_decoded, errors: bq_errors } = H.decode_wh_lines(full_snap)
        const bq_child     = bq_decoded?.o({ Output: 1 })[0] as TheC | undefined
        const roundtrip_ok = bq_child?.sc.source === source_text && !bq_errors.length
        record('bq_roundtrip', !!roundtrip_ok, { dec_errors: bq_errors.length })
    }
 
    // ── 5. bq_no_newline ─────────────────────────────────────────────────
    // A BQ value not ending in \n → bq_errors entry, key emitted inline instead.
    // enLine preserves the data (inline fallback) but flags it loudly.
    {
        const n = _C({ Output: 1, name: 'truncated.txt', dige: 'xyz789', source: 'no newline at end' })
        const rules = [{
            matching_any: [{ sc_has: { Output: 1 } }],
            means: { blockquote_these_sc: { source: 1 } },
        }]
        const q: any = { d: 0, rules }
        const lines = H.enLine(n, q) ?? []
        const bq_errors     = q.bq_errors ?? []
        const source_inline = lines[0]?.includes('source')
 
        record('bq_no_newline', bq_errors.length > 0 && !!source_inline, {
            bq_error_count: bq_errors.length,
            source_inline:  source_inline ? 1 : 0,
        })
    }
 
    // ── 6. mung_cycle ────────────────────────────────────────────────────
    // enLine with a munging rule excludes the munged key and sets objecties.mung.
    // decode_wh_lines sees objecties.mung on a loaded line → error, line skipped.
    // mung = "this key was deliberately suppressed, not just missing".
    {
        const n_nero = _C({ Emperor: 1, name: 'Nero', reign_end: 68, volatile_ts: 1712345678 })
        const mung_rules = [{
            matching_any: [{ sc_has: { Emperor: 1 } }],
            means: { munging: [{ these_sc: { volatile_ts: 1 }, type: 'timestamp' }] },
        }]
        const q_enc: any = { d: 1, rules: mung_rules }
        const enc_lines = H.enLine(n_nero, q_enc) ?? []
 
        const parent_line   = enc_lines[0] ?? ''
        // q.mung is the list of keys the rule suppressed — check that directly
        // rather than scanning the whole line (the key name appears in the mung array JSON too).
        const mung_excluded = (q_enc.mung ?? []).includes('volatile_ts')
        const mung_marker   = parent_line.includes('"mung"')
 
        const mung_snap = `MungRoot:1\n${parent_line}\n`
        const { C: mung_C, errors: mung_dec_errors } = H.decode_wh_lines(mung_snap)
        const child_count    = (mung_C?.o({ Emperor: 1 }) ?? []).length
        const decode_refused = mung_dec_errors.length > 0 && child_count === 0
 
        record('mung_cycle', mung_excluded && mung_marker && decode_refused, {
            mung_excluded:  mung_excluded  ? 1 : 0,
            mung_marker:    mung_marker    ? 1 : 0,
            decode_refused: decode_refused ? 1 : 0,
        })
    }
 
    // ── 7. ref_inline ────────────────────────────────────────────────────
    // Object refs in sc → objecties.ref in the snap line.
    // These are not fatal errors — refs are excluded from diff comparisons.
    // Refs in .sc are bugs (they belong in .c); the ref path is how they
    // surface loudly enough to be noticed without aborting unrelated saves.
    {
        const n_ref = _C({ Senate: 1, term: 'annual', live_ref: { cannot: 'encode' } })
        const q_ref: any = { d: 0 }
        const ref_lines = H.enLine(n_ref, q_ref) ?? []
 
        const ref_line    = ref_lines[0] ?? ''
        const has_ref_obj = ref_line.includes('"ref"')
        const no_mung_err = !(q_ref.mung?.length)
        const has_senate  = ref_line.includes('Senate')
 
        record('ref_inline', has_ref_obj && no_mung_err && has_senate, {
            has_ref_obj: has_ref_obj ? 1 : 0,
            no_mung_err: no_mung_err ? 1 : 0,
            has_senate:  has_senate  ? 1 : 0,
        })
    }
 
    // ── 8. dupe_impossible ───────────────────────────────────────────────
    // Two particles with identical sc shapes are distinct _C() objects —
    // the seen-set dupe guard in Travel compares object identity, not sc content,
    // so identical-sc siblings never collide.  i() also deduplicates by identity
    // so the guard is not reachable through the normal tree-building API; it is
    // internal safety for unusual sharing scenarios.
    {
        const rootC = _C({ DupeTest: 1 })
        rootC.i(_C({ Battle: 'Zama', year: -202, victor: 'Scipio' }))
        rootC.i(_C({ Battle: 'Zama', year: -202, victor: 'Scipio' }))  // same sc, distinct objects
 
        const { snap, errors: dupe_errors } = await H.encode_wh_lines(rootC)
        const { C: dupe_dec } = H.decode_wh_lines(snap)
        const battle_count = (dupe_dec?.o({ Battle: 'Zama' }) ?? []).length
 
        record('dupe_impossible', !dupe_errors.length && battle_count === 2, {
            enc_errors:    dupe_errors.length,
            battles_found: battle_count,
        })
    }
 
    // ── 9. decode_errors ─────────────────────────────────────────────────
    {
        const { C: c_empty, errors: e_empty } = H.decode_wh_lines('')
        const empty_ok = !c_empty && e_empty[0] === 'empty snap'
 
        const { C: c_2root, errors: e_2root } = H.decode_wh_lines('Root:first\nRoot:second\n')
        const second_root_ok = !!c_2root && e_2root.some(e => e.startsWith('second depth-0 root'))
 
        const { C: c_jump, errors: e_jump } = H.decode_wh_lines('Root:1\n    Orphan:1\n')
        const depth_jump_ok = !!c_jump && e_jump.some(e => e.startsWith('depth jump'))
 
        const bq_no_body_snap = 'Root:1\n  Child:1 name:test\n   source: |\n  Sibling:1\n'
        const { C: c_bq, errors: e_bq } = H.decode_wh_lines(bq_no_body_snap)
        const bq_no_body_ok  = e_bq.some(e => e.includes('no body lines'))
        const sibling_decoded = !!(c_bq?.o({ Sibling: 1 })[0])
 
        record('decode_errors', empty_ok && second_root_ok && depth_jump_ok && bq_no_body_ok, {
            empty:       empty_ok       ? 1 : 0,
            second_root: second_root_ok ? 1 : 0,
            depth_jump:  depth_jump_ok  ? 1 : 0,
            bq_no_body:  bq_no_body_ok  ? 1 : 0,
            sibling_ok:  sibling_decoded ? 1 : 0,
        })
    }
 
    // ── 10. lematch ───────────────────────────────────────────────────────
    {
        const augustus = _C({ Emperor: 1, name: 'Augustus', dynasty: 'JulioClaudian', reign_years: 41 })
        const senate   = _C({ Senate: 1, members: 300 })
 
        const r_has = augustus.lematch([{
            matching_any: [{ sc_has: { Emperor: 1 } }],
            means: { munging: [{ these_sc: { reign_years: 1 }, type: 'lifespan' }] },
        }])
        const lm_has = r_has.munging.length === 1 && !r_has.skip
 
        const r_value = augustus.lematch([{
            matching_any: [{ sc_has: { Emperor: 1, name: 'Trajan' } }],
            means: { skip: true },
        }])
        const lm_value_no_match = !r_value.skip
 
        const r_exact = senate.lematch([{
            matching_any: [{ sc_only: { Senate: 1, members: 300 } }],
            means: { skip: true },
        }])
        const lm_only_exact = r_exact.skip
 
        const r_inexact = senate.lematch([{
            matching_any: [{ sc_only: { Senate: 1 } }],
            means: { skip: true },
        }])
        const lm_only_inexact = !r_inexact.skip
 
        const r_thence = augustus.lematch([{
            matching_any: [{ sc_has: { Emperor: 1 } }],
            means: { thence_matching: [
                { matching_any: [{ sc_has: { Consul: 1 } }], means: { skip: true } },
            ]},
        }])
        const lm_thence = r_thence.thence.length === 1
 
        const consul_rule = { matching_any: [{ sc_has: { Consul: 1 } }], means: { skip: true } }
        const r_dedup = augustus.lematch([
            { matching_any: [{ sc_has: { Emperor: 1 } }], means: { thence_matching: [consul_rule] } },
            { matching_any: [{ sc_has: { Emperor: 1 } }], means: { thence_matching: [consul_rule] } },
        ])
        const lm_dedup = r_dedup.thence.length === 1
 
        const all_lm = lm_has && lm_value_no_match && lm_only_exact && lm_only_inexact
            && lm_thence && lm_dedup
 
        const lm = w.i({ lematch_test: 1, ok: all_lm ? 1 : 0 })
        lm.i({ lm_sc_has_munging:    lm_has             ? 1 : 0 })
        lm.i({ lm_sc_has_no_match:   lm_value_no_match  ? 1 : 0 })
        lm.i({ lm_sc_only_exact:     lm_only_exact      ? 1 : 0 })
        lm.i({ lm_sc_only_inexact:   lm_only_inexact    ? 1 : 0 })
        lm.i({ lm_thence_propagates: lm_thence          ? 1 : 0 })
        lm.i({ lm_thence_dedup:      lm_dedup           ? 1 : 0 })
    }
 
    w.i({ see: '📜 TextInca done' })
},

//#endregion





























































//#region StuffResolving


 
    async StuffResolving(A: TheC, w: TheC) {
        const H   = this as House
        const log = w.oai({ log: 1 }) as TheC

        let it = w.i({item:1})

        let n = it.i({blah:1})
        n.i({first:1})
        it.i({blah:1}).i({second:1})
        it.i({etc:1})

        await it.replace({}, async () => {
            it.i({blah:1})
            it.i(n)
            it.i({etc:1})
        }, { pairs_fn: async (a, b) => {
            let isn = (a) => a == n ? "n = " : ""
            log.i({
                msg:"resolved pair",
                before: a ? isn(a)+depeel(a.sc) : '-',
                after: b ? isn(b)+depeel(b.sc) : '-',
            })
        }})

        n.sc.bang = 1

 
    },
 




//#endregion




//#region StuffFlipping


    Run_A_StuffFlipping(this: House) {
        for (const [Aname, wname] of [
            ['StuffFlipping',  'StuffFlipping' ],
        ] as [string, string][]) {
            const A = this.o({ A: Aname })[0] || this.i({ A: Aname })
            if (!A.o({ w: wname }).length) A.i({ w: wname })
        }
        console.log(`🤹 ${this.name} StuffFlipping wired`)
    },


    async StuffFlipping(A, w) {
        // < find more problems by fuzzing lots of Lang->Cyto,
        //    then serialise the graph directly from cytoscape, do a Cyto_wipe,
        //     repeat serialise and compare - missing edges should show up...












        


        let o = w.i({test:"C.resolve() unambiguity in the past and future"})
        let lh = o.oai({ hand: 'left'  })
        let temporary = lh.resolve 
        try {
            let it
            await lh.replace({bug:1}, async () => {
                it = lh.i({bug:1,the_w:"Ying"})
            })
            it.i({terpestra:1})

            // lh.resolve = this.DEV_resolve
            await lh.replace({bug:1}, async () => {
                lh.i({bug:1,shelf:1,est:171717171717})
                lh.i({bug:1,shelf:1})
                lh.i({bug:1,the_w:"Ying"})
            })
        }
        finally {
            lh.resolve = temporary
        }

















        // from here down is studying the same resolve() bug
        //  fixed in daf49c838fc30c7525a7bc2b315789fade0c45b1
        //     C.resolve() rejects longtail of pairings via UNAMBIGUITY_THRESHOLD




        o = w.i({ test: "C.resolve() leaf test suite" })

        const resolve_test = async (label, pattern_sc, first_strs, then_strs,DEV) => {
            const t = o.i({ resolve_test: label })
            const C = t.i({ C: 1 })
            first_strs.map(s => C.i({ ...pattern_sc, ...peel(s) }))
            const pairs = t.i({ pairs: 1 })
            if (DEV) C.coms = t.i({resolve_coms:1})
            // if (DEV) C.resolve = this.DEV_resolve
            await C.replace(pattern_sc, async () => {
                then_strs.map(s => C.i({ ...pattern_sc, ...peel(s) }))
            }, { pairs_fn: async (a, b) => {
                pairs.i({before: a ? keyser(a.sc) : '-'})
                pairs.i({after: b ? keyser(b.sc) : '-' })
            }})
        }

        await resolve_test('leaf vanishes, self,est arrives',
            { tracing: 1 },
            [ 'hand:left', 'hand:right', 'whatsit', 'other:3', 'leaf', 'self,round:5,age:5' ],
            [ 'self,est:1775527585', 'hand:left', 'hand:right', 'whatsit', 'other:3', 'self,round:6,age:5' ],
            true
        )
        await resolve_test('leaf vanishes, self,est arrives - no tracing noise',
            {},
            [ 'hand:left', 'hand:right', 'whatsit', 'other:3', 'leaf', 'self,round:5,age:5' ],
            [ 'self,est:1775527585', 'hand:left', 'hand:right', 'whatsit', 'other:3', 'self,round:6,age:5' ]
        )

        await resolve_test('leaf moves into hand (depth change irrelevant at C level)',
            { tracing: 1 },
            [ 'hand:left', 'hand:right', 'leaf' ],
            [ 'hand:left', 'hand:right' ]
            // leaf gone — no match expected
        )

        await resolve_test('everything stable',
            { tracing: 1 },
            [ 'hand:left', 'hand:right', 'leaf' ],
            [ 'hand:left', 'hand:right', 'leaf' ]
        )

        await resolve_test('one key changes value',
            { tracing: 1 },
            [ 'hand:left', 'hand:right', 'other:3' ],
            [ 'hand:left', 'hand:right', 'other:4' ]
        )

        await resolve_test('pattern_sc empty — no tracing key noise',
            {},
            [ 'hand:left', 'hand:right', 'leaf', 'self,round:6,age:5' ],
            [ 'self,est:1775527585', 'hand:left', 'hand:right', 'self,round:6,age:5' ]
        )







        o = w.i({test:"C.resolve() bug about leaf"})
        // < needs reproducing outside of LeafJuggle step 6.
        //    this does show the bug but it needs whittling down
        // resolve() itself doesn't show the bug, it's something in thefu()
        //    

        let thefu = async (l,s) => {
            const topC = await this.cyto_scan(w, s)
            await this.cyto_assign_ids(w, topC)
            await this.cyto_scan_refs(w, topC)
            await this.cyto_assign_ids(w, topC)
            await this.cyto_resolve_refs(w, topC)
 

            const wave = await this.make_wave(w, topC, true)
            o.i({ see:1,CytoStep: 1, through:l }).i(wave)
        }
        
        
        const p = { tracing_run: 1 }
        // First pass: Inflate the space with all 6 items
        let laleaf
        await o.replace(p, async () => {
            o.i({ ...p, ohyea: 1, the_hand: "left" })
            o.i({ ...p, ohyea: 1, the_hand: "right" })
                .i({excellent:1})
            o.i({ ...p, ohyea: 1, the_whatsit: 1 })
                .i({excellent:1})
            o.i({ ...p, ohyea: 1, the_other: 3 })
            laleaf = o.i({ ...p, ohyea: 1, the_leaf: 1 })
        })

        await thefu('001 see',o)

        // Second pass: the_leaf goes missing
        let captured_goners = []
        lh = null
        let rh = null
        await o.replace(p, async () => {
            lh = o.i({ ...p, ohyea: 1, the_hand: "left" })
            rh = o.i({ ...p, ohyea: 1, the_hand: "right" })
            o.i({ ...p, ohyea: 1, the_whatsit: 1 })
            o.i({ ...p, ohyea: 1, the_other: 3 })
            // Omitted: the_leaf: 1
        }, {
            // Hook into your resolve() pairs where b is null
            gone_fn: (gone_atom) => {
                captured_goners.push(gone_atom)
                // o.i({see:"Goner detected:"}).i(gone_atom)
            }
        })
        // add to these after replace (we obscure that as trace time)
        //  to avoid this error: Stuff.svelte.ts:592 C.replace() resolved n have /*
        lh.i(laleaf)
        rh.i({tangiuy:1})
        if (captured_goners.length != 1 || !captured_goners[0].sc.the_leaf) o.i({heck:1})

        // we now get a %migrate for o/the_leaf -> o/the_hand/the_leaf
        await thefu('002 see goner, leaf into left',o)

        lh.empty()
        rh.empty()
        rh.i(laleaf)


        // < should %migrate it. Book:LeafJuggle was doing these sideways moves. why?
        await thefu('003 leaf moves left->right',o)














        // benign. doesn't really explain or expose anything.
        //  this T%goners and Se_some_Migration() thing is novel.
        //  ugly data except: Migration,n:wanderer,from_depth,to_depth:2
        o = w.i({ test: "Selection: leaf moves from root/* to root/container/*" })

        const root = _C({ root_node: 1 })
        const leaf = root.i({ leaf: 1, name: 'wanderer' })

        let Se = new Selection()

        const run = async (label) => {
            Se.sc.topD = await Se.r({ Se_test: 1 })
            await Se.process({
                n:          root,
                process_D:  Se.sc.topD,
                match_sc:   {},
                trace_sc:   { t: 1 },

                each_fn: async (D, n, T) => {
                    D.sc.depth = T.c.path.length - 1
                    D.sc.label = Object.keys(n.sc).filter(k => typeof n.sc[k] !== 'object').join(',')
                },

                trace_fn: async (uD, n) => uD.i({ t: 1,
                    ...Object.fromEntries(
                        Object.entries(n.sc)
                            .filter(([,v]) => typeof v === 'string' || typeof v === 'number')
                            .map(([k,v]) => [`the_${k}`, v])
                    )
                }),

                traced_fn: async (D, bD) => {
                    let c = sex({ Traced:1, see: label},D.sc,'label,depth')
                    if (bD) c.resolved = 1
                    o.i(c)
                },

                resolved_fn: async (T, N, goners, neus) => {
                    if (goners.length) T.sc.goners = goners
                    o.i({ Reso:1, see: label, at: T.sc.n?.sc.name ?? 'root',
                        goners: goners.length, neus: neus.length })
                },
            })
            let mo = o.i({moves:label})
            await this.Se_some_Migration(mo,Se)
        }

        await run('pass1')
        // expect: leaf at depth 1, neu:true
        const box = root.i({ container: 1, name: 'box' })
        await run('pass1.1')

        // move leaf: no longer direct child of root
        await root.replace({ leaf: 1 }, async () => {
            // leaf gone from root level
        })
        box.i(leaf)   // same C object, now at depth 2

        await run('pass2')



















        // < GONER? it doesn't reproduce the problem.
        // ── resolve() Leg-split: the_from vs the_to tie ──────────────────────
        // Regression for the scan_id mismatch seen in LakeTiles step 3→4.
        //
        // When one Leg(from:6, to:10) splits into Leg(6–8) + Leg(9–10),
        // both halves score unambiguity 1.0 against the old node:
        //   new Leg(6–8)  via the_from:6  → 1.0
        //   new Leg(9–10) via the_to:10   → 1.0
        // The correct match is old → new Leg(6–8) because `from` is the
        // stable left-anchor of a span when content splits rightward.
        {
            let o = w.i({ test: "resolve() Leg-split: from-anchor vs to-anchor tie" })
            let fails = 0
            const assert = (label, ok) => {
                if (ok) o.i({ ok: label })
                else  { o.i({ fail: label }); fails++ }
            }
 
            // test 1: split on the right — the_to changes, the_from survives
            // old: Leg(1–5) Leg(6–10)
            // new: Leg(1–5) Leg(6–8) Leg(9–10)   ← 6–10 split at 8|9
            {
                const parent = _C({})
                await parent.replace({ tracing: 1 }, async () => {
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 1, the_to: 5  })
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 6, the_to: 10 })
                })
                const pairs = []
                await parent.replace({ tracing: 1 }, async () => {
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 1, the_to: 5  })
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 6, the_to: 8  })
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 9, the_to: 10 })
                }, { pairs_fn: async (a, b) => pairs.push([a, b]) })
 
                const match = pairs.find(([a]) => a?.sc.the_from === 6 && a?.sc.the_to === 10)
                assert("split-right: old Leg(6–10) paired (not dropped)",
                    !!match && match[1] != null)
                assert("split-right: old Leg(6–10) → new Leg(6–8) via from-anchor",
                    match?.[1]?.sc.the_from === 6 && match?.[1]?.sc.the_to === 8)
                assert("split-right: new Leg(9–10) is unfound (null a-side)",
                    pairs.some(([a, b]) => a == null && b?.sc.the_from === 9))
            }
 
            // test 2: split on the left — the_from changes, the_to survives
            // old: Leg(6–10)
            // new: Leg(6–7) Leg(8–10)   ← still prefer from-anchor
            {
                const parent = _C({})
                await parent.replace({ tracing: 1 }, async () => {
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 1, the_to: 5  })
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 6, the_to: 10 })
                })
                const pairs = []
                await parent.replace({ tracing: 1 }, async () => {
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 1, the_to: 5  })
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 6, the_to: 7  })
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 8, the_to: 10 })
                }, { pairs_fn: async (a, b) => pairs.push([a, b]) })
 
                const match = pairs.find(([a]) => a?.sc.the_from === 6 && a?.sc.the_to === 10)
                assert("split-left: old Leg(6–10) → new Leg(6–7) via from-anchor",
                    match?.[1]?.sc.the_from === 6 && match?.[1]?.sc.the_to === 7)
            }
 
            // test 3: sanity — plain range-narrow (no split) still resolves
            // old: Leg(6–10)
            // new: Leg(6–9)   ← to shrinks, nothing ambiguous
            {
                const parent = _C({})
                await parent.replace({ tracing: 1 }, async () => {
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 6, the_to: 10 })
                })
                const pairs = []
                await parent.replace({ tracing: 1 }, async () => {
                    parent.i({ tracing: 1, the_node: 'Leg', the_from: 6, the_to: 9 })
                }, { pairs_fn: async (a, b) => pairs.push([a, b]) })
 
                assert("range-narrow: still resolves (not dropped)",
                    pairs.some(([a, b]) => a?.sc.the_from === 6 && b?.sc.the_from === 6))
            }
 
            if (!fails) o.i({ all_ok: 1 })
        }


    },

    async Se_some_Migration(o,Se) {
        // collect what we learned
        const goner_ns = new Map()
        const neu_ns   = new Map()

        await Se.c.T.forward(async T => {
            const bD = T.sc.bD
            const D  = T.sc.D
            if (bD && !D) {
                throw "impossible - goners must be noticed missing from somewhere still there"
            }
            if (D && !bD) {
                // neu
                const n = D.c.T?.sc.n
                if (n) { o.i({n_neu: keyser(n.sc)}); neu_ns.set(n, D) }
            }
        })
        await Se.c.T.forward(async T => {
            for (const gD of (T.sc.goners ?? [])) {
                const n = gD.c.T?.sc.n
                if (n) { o.i({n_gone: keyser(n.sc)}); goner_ns.set(n, gD) }
            }
        })

        for (const [n, gD] of goner_ns) {
            if (neu_ns.has(n)) {
                o.i({ Migration: 1, n: n.sc.name ?? '?',
                    from_depth: gD.sc.depth,
                    to_depth:   neu_ns.get(n).sc.depth })
            }
        }

    },



















































//#endregion
//#region LeafJuggle
    // this one's a simple animation roundabout of the same leaf
    //  *w/*hand/leaf
    // without elvis, it gets put on the w/* when it changes w
    //  which you don't usually see because they pick up the leaf
    //  except when it moves w:Yang->w:Yin, when w:Yin has already run this time
    //   and so Story comes and snaps the state when it is w:Yin/leaf
    //   see oddity:leaf not it hand
    // < use elvis, which will add more beliefs(), etc


    Run_A_LeafJuggle(this: House) {
        for (const [Aname, wname] of [
            ['Yin',  'Yin' ],
            ['Yang', 'Yang'],
        ] as [string, string][]) {
            const A = this.o({ A: Aname })[0] || this.i({ A: Aname })
            if (!A.o({ w: wname }).length) A.i({ w: wname })
        }
        console.log(`🤹 ${this.name} LeafJuggle wired`)
    },
    async Yin(A, w) {
        const yang_w = this.o({ A: 'Yang' })[0]?.o({ w: 'Yang' })[0]
        if (!yang_w) return
 
        await this.Yaing(w, yang_w)

        if (!w.oa({whatsit:1})) {
            let thing = w.i({whatsit:1}).i({thing:'with'})
            thing.sc.see = 1
            w.i({other:3}).i(thing)
        }

        // seed: place a fresh leaf if nobody in the whole RunH is holding one
        if (!A.sc.began) {
            A.sc.began = 1
            w.oai({ hand: 'left' })
                .i({ leaf: 1 })
                    // .i({marble:1})
        }
    },
 
    async Yang(A, w) {
        const yin_w = this.o({ A: 'Yin' })[0]?.o({ w: 'Yin' })[0]
        if (!yin_w) return
 
        await this.Yaing(w, yin_w)
    },



    async Yaing(w: TheC, other_w: TheC) {
        const lh = w.oai({ hand: 'left'  })
        const rh = w.oai({ hand: 'right' })
        
        let check = (leaf) => {
            w.c.firstleaf ||= leaf
            if (w.c.firstleaf != leaf) throw `many leaf`
        }
 
        // rh exits first — passes the leaf to other/*
        for (let leaf of rh.o({ leaf: 1 })) {
            await rh.r({ leaf: 1 }, {})        // evict from rh (keep C alive)
            check(leaf)
            check(other_w.i(leaf))   // place same C object
        }
 
        // lh passes to rh
        for (let leaf of lh.o({ leaf: 1 })) {
            await lh.r({ leaf: 1 }, {})
            check(leaf)
            check(rh.i(leaf))
        }

        // 
        // so we see a leaf in the left hand placed by the second w:* to occur
        for (let leaf of w.o({ leaf: 1 })) {
            await w.r({ leaf: 1 }, {})
            check(leaf)
            check(w.oai({ hand: 'left' }).i(leaf))
        }
    },













//#endregion
//#region LeafFarm


    // LeafFarm ghost — wired as Run_A_LeafFarm in Story.svelte.
    //
    // Three workers: farm, plate, enzymeco.
    //
    // ── cross-worker transfers ────────────────────────────────────────────────
    //
    //   All transfers are direct .i() calls into the target worker's C.
    //   Since all workers run inside the same RunH beliefs mutex, the particle
    //   is always somewhere visible — no gap tick where it's in flight but
    //   invisible to the snap.
    //
    //     leaf harvest:  farm drops the leaf → same tick, plate.i({leaf:1,...})
    //     protein:       farm builds a guard particle, places it into plate directly
    //     enzyme:        enzymeco batch completes → plate.i({shelf:1,enzyme:1,...})
    //     enzyme request: plate sets %wants_to_produce directly on enzymeco
    //
    //   plate_w() / enzymeco_w() helpers find sibling workers on RunH.
    //
    // ── plate's permanent sun ─────────────────────────────────────────────────
    //
    //   plate carries a {sunshine:1, dose:1} particle that is created once
    //   and never changed.  It does nothing computationally — it exists purely
    //   so Cyto always has something to anchor the plate compound when leaves,
    //   mouthfuls, and proteins are all absent.  dose:1 renders as a stable
    //   mid-sized diamond in Cytui.  Cyto gives it the id "sun:plate" (vs
    //   farm's oscillating "sun:farm") so they never collide.


    Run_A_LeafFarm(this: House) {
        for (const [Aname, wname] of [
            ['farm',     'farm'],
            ['plate',    'plate'],
            ['enzymeco', 'enzymeco'],
        ] as [string, string][]) {
            const A = this.o({ A: Aname })[0] || this.i({ A: Aname })
            if (!A.o({ w: wname }).length) A.i({ w: wname })
        }
        console.log(`🌿 ${this.name} LeafFarm wired`)
    },

//#region helpers

    // plate_w / enzymeco_w: find the sibling plate or enzymeco worker particle.
    // Returns null if not yet materialised (should be immediate after do_A).
    plate_w(): any | null {
        return this.o({ A: 'plate' })[0]?.o({ w: 'plate' })[0] ?? null
    },
    enzymeco_w(): any | null {
        return this.o({ A: 'enzymeco' })[0]?.o({ w: 'enzymeco' })[0] ?? null
    },

//#endregion
//#region farm

    // The farm grows individual %leaf particles from sunshine and poo.
    // Each leaf has a .dose (float) representing its biomass content.
    // Leaves grow each tick; max growth is 22% of current dose per tick.
    // When a leaf reaches dose >= 2.0 it is dropped from farm and placed
    // directly into plate within the same beliefs tick — no gap.
    // New leaves sprout when sunny_streak >= 2, capped at 3 total leaves.
    // A seed leaf (dose 1.86) is planted on tick 1 so a harvest appears early.
    async farm(A, w) {
        let tick = w.o1({ round: 1, self: 1 })[0] ?? 0

        // ── %sunshine:1 ───────────────────────────────────────────────
        let sun_dose = Math.sin(tick * 0.3) * 0.5 + 0.6   // 0.1 .. 1.1
        let sun = w.o({ sunshine: 1 })[0]
        if (!sun) sun = w.i({ sunshine: 1, dose: 0 })
        sun.sc.dose = sun_dose

        // track consecutive sunny rounds for sprouting
        let streak = w.o({ sunny_streak: 1 })[0]
        if (!streak) streak = w.i({ sunny_streak: 1, count: 0 })
        streak.sc.count = sun_dose > 0.6 ? streak.sc.count + 1 : 0

        // ── %poo:1 ────────────────────────────────────────────────────
        let poo = w.o({ poo: 1 })[0]
        if (!poo) poo = w.i({ poo: 1, dose: 0 })
        poo.sc.dose = Math.min(poo.sc.dose + 0.4, 8)

        // ── $life_input: shared growth budget ─────────────────────────
        let life_input = sun_dose * Math.min(poo.sc.dose, 4)
        poo.sc.dose *= 0.85

        // ── grow existing %leaf particles ─────────────────────────────
        let leaves = w.o({ leaf: 1 })
        let total_leaf_dose = leaves.reduce((s, l) => s + l.sc.dose, 0) || 1
        let absorbed = 0
        for (let leaf of leaves) {
            let share = life_input * (leaf.sc.dose / total_leaf_dose)
            let max_growth = leaf.sc.dose * 0.22
            let growth = Math.min(share, max_growth)
            leaf.sc.dose += growth
            absorbed += growth
        }

        // ── sprouting: spare life_input → new %leaf particles ─────────
        // One small sprout per tick, capped at 3 leaves total.
        if (streak.sc.count >= 2 && w.o({ leaf: 1 }).length < 3) {
            let spare = Math.max(life_input - absorbed, 0)
            let sprout_budget = 0.10
            let sprout_i = 0
            while (spare > 0.1 && sprout_budget > 0) {
                let dose = Math.min(0.1, spare, sprout_budget)
                let id = `leaf_${tick}_${sprout_i++}`
                w.i({ leaf: 1, leaf_id: id, dose })
                spare        -= dose
                sprout_budget -= dose
            }
        }

        // ── harvest ripe leaves → place directly into plate ───────────
        // Drops the leaf from farm and i()s it into plate within the same
        // beliefs tick so there is no gap in the snap output.
        let plate = this.plate_w()
        for (let leaf of w.o({ leaf: 1 })) {
            if (leaf.sc.dose >= 2.0) {
                const { leaf_id } = leaf.sc
                await w.r({ leaf: 1, leaf_id }, {})
                leaf.sc.tick = tick
                if (plate) plate.i(leaf)
            }
        }

        // ── complex protein (every ~7 ticks) ──────────────────────────
        // A guard particle on farm prevents double-spawning; it is dropped
        // immediately after placing the protein into plate.
        if (tick > 0 && tick % 7 === 0) {
            let protein_id = `prot_${tick}`
            if (!w.o({ protein: 1, protein_id }).length) {
                let complexity = 2 + this.prandle(4)
                w.i({ protein: 1, protein_id, complexity })
                let plate = this.plate_w()
                if (plate) plate.i({ protein: 1, protein_id, complexity })
                w.drop(w.o({ protein: 1, protein_id })[0])
            }
        }

        // ── seed leaf on tick 1: near-ripe so it harvests on tick 2 ───
        if (tick === 1 && !w.o({ leaf: 1, leaf_id: 'seed_0' }).length) {
            w.i({ leaf: 1, leaf_id: 'seed_0', dose: 1.86 })
        }

        streak.sc.count == 10 && w.i({ seen: 'wonder' })
    },

//#endregion
//#region plate

    // plate receives harvested %leaf particles directly from farm (no elvis gap).
    // Leaves are consumed in random 0.25–0.35 bites per tick.
    // Each bite spawns a %mouthful (ttl:1, spawning_from:leaf_id) that converts
    // to basic material on expiry.  Cyto uses spawning_from to teleport the
    // mouthful node to the leaf's position then animate it outward.
    //
    // Proteins are broken down using shelf enzymes.  When the shelf is empty,
    // plate sets %wants_to_produce directly on enzymeco rather than elvisng.
    async plate(A, w) {

        // ── permanent decorative sun ──────────────────────────────────
        // Created once, never changed.  Gives the plate compound a stable
        // anchor node so it's never empty, and reads nicely in Cytui as a
        // fixed mid-sized diamond (dose:1 → sz≈44px in cyto_node).
        if (!w.o({ sunshine: 1 }).length) {
            w.i({ sunshine: 1, dose: 1 })
        }

        // ── consume plate leaves in bites → %mouthful particles ───────
        // Bite size is lightly randomised via tick+leaf_id arithmetic (no
        // Math.random so the snap is deterministic).
        let tick = w.o1({ round: 1, self: 1 })[0] ?? 0
        for (let leaf of w.o({ leaf: 1 })) {
            let jitter = ((tick * 13 + leaf.sc.leaf_id.length * 7) % 10) * 0.01
            let bite   = Math.min(leaf.sc.dose, 0.25 + jitter)
            leaf.sc.dose -= bite
            let mouthful_id = `${leaf.sc.leaf_id}_m${tick}`
            w.i({ mouthful: 1, mouthful_id, dose: bite, spawning_from: leaf.sc.leaf_id, ttl: 1 })
            if (leaf.sc.dose <= 0.04) w.drop(leaf)
        }

        // ── expire mouthfuls after one tick → basic material ──────────
        for (let m of w.o({ mouthful: 1 })) {
            if (m.sc.ttl <= 0) {
                let basic = w.o({ material: 'basic' })[0]
                if (!basic) basic = w.i({ material: 'basic', amount: 0 })
                basic.sc.amount += m.sc.dose
                w.drop(m)
            } else {
                m.sc.ttl -= 1
            }
        }

        // ── break down proteins using shelf enzymes ───────────────────
        for (let prot of w.o({ protein: 1 })) {
            let first_enzyme = w.o({ shelf: 1, enzyme: 1 })[0]
            if (!first_enzyme) {
                // request restock: set flag directly on enzymeco, no elvis round-trip
                let eco = this.enzymeco_w()
                if (eco && !eco.oa({ wants_to_produce: 1 })) {
                    eco.i({ wants_to_produce: 1 })
                    if (!w.oa({ wants_enzyme: 1 })) w.i({ wants_enzyme: 1 })
                }
                break
            }
            let cost = Math.min(prot.sc.complexity, first_enzyme.sc.units)
            first_enzyme.sc.units -= cost
            prot.sc.complexity    -= cost
            if (first_enzyme.sc.units <= 0) {
                w.drop(first_enzyme)
                await w.r({ wants_enzyme: 1 }, {})
            }
            if (prot.sc.complexity <= 0) {
                let basic = w.o({ material: 'basic' })[0]
                if (!basic) basic = w.i({ material: 'basic', amount: 0 })
                basic.sc.amount += 2
                w.drop(prot)
            }
        }

        // ── basic material consumed by life ───────────────────────────
        let basic = w.o({ material: 'basic' })[0]
        if (basic) {
            let vanish = Math.min(basic.sc.amount * 0.25, 1.5)
            basic.sc.amount = Math.max(basic.sc.amount - vanish, 0)
        }
    },

//#endregion
//#region enzymeco

    // enzymeco produces enzyme particles in a %producing batch.
    // Production is triggered by plate setting %wants_to_produce directly
    // on this worker.  When the batch completes, the enzyme is placed
    // directly into plate's shelf — no elvis gap.
    async enzymeco(A, w) {

        // ── check for restock request from plate ──────────────────────
        if (w.oa({ wants_to_produce: 1 }) && !w.oa({ producing: 1 })) {
            let prod = w.i({ producing: 1, ticks_left: 3 })
            prod.i({ enzyme: 1, units: 5 })
            await w.r({ wants_to_produce: 1 }, {})
        }

        // ── tick down production ──────────────────────────────────────
        let prod = w.o({ producing: 1 })[0]
        if (prod) {
            prod.sc.ticks_left -= 1
            if (prod.sc.ticks_left <= 0) {
                let enzyme = prod.o({ enzyme: 1 })[0]
                let plate = this.plate_w()
                if (plate) plate.i({ shelf: 1, enzyme: 1, units: enzyme.sc.units })
                w.drop(prod)
            }
        }
    },

//#endregion
//#region do_A

    async do_A() {
        for (let [Aname, wname] of [['farm','farm'], ['plate','plate'], ['enzymeco','enzymeco']]) {
            let A = this.o({ A: Aname })[0] || this.i({ A: Aname })
            if (!A.o({ w: wname }).length) A.i({ w: wname })
        }
    },

//#endregion

    })
    })
</script>
<MachPeerily {M} />
<MachReactivity {M} />
<MachReqy {M} />
<Mundane {M} />
<Understandity {M} />
<Understandium {M} />
<Understandication {M} />
<TextLinestests {M} />

<Diffmatication {M} />