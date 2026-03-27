<script lang="ts">
    // Cyto.svelte — ghost depositing Cyto worker methods onto H.* via eatfunc.
    //
    // ── C-sphere ──────────────────────────────────────────────────────────────
    //
    //   Alongside D** (Se's identity mirror), each_fn builds a parallel C**
    //   that is the canonical graph-abstraction state for this tick.
    //
    //   C lives as a child of T.up.sc.C — so:
    //     invisible layers (H, A): T.sc.C = T.up?.sc.C  (virtual absorption)
    //     compound / normal:       C = T.up.sc.C.i({ cyto_node:1, cyto_id, ...style })
    //
    //   C/* children:
    //     { cyto_edge:1, target_id, ...edge_style }   — edges this node wants
    //     { cyto_edge:1, ref:1, target_id }            — ref-detected blue edges
    //     { cyto_migration:1, from_id, to_id }         — migration advice
    //
    //   C** is rebuilt every tick.  It is the only input needed for Z to
    //   compute a forward or reverse wave between two steps.
    //
    // ── Goner subtree ─────────────────────────────────────────────────────────
    //
    //   resolved_fn receives the immediate goner D children per parent.
    //   cyto_collect_goner_ids() recursively descends into each goner's D.o({})
    //   to find all nested cyto_ids — eg: one/two/three/four → one/two drops
    //   three (and everything under three) while four remains.
    //
    //   Goners are stashed on w.c.prev_goners_by_id (Map<string, TheD>) so
    //   snap_scan_refs() can look up D.c.n for each gone id.
    //
    // ── Z: direction-sensitive wave ───────────────────────────────────────────
    //
    //   make_wave(C_from, C_to, adjacent) diffs two C** snapshots:
    //     forward:  upsert neus, remove goners
    //     backward: upsert what was removed, remove what was added
    //     jump:     same as forward but dur=0 and no migration advice
    //
    //   C_from = previous step's topC (stored on Step.sc.CytoStep)
    //   C_to   = current step's topC
    //
    // ── Cytui ─────────────────────────────────────────────────────────────────
    //
    //   Instead of history[], the $effect calls cyto_step(from_step_n, to_step_n).
    //   Each Story Step particle carries Step.sc.CytoStep = topC for that step.
    //   cyto_step() retrieves the two CytoStep C-tops and calls make_wave().
    //   Wave is cached on the Step: Step.sc.CytoWave = wave.

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
        w.c.gn    = wa.oai({ cyto_graph: 1 })
        w.c.plan_done   = true
        w.c.id_counter  = w.c.id_counter ?? 0
        w.sc.grawave_duration ??= 2
    },

    async cyto_update_wave(w: TheC): Promise<boolean> {
        const H = this as House
        const RunH = (H.o({ H: 1 }) as House[]).find(h => h.sc.Run) as House | undefined
        if (!RunH) return false

        const tracking = w.oai({ cyto_tracking: 1 })
        const v = RunH.version
        if (tracking.sc.v === v) return true
        tracking.sc.v = v

        const { topC, wave } = await this.cyto_scan(w, RunH)

        // tag with story step and store CytoStep on the Step particle
        const story_w = H.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0] as TheC | undefined
        const run     = story_w?.o({ run: 1 })[0] as TheC | undefined
        const step_n  = run?.sc.done as number | undefined
        wave.step_n   = step_n

        // store topC on the Story step particle so Cytui can retrieve it later
        if (step_n != null && story_w) {
            const step_c = story_w.c.This?.o({ Step: 1 })
                ?.find((s: TheC) => s.sc.Step === step_n) as TheC | undefined
            if (step_c) step_c.sc.CytoStep = topC
        }

        const gn = w.c.gn as TheC
        if (!gn) return false
        gn.sc.wave    = wave
        gn.sc.tick    = ((gn.sc.tick as number) ?? 0) + 1
        gn.sc.topC    = topC   // live head C** for Cytui direct access
        ;(H.o({ watched: 'graph' })[0] as TheC)?.bump_version()

        await w.replace({ wave_data: 1 }, async () => {
            w.i({ wave_data: 1, nodes: wave.upsert.length,
                  edges: wave.edge_upsert.length, removing: wave.remove.length,
                  step_n: wave.step_n ?? null })
        })

        return true
    },

    async cyto_seek(A: TheC, w: TheC, e: TheC) {
        const gn = w.c.gn as TheC
        if (!gn) return
        gn.sc.seek_step = e?.sc.seek_step ?? null
        ;(this as House).o({ watched: 'graph' })[0]?.bump_version()
    },

//#endregion
//#region cyto_scan

    async cyto_scan(w: TheC, RunH: House): Promise<{ topC: TheC, wave: any }> {
        w.c.cyto_Se ??= new Selection()
        const Se: Selection = w.c.cyto_Se

        const prev_ids:      Set<string> = w.c.prev_ids      ?? new Set()
        const prev_ref_eids: string[]    = w.c.prev_ref_eids ?? []

        const seen      = new Set<string>()
        const neu_ids:   string[] = []
        const goner_ids: string[] = []

        // goners_by_id: id → goner D, accumulated across all resolved_fn calls
        const goners_by_id = new Map<string, TheD>()

        // C-sphere: invisible top container, absorbs H and A
        const topC: TheC = _C({ cyto_root: 1 })

        await Se.process({
            n:          RunH,
            process_sc: { cyto_root: 1 },
            match_sc:   {},
            trace_sc:   { cyto_node: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                const cls = this.cytyle_classify(n)
                if (cls === 'skip') { T.sc.not = 1; return }

                if (cls === 'invisible') {
                    // absorb into parent — children will land in T.up's C
                    T.sc.C = T.sc.up?.sc.C ?? topC
                    T.sc.cyto_id = null
                    return
                }

                // stable id lives on D — resolve() continuity keeps it
                const id: string = D.c.stable_id ??= `c:${++w.c.id_counter}`
                T.sc.cyto_id = id
                D.sc.cyto_id = id
                D.c.n = n   // store n ref for ref detection

                // parent C = nearest ancestor that produced a C node
                const parentC: TheC = T.sc.up?.sc.C ?? topC

                // build C node — children of parentC
                let nd_style: any = this.cyto_node(n, id)   // style + isCompound from v1
                if (cls === 'compound') {
                    nd_style = { id, label: String(n.sc.w),
                                 style: this.cyto_w_style(String(n.sc.w)), isCompound: true }
                }
                const C: TheC = parentC.i({
                    cyto_node:   1,
                    cyto_id:     id,
                    label:       nd_style.label ?? '',
                    isCompound:  nd_style.isCompound ?? false,
                    // flatten style keys onto C for easy make_wave access
                    node_style:  nd_style.style ?? {},
                    parent_id:   (T.sc.up?.sc.cyto_id as string | undefined) ?? null,
                })
                T.sc.C = C
                D.c.C  = C   // D → C link for goner extraction

                seen.add(id)
                if (!prev_ids.has(id)) neu_ids.push(id)
            },

            trace_fn: async (uD: TheD, n: TheC) => {
                const sc: any = { cyto_node: 1 }
                for (const [k, v] of Object.entries(n.sc ?? {})) {
                    if (typeof v !== 'object' && typeof v !== 'function') sc[`the_${k}`] = v
                }
                return uD.i(sc)
            },

            traced_fn: async () => {},

            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                // accumulate goners from every resolved_fn call (one per parent D)
                for (const g of goners) {
                    // recurse into goner subtree to find all nested ids
                    this.cyto_collect_goner_ids(g, goner_ids, goners_by_id)
                }
            },
        })

        // ── ref scan: multi-placed + migration blue edges into C ──────────────
        const new_ref_eids = await this.snap_scan_refs(
            Se, w, topC, new Set(neu_ids), goners_by_id
        )

        // ── derive wave from seen vs prev ─────────────────────────────────────
        const edge_remove = prev_ref_eids   // clear last tick's ref edges
        const remove      = [...prev_ids].filter(id => !seen.has(id))

        w.c.prev_ids      = new Set(seen)
        w.c.prev_ref_eids = new_ref_eids
        w.c.prev_goners_by_id = goners_by_id   // kept for snap_scan_refs next tick

        // build upsert + edge_upsert from C**
        const upsert:      any[] = []
        const edge_upsert: any[] = []
        this.cyto_collect_wave_from_C(topC, upsert, edge_upsert)

        return {
            topC,
            wave: {
                upsert, edge_upsert,
                remove, edge_remove,
                migrate: [], constraints: null,
                duration: (w.sc.grawave_duration as number) ?? 0.3,
            }
        }
    },

//#endregion
//#region cyto_collect helpers

    // recursively descend into a goner D's subtree, collecting all cyto_ids
    // and stashing each D in goners_by_id
    cyto_collect_goner_ids(
        D:            TheD,
        goner_ids:    string[],
        goners_by_id: Map<string, TheD>,
    ): void {
        const id = D.sc.cyto_id as string | undefined
        if (id && !goners_by_id.has(id)) {
            goner_ids.push(id)
            goners_by_id.set(id, D)
        }
        // descend into D/* — these are traced cyto_node children
        for (const child of D.o({ cyto_node: 1 }) as TheD[]) {
            this.cyto_collect_goner_ids(child, goner_ids, goners_by_id)
        }
    },

    // walk C** and collect upsert / edge_upsert arrays for the wave
    cyto_collect_wave_from_C(
        C:            TheC,
        upsert:       any[],
        edge_upsert:  any[],
    ): void {
        for (const node_C of C.o({ cyto_node: 1 }) as TheC[]) {
            const id = node_C.sc.cyto_id as string
            upsert.push({
                id,
                label:      node_C.sc.label      ?? '',
                style:      node_C.sc.node_style  ?? {},
                isCompound: node_C.sc.isCompound  ?? false,
                parent:     node_C.sc.parent_id   ?? undefined,
            })
            for (const edge_C of node_C.o({ cyto_edge: 1 }) as TheC[]) {
                const eid = edge_C.sc.edge_id as string
                edge_upsert.push({
                    id:     eid,
                    source: id,
                    target: edge_C.sc.target_id as string,
                    data:   edge_C.sc.edge_data  ?? {},
                    style:  edge_C.sc.edge_style ?? {},
                })
            }
            // recurse
            this.cyto_collect_wave_from_C(node_C, upsert, edge_upsert)
        }
    },

//#endregion
//#region snap_scan_refs

    async snap_scan_refs(
        Se:           Selection,
        w:            TheC,
        topC:         TheC,
        neu_set:      Set<string>,
        goners_by_id: Map<string, TheD>,
    ): Promise<string[]> {
        // n_to_Cs: maps a TheC n ref → the C nodes currently holding it
        const n_to_Cs = new Map<TheC, TheC[]>()

        // single forward pass: build n → C[] map, flag ref_stable
        await Se.c.T.forward(async (T: Travel) => {
            const D = T.sc.D
            const C = D?.c.C  as TheC | undefined
            const n = D?.c.n  as TheC | undefined
            if (!C || !n) return

            // ref_stable: same n stayed in same D slot — no animation needed
            if (T.sc.bD?.c.n === n) {
                T.sc.ref_stable = true
                D.c.ref_stable  = true
            }

            const existing = n_to_Cs.get(n)
            if (existing) existing.push(C)
            else n_to_Cs.set(n, [C])
        })

        const ref_eids: string[] = []

        const add_ref_edge = (
            from_C: TheC, to_C: TheC,
            from_id: string, to_id: string,
            directed: boolean,
        ) => {
            const eid = `ref:${from_id}:${to_id}`
            ref_eids.push(eid)
            from_C.i({ cyto_edge: 1, ref: 1, edge_id: eid,
                        target_id: to_id,
                        edge_style: {
                            'line-color': '#4488ff', width: 1.2, 'line-style': 'dashed',
                            'target-arrow-shape': directed ? 'triangle' : 'none',
                            'target-arrow-color': '#4488ff',
                            'curve-style': 'bezier', opacity: 0.5,
                        },
                        edge_data: { ideal_length: 120 } })
        }

        // ── multi-placed: same n in >1 current C ─────────────────────────────
        for (const [_n, Cs] of n_to_Cs) {
            if (Cs.length < 2) continue
            for (let i = 0; i < Cs.length - 1; i++) {
                const from_id = Cs[i].sc.cyto_id   as string
                const to_id   = Cs[i+1].sc.cyto_id as string
                add_ref_edge(Cs[i], Cs[i+1], from_id, to_id, false)
            }
        }

        // ── migration: goner D whose n appears as a neu C elsewhere ──────────
        for (const [gid, gD] of goners_by_id) {
            const n = gD.c.n as TheC | undefined
            if (!n) continue

            const curr_Cs = n_to_Cs.get(n) ?? []
            const neu_Cs  = curr_Cs.filter(C => neu_set.has(C.sc.cyto_id as string))
            if (!neu_Cs.length) continue

            const to_C  = neu_Cs[0]
            const to_id = to_C.sc.cyto_id as string

            // record migration advice on the destination C
            to_C.i({ cyto_migration: 1, from_id: gid, to_id })
            // directed blue edge goner → destination
            add_ref_edge(to_C, to_C, gid, to_id, true)   // source = gid, emit from topC
            // (source node is gone so we park the edge on topC; Cytui handles visually)
            topC.i({ cyto_edge: 1, ref: 1, edge_id: `ref:${gid}:${to_id}`,
                      target_id: to_id, source_id: gid,
                      edge_style: {
                          'line-color': '#4488ff', width: 1.2, 'line-style': 'dashed',
                          'target-arrow-shape': 'triangle', 'target-arrow-color': '#4488ff',
                          'curve-style': 'bezier', opacity: 0.5,
                      },
                      edge_data: { ideal_length: 120 } })
        }

        return ref_eids
    },

//#endregion
//#region make_wave black box

    // Diff two C** snapshots to produce a wave in a given direction.
    //
    //   C_from — the C** we are leaving (previous CytoStep)
    //   C_to   — the C** we are arriving at (target CytoStep)
    //   adjacent — true: steps are neighbours, include migration advice
    //              false: jump, no migration, dur = 0
    //
    // Walks C_to.o({cyto_node:1}) recursively for upsert.
    // Walks C_from.o({cyto_node:1}) recursively for ids not in C_to → remove.
    // Direction (forward/backward) is implicit: caller passes (prev, next) or
    // (next, prev) — make_wave always produces "go from C_from to C_to".

    make_wave(C_from: TheC | null, C_to: TheC, adjacent: boolean): any {
        const upsert:      any[] = []
        const edge_upsert: any[] = []
        const remove:      string[] = []
        const edge_remove: string[] = []
        const migrate:     any[] = []

        // collect all ids present in a C** recursively
        const ids_in = (C: TheC): Set<string> => {
            const s = new Set<string>()
            const walk = (c: TheC) => {
                for (const nc of c.o({ cyto_node: 1 }) as TheC[]) {
                    const id = nc.sc.cyto_id as string
                    if (id) s.add(id)
                    walk(nc)
                }
            }
            walk(C)
            return s
        }

        this.cyto_collect_wave_from_C(C_to, upsert, edge_upsert)

        if (C_from) {
            const from_ids = ids_in(C_from)
            const to_ids   = ids_in(C_to)
            for (const id of from_ids) {
                if (!to_ids.has(id)) remove.push(id)
            }
            // collect edges that were in C_from but not C_to
            const edges_in = (C: TheC): Set<string> => {
                const s = new Set<string>()
                const walk = (c: TheC) => {
                    for (const nc of c.o({ cyto_node: 1 }) as TheC[]) {
                        for (const ec of nc.o({ cyto_edge: 1 }) as TheC[])
                            s.add(ec.sc.edge_id as string)
                        walk(nc)
                    }
                }
                walk(C)
                return s
            }
            const from_eids = edges_in(C_from)
            const to_eids   = edges_in(C_to)
            for (const eid of from_eids) {
                if (!to_eids.has(eid)) edge_remove.push(eid)
            }
        }

        // migration advice from C_to's cyto_migration particles (adjacent only)
        if (adjacent) {
            const walk_migrate = (C: TheC) => {
                for (const nc of C.o({ cyto_node: 1 }) as TheC[]) {
                    for (const mc of nc.o({ cyto_migration: 1 }) as TheC[]) {
                        migrate.push({ id: mc.sc.from_id, toward: mc.sc.to_id,
                                       then_parent: nc.sc.parent_id ?? null })
                    }
                    walk_migrate(nc)
                }
            }
            walk_migrate(C_to)
        }

        return {
            upsert, edge_upsert,
            remove, edge_remove,
            migrate, constraints: null,
            duration: adjacent ? ((this as any).w?.sc.grawave_duration ?? 0.3) : 0,
        }
    },

//#endregion
//#region cytyle helpers

    cytyle_classify(n: TheC): 'skip' | 'invisible' | 'compound' | null {
        const s = n.sc
        if (s.self || s.chaFrom || s.wasLast || s.sunny_streak || s.seen
            || s.o_elvis || s.cyto_node || s.cyto_root || s.cyto_tracking
            || s.wave_data || s.refs || s.snap_node || s.snap_root
            || s.housed || s.run || s.Se || s.inst || s.began_wanting
            || s.CytoStep || s.CytoWave) return 'skip'
        if (s.H || s.A) return 'invisible'
        if (s.w) return 'compound'
        return null
    },

    cytyle_parent_id(T: Travel): string | undefined {
        let up = T.sc.up as Travel | undefined
        while (up) {
            if (up.sc.cyto_id) return String(up.sc.cyto_id)
            up = up.sc.up as Travel | undefined
        }
        return undefined
    },

    cytyle_wname(T: Travel): string | undefined {
        let up = T.sc.up as Travel | undefined
        while (up) {
            const n = up.sc.n as TheC | undefined
            if (n?.sc?.w) return String(n.sc.w)
            up = up.sc.up as Travel | undefined
        }
        return undefined
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

    cyto_node(n: TheC, id: string): any {
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
            style['background-color']='#1a1a28';style['background-opacity']=0.6
            style['border-color']='#5a5a9a';style['border-width']=1;style['border-style']='solid'
            style.padding='7px';style['font-size']='8px';style['font-style']='italic'
            style.color='#8888bb';style['text-valign']='top'
            return { id, label: String(n.sc.hand), style, isCompound: true }
        } else {
            style['background-color']='#242424';style.width=16;style.height=16;style.color='#666'
        }
        return { id, label, style }
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