<script lang="ts">
    // Cyto.svelte — ghost depositing Cyto worker methods onto H.* via eatfunc.
    //
    // ── Three Se passes ───────────────────────────────────────────────────────
    //
    //   Se1  n=RunH,  process_D=Se.sc.topD  → D** mirrors n**; C** built in each_fn
    //   Se2  n=topC,  process_D=Se2.sc.topD → D** mirrors C%cyto_edge**; assigns edge ids
    //   Ze   n=topC,  process_D=Ze.sc.topD  → diffs incoming C** vs D** → wave
    //        (Ze also runs over a prior CytoStep C** when seeking)
    //
    // ── C-sphere ──────────────────────────────────────────────────────────────
    //
    //   Fresh topC = _C({cyto_root:1}) each tick.
    //   CSS style properties spread directly onto C: parentC.i({cyto_node:1, cyto_id, label, ...style})
    //   Edges are children: C.i({cyto_edge:1, source_id, target_id, edge_id, ...edge_style})
    //   Ref edges from snap_scan_refs also land as cyto_edge children of topC.
    //
    //   T.sc holds {n, D, C} — unpack freely.
    //   D.c.T is the sole link back to T; C is not stored on D.c.
    //
    // ── Edge id assignment (Se2) ──────────────────────────────────────────────
    //
    //   Se2 climbs topC/*%cyto_node/**%cyto_edge.
    //   trace_fn creates D%cyto_edge_id,source_id,target_id — resolve() keeps these stable.
    //   In each_fn, edge.sc.edge_id = D.c.stable_id ??= `e:${++w.c.id_counter}`
    //   Written back onto the C edge particle before Ze sees it.
    //
    // ── Z diff (make_wave / Ze) ───────────────────────────────────────────────
    //
    //   Ze.process() with n=topC_to, process_D=Ze.sc.topD.
    //   trace_sc={cyto_z:1}, keyed on cyto_id — so D stably tracks each node.
    //   each_fn: writes Ze upsert candidate onto D.
    //   resolved_fn: goners → remove/edge_remove; neus → add to upsert.
    //   traced_fn: compare current C vs bD's copy → changed props → style upsert.
    //
    //   Adjacent steps: include migration advice (cyto_migration particles on C).
    //   Non-adjacent / jump: no migration, duration=0.

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
        const H = this as House
        const RunH = (H.o({ H: 1 }) as House[]).find(h => h.sc.Run) as House | undefined
        if (!RunH) return false

        const tracking = w.oai({ cyto_tracking: 1 })
        const v = RunH.version
        if (tracking.sc.v === v) return true
        tracking.sc.v = v

        // Se1: build D** + C** from RunH
        const topC = await this.cyto_scan(w, RunH)
        // Se2: assign stable edge ids across C%cyto_edge**
        await this.cyto_assign_edge_ids(w, topC)
        // Ze: diff C** → wave
        const wave = await this.make_wave(w, null, topC, true)

        const story_w = H.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0] as TheC | undefined
        const run     = story_w?.o({ run: 1 })[0] as TheC | undefined
        const step_n  = run?.sc.done as number | undefined
        wave.step_n   = step_n

        if (step_n != null && story_w) {
            const step_c = (story_w.c.This?.o({ Step: 1 }) as TheC[] | undefined)
                ?.find(s => s.sc.Step === step_n)
            if (step_c) {
                step_c.sc.CytoStep = topC
                step_c.sc.CytoWave = null   // invalidate cached wave for this step
            }
        }

        const gn = w.c.gn as TheC
        if (!gn) return false
        gn.sc.wave = wave
        gn.sc.tick = ((gn.sc.tick as number) ?? 0) + 1
        gn.sc.topC = topC
        ;(H.o({ watched: 'graph' })[0] as TheC)?.bump_version()

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
        ;(this as House).o({ watched: 'graph' })[0]?.bump_version()
    },

//#endregion
//#region Se1 — cyto_scan: D** + C** from RunH

    async cyto_scan(w: TheC, RunH: House): Promise<TheC> {
        w.c.cyto_Se ??= new Selection()
        const Se: Selection = w.c.cyto_Se

        // topD is persistent — Se uses it as the root of D**
        Se.sc.topD = await Se.r({ cyto_root: 1 })

        // fresh C** root each tick
        const topC: TheC = _C({ cyto_root: 1 })

        const neu_ids:    string[] = []
        const goner_ids:  string[] = []
        const goners_by_id = new Map<string, TheD>()

        await Se.process({
            n:          RunH,
            process_D:  Se.sc.topD,
            match_sc:   {},
            trace_sc:   { cyto_node: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                const cls = this.cytyle_classify(n)
                if (cls === 'skip') { T.sc.not = 1; return }

                if (cls === 'invisible') {
                    // absorb into parent — children will land inside T.up's C
                    T.sc.C = T.sc.up?.sc.C ?? topC
                    T.sc.cyto_id = null
                    return
                }

                // stable id lives on D.c — resolve() continuity keeps it across ticks
                const id: string = D.c.stable_id ??= `c:${++w.c.id_counter}`
                T.sc.cyto_id  = id
                D.sc.cyto_id  = id

                // parent C is the nearest ancestor that produced a C node
                const parentC: TheC = T.sc.up?.sc.C ?? topC

                // build node style — cyto_node returns {id, label, style, isCompound?}
                const nd = cls === 'compound'
                    ? { id, label: String(n.sc.w), isCompound: true,
                        ...this.cyto_w_style(String(n.sc.w)) }
                    : (() => { const r = this.cyto_node(n, id); return { id, label: r.label, isCompound: r.isCompound, ...r.style } })()

                // style properties spread directly onto C — no nested object
                const { id: _id, label, isCompound, ...style_props } = nd
                const C: TheC = parentC.i({
                    cyto_node:  1,
                    cyto_id:    id,
                    label:      label ?? '',
                    isCompound: isCompound ?? false,
                    parent_id:  (T.sc.up?.sc.cyto_id as string | null) ?? null,
                    ...style_props,
                })
                T.sc.C = C
                // n lives on T.sc.n (set by Se); make it easy to unpack from T.sc
            },

            trace_fn: async (uD: TheD, n: TheC) => {
                // encode primitive sc values as the_* for stable resolve() matching
                const sc: any = { cyto_node: 1 }
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

        // ref scan: multi-placed blue edges + migration advice onto C**
        await this.snap_scan_refs(Se, w, topC, new Set(neu_ids), goners_by_id)

        return topC
    },

    // recursively descend a goner D subtree, collecting all nested cyto_ids
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
        for (const child of D.o({ cyto_node: 1 }) as TheD[]) {
            this.cyto_collect_goner_ids(child, goner_ids, goners_by_id)
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
    ): Promise<void> {
        // n_to_Cs: TheC n ref → C[] (current positions)
        const n_to_Cs = new Map<TheC, TheC[]>()

        // single forward pass — T.sc holds {n, D, C} set by Se and our each_fn
        await Se.c.T.forward(async (T: Travel) => {
            const { n, D, C } = T.sc as { n: TheC; D: TheD; C: TheC | undefined }
            if (!n || !C) return

            // ref_stable: same TheC stayed in this D slot
            if (T.sc.bD?.c.T?.sc.n === n) {
                T.sc.ref_stable = true
                D.c.ref_stable  = true
            }

            const existing = n_to_Cs.get(n)
            if (existing) existing.push(C)
            else n_to_Cs.set(n, [C])
        })

        const blue_edge_sc = (source_id: string, target_id: string, directed: boolean) => ({
            cyto_edge:   1 as const,
            ref:         1 as const,
            source_id,
            target_id,
            ideal_length: 120,
            'line-color': '#4488ff',
            width:        1.2,
            'line-style': 'dashed',
            'target-arrow-shape': directed ? 'triangle' : 'none',
            'target-arrow-color': '#4488ff',
            'curve-style': 'bezier',
            opacity:       0.5,
        })

        // multi-placed: same n in >1 current C
        for (const [_n, Cs] of n_to_Cs) {
            if (Cs.length < 2) continue
            for (let i = 0; i < Cs.length - 1; i++) {
                const src = Cs[i].sc.cyto_id   as string
                const tgt = Cs[i+1].sc.cyto_id as string
                // edge hangs off the source C node
                Cs[i].i(blue_edge_sc(src, tgt, false))
            }
        }

        // migration: goner D whose n ref appears as a neu C
        for (const [gid, gD] of goners_by_id) {
            const n = gD.c.T?.sc.n as TheC | undefined
            if (!n) continue
            const curr_Cs = n_to_Cs.get(n) ?? []
            const neu_Cs  = curr_Cs.filter(C => neu_set.has(C.sc.cyto_id as string))
            if (!neu_Cs.length) continue

            const to_C  = neu_Cs[0]
            const to_id = to_C.sc.cyto_id as string
            // migration advice on destination C
            to_C.i({ cyto_migration: 1, from_id: gid, to_id })
            // directed blue edge: source is gone so park on topC with explicit source_id
            topC.i({ ...blue_edge_sc(gid, to_id, true), orphan_source: 1 })
        }
    },

//#endregion
//#region Se2 — assign stable edge ids across C%cyto_edge**

    async cyto_assign_edge_ids(w: TheC, topC: TheC): Promise<void> {
        w.c.cyto_Se2 ??= new Selection()
        const Se2: Selection = w.c.cyto_Se2
        Se2.sc.topD = await Se2.r({ cyto_root: 1 })

        await Se2.process({
            n:          topC,
            process_D:  Se2.sc.topD,
            match_sc:   { cyto_node: 1 },   // climb C%cyto_node**
            trace_sc:   { cyto_edge_D: 1 },  // D mirrors C%cyto_edge children

            each_fn: async (D: TheD, C_node: TheC, T: Travel) => {
                // for each C%cyto_node, process its cyto_edge children
                for (const edge_C of C_node.o({ cyto_edge: 1 }) as TheC[]) {
                    // trace_fn for edges handled inline via a mini replace()
                    await D.replace({ cyto_edge_D: 1,
                                      source_id: edge_C.sc.source_id ?? C_node.sc.cyto_id,
                                      target_id: edge_C.sc.target_id }, async () => {
                        const eD = D.i({ cyto_edge_D: 1,
                                          source_id: edge_C.sc.source_id ?? C_node.sc.cyto_id,
                                          target_id: edge_C.sc.target_id })
                        // stable edge id lives on eD.c, restored by resolve()
                        eD.c.stable_id ??= `e:${++w.c.id_counter}`
                        edge_C.sc.edge_id = eD.c.stable_id
                    })
                }
            },

            trace_fn: async (uD: TheD, C_node: TheC) => {
                return uD.i({ cyto_edge_D: 1, cyto_id: C_node.sc.cyto_id })
            },

            traced_fn: async () => {},
            resolved_fn: async () => {},
        })
    },

//#endregion
//#region Ze — make_wave: diff two C** → wave

    // C_from = previous CytoStep topC (null = first wave, assume empty canvas)
    // C_to   = arriving CytoStep topC
    // adjacent = true → include migration advice and full duration
    //            false → no migration, duration = 0 (jump)
    async make_wave(
        w:        TheC,
        C_from:   TheC | null,
        C_to:     TheC,
        adjacent: boolean,
    ): Promise<any> {
        w.c.cyto_Ze ??= new Selection()
        const Ze: Selection = w.c.cyto_Ze
        Ze.sc.topD = await Ze.r({ cyto_z: 1 })

        const upsert:      any[] = []
        const edge_upsert: any[] = []
        const remove:      string[] = []
        const edge_remove: string[] = []
        const migrate:     any[] = []

        // helper: read all style props off a C node (everything except controlled keys)
        const CTRL = new Set(['cyto_node','cyto_edge','cyto_root','cyto_id','label',
                               'isCompound','parent_id','edge_id','source_id','target_id',
                               'cyto_migration','ref','orphan_source','cyto_z'])
        const style_of = (C: TheC): Record<string,any> => {
            const s: Record<string,any> = {}
            for (const [k,v] of Object.entries(C.sc ?? {})) {
                if (!CTRL.has(k)) s[k] = v
            }
            return s
        }

        await Ze.process({
            n:          C_to,
            process_D:  Ze.sc.topD,
            match_sc:   { cyto_node: 1 },
            trace_sc:   { cyto_z: 1 },

            each_fn: async (D: TheD, C: TheC, T: Travel) => {
                const id = C.sc.cyto_id as string
                if (!id) { T.sc.not = 1; return }
                D.sc.cyto_id = id
            },

            trace_fn: async (uD: TheD, C: TheC) => {
                return uD.i({ cyto_z: 1, cyto_id: C.sc.cyto_id })
            },

            traced_fn: async (D: TheD, bD: TheD | undefined, C: TheC) => {
                const id = C.sc.cyto_id as string

                if (!bD || C_from == null) {
                    // new node — full upsert
                    upsert.push({
                        id,
                        label:      C.sc.label ?? '',
                        isCompound: C.sc.isCompound ?? false,
                        parent:     C.sc.parent_id ?? undefined,
                        style:      style_of(C),
                    })
                    // edges
                    for (const edge_C of C.o({ cyto_edge: 1 }) as TheC[]) {
                        if (!edge_C.sc.edge_id || edge_C.sc.orphan_source) continue
                        edge_upsert.push({
                            id:     edge_C.sc.edge_id as string,
                            source: edge_C.sc.source_id as string ?? id,
                            target: edge_C.sc.target_id as string,
                            style:  style_of(edge_C),
                            data:   { ideal_length: (edge_C.sc.ideal_length as number) ?? 80 },
                        })
                    }
                } else {
                    // existing node — diff style and structural props
                    const old_style = bD.c.style_snapshot ?? {}
                    const new_style = style_of(C)
                    const changed: Record<string,any> = {}
                    let has_change = false
                    for (const [k,v] of Object.entries(new_style)) {
                        if (old_style[k] !== v) { changed[k] = v; has_change = true }
                    }
                    const label_changed   = C.sc.label    !== bD.sc.label
                    const parent_changed  = C.sc.parent_id !== bD.sc.parent_id
                    if (has_change || label_changed || parent_changed) {
                        const nd: any = { id, style: changed }
                        if (label_changed)  nd.label      = C.sc.label
                        if (parent_changed) nd.new_parent  = C.sc.parent_id ?? null
                        upsert.push(nd)
                    }
                    // edges: simple re-upsert for now (stable ids, Se2 dedupes)
                    for (const edge_C of C.o({ cyto_edge: 1 }) as TheC[]) {
                        if (!edge_C.sc.edge_id || edge_C.sc.orphan_source) continue
                        edge_upsert.push({
                            id:     edge_C.sc.edge_id as string,
                            source: edge_C.sc.source_id as string ?? id,
                            target: edge_C.sc.target_id as string,
                            style:  style_of(edge_C),
                            data:   { ideal_length: (edge_C.sc.ideal_length as number) ?? 80 },
                        })
                    }
                }
                // snapshot current style for next tick's diff
                bD ? (bD.c.style_snapshot = style_of(C)) : (D.c.style_snapshot = style_of(C))
            },

            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                for (const g of goners) {
                    const gid = g.sc.cyto_id as string | undefined
                    if (gid) remove.push(gid)
                }
            },
        })

        // migration advice from C_to (adjacent steps only)
        if (adjacent) {
            const walk = (C: TheC) => {
                for (const mc of C.o({ cyto_migration: 1 }) as TheC[]) {
                    migrate.push({ id: mc.sc.from_id, toward: mc.sc.to_id,
                                   then_parent: mc.sc.parent_id ?? null })
                }
                for (const nc of C.o({ cyto_node: 1 }) as TheC[]) walk(nc)
            }
            walk(C_to)
        }

        return {
            upsert, edge_upsert,
            remove, edge_remove,
            migrate, constraints: null,
            duration: adjacent ? ((w.sc.grawave_duration as number) ?? 0.3) : 0,
        }
    },

//#endregion
//#region cytyle_classify / cytyle helpers

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
            return { id, label: String(n.sc.hand), isCompound: true, style }
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