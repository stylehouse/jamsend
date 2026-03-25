<script lang="ts">
    // Cyto.svelte — ghost depositing Cyto worker methods onto H.* via eatfunc.
    //
    // w:Cyto scans RunH each tick, builds a Wave, and deposits it into a
    // {cyto_graph:1} particle watched by Cytui.svelte.
    //
    // ── changes from original ─────────────────────────────────────────────────
    //
    //   • Worker compound nodes are always emitted (upsert) even when empty,
    //     so enzymeco stays visible throughout, not just when it has children.
    //
    //   • Plate edges added:
    //       mouthful → spawning leaf  (bite origin arc)
    //       leaf     → mat:basic      (consumption direction)
    //       protein  → enz_shelf      (enzyme processes protein)
    //
    //   • Auto-fit after layout: relayout() attaches a one-shot 'layoutstop'
    //     listener that calls cy.fit(cy.nodes(), 16) so the graph fills the
    //     container rather than sitting as a small island.

    import { TheC }       from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount }    from "svelte"
    import Cytui          from "./ui/Cytui.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region w:Cyto

    async Cyto(A: TheC, w: TheC) {
        if (!w.c.plan_done) this.Cyto_plan(w)
        const ok = this.cyto_update_wave(w)
        if (!ok) return w.i({ see: '⏳ no H:LeafFarm yet' })
        w.i({ see: `📊 tick:${w.c.gn?.sc.tick ?? 0}` })
    },

    Cyto_plan(w: TheC) {
        const uis  = this.oai_enroll(this, { watched: 'UIs' })
        uis.oai({ UI: 'Cyto', component: Cytui })
        const wa   = this.oai_enroll(this, { watched: 'graph' })
        w.c.gn     = wa.oai({ cyto_graph: 1 })
        w.c.plan_done = true
        // wave.duration: both the Cytui animation window and the Story pause length.
        w.sc.grawave_duration ??= 2
    },

    cyto_update_wave(w: TheC): boolean {
        const H    = this as House
        const RunH = H.o({ H: 'LeafFarm' })[0] as House | undefined
        if (!RunH) return false
        const tracking = w.oai({ cyto_tracking: 1 })
        const v = RunH.version
        if (tracking.sc.v === v) return true
        tracking.sc.v = v
        const wave = this.cyto_scan(w, RunH)
        const gn   = w.c.gn as TheC
        if (!gn) return false
        gn.sc.wave = wave
        gn.sc.tick = ((gn.sc.tick as number) ?? 0) + 1
        const wa   = H.o({ watched: 'graph' })[0] as TheC
        wa?.bump_version()
        return true
    },

    // ── cyto_scan ────────────────────────────────────────────────────────────
    //
    //   Produces a full wave per tick.  Worker compound nodes are always
    //   emitted first (even when empty) so compounds like w:enzymeco remain
    //   visible throughout the simulation.  Content nodes are emitted after.
    //
    //   Edges built per worker:
    //     farm:   stem (leaf→poo), helio (leaf→sun)
    //     plate:  bite (mouthful→leaf via spawning_from),
    //             consume (leaf→mat:basic),
    //             process (protein→enz_shelf)
    //     all:    relativePlacementConstraint left-of chain for worker order

    cyto_scan(w: TheC, RunH: House) {
        const pn        = w.oai({ cyto_prev_ids:  1 })
        const pe        = w.oai({ cyto_prev_eids: 1 })
        const prev_ids  = new Set<string>(pn.sc.ids  ?? [])
        const prev_eids = new Set<string>(pe.sc.ids  ?? [])
        const prev_ref:  Map<TheC, {wid:string, id:string}> = w.c.ref_map  ?? new Map()
        const prev_leaf: Map<string, string>                 = w.c.leaf_map ?? new Map()
        const prev_mf:   Set<string>                         = w.c.mf_ids   ?? new Set()

        const curr_ref  = new Map<TheC, {wid:string, id:string}>()
        const curr_leaf = new Map<string, string>()
        const curr_mf   = new Set<string>()

        const upsert: any[] = [], edge_upsert: any[] = []
        const seen = new Set<string>(), seen_e = new Set<string>()
        const migrate: any[] = []
        const w_order: string[] = []
        const rel: any[] = []

        let mat_node_id: string | null = null

        for (const A of RunH.o({ A: 1 }) as TheC[]) {
            for (const wk of A.o({ w: 1 }) as TheC[]) {
                const wid   = `w:${wk.sc.w}`
                const wname = String(wk.sc.w)
                seen.add(wid)
                w_order.push(wid)

                // ── always emit the worker compound ───────────────────
                // isCompound:true ensures Cytoscape keeps the container
                // even when it has no child nodes.  Previously the node
                // was only pushed when there were children, so empty
                // workers like w:enzymeco (idle between batches) vanished.
                upsert.push({
                    id: wid,
                    label: wname,
                    style: this.cyto_w_style(wname),
                    isCompound: true,
                })

                // per-worker positioning helpers
                let poo_id:  string | null = null
                let sun_id:  string | null = null
                const leaf_ids: string[] = []

                for (const n of wk.o({}) as TheC[]) {
                    if (n.c.drop) continue
                    const id = this.cyto_id(n)
                    if (!id) continue

                    const is_new      = !prev_ids.has(id)
                    const prev_entry  = prev_ref.get(n)
                    const is_reparent = prev_entry && prev_entry.wid !== wid

                    seen.add(id)
                    curr_ref.set(n, { wid, id })
                    if (n.sc.leaf && n.sc.leaf_id)         curr_leaf.set(String(n.sc.leaf_id), wid)
                    if (n.sc.mouthful && n.sc.mouthful_id)  curr_mf.add(id)
                    if (n.sc.material === 'basic')           mat_node_id = id

                    const nd = this.cyto_node(n, id)
                    nd.parent = wid
                    if (is_reparent) nd.new_parent = wid

                    // new mouthfuls teleport to their spawning leaf position
                    if (is_new && n.sc.mouthful && n.sc.spawning_from) {
                        nd.appear_from = `leaf:${n.sc.spawning_from}`
                    }
                    upsert.push(nd)

                    if (n.sc.poo)      poo_id = id
                    if (n.sc.sunshine) sun_id = id
                    if (n.sc.leaf)     leaf_ids.push(id)
                }

                // ── farm edges ────────────────────────────────────────
                if (wname === 'farm') {
                    // vertical placement: sun → leaves → poo
                    if (sun_id && poo_id) rel.push({ top: sun_id, bottom: poo_id, gap: 55 })
                    for (const lid of leaf_ids) {
                        if (sun_id) rel.push({ top: sun_id, bottom: lid,    gap: 20 })
                        if (poo_id) rel.push({ top: lid,    bottom: poo_id, gap: 14 })
                    }
                    // stem: leaf → poo (stature-weighted)
                    if (poo_id) {
                        for (const n of wk.o({ leaf: 1 }) as TheC[]) {
                            if (n.c.drop) continue
                            const lid = this.cyto_id(n)
                            if (!lid) continue
                            const dose    = (n.sc.dose as number) ?? 0
                            const stature = Math.min(dose / 2.0, 1.0)
                            const eid     = `e:stem:${lid}`
                            seen_e.add(eid)
                            edge_upsert.push({
                                id: eid, source: lid, target: poo_id,
                                data: { ideal_length: Math.max(18, Math.round(18 + stature * 55)) },
                                style: {
                                    'line-color':   '#3d7a1e',
                                    width:          Math.max(0.5, 0.8 + stature * 1.8),
                                    'line-style':   'solid',
                                    'target-arrow-shape': 'none',
                                    'curve-style':  'straight',
                                    opacity: 0.5 + stature * 0.38,
                                },
                            })
                        }
                    }
                    // helio: leaf → sun (loose, dashed)
                    if (sun_id) {
                        for (const n of wk.o({ leaf: 1 }) as TheC[]) {
                            if (n.c.drop) continue
                            const lid = this.cyto_id(n)
                            if (!lid) continue
                            const eid = `e:helio:${lid}`
                            seen_e.add(eid)
                            edge_upsert.push({
                                id: eid, source: lid, target: sun_id,
                                data: { ideal_length: 110 },
                                style: {
                                    'line-color': '#c8b020', width: 0.6,
                                    'line-style': 'dashed',
                                    'target-arrow-shape': 'none',
                                    'curve-style': 'bezier',
                                    opacity: 0.18,
                                },
                            })
                        }
                    }
                }

                // ── plate edges ───────────────────────────────────────
                if (wname === 'plate') {
                    // bite arc: mouthful → its spawning leaf
                    // shows visually where each bite originated
                    for (const n of wk.o({ mouthful: 1 }) as TheC[]) {
                        if (n.c.drop) continue
                        const mid = this.cyto_id(n)
                        if (!mid) continue
                        const lid = `leaf:${n.sc.spawning_from}`
                        if (!seen.has(lid)) continue   // leaf may have just left
                        const eid = `e:bite:${mid}`
                        seen_e.add(eid)
                        edge_upsert.push({
                            id: eid, source: lid, target: mid,
                            data: { ideal_length: 24 },
                            style: {
                                'line-color': '#af5',
                                width: 0.8,
                                'line-style': 'dotted',
                                'target-arrow-shape': 'triangle',
                                'target-arrow-color': '#af5',
                                'curve-style': 'bezier',
                                opacity: 0.55,
                            },
                        })
                    }

                    // consume arc: leaf → mat:basic (drift direction of biomass)
                    if (mat_node_id) {
                        for (const n of wk.o({ leaf: 1 }) as TheC[]) {
                            if (n.c.drop) continue
                            const lid = this.cyto_id(n)
                            if (!lid) continue
                            const eid = `e:consume:${lid}`
                            seen_e.add(eid)
                            edge_upsert.push({
                                id: eid, source: lid, target: mat_node_id,
                                data: { ideal_length: 60 },
                                style: {
                                    'line-color': '#b82',
                                    width: 0.7,
                                    'line-style': 'dashed',
                                    'target-arrow-shape': 'triangle',
                                    'target-arrow-color': '#b82',
                                    'curve-style': 'bezier',
                                    opacity: 0.25,
                                },
                            })
                        }
                    }

                    // process arc: protein → enzyme shelf
                    // shows which resource is needed for breakdown
                    const enz_id = 'enz_shelf'
                    if (seen.has(enz_id)) {
                        for (const n of wk.o({ protein: 1 }) as TheC[]) {
                            if (n.c.drop) continue
                            const pid = this.cyto_id(n)
                            if (!pid) continue
                            const eid = `e:process:${pid}`
                            seen_e.add(eid)
                            edge_upsert.push({
                                id: eid, source: pid, target: enz_id,
                                data: { ideal_length: 40 },
                                style: {
                                    'line-color': '#4a8',
                                    width: 0.9,
                                    'line-style': 'dashed',
                                    'target-arrow-shape': 'triangle',
                                    'target-arrow-color': '#4a8',
                                    'curve-style': 'bezier',
                                    opacity: 0.5,
                                },
                            })
                        }
                    }
                }
            }
        }

        // leaf harvest migrations
        const mat_toward = mat_node_id ?? 'mat:basic'
        for (const [lid, _prev_wid] of prev_leaf) {
            if (!curr_leaf.has(lid)) {
                migrate.push({ id: `leaf:${lid}`, toward: mat_toward, harvest_detach: true })
            }
        }

        // mouthful expiry migrations
        for (const mf_id of prev_mf) {
            if (!curr_mf.has(mf_id)) {
                migrate.push({ id: mf_id, toward: mat_toward, mouthful_expire: true })
            }
        }

        // ref re-parent migrations
        for (const [n, { wid, id }] of curr_ref) {
            const prev = prev_ref.get(n)
            if (prev && prev.wid !== wid && !migrate.find(m => m.id === id)) {
                migrate.push({ id, toward: wid, then_parent: wid })
            }
        }

        pn.sc.ids  = [...seen]
        pe.sc.ids  = [...seen_e]
        w.c.ref_map  = curr_ref
        w.c.leaf_map = curr_leaf
        w.c.mf_ids   = curr_mf

        const migrating_ids = new Set(migrate.map(m => m.id))
        const remove      = [...prev_ids].filter(id => !seen.has(id) && !migrating_ids.has(id))
        const edge_remove = [...prev_eids].filter(id => !seen_e.has(id))

        // left-of constraints keep workers in spawn order
        for (let i = 0; i < w_order.length - 1; i++) {
            rel.push({ left: w_order[i], right: w_order[i + 1], gap: 24 })
        }
        const constraints = rel.length ? { relativePlacementConstraint: rel } : null

        return { upsert, edge_upsert, remove, edge_remove, migrate, constraints,
                 duration: (w.sc.grawave_duration as number) ?? 0.3 }
    },

//#endregion
//#region cyto_id

    cyto_id(n: TheC): string | null {
        if (n.sc.mouthful && n.sc.mouthful_id) return `mf:${n.sc.mouthful_id}`
        if (n.sc.leaf)                          return `leaf:${n.sc.leaf_id ?? n.sc.leaf}`
        if (n.sc.sunshine)                      return `sun`
        if (n.sc.poo)                           return `poo`
        if (n.sc.material)                      return `mat:${n.sc.material}`
        if (n.sc.producing)                     return `prod`
        if (n.sc.protein)                       return `prot:${n.sc.protein_id ?? 'p'}`
        if (n.sc.shelf && n.sc.enzyme)          return `enz_shelf`
        if (n.sc.wants_enzyme)                  return `want_enz`
        if (n.sc.wants_to_produce)              return `want_prod`
        if (n.sc.run)                           return `run:${n.sc.run}`
        // noise — skip self-ref bookkeeping particles
        if (n.sc.self || n.sc.chaFrom || n.sc.wasLast || n.sc.sunny_streak
            || n.sc.seen || n.sc.o_elvis)       return null
        return null
    },

//#endregion
//#region cyto_label

    // Compact label: numbers rounded to 2 dp, long strings truncated.
    cyto_label(n: TheC): string {
        const parts: string[] = []
        for (const [k, v] of Object.entries(n.sc ?? {})) {
            if (typeof v === 'number') {
                parts.push(`${k}:${Math.round(v * 100) / 100}`)
            } else if (typeof v === 'boolean') {
                parts.push(k)
            } else if (typeof v === 'string' && v !== '1') {
                parts.push(`${k}:${v.length > 11 ? v.slice(0, 9) + '…' : v}`)
            }
        }
        return parts.join('\n')
    },

//#endregion
//#region hsl2rgb

    // Cytoscape can animate rgb() but not hsl().  Convert at build time.
    hsl2rgb(h: number, s: number, l: number): string {
        s /= 100; l /= 100
        const c = (1 - Math.abs(2 * l - 1)) * s
        const x = c * (1 - Math.abs(((h / 60) % 2) - 1))
        const m = l - c / 2
        let r = 0, g = 0, b = 0
        if      (h < 60)  { r = c; g = x; b = 0 }
        else if (h < 120) { r = x; g = c; b = 0 }
        else if (h < 180) { r = 0; g = c; b = x }
        else if (h < 240) { r = 0; g = x; b = c }
        else if (h < 300) { r = x; g = 0; b = c }
        else              { r = c; g = 0; b = x }
        return `rgb(${Math.round((r+m)*255)},${Math.round((g+m)*255)},${Math.round((b+m)*255)})`
    },

//#endregion
//#region cyto_node

    cyto_node(n: TheC, id: string): any {
        const label = this.cyto_label(n)
        const style: any = {}

        if (n.sc.mouthful) {
            const d  = (n.sc.dose as number) ?? 0
            const sz = Math.round(6 + d * 40)
            style['background-color'] = this.hsl2rgb(72, 80, 62)
            style.width = sz; style.height = sz; style.shape = 'ellipse'
            style.opacity = 0.82
            style.color   = '#003300'

        } else if (n.sc.leaf) {
            const d  = (n.sc.dose as number) ?? 0
            const sz = Math.round(14 + d * 16)
            const lt = Math.round(28 + d * 12)
            style['background-color'] = this.hsl2rgb(120, 55, lt)
            style.width = sz; style.height = sz; style.shape = 'ellipse'
            style.color = d > 1.4 ? '#001800' : '#b0ffb0'

        } else if (n.sc.sunshine) {
            const d  = (n.sc.dose as number) ?? 0
            const sz = Math.round(22 + d * 22)
            const lt = Math.round(42 + d * 18)
            style['background-color'] = this.hsl2rgb(46, 90, lt)
            style.width = sz; style.height = sz; style.shape = 'diamond'
            style.color = '#331800'

        } else if (n.sc.poo) {
            const d  = (n.sc.dose as number) ?? 0
            const sz = Math.round(18 + Math.min(d, 8) * 2.5)
            style['background-color'] = '#5c3010'
            style.width = sz; style.height = sz; style.shape = 'ellipse'
            style.color = '#c88040'

        } else if (n.sc.material) {
            const amt = (n.sc.amount as number) ?? 0
            const sz  = Math.round(18 + Math.min(amt, 20) * 1.6)
            style['background-color'] = this.hsl2rgb(33, 52, 20 + Math.min(amt, 20) * 1.5)
            style.width = sz; style.height = sz; style.shape = 'round-rectangle'
            style.color = '#ffe8c0'

        } else if (n.sc.producing) {
            style['background-color'] = '#142060'
            style.width = 42; style.height = 42; style.shape = 'round-rectangle'
            style.color = '#9ab4ff'

        } else if (n.sc.protein) {
            const cx = (n.sc.complexity as number) ?? 0
            const sz = Math.round(18 + cx * 4.5)
            style['background-color'] = this.hsl2rgb(276, 40, 22 + cx * 5)
            style.width = sz; style.height = sz; style.shape = 'hexagon'
            style.color = '#ddc8ff'

        } else if (n.sc.shelf && n.sc.enzyme) {
            const u = (n.sc.units as number) ?? 0
            style['background-color'] = '#1a4828'
            style.width = Math.round(20 + u * 2.5); style.height = 20
            style.shape = 'round-rectangle'; style.color = '#90ffc0'

        } else if (n.sc.wants_enzyme || n.sc.wants_to_produce) {
            style['background-color'] = '#6a1a08'
            style.width = 22; style.height = 22; style.shape = 'star'
            style.color = '#ff9070'

        } else if (n.sc.run) {
            style['background-color'] = '#101028'
            style.width = 44; style.height = 18; style.shape = 'round-rectangle'
            style.color = '#7888ff'

        } else {
            style['background-color'] = '#242424'
            style.width = 16; style.height = 16
            style.color = '#666'
        }
        return { id, label, style }
    },

//#endregion
//#region cyto_w_style

    cyto_w_style(wname: string): any {
        const bg: Record<string,string>     = { farm: '#0a1f0a', plate: '#1f130a', enzymeco: '#0a0a1f' }
        const border: Record<string,string> = { farm: '#2a5a1a', plate: '#5a3a1a', enzymeco: '#1a1a5a' }
        return {
            'background-color':   bg[wname]     ?? '#181818',
            'background-opacity': 0.5,
            'border-color':       border[wname] ?? '#2a2a2a',
            'border-width':       1, 'border-style': 'dashed',
            'text-valign': 'top', 'text-halign': 'center',
            padding: '12px', 'font-size': '9px',
            'font-weight': 'bold', 'font-style': 'italic',
            color: '#4a6a4a',
        }
    },

//#endregion
//#region intoCyto handshake

    async story_cyto_step(A: TheC, w: TheC, e: TheC) {
        this.cyto_update_wave(w)
        const dur = ((w.sc.grawave_duration as number) ?? 0.3) * 1000
        setTimeout(() => {
            this.elvisto('Story/Story', 'story_cyto_continue', { story_step: e?.sc.story_step })
        }, dur + 100)
    },

//#endregion

    })
    })
</script>