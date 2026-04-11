<script lang="ts">
    // Cyto.svelte — ghost.
    //
    // ── Commission protocol ──────────────────────────────────────────────────
    //
    //   A client (Story, LangTiles, etc.) posts e_Cyto_commission with a req
    //   whose sc carries:
    //
    //     Scannable          — the TheC to treat as RunH-equivalent (scanned
    //                          as the graph source)
    //     Styles             — the matstyle bucket TheC; may be null, in
    //                          which case cyto_nstyle uses a palette fallback
    //     client_w           — the client's w particle, for animation_done
    //                          callbacks and seek responses
    //     supports_seek      — if true, Cyto honors e_Cyto_seek from this
    //                          client (time travel through CytoStep archive)
    //     supports_takeTurns — if true, Cyto does the pause-animate-continue
    //                          handshake via e_Cyto_animation_request
    //
    //   One Cyto worker serves one commission at a time.  Its contents get
    //   cached onto w.c: Scannable, Styles, client_w, supports_*.  The
    //   commission req particle itself is held at w.c.commission.
    //
    //   Reactivity: Cyto watch_c's the Scannable.  Any version bump on it
    //   triggers a new scan on the next main() — no tick counter passed
    //   through the elvis, no Story.run.done coupling.
    //
    // ── Dip protocol ─────────────────────────────────────────────────────────
    //
    //   Dip_assign(scheme, D) — only D; parent via D.c.T.up.sc.D.
    //   Dip particles persist in D/** across ticks via resume_X.
    //   No resetting — existing children keep their values; new children
    //   claim the next slot from the parent's Dip.sc.i counter.
    //   Result written to T.sc.Dip_scanid (or _cytoid) for easy lookup.
    //   T.sc.Dip_scanid_is_new = true when the Dip was freshly created
    //
    // ── Passes ───────────────────────────────────────────────────────────────
    //
    //   cyto_scan       Se1  n=Scannable  → D** mirrors n**; scan_id on C; C.c.Se1_D=D
    //                                       goners → Se1.c.scan_goners_by_id
    //
    //   cyto_assign_ids Se2  n=topC       → cytoid Dip on all nodes in C**
    //                   (1st call, nodes only)
    //
    //   cyto_scan_refs                    → blue edges added to C** (uses cyto_ids for endpoints,
    //                                       gD.c.T.sc.Dip_scanid for goner from-ids)
    //
    //   cyto_assign_ids Se2  n=topC       → cytoid Dip on new edges too
    //                   (2nd call — existing nodes keep ids, new edges get fresh)
    //
    //   cyto_resolve_refs                 → forward(): parent/source/target C refs → _id strings
    //                                       clear C.c.Se1_D
    //
    //   make_wave       Ze   n=topC       → diffs C** vs bD** → wave

    import { TheC, _C, objectify }  from "$lib/data/Stuff.svelte"
    import { Selection } from "$lib/mostly/Selection.svelte"
    import type { TheD, Travel } from "$lib/mostly/Selection.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount }   from "svelte"
    import Cytui         from "./ui/Cytui.svelte"
    import { ex, indent, sex } from "$lib/Y.svelte";

    let { M } = $props()
    let V = {}
    V.gone_debug = 1

    onMount(async () => {
    await M.eatfunc({

//#region w:Cyto

    async Cyto(A: TheC, w: TheC) {
        if (!w.c.plan_done) this.Cyto_plan(w)
        if (!w.c.commission) return w.i({ see: '⏳ awaiting commission' })
        const ok = await this.cyto_update_wave(w)
        if (!ok) return w.i({ see: '⏳ Scannable empty' })
        w.i({ see: `📊 tick:${w.c.gn?.sc.tick ?? 0}` })
    },

    Cyto_plan(w: TheC) {
        const uis = this.oai_enroll(this, { watched: 'UIs' })
        uis.oai({ UI: 'Cyto', component: Cytui })
        const wa  = this.oai_enroll(this, { watched: 'graph' })
        w.c.gn        = wa.oai({ cyto_graph: 1 })
        w.c.plan_done = true
        w.sc.grawave_duration ??= 0.4
    },

    // ── e_Cyto_commission ────────────────────────────────────────────────
    // Client (Story, LangTiles, etc.) posts this with a req whose sc carries
    // Scannable, Styles, client_w, and capability flags.  We cache everything
    // on w.c for fast access, and watch_c the Scannable so future mutations
    // fire cyto_update_wave automatically.
    async e_Cyto_commission(A: TheC, w: TheC, e: TheC) {
        const req = e?.sc.req as TheC | undefined
        if (!req) return w.i({ error: 'Cyto_commission: !req' })
        if (!w.c.plan_done) this.Cyto_plan(w)

        w.c.commission         = req
        w.c.Scannable          = req.sc.Scannable as TheC
        w.c.Styles             = req.sc.Styles as TheC | null
        w.c.client_w           = req.sc.client_w as TheC | undefined
        w.c.supports_seek      = !!req.sc.supports_seek
        w.c.supports_takeTurns = !!req.sc.supports_takeTurns

        // React to Scannable mutations — any version bump queues a main()
        // which will run Cyto() → cyto_update_wave().
        const scan = w.c.Scannable as TheC
        if (scan && !w.c.scannable_watched) {
            this.watch_c(scan, () => this.main())
            w.c.scannable_watched = true
        }

        console.log(`📡 Cyto commissioned by ${w.c.client_w?.sc.w ?? '?'}`
            + ` seek:${w.c.supports_seek} takeTurns:${w.c.supports_takeTurns}`
            + ` Styles:${w.c.Styles ? 'yes' : 'no'}`)
        this.main()
    },

    async cyto_update_wave(w: TheC): Promise<boolean> {
        const H    = this as House
        const scan = w.c.Scannable as TheC | undefined
        if (!scan) return false

        // Version-based change detection — replaces the old done/last_done
        // proxy that reached into Story's run particle.
        const v_now     = scan.version
        const last_v    = w.c.last_scan_v as number | undefined
        const open_at   = w.c.supports_seek ? (w.c.open_at as number | null | undefined) : undefined
        const last_open = w.c.last_open_at as number | null | undefined

        const gn = w.c.gn as TheC | undefined
        if (v_now === last_v && open_at === last_open && !w.c.cyto_wipe) {
            return true
        }

        // ── TRIGGER 1: Scannable changed → scan, archive CytoStep ──────────────
        if (v_now !== last_v) {
            const topC = await this.cyto_scan(w, scan)
            await this.cyto_assign_ids(w, topC)
            await this.cyto_scan_refs(w, topC)
            await this.cyto_assign_ids(w, topC)
            await this.cyto_resolve_refs(w, topC)

            // step_n is optional metadata — client may provide via commission,
            // otherwise we just use the version counter as a monotonic key
            const step_n = v_now
            w.i({ CytoStep: 1, step_n, C: topC })
            w.c.last_scan_v = v_now

            if (!open_at && !w.c.no_graph) {
                const wave = await this.make_wave(w, topC, true)
                wave.sc.step_n = step_n
                this._cyto_push(w, wave)
            }

            await w.r({ wave_data: 1 }, async () => {
                const wv = (w.c.gn as TheC)?.sc.wave as TheC | undefined
                if (wv) w.i({ wave_data: 1,
                    nodes:    wv.o({ upsert:      1 }).length,
                    edges:    wv.o({ edge_upsert: 1 }).length,
                    removing: wv.o({ remove:      1 }).length,
                    step_n })
            })
        }

        // ── TRIGGER 2: open_at changed → seek or return to live ────────────────
        // Only runs when the client supports seeking.
        if (w.c.supports_seek && (open_at !== last_open || w.c.cyto_wipe)) {
            const backwards = typeof last_open === 'number' && typeof open_at === 'number'
                && open_at < last_open
            let adjacent = last_open-1 == open_at || last_open+1 == open_at
            const departing = backwards
                ? (w.o({ CytoStep: 1 }) as TheC[]).find(s => s.sc.step_n === last_open)?.sc.C
                : null
            w.c.last_open_at = open_at
            if (gn) gn.sc.seek_warning = null

            if (open_at == null) {
                const latest = (w.o({ CytoStep: 1 }) as TheC[])
                    .sort((a, b) => (a.sc.step_n as number) - (b.sc.step_n as number)).at(-1)
                if (latest?.sc.C) {
                    const wave = await this.make_wave(w, latest.sc.C as TheC, adjacent, backwards, departing)
                    wave.sc.step_n = latest.sc.step_n as number
                    this._cyto_push(w, wave)
                }
            } else {
                const target = (w.o({ CytoStep: 1 }) as TheC[])
                    .find(s => s.sc.step_n === open_at)
                if (!target) {
                    if (gn) { gn.sc.seek_warning = `no graph data for step ${open_at}`; gn.bump_version() }
                    ;(H.o({ watched: 'graph' })[0] as TheC)?.bump_version()
                } else {
                    const wave = await this.make_wave(w, target.sc.C as TheC, adjacent, backwards, departing)
                    wave.sc.step_n = open_at
                    this._cyto_push(w, wave)
                }
            }
        }

        return true
    },

    _cyto_push(w: TheC, wave: TheC) {
        console.log(`🌊 push dur:${wave.sc.duration} wipe:${!!wave.sc.cyto_wipe} tick:${(w.c.gn as any)?.sc.tick}`)
        w.o({TheWave:1}).map(n => n.drop(n))
        w.i({TheWave:1}).i(wave)

        const H  = this as House
        const gn = w.c.gn as TheC | undefined
        if (!gn) return
        if (w.c.cyto_wipe) {
            wave.sc.cyto_wipe = true
            delete w.c.cyto_wipe
        }
        gn.sc.wave = wave
        gn.sc.tick = ((gn.sc.tick as number) ?? 0) + 1
        gn.bump_version()
        ;(H.o({ watched: 'graph' })[0] as TheC)?.bump_version()
    },

    // ── e_Cyto_seek ──────────────────────────────────────────────────────
    // Client (only if supports_seek) tells us to show a particular
    // archived step.  We cache it on w.c.open_at and run Trigger 2.
    async e_Cyto_seek(A: TheC, w: TheC, e: TheC) {
        if (!w.c.supports_seek) return
        w.c.open_at = e?.sc.open_at ?? null
        await this.cyto_update_wave(w)
    },

    async e_Cyto_wipe(A: TheC, w: TheC) {
        w.c.cyto_wipe = true       // Cytui reads this when applying next wave
        w.c.cyto_Ze?.sc.topD?.empty()   // D history gone → next process() is fully fresh
        this.main()
    },

//#endregion
//#region Se1 — cyto_scan

    async cyto_scan(w: TheC, Scannable: TheC): Promise<TheC> {
        w.c.cyto_Se ??= new Selection()
        const Se: Selection = w.c.cyto_Se
        // replace topD every tick: fresh .c.T; D/** (Dip, n_ref) preserved via resume_X
        Se.sc.topD = await Se.r({ cyto_root: 1 })
        let has_Dip = Se.sc.topD.o({ Dip: 'scanid' })[0] ? "has" : 'neu'
                console.log(`cyto_scan()! ${has_Dip}`)
        const topC: TheC = _C({ cyto_root: 1 })
        Se.c.scan_goners_by_id = new Map<string, TheD>()

        await Se.process({
            n:          Scannable,
            loop_but_no_further: 1,
            process_D:  Se.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                T.sc.inherits = ex({},T.up?.sc.inherits||{})

                const cls = this.cytyle_classify(n)
                if (cls === 'skip')      { T.sc.not = 1; D.drop(D); return }
                if (cls === 'invisible') {
                    if (T == T.c.path[0]) {
                        // Dip must begin on the topD
                        const scan_id = this.Dip_assign('scanid', D)
                    }
                    T.sc.C = T.sc.up?.sc.C ?? topC
                    return
                }

                const scan_id = this.Dip_assign('scanid', D)

                const parentC: TheC = T.sc.up?.sc.C ?? topC
                const nd = this.cyto_nstyle(w, n)

                const C: TheC = parentC.i({
                    cyto_node:  1,
                    scan_id,
                    label:      nd.label,
                    isCompound: nd.isCompound ?? false,
                    // parent only when parentC is itself a cyto_node (not topC/cyto_root)
                    parent: T.sc.inherits.parent ??
                        (parentC.sc.isCompound && parentC.sc.cyto_node ? parentC : null),
                    style:      nd.style,
                })
                C.c.Se1_D = D   // link to Se1 D for cyto_scan_refs
                T.sc.C = C

                // backlink for matstyle_restyle reactivity
                // < can be got via Se1_D. generalise...
                C.c.source_n = n

                // nd already has matstyles_desc when matstyle_apply ran
                if (nd.matstyles_desc) C.sc.matstyles = nd.matstyles_desc

                // special cases of node typing:
                // the non-first duplicate refs get:
                if (T.sc.loopy) C.sc.loopy = 1
                // %w contains everything in it
                if (n.sc.w) T.sc.inherits.parent = C
                // uplinks forming trees of / ness
                if (parentC.sc.cyto_node && !parentC.sc.isCompound) {
                    C.i({cyto_edge:1,scan_id,
                        source:parentC, label:"/", target:C})
                }
            },

            trace_fn: async (uD: TheD, n: TheC) => {
                const sc: any = { tracing: 1 }
                for (const [k, v] of Object.entries(n.sc ?? {})) {
                    if (typeof v !== 'object' && typeof v !== 'function') { sc[`the_${k}`] = v }
                }
                return uD.i(sc)
            },

            traced_fn: async (D: TheD, bD: TheD | undefined, n: TheC, T: Travel) => {
                if (T.sc.C && bD) {
                    T.sc.C.sc.ref_stable = !!(bD && T.sc.n === bD.c.T?.sc.n)
                }
            },

            resolved_fn: async (T: Travel, _N: Travel[], goners: TheD[]) => {
                let {D} = T.sc
                V.gone_debug && goners.length && D.i({goners}) // debug

                for (const g of goners)
                    this.cyto_collect_goner_scan_ids(g, Se.c.scan_goners_by_id as Map<string,TheD>)
            },
        })

        // build neu_scan_ids here — T** are populated, _is_new flags are set
        const neu = new Set<string>()
        await Se.c.T?.forward(async (T: Travel) => {
            if (T.sc.Dip_scanid_is_new) neu.add(T.sc.Dip_scanid as string)
        })
        Se.c.neu_scan_ids = neu  // overwrites every tick, no cache guard

        
        return topC
    },

    cyto_collect_goner_scan_ids(D: TheD, by_id: Map<string, TheD>): void {
        const id = D.o({ Dip: 'scanid' })[0]?.sc.value as string | undefined
        if (id && !by_id.has(id)) by_id.set(id, D)
        for (const child of D.o({ tracing: 1 }) as TheD[])
            this.cyto_collect_goner_scan_ids(child, by_id)
    },


//#endregion
//#region classify n

    cytyle_classify(n: TheC): 'skip' | 'invisible' | 'compound' | null {
        const s = n.sc
        if (s.self || s.mo || s.chaFrom || s.wasLast || s.sunny_streak || s.seen
            || s.o_elvis || s.cyto_node || s.cyto_root || s.cyto_tracking
            || s.wave_data || s.refs || s.snap_node || s.snap_root
            || s.housed || s.run || s.Se || s.inst || s.began_wanting
            || s.CytoStep || s.CytoWave || s.tracing || s.Dip
            || s.snapshot || s.cyto_edge_root || s.cyto_z) return 'skip'
        if (s.H || s.A) return 'invisible'
        if (s.w) return 'compound'
        return null
    },

    cyto_label(n: TheC): string {
        const parts: string[] = []
        for (const [k, v] of Object.entries(n.sc ?? {})) {
            if (v === 1)                                  parts.push(k)          // leaf:1 → "leaf"
            else if (typeof v === 'number')               parts.push(`${k}:${Math.round(v*100)/100}`)
            else if (typeof v === 'boolean')              parts.push(k)
            else if (typeof v === 'string' && v !== '1') parts.push(`${k}:${v.length>11?v.slice(0,9)+'…':v}`)
        }
        return parts.join('\n')
    },

    // cyto_nstyle now takes the Cyto worker w explicitly and reads
    // w.c.Styles (cached from the commission).  If Styles is absent,
    // we fall back to a deterministic palette-pick and warn once.
    cyto_nstyle(w: TheC, n: TheC): any {
        const key = this.mainkey(n)
        if (!key) return { label: this.cyto_label(n),
            style: { 'background-color': '#242424', width: 16, height: 16, color: '#666' } }

        const stylesC = w.c.Styles as TheC | null | undefined
        if (!stylesC) {
            if (!w.c._warned_no_styles) {
                console.warn(`Cyto w:${w.sc.w} has no Styles bucket — palette fallback`)
                w.c._warned_no_styles = true
            }
            const idx = key.split('').reduce((a, c) => a + c.charCodeAt(0), 0) % 40
            return { label: this.cyto_label(n),
                style: { 'background-color': this.MATSTYLE_PALETTE[idx],
                        width: 16, height: 16, color: '#ccc' } }
        }

        const ms = this.matstyle_get_or_create(stylesC, key)
        return this.matstyle_apply(ms, n)
    },



    

//#endregion

//#endregion
//#region Se2 ids

    // Pass 1 (before cyto_scan_refs): walks C%cyto_node** — nodes get cytoid Dips.
    // Pass 2 (after  cyto_scan_refs): same walk — nodes keep ids; new edges get fresh ids.
    // Se2 topD is replaced each pair of calls (i.e., each cyto_update_wave tick) so .c.T
    // is fresh, but D/** (Dip particles) carry over giving stable ids to matching C nodes.

    async cyto_assign_ids(w: TheC, topC: TheC): Promise<void> {
        w.c.cyto_Se2 ??= new Selection()
        const Se2: Selection = w.c.cyto_Se2
        Se2.sc.topD = await Se2.r({ cyto_assigning: 1 })

        await Se2.process({
            n:          topC,
            process_D:  Se2.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, C: TheC, T: Travel) => {
                if (C.sc.cyto_node) C.sc.cyto_id = this.Dip_assign('cytoid', D)
                else
                if (C.sc.cyto_edge) C.sc.edge_id  = this.Dip_assign('cytoid', D)
                else
                if (T == T.c.path[0]) this.Dip_assign('cytoid', D)
            },

            trace_fn: async (uD: TheD, C: TheC) => {
                // trace on scan_id for nodes, source+target for edges
                if (C.sc.cyto_node) return uD.i({ tracing: 1, the_scan_id: C.sc.scan_id ?? '' })
                if (C.sc.cyto_edge) {
                    const src = typeof C.sc.source === 'object'
                        ? (C.sc.source as TheC).sc.scan_id ?? ''
                        : C.sc.source_id ?? ''
                    const tgt = typeof C.sc.target === 'object'
                        ? (C.sc.target as TheC).sc.scan_id ?? ''
                        : C.sc.target_id ?? ''
                    return uD.i({ tracing: 1, the_src: src, the_tgt: tgt })
                }
                return uD.i({ tracing: 1 })
            },

            traced_fn:   async () => {},
            resolved_fn: async () => {},
        })
    },

//#endregion
//#region cyto_scan_refs

    // Runs after Se2 pass 1 (nodes have cyto_ids) and before Se2 pass 2 (edges get ids).
    // Reads C.c.Se1_D for n refs (migration detection).
    // Adds cyto_edge children to C nodes (multi-placed) and topC (migration orphans).

    async cyto_scan_refs(w: TheC, topC: TheC): Promise<void> {
        const Se1          = w.c.cyto_Se as Selection
        const goners_by_id = Se1.c.scan_goners_by_id as Map<string, TheD>

        // build n → C[] map from current C%cyto_node**
        const n_to_Cs = new Map<TheC, TheC[]>()
        const walk = (C: TheC) => {
            for (const nc of C.o({ cyto_node: 1 }) as TheC[]) {
                const n = (nc.c.Se1_D as TheD | undefined)?.c.T.sc.n as TheC | undefined
                if (n) {
                     const a = n_to_Cs.get(n);
                     if (a) a.push(nc)
                     else n_to_Cs.set(n, [nc]) 
                }
                walk(nc)
            }
        }
        walk(topC)

        const blue_sc = (source:TheC, target:TheC, directed: boolean, extra: any = {}) => ({
            cyto_edge: 1 as const, ref: 1 as const,
            source, target,
            label: '==',
            style: {
                'line-color': '#4488ff', width: 1.2, 'line-style': 'dashed',
                'target-arrow-shape': directed ? 'triangle' : 'none',
                'target-arrow-color': '#4488ff', 'curve-style': 'bezier', opacity: 0.5,
            },
            ...extra,
        })

        // multi-placed: same n in >1 current C
        for (const [n, Cs] of n_to_Cs) {
            if (Cs.length < 2) continue
            console.log(`ref saw multiply: ${objectify(n)}`)
            for (let i = 0; i < Cs.length - 1; i++)
                Cs[i].i(blue_sc(Cs[i], Cs[i+1], false))
        }
        // migration: goner whose n ref appears as a neu C
        for (const [_gid, gD] of goners_by_id) {
            const n = gD.c.T?.sc.n as TheC | undefined

            if (!n) continue
            const neu_Cs = (n_to_Cs.get(n) ?? []).filter(
                C => Se1.c.neu_scan_ids.has(C.sc.scan_id)
            )
            if (!neu_Cs.length) continue
            const to_C      = neu_Cs[0]
            const to_id     = to_C.sc.cyto_id as string
            const from_id   = (gD.c.T?.sc.C as TheC | undefined)?.sc.cyto_id as string | undefined
            if (!from_id) continue
            to_C.i({ cyto_migration: 1, from_id, to_id })
        }
    },

//#endregion
//#region cyto_resolve_refs

    // Forward walk via Se2.c.T: convert parent/source/target C refs → _id strings.
    // Clears C.c.Se1_D links (keep C** low-memory after this point).

    async cyto_resolve_refs(w: TheC, topC: TheC): Promise<void> {
        const Se2 = w.c.cyto_Se2 as Selection
        if (!Se2?.c.T) return

        await Se2.c.T.forward(async (T: Travel) => {
            const C = T.sc.n as TheC; if (!C) return

            if (C.sc.cyto_node) {
                if (C.sc.parent && typeof C.sc.parent === 'object') {
                    C.sc.parent_id = (C.sc.parent as TheC).sc.cyto_id ?? null
                    delete C.sc.parent
                }
            }

            if (C.sc.cyto_edge) {
                if (C.sc.source && typeof C.sc.source === 'object') {
                    C.sc.source_id = (C.sc.source as TheC).sc.cyto_id ?? null
                    delete C.sc.source
                }
                if (C.sc.target && typeof C.sc.target === 'object') {
                    C.sc.target_id = (C.sc.target as TheC).sc.cyto_id ?? null
                    delete C.sc.target
                }
            }
        })
    },

//#endregion
//#region Ze — make_wave
    // Compare newVal against what's stored at bD.sc[key].
    // newVal is an object (style) or scalar (label, parent_id).
    // Returns changed subset / changed scalar, or null if nothing changed.
    // bD=undefined means "all new" — returns newVal wholesale.
    cyto_changed(bD: TheD | undefined, key: string, newVal: any): any | null {
        if (!bD) return newVal
        const old = bD.sc[key]
        if (newVal !== null && typeof newVal === 'object') {
            const ch: any = {}; let has = false
            for (const [k, v] of Object.entries(newVal)) {
                if (old?.[k] !== v) { ch[k] = v; has = true }
            }
            return has ? ch : null
        }
        return old !== newVal ? newVal : null
    },

    async make_wave(w: TheC, topC: TheC, adjacent: boolean, backwards = false, departing?:TheC): Promise<TheC> {
        w.c.cyto_Ze ??= new Selection()
        const Ze: Selection = w.c.cyto_Ze
        Ze.sc.topD = await Ze.r({ cyto_root: 'Ze' })
 
        const dur  = (w.sc.grawave_duration as number) ?? 0.3
        const wave = _C({ CytoWave:1, duration: dur })
 
        await Ze.process({
            n:          topC,
            process_D:  Ze.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },
 
            each_fn: async (D: TheD, C: TheC, T: Travel) => {
                if (D.sc.cyto_root && C.sc.cyto_root) return
                if (!C.sc.cyto_node && !C.sc.cyto_edge) { T.sc.not = 1; return }
                D.sc.is_edge = !!C.sc.cyto_edge
            },
 
            trace_fn: async (uD: TheD, C: TheC) => {
                if (C.sc.cyto_node) return uD.i({
                    tracing: 1, the_cyto_id: C.sc.cyto_id ?? '',
                    the_style:  { ...C.sc.style  as object ?? {} },
                    the_label:  C.sc.label  ?? '',
                    the_parent: C.sc.parent_id ?? null,
                })
                if (C.sc.cyto_edge) return uD.i({
                    tracing: 1, the_edge_id: C.sc.edge_id ?? '',
                    the_style: { ...C.sc.style as object ?? {} },
                    the_src:   C.sc.source_id ?? '',
                    the_tgt:   C.sc.target_id ?? '',
                })
                return uD.i({ tracing: 1 })
            },
 
            traced_fn: async (D: TheD, bD: TheD | undefined, C: TheC) => {
                if (!C.sc.cyto_node && !C.sc.cyto_edge) return


                let label = C.c.Se1_D?.c.T.sc.n.sc.label
                let etc = label != null ? {label} : {}
 
                if (C.sc.cyto_edge) {
                    const eid = C.sc.edge_id as string
                    if (!eid) return
                    const style_ch = this.cyto_changed(bD, 'the_style', C.sc.style ?? {})
                    if (!bD) {
                        wave.i({ edge_upsert: 1, id: eid, ...etc,
                            source: C.sc.source_id, target: C.sc.target_id,
                            style:  C.sc.style ?? {},
                            data: sex({},C.sc,['ideal_length'])
                        })
                    } else if (style_ch) {
                        wave.i({ edge_upsert: 1, id: eid, ...etc, style: style_ch })
                    }
                    return
                }
 
                // cyto_node
                const id       = C.sc.cyto_id  as string
                const style_ch = this.cyto_changed(bD, 'the_style',  C.sc.style    ?? {})
                const label_ch = this.cyto_changed(bD, 'the_label',  C.sc.label    ?? '')
                const par_ch   = this.cyto_changed(bD, 'the_parent', C.sc.parent_id ?? null)
 
                if (!bD) {
                    if (C.sc.label != null) etc.label = C.sc.label
                    if (C.sc.isCompound) etc.isCompound = C.sc.isCompound
                    if (C.sc.parent_id != null) etc.parent = C.sc.parent_id
                    if (C.sc.style != null) etc.style = C.sc.style
                    wave.i({ upsert: 1, id, ...etc })
                } else if (style_ch || label_ch !== null || par_ch !== null) {
                    wave.i({ upsert: 1, id, ...etc,
                        ...(style_ch          ? { style:      style_ch         } : {}),
                        ...(label_ch !== null ? { label:      C.sc.label       } : {}),
                        ...(par_ch   !== null ? { new_parent: C.sc.parent_id ?? null } : {}),
                    })
                }
            },
 
            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                // walk the Ze D subtree of every goner — catches nested nodes
                // (eg marble inside a goner leaf) that were never explicitly resolved
                const emit_removes = (g: TheD) => {
                    if (g.sc.is_edge) {
                        if (g.sc.the_edge_id) wave.i({ edge_remove: 1, id: g.sc.the_edge_id })
                    } else {
                        if (g.sc.the_cyto_id) wave.i({ remove: 1, id: g.sc.the_cyto_id })
                    }
                    for (const child of g.o({ tracing: 1 }) as TheD[]) emit_removes(child)
                }
                for (const g of goners) emit_removes(g)
            },
        })
 
        if (adjacent) {
            const source = backwards ? departing : topC
            const walk = (C: TheC) => {
                for (const mc of C.o({ cyto_migration: 1 }) as TheC[]) {
                    const from = backwards ? mc.sc.to_id   : mc.sc.from_id
                    const toward = backwards ? mc.sc.from_id : mc.sc.to_id
                    wave.i({ migrate: 1, id: from, toward })
                }
                for (const nc of C.o({ cyto_node: 1 }) as TheC[]) walk(nc)
            }
            walk(source)
        }
 
        return wave
    },


//#endregion
//#region wave -> string

    // ── snap_cytowave_str ──────────────────────────────────────────────────────
    // Encode a cyto wave as enL lines starting at d_base.
    // Each node/edge is one enL line (stringies = identity keys).
    // Style properties are children at d_base+1, one key per line.
    // Numeric style values rounded to 2dp; label \n → space.
    // Excluded: duration, step_n, constraints (non-content).

    snap_cytowave_str(wave: any, d_base = 1): string {
        if (!wave) return ''
        const lines: string[] = []

        const rank = (n: TheC) =>
            n.sc.upsert       ? 0
            : n.sc.edge_upsert ? 1
            : n.sc.remove      ? 2
            : n.sc.edge_remove ? 3
            : n.sc.migrate     ? 4
            : 5

        const emit = (n: TheC, d: number) => {
            // strip style/data so they never appear as refs in the parent line
            const { style, data, ...rest } = n.sc
            const line = this.enLine(_C(rest), { d })
            if (!line) return
            lines.push(line)

            // style children: {style:1, height:40}
            if (style && typeof style === 'object' && Object.keys(style).length) {
                for (const [k, v] of Object.entries(style as Record<string,any>)
                        .sort(([a],[b]) => a.localeCompare(b))) {
                    if (v == null) continue
                    const sv = typeof v === 'number' ? Math.round(v * 100) / 100 : v
                    const child = this.enLine(_C({ style: 1, [k]: sv }), { d: d + 1 })
                    if (child) lines.push(child)
                }
            }

            // data children: {data:1, ideal_length:80}
            if (data && typeof data === 'object' && Object.keys(data).length) {
                for (const [k, v] of Object.entries(data as Record<string,any>)
                        .sort(([a],[b]) => a.localeCompare(b))) {
                    if (v == null) continue
                    const child = this.enLine(_C({ data: 1, [k]: v }), { d: d + 1 })
                    if (child) lines.push(child)
                }
            }
        }

        for (const n of (wave.o({}) as TheC[]).sort((a: TheC, b: TheC) => {
            const dr = rank(a) - rank(b)
            if (dr) return dr
            const ia = String(a.sc.id ?? a.sc.edge_id ?? a.sc.migrate ?? '')
            const ib = String(b.sc.id ?? b.sc.edge_id ?? b.sc.migrate ?? '')
            return ia.localeCompare(ib)
        })) {
            emit(n, d_base)
        }

        return lines.join('\n') + '\n'
    },

//#endregion
//#region takeTurns handshake — e_Cyto_animation_request / animation_done
//
//  Client (if supports_takeTurns) sends e_Cyto_animation_request to pause
//  its own drive while Cyto renders and animates the current step.  Cyto
//  runs cyto_update_wave then elvistwos back to w.c.client_w as
//  'animation_done' after the grawave duration has elapsed.
//
//  The client handler is just e_${Clientname}_animation_done on its worker.

    async e_Cyto_animation_request(A: TheC, w: TheC, e: TheC) {
        if (!w.c.supports_takeTurns) return
        await this.cyto_update_wave(w)
        const dur = ((w.sc.grawave_duration as number) ?? 0.3) * 1000
        const client = w.c.client_w as TheC | undefined
        setTimeout(() => {
            if (client) this.elvistwo(w, client, 'animation_done', { story_step: e?.sc.story_step })
        }, dur + 100)
    },

//#endregion

    })
    })
</script>