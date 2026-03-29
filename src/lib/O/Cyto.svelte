<script lang="ts">
    // Cyto.svelte — ghost.
    //
    // ── Dip protocol ─────────────────────────────────────────────────────────
    //
    //   Dip_assign(scheme, D) — only D is passed; T reached via D.c.T.
    //   Parent D via D.c.T.up.sc.D.  Parent's Dip tracks sibling counter.
    //   Value = parent_value+'_'+sibling_i.  TopD gets Dip{value:scheme, i:0}
    //   on first child visit.  Before each Se pass, topD's Dip.sc.i is reset
    //   to 0 so sibling numbering restarts correctly each tick.
    //
    //   D/{Dip:scheme, value:'cytoid_0_1', i:0}
    //     Dip  = scheme identifier (for o() lookup)
    //     value = the actual id
    //     i     = next-child counter (incremented as children claim slots)
    //
    // ── Passes ───────────────────────────────────────────────────────────────
    //
    //   cyto_scan  (Se1) n=RunH → D** mirrors n**; scan_id on C; C.c.Se1_D=D
    //                    goners → Se1.c.scan_goners_by_id
    //
    //   cyto_assign_ids (Se2a) n=topC → cytoid Dip on nodes only; no forward yet
    //
    //   cyto_scan_refs → blue edges added to C** using node cyto_ids
    //
    //   cyto_assign_ids (Se2b) n=topC → cytoid Dip on new edges too;
    //                    forward(): parent/source/target C→_id; clear Se1_D
    //                    resolved_fn: goners → Se2.c.cyto_goners (for Ze)

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

        const topC = await this.cyto_scan(w, RunH)         // Se1
        await this.cyto_assign_ids(w, topC, false)          // Se2a: node ids
        await this.cyto_scan_refs(w, topC)                  // ref blue edges
        await this.cyto_assign_ids(w, topC, true)           // Se2b: edge ids + finalize
        const wave = await this.make_wave(w, topC, true)    // Ze

        const story_w = H.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0] as TheC | undefined
        const run     = story_w?.o({ run: 1 })[0] as TheC | undefined
        const step_n  = run?.sc.done as number | undefined
        wave.step_n   = step_n

        if (step_n != null && story_w) {
            const step_c = (story_w.c.This?.o({ Step: 1 }) as TheC[] | undefined)
                ?.find(s => s.sc.Step === step_n)
            if (step_c) { step_c.sc.CytoStep = topC; step_c.sc.CytoWave = null }
        }

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

    // Assign (or update) a branching hierarchical id on D.
    // Only D is passed — T is reached via D.c.T; parent D via D.c.T.up.sc.D.
    //
    //   D/{Dip:scheme, value:'cytoid_0_1', i:0}
    //   Parent's Dip.sc.i counts children claimed so far this tick.
    //   Call Se_reset_dips(topD, scheme) before each Se pass to reset counters.

    Dip_assign(scheme: 'scanid' | 'cytoid', D: TheD): string {
        const parent_D = D.c.T?.up?.sc.D as TheD | undefined

        // find or init parent's Dip (topD gets one on first child visit)
        let uDip = parent_D?.o({ Dip: scheme })[0] as TheC | undefined
        if (!uDip && parent_D) uDip = parent_D.i({ Dip: scheme, value: scheme, i: 0 })

        // claim next sibling index from parent
        const i = (uDip?.sc.i as number) ?? 0
        if (uDip) uDip.sc.i = i + 1
        const value = `${uDip?.sc.value ?? scheme}_${i}`

        // update or create own Dip; reset children counter to 0
        const dip = D.o({ Dip: scheme })[0] as TheC | undefined
        if (dip) { dip.sc.value = value; dip.sc.i = 0 }
        else       D.i({ Dip: scheme, value, i: 0 })
        return value
    },

    // Reset Dip sibling counter on topD before each Se pass so sibling
    // numbering restarts at 0.  topD itself is never visited in each_fn.
    Se_reset_dips(topD: TheD, scheme: 'scanid' | 'cytoid') {
        for (const d of topD.o({ Dip: scheme }) as TheC[]) d.sc.i = 0
    },

//#endregion
//#region Se1 — cyto_scan

    async cyto_scan(w: TheC, RunH: House): Promise<TheC> {
        w.c.cyto_Se ??= new Selection()
        const Se: Selection = w.c.cyto_Se
        Se.sc.topD = await Se.r({ cyto_root: 1 })
        this.Se_reset_dips(Se.sc.topD, 'scanid')

        const topC: TheC = _C({ cyto_root: 1 })
        const prev_scan_ids: Set<string> = w.c.prev_scan_ids ?? new Set()
        const neu_scan_ids: string[] = []

        Se.c.scan_goners_by_id = new Map<string, TheD>()

        await Se.process({
            n:          RunH,
            process_D:  Se.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                const cls = this.cytyle_classify(n)
                if (cls === 'skip') { T.sc.not = 1; return }
                if (cls === 'invisible') { T.sc.C = T.sc.up?.sc.C ?? topC; return }

                const scan_id = this.Dip_assign('scanid', D)
                D.oai({ n_ref: 1 }).sc.n = n

                const parentC: TheC = T.sc.up?.sc.C ?? topC
                const nd = this.cyto_node(n)

                const C: TheC = parentC.i({
                    cyto_node:  1,
                    scan_id,
                    label:      nd.label,
                    isCompound: nd.isCompound ?? false,
                    parent:     parentC,   // C ref → converted to parent_id in Se2b
                    style:      nd.style,
                })
                C.c.Se1_D = D   // link to Se1 D for ref detection
                T.sc.C = C

                if (!prev_scan_ids.has(scan_id)) neu_scan_ids.push(scan_id)
            },

            trace_fn: async (uD: TheD, n: TheC) => {
                const sc: any = { tracing: 1 }
                for (const [k, v] of Object.entries(n.sc ?? {}))
                    if (typeof v !== 'object' && typeof v !== 'function') sc[`the_${k}`] = v
                return uD.i(sc)
            },

            traced_fn: async () => {},

            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                for (const g of goners) this.cyto_collect_goner_scan_ids(g, Se.c.scan_goners_by_id)
            },
        })

        Se.c.neu_scan_ids = new Set(neu_scan_ids)

        // track scan_ids for next tick's neu detection
        const all = new Set<string>()
        const coll = (C: TheC) => {
            for (const nc of C.o({ cyto_node: 1 }) as TheC[]) { all.add(nc.sc.scan_id as string); coll(nc) }
        }
        coll(topC)
        w.c.prev_scan_ids = all

        return topC
    },

    cyto_collect_goner_scan_ids(D: TheD, by_id: Map<string, TheD>): void {
        const id = D.o({ Dip: 'scanid' })[0]?.sc.value as string | undefined
        if (id && !by_id.has(id)) by_id.set(id, D)
        for (const child of D.o({ tracing: 1 }) as TheD[])
            this.cyto_collect_goner_scan_ids(child, by_id)
    },

//#endregion
//#region cyto_assign_ids (Se2a / Se2b)

    // Se2a (finalize=false): assigns cytoid Dips to C%cyto_node only — nodes must
    //   have cyto_ids before cyto_scan_refs can name edge endpoints.
    //
    // Se2b (finalize=true): assigns cytoid Dips to everything (including new ref
    //   edges from cyto_scan_refs); collects goners; runs forward() to:
    //     • convert parent/source/target C refs → _id strings
    //     • remove C.c.Se1_D links (keep C** low-memory)

    async cyto_assign_ids(w: TheC, topC: TheC, finalize: boolean): Promise<void> {
        w.c.cyto_Se2 ??= new Selection()
        const Se2: Selection = w.c.cyto_Se2
        Se2.sc.topD = await Se2.r({ cyto_edge_root: 1 })
        this.Se_reset_dips(Se2.sc.topD, 'cytoid')

        if (finalize) Se2.c.cyto_goners = [] as string[]

        await Se2.process({
            n:          topC,
            process_D:  Se2.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, C: TheC, T: Travel) => {
                if (!finalize && C.sc.cyto_edge) { T.sc.not = 1; return }  // Se2a skips edges
                const cyto_id = this.Dip_assign('cytoid', D)
                if (C.sc.cyto_node) C.sc.cyto_id = cyto_id
                if (C.sc.cyto_edge) C.sc.edge_id  = cyto_id
            },

            trace_fn: async (uD: TheD, C: TheC) => {
                if (C.sc.cyto_node) return uD.i({ tracing: 1, the_scan_id: C.sc.scan_id ?? '' })
                if (C.sc.cyto_edge) {
                    // trace on resolved endpoint ids; fall back to C ref if available
                    const src = typeof C.sc.source === 'object'
                        ? (C.sc.source as TheC).sc.cyto_id ?? ''
                        : C.sc.source_id ?? ''
                    const tgt = typeof C.sc.target === 'object'
                        ? (C.sc.target as TheC).sc.cyto_id ?? ''
                        : C.sc.target_id ?? ''
                    return uD.i({ tracing: 1, the_source_id: src, the_target_id: tgt })
                }
                return uD.i({ tracing: 1 })
            },

            traced_fn: async () => {},

            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                if (!finalize) return
                for (const g of goners) {
                    const id = g.o({ Dip: 'cytoid' })[0]?.sc.value as string | undefined
                    if (id) (Se2.c.cyto_goners as string[]).push(id)
                }
            },
        })

        if (!finalize) return

        // Se2b forward(): resolve C refs → _id; clear Se1_D links
        await Se2.c.T.forward(async (T: Travel) => {
            const C = T.sc.n as TheC; if (!C) return

            // parent C → parent_id
            if (C.sc.parent && typeof C.sc.parent === 'object' && C.sc.parent !== topC) {
                C.sc.parent_id = (C.sc.parent as TheC).sc.cyto_id ?? null
            }
            delete C.sc.parent

            // edge source/target C → _id
            for (const edge_C of C.o({ cyto_edge: 1 }) as TheC[]) {
                if (edge_C.sc.source && typeof edge_C.sc.source === 'object') {
                    edge_C.sc.source_id = (edge_C.sc.source as TheC).sc.cyto_id ?? null
                    delete edge_C.sc.source
                }
                if (edge_C.sc.target && typeof edge_C.sc.target === 'object') {
                    edge_C.sc.target_id = (edge_C.sc.target as TheC).sc.cyto_id ?? null
                    delete edge_C.sc.target
                }
            }

            delete C.c.Se1_D
        })
    },

//#endregion
//#region cyto_scan_refs

    // Runs after Se2a (nodes have cyto_ids) and before Se2b (edges need ids).
    // Reads C.c.Se1_D to get n refs for migration detection.
    // Adds blue cyto_edge children to C nodes (multi-placed) and topC (migration).
    // Se2b will assign ids to these new edges and clear Se1_D links.

    async cyto_scan_refs(w: TheC, topC: TheC): Promise<void> {
        const Se1 = w.c.cyto_Se as Selection
        const goners_by_id: Map<string, TheD> = Se1.c.scan_goners_by_id ?? new Map()
        const neu_set:       Set<string>       = Se1.c.neu_scan_ids      ?? new Set()

        // build n → C[] map from current C** nodes
        const n_to_Cs = new Map<TheC, TheC[]>()
        const walk = (C: TheC) => {
            for (const nc of C.o({ cyto_node: 1 }) as TheC[]) {
                const n = (nc.c.Se1_D as TheD | undefined)?.o({ n_ref: 1 })[0]?.sc.n as TheC | undefined
                if (n) { const a = n_to_Cs.get(n); if (a) a.push(nc); else n_to_Cs.set(n, [nc]) }
                walk(nc)
            }
        }
        walk(topC)

        const blue_sc = (src_id: string, tgt_id: string, directed: boolean, opts: any = {}) => ({
            cyto_edge: 1 as const, ref: 1 as const,
            source_id: src_id, target_id: tgt_id,
            ideal_length: 120,
            style: {
                'line-color': '#4488ff', width: 1.2, 'line-style': 'dashed',
                'target-arrow-shape': directed ? 'triangle' : 'none',
                'target-arrow-color': '#4488ff', 'curve-style': 'bezier', opacity: 0.5,
            },
            ...opts,
        })

        // multi-placed: same n in >1 current C — undirected blue edges
        for (const [_n, Cs] of n_to_Cs) {
            if (Cs.length < 2) continue
            for (let i = 0; i < Cs.length - 1; i++)
                Cs[i].i(blue_sc(Cs[i].sc.cyto_id as string, Cs[i+1].sc.cyto_id as string, false))
        }

        // migration: goner (by scan_id) whose n appears as a neu C
        for (const [gid, gD] of goners_by_id) {
            const n = gD.o({ n_ref: 1 })[0]?.sc.n as TheC | undefined; if (!n) continue
            const neu_Cs = (n_to_Cs.get(n) ?? []).filter(C => neu_set.has(C.sc.scan_id as string))
            if (!neu_Cs.length) continue
            const to_C  = neu_Cs[0]
            const to_id = to_C.sc.cyto_id as string
            to_C.i({ cyto_migration: 1, from_scan_id: gid, to_id })
            // orphan source edge parked on topC — source_id is scan_id for now
            topC.i(blue_sc(gid, to_id, true, { orphan_source: 1 }))
        }
    },

//#endregion
//#region Ze — make_wave

    async make_wave(w: TheC, topC: TheC, adjacent: boolean): Promise<any> {
        w.c.cyto_Ze ??= new Selection()
        const Ze: Selection = w.c.cyto_Ze
        Ze.sc.topD = await Ze.r({ cyto_z: 1 })

        const UPSERT = true

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
                if (C.sc.cyto_edge) return uD.i({ tracing: 1, the_edge_id:  C.sc.edge_id  ?? '' })
                if (C.sc.cyto_node) return uD.i({ tracing: 1, the_cyto_id:  C.sc.cyto_id  ?? '' })
                return uD.i({ tracing: 1 })
            },

            traced_fn: async (D: TheD, bD: TheD | undefined, C: TheC) => {
                if (!C.sc.cyto_node && !C.sc.cyto_edge) return
                const snap_C = D.oai({ snapshot: 1 })

                if (C.sc.cyto_edge) {
                    const eid = C.sc.edge_id as string
                    if (!eid || C.sc.orphan_source) return
                    if (UPSERT || !bD) {
                        edge_upsert.push({ id: eid, source: C.sc.source_id as string,
                            target: C.sc.target_id as string, style: C.sc.style ?? {},
                            data: { ideal_length: (C.sc.ideal_length as number) ?? 80 } })
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
                            parent: C.sc.parent_id ?? undefined,
                            style: C.sc.style ?? {} })
                    } else {
                        const old   = JSON.parse(snap_C.sc.snap as string ?? '{}')
                        const nw    = C.sc.style as Record<string,any> ?? {}
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
                    if (g.sc.is_edge) { if (g.sc.the_edge_id)  edge_remove.push(g.sc.the_edge_id as string) }
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
        if (s.self || s.chaFrom || s.wasLast || s.sunny_streak || s.seen
            || s.o_elvis || s.cyto_node || s.cyto_root || s.cyto_tracking
            || s.wave_data || s.refs || s.snap_node || s.snap_root
            || s.housed || s.run || s.Se || s.inst || s.began_wanting
            || s.CytoStep || s.CytoWave || s.tracing || s.Dip || s.n_ref
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

    cyto_node(n: TheC): any {
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