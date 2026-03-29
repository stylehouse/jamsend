<script lang="ts">
    // Cyto.svelte — ghost.
    //
    // ── Dip protocol ─────────────────────────────────────────────────────────
    //
    //   Dip_assign(scheme, D, T) assigns a branching hierarchical id to D,
    //   stored as D/{Dip:scheme, value:'cytoid_1_2_0', i:0}.
    //
    //   The parent Dip is found by walking T.c.up to find the parent Travel's D,
    //   then reading its Dip for this scheme.  The parent's Dip.sc.i is the
    //   sibling counter — incremented on each new child.
    //
    //   Top-level: value = `${scheme}_${parent_i}` (e.g. 'cytoid_0').
    //   Children:  value = `${parent_value}_${sibling_i}`.
    //
    //   This mirrors Cytoscaping's Dip approach exactly.  Because the Dip
    //   particle lives in D/** and survives Se's replace() via resume_X,
    //   the same path through the tree always gets the same id across ticks —
    //   even as the structure changes, the branching namespace is stable.
    //
    // ── Three Se passes ───────────────────────────────────────────────────────
    //
    //   cyto_scan (Se1)   n=RunH  → D** mirrors n**
    //                              Dip scheme='scanid' → C.sc.scan_id
    //                              C.c.of_Se1 = D (for snap_scan_refs lookup)
    //
    //   cyto_assign_ids (Se2a)  n=topC → D** mirrors C%cyto_node/**
    //                              Dip scheme='cytoid' → C.sc.cyto_id
    //                              also assigns edge_id to any cyto_edge children
    //                              forward() pass removes C.c.of_Se1 links
    //
    //   snap_scan_refs          runs after Se2a, adds cyto_edge ref particles to C
    //
    //   cyto_assign_ids (Se2b)  runs again on same Se2, same topD
    //                              picks up any new cyto_edge children from refs
    //                              assigns their edge_ids
    //
    //   make_wave (Ze)    n=topC → diffs C** vs bD** → wave

    import { TheC, _C }  from "$lib/data/Stuff.svelte"
    import { Selection } from "$lib/mostly/Selection.svelte"
    import type { TheD, Travel } from "$lib/mostly/Selection.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount }   from "svelte"
    import Cytui         from "./ui/Cytui.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region w:Cyto

    async Cyto(A: TheC, w: TheC) {
        if (!w.c.plan_done) this.Cyto_plan(w)
        const ok = await this.cyto_update_wave(w)
        if (!ok) return w.i({ see: '⏳ no H%Run yet' })
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

        // Se1: D** from RunH + provisional scan_ids on C nodes
        const topC = await this.cyto_scan(w, RunH)

        // Se2a: cyto_ids on C nodes (before refs, so ref edges can name their endpoints)
        await this.cyto_assign_ids(w, topC)

        // ref edges — uses cyto_ids from Se2a
        await this.snap_scan_refs(w, topC)

        // Se2b: cyto_ids on the new ref edges (same Se2 instance, same topD)
        await this.cyto_assign_ids(w, topC)

        // Ze: diff C** → wave
        const wave = await this.make_wave(w, topC, true)

        // story step tagging
        const story_w = H.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0] as TheC | undefined
        const run     = story_w?.o({ run: 1 })[0] as TheC | undefined
        const step_n  = run?.sc.done as number | undefined
        wave.step_n   = step_n

        if (step_n != null && story_w) {
            const step_c = (story_w.c.This?.o({ Step: 1 }) as TheC[] | undefined)
                ?.find(s => s.sc.Step === step_n)
            if (step_c) { step_c.sc.CytoStep = topC; step_c.sc.CytoWave = null }
        }

        // write topC onto w for Stuffing inspection
        await w.replace({ CytoStep: 1 }, async () => {
            w.i({ CytoStep: 1, step_n: step_n ?? null, C: topC })
        })

        const gn = w.c.gn as TheC
        if (!gn) return false
        gn.sc.wave = wave
        gn.sc.tick = ((gn.sc.tick as number) ?? 0) + 1
        gn.sc.topC = topC
        gn.bump_version()

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

    // Assign a branching hierarchical id to D under scheme 'scanid' or 'cytoid'.
    // Stored as D/{Dip:scheme, value:'cytoid_0_1_2', i:0} — survives Se replace()
    // via resume_X because it is a child of D, not a .c property.
    //
    // Parent Dip found by climbing T via T.c.up.sc.D (the parent Travel's D).
    // Parent's Dip.sc.i is the sibling counter; incremented on first use.
    // Top-level (no parent Dip): value = `${scheme}_${parent_i}`.
    // Children:                  value = `${parent_value}_${child_i}`.

    Dip_assign(scheme: 'scanid' | 'cytoid', D: TheD, T: Travel): string {
        // is there already a Dip for this scheme?
        const existing = D.o({ Dip: scheme })[0]
        if (existing) return existing.sc.value as string

        // find parent D by climbing T.c.path
        // T.c.path[-2] is the parent Travel; its D is T.c.up.sc.D
        const parent_T   = T.c.path.length >= 2 ? T.c.path[T.c.path.length - 2] : null
        const parent_D   = parent_T?.sc.D as TheD | undefined

        // find (or create) parent's Dip to get/increment sibling counter
        let parent_dip: TheC | undefined
        let parent_value: string | undefined
        if (parent_D) {
            parent_dip = parent_D.o({ Dip: scheme })[0]
            if (!parent_dip) {
                // parent hasn't been assigned yet — rare edge case, give it root
                parent_dip = parent_D.i({ Dip: scheme, value: `${scheme}_root`, i: 0 })
            }
            parent_value = parent_dip.sc.value as string
        }

        // claim next sibling index from parent (or root counter on topD)
        let sibling_i: number
        if (parent_dip) {
            sibling_i = (parent_dip.sc.i as number) ?? 0
            parent_dip.sc.i = sibling_i + 1
        } else {
            // top-level: sibling counter lives on D itself (no parent Dip)
            // use a stable root counter stored in w.c
            const root_key = `${scheme}_root_i`
            sibling_i = w.c[root_key] ?? 0
            ;(w.c as any)[root_key] = sibling_i + 1
        }

        const value = parent_value
            ? `${parent_value}_${sibling_i}`
            : `${scheme}_${sibling_i}`

        D.i({ Dip: scheme, value, i: 0 })
        return value
    },

//#endregion
//#region Se1 — cyto_scan: D** + C** with scan_ids

    async cyto_scan(w: TheC, RunH: House): Promise<TheC> {
        w.c.cyto_Se ??= new Selection()
        const Se: Selection = w.c.cyto_Se
        // replace topD every tick: fresh .c.T; D/** (including Dip) preserved via resume_X
        Se.sc.topD = await Se.r({ cyto_root: 1 })

        const topC: TheC = _C({ cyto_root: 1 })

        const prev_scan_ids: Set<string> = w.c.prev_scan_ids ?? new Set()
        const neu_scan_ids:  string[]    = []
        const goner_ids:     string[]    = []
        const goners_by_id   = new Map<string, TheD>()

        await Se.process({
            n:          RunH,
            process_D:  Se.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                const cls = this.cytyle_classify(n)
                if (cls === 'skip') { T.sc.not = 1; return }

                if (cls === 'invisible') {
                    T.sc.C       = T.sc.up?.sc.C ?? topC
                    T.sc.scan_id = null
                    return
                }

                // provisional scan_id via Dip scheme='scanid'
                const scan_id = this.Dip_assign('scanid', D, T)
                T.sc.scan_id = scan_id

                // store n ref in D/** for goner migration detection
                D.oai({ n_ref: 1 }).sc.n = n

                const parentC: TheC = T.sc.up?.sc.C ?? topC
                const nd = this.cyto_node(n)   // {label, isCompound?, style:{...}}

                const C: TheC = parentC.i({
                    cyto_node:  1,
                    scan_id,            // provisional id; cyto_id assigned in Se2
                    label:      nd.label,
                    isCompound: nd.isCompound ?? false,
                    parent_id:  (T.sc.up?.sc.scan_id as string | null) ?? null,
                    style:      nd.style,
                })
                // link C back to Se1's D so snap_scan_refs can read D.c
                C.c.of_Se1 = D
                T.sc.C = C

                if (!prev_scan_ids.has(scan_id)) neu_scan_ids.push(scan_id)
            },

            trace_fn: async (uD: TheD, n: TheC) => {
                // trace on all primitive sc values so resolve() matches stably
                const sc: any = { tracing: 1 }
                for (const [k, v] of Object.entries(n.sc ?? {})) {
                    if (typeof v !== 'object' && typeof v !== 'function') sc[`the_${k}`] = v
                }
                return uD.i(sc)
            },

            traced_fn: async () => {},

            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                for (const g of goners) {
                    this.cyto_collect_goner_ids(g, goner_ids, goners_by_id)
                }
            },
        })

        // update scan_id tracking for next tick
        const all_scan_ids = new Set<string>()
        const collect_scan_ids = (C: TheC) => {
            for (const nc of C.o({ cyto_node: 1 }) as TheC[]) {
                all_scan_ids.add(nc.sc.scan_id as string)
                collect_scan_ids(nc)
            }
        }
        collect_scan_ids(topC)
        w.c.prev_scan_ids = all_scan_ids

        // stash goners for snap_scan_refs (called after Se2a)
        w.c.snap_goners_by_id  = goners_by_id
        w.c.snap_neu_scan_ids  = new Set(neu_scan_ids)

        return topC
    },

    // recursively descend a goner D subtree collecting all scanid Dip values
    cyto_collect_goner_ids(
        D:            TheD,
        goner_ids:    string[],
        goners_by_id: Map<string, TheD>,
    ): void {
        const id = D.o({ Dip: 'scanid' })[0]?.sc.value as string | undefined
        if (id && !goners_by_id.has(id)) {
            goner_ids.push(id)
            goners_by_id.set(id, D)
        }
        for (const child of D.o({ tracing: 1 }) as TheD[]) {
            this.cyto_collect_goner_ids(child, goner_ids, goners_by_id)
        }
    },

//#endregion
//#region Se2 — cyto_assign_ids: Dip scheme='cytoid' across C**

    // Called twice: Se2a (before snap_scan_refs) and Se2b (after, for ref edges).
    // Same Se2 instance and same topD — Se2b picks up any new C%cyto_edge
    // particles that snap_scan_refs added, assigning them cytoid Dips.
    // each_fn names its first arg D and second C for clarity (n is a C here).

    async cyto_assign_ids(w: TheC, topC: TheC): Promise<void> {
        w.c.cyto_Se2 ??= new Selection()
        const Se2: Selection = w.c.cyto_Se2
        Se2.sc.topD = await Se2.r({ cyto_edge_root: 1 })

        await Se2.process({
            n:          topC,
            process_D:  Se2.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, C: TheC, T: Travel) => {
                // assign cytoid Dip to this D, write back to C
                const cyto_id = this.Dip_assign('cytoid', D, T)

                if (C.sc.cyto_node) {
                    C.sc.cyto_id = cyto_id
                    // update parent_id now we have real cyto_ids
                    const parent_T  = T.c.path.length >= 2 ? T.c.path[T.c.path.length - 2] : null
                    const parent_D  = parent_T?.sc.D as TheD | undefined
                    const par_cyto  = parent_D?.o({ Dip: 'cytoid' })[0]?.sc.value as string | undefined
                    if (par_cyto !== undefined) C.sc.parent_id = par_cyto ?? null
                }

                if (C.sc.cyto_edge) {
                    C.sc.edge_id = cyto_id
                }
            },

            trace_fn: async (uD: TheD, C: TheC) => {
                // trace on scan_id (nodes) or source+target (edges) for stable resolve()
                if (C.sc.cyto_node) return uD.i({ tracing: 1, the_scan_id: C.sc.scan_id ?? '' })
                if (C.sc.cyto_edge) return uD.i({ tracing: 1,
                    the_source_id: C.sc.source_id ?? '', the_target_id: C.sc.target_id ?? '' })
                return uD.i({ tracing: 1 })
            },

            traced_fn: async () => {},
            resolved_fn: async () => {},
        })

        // forward pass: remove C.c.of_Se1 links now ids are assigned
        // (keeps C** low-memory; Se1 D refs not needed beyond this point)
        await Se2.c.T.forward(async (T: Travel) => {
            const C = T.sc.n as TheC
            if (C?.c?.of_Se1) delete C.c.of_Se1
        })
    },

//#endregion
//#region snap_scan_refs

    // Runs after Se2a (nodes have cyto_ids) and before Se2b (edges need ids).
    // Reads Se1 D via C.c.of_Se1 to get n refs for migration detection.

    async snap_scan_refs(w: TheC, topC: TheC): Promise<void> {
        const goners_by_id: Map<string, TheD> = w.c.snap_goners_by_id ?? new Map()
        const neu_scan_ids: Set<string>        = w.c.snap_neu_scan_ids ?? new Set()

        // n → C[] map from current C** nodes
        const n_to_Cs = new Map<TheC, TheC[]>()

        const walk_nodes = (C: TheC) => {
            for (const nc of C.o({ cyto_node: 1 }) as TheC[]) {
                const D   = nc.c.of_Se1 as TheD | undefined
                const n   = D?.o({ n_ref: 1 })[0]?.sc.n as TheC | undefined
                if (n) {
                    const existing = n_to_Cs.get(n)
                    if (existing) existing.push(nc)
                    else n_to_Cs.set(n, [nc])
                }
                walk_nodes(nc)
            }
        }
        walk_nodes(topC)

        const blue_edge_sc = (source_id: string, target_id: string, directed: boolean) => ({
            cyto_edge:            1 as const,
            ref:                  1 as const,
            source_id,
            target_id,
            ideal_length:         120,
            'line-color':         '#4488ff',
            width:                1.2,
            'line-style':         'dashed',
            'target-arrow-shape': directed ? 'triangle' : 'none',
            'target-arrow-color': '#4488ff',
            'curve-style':        'bezier',
            opacity:              0.5,
            style: {
                'line-color':         '#4488ff',
                width:                1.2,
                'line-style':         'dashed',
                'target-arrow-shape': directed ? 'triangle' : 'none',
                'target-arrow-color': '#4488ff',
                'curve-style':        'bezier',
                opacity:              0.5,
            },
        })

        // multi-placed: same n in >1 current C → undirected blue edges
        for (const [_n, Cs] of n_to_Cs) {
            if (Cs.length < 2) continue
            for (let i = 0; i < Cs.length - 1; i++) {
                const src = Cs[i].sc.cyto_id   as string
                const tgt = Cs[i+1].sc.cyto_id as string
                Cs[i].i(blue_edge_sc(src, tgt, false))
            }
        }

        // migration: goner (keyed by scan_id) whose n ref appears as a neu C
        for (const [gid, gD] of goners_by_id) {
            const n = gD.o({ n_ref: 1 })[0]?.sc.n as TheC | undefined
            if (!n) continue
            const curr_Cs = n_to_Cs.get(n) ?? []
            const neu_Cs  = curr_Cs.filter(C => neu_scan_ids.has(C.sc.scan_id as string))
            if (!neu_Cs.length) continue

            const to_C  = neu_Cs[0]
            const to_id = to_C.sc.cyto_id as string
            to_C.i({ cyto_migration: 1, from_id: gid, to_id })
            // directed ref edge — source is gone, park on topC with explicit source_id
            topC.i({ ...blue_edge_sc(gid, to_id, true), orphan_source: 1 })
        }
    },

//#endregion
//#region Ze — make_wave

    async make_wave(w: TheC, topC: TheC, adjacent: boolean): Promise<any> {
        w.c.cyto_Ze ??= new Selection()
        const Ze: Selection = w.c.cyto_Ze
        Ze.sc.topD = await Ze.r({ cyto_z: 1 })

        const UPSERT = true   // flip false for minimal diff mode once stable

        const upsert:      any[] = []
        const edge_upsert: any[] = []
        const remove:      string[] = []
        const edge_remove: string[] = []
        const migrate:     any[] = []

        await Ze.process({
            n:          topC,
            process_D:  Ze.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, C: TheC, T: Travel) => {
                if (!C.sc.cyto_node && !C.sc.cyto_edge) { T.sc.not = 1; return }
                D.sc.is_edge = !!C.sc.cyto_edge
            },

            trace_fn: async (uD: TheD, C: TheC) => {
                if (C.sc.cyto_edge)  return uD.i({ tracing: 1, the_edge_id:  C.sc.edge_id  ?? '' })
                if (C.sc.cyto_node)  return uD.i({ tracing: 1, the_cyto_id:  C.sc.cyto_id  ?? '' })
                return uD.i({ tracing: 1 })
            },

            traced_fn: async (D: TheD, bD: TheD | undefined, C: TheC) => {
                if (!C.sc.cyto_node && !C.sc.cyto_edge) return
                const snap_C = D.oai({ snapshot: 1 })

                if (C.sc.cyto_edge) {
                    const eid = C.sc.edge_id as string
                    if (!eid || C.sc.orphan_source) return
                    if (UPSERT || !bD) {
                        edge_upsert.push({
                            id:     eid,
                            source: C.sc.source_id as string,
                            target: C.sc.target_id as string,
                            style:  C.sc.style ?? {},
                            data:   { ideal_length: (C.sc.ideal_length as number) ?? 80 },
                        })
                    } else {
                        const old_style = JSON.parse(snap_C.sc.snap as string ?? '{}')
                        const new_style = C.sc.style as Record<string,any> ?? {}
                        const changed: any = {}; let has = false
                        for (const [k,v] of Object.entries(new_style)) {
                            if (old_style[k] !== v) { changed[k] = v; has = true }
                        }
                        if (has) edge_upsert.push({ id: eid, style: changed })
                    }
                    snap_C.sc.snap = JSON.stringify(C.sc.style ?? {})

                } else {
                    const id = C.sc.cyto_id as string
                    if (UPSERT || !bD) {
                        upsert.push({
                            id,
                            label:      C.sc.label      ?? '',
                            isCompound: C.sc.isCompound  ?? false,
                            parent:     C.sc.parent_id   ?? undefined,
                            style:      C.sc.style ?? {},
                        })
                    } else {
                        const old_style  = JSON.parse(snap_C.sc.snap as string ?? '{}')
                        const new_style  = C.sc.style as Record<string,any> ?? {}
                        const changed: any = {}; let has = false
                        for (const [k,v] of Object.entries(new_style)) {
                            if (old_style[k] !== v) { changed[k] = v; has = true }
                        }
                        const label_ch  = C.sc.label     !== snap_C.sc.label
                        const parent_ch = C.sc.parent_id !== snap_C.sc.parent
                        if (has || label_ch || parent_ch) {
                            const nd: any = { id, style: changed }
                            if (label_ch)  nd.label      = C.sc.label
                            if (parent_ch) nd.new_parent = C.sc.parent_id ?? null
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
                    if (g.sc.is_edge) {
                        if (g.sc.the_edge_id) edge_remove.push(g.sc.the_edge_id as string)
                    } else {
                        if (g.sc.the_cyto_id) remove.push(g.sc.the_cyto_id as string)
                    }
                }
            },
        })

        if (adjacent) {
            const walk = (C: TheC) => {
                for (const mc of C.o({ cyto_migration: 1 }) as TheC[])
                    migrate.push({ id: mc.sc.from_id, toward: mc.sc.to_id,
                                   then_parent: mc.sc.parent_id ?? null })
                for (const nc of C.o({ cyto_node: 1 }) as TheC[]) walk(nc)
            }
            walk(topC)
        }

        return {
            upsert, edge_upsert,
            remove, edge_remove,
            migrate, constraints: null,
            duration: adjacent ? ((w.sc.grawave_duration as number) ?? 0.3) : 0,
        }
    },

//#endregion
//#region cytyle_classify

    cytyle_classify(n: TheC): 'skip' | 'invisible' | 'compound' | null {
        const s = n.sc
        if (s.self || s.chaFrom || s.wasLast || s.sunny_streak || s.seen
            || s.o_elvis || s.cyto_node || s.cyto_root || s.cyto_tracking
            || s.wave_data || s.refs || s.snap_node || s.snap_root
            || s.housed || s.run || s.Se || s.inst || s.began_wanting
            || s.CytoStep || s.CytoWave || s.tracing || s.Dip || s.n_ref
            || s.snapshot || s.dip_counter) return 'skip'
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

    // returns {label, isCompound?, style:{...css}}
    // calls cytyle_classify so compound branch uses cyto_w_style
    cyto_node(n: TheC): any {
        const label = this.cyto_label(n)
        const cls   = this.cytyle_classify(n)
        if (cls === 'compound') {
            return { label: String(n.sc.w), isCompound: true,
                     style: this.cyto_w_style(String(n.sc.w)) }
        }
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