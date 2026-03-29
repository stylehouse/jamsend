<script lang="ts">
    // Cyto.svelte — ghost.
    //
    // ── Dip protocol ─────────────────────────────────────────────────────────
    //
    //   Dip_assign(scheme, D) — only D; parent via D.c.T.up.sc.D.
    //   Dip particles persist in D/** across ticks via resume_X.
    //   No resetting — existing children keep their values; new children
    //   claim the next slot from the parent's Dip.sc.i counter.
    //   Result written to T.sc.Dip_scanid (or _cytoid) for easy lookup.
    //   T.sc.Dip_scanid_is_new = true when the Dip was freshly created
    //
    // ── Passes ───────────────────────────────────────────────────────────────
    //
    //   cyto_scan       Se1  n=RunH   → D** mirrors n**; scan_id on C; C.c.Se1_D=D
    //                                   goners → Se1.c.scan_goners_by_id
    //
    //   cyto_assign_ids Se2  n=topC   → cytoid Dip on all nodes in C**
    //                   (1st call, nodes only)
    //
    //   cyto_scan_refs            → blue edges added to C** (uses cyto_ids for endpoints,
    //                               gD.c.T.sc.Dip_scanid for goner from-ids)
    //
    //   cyto_assign_ids Se2  n=topC   → cytoid Dip on new edges too
    //                   (2nd call — existing nodes keep ids, new edges get fresh)
    //
    //   cyto_resolve_refs        → forward(): parent/source/target C refs → _id strings
    //                              clear C.c.Se1_D
    //
    //   make_wave       Ze   n=topC   → diffs C** vs bD** → wave

    import { TheC, _C, objectify }  from "$lib/data/Stuff.svelte"
    import { Selection } from "$lib/mostly/Selection.svelte"
    import type { TheD, Travel } from "$lib/mostly/Selection.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount }   from "svelte"
    import Cytui         from "./ui/Cytui.svelte"
    import { indent } from "$lib/Y";

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region w:Cyto

    async Cyto(A: TheC, w: TheC) {
        if (!w.c.plan_done) this.Cyto_plan(w)
        const ok = await this.cyto_update_wave(w)
        if (!ok) return w.i({ see: '⏳ no H%Run/%run,done yet' })
        w.i({ see: `📊 tick:${w.c.gn?.sc.tick ?? 0}` })
    },

    Cyto_plan(w: TheC) {
        const uis = this.oai_enroll(this, { watched: 'UIs' })
        uis.oai({ UI: 'Cyto', component: Cytui })
        const wa  = this.oai_enroll(this, { watched: 'graph' })
        w.c.gn        = wa.oai({ cyto_graph: 1 })
        w.c.plan_done = true
        w.sc.grawave_duration ??= 2
    },

    async cyto_update_wave(w: TheC): Promise<boolean> {
        const H    = this as House
        const RunH = (H.o({ H: 1 }) as House[]).find(h => h.sc.Run) as House | undefined
        if (!RunH) return false

        const tracking = w.oai({ cyto_tracking: 1 })
        const v = RunH.version
        if (tracking.sc.v === v) return true
        tracking.sc.v = v

        const story_w = H.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0] as TheC | undefined
        const run     = story_w?.o({ run: 1 })[0] as TheC | undefined
        const step_n  = run?.sc.done as number | undefined
        // wait for step to happen. for take a photo of the stage? H/A/w
        if (!step_n) return false

        const topC = await this.cyto_scan(w, RunH)       // Se1: D** + C** + scan goners
        await this.cyto_assign_ids(w, topC)               // Se2 pass 1: cytoid on nodes
        await this.cyto_scan_refs(w, topC)                // add ref/migration edges to C**
        await this.cyto_assign_ids(w, topC)               // Se2 pass 2: cytoid on new edges
        await this.cyto_resolve_refs(w, topC)             // forward(): C refs → _id strings
        const wave = await this.make_wave(w, topC, true)  // Ze: diff → wave
        wave.step_n   = step_n


        await w.replace({ CytoStep: 1 }, async () => {
            w.i({ CytoStep: 1, step_n: step_n ?? null, C: topC })
        })

        const gn = w.c.gn as TheC
        if (!gn) throw "Nograph on update_wave" //return false
        gn.sc.wave = wave
        gn.sc.tick = ((gn.sc.tick as number) ?? 0) + 1
        gn.sc.topC = topC
        gn.bump_version()
        const wa = H.o({ watched: 'graph' })[0] as TheC
        wa?.bump_version()
        
        if (step_n != null && story_w) {
            const step_c = (story_w.c.This?.o({ Step: 1 }) as TheC[] | undefined)
                ?.find(s => s.sc.Step === step_n)
            if (step_c) { step_c.sc.CytoStep = topC; step_c.sc.CytoWave = wave }
        }
        let nostyle = this.snap_cytowave_str(wave).split("\n")
            .filter(l=>!l.match(/^ {4}/)).join("\n")
        console.log(`Your cyto update wave:\n`+nostyle,wave)

        await w.replace({ wave_data: 1 }, async () => {
            w.i({ wave_data: 1, nodes: wave.upsert.length,
                  edges: wave.edge_upsert.length, removing: wave.remove.length,
                  step_n: step_n ?? null })
        })
        return true
    },

    async cyto_seek(A: TheC, w: TheC, e: TheC) {
        const gn = w.c.gn as TheC
        if (!gn) return
        gn.sc.seek_step = e?.sc.seek_step ?? null
        gn.bump_version()
    },

//#endregion
//#region Dip_assign

    // Assign a branching hierarchical id to D under a named scheme.
    // Only D is passed — T reached via D.c.T, parent D via D.c.T.up.sc.D.
    //
    // Dip particles persist in D/** across Se replace() via resume_X.
    // Existing D: Dip already present → reuse value (no counter increment).
    // New D:      no Dip → claim parent's next slot (parent.Dip.sc.i++) → create Dip.
    //
    // Stores result on T.sc.Dip_${scheme} for easy later access.
    // Sets T.sc.Dip_${scheme}_is_new = true when freshly created (neu detection).

    Dip_assign(scheme: 'scanid' | 'cytoid', D: TheD): string {
        const T          = D.c.T as Travel
        const tsc_key    = `Dip_${scheme}` as const
        const tsc_is_new = `Dip_${scheme}_is_new` as const

        // already assigned this tick?
        const existing = D.o({ Dip: scheme })[0] as TheC | undefined
        if (existing) {
            T.sc[tsc_key]    = existing.sc.value
            T.sc[tsc_is_new] = false
            return existing.sc.value as string
        }

        // new — find/init parent's Dip and claim next slot
        let possible = T.c.path.slice().reverse().slice(1).map(T=>T.sc.D)
        let uDip
        for (let uD of possible) {
            uDip = uD.o({ Dip: scheme })[0]
            if (uDip) break
        }
        // starts from 1 either way:
        let i = uDip ? ++uDip.sc.i : 1
        const value = `${uDip?.sc.value ?? scheme}_${i}`
        D.i({ Dip: scheme, value, i: 0 })
        T.sc[tsc_key]    = value
        T.sc[tsc_is_new] = true
        return value
    },

//#endregion
//#region Se1 — cyto_scan

    async cyto_scan(w: TheC, RunH: House): Promise<TheC> {
        w.c.cyto_Se ??= new Selection()
        const Se: Selection = w.c.cyto_Se
        // replace topD every tick: fresh .c.T; D/** (Dip, n_ref) preserved via resume_X
        Se.sc.topD = await Se.r({ cyto_root: 1 })
        let has_Dip = Se.sc.topD.o({ Dip: 'scanid' })[0] ? "has" : 'neu'
                console.log(`cyto_scan()! ${has_Dip}`)
        const topC: TheC = _C({ cyto_root: 1 })
        Se.c.scan_goners_by_id = new Map<string, TheD>()

        await Se.process({
            n:          RunH,
            process_D:  Se.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                const cls = this.cytyle_classify(n)
                if (cls === 'skip')      { T.sc.not = 1; D.drop(D); return }
                if (cls === 'invisible') {
                    if (T == T.c.path[0]) {
                        // Dip must begin on the topD
                        const scan_id = this.Dip_assign('scanid', D)
                    }
                    T.sc.C = T.sc.up?.sc.C ?? topC
                    return
                }

                const scan_id = this.Dip_assign('scanid', D)

                const parentC: TheC = T.sc.up?.sc.C ?? topC
                const nd = this.cyto_nstyle(n)
                let spawny = T.sc.bD ? "---" : 'neu'
                console.log(`your ${spawny} scanid: ${scan_id}: ${[
                    ...T.c.path.map(T => T.sc.C?.sc.label || "("+objectify(T.sc.n)+")"),nd.label
                ].join(" \t ")}`)

                const C: TheC = parentC.i({
                    cyto_node:  1,
                    scan_id,
                    label:      nd.label,
                    isCompound: nd.isCompound ?? false,
                    // parent only when parentC is itself a cyto_node (not topC/cyto_root)
                    parent: parentC.sc.isCompound && parentC.sc.cyto_node ? parentC : null,
                    style:      nd.style,
                })
                C.c.Se1_D = D   // link to Se1 D for cyto_scan_refs
                T.sc.C = C
            },

            trace_fn: async (uD: TheD, n: TheC) => {
                const sc: any = { tracing: 1 }
                for (const [k, v] of Object.entries(n.sc ?? {})) {
                    if (typeof v !== 'object' && typeof v !== 'function') sc[`the_${k}`] = v
                }
                return uD.i(sc)
            },

            traced_fn: async () => {},

            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                for (const g of goners)
                    this.cyto_collect_goner_scan_ids(g, Se.c.scan_goners_by_id as Map<string,TheD>)
            },
        })
        
        return topC
    },

    cyto_collect_goner_scan_ids(D: TheD, by_id: Map<string, TheD>): void {
        const id = D.o({ Dip: 'scanid' })[0]?.sc.value as string | undefined
        if (id && !by_id.has(id)) by_id.set(id, D)
        for (const child of D.o({ tracing: 1 }) as TheD[])
            this.cyto_collect_goner_scan_ids(child, by_id)
    },

//#endregion
//#region Se2 — cyto_assign_ids (called twice)

    // Pass 1 (before cyto_scan_refs): walks C%cyto_node** — nodes get cytoid Dips.
    // Pass 2 (after  cyto_scan_refs): same walk — nodes keep ids; new edges get fresh ids.
    // Se2 topD is replaced each pair of calls (i.e., each cyto_update_wave tick) so .c.T
    // is fresh, but D/** (Dip particles) carry over giving stable ids to matching C nodes.

    async cyto_assign_ids(w: TheC, topC: TheC): Promise<void> {
        w.c.cyto_Se2 ??= new Selection()
        const Se2: Selection = w.c.cyto_Se2
        Se2.sc.topD = await Se2.r({ cyto_assigning: 1 })

        await Se2.process({
            n:          topC,
            process_D:  Se2.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, C: TheC, T: Travel) => {
                // if (C.sc.label == 'Yin') debugger
                if (C.sc.cyto_node) C.sc.cyto_id = this.Dip_assign('cytoid', D)
                else
                if (C.sc.cyto_edge) C.sc.edge_id  = this.Dip_assign('cytoid', D)
                else
                if (T == T.c.path[0]) this.Dip_assign('cytoid', D)


                let spawny = T.sc.bD ? "---" : 'neu'
                console.log(`thee ${spawny} scanid: ${C.sc.cyto_id||C.sc.edge_id}: ${[
                    ...T.c.path.slice().reverse().slice(1).reverse()
                    .map(T => T.sc.C?.sc.label || "("+objectify(T.sc.n)+")"),C.sc.label
                ].join(" \t ")}`)
            },

            trace_fn: async (uD: TheD, C: TheC) => {
                // trace on scan_id for nodes, source+target for edges
                if (C.sc.cyto_node) return uD.i({ tracing: 1, the_scan_id: C.sc.scan_id ?? '' })
                if (C.sc.cyto_edge) {
                    const src = typeof C.sc.source === 'object'
                        ? (C.sc.source as TheC).sc.scan_id ?? ''
                        : C.sc.source_id ?? ''
                    const tgt = typeof C.sc.target === 'object'
                        ? (C.sc.target as TheC).sc.scan_id ?? ''
                        : C.sc.target_id ?? ''
                    return uD.i({ tracing: 1, the_src: src, the_tgt: tgt })
                }
                return uD.i({ tracing: 1 })
            },

            traced_fn:   async () => {},
            resolved_fn: async () => {},
        })
    },

//#endregion
//#region cyto_scan_refs

    // Runs after Se2 pass 1 (nodes have cyto_ids) and before Se2 pass 2 (edges get ids).
    // Reads C.c.Se1_D for n refs (migration detection).
    // Adds cyto_edge children to C nodes (multi-placed) and topC (migration orphans).

    async cyto_scan_refs(w: TheC, topC: TheC): Promise<void> {
        const Se1          = w.c.cyto_Se as Selection
        const goners_by_id = Se1.c.scan_goners_by_id as Map<string, TheD>

        // build n → C[] map from current C%cyto_node**
        const n_to_Cs = new Map<TheC, TheC[]>()
        const walk = (C: TheC) => {
            for (const nc of C.o({ cyto_node: 1 }) as TheC[]) {
                const n = (nc.c.Se1_D as TheD | undefined)?.o({ n_ref: 1 })[0]?.sc.n as TheC | undefined
                if (n) { const a = n_to_Cs.get(n); if (a) a.push(nc); else n_to_Cs.set(n, [nc]) }
                walk(nc)
            }
        }
        walk(topC)

        // detect neu: T.sc.Dip_scanid_is_new was set by Dip_assign in Se1 each_fn
        const is_neu_scan_id = (scan_id: string): boolean => {
            // walk Se1.c.T to find if any T has this scan_id as a new Dip
            // shortcut: if goners_by_id has the scan_id → it's gone (not neu)
            // neu if it's NOT in goners and was T.sc.Dip_scanid_is_new
            // simplest: check if the D's Dip was assigned this tick = T.sc.Dip_scanid_is_new
            // We can't easily walk T** here, so instead: neu if scan_id not in goners_by_id
            // and scan_id is not in the PREVIOUS tick's ids.
            // Use Se1.c.T.forward to find the T with this scan_id — but that's heavy.
            // Practical: any node not in goners is either persistent or new.
            // Se1.c.neu_scan_ids is built cheaply:
            const neu = Se1.c.neu_scan_ids as Set<string> | undefined
            return neu?.has(scan_id) ?? false
        }

        const blue_sc = (src_id: string, tgt_id: string, directed: boolean, extra: any = {}) => ({
            cyto_edge: 1 as const, ref: 1 as const,
            source: null, target: null,   // C refs — null since source is gone or id-based
            source_id: src_id, target_id: tgt_id,
            style: {
                'line-color': '#4488ff', width: 1.2, 'line-style': 'dashed',
                'target-arrow-shape': directed ? 'triangle' : 'none',
                'target-arrow-color': '#4488ff', 'curve-style': 'bezier', opacity: 0.5,
            },
            ...extra,
        })

        // multi-placed: same n in >1 current C
        for (const [_n, Cs] of n_to_Cs) {
            if (Cs.length < 2) continue
            for (let i = 0; i < Cs.length - 1; i++)
                Cs[i].i(blue_sc(Cs[i].sc.cyto_id as string, Cs[i+1].sc.cyto_id as string, false))
        }

        // migration: goner whose n ref appears as a neu C
        for (const [_gid, gD] of goners_by_id) {
            const from_scan_id = gD.c.T?.sc.Dip_scanid as string | undefined
            if (!from_scan_id) continue
            const n = gD.c.T?.sc.n as TheC | undefined
            if (!n) continue
            const neu_Cs = (n_to_Cs.get(n) ?? []).filter(C => is_neu_scan_id(C.sc.scan_id as string))
            if (!neu_Cs.length) continue
            const to_C  = neu_Cs[0]
            const to_id = to_C.sc.cyto_id as string
            to_C.i({ cyto_migration: 1, from_scan_id, to_id })
            topC.i(blue_sc(from_scan_id, to_id, true, { orphan_source: 1 }))
        }

        // build neu_scan_ids set for is_neu_scan_id — do this here for completeness
        // (was missing from cyto_scan, added now on Se1.c)
        if (!Se1.c.neu_scan_ids) {
            const neu = new Set<string>()
            await Se1.c.T?.forward(async (T: Travel) => {
                if (T.sc.Dip_scanid_is_new) neu.add(T.sc.Dip_scanid as string)
            })
            Se1.c.neu_scan_ids = neu
        }
    },

//#endregion
//#region cyto_resolve_refs

    // Forward walk via Se2.c.T: convert parent/source/target C refs → _id strings.
    // Clears C.c.Se1_D links (keep C** low-memory after this point).

    async cyto_resolve_refs(w: TheC, topC: TheC): Promise<void> {
        const Se2 = w.c.cyto_Se2 as Selection
        if (!Se2?.c.T) return

        await Se2.c.T.forward(async (T: Travel) => {
            const C = T.sc.n as TheC; if (!C) return

            if (C.sc.cyto_node) {
                if (C.sc.parent && typeof C.sc.parent === 'object') {
                    C.sc.parent_id = (C.sc.parent as TheC).sc.cyto_id ?? null
                    delete C.sc.parent
                }
                delete C.c.Se1_D
            }

            if (C.sc.cyto_edge) {
                if (C.sc.source && typeof C.sc.source === 'object') {
                    C.sc.source_id = (C.sc.source as TheC).sc.cyto_id ?? null
                    delete C.sc.source
                }
                if (C.sc.target && typeof C.sc.target === 'object') {
                    C.sc.target_id = (C.sc.target as TheC).sc.cyto_id ?? null
                    delete C.sc.target
                }
            }
        })
    },

//#endregion
//#region Ze — make_wave

    async make_wave(w: TheC, topC: TheC, adjacent: boolean): Promise<any> {
        w.c.cyto_Ze ??= new Selection()
        const Ze: Selection = w.c.cyto_Ze
        Ze.sc.topD = await Ze.r({ cyto_root: 'Ze' })

        const UPSERT = false

        const upsert:      any[] = []
        const edge_upsert: any[] = []
        const remove:      string[] = []
        const edge_remove: string[] = []
        const migrate:     any[] = []

        let We = await w.r({Zeeeee:1})
        We.empty()
        We.i({C:1}).i(topC)
        We.i({D:1}).i(Ze.sc.topD)

        await Ze.process({
            n:          topC,
            process_D:  Ze.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, C: TheC, T: Travel) => {
                if (D.sc.cyto_root && C.sc.cyto_root) return
                if (!C.sc.cyto_node && !C.sc.cyto_edge) { T.sc.not = 1; return }
                D.sc.is_edge = !!C.sc.cyto_edge
            },

            trace_fn: async (uD: TheD, C: TheC) => {
                if (C.sc.cyto_edge) return uD.i({ tracing: 1, the_edge_id: C.sc.edge_id  ?? '' })
                if (C.sc.cyto_node) return uD.i({ tracing: 1, the_cyto_id: C.sc.cyto_id  ?? '' })
                return uD.i({ tracing: 1 })
            },

            traced_fn: async (D: TheD, bD: TheD | undefined, C: TheC) => {
                if (!C.sc.cyto_node && !C.sc.cyto_edge) return
                const snap_C = D.oai({ snapshot: 1 })

                if (C.sc.cyto_edge) {
                    const eid = C.sc.edge_id as string
                    if (!eid || C.sc.orphan_source) return
                    if (UPSERT || !bD) {
                        edge_upsert.push({ id: eid,
                            source: C.sc.source_id as string, target: C.sc.target_id as string,
                            style: C.sc.style ?? {},
                            data:  { ideal_length: (C.sc.ideal_length as number) ?? 80 } })
                    } else {
                        const old = JSON.parse(snap_C.sc.snap as string ?? '{}')
                        const nw  = C.sc.style as Record<string,any> ?? {}
                        const chg: any = {}; let has = false
                        for (const [k,v] of Object.entries(nw)) if (old[k]!==v) { chg[k]=v; has=true }
                        if (has) edge_upsert.push({ id: eid, style: chg })
                    }
                    snap_C.sc.snap = JSON.stringify(C.sc.style ?? {})

                } else {
                    const id = C.sc.cyto_id as string
                    if (UPSERT || !bD) {
                        upsert.push({ id, label: C.sc.label ?? '',
                            isCompound: C.sc.isCompound ?? false,
                            parent:     C.sc.parent_id  ?? undefined,
                            style:      C.sc.style ?? {} })
                    } else {
                        const old  = JSON.parse(snap_C.sc.snap as string ?? '{}')
                        const nw   = C.sc.style as Record<string,any> ?? {}
                        const chg: any = {}; let has = false
                        for (const [k,v] of Object.entries(nw)) if (old[k]!==v) { chg[k]=v; has=true }
                        const lc = C.sc.label     !== snap_C.sc.label
                        const pc = C.sc.parent_id !== snap_C.sc.parent
                        if (has || lc || pc) {
                            const nd: any = { id, style: chg }
                            if (lc) nd.label      = C.sc.label
                            if (pc) nd.new_parent = C.sc.parent_id ?? null
                            upsert.push(nd)
                        }
                        snap_C.sc.label  = C.sc.label
                        snap_C.sc.parent = C.sc.parent_id
                    }
                    snap_C.sc.snap = JSON.stringify(C.sc.style ?? {})
                }
            },

            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                for (const g of goners) {
                    if (g.sc.is_edge) { if (g.sc.the_edge_id)  edge_remove.push(g.sc.the_edge_id  as string) }
                    else              { if (g.sc.the_cyto_id)  remove.push(g.sc.the_cyto_id as string) }
                }
            },
        })

        if (adjacent) {
            const walk = (C: TheC) => {
                for (const mc of C.o({ cyto_migration: 1 }) as TheC[])
                    migrate.push({ id: mc.sc.from_scan_id, toward: mc.sc.to_id, then_parent: null })
                for (const nc of C.o({ cyto_node: 1 }) as TheC[]) walk(nc)
            }
            walk(topC)
        }

        return { upsert, edge_upsert, remove, edge_remove, migrate, constraints: null,
                 duration: adjacent ? ((w.sc.grawave_duration as number) ?? 0.3) : 0 }
    },

//#endregion
//#region cytyle_classify

    cytyle_classify(n: TheC): 'skip' | 'invisible' | 'compound' | null {
        const s = n.sc
        if (s.self || s.mo || s.chaFrom || s.wasLast || s.sunny_streak || s.seen
            || s.o_elvis || s.cyto_node || s.cyto_root || s.cyto_tracking
            || s.wave_data || s.refs || s.snap_node || s.snap_root
            || s.housed || s.run || s.Se || s.inst || s.began_wanting
            || s.CytoStep || s.CytoWave || s.tracing || s.Dip
            || s.snapshot || s.cyto_edge_root || s.cyto_z) return 'skip'
        if (s.H || s.A) return 'invisible'
        if (s.w) return 'compound'
        return null
    },

//#endregion
//#region cyto_label / hsl2rgb / cyto_node / cyto_w_style — from v1

    cyto_label(n: TheC): string {
        const parts: string[] = []
        for (const [k, v] of Object.entries(n.sc ?? {})) {
            if (typeof v === 'number')                    parts.push(`${k}:${Math.round(v*100)/100}`)
            else if (typeof v === 'boolean')              parts.push(k)
            else if (typeof v === 'string' && v !== '1') parts.push(`${k}:${v.length>11?v.slice(0,9)+'…':v}`)
        }
        return parts.join('\n')
    },

    hsl2rgb(h: number, s: number, l: number): string {
        s /= 100; l /= 100
        const c=(1-Math.abs(2*l-1))*s, x=c*(1-Math.abs(((h/60)%2)-1)), m=l-c/2
        let r=0,g=0,b=0
        if      (h<60)  {r=c;g=x} else if (h<120) {r=x;g=c}
        else if (h<180) {g=c;b=x} else if (h<240) {g=x;b=c}
        else if (h<300) {r=x;b=c} else             {r=c;b=x}
        return `rgb(${Math.round((r+m)*255)},${Math.round((g+m)*255)},${Math.round((b+m)*255)})`
    },

    cyto_nstyle(n: TheC): any {
        const label = this.cyto_label(n)
        const cls   = this.cytyle_classify(n)
        if (cls === 'compound') return { label: String(n.sc.w), isCompound: true,
                                          style: this.cyto_w_style(String(n.sc.w)) }
        const style: any = {}
        if (n.sc.mouthful) {
            const d=(n.sc.dose as number)??0,sz=Math.round(6+d*40)
            style['background-color']=this.hsl2rgb(72,80,62);style.width=sz;style.height=sz
            style.shape='ellipse';style.opacity=0.82;style.color='#003300'
        } else if (n.sc.leaf) {
            const d=(n.sc.dose as number)??0,sz=Math.round(14+d*16),lt=Math.round(28+d*12)
            style['background-color']=this.hsl2rgb(120,55,lt);style.width=sz;style.height=sz
            style.shape='ellipse';style.color=d>1.4?'#001800':'#b0ffb0'
        } else if (n.sc.sunshine) {
            const d=(n.sc.dose as number)??0,sz=Math.round(22+d*22),lt=Math.round(42+d*18)
            style['background-color']=this.hsl2rgb(46,90,lt);style.width=sz;style.height=sz
            style.shape='diamond';style.color='#331800'
        } else if (n.sc.poo) {
            const d=(n.sc.dose as number)??0,sz=Math.round(18+Math.min(d,8)*2.5)
            style['background-color']='#5c3010';style.width=sz;style.height=sz
            style.shape='ellipse';style.color='#c88040'
        } else if (n.sc.material) {
            const amt=(n.sc.amount as number)??0,sz=Math.round(18+Math.min(amt,20)*1.6)
            style['background-color']=this.hsl2rgb(33,52,20+Math.min(amt,20)*1.5)
            style.width=sz;style.height=sz;style.shape='round-rectangle';style.color='#ffe8c0'
        } else if (n.sc.producing) {
            style['background-color']='#142060';style.width=42;style.height=42
            style.shape='round-rectangle';style.color='#9ab4ff'
        } else if (n.sc.protein) {
            const cx=(n.sc.complexity as number)??0,sz=Math.round(18+cx*4.5)
            style['background-color']=this.hsl2rgb(276,40,22+cx*5)
            style.width=sz;style.height=sz;style.shape='hexagon';style.color='#ddc8ff'
        } else if (n.sc.shelf && n.sc.enzyme) {
            const u=(n.sc.units as number)??0
            style['background-color']='#1a4828';style.width=Math.round(20+u*2.5);style.height=20
            style.shape='round-rectangle';style.color='#90ffc0'
        } else if (n.sc.wants_enzyme || n.sc.wants_to_produce) {
            style['background-color']='#6a1a08';style.width=22;style.height=22
            style.shape='star';style.color='#ff9070'
        } else if (n.sc.hand !== undefined) {
            style['background-color']='#1a1a28';style['background-opacity']=0.6
            style['border-color']='#5a5a9a';style['border-width']=1;style['border-style']='solid'
            style.padding='7px';style['font-size']='8px';style['font-style']='italic'
            style.color='#8888bb';style['text-valign']='top'
            return { label: String(n.sc.hand), isCompound: true, style }
        } else {
            style['background-color']='#242424';style.width=16;style.height=16;style.color='#666'
        }
        return { label, style }
    },

    cyto_w_style(wname: string): any {
        const bg:     Record<string,string> = { farm:'#0a1f0a',plate:'#1f130a',enzymeco:'#0a0a1f',
                                                 Yin:'#1a0a1a',Yang:'#1a1a0a' }
        const border: Record<string,string> = { farm:'#2a5a1a',plate:'#5a3a1a',enzymeco:'#1a1a5a',
                                                 Yin:'#5a1a5a',Yang:'#5a5a1a' }
        const color:  Record<string,string> = { farm:'#4a6a4a',plate:'#6a5a4a',enzymeco:'#4a4a6a',
                                                 Yin:'#8a4a8a',Yang:'#8a8a4a' }
        return {
            'background-color': bg[wname] ?? '#181818', 'background-opacity': 0.5,
            'border-color': border[wname] ?? '#2a2a2a', 'border-width': 1, 'border-style': 'dashed',
            'text-valign': 'top', 'text-halign': 'center', padding: '12px',
            'font-size': '9px', 'font-weight': 'bold', 'font-style': 'italic',
            color: color[wname] ?? '#4a6a4a',
        }
    },

//#endregion
//#region intoCyto handshake

    async story_cyto_step(A: TheC, w: TheC, e: TheC) {
        await this.cyto_update_wave(w)
        const dur = ((w.sc.grawave_duration as number) ?? 0.3) * 1000
        setTimeout(() => {
            this.elvisto('Story/Story', 'story_cyto_continue', { story_step: e?.sc.story_step })
        }, dur + 100)
    },

//#endregion

    })
    })
</script>