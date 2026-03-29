<script lang="ts">
    // Cyto.svelte — ghost. Four logical passes per tick:
    //
    //   Se1   n=RunH,  process_D=Se.sc.topD
    //         → D** mirrors n**; builds C** with provisional scan_id
    //         → C.c.of_Se1 = Se1 D, for snap_scan_refs n_ref access
    //         → D.oai({n_ref:1}).sc.n = n, for migration detection
    //
    //   Se2a  n=topC,  process_D=Se2.sc.topD   (first pass, nodes only exist yet)
    //         → assigns branching Dip to C nodes; sets C.sc.cyto_id, C.sc.parent_id
    //         → writes last_cyto_id onto Se1 D for next-tick goner migration
    //
    //   snap_scan_refs
    //         → multi-placed n refs → undirected blue cyto_edge between C nodes
    //         → migrated n refs (goner scan_id + neu cyto_id) → directed blue + cyto_migration
    //         → new cyto_edge particles attached to C nodes (no cyto_id yet)
    //
    //   Se2b  n=topC,  process_D=Se2.sc.topD   (second pass, new edges get Dips)
    //         → assigns Dip to new cyto_edge particles from snap_scan_refs
    //         → after: snips C.c.of_Se1 for GC
    //
    //   Ze    n=topC,  process_D=Ze.sc.topD
    //         → diffs C** vs bD** → wave (upsert/remove/edge_upsert/edge_remove/migrate)
    //         → unified cyto_id for nodes and edges (no separate edge_id)
    //         → UPSERT=true: always full descriptions (v1-compatible, safe to flip false)
    //
    // ── Stable identity ──────────────────────────────────────────────────────
    //   scan_id  D.oai({scan_id:1}).sc.value ??= 's:N'  — once per D, survives replace
    //            stored on C.sc.scan_id for Se2 trace_fn (avoids the_* enumeration)
    //   cyto_id  Se2 Dip.sc.value — branching address like an IP path: r_0, r_0_0, r_1…
    //            parent_dip.sc.i is the sibling counter; root counter is Se2.sc.root_dip_i
    //            Dip particles survive Se2's topD replace via resume_X
    //
    // ── C-sphere ──────────────────────────────────────────────────────────────
    //   topC   = _C({cyto_root:1})  — rebuilt fresh each tick; kept on gn.sc.topC
    //   C.sc   = { cyto_node|cyto_edge|cyto_root|cyto_migration|orphan_source,
    //              cyto_id, scan_id, label, isCompound, parent_id, style:{css…},
    //              source_id, target_id (edges) }
    //   C.c    = { of_Se1: Se1_D }  — snipped after Se2b
    //
    // ── Story integration ─────────────────────────────────────────────────────
    //   wave stored in gn.sc.wave; gn.bump_version() notifies Cytui.
    //   w:Cyto/%CytoStep,C:topC,step_n visible in Stuffing for C** inspection.
    //   Step.sc.CytoStep = topC stored for seek (Cytui can diff any two steps).
    //   story_snap() in Story.svelte reads gn.sc.wave and encodes as Snap:cytowave.

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
        w.c.gn         = wa.oai({ cyto_graph: 1 })
        w.c.plan_done  = true
        w.c.id_counter = w.c.id_counter ?? 0
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

        // Se1 + Se2a + snap_scan_refs + Se2b → topC
        const topC = await this.cyto_scan(w, RunH)
        // Ze → wave
        const wave = await this.make_wave(w, topC, true)

        const story_w = H.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0] as TheC | undefined
        const run     = story_w?.o({ run: 1 })[0] as TheC | undefined
        const step_n  = run?.sc.done as number | undefined
        wave.step_n   = step_n

        // w:Cyto/%CytoStep — Stuffing can drill into C (TheC ref) to browse C**
        await w.r({ CytoStep: 1 }, { CytoStep: 1, C: topC, step_n: step_n ?? null })

        // Store topC on the live Story Step particle for seek
        if (step_n != null && story_w) {
            const step_c = (story_w.c.This?.o({ Step: 1 }) as TheC[] | undefined)
                ?.find(s => s.sc.Step === step_n)
            if (step_c) { step_c.sc.CytoStep = topC; step_c.sc.CytoWave = null }
        }

        const gn = w.c.gn as TheC
        if (!gn) return false
        gn.sc.wave = wave
        gn.sc.tick = ((gn.sc.tick as number) ?? 0) + 1
        gn.sc.topC = topC
        gn.bump_version()   // gn lives in %watched:graph; Cytui subscribes via gn.version
        return true
    },

    async cyto_seek(A: TheC, w: TheC, e: TheC) {
        const gn = w.c.gn as TheC
        if (!gn) return
        gn.sc.seek_step = e?.sc.seek_step ?? null
        gn.bump_version()
    },

//#endregion
//#region cyto_scan — Se1 + Se2a + snap_scan_refs + Se2b

    async cyto_scan(w: TheC, RunH: House): Promise<TheC> {
        w.c.cyto_Se ??= new Selection()
        const Se: Selection = w.c.cyto_Se
        // Replace topD every tick: fresh .c.T; D/** children persist via resume_X
        Se.sc.topD = await Se.r({ cyto_root: 1 })

        const topC:          TheC             = _C({ cyto_root: 1 })
        const prev_cyto_ids: Set<string>      = w.c.prev_cyto_ids ?? new Set()
        const goners_by_id   = new Map<string, TheD>()   // scan_id → Se1 D

        // ── Se1: walk RunH → D** + C** with provisional scan_ids ──────────────
        await Se.process({
            n:          RunH,
            process_D:  Se.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                const cls = this.cytyle_classify(n)
                if (cls === 'skip') { T.sc.not = 1; return }

                if (cls === 'invisible') {
                    // absorb: children land in nearest ancestor's C
                    T.sc.C            = T.sc.up?.sc.C ?? topC
                    T.sc.cyto_id      = null
                    T.sc.skip_ref_map = true   // snap_scan_refs ignores invisible T nodes
                    return
                }

                // scan_id: stable provisional id, lives in D/**{scan_id:1}, never reassigned
                const sid_C      = D.oai({ scan_id: 1 })
                sid_C.sc.value ??= `s:${++w.c.id_counter}`
                const scan_id    = sid_C.sc.value as string
                T.sc.cyto_id     = scan_id   // provisional parent-id for Se1 hierarchy

                // persist current n ref for snap_scan_refs migration detection
                D.oai({ n_ref: 1 }).sc.n = n

                const parentC: TheC = T.sc.up?.sc.C ?? topC
                const nd            = this.cyto_node(n)   // {label, isCompound?, style:{css}}
                const C: TheC       = parentC.i({
                    cyto_node:  1,
                    scan_id,
                    label:      nd.label,
                    isCompound: nd.isCompound ?? false,
                    style:      nd.style,
                    // cyto_id and parent_id will be written by Se2a
                })
                T.sc.C     = C
                C.c.of_Se1 = D   // backlink: snap_scan_refs reads D.o({n_ref:1}) via this
            },

            // encode primitive sc values as the_* for stable resolve() matching
            trace_fn: async (uD: TheD, n: TheC) => {
                const sc: any = { tracing: 1 }
                for (const [k, v] of Object.entries(n.sc ?? {})) {
                    if (typeof v !== 'object' && typeof v !== 'function') sc[`the_${k}`] = v
                }
                return uD.i(sc)
            },

            traced_fn: async () => {},

            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                for (const g of goners) this.cyto_collect_goners(g, goners_by_id)
            },
        })

        // ── Se2a: assign Dip/cyto_id to C nodes ───────────────────────────────
        await this.cyto_scan_assign_ids(w, topC)

        // compute new cyto_ids for snap_scan_refs's migration detection
        const curr_cyto_ids = new Set<string>()
        this.cyto_walk_nodes(topC, C => {
            const id = C.sc.cyto_id as string | undefined
            if (id) curr_cyto_ids.add(id)
        })
        const neu_cyto_ids = new Set([...curr_cyto_ids].filter(id => !prev_cyto_ids.has(id)))

        // ── snap_scan_refs: blue edges + migration advice onto C ───────────────
        await this.snap_scan_refs(Se, w, topC, neu_cyto_ids, goners_by_id)

        // ── Se2b: assign Dip/cyto_id to new cyto_edge particles ───────────────
        await this.cyto_scan_assign_ids(w, topC)

        // Snip C.c.of_Se1 backlinks — Se1 D refs no longer needed
        this.cyto_walk_nodes(topC, C => { C.c.of_Se1 = null })

        w.c.prev_cyto_ids = curr_cyto_ids
        return topC
    },

    // Walk only cyto_node children of C recursively
    cyto_walk_nodes(C: TheC, fn: (C: TheC) => void): void {
        for (const nc of C.o({ cyto_node: 1 }) as TheC[]) { fn(nc); this.cyto_walk_nodes(nc, fn) }
    },

    // Recursively descend a goner Se1 D subtree, collecting scan_ids
    cyto_collect_goners(D: TheD, goners_by_id: Map<string, TheD>): void {
        const scan_id = D.o({ scan_id: 1 })[0]?.sc.value as string | undefined
        if (scan_id && !goners_by_id.has(scan_id)) goners_by_id.set(scan_id, D)
        for (const child of D.o({ tracing: 1 }) as TheD[]) this.cyto_collect_goners(child, goners_by_id)
    },

//#endregion
//#region Se2 — cyto_scan_assign_ids: branching Dip for everything in C**

    // Runs twice per cyto_scan tick:
    //   Pass 1 (before snap_scan_refs): assigns Dip to C nodes → cyto_id, parent_id
    //   Pass 2 (after  snap_scan_refs): assigns Dip to new cyto_edge particles
    //
    // Dip value is a branching address string: r_0, r_0_0, r_0_1, r_1, r_1_0, …
    //   Each D carries a Dip particle {Dip:1, value:'r_0_1', i:0}.
    //   .i is the sibling counter for THIS node's children (not its own index).
    //   On first assignment: new D gets value = parentDip.sc.value + '_' + parentDip.sc.i,
    //   then parentDip.sc.i++.  Root-level counter lives on Se2.sc.root_dip_i.
    //   Dip particles survive Se2.sc.topD replacement via resume_X (they are D/** children).
    //
    // Se2 trace_fn uses scan_id for nodes (stable from Se1) and source+target for edges,
    // so resolve() matches Se2 D objects correctly without the_* enumeration.

    async cyto_scan_assign_ids(w: TheC, topC: TheC): Promise<void> {
        w.c.cyto_Se2 ??= new Selection()
        const Se2: Selection = w.c.cyto_Se2
        // Replace topD: fresh .c.T; D/** children (including Dips) persist via resume_X
        Se2.sc.topD       = await Se2.r({ cyto_id_root: 1 })
        Se2.sc.root_dip_i ??= 0   // root-level sibling counter; persists on Se2.sc itself

        await Se2.process({
            n:          topC,
            process_D:  Se2.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                // assign Dip to D if it doesn't have one yet (never reassigned once set)
                let dip = D.o({ Dip: 1 })[0]
                if (!dip) {
                    const parent_D   = (T.sc.up as Travel | undefined)?.sc.D as TheD | undefined
                    const parent_dip = parent_D?.o({ Dip: 1 })[0]
                    if (parent_dip) {
                        // non-root: address = parentDip.value + '_' + parentDip.i
                        const i         = (parent_dip.sc.i as number) ?? 0
                        parent_dip.sc.i = i + 1
                        dip = D.i({ Dip: 1, value: `${parent_dip.sc.value as string}_${i}`, i: 0 })
                    } else {
                        // root-level child: address = 'r_' + root counter
                        const i           = Se2.sc.root_dip_i as number
                        Se2.sc.root_dip_i = i + 1
                        dip = D.i({ Dip: 1, value: `r_${i}`, i: 0 })
                    }
                }

                // assign cyto_id from Dip (same field for nodes and edges — no distinction)
                n.sc.cyto_id = dip.sc.value as string

                if (n.sc.cyto_node) {
                    // update parent_id now that parent's cyto_id is assigned (process is top-down)
                    const parent_n     = (T.sc.up as Travel | undefined)?.sc.n as TheC | undefined
                    n.sc.parent_id     = (parent_n?.sc.cyto_id as string | null) ?? null
                    // store on Se1 D so snap_scan_refs can find this node's last cyto_id
                    if (n.c.of_Se1) (n.c.of_Se1 as TheD).sc.last_cyto_id = n.sc.cyto_id
                }
            },

            // trace nodes by scan_id (stable from Se1); edges by source+target
            trace_fn: async (uD: TheD, n: TheC) => {
                if (n.sc.cyto_edge) return uD.i({ tracing: 1,
                    the_source_id: n.sc.source_id ?? '', the_target_id: n.sc.target_id ?? '' })
                if (n.sc.cyto_node) return uD.i({ tracing: 1, the_scan_id: n.sc.scan_id ?? '' })
                return uD.i({ tracing: 1 })
            },

            traced_fn:   async () => {},
            resolved_fn: async () => {},
        })
    },

//#endregion
//#region snap_scan_refs — runs after Se2a (nodes have cyto_ids)

    // Single forward pass over Se1's T** to build n → C[] map, then:
    //   multi-placed: same n in >1 current C → undirected blue cyto_edge (node has it)
    //   migration:    goner D whose n appears in a neu C → directed blue + cyto_migration
    //
    // ref_stable detection uses D.oai({n_ref_prev:1}).sc.n (previous tick's n),
    // updated here each tick, distinct from D.oai({n_ref:1}).sc.n (current n from Se1).

    async snap_scan_refs(
        Se:           Selection,
        w:            TheC,
        topC:         TheC,
        neu_cyto_ids: Set<string>,
        goners_by_id: Map<string, TheD>,   // scan_id → Se1 D
    ): Promise<void> {
        const n_to_Cs = new Map<TheC, TheC[]>()

        await Se.c.T.forward(async (T: Travel) => {
            if (T.sc.skip_ref_map) return   // invisible nodes (H, A)
            const n  = T.sc.n  as TheC | undefined
            const C  = T.sc.C  as TheC | undefined
            if (!n || !C || !C.sc.cyto_id) return

            // ref_stable: same TheC stayed in the same D slot from last tick
            const Se1_D    = C.c.of_Se1 as TheD | undefined
            const prev_ref = Se1_D?.oai({ n_ref_prev: 1 })
            if (prev_ref?.sc.n === n) {
                T.sc.ref_stable   = true
                if (Se1_D) Se1_D.c.ref_stable = true
            }
            if (prev_ref) prev_ref.sc.n = n   // update for next tick's comparison

            const existing = n_to_Cs.get(n)
            if (existing) existing.push(C)
            else n_to_Cs.set(n, [C])
        })

        const blue_edge = (source_id: string, target_id: string, directed: boolean) => ({
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
        })

        // multi-placed: same n in >1 current C → undirected blue edges between adjacent pairs
        for (const [_n, Cs] of n_to_Cs) {
            if (Cs.length < 2) continue
            for (let i = 0; i < Cs.length - 1; i++) {
                Cs[i].i(blue_edge(Cs[i].sc.cyto_id as string, Cs[i+1].sc.cyto_id as string, false))
            }
        }

        // migration: goner whose n ref appears as a neu C elsewhere
        // last_cyto_id was written onto Se1 D by Se2a's each_fn
        for (const [_scan_id, gD] of goners_by_id) {
            const n            = gD.o({ n_ref: 1 })[0]?.sc.n as TheC | undefined
            if (!n) continue
            const curr_Cs      = n_to_Cs.get(n) ?? []
            const neu_Cs       = curr_Cs.filter(C => neu_cyto_ids.has(C.sc.cyto_id as string))
            if (!neu_Cs.length) continue
            const from_id      = gD.sc.last_cyto_id as string | undefined
            if (!from_id) continue   // first tick, no previous cyto_id to fly from
            const to_C  = neu_Cs[0]
            const to_id = to_C.sc.cyto_id as string
            // migration advice on destination C (Ze reads cyto_migration in make_wave)
            to_C.i({ cyto_migration: 1, from_id, to_id })
            // source node is gone so we can't park the edge on it; topC holds it
            topC.i({ ...blue_edge(from_id, to_id, true), orphan_source: 1 })
        }
    },

//#endregion
//#region Ze — make_wave: diff C** → wave

    // Diffs topC against Ze's persisted D** (bD = last tick's copy).
    // UPSERT=true:  always emit full node+edge descriptions → Cytui safe, v1-compatible
    // UPSERT=false: emit only changed props → flip once diff mode is trusted
    //
    // Nodes and edges both identified by cyto_id (no separate edge_id).
    // Orphan-source edges (source is gone) emitted as best-effort; Cytui catches failures.

    async make_wave(w: TheC, topC: TheC, adjacent: boolean): Promise<any> {
        w.c.cyto_Ze ??= new Selection()
        const Ze: Selection = w.c.cyto_Ze
        Ze.sc.topD = await Ze.r({ cyto_z: 1 })

        const UPSERT = true   // < flip false once stable for minimal-diff mode

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

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                if (!n.sc.cyto_node && !n.sc.cyto_edge) { T.sc.not = 1; return }
                D.sc.cyto_id = n.sc.cyto_id as string
                D.sc.is_edge = !!n.sc.cyto_edge
            },

            // unified identity via cyto_id for both nodes and edges
            trace_fn: async (uD: TheD, n: TheC) => {
                return uD.i({ tracing: 1, the_cyto_id: (n.sc.cyto_id as string) ?? '' })
            },

            traced_fn: async (D: TheD, bD: TheD | undefined, n: TheC) => {
                if (!n.sc.cyto_node && !n.sc.cyto_edge) return
                const snap_C = D.oai({ snapshot: 1 })

                if (n.sc.cyto_edge) {
                    const id = n.sc.cyto_id as string
                    if (!id) return

                    // orphan-source edge: source node is gone; emit as-is, Cytui try/catch handles
                    if (n.sc.orphan_source) {
                        edge_upsert.push({
                            id:     id,
                            source: n.sc.source_id as string,
                            target: n.sc.target_id as string,
                            style:  n.sc.style ?? {},
                            data:   {},
                        })
                        return
                    }

                    if (UPSERT || !bD) {
                        edge_upsert.push({
                            id,
                            source: n.sc.source_id as string,
                            target: n.sc.target_id as string,
                            style:  n.sc.style ?? {},
                            data:   { ideal_length: (n.sc.ideal_length as number) ?? 80 },
                        })
                    } else {
                        const old = JSON.parse(snap_C.sc.snap as string ?? '{}')
                        const neo = n.sc.style as Record<string,any> ?? {}
                        const ch: any = {}; let has = false
                        for (const [k,v] of Object.entries(neo)) if (old[k] !== v) { ch[k]=v; has=true }
                        if (has) edge_upsert.push({ id, style: ch })
                    }
                    snap_C.sc.snap = JSON.stringify(n.sc.style ?? {})

                } else {
                    const id = n.sc.cyto_id as string
                    if (UPSERT || !bD) {
                        upsert.push({
                            id,
                            label:      n.sc.label      ?? '',
                            isCompound: n.sc.isCompound  ?? false,
                            parent:     n.sc.parent_id   ?? undefined,
                            style:      n.sc.style ?? {},
                        })
                    } else {
                        const old = JSON.parse(snap_C.sc.snap as string ?? '{}')
                        const neo = n.sc.style as Record<string,any> ?? {}
                        const ch: any = {}; let has = false
                        for (const [k,v] of Object.entries(neo)) if (old[k] !== v) { ch[k]=v; has=true }
                        const lch = n.sc.label     !== snap_C.sc.label
                        const pch = n.sc.parent_id !== snap_C.sc.parent
                        if (has || lch || pch) {
                            const nd: any = { id, style: ch }
                            if (lch) nd.label      = n.sc.label
                            if (pch) nd.new_parent = n.sc.parent_id ?? null
                            upsert.push(nd)
                        }
                        snap_C.sc.label  = n.sc.label
                        snap_C.sc.parent = n.sc.parent_id
                    }
                    snap_C.sc.snap = JSON.stringify(n.sc.style ?? {})
                }
            },

            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                for (const g of goners) {
                    const id = g.sc.cyto_id as string | undefined
                    if (!id) continue
                    if (g.sc.is_edge) edge_remove.push(id)
                    else remove.push(id)
                }
            },
        })

        // migration advice from cyto_migration particles in C** (adjacent steps only)
        if (adjacent) {
            this.cyto_walk_nodes(topC, C => {
                for (const mc of C.o({ cyto_migration: 1 }) as TheC[]) {
                    migrate.push({ id: mc.sc.from_id, toward: mc.sc.to_id,
                                   then_parent: C.sc.parent_id ?? null })
                }
            })
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

    // Single classifier used by Se1 and by cyto_node's compound branch.
    // 'skip'      — don't graph, don't traverse children
    // 'invisible' — traverse children; don't add to graph (H, A structural containers)
    // 'compound'  — %w particles → compound worker node via cyto_w_style()
    // null        — normal node → cyto_node() for style

    cytyle_classify(n: TheC): 'skip' | 'invisible' | 'compound' | null {
        const s = n.sc
        // internal mechanics — not part of the graph
        if (s.self || s.chaFrom || s.wasLast || s.sunny_streak || s.seen
            || s.o_elvis || s.cyto_node || s.cyto_root || s.cyto_tracking
            || s.wave_data || s.refs || s.snap_node || s.snap_root
            || s.housed || s.run || s.Se || s.inst || s.began_wanting
            || s.CytoStep || s.CytoWave || s.tracing || s.Dip
            || s.scan_id || s.n_ref || s.n_ref_prev || s.snapshot
            || s.cyto_id_root || s.cyto_edge_root || s.cyto_z) return 'skip'
        // structural containers — traverse but don't add to graph
        if (s.H || s.A) return 'invisible'
        // %w → compound worker node (%Cytyles:Agency equivalent)
        if (s.w) return 'compound'
        return null
    },

//#endregion
//#region cyto_label / hsl2rgb / cyto_node / cyto_w_style

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

    // Returns {label, isCompound?, style:{…css}}.  No id — Se1 supplies that.
    // Calls cytyle_classify so compound nodes always go through cyto_w_style.
    cyto_node(n: TheC): any {
        const cls = this.cytyle_classify(n)
        if (cls === 'compound') {
            return { label: String(n.sc.w), isCompound: true,
                     style: this.cyto_w_style(String(n.sc.w)) }
        }
        const label = this.cyto_label(n)
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
            // %hand sub-compound for LeafJuggle — styled as a nested box
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
//#region intoCyto handshake — story_cyto_step

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