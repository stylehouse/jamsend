<script lang="ts">
    import { _C, keyser, objectify, TheC, TheX } from "$lib/data/Stuff.svelte";
    import { Selection } from "$lib/mostly/Selection.svelte";
    import { register_class, WormholeNav, type House } from "$lib/O/Housing.svelte";
    import { Peerily, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts";
    import { armap, depeel, Idento, nex, peel, sex } from "$lib/Y.svelte";
    import { onMount } from "svelte";
    import MachPeerily from "../MachPeerily.svelte";
    import MachReactivity from "./MachReactivity.svelte";

    let {M} = $props()

    onMount(async () => {
    await M.eatfunc({


















//#endregion
//#region LangTiles

    // LangTiles ghost — a second test-case game with its own Cyto instance.
    //
    // ── eithery commissioning ───────────────────────────────────────────────
    //
    //   H:Story commissions its Cyto with Scannable=H (everything), giving the
    //   low-frequency overview wave.  H:LangTiles commissions its own Cyto
    //   with Scannable=w.c.model — a permanent TheC it owns — for a tighter,
    //   higher-detail wave of just the Lang viewable model.
    //
    //   Both Cytos share the same Styles bucket: Story's The/Styles.  We reach
    //   across via top_House().Awo('Story','Story').c.The and call The_Styles.
    //   Any matstyle edit from either Cytui writes to the same place and both
    //   graphs restyle.  Story's watch_c on stylesC handles save-on-change.
    //
    //   Client for LangTiles's Cyto is w:Lang itself, so Cyto_animation_done
    //   etc. route back here.  Story's Cyto still talks to w:Story.
    //


    // Called from Auto (same path Story uses) with Book=name of a LangTiles book.
    // Auto spawns H:LangTiles as a subHouse and calls Run_A_LangTiles on it.
    Run_A_LangTiles(this: House) {
        const H = this
        H.i({ A: 'Lies' }).i({ w: 'Lies' })
        H.i({ A: 'Lang' }).i({ w: 'Lang' })
        H.i({ A: 'Cyto'      }).i({ w: 'Cyto'      })
        H.i({ A: 'Pantheate' }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LangTiles wired`)
    },


//#endregion
//#region LakeSurfer


    Run_A_LakeSurfer(this: House) {
        const H = this
        H.i({ A: 'Lies' }).i({ w: 'Lies' })
        H.i({ A: 'Lang'       }).i({ w: 'Lang' })
        H.i({ A: 'Cyto'       }).i({ w: 'Cyto'      })
        H.i({ A: 'Pantheate'  }).i({ w: 'Pantheate' })
        console.log(`🟦 ${H.name} LakeSurfer wired`)
    },






//#endregion












































//#region TextInca
// TextInca — unit-test book for encode_wh_lines / decode_wh_lines / enLine / lematch.
//
// Historical particles drawn from antiquity give the codec a realistic spread
// of sc shapes: negative integers (founding dates), multi-word strings that
// stay in peel format, coloned strings that force JSON fallback, and multi-line
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
//   2. peel_vs_json        colon/comma in a value forces JSON for the whole line; safe values stay peel
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

    // record: one enc_test particle per case.
    // snap_output must end with \n so the story_matching rule can BQ it.
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
    // Colon in some label values forces JSON for those lines;
    // all others stay in peel format.  Visible in snap_output.
    {
        const roman: any = {
            sc: { Empire: 'Roman', founded: -753, fell: 476, capital: 'Rome' },
            children: [
                { sc: { Emperor: 1, name: 'Augustus',  reign_start: -27,  reign_end: 14  } },
                { sc: { Emperor: 1, name: 'Trajan',    reign_start: 98,   reign_end: 117, note: 'Optimus' } },
                { sc: { Emperor: 1, name: 'Hadrian',   reign_start: 117,  reign_end: 138 } },
                { sc: { Event: 1,   year: 79,  label: 'Vesuvius' } },
                // colon in label → this line encodes as JSON
                { sc: { Event: 1,   year: 476, label: 'Romulus Augustulus deposed: end of Western Empire' } },
            ],
        }
        const mongol: any = {
            sc: { Empire: 'Mongol', founded: 1206, fell: 1368, capital: 'Karakorum' },
            children: [
                { sc: { Emperor: 1, name: 'GenghisKhan', reign_start: 1206, reign_end: 1227 } },
                { sc: { Emperor: 1, name: 'KublaiKhan',  reign_start: 1260, reign_end: 1294 } },
                // colon again
                { sc: { Event: 1, year: 1258, label: 'Sack of Baghdad: House of Wisdom destroyed' } },
            ],
        }

        const { snap, errors: enc_errors } = await H.encode_wh_lines({ Civilization: 1 }, [roman, mongol])
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
            empires:        empires.length,
            roman_emperors: roman_emp.length,
            mongol_emperors: mongol_emp.length,
            enc_errors:     enc_errors.length,
            dec_errors:     dec_errors.length,
        }, snap)
    }

    // ── 2. peel_vs_json ───────────────────────────────────────────────────
    // encode_stringies: /[:,\t\n]/ in any key or value → JSON for the whole line.
    // Only Hastings is safe (all values alphanum or numeric).
    {
        const items = [
            { sc: { Battle: 'Thermopylae', year: -480, desc: 'Leonidas: 300 Spartans vs Xerxes' } },
            { sc: { Battle: 'Marathon',    year: -490, desc: 'Athenians, Plataeans vs Persians'  } },
            { sc: { Battle: 'Hastings',    year: 1066, victor: 'Norman' } },
        ]

        const { snap, errors } = await H.encode_wh_lines({ BattleLog: 1 }, items)
        const lines = snap.split('\n').filter(Boolean)
        // lines[0] = 'BattleLog:1', lines[1..3] = the battles
        const thermo_json = lines[1]?.trimStart().startsWith('{')
        const mara_json   = lines[2]?.trimStart().startsWith('{')
        const hast_peel   = lines[3]?.trimStart().startsWith('Battle:Hastings')

        record('peel_vs_json', !errors.length && !!thermo_json && !!mara_json && !!hast_peel, {
            thermo_json: thermo_json ? 1 : 0,
            mara_json:   mara_json   ? 1 : 0,
            hast_peel:   hast_peel   ? 1 : 0,
            enc_errors:  errors.length,
        }, snap)
    }

    // ── 3 + 4. bq_encode and bq_roundtrip ────────────────────────────────
    // enLine with blockquote_these_sc:{source:1} on an Output particle.
    // encode_wh_lines has no rules path, so BQ must go through enLine directly.
    //
    //   Parent line: Output:1 name:Cannae.txt dige:abc123   (no source here)
    //    source: |                                           (3 spaces = 2*d+1, d=1)
    //      Hannibal Barca crossed the Alps...               (5 spaces = 2*d+3)
    //      ...
    //
    // Decode then strips body_min=5 leading spaces per body line
    // and reassembles with join('\n') + '\n'.
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
        // the snap_output above is the enLine output itself — block-scalar lines
        // visible inside the enc_test entry in Story's snap

        // round-trip: wrap in a root so decode_wh_lines sees a valid tree
        const full_snap = `BQ_wrap:1\n` + lines.join('\n') + '\n'
        const { C: bq_decoded, errors: bq_errors } = H.decode_wh_lines(full_snap)
        const bq_child    = bq_decoded?.o({ Output: 1 })[0] as TheC | undefined
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
        const bq_errors    = q.bq_errors ?? []
        // source fell back to inline — the first line should contain it
        const source_inline = lines[0]?.includes('source')

        record('bq_no_newline', bq_errors.length > 0 && !!source_inline, {
            bq_error_count: bq_errors.length,
            source_inline:  source_inline ? 1 : 0,
        })
    }

    // ── 6. mung_cycle ────────────────────────────────────────────────────
    // enLine with a munging rule excludes the munged key and sets objecties.mung.
    // decode_wh_lines sees objecties.mung on a loaded line → error, line skipped.
    // This makes a mung-encoded line un-loadable, which is the intent:
    //   mung = "this key was deliberately suppressed, not just missing".
    {
        const n_nero = _C({ Emperor: 1, name: 'Nero', reign_end: 68, volatile_ts: 1712345678 })
        const mung_rules = [{
            matching_any: [{ sc_has: { Emperor: 1 } }],
            means: { munging: [{ these_sc: { volatile_ts: 1 }, type: 'timestamp' }] },
        }]
        const q_enc: any = { d: 1, rules: mung_rules }
        const enc_lines = H.enLine(n_nero, q_enc) ?? []

        const parent_line     = enc_lines[0] ?? ''
        const mung_excluded   = !parent_line.includes('volatile_ts')
        const mung_marker     = parent_line.includes('"mung"')

        // feed the mung-marked line into decode_wh_lines — it must refuse it
        const mung_snap = `MungRoot:1\n${parent_line}\n`
        const { C: mung_C, errors: mung_dec_errors } = H.decode_wh_lines(mung_snap)
        const child_count  = (mung_C?.o({ Emperor: 1 }) ?? []).length
        // the mung line is skipped: the root C exists but has no Emperor child
        const decode_refused = mung_dec_errors.length > 0 && child_count === 0

        record('mung_cycle', mung_excluded && mung_marker && decode_refused, {
            mung_excluded:  mung_excluded  ? 1 : 0,
            mung_marker:    mung_marker    ? 1 : 0,
            decode_refused: decode_refused ? 1 : 0,
        })
    }

    // ── 7. ref_inline ────────────────────────────────────────────────────
    // Object refs in sc → objecties.ref in the snap line (no error from enLine).
    // encode_wh_lines does not call enLine with any rules, so the mung check
    // in its each_fn (q.objecties?.mung) never fires for object refs — only for
    // lematch-munged keys.  auto_save_library pre-strips objects before calling
    // encode_wh_lines precisely because of this: the ref ends up in the snap line
    // and is then excluded from diff comparisons, but it is not an error.
    {
        const n_ref = _C({ Senate: 1, term: 'annual', live_ref: { cannot: 'encode' } })
        const q_ref: any = { d: 0 }
        const ref_lines = H.enLine(n_ref, q_ref) ?? []

        const ref_line     = ref_lines[0] ?? ''
        const has_ref_obj  = ref_line.includes('"ref"')
        const no_mung_err  = !(q_ref.mung?.length)
        // Senate and term still appear in stringies (ref_obj excluded from inline)
        const has_senate   = ref_line.includes('Senate')

        record('ref_inline', has_ref_obj && no_mung_err && has_senate, {
            has_ref_obj: has_ref_obj ? 1 : 0,
            no_mung_err: no_mung_err ? 1 : 0,
            has_senate:  has_senate  ? 1 : 0,
        })
    }

    // ── 8. dupe_impossible ───────────────────────────────────────────────
    // encode_wh_lines calls _C({...sc}) at each node — two items with identical
    // sc shapes produce two distinct TheC objects.  The seen-set dupe guard in
    // its Travel each_fn can therefore never fire through the normal API.
    // The guard exists for internal safety if build_into ever reuses objects.
    {
        const items = [
            { sc: { Battle: 'Zama', year: -202, victor: 'Scipio' } },
            { sc: { Battle: 'Zama', year: -202, victor: 'Scipio' } },  // same sc, fresh _C each time
        ]
        const { snap, errors: dupe_errors } = await H.encode_wh_lines({ DupeTest: 1 }, items)
        const { C: dupe_dec } = H.decode_wh_lines(snap)
        const battle_count = (dupe_dec?.o({ Battle: 'Zama' }) ?? []).length

        record('dupe_impossible', !dupe_errors.length && battle_count === 2, {
            enc_errors:    dupe_errors.length,
            battles_found: battle_count,
        })
    }

    // ── 9. decode_errors ─────────────────────────────────────────────────
    // Four distinct error paths in decode_wh_lines.
    {
        // 9a. empty snap
        const { C: c_empty, errors: e_empty } = H.decode_wh_lines('')
        const empty_ok = !c_empty && e_empty[0] === 'empty snap'

        // 9b. second depth-0 root
        const { C: c_2root, errors: e_2root } = H.decode_wh_lines('Root:first\nRoot:second\n')
        const second_root_ok = !!c_2root && e_2root.some(e => e.startsWith('second depth-0 root'))

        // 9c. depth jump (depth 0 → 2, parent at depth 1 absent)
        // 4 spaces = depth 2; prev_d is 0 after the root line → jump > 1 → error, line skipped
        const { C: c_jump, errors: e_jump } = H.decode_wh_lines('Root:1\n    Orphan:1\n')
        const depth_jump_ok = !!c_jump && e_jump.some(e => e.startsWith('depth jump'))

        // 9d. BQ key with no body
        // Child at depth 1 (2 spaces); bq_sp = 1*2+1 = 3 spaces; body_min = 5 spaces.
        // '   source: |' (3 sp) is parsed as a BQ key; '  Sibling:1' (2 sp < 5) breaks
        // body collection immediately → body_lines empty → error.
        const bq_no_body_snap = 'Root:1\n  Child:1 name:test\n   source: |\n  Sibling:1\n'
        const { C: c_bq, errors: e_bq } = H.decode_wh_lines(bq_no_body_snap)
        const bq_no_body_ok = e_bq.some(e => e.includes('no body lines'))
        // Sibling still lands correctly — only source key is absent from Child
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
    // All tests use historical particles as subjects.
    // lematch is a TheC method, not on H.
    {
        const augustus = _C({ Emperor: 1, name: 'Augustus', dynasty: 'JulioClaudian', reign_years: 41 })
        const senate   = _C({ Senate: 1, members: 300 })

        // sc_has wildcard: {Emperor:1} means "has key Emperor with any value"
        // — munging rule should attach
        const r_has = augustus.lematch([{
            matching_any: [{ sc_has: { Emperor: 1 } }],
            means: { munging: [{ these_sc: { reign_years: 1 }, type: 'lifespan' }] },
        }])
        const lm_has = r_has.munging.length === 1 && !r_has.skip

        // sc_has with a specific value that augustus does NOT have — no match
        const r_value = augustus.lematch([{
            matching_any: [{ sc_has: { Emperor: 1, name: 'Trajan' } }],
            means: { skip: true },
        }])
        const lm_value_no_match = !r_value.skip

        // sc_only exact: senate.sc has exactly {Senate:1, members:300}
        const r_exact = senate.lematch([{
            matching_any: [{ sc_only: { Senate: 1, members: 300 } }],
            means: { skip: true },
        }])
        const lm_only_exact = r_exact.skip

        // sc_only inexact: senate has 2 keys, rule specifies only 1 → no match
        const r_inexact = senate.lematch([{
            matching_any: [{ sc_only: { Senate: 1 } }],
            means: { skip: true },
        }])
        const lm_only_inexact = !r_inexact.skip

        // thence_matching propagates child rules via the returned .thence array
        const r_thence = augustus.lematch([{
            matching_any: [{ sc_has: { Emperor: 1 } }],
            means: { thence_matching: [
                { matching_any: [{ sc_has: { Consul: 1 } }], means: { skip: true } },
            ]},
        }])
        const lm_thence = r_thence.thence.length === 1

        // thence dedup: same rule object appearing in two rules → collected once
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

//#region PotPlaner

    // Exercises the %scheme/%lematch → concretion pipeline with a mock class.
    //
    // MockSprout stands in for Peering/Pier — no real async I/O, just a
    //   setTimeout that fires like Pier_init_completo does in the PeeringLive shim.
    //   started=true → inst_started() resolves immediately after constructor.
    //
    // w/Sprout,name:'seedling'           — particle; triggers concretion
    //   .c.inst = MockSprout             — set by apply_scheme after post_do resolves
    //
    // post_fn closure (captured H, n):
    //   setTimeout 2000 → reqyscile(req:tend, {see:'sprouted',ready:1})
    //   demand_time_to_think(2000) holds Story open for the gap
    //
    // De:tend
    //   req:tend                         — waits for c.inst, then for req%ready
    //     re-entry via e_reqysciliation: ready set → finish


    async PotPlaner(A: TheC, w: TheC) {
        // %scheme:Sprout — one lematch pattern for {Sprout:1} particles.
        //   args_fn: pulls name from n.sc; passes plain opt to constructor.
        //   post_fn: shim-style — arms one setTimeout per inst, lazily finds req
        //            inside the callback (req seeded before timeout fires).
        if (!w.oa({ scheme: 'Sprout' })) {
            // MockSprout — stable reference here so register_class always gets the same ctor.
            //   started=true: inst_started() skips the microtask spin.
            //   < wake() absent: apply_scheme's 'wake' in inst check is also skipped.
            class MockSprout {
                name: string
                started = true
                constructor(opt: { name: string }) { this.name = opt.name }
            }
            register_class('Sprout', MockSprout as any)
            const sp = w.i({ scheme: 'Sprout' })
            sp.i({
                lematch: 1, sc_has: { Sprout: 1 }, class: 'Sprout',
                args_fn: (n: TheC, opt: any) => [{ name: (n.sc.name ?? opt.name) as string }],
                post_fn: (inst: MockSprout, n: TheC, _H: House) => {
                    // demand_time_to_think: holds Story open while we wait.
                    //   mirrors _PeeringLive_shim's Peering_i_Pier call.
                    // _H.demand_time_to_think(123)
                    setTimeout(() => {
                        // req:tend will exist by now — seeded in PotPlaner() before concretion
                        const De  = w.o({ De: 'tend' })[0] as TheC | undefined
                        const req = De?.o({ req: 'tend' })[0] as TheC | undefined
                        console.log(`🌱 MockSprout(${inst.name}) ready — reqyscile: ${req ? 'found' : 'MISSING'}`)
                        if (req) void _H.reqyscile(req, { see: 'sprouted', ready: 1 })
                    }, 123)
                },
            })
        }





        // necessary to get it to notice needing concretion this step
        //  someone has to go back into beliefs() from the top
        if (w.oa({self:1,round:'1'})) this.feebly_ponder()



        // seed the Sprout particle — organise() picks it up, concretion fires next pass.
        //   oai: idempotent; safe to call every think tick.
        w.oai({ Sprout: 1, name: 'seedling' })

        // show concretion status each tick
        const sprout_n = w.o({ Sprout: 1 })[0] as TheC | undefined
        if (sprout_n) {
            const inst = sprout_n.c.inst as { name: string } | undefined
            w.i({ see: inst
                ? `Sprout(${inst.name}) concretised → ${inst.constructor.name}`
                : `Sprout(${sprout_n.sc.name as string}) awaiting concretion…`
            })
        }

        w.c.rq ||= this.reqys(w, 'De')
        const dq = w.c.rq

        // ── De:tend ───────────────────────────────────────────────────────────
        dq.doai({ De: 'tend' })?.(async (De: TheC, dq) => {
            // reqyscile climbs req.c.host=De → De.c.host=w to reach %w
            De.c.host = w
            De.c.rq ||= this.reqys(De, 'req')
            const rq = De.c.rq

            // req:tend
            //   phase 1: stall until concretion lands c.inst on the Sprout particle
            //   phase 2 (re-entry via reqyscile): ready is set → finish
            rq.doai({ req: 'tend' })?.(async (req: TheC, rq: any) => {
                const sn = w.o({ Sprout: 1 })[0] as TheC | undefined
                if (!sn?.c.inst) { req.i({ waits: 'concretion' }); return }
                if (!req.sc.ready) { req.i({ waits: 'sprouted' }); return }
                const inst = sn.c.inst as { name: string }
                w.i({ see: `🌱 ${inst.name} ready (ready:${req.sc.ready as number})` })
                rq.finish(req)
            })

            await rq.do()
            if (rq.all_done() && !De.sc.finished) dq.finish(De)
        })

        await dq.do()
    },

//#endregion

//#region PotPlan

    // w/plan                            — world
    //
    // De:sort
    //   req:wait,time:5000              — stalls; do_fn arms a one-shot timer
    //     setTimeout → reqyscile(req,{see:'sorted out',thing:3})
    //       merges thing:3 into req.sc, elvisses to e_reqysciliation
    //     do_fn re-entry: thing set → rq.finish(req)
    //
    // demand_time_to_think is manual here — may move into the wall


    async PotPlan(A, w) {
        w.c.rq ||= this.reqys(w, 'De')
        const dq = w.c.rq

        // ── De:sort ───────────────────────────────────────────────────────────
        dq.doai({ De: 'sort' })?.(async (De: TheC, dq) => {
            this.trace("De:sort")
            // reqyscile climbs req.c.host=De → De.c.host=w to reach %w
            De.c.host = w
            De.c.rq ||= this.reqys(De, 'req')
            const rq = De.c.rq

            // req:wait,time:5000
            //   armed guard: one timer only; reqyscile brings re-entry
            //   re-entry: thing set → finish; demand_time_to_think holds story open
            rq.doai({ req: 'wait', time: 123 })?.(async (req: TheC, rq: any) => {
                if (req.sc.thing) {
                    this.trace("De:sort -> finito")
                    this.want_savepoint()
                    rq.finish(req); return
                }
                if (req.c.armed) return
                req.c.armed = true
                // this.demand_time_to_think(req.sc.time + 20)
                setTimeout(() => {
                    this.trace("De:sort -> reqyscile")
                    this.reqyscile(req, { see: 'sorted out', thing: 3 })
                }, req.sc.time)
            })

            await rq.do()
            if (rq.all_done() && !De.sc.finished) dq.finish(De)
        })
        dq.doai({ De: 'yay', maz:2 })?.(async (De: TheC, dq) => {
            this.trace("De:yay")
            w.i({confetti:"!!!"})
            dq.finish(De); return
        })

        await dq.do()
    },

//#endregion


//#region PotPlanet

    // Fiction: a standing order desk receives two orders (rose:3, fern:7 doses).
    //   Mid-flight, rose is bumped to 5 — the delta of 2 spawns a rogue order
    //   that arrived sideways into De:receive, not through the orders pipeline.
    //
    // w/orders/order:rose,dose:3         — source; driver mutates dose here
    //          order:fern,dose:7           orders loop flows changes → reqs via oai(c,sc)
    // w/world/order:*,dose:N             — committed record; written by confirm
    //
    // De:receive
    //   req:order:rose,dose               — permanent-state reqs (no do_fn); transparent
    //   req:order:fern,dose                 to do(). oai(c,sc) propagates source changes →
    //                                       hakd → %mutated → rq.mutated_fn → order_update
    //   req:order:rose_extra,dose:2       — rogue; seeded inside order_update; has do_fn
    //   req:confirm                       — staged by driver; De:receive completion signal
    //
    // De:report,maz:2                    — De-level %waits; do_fn fallback via q.do_fn
    //   req:summarise                       all_done() → inline finish

    Run_A_PotPlanet(this: House) {
        const A = this.o({ A: 'PotPlanet' })[0] || this.i({ A: 'PotPlanet' })
        if (!A.o({ w: 'PotPlanet' }).length) {
            const w  = A.i({ w: 'PotPlanet' })
            const os = w.oai({ orders: 1 })
            os.oai({ order: 'rose', dose: 3 })
            os.oai({ order: 'fern', dose: 7 })
        }
        console.log(`🪐 ${this.name} PotPlanet wired`)
    },

    async PotPlanet(A, w) {
        this.logger(w)
        const li = this.c.loggeri

        // ── test driver ───────────────────────────────────────────────────────
        // step 3: mutate source order in w/orders — orders loop propagates to req
        //           via two-arg oai(c,sc); hakd sees dose 3→5 → %mutated → rq.mutated_fn
        // step 4: arm confirm → De:receive closes; De:report opens
        await this.on_step({
            3: async () => {
                li('driver[3]', { order: 'rose', dose: 5 })
                w.oai({ orders: 1 }).oai({ order: 'rose' }).sc.dose = 5
            },
            4: async () => {
                li('driver[4]', { staged: 1 })
                const dReceive = w.o({ De: 'receive' })[0] as TheC | undefined
                if (!dReceive) return
                const rConf = this.reqys(dReceive, 'req')
                                  .o({ req: 'confirm' })[0] as TheC | undefined
                if (rConf) rConf.sc.staged = true
            },
        })

        // ── business logic ────────────────────────────────────────────────────
        w.c.rq ||= this.reqys(w, 'De')
        const dq = w.c.rq

        // ── De:receive ────────────────────────────────────────────────────────
        dq.doai({ De: 'receive' })?.(async (De: TheC, dq) => {
            De.c.rq ||= this.reqys(De, 'req')
            const rq = De.c.rq

            // order_update — rq.mutated_fn; fires for any req carrying %mutated
            //   req.sc.mutated.dose is the pre-merge value; gap = delta only
            //   rogue seeded directly into rq — not from w/orders pipeline
            rq.mutated_fn = async (req: TheC, rq: any) => {
                const old_dose = req.sc.mutated?.dose as number || 0
                const new_dose = req.sc.dose as number || 0
                const gap      = new_dose - old_dose
                if (gap <= 0) return
                const rogue = rq.oai(
                    { req: 'order', order: `${req.sc.order as string}_extra` },
                    { dose: gap }
                )
                rogue.c.do_fn ||= async (req: TheC, rq: any) => {
                    li('rogue_done', { order: req.sc.order as string, dose: req.sc.dose as number || 0 })
                    rq.finish(req)
                }
                li('extra_order', { order: req.sc.order as string, gap })
            }

            // flow w/orders into permanent-state reqs via two-arg oai:
            //   c = identity (order name only); sc = data (dose)
            //   same particle found each tick; hakd detects source changes → %mutated
            for (const order of w.oai({ orders: 1 }).o({ order: 1 }) as TheC[]) {
                rq.oai(
                    { req: 'order', order: order.sc.order },
                    { dose: order.sc.dose as number || 0 }
                )
            }

            // req:confirm — staged by driver at step 4; commits all orders to world
            //   De:receive completion signal (order reqs are permanent state, never finish)
            rq.doai({ req: 'confirm' })?.(async (req: TheC, rq: any) => {
                if (!req.sc.staged) { req.i({ waits: 'staged' }); return }
                const world = w.oai({ world: 1 })
                for (const or of rq.o({ req: 'order' }) as TheC[]) {
                    world.oai({ order: or.sc.order }).sc.dose = or.sc.dose as number || 0
                }
                li('confirmed')
                rq.finish(req)
            })

            await rq.do()
            const conf = rq.o({ req: 'confirm' })[0] as TheC | undefined
            if (conf?.sc.finished && !De.sc.finished) dq.finish(De)
        })

        // ── De:report,maz:2 ──────────────────────────────────────────────────
        dq.doai({ De: 'report', maz: 2 })?.(async (De: TheC, dq) => {
            const dReceive = w.o({ De: 'receive' })[0] as TheC | undefined
            if (!dReceive?.sc.finished) {
                De.i({ waits: 'receive' })
                return
            }

            De.c.rq ||= this.reqys(De, 'req')
            const rq = De.c.rq

            // q.do_fn: fallback for any req with no c.do_fn — carries req:summarise
            rq.do_fn ||= async (req: TheC, rq: any) => {
                const world = w.oai({ world: 1 })
                const total = (world.o({ order: 1 }) as TheC[])
                    .reduce((s, o) => s + (o.sc.dose as number || 0), 0)
                li('report_final', { total })
                w.i({ see: `📋 world total: ${total} doses` })
                rq.finish(req)
            }

            rq.oai({ req: 'summarise' })

            await rq.do()
            if (rq.all_done() && !De.sc.finished) dq.finish(De)
        })

        await dq.do()
    },

//#endregion




//#region PotPlant

    // w/body,hands:2                    — capacity = hands - body.o({pot:1}).length
    // w/shelf/*pot/plant|soil,dose:3    — starting positions
    // w/yard/*pot/plant|soil,dose:5     — after repotting
    // w/yard/soil,dose:12               — bulk supply; 2 doses per pot (3→5)
    // w/arrival                         — blocks move_outside until step:1 snap
    //
    // De:repot
    //   req:move_outside       — shelf→body→yard; body pots on entry = last step's load
    //   req:repot,maz:2        — draw 2 from yard/soil per pot, dose:3→5
    //   req:move_inside,maz:3  — yard→body→shelf; same transit pattern
    // De:celebrate,maz:2

    Run_A_PotPlant(this: House) {
        const A = this.o({ A: 'PotPlant' })[0] || this.i({ A: 'PotPlant' })
        if (!A.o({ w: 'PotPlant' }).length) {
            const w  = A.i({ w: 'PotPlant' })
            w.i({ body: 1, hands: 2 })
            w.i({ arrival: 1 })   // dropped by Runstepped after step:1 snap

            const sh = w.oai({ shelf: 1 })
            for (const name of ['rose', 'fern', 'cactus']) {
                const pot = sh.oai({ pot: name })
                pot.i({ plant: 1 })
                pot.i({ soil: 1, dose: 3 })
            }
            w.oai({ yard: 1 }).i({ soil: 1, dose: 12 })   // 3 pots × 2 doses each

            // drop arrival after step:1 snap — feebly_ponder is no-op here (runtime=false),
            //   so PotPlant() doesn't run until step:2's do_step
            this.Runstepped(async () => { await w.r({ arrival: 1 }, {}) })
        }
        console.log(`🪴 ${this.name} PotPlant wired`)
    },

    async PotPlant(A, w) {
        const shelf = w.oai({ shelf: 1 })
        const yard  = w.oai({ yard:  1 })
        const body  = w.oai({ body:  1 })

        w.c.rq ||= this.reqys(w, 'De')
        const dq = w.c.rq
        dq.subreqys('req')

        // ── De:repot ──────────────────────────────────────────────────────────
        dq.doai({ De: 'repot' })?.(async (De: TheC, dq) => {
            De.c.rq ||= this.reqys(De, 'req')
            const rq = De.c.rq

            // req:move_outside
            //   body pots on entry = loaded last step and snapped → safe to unload now
            //   is_there_yet: set by Runstepped callback (runtime=false, so no spurious wake)
            rq.doai({ req: 'move_outside' })?.(async (req, rq) => {
                if (w.o({ arrival: 1 }).length) { req.i({ waits: 'arrival' }); return }

                if (body.c.is_there_yet) {
                    body.c.is_there_yet = false
                    for (const pot of body.o({ pot: 1 }) as TheC[]) {
                        await body.r({ pot: pot.sc.pot }, {})
                        yard.i(pot)
                        w.oai({ log: 1 }).i({ msg: `${pot.sc.pot} in yard` })
                    }
                }

                const capacity = (body.sc.hands as number) - body.o({ pot: 1 }).length

                if (!shelf.o({ pot: 1 }).length && !body.o({ pot: 1 }).length) {
                    rq.finish(req)
                    return
                }

                for (const pot of (shelf.o({ pot: 1 }) as TheC[]).slice(0, capacity)) {
                    await shelf.r({ pot: pot.sc.pot }, {})
                    body.i(pot)
                    w.oai({ log: 1 }).i({ msg: `carrying ${pot.sc.pot}` })
                }

                if (body.o({ pot: 1 }).length) {
                    // snap body/pot:* before transit completes
                    this.Runstepped(async () => {
                        body.c.is_there_yet = true
                        this.feebly_ponder()
                    })
                }
            })

            // req:repot,maz:2 — doai style; draws 2 doses per pot from yard supply
            rq.doai({ req: 'repot', maz: 2 })?.(async (req, rq) => {
                const ysoil = yard.o({ soil: 1 })[0]
                if (!ysoil) return
                for (const pot of yard.o({ pot: 1 }) as TheC[]) {
                    if ((ysoil.sc.dose as number) < 2) { req.i({ waits: 'soil' }); return }
                    ysoil.sc.dose = (ysoil.sc.dose as number) - 2
                    const psoil = pot.o({ soil: 1 })[0]
                    if (psoil) psoil.sc.dose = (psoil.sc.dose as number) + 2   // 3→5
                    w.oai({ log: 1 }).i({ msg: `repotted ${pot.sc.pot} (yard soil: ${ysoil.sc.dose})` })
                }
                rq.finish(req)
            })

            // req:move_inside,maz:3 — mirror of move_outside
            rq.doai({ req: 'move_inside', maz: 3 })?.(async (req, rq) => {
                if (body.c.is_there_yet) {
                    body.c.is_there_yet = false
                    for (const pot of body.o({ pot: 1 }) as TheC[]) {
                        await body.r({ pot: pot.sc.pot }, {})
                        shelf.i(pot)
                        w.oai({ log: 1 }).i({ msg: `${pot.sc.pot} back on shelf` })
                    }
                }

                const capacity = (body.sc.hands as number) - body.o({ pot: 1 }).length

                if (!yard.o({ pot: 1 }).length && !body.o({ pot: 1 }).length) {
                    rq.finish(req)
                    return
                }

                for (const pot of (yard.o({ pot: 1 }) as TheC[]).slice(0, capacity)) {
                    await yard.r({ pot: pot.sc.pot }, {})
                    body.i(pot)
                }

                if (body.o({ pot: 1 }).length) {
                    this.Runstepped(async () => {
                        body.c.is_there_yet = true
                        this.feebly_ponder()
                    })
                }
            })

            await rq.do()
            if (rq.all_done() && !De.sc.finished) dq.finish(De)
        })

        // ── De:celebrate,maz:2 ────────────────────────────────────────────────
        dq.doai({ De: 'celebrate' }, { maz: 2 })?.(async (De: TheC, dq) => {
            De.c.rq ||= this.reqys(De, 'req')
            const rq = De.c.rq

            rq.doai({ req: 'confetti' })?.(async (req, rq) => {
                w.i({ thus: '🎉 all repotted and shelved!' })
                rq.finish(req)
            })

            await rq.do()
            if (rq.all_done() && !De.sc.finished) dq.finish(De)
        })

        await dq.do()
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
        // Regression for the scan_id mismatch seen in LangTiles step 3→4.
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