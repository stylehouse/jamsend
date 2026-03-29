<script lang="ts">
    // Cyto.svelte — ghost. Three Se passes:
    //
    //   Se1  n=RunH, process_D=Se.sc.topD
    //        → D** mirrors n**; C** built with style:{} nested; node Dip ids in D/**
    //
    //   Se2  n=topC, process_D=Se2.sc.topD
    //        → D** mirrors C**; assigns stable edge ids from D/**{Dip:1}
    //
    //   Ze   n=topC, process_D=Ze.sc.topD
    //        → diffs current C** vs previous D**/bD → wave
    //        UPSERT=true: always emit full descriptions (v1-compatible, safe)
    //        UPSERT=false: emit only changed props (turn on once stable)
    //
    //   All topDs replaced every tick via Se.r({...}) → fresh .c.T, D/** preserved.
    //   Stable ids live in D/**{Dip:1, value:'c:N'} — survive replace() via resume_X.
    //   gn.bump_version() notifies Cytui (gn lives in %watched:graph).
    //   Style is a nested object on C: C.sc.style = {...css props}.

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

        const topC = await this.cyto_scan(w, RunH)        // Se1 + Se2
        const wave = await this.make_wave(w, topC, true)  // Ze

        const story_w = H.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0] as TheC | undefined
        const run     = story_w?.o({ run: 1 })[0] as TheC | undefined
        const step_n  = run?.sc.done as number | undefined
        wave.step_n   = step_n
        await w.r({CytoStep:topC,wave,step_n})

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
        gn.bump_version()   // gn is in %watched:graph; Cytui subscribes to gn.version

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
//#region Se1 — cyto_scan: D** + C** from RunH

    async cyto_scan(w: TheC, RunH: House): Promise<TheC> {
        w.c.cyto_Se ??= new Selection()
        const Se: Selection = w.c.cyto_Se
        // replace topD every tick: fresh .c.T, D/** preserved via resume_X
        Se.sc.topD = await Se.r({ cyto_root: 1 })

        const topC: TheC    = _C({ cyto_root: 1 })
        const prev_ids: Set<string> = w.c.prev_ids ?? new Set()
        const neu_ids:    string[] = []
        const goner_ids:  string[] = []
        const goners_by_id = new Map<string, TheD>()

        await Se.process({
            n:          RunH,
            process_D:  Se.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                const cls = this.cytyle_classify(n)
                if (cls === 'skip') { T.sc.not = 1; return }

                if (cls === 'invisible') {
                    // absorb into parent: children will land inside T.up's C
                    T.sc.C       = T.sc.up?.sc.C ?? topC
                    T.sc.cyto_id = null
                    return
                }

                // stable id from D/**{Dip:1} — survives Se replace() via resume_X
                let dip = D.o({ Dip: 1 })[0]
                if (!dip) dip = D.i({ Dip: 1, value: `c:${++w.c.id_counter}` })
                const id = dip.sc.value as string
                T.sc.cyto_id = id

                // persist n ref in D/** for goner migration detection next tick
                D.oai({ n_ref: 1 }).sc.n = n

                const parentC: TheC = T.sc.up?.sc.C ?? topC
                const nd = cls === 'compound'
                    ? { label: String(n.sc.w), isCompound: true,
                        style: this.cyto_w_style(String(n.sc.w)) }
                    : (() => { const r = this.cyto_node(n); return { label: r.label, isCompound: r.isCompound ?? false, style: r.style } })()

                // style is a nested object — no spreading CSS props onto C directly
                const C: TheC = parentC.i({
                    cyto_node:  1,
                    cyto_id:    id,
                    label:      nd.label,
                    isCompound: nd.isCompound,
                    parent_id:  (T.sc.up?.sc.cyto_id as string | null) ?? null,
                    style:      nd.style,
                })
                T.sc.C = C

                if (!prev_ids.has(id)) neu_ids.push(id)
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
                for (const g of goners) {
                    this.cyto_collect_goner_ids(g, goner_ids, goners_by_id)
                }
            },
        })

        // track all current ids for next tick's neu detection
        const all_ids = new Set<string>()
        const collect_ids = (C: TheC) => {
            for (const nc of C.o({ cyto_node: 1 }) as TheC[]) {
                all_ids.add(nc.sc.cyto_id as string)
                collect_ids(nc)
            }
        }
        collect_ids(topC)
        w.c.prev_ids = all_ids

        await this.snap_scan_refs(Se, w, topC, new Set(neu_ids), goners_by_id)
        
        await this.cyto_assign_edge_ids(w, topC)

        return topC
    },

    // recursively descend a goner D subtree collecting all Dip ids
    cyto_collect_goner_ids(
        D:            TheD,
        goner_ids:    string[],
        goners_by_id: Map<string, TheD>,
    ): void {
        const id = D.o({ Dip: 1 })[0]?.sc.value as string | undefined
        if (id && !goners_by_id.has(id)) {
            goner_ids.push(id)
            goners_by_id.set(id, D)
        }
        for (const child of D.o({ tracing: 1 }) as TheD[]) {
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
        const n_to_Cs = new Map<TheC, TheC[]>()

        await Se.c.T.forward(async (T: Travel) => {
            const { n, D, C } = T.sc as { n: TheC; D: TheD; C: TheC | undefined }
            if (!n || !C) return

            // ref_stable: same TheC n stayed in same D slot across ticks
            const prev_n = D.o({ n_ref: 1 })[0]?.sc.n as TheC | undefined
            if (prev_n === n) {
                T.sc.ref_stable = true
                D.c.ref_stable  = true
            }

            const existing = n_to_Cs.get(n)
            if (existing) existing.push(C)
            else n_to_Cs.set(n, [C])
        })

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
        })

        // multi-placed: same n in >1 current C → undirected blue edges
        for (const [_n, Cs] of n_to_Cs) {
            if (Cs.length < 2) continue
            for (let i = 0; i < Cs.length - 1; i++) {
                Cs[i].i(blue_edge_sc(
                    Cs[i].sc.cyto_id   as string,
                    Cs[i+1].sc.cyto_id as string,
                    false,
                ))
            }
        }

        // migration: goner whose n ref appears as a neu C elsewhere
        // blue edge as ropeway during the animation; migration advice on dest C
        for (const [gid, gD] of goners_by_id) {
            const n = gD.o({ n_ref: 1 })[0]?.sc.n as TheC | undefined
            if (!n) continue
            const curr_Cs = n_to_Cs.get(n) ?? []
            const neu_Cs  = curr_Cs.filter(C => neu_set.has(C.sc.cyto_id as string))
            if (!neu_Cs.length) continue

            const to_C  = neu_Cs[0]
            const to_id = to_C.sc.cyto_id as string
            to_C.i({ cyto_migration: 1, from_id: gid, to_id })
            // source is gone → park orphan edge on topC with explicit source_id
            topC.i({ ...blue_edge_sc(gid, to_id, true), orphan_source: 1 })
        }
    },

//#endregion
//#region Se2 — assign stable edge ids across C%cyto_edge**

    async cyto_assign_edge_ids(w: TheC, topC: TheC): Promise<void> {
        w.c.cyto_Se2 ??= new Selection()
        const Se2: Selection = w.c.cyto_Se2
        Se2.sc.topD = await Se2.r({ cyto_edge_root: 1 })

        await Se2.process({
            n:          topC,
            process_D:  Se2.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                // Dip for every C node and edge — branching namespace like an IP path.
                // Parent Dip lives on T.sc.up's D; root gets 'r'.
                // D/{Dip:1} survives replace() via resume_X.
                const parent_dip_val = (T.sc.up?.sc.D as TheD | undefined)
                    ?.o({ Dip: 1 })[0]?.sc.Dip as string | undefined ?? 'r'

                let dip = D.o({ Dip: 1 })[0]
                if (!dip) {
                    // find or create a sibling counter on parent
                    const parent_D = T.sc.up?.sc.D as TheD | undefined ?? Se2.sc.topD as TheD
                    const counter  = parent_D.oai({ dip_counter: 1 })
                    const i        = (counter.sc.i as number) ?? 0
                    counter.sc.i   = i + 1
                    dip = D.i({ Dip: 1, value: `${parent_dip_val}_${i}` })
                }

                // assign edge_id for cyto_edge particles
                if (n.sc.cyto_edge) {
                    n.sc.edge_id = dip.sc.value as string
                }
            },

            trace_fn: async (uD: TheD, n: TheC) => {
                // trace on Dip value if present, else on semantic identity
                const dip = uD.o({ Dip: 1 })[0]?.sc.value as string | undefined
                if (dip) return uD.i({ tracing: 1, the_Dip: dip })
                if (n.sc.cyto_edge) return uD.i({ tracing: 1,
                    the_source_id: n.sc.source_id ?? '', the_target_id: n.sc.target_id ?? '' })
                if (n.sc.cyto_node) return uD.i({ tracing: 1, the_cyto_id: n.sc.cyto_id ?? '' })
                return uD.i({ tracing: 1 })
            },

            traced_fn:   async () => {},
            resolved_fn: async () => {},
        })
    },

//#endregion
//#region Ze — make_wave

    async make_wave(w: TheC, topC: TheC, adjacent: boolean): Promise<any> {
        w.c.cyto_Ze ??= new Selection()
        const Ze: Selection = w.c.cyto_Ze
        Ze.sc.topD = await Ze.r({ cyto_z: 1 })

        const UPSERT = true   // < flip false for minimal diff mode once stable

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
                // only process nodes and edges; skip cyto_root, migration, etc
                if (!n.sc.cyto_node && !n.sc.cyto_edge) { T.sc.not = 1; return }
                D.sc.is_edge = !!n.sc.cyto_edge
            },

            trace_fn: async (uD: TheD, n: TheC) => {
                if (n.sc.cyto_edge)  return uD.i({ tracing: 1, the_edge_id:  n.sc.edge_id  ?? '' })
                if (n.sc.cyto_node)  return uD.i({ tracing: 1, the_cyto_id:  n.sc.cyto_id  ?? '' })
                return uD.i({ tracing: 1 })
            },

            traced_fn: async (D: TheD, bD: TheD | undefined, n: TheC) => {
                if (!n.sc.cyto_node && !n.sc.cyto_edge) return
                const snap_C = D.oai({ snapshot: 1 })

                if (n.sc.cyto_edge) {
                    const eid = n.sc.edge_id as string
                    if (!eid || n.sc.orphan_source) return
                    if (UPSERT || !bD) {
                        edge_upsert.push({
                            id:     eid,
                            source: n.sc.source_id as string,
                            target: n.sc.target_id as string,
                            style:  n.sc.style ?? {},
                            data:   { ideal_length: (n.sc.ideal_length as number) ?? 80 },
                        })
                    } else {
                        const old_style = JSON.parse(snap_C.sc.snap as string ?? '{}')
                        const new_style = n.sc.style as Record<string,any> ?? {}
                        const changed: any = {}; let has = false
                        for (const [k,v] of Object.entries(new_style)) {
                            if (old_style[k] !== v) { changed[k] = v; has = true }
                        }
                        if (has) edge_upsert.push({ id: eid, style: changed })
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
                        const old_style = JSON.parse(snap_C.sc.snap as string ?? '{}')
                        const new_style = n.sc.style as Record<string,any> ?? {}
                        const changed: any = {}; let has = false
                        for (const [k,v] of Object.entries(new_style)) {
                            if (old_style[k] !== v) { changed[k] = v; has = true }
                        }
                        const label_ch  = n.sc.label     !== snap_C.sc.label
                        const parent_ch = n.sc.parent_id !== snap_C.sc.parent
                        if (has || label_ch || parent_ch) {
                            const nd: any = { id, style: changed }
                            if (label_ch)  nd.label      = n.sc.label
                            if (parent_ch) nd.new_parent = n.sc.parent_id ?? null
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
                    if (g.sc.is_edge) {
                        if (g.sc.the_edge_id) edge_remove.push(g.sc.the_edge_id as string)
                    } else {
                        if (g.sc.the_cyto_id) remove.push(g.sc.the_cyto_id as string)
                    }
                }
            },
        })

        // migration advice from C** (adjacent steps only)
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
            || s.snapshot) return 'skip'
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

    // returns {label, isCompound?, style:{...css}} — no id (Se1 supplies that)
    cyto_node(n: TheC): any {
        const cls   = this.cytyle_classify(n)
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