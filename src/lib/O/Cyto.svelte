<script lang="ts">
    // Cyto.svelte — ghost depositing Cyto worker methods onto H.* via eatfunc.
    //
    // ── Se scan architecture ──────────────────────────────────────────────────
    //
    //   Se.process() walks RunH/** generically, building D** mirrors of n**.
    //   trace_fn stores n on D.c.n so ref comparisons work across ticks.
    //
    //   After process(), a forward() pass calls snap_scan_refs() which:
    //     1. Detects T.sc.ref_stable — bD.c.n === D.c.n, same particle stayed
    //        in same D slot.  No animation needed.
    //     2. Detects multi-placed — same n appears in more than one current D.
    //        These get a loose blue edge between them.
    //     3. Detects migration — a goner D whose n ref appears as a neu D
    //        elsewhere.  Marks both for animate-and-reparent.
    //
    //   D.replace({cyto_edge:1}) stores the edges this node wants.
    //   This is the canonical per-step graph state.
    //
    // ── Canonical state + direction-sensitive waves ───────────────────────────
    //
    //   After scan, a memory-safe snapshot is kept:
    //     mD = D-clones stored in w.c.snap_mDs (array, one per step)
    //   Each mD holds:
    //     mD.sc = {...D.sc}           — the stable cyto_id, label, etc
    //     mD.c.n = D.c.n              — the original n ref (for seek migration)
    //     mD.c.edges = D.o({cyto_edge:1}) — edges as of this step
    //
    //   When seeking, a Ze (second Selection instance, w.c.cyto_Ze) runs
    //   Ze.process() over the target step's mD** rather than live RunH.
    //   This derives a wave for any step without re-running the simulation.
    //
    //   Direction:
    //     forward  — upsert new nodes/edges, remove goners
    //     backward — restore prior mD**, remove what was added since
    //     jump     — rebuild from scratch at dur=0 (no migration animation)
    //   Only the forward (live) wave is normally produced.
    //   The first wave goes into got_snap (the canonical record).
    //
    // ── Cytui.svelte ─────────────────────────────────────────────────────────
    //   Unchanged from v1.  Wave format is compatible:
    //   upsert / edge_upsert / remove / edge_remove / migrate / constraints /
    //   duration / step_n.
    //   ref edges (blue) arrive in edge_upsert and are cleared next tick via
    //   edge_remove.

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
        const RunH = (H.o({ H: 1 }) as House[]).find(h => h.sc.Run) as House | undefined
        if (!RunH) return false

        const tracking = w.oai({ cyto_tracking: 1 })
        const v = RunH.version
        if (tracking.sc.v === v) return true
        tracking.sc.v = v

        const wave = await this.cyto_scan(w, RunH)

        const story_w = H.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0] as TheC | undefined
        wave.step_n   = story_w?.o({ run: 1 })[0]?.sc.done as number | undefined

        const gn = w.c.gn as TheC
        if (!gn) return false
        gn.sc.wave = wave
        gn.sc.tick = ((gn.sc.tick as number) ?? 0) + 1
        ;(H.o({ watched: 'graph' })[0] as TheC)?.bump_version()

        await w.replace({ wave_data: 1 }, async () => {
            w.i({ wave_data: 1,
                  nodes:    wave.upsert.length,
                  edges:    wave.edge_upsert.length,
                  removing: wave.remove.length,
                  step_n:   wave.step_n ?? null,
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
//#region cyto_scan

    async cyto_scan(w: TheC, RunH: House) {
        w.c.cyto_Se ??= new Selection()
        const Se: Selection = w.c.cyto_Se

        const prev_ids:      Set<string>  = w.c.prev_ids      ?? new Set()
        const prev_eids:     Set<string>  = w.c.prev_eids     ?? new Set()
        const prev_ref_eids: string[]     = w.c.prev_ref_eids ?? []

        const upsert:      any[] = []
        const edge_upsert: any[] = []
        const seen      = new Set<string>()
        const seen_e    = new Set<string>()
        const goner_ids: string[] = []
        const neu_ids:   string[] = []   // ids added this tick (were not in prev_ids)

        // ── Se.process(): build D** mirroring n** ─────────────────────────────
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
                    id = `w:${n.sc.w}`
                    nd = { id, label: String(n.sc.w), style: this.cyto_w_style(String(n.sc.w)), isCompound: true }
                } else {
                    const wname = this.cytyle_wname(T)
                    id = this.cyto_id(n, wname)
                    if (!id) { T.sc.not = 1; return }
                    nd = this.cyto_node(n, id)
                }

                T.sc.cyto_id = id
                D.sc.cyto_id = id
                // store n ref on D for ref detection in snap_scan_refs()
                D.c.n = n
                seen.add(id)

                const parent_id = this.cytyle_parent_id(T)
                if (parent_id) nd.parent = parent_id
                upsert.push(nd)

                if (!prev_ids.has(id)) neu_ids.push(id)
            },

            trace_fn: async (uD: TheD, n: TheC) => {
                // encode primitive sc values as the_* so resolve() can stably
                // match D particles across ticks despite all sharing {cyto_node:1}
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

        // ── ref scan: forward pass over D** after process() is complete ───────
        // snap_scan_refs() populates edge_upsert with blue ref-edges,
        // and D.c.ref_stable / D.c.ref_migration for future animation use.
        await this.snap_scan_refs(Se, w, neu_ids, goner_ids, edge_upsert, seen_e)

        // ── remove prev ref edges; new ones are in edge_upsert ────────────────
        const edge_remove = prev_ref_eids

        const remove = [...prev_ids].filter(id => !seen.has(id))

        w.c.prev_ids      = new Set(seen)
        w.c.prev_eids     = new Set(seen_e)
        w.c.prev_ref_eids = [...seen_e].filter(id => id.startsWith('ref:'))

        return {
            upsert, edge_upsert,
            remove, edge_remove,
            migrate: [], constraints: null,
            duration: (w.sc.grawave_duration as number) ?? 0.3,
        }
    },

//#endregion
//#region snap_scan_refs

    // Forward pass over D** after Se.process().
    //
    // Three ref patterns detected:
    //
    //   ref_stable:   bD.c.n === D.c.n
    //                 Same TheC in same D slot across ticks. No animation needed.
    //                 Set T.sc.ref_stable = true for downstream use.
    //
    //   multi_placed: The same TheC n currently appears in more than one D.
    //                 Collect via a Map<TheC, string[]> (n → [cyto_id...]).
    //                 Emit a loose blue edge between every pair.
    //
    //   migration:    A goner D (id in goner_ids) has D.c.n that also appears
    //                 as a neu D (id in neu_ids) — the ref moved.
    //                 Mark D.c.ref_migration = { from, to } on the neu D.
    //                 Emit a directed blue edge from → to.
    //
    // All blue edges get ids starting with "ref:" so they can be cleared
    // from edge_remove at the start of the next tick.

    async snap_scan_refs(
        Se:          Selection,
        w:           TheC,
        neu_ids:     string[],
        goner_ids:   string[],
        edge_upsert: any[],
        seen_e:      Set<string>,
    ) {
        const neu_set   = new Set(neu_ids)
        const goner_set = new Set(goner_ids)

        // build maps from this tick's D** forward pass
        // n_to_ids:  TheC → cyto_id[] (detects multi-placed)
        // id_to_n:   cyto_id → TheC   (detects goner migration)
        const n_to_ids  = new Map<TheC, string[]>()
        const id_to_n   = new Map<string, TheC>()

        await Se.c.T.forward(async (T: Travel) => {
            const D = T.sc.D
            if (!D) return
            const id  = D.sc.cyto_id as string | undefined
            const n   = D.c.n        as TheC   | undefined
            if (!id || !n) return

            // ref_stable: same n stayed in this D slot
            const bD = T.sc.bD
            if (bD?.c.n === n) {
                T.sc.ref_stable = true
                D.c.ref_stable  = true
            }

            // accumulate n → ids
            const existing = n_to_ids.get(n)
            if (existing) existing.push(id)
            else n_to_ids.set(n, [id])

            id_to_n.set(id, n)
        })

        const blue_edge = (eid: string, source: string, target: string, directed = false) => ({
            id: eid, source, target,
            data: { ideal_length: 120 },
            style: {
                'line-color': '#4488ff', width: 1.2,
                'line-style': 'dashed',
                'target-arrow-shape': directed ? 'triangle' : 'none',
                'target-arrow-color': '#4488ff',
                'curve-style': 'bezier', opacity: 0.5,
            },
        })

        // ── multi-placed: same n in >1 current D ─────────────────────────────
        for (const [_n, ids] of n_to_ids) {
            if (ids.length < 2) continue
            // connect adjacent pairs (keeps edge count manageable for 3+ placements)
            for (let i = 0; i < ids.length - 1; i++) {
                const eid = `ref:multi:${ids[i]}:${ids[i+1]}`
                if (!seen_e.has(eid)) {
                    seen_e.add(eid)
                    edge_upsert.push(blue_edge(eid, ids[i], ids[i+1]))
                }
            }
        }

        // ── migration: goner D whose n is now a neu D elsewhere ───────────────
        // Walk goner_ids, look up their n via id_to_n (built above covers current Ds,
        // so we need the previous tick's map for goners).
        // Conveniently D.c.n was stored during each_fn and persists on the D object
        // even after it becomes a goner — D** is still in Se's tree until next process().
        await Se.c.T.forward(async (T: Travel) => {
            // only consider Ds that are *gone* this tick (their id is in goner_ids)
            // but their D object is still reachable in T.sc.bD of a matched node
            const bD = T.sc.bD
            if (!bD) return
            const gid = bD.sc.cyto_id as string | undefined
            if (!gid || !goner_set.has(gid)) return

            const n = bD.c.n as TheC | undefined
            if (!n) return

            // is this n currently present somewhere new?
            const curr_ids = n_to_ids.get(n) ?? []
            const new_ids  = curr_ids.filter(id => neu_set.has(id))
            if (!new_ids.length) return

            const to_id = new_ids[0]
            // mark on the destination D for future animation wiring
            const dest_D = id_to_n.get(to_id)   // value is TheC n, not D — rethink:
            // < ideally we'd mark the destination D, but we only have n→id mapping here.
            // For now just record on goner bD and emit the directed blue edge.
            bD.c.ref_migration = { from: gid, to: to_id }

            const eid = `ref:migrate:${gid}:${to_id}`
            if (!seen_e.has(eid)) {
                seen_e.add(eid)
                edge_upsert.push(blue_edge(eid, gid, to_id, true))
            }
        })
    },

//#endregion
//#region cytyle helpers

    cytyle_classify(n: TheC): 'skip' | 'invisible' | 'compound' | null {
        const s = n.sc
        if (s.self || s.chaFrom || s.wasLast || s.sunny_streak || s.seen
            || s.o_elvis || s.cyto_node || s.cyto_root || s.cyto_tracking
            || s.wave_data || s.refs || s.snap_node || s.snap_root
            || s.housed || s.run || s.Se || s.inst || s.began_wanting) return 'skip'
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
//#region cyto_id / cyto_label / hsl2rgb / cyto_node / cyto_w_style — from v1

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