<script lang="ts">
    // Cyto.svelte — ghost depositing Cyto worker methods onto H.* via eatfunc.
    //
    // Phase 1: Se.process() based scanning + ref reidentification blue edges.
    // Domain-specific styles (cyto_id/cyto_node/cyto_w_style) preserved from v1.
    //
    // ── Se scan ───────────────────────────────────────────────────────────────
    //   Se.process() walks RunH/** generically.  cytyle_classify() decides
    //   how each particle is treated:
    //     'skip'      — T.sc.not=1; don't graph or traverse children
    //     'invisible' — traverse children but emit no node (H, A containers)
    //     'compound'  — %w particles become compound parent nodes
    //     null        — normal node; cyto_id/cyto_node determine style + id
    //
    //   trace_fn encodes primitive sc values as the_* identity keys so
    //   resolve() can stably match D particles across ticks even when all
    //   share trace_sc={cyto_node:1}.
    //
    //   D.sc.cyto_id is written in each_fn so resolved_fn goners can report
    //   which ids are leaving the graph.
    //
    // ── Ref reidentification ──────────────────────────────────────────────────
    //   refs_C (w.oai({refs:1})) accumulates {ref:TheC, D:TheD, cyto_id:string}
    //   particles.  For each n in each_fn, refs_C.o({ref:n}) is queried BEFORE
    //   inserting the current tick's entry.  If any previous entry exists and
    //   its cyto_id differs from the current id, a blue dashed edge is drawn
    //   connecting the two positions.  These ref_edges are cleared each tick.
    //
    // ── Wave format ───────────────────────────────────────────────────────────
    //   Same as v1 (upsert/edge_upsert/remove/edge_remove/migrate/constraints/
    //   duration/step_n) so Cytui.svelte is unchanged.
    //   ref_edge ids are tracked in w.c.prev_ref_eids and always removed next tick.
    //
    // ── w:Cyto/** Stuffing output ─────────────────────────────────────────────
    //   {wave_data:1} particle written each tick for Stuffing inspection.

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
        w.c.plan_done = true
        w.sc.grawave_duration ??= 2
    },

    async cyto_update_wave(w: TheC): Promise<boolean> {
        const H = this as House
        // find the active Run sub-House generically — Story sets Run.sc.Run = 1
        const RunH = (H.o({ H: 1 }) as House[]).find(h => h.sc.Run) as House | undefined
        if (!RunH) return false

        const tracking = w.oai({ cyto_tracking: 1 })
        const v = RunH.version
        if (tracking.sc.v === v) return true   // nothing changed, skip rebuild
        tracking.sc.v = v

        const wave = await this.cyto_scan(w, RunH)

        // tag with current story step
        const story_w = H.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0] as TheC | undefined
        wave.step_n   = story_w?.o({ run: 1 })[0]?.sc.done as number | undefined

        const gn = w.c.gn as TheC
        if (!gn) return false
        gn.sc.wave = wave
        gn.sc.tick = ((gn.sc.tick as number) ?? 0) + 1
        ;(H.o({ watched: 'graph' })[0] as TheC)?.bump_version()

        // store wave summary in w/** for Stuffing inspection
        await w.replace({ wave_data: 1 }, async () => {
            w.i({ wave_data:    1,
                  nodes:        wave.upsert.length,
                  edges:        wave.edge_upsert.length,
                  removing:     wave.remove.length,
                  ref_edges:    (w.c.prev_ref_eids ?? []).length,
                  step_n:       wave.step_n ?? null,
            })
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
//#region cyto_scan — Se.process() based

    async cyto_scan(w: TheC, RunH: House) {
        // Se retains D** identity continuity across ticks
        w.c.cyto_Se ??= new Selection()
        const Se: Selection = w.c.cyto_Se

        // refs_C accumulates {ref:TheC, cyto_id:string} across all ticks
        // used to detect when the same C ref appears in a new location
        const refs_C: TheC = w.oai({ refs: 1 })

        const prev_ids  = new Set<string>(w.c.prev_ids  ?? [])
        const prev_eids = new Set<string>(w.c.prev_eids ?? [])
        // ref edges from last tick are always removed — they're rebuilt fresh
        const prev_ref_eids: string[] = w.c.prev_ref_eids ?? []

        const upsert:      any[] = []
        const edge_upsert: any[] = []
        const seen      = new Set<string>()
        const seen_e    = new Set<string>()
        const goner_ids: string[] = []

        await Se.process({
            n:          RunH,
            process_sc: { cyto_root: 1 },
            match_sc:   {},
            trace_sc:   { cyto_node: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                const cls = this.cytyle_classify(n)
                if (cls === 'skip')      { T.sc.not = 1; return }
                if (cls === 'invisible') { T.sc.cyto_id = null;  return }

                let id: string
                let nd: any

                if (cls === 'compound') {
                    // %w → compound worker node
                    id = `w:${n.sc.w}`
                    nd = {
                        id,
                        label: String(n.sc.w),
                        style: this.cyto_w_style(String(n.sc.w)),
                        isCompound: true,
                    }
                } else {
                    // normal node — reuse v1 cyto_id / cyto_node
                    const wname = this.cytyle_wname(T)
                    id = this.cyto_id(n, wname)
                    if (!id) { T.sc.not = 1; return }
                    nd = this.cyto_node(n, id)
                }

                T.sc.cyto_id = id
                D.sc.cyto_id = id   // so goners can report their id in resolved_fn
                seen.add(id)

                // parent = nearest ancestor T whose cyto_id is non-null
                const parent_id = this.cytyle_parent_id(T)
                if (parent_id) nd.parent = parent_id

                upsert.push(nd)

                // ── ref reidentification ──────────────────────────────────────
                // query BEFORE inserting current tick's entry so we only see past
                const prev_entries = refs_C.o({ ref: n }) as TheC[]
                if (prev_entries.length > 0) {
                    const prev_id = prev_entries[prev_entries.length - 1].sc.cyto_id as string
                    if (prev_id && prev_id !== id) {
                        // same C ref, different position — draw a blue connector
                        const eid = `ref:${prev_id}:${id}`
                        if (!seen_e.has(eid)) {
                            seen_e.add(eid)
                            edge_upsert.push({
                                id: eid, source: prev_id, target: id,
                                style: {
                                    'line-color': '#4488ff', width: 1.4,
                                    'line-style': 'dashed', 'target-arrow-shape': 'none',
                                    'curve-style': 'bezier', opacity: 0.6,
                                },
                            })
                        }
                    }
                }
                // record this position for future ticks
                refs_C.i({ ref: n, cyto_id: id })
            },

            // encode primitive sc values as the_* so resolve() matches D across ticks
            trace_fn: async (uD: TheD, n: TheC) => {
                const sc: any = { cyto_node: 1 }
                for (const [k, v] of Object.entries(n.sc ?? {})) {
                    if (typeof v !== 'object' && typeof v !== 'function') sc[`the_${k}`] = v
                }
                return uD.i(sc)
            },

            traced_fn: async () => {},

            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                for (const g of goners) {
                    const gid = g.sc.cyto_id as string | undefined
                    if (gid && !seen.has(gid)) goner_ids.push(gid)
                }
            },
        })

        // remove prev ref edges; new ones are in edge_upsert
        const edge_remove = prev_ref_eids

        const remove = [...prev_ids].filter(id => !seen.has(id))

        w.c.prev_ids     = [...seen]
        w.c.prev_eids    = [...seen_e]
        w.c.prev_ref_eids = [...seen_e]   // ref edges rebuilt every tick

        return {
            upsert, edge_upsert,
            remove, edge_remove,
            migrate: [], constraints: null,
            duration: (w.sc.grawave_duration as number) ?? 0.3,
        }
    },

//#endregion
//#region cytyle helpers

    // simple classifier — no rule DSL yet, just direct key checks
    cytyle_classify(n: TheC): 'skip' | 'invisible' | 'compound' | null {
        const s = n.sc
        // bookkeeping noise — skip entirely
        if (s.self || s.chaFrom || s.wasLast || s.sunny_streak || s.seen
            || s.o_elvis || s.cyto_node || s.cyto_root || s.cyto_tracking
            || s.wave_data || s.refs || s.snap_node || s.snap_root
            || s.housed || s.run || s.Se || s.inst || s.began_wanting) return 'skip'
        // structural containers — traverse but don't graph
        if (s.H || s.A) return 'invisible'
        // %w → compound worker node (%Cytyles:Agency)
        if (s.w) return 'compound'
        return null
    },

    // walk up T chain to find the nearest ancestor that contributed a graph node
    cytyle_parent_id(T: Travel): string | undefined {
        let up = T.sc.up as Travel | undefined
        while (up) {
            if (up.sc.cyto_id) return String(up.sc.cyto_id)
            up = up.sc.up as Travel | undefined
        }
        return undefined
    },

    // walk up T chain to find the nearest ancestor %w name (for cyto_id disambiguation)
    cytyle_wname(T: Travel): string | undefined {
        let up = T.sc.up as Travel | undefined
        while (up) {
            if (up.sc.n?.sc?.w) return String(up.sc.n.sc.w)
            up = up.sc.up as Travel | undefined
        }
        return undefined
    },

//#endregion
//#region cyto_id — preserved from v1

    cyto_id(n: TheC, wname?: string): string | null {
        if (n.sc.mouthful && n.sc.mouthful_id) return `mf:${n.sc.mouthful_id}`
        if (n.sc.leaf)                          return `leaf:${n.sc.leaf_id ?? n.sc.leaf}`
        if (n.sc.sunshine)                      return wname ? `sun:${wname}` : `sun`
        if (n.sc.poo)                           return `poo`
        if (n.sc.material)                      return `mat:${n.sc.material}`
        if (n.sc.producing)                     return `prod`
        if (n.sc.protein)                       return `prot:${n.sc.protein_id ?? 'p'}`
        if (n.sc.shelf && n.sc.enzyme)          return `enz_shelf`
        if (n.sc.wants_enzyme)                  return `want_enz`
        if (n.sc.wants_to_produce)              return `want_prod`
        if (n.sc.hand !== undefined)            return `hand:${wname ?? 'w'}:${n.sc.hand}`
        return null
    },

//#endregion
//#region cyto_label / hsl2rgb / cyto_node / cyto_w_style — preserved from v1

    cyto_label(n: TheC): string {
        const parts: string[] = []
        for (const [k, v] of Object.entries(n.sc ?? {})) {
            if (typeof v === 'number')                   parts.push(`${k}:${Math.round(v*100)/100}`)
            else if (typeof v === 'boolean')             parts.push(k)
            else if (typeof v === 'string' && v !== '1') parts.push(`${k}:${v.length>11?v.slice(0,9)+'…':v}`)
        }
        return parts.join('\n')
    },

    hsl2rgb(h: number, s: number, l: number): string {
        s /= 100; l /= 100
        const c = (1-Math.abs(2*l-1))*s, x = c*(1-Math.abs(((h/60)%2)-1)), m = l-c/2
        let r=0,g=0,b=0
        if      (h<60)  {r=c;g=x} else if (h<120) {r=x;g=c}
        else if (h<180) {g=c;b=x} else if (h<240) {g=x;b=c}
        else if (h<300) {r=x;b=c} else            {r=c;b=x}
        return `rgb(${Math.round((r+m)*255)},${Math.round((g+m)*255)},${Math.round((b+m)*255)})`
    },

    cyto_node(n: TheC, id: string): any {
        const label = this.cyto_label(n)
        const style: any = {}
        if (n.sc.mouthful) {
            const d=(n.sc.dose as number)??0, sz=Math.round(6+d*40)
            style['background-color']=this.hsl2rgb(72,80,62); style.width=sz; style.height=sz
            style.shape='ellipse'; style.opacity=0.82; style.color='#003300'
        } else if (n.sc.leaf) {
            const d=(n.sc.dose as number)??0, sz=Math.round(14+d*16), lt=Math.round(28+d*12)
            style['background-color']=this.hsl2rgb(120,55,lt); style.width=sz; style.height=sz
            style.shape='ellipse'; style.color=d>1.4?'#001800':'#b0ffb0'
        } else if (n.sc.sunshine) {
            const d=(n.sc.dose as number)??0, sz=Math.round(22+d*22), lt=Math.round(42+d*18)
            style['background-color']=this.hsl2rgb(46,90,lt); style.width=sz; style.height=sz
            style.shape='diamond'; style.color='#331800'
        } else if (n.sc.poo) {
            const d=(n.sc.dose as number)??0, sz=Math.round(18+Math.min(d,8)*2.5)
            style['background-color']='#5c3010'; style.width=sz; style.height=sz
            style.shape='ellipse'; style.color='#c88040'
        } else if (n.sc.material) {
            const amt=(n.sc.amount as number)??0, sz=Math.round(18+Math.min(amt,20)*1.6)
            style['background-color']=this.hsl2rgb(33,52,20+Math.min(amt,20)*1.5)
            style.width=sz; style.height=sz; style.shape='round-rectangle'; style.color='#ffe8c0'
        } else if (n.sc.producing) {
            style['background-color']='#142060'; style.width=42; style.height=42
            style.shape='round-rectangle'; style.color='#9ab4ff'
        } else if (n.sc.protein) {
            const cx=(n.sc.complexity as number)??0, sz=Math.round(18+cx*4.5)
            style['background-color']=this.hsl2rgb(276,40,22+cx*5)
            style.width=sz; style.height=sz; style.shape='hexagon'; style.color='#ddc8ff'
        } else if (n.sc.shelf && n.sc.enzyme) {
            const u=(n.sc.units as number)??0
            style['background-color']='#1a4828'; style.width=Math.round(20+u*2.5); style.height=20
            style.shape='round-rectangle'; style.color='#90ffc0'
        } else if (n.sc.wants_enzyme || n.sc.wants_to_produce) {
            style['background-color']='#6a1a08'; style.width=22; style.height=22
            style.shape='star'; style.color='#ff9070'
        } else if (n.sc.hand !== undefined) {
            // %hand — sub-compound for LeafJuggle
            style['background-color']='#1a1a28'; style['background-opacity']=0.6
            style['border-color']='#5a5a9a'; style['border-width']=1; style['border-style']='solid'
            style.padding='7px'; style['font-size']='8px'; style['font-style']='italic'
            style.color='#8888bb'; style['text-valign']='top'
            return { id, label: String(n.sc.hand), style, isCompound: true }
        } else {
            style['background-color']='#242424'; style.width=16; style.height=16; style.color='#666'
        }
        return { id, label, style }
    },

    cyto_w_style(wname: string): any {
        const bg:     Record<string,string> = { farm:'#0a1f0a', plate:'#1f130a', enzymeco:'#0a0a1f',
                                                 Yin:'#1a0a1a', Yang:'#1a1a0a' }
        const border: Record<string,string> = { farm:'#2a5a1a', plate:'#5a3a1a', enzymeco:'#1a1a5a',
                                                 Yin:'#5a1a5a', Yang:'#5a5a1a' }
        const color:  Record<string,string> = { farm:'#4a6a4a', plate:'#6a5a4a', enzymeco:'#4a4a6a',
                                                 Yin:'#8a4a8a', Yang:'#8a8a4a' }
        return {
            'background-color':   bg[wname]     ?? '#181818',
            'background-opacity': 0.5,
            'border-color':       border[wname] ?? '#2a2a2a',
            'border-width': 1, 'border-style': 'dashed',
            'text-valign': 'top', 'text-halign': 'center',
            padding: '12px', 'font-size': '9px',
            'font-weight': 'bold', 'font-style': 'italic',
            color: color[wname] ?? '#4a6a4a',
        }
    },

//#endregion
//#region intoCyto handshake — preserved from v1

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