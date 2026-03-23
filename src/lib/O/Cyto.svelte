<script lang="ts">
    import { TheC }       from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount }    from "svelte"
    import Cytui          from "./ui/Cytui.svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

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

    cyto_scan(w: TheC, RunH: House) {
        const pn   = w.oai({ cyto_prev_ids:  1 })
        const pe   = w.oai({ cyto_prev_eids: 1 })
        const prev_ids  = new Set<string>(pn.sc.ids  ?? [])
        const prev_eids = new Set<string>(pe.sc.ids  ?? [])
        const prev_ref:  Map<TheC, {wid:string, id:string}> = w.c.ref_map  ?? new Map()
        const prev_leaf: Map<string, string>                 = w.c.leaf_map ?? new Map()
        const curr_ref  = new Map<TheC, {wid:string, id:string}>()
        const curr_leaf = new Map<string, string>()

        const upsert: any[] = [], edge_upsert: any[] = []
        const seen = new Set<string>(), seen_e = new Set<string>()
        const migrate: any[] = []
        const w_order: string[] = []

        for (const A of RunH.o({ A: 1 }) as TheC[]) {
            for (const wk of A.o({ w: 1 }) as TheC[]) {
                const wid   = `w:${wk.sc.w}`
                const wname = String(wk.sc.w)
                seen.add(wid)
                w_order.push(wid)
                upsert.push({ id: wid, label: wname, style: this.cyto_w_style(wname), isCompound: true })

                let poo_id: string | null = null
                let sun_id: string | null = null

                for (const n of wk.o({}) as TheC[]) {
                    if (n.c.drop) continue
                    const id = this.cyto_id(n)
                    if (!id) continue
                    const prev_entry  = prev_ref.get(n)
                    const is_reparent = prev_entry && prev_entry.wid !== wid
                    seen.add(id)
                    curr_ref.set(n, { wid, id })
                    const nd = this.cyto_node(n, id)
                    nd.parent = wid
                    if (is_reparent) { nd.new_parent = wid; nd.migrate_from_wid = prev_entry!.wid }
                    upsert.push(nd)
                    if (n.sc.leaf && n.sc.leaf_id) curr_leaf.set(String(n.sc.leaf_id), wid)
                    if (n.sc.poo)      poo_id = id
                    if (n.sc.sunshine) sun_id = id
                }

                // stem edges: leaf → poo
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
                            data:  { ideal_length: Math.max(18, Math.round(18 + stature * 55)) },
                            style: {
                                'line-color':         '#3d7a1e',
                                width:                Math.max(0.5, 0.8 + stature * 1.8),
                                'line-style':         'solid',
                                'target-arrow-shape': 'none',
                                'curve-style':        'straight',
                                opacity:              0.5 + stature * 0.38,
                            },
                        })
                    }
                }

                // helio edges: leaf → sun
                if (sun_id) {
                    for (const n of wk.o({ leaf: 1 }) as TheC[]) {
                        if (n.c.drop) continue
                        const lid = this.cyto_id(n)
                        if (!lid) continue
                        const eid = `e:helio:${lid}`
                        seen_e.add(eid)
                        edge_upsert.push({
                            id: eid, source: lid, target: sun_id,
                            data:  { ideal_length: 110 },
                            style: {
                                'line-color':         '#c8b020',
                                width:                0.6,
                                'line-style':         'dashed',
                                'target-arrow-shape': 'none',
                                'curve-style':        'bezier',
                                opacity:              0.18,
                            },
                        })
                    }
                }
            }
        }

        // harvest migrations: leaf present last scan, gone this scan
        const mat_id = 'mat:basic'
        for (const [lid] of prev_leaf) {
            if (!curr_leaf.has(lid)) {
                const leaf_id = `leaf:${lid}`
                if (seen.has(mat_id)) migrate.push({ id: leaf_id, toward: mat_id })
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

        const migrating_ids = new Set(migrate.map(m => m.id))
        const remove      = [...prev_ids].filter(id => !seen.has(id)  && !migrating_ids.has(id))
        const edge_remove = [...prev_eids].filter(id => !seen_e.has(id))

        const rel: any[] = []
        for (let i = 0; i < w_order.length - 1; i++) {
            rel.push({ left: w_order[i], right: w_order[i + 1], gap: 60 })
        }
        const constraints = rel.length ? { relativePlacementConstraint: rel } : null

        console.log(`Cyto scan: ${seen.size} nodes, ${seen_e.size} edges, ${migrate.length} migrations`)
        return { upsert, edge_upsert, remove, edge_remove, migrate, constraints,
                 duration: (w.sc.grawave_duration as number) ?? 0.3 }
    },

    cyto_id(n: TheC): string | null {
        if (n.sc.leaf)                 return `leaf:${n.sc.leaf_id ?? n.sc.leaf}`
        if (n.sc.sunshine)             return `sun`
        if (n.sc.poo)                  return `poo`
        if (n.sc.material)             return `mat:${n.sc.material}`
        if (n.sc.producing)            return `prod`
        if (n.sc.protein)              return `prot:${n.sc.protein_id ?? 'p'}`
        if (n.sc.shelf && n.sc.enzyme) return `enz_shelf`
        if (n.sc.wants_enzyme)         return `want_enz`
        if (n.sc.run)                  return `run:${n.sc.run}`
        if (n.sc.self || n.sc.chaFrom || n.sc.wasLast || n.sc.sunny_streak
            || n.sc.seen || n.sc.o_elvis) return null
        return null
    },

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

    hsl2rgb(h: number, s: number, l: number): string {
        s /= 100;
        l /= 100;

        const c = (1 - Math.abs(2 * l - 1)) * s;
        const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
        const m = l - c / 2;

        let r = 0, g = 0, b = 0;

        if (h >= 0 && h < 60) {
            r = c; g = x; b = 0;
        } else if (h >= 60 && h < 120) {
            r = x; g = c; b = 0;
        } else if (h >= 120 && h < 180) {
            r = 0; g = c; b = x;
        } else if (h >= 180 && h < 240) {
            r = 0; g = x; b = c;
        } else if (h >= 240 && h < 300) {
            r = x; g = 0; b = c;
        } else if (h >= 300 && h < 360) {
            r = c; g = 0; b = x;
        }

        r = Math.round((r + m) * 255);
        g = Math.round((g + m) * 255);
        b = Math.round((b + m) * 255);

        return `rgb(${r},${g},${b})`;
    },

    cyto_node(n: TheC, id: string): any {
        const label = this.cyto_label(n);
        const style: any = {};

        if (n.sc.leaf) {
            const d = (n.sc.dose as number) ?? 0;
            const sz = Math.round(14 + d * 16);
            const lt = Math.round(28 + d * 12);
            style['background-color'] = this.hsl2rgb(120, 55, lt);
            style.width = sz; style.height = sz; style.shape = 'ellipse';
            style.color = d > 1.4 ? '#001800' : '#b0ffb0';
        } else if (n.sc.sunshine) {
            const d = (n.sc.dose as number) ?? 0;
            const sz = Math.round(28 + d * 8);
            style['background-color'] = this.hsl2rgb(46, 90, 50 + d * 8);
            style.width = sz; style.height = sz; style.shape = 'diamond';
            style.color = '#331800';
        } else if (n.sc.poo) {
            const d = (n.sc.dose as number) ?? 0;
            const sz = Math.round(18 + Math.min(d, 8) * 2.5);
            style['background-color'] = '#5c3010';
            style.width = sz; style.height = sz; style.shape = 'ellipse';
            style.color = '#c88040';
        } else if (n.sc.material) {
            const amt = (n.sc.amount as number) ?? 0;
            const sz = Math.round(18 + Math.min(amt, 20) * 1.6);
            style['background-color'] = this.hsl2rgb(33, 52, 20 + Math.min(amt, 20) * 1.5);
            style.width = sz; style.height = sz; style.shape = 'round-rectangle';
            style.color = '#ffe8c0';
        } else if (n.sc.producing) {
            style['background-color'] = '#142060';
            style.width = 42; style.height = 42; style.shape = 'round-rectangle';
            style.color = '#9ab4ff';
        } else if (n.sc.protein) {
            const cx = (n.sc.complexity as number) ?? 0;
            const sz = Math.round(18 + cx * 4.5);
            style['background-color'] = this.hsl2rgb(276, 40, 22 + cx * 5);
            style.width = sz; style.height = sz; style.shape = 'hexagon';
            style.color = '#ddc8ff';
        } else if (n.sc.shelf && n.sc.enzyme) {
            const u = (n.sc.units as number) ?? 0;
            style['background-color'] = '#1a4828';
            style.width = Math.round(20 + u * 2.5); style.height = 20;
            style.shape = 'round-rectangle'; style.color = '#90ffc0';
        } else if (n.sc.wants_enzyme) {
            style['background-color'] = '#6a1a08';
            style.width = 22; style.height = 22; style.shape = 'star';
            style.color = '#ff9070';
        } else if (n.sc.run) {
            style['background-color'] = '#101028';
            style.width = 44; style.height = 18; style.shape = 'round-rectangle';
            style.color = '#7888ff';
        } else {
            style['background-color'] = '#242424';
            style.width = 16; style.height = 16;
            style.color = '#666';
        }
        return { id, label, style };
    },


    cyto_w_style(wname: string): any {
        const bg: Record<string,string>     = { farm: '#0a1f0a', plate: '#1f130a', enzymeco: '#0a0a1f' }
        const border: Record<string,string> = { farm: '#2a5a1a', plate: '#5a3a1a', enzymeco: '#1a1a5a' }
        return {
            'background-color':   bg[wname]     ?? '#181818',
            'background-opacity': 0.5,
            'border-color':       border[wname] ?? '#2a2a2a',
            'border-width':       1,
            'border-style':       'dashed',
            'text-valign':        'top',
            'text-halign':        'center',
            padding:              '18px',
            'font-size':          '9px',
            'font-weight':        'bold',
            'font-style':         'italic',
            color:                '#4a6a4a',
        }
    },

    async story_cyto_step(A: TheC, w: TheC, e: TheC) {
        this.cyto_update_wave(w)
        const dur = ((w.sc.grawave_duration as number) ?? 0.3) * 1000
        setTimeout(() => {
            this.elvisto('Story/Story', 'story_cyto_continue', { story_step: e?.sc.story_step })
        }, dur + 100)
    },

    })
    })
</script>