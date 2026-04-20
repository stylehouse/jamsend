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
    //
    // ── Lang-aware node types ────────────────────────────────────────────────
    //
    //   cyto_nstyle branches by particle type:
    //     text:1          → code token, monospace, sized to measured_width/height
    //     Line:N          → gutter marker, narrow pill
    //     node:Name       → syntax annotation, small rounded rect
    //     bookmark_node:1 → bookmark pin, tinted badge
    //
    //   Text nodes carry overlay_str in wave data for Cytui's HTML overlay
    //   system (positioned <pre> elements over the cytoscape canvas).

    import { TheC, _C, objectify }  from "$lib/data/Stuff.svelte"
    import { Selection } from "$lib/mostly/Selection.svelte"
    import type { TheD, Travel } from "$lib/mostly/Selection.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount }   from "svelte"
    import Cytui         from "./ui/Cytui.svelte"
    import { ex, indent, sex } from "$lib/Y.svelte";

    let { M } = $props()
    let V = {}
    V.gone_debug = 0
    V.cyto = 0

    onMount(async () => {
    await M.eatfunc({

//#region w:Cyto

    async Cyto(A: TheC, w: TheC) {
        if (!w.c.plan_done) this.Cyto_plan(w)
        if (!w.c.commission) return w.i({ see: '⏳ awaiting commission' })
        // When commissioned by a takeTurns client, all work happens in
        // e_Cyto_animation_request and e_Cyto_seek. Cyto() is idle.
        w.i({ see: `📊 tick:${w.c.gn?.sc.tick ?? 0}` })
    },

    Cyto_plan(w: TheC) {
        const uis = this.oai_enroll(this, { watched: 'UIs' })
        uis.oai({ UI: 'Cyto', component: Cytui })
        const wa  = this.oai_enroll(this, { watched: 'graph' })
        w.c.gn        = wa.oai({ cyto_graph: 1 })
        w.c.plan_done = true
        w.sc.grawave_duration ??= 0.4
        const stashed_layout = (this as House).stashed?.Cyto_layout_name as string | undefined
        w.c.gn.sc.layout_name ??= stashed_layout ?? 'fcose'
        this.cyto_install_actions(w)
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
        w.c.supports_constraints = !!req.sc.supports_constraints
        w.c.supports_seek        = !!req.sc.supports_seek
        w.c.supports_takeTurns   = !!req.sc.supports_takeTurns
        w.c.wants_wave_done      = !!req.sc.wants_wave_done
        w.c.wants_animation_done = !!req.sc.wants_animation_done
        if (w.c.Styles) {
            const ave = (this as House).oai_enroll(this as House, { watched: 'ave' })
            ave.i(w.c.Styles)
        }

        console.log(`📡 Cyto commissioned by ${w.c.client_w?.sc.w ?? '?'}`
            + ` seek:${w.c.supports_seek} takeTurns:${w.c.supports_takeTurns}`
            + ` Styles:${w.c.Styles ? 'yes' : 'no'}`)
        this.main()
    },

    // Install Cyto's own action buttons on this H.
    // Called from Cyto_plan so whichever H owns this w:Cyto gets them.
    cyto_install_actions(w: TheC) {
        const H  = this as House
        const wa = H.oai_enroll(H, { watched: 'actions' })
        const gn = w.c.gn as TheC

        wa.oai({ action: 1, role: 'cyto_wipe' }, {
            label: 'wipe', icon: '⌀', cls: 'remove',
            fn: () => H.elvisto(w, 'Cyto_wipe', {}),
        })

        const engines = [
            { value: 'fcose',        label: 'fcose'   },
            { value: 'cose-bilkent', label: 'bilkent' },
            { value: 'cola',         label: 'cola'    },
            { value: 'dagre',        label: 'dagre'   },
        ]
        wa.oai({ action: 1, role: 'layout_picker' }, {
            kind:    'dropdown',
            label:   'layout engine',
            icon:    '',
            cls:     'default',
            options: engines,
            value:   gn.sc.layout_name ?? 'fcose',
            on_pick: (name: string) => {
                if (H.stashed) H.stashed.Cyto_layout_name = name
                H.elvisto(w, 'Cyto_set_layout', { layout_name: name })
            },
        })
    },

    async e_Cyto_set_layout(A: TheC, w: TheC, e: TheC) {
        const name = e?.sc.layout_name as string | undefined
        if (!name) return
        const gn = w.c.gn as TheC
        gn.sc.layout_name = name
        gn.bump_version()
        const pick = (this.o({ watched: 'actions' })[0] as TheC | undefined)
            ?.o({ action: 1, role: 'layout_picker' })[0] as TheC | undefined
        if (pick) pick.sc.value = name
        // poke the graph watcher so Cytui re-runs relayout with the new engine
        ;(this as House).o({ watched: 'graph' })[0]?.bump_version()
    },

//#region cyto_update_wave
    async cyto_update_wave(w: TheC, incoming_step_n?: number, absolute = false): Promise<boolean> {
        const H    = this as House
        const scan = w.c.Scannable as TheC | undefined
        if (!scan) return false

        const last_step_n = w.c.last_step_n as number | undefined
        const open_at     = w.c.supports_seek ? (w.c.open_at as number | null | undefined) : undefined
        const last_open   = w.c.last_open_at as number | null | undefined
        const gn          = w.c.gn as TheC | undefined

        let same_step_n = last_step_n && incoming_step_n === last_step_n
        let same_open_at = last_open && open_at === last_open
        if (!absolute && same_step_n && same_open_at) return true

        // TRIGGER 1: new step from client → scan + archive
        if (incoming_step_n !== undefined && !same_step_n || !w.c.supports_seek) {
            const topC = await this.cyto_scan(w, scan)
            await this.cyto_assign_ids(w, topC)
            await this.cyto_scan_refs(w, topC)
            await this.cyto_assign_ids(w, topC)
            await this.cyto_resolve_refs(w, topC)

            V.cyto && console.log(`📦 archive CytoStep step_n=${incoming_step_n} nodes=${topC.c.node_total} edges=${topC.c.edge_total}`);

            if (!w.c.supports_seek) await w.r({CytoStep:1},{})
            w.i({ CytoStep: 1, step_n: incoming_step_n, C: topC })
            w.c.last_step_n = incoming_step_n

            if (!open_at && !w.c.no_graph) {
                const wave = await this.make_wave(w, topC, true, false, undefined, absolute)
                wave.sc.step_n = incoming_step_n
                this._cyto_push(w, wave)
            }

            await w.r({ wave_data: 1 }, async () => {
                const wv = (w.c.gn as TheC)?.sc.wave as TheC | undefined
                if (wv) w.i({ wave_data: 1,
                    nodes:    wv.o({ upsert:      1 }).length,
                    edges:    wv.o({ edge_upsert: 1 }).length,
                    removing: wv.o({ remove:      1 }).length,
                    step_n: incoming_step_n })
            })
            // absolute-only wipe path: incoming_step_n is undefined and
            // open_at === last_open, so trigger 2 won't fire — do the wave here.
        } else if (absolute && open_at == null) {
            // absolute wipe while showing latest — re-emit from current topC.
            // No rescan needed; use the latest archived C.
            const latest = (w.o({ CytoStep: 1 }) as TheC[])
                .sort((a, b) => (a.sc.step_n as number) - (b.sc.step_n as number)).at(-1)
            if (latest?.sc.C) {
                const wave = await this.make_wave(w, latest.sc.C as TheC, false, false, undefined, true)
                wave.sc.step_n = latest.sc.step_n as number
                this._cyto_push(w, wave)
            }
        }

        // TRIGGER 2: open_at changed OR absolute requested while seeking
        if (w.c.supports_seek && (open_at !== last_open || (absolute && open_at != null))) {
            const backwards = typeof last_open === 'number' && typeof open_at === 'number' && open_at < last_open
            const adjacent  = !absolute
                        && last_open != null && open_at != null
                        && Math.abs((open_at as number) - last_open) === 1
            const departing = typeof last_open === 'number'
                ? (w.o({ CytoStep: 1 }) as TheC[]).find(s => s.sc.step_n === last_open)?.sc.C ?? null
                : null
            w.c.last_open_at = open_at
            if (gn) gn.sc.seek_warning = null

            if (open_at == null) {
                const latest = (w.o({ CytoStep: 1 }) as TheC[])
                    .sort((a, b) => (a.sc.step_n as number) - (b.sc.step_n as number)).at(-1)
                if (latest?.sc.C) {
                    const wave = await this.make_wave(w, latest.sc.C as TheC, adjacent, backwards, departing, absolute || !adjacent)
                    wave.sc.step_n = latest.sc.step_n as number
                    this._cyto_push(w, wave)
                }
            } else {
                const target = (w.o({ CytoStep: 1 }) as TheC[]).find(s => s.sc.step_n === open_at)
                if (!target) {
                    if (gn) { gn.sc.seek_warning = `no graph data for step ${open_at}`; gn.bump_version() }
                    ;(H.o({ watched: 'graph' })[0] as TheC)?.bump_version()
                } else {
                    const wave = await this.make_wave(w, target.sc.C as TheC, adjacent, backwards, departing, absolute || !adjacent)
                    wave.sc.step_n = open_at
                    this._cyto_push(w, wave)
                }
            }
        }

        return true
    },

    _cyto_push(w: TheC, wave: TheC) {
        if (!wave.oa()) {
            V.cyto && console.log(`🌊 push NOTHING tick:${(w.c.gn as any)?.sc.tick}`)
            return
        }
        V.cyto && console.log(`🌊 push dur:${wave.sc.duration}`
            + ` abs:${!!wave.sc.absolute}`
            + ` tick:${(w.c.gn as any)?.sc.tick}`)
        w.o({ TheWave: 1 }).map(n => n.drop(n))
        w.i({ TheWave: 1 }).i(wave)

        const H  = this as House
        const gn = w.c.gn as TheC | undefined
        if (!gn) return
        // Story looks for this, it makes and reads one at a time
        gn.sc.wave = wave
        // Lang can make waves faster than Cytui reads them, so they queue here
        gn.sc.waves = [...(gn.sc.waves ?? []), wave]
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
    await this.cyto_update_wave(w, undefined, true)
    },

//#endregion
//#region Se1 — cyto_scan

    async cyto_scan(w: TheC, Scannable: TheC): Promise<TheC> {
        w.c.cyto_Se ??= new Selection()
        const Se: Selection = w.c.cyto_Se
        // replace topD every tick: fresh .c.T; D/** (Dip, n_ref) preserved via resume_X
        Se.sc.topD = await Se.r({ cyto_scannery: 1 })
        // this is quite a thing...
        const topC: TheC = _C({ cyto_root: 1 })
        // debug: put it in the client
        if (w.c.supports_constraints) {
            await w.c.client_w.r({cyto_root: 1},{})
            w.c.client_w.i(topC)
        }
        Se.c.scan_goners_by_id = new Map<string, TheD>()
        // so %cyto_cons can resolve left|right etc to ids for D%* resolve()
        Se.c.scan_id_by_n = new Map<TheC, string>()

        await Se.process({
            n:          Scannable,
            loop_but_no_further: 1,
            process_D:  Se.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                T.sc.inherits = ex({},T.up?.sc.inherits||{})
                const parentC: TheC = T.sc.up?.sc.C ?? topC

                // ── visibility filter via lematch ──────────────────────
                // Rules from this.cyto_visibility (depth 0) plus any
                // thence_matching that depth-0 carried down via T.up.sc.thence.
                const active = [
                    ...this.cyto_visibility,
                    ...(T.up?.sc.cyto_thence ?? []),
                ]
                const lm = n.lematch(active)
                if (lm.skip) {
                    // depth 0 H is "skip" but its children must still be
                    // walked — so for the top T we drop D, mark T as
                    // invisible-passthrough, and stash the thence rules.
                    if (T == T.c.path[0]) {
                        T.sc.cyto_thence = lm.thence
                        T.sc.C = topC
                        return
                    }
                    T.sc.not = 1
                    D.drop(D)
                    return
                }
                // carry thence rules to children
                if (lm.thence.length) T.sc.cyto_thence = lm.thence

                let cls = this.cytyle_classify(n)
                // a %cyto_dir is a %cyto_fold that dissolves now  - doesn't branch C**
                if (w.c.supports_constraints && n.sc.cyto_dir) cls = 'invisible'
                // avoid everything under n**
                if (cls === 'skip')      { T.sc.not = 1; D.drop(D); return }
                // a structure that vanishes - can overload and confuse resolve()
                if (cls === 'invisible') {
                    if (T == T.c.path[0]) {
                        // Dip must begin on the topD
                        const scan_id = this.Dip_assign('scanid', D)
                    }
                    T.sc.C = T.sc.up?.sc.C ?? topC
                    return
                }

                const scan_id = this.Dip_assign('scanid', D)
                // a structure that remains only to group things
                //  probably just for the next resolve() that happens
                if (cls === 'group') {
                    if (!n.sc.cyto_fold) throw "notafold"
                    const C: TheC = parentC.i({
                        cyto_group:1,
                        scan_id,
                        ...n.sc,
                    })
                    C.c.Se1_D = D   // link to Se1 D for cyto_scan_refs
                    T.sc.C = C
                    C.c.source_n = n
                    return
                }
                if (w.c.supports_constraints) {
                    // diagnostic — show which particles are being treated as brand-new
                    // this tick vs matched against a previous-tick D. If you see the same
                    // things upsert+removing with new ids ever wave|tick,
                    //   the D%* trace for them is ambiguous to Stuff.resolve()
                    //    and Dip_assign is allocating a fresh slot|identity.
                    if (T.sc.Dip_scanid_is_new) {
                        // console.log(`🆕 scan new: sid=${scan_id}`,D.sc)
                        // < is it just me or is all this undefined:
                            // { node: n.sc.node, from: n.sc.from, to: n.sc.to, str: n.sc.str,
                            // parent_name: n.sc.parent_name })
                        // if (n.sc.node == 'Name') console.log(`Dip_scanid_is_new: ${objectify(n)}`)
                    }
                }

                Se.c.scan_id_by_n.set(n,scan_id)
                const nd = this.cyto_nstyle(w, n)

                let no_parent_linkage = false
                if (w.c.supports_constraints) {
                    // misnomer. this means, for any n**:
                    // they don't come with a generic n/n edge or parent relation
                    no_parent_linkage = true
                    // n%* can be intelligised, assume it's ready to be C scans scan_id:
                    if (n.sc.cyto_cons || n.sc.cyto_edge) {
                        const C = parentC.i({ ...n.sc,  scan_id });
                        C.c.Se1_D = D   // link to Se1 D for cyto_scan_refs
                        T.sc.C = C
                        return
                    }
                }

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

                // ── overlay data ─────────────────────────────────────────
                // Text nodes carry their string for Cytui's HTML overlay system.
                // The overlay renders a <pre> with monospace text positioned over
                // the cytoscape node, giving crisp typography independent of the
                // graph zoom level. overlay_str is passed through the wave as data.
                // overlay_bg matches the node's background so the overlay cleanly
                // hides the cytoscape label rendered beneath it.
                if (nd.overlay_str) {
                    C.sc.overlay_str  = nd.overlay_str
                    C.sc.overlay_kind = nd.overlay_kind ?? 'code'
                    if (nd.overlay_bg) C.sc.overlay_bg = nd.overlay_bg
                }

                // special cases of node typing:
                // the non-first duplicate refs get:
                if (T.sc.loopy) C.sc.loopy = 1
                
                if (!no_parent_linkage) {
                    // %w contains everything in it
                    if (n.sc.w) T.sc.inherits.parent = C
                    // uplinks forming trees of / ness
                    if (parentC.sc.cyto_node && !parentC.sc.isCompound) {
                        C.i({cyto_edge:1,scan_id,
                            source:parentC, label:"/", target:C})
                    }
                }
            },

            trace_fn: async (uD: TheD, n: TheC) => {
                const sc: any = { tracing: 1 }
                for (const [k, v] of Object.entries(n.sc ?? {})) {
                    if (typeof v !== 'object' && typeof v !== 'function') { sc[`the_${k}`] = v }
                    if (typeof v == 'object' && v instanceof TheC) {
                        // mention the ids of n%left=C%cyto_node etc
                        // as long as the eg constraints are in a later C/* we know the nodes ids by now
                        let v_id = Se.c.scan_id_by_n.get(v)
                        if (v_id != null) sc[`id_of_C_${k}`] = v_id
                    }
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
        // n -> C lookup for downstream ref resolution.
        // Built once per Se1 walk; consumed by cyto_resolve_refs to translate
        // n refs (held in cyto_cons.top/bottom/nodes/..., cyto_edge.source/target,
        // cyto_node.parent) into the C particle that represents that n in this
        // graph snapshot. The map is rebuilt each tick so dropped/recreated
        // C particles always resolve to their current incarnation.
        const n_to_C = new Map<TheC, TheC>()
        await Se.c.T.forward(async (T: Travel) => {
            const n = T.sc.n as TheC | undefined
            const C = T.sc.C as TheC | undefined
            // skip topT (no real n) and invisible-passthrough Ts (C inherited from parent)
            if (n && C && C.sc.cyto_node && C.c.Se1_D?.c.T === T) {
                n_to_C.set(n, C)
            }
        })
        Se.c.n_to_C = n_to_C

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
    // ── cyto_visibility ──────────────────────────────────────────────
    // Rules consumed by lematch in cyto_scan's each_fn.
    //
    // Depth 0 (the H itself, if Scannable is an H): skip the H particle
    // (it has nothing to render), and carry a thence rule that filters
    // its direct children — only A particles allowed, and A:Cyto skipped
    // outright so a Cyto never draws itself.
    //
    // For non-H Scannables (eg LangTiles model C), the depth-0 particle
    // has no H key — no rule matches — no thence carries — every child
    // proceeds normally.
    cyto_visibility: [
        {
            // depth 0: the scannable H — skip it, install child filter
            matching_any: [{ sc: { H: 1 } }],
            means: {
                thence_matching: [
                    {
                        // depth 1: only A particles allowed; A:Cyto skipped
                        matching_any: [{ sc: { A: 'Cyto' } }],
                        means: { skip: true },
                    },
                    {
                        // any non-A at depth 1 → skip
                        matching_any: [{ sc: { watched: 1 } }],
                        means: { skip: true },
                    },
                ],
            },
        },
    ] as Array<any>,

    cytyle_classify(n: TheC): 'skip' | 'invisible' | 'group' | 'compound' | null {
        const s = n.sc
        if (s.self || s.mo || s.chaFrom || s.wasLast || s.sunny_streak || s.seen
            || s.o_elvis || s.cyto_node || s.cyto_root || s.cyto_tracking
            || s.wave_data || s.refs || s.snap_node || s.snap_root
            || s.housed || s.run || s.Se || s.inst || s.began_wanting
            || s.CytoStep || s.CytoWave || s.tracing || s.Dip
            || s.snapshot || s.cyto_edge_root || s.cyto_z) return 'skip'
        // cyto_fold: a grouping container for constraints/edges. Walked through
        // (so its cyto_cons / cyto_edge children are still emitted), but nothing
        // is drawn for the fold itself. mode:'cyto_fold' is the explicit marker
        // — also match bare cyto_fold:1 for robustness.
        if (s.cyto_fold || s.mode === 'cyto_fold') return 'group'
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

    // ── cyto_nstyle ──────────────────────────────────────────────────────
    // Branches by particle type for Lang-aware layout:
    //
    //   text:1          → code token: monospace, sized to measured_width/height,
    //                     dark bg, light text, round-rectangle.
    //                     Carries overlay_str for Cytui HTML overlay.
    //
    //   Line:N          → gutter marker: narrow pill, muted color, shows "LN".
    //
    //   node:Name       → syntax annotation: small rounded rect, tinted by name.
    //                     Floats above its text segment.
    //
    //   bookmark_node:1 → bookmark pin: distinctive badge with bookmark color.
    //
    //   (default)       → falls through to matstyle / palette as before.
    //
    // overlay_bg: when an overlay is emitted for a node, it needs a background
    // colour matching the node so the cytoscape-rendered label is hidden
    // underneath the overlay text. Returned alongside overlay_str.
    cyto_nstyle(w: TheC, n: TheC): any {
        // ── Lang particle types ──────────────────────────────────────
        if (n.sc.text != null) {
            // code token — sized to fit its string
            const str = (n.sc.str as string) ?? ''
            const mw  = (n.sc.measured_width  as number) ?? 60
            const mh  = (n.sc.measured_height as number) ?? 28
            const bg  = '#0c0c0c'
            return {
                label: str,
                overlay_str: str,
                overlay_kind: 'code',
                overlay_bg:   bg,
                style: {
                    'background-color': bg,
                    'border-width': 1,
                    'border-color': '#1a1a1a',
                    width: mw,
                    height: mh,
                    shape: 'round-rectangle',
                    color: '#8b9a7b',       // muted green for code text
                    'font-size': '11px',
                    'text-wrap': 'none',
                    'text-valign': 'center',
                    'text-halign': 'center',
                },
            }
        }

        if (n.sc.Line != null) {
            // Lines with containium become compound cytoscape nodes that
            // wrap their text/node children. Cytui's :parent selector puts
            // the label at top-center and enforces min-width/min-height.
            // Without containium (shouldn't happen in current Lang usage, but
            // kept for robustness) a Line renders as a narrow gutter pill.
            const label = (n.sc.label as string) ?? `L${n.sc.Line}`
            if (n.sc.containium) {
                return {
                    label,
                    isCompound: true,
                    style: {
                        'background-color': '#080808',
                        'background-opacity': 0.7,
                        'border-width': 1,
                        'border-color': '#1a1a1a',
                        shape: 'round-rectangle',
                        color: '#5a6a5a',
                        'font-size': '10px',
                        'text-wrap': 'none',
                        'text-valign': 'top',
                        'text-halign': 'center',
                        padding: 6,
                    },
                }
            }
            return {
                label,
                style: {
                    'background-color': '#0a0a0a',
                    'border-width': 1,
                    'border-color': '#181818',
                    width: 32,
                    height: 20,
                    shape: 'round-rectangle',
                    color: '#3a3a3a',
                    'font-size': '9px',
                    'text-wrap': 'none',
                    'text-valign': 'center',
                    'text-halign': 'center',
                },
            }
        }

        if (n.sc.node != null && n.sc.from != null) {
            // syntax annotation — small, tinted by node name
            // label is just the syntax name (e.g. "Name", "Leg"). The str
            // itself is shown on the connected text node, so duplicating it
            // here just adds clutter.
            const name = (n.sc.node as string) ?? ''
            // deterministic tint from name hash
            const hue = name.split('').reduce((a, c) => a + c.charCodeAt(0), 0) % 360
            const bg  = `hsl(${hue}, 20%, 12%)`
            return {
                label: name,
                overlay_str: name,
                overlay_kind: 'annotation',
                overlay_bg:   bg,
                style: {
                    'background-color': bg,
                    'border-width': 1,
                    'border-color': `hsl(${hue}, 30%, 20%)`,
                    width: Math.max(36, name.length * 6 + 14),
                    height: 22,
                    shape: 'round-rectangle',
                    color: `hsl(${hue}, 40%, 65%)`,
                    'font-size': '9px',
                    'text-wrap': 'none',
                    'text-valign': 'center',
                    'text-halign': 'center',
                },
            }
        }

        if (n.sc.bookmark_node != null) {
            // bookmark pin — distinctive badge
            const label = (n.sc.label as string) ?? (n.sc.bm_id as string) ?? '🔖'
            return {
                label: `🔖 ${label}`,
                style: {
                    'background-color': '#1a1428',
                    'border-width': 2,
                    'border-color': '#7ab0d4',
                    width: Math.max(48, label.length * 6 + 24),
                    height: 24,
                    shape: 'round-rectangle',
                    color: '#7ab0d4',
                    'font-size': '9px',
                    'text-wrap': 'none',
                    'text-valign': 'center',
                    'text-halign': 'center',
                },
            }
        }

        // ── default: matstyle / palette fallback (Story, generic) ────
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
                if (C.sc.cyto_edge) {
                    C.sc.edge_id  = this.Dip_assign('cytoid', D)
                }
                else if (C.sc.cyto_cons) {
                    // Constraints don't go into the cytoscape graph as elements — they're
                    // just passed as options to relayout(). They only need a wave-local
                    // key, which make_wave assigns on its own, so skip the cytoid Dip. 
                }
                else if (C.sc.cyto_migration) {
                    // these belong to a C** but only become part of adjacent waves if etc
                }
                else {
                    C.sc.cyto_id = this.Dip_assign('cytoid', D)
                }
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
                return uD.i({ tracing: 1, ...C.sc })
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
        // n_to_C was built at the end of cyto_scan
        const n_to_C = (w.c.cyto_Se as Selection).c.n_to_C as Map<TheC, TheC>
        const R = (ref: any) => this.resolveCytoId(ref, n_to_C)

        let node_total = 0
        let edge_total = 0

        await Se2.c.T.forward(async (T: Travel) => {
            const C = T.sc.n as TheC; if (!C) return

            if (C.sc.cyto_node) {
                node_total++
                if (C.sc.parent && typeof C.sc.parent === 'object') {
                    C.sc.parent_id = R(C.sc.parent)
                    delete C.sc.parent
                }
            }

            if (C.sc.cyto_edge) {
                edge_total++
                if (C.sc.source && typeof C.sc.source === 'object') {
                    C.sc.source_id = R(C.sc.source)
                    delete C.sc.source
                }
                if (C.sc.target && typeof C.sc.target === 'object') {
                    C.sc.target_id = R(C.sc.target)
                    delete C.sc.target
                }
            }

            if (C.sc.cyto_cons) {
                // Constraint endpoints may be n particles (from Lang.wherewhatis,
                // which builds constraints out of model Lines/texts/nodes), C particles
                // (if some upstream already promoted them), or already-resolved strings.
                // R() handles all three; missing slots come back as null and are
                // dropped before make_wave hands the constraint over.
                const cleaned: any = {
                    type: C.sc.type,
                    axis: C.sc.axis,
                    gap:  C.sc.gap,
                }
                if (Array.isArray(C.sc.nodes)) {
                    cleaned.nodes = C.sc.nodes.map(R).filter((x: any) => x != null)
                }
                for (const slot of ['top', 'bottom', 'left', 'right'] as const) {
                    const v = R(C.sc[slot])
                    if (v != null) cleaned[slot] = v
                }
                C.sc.resolved_constraint = cleaned
            }
        })
        topC.c.node_total = node_total
        topC.c.edge_total = edge_total
    },
    // Resolve any reference (n particle from model, C particle from cyto graph,
    // or already-resolved string id) down to a cyto_id string.
    //
    // Used by cyto_resolve_refs for: cyto_cons endpoints, cyto_edge source/target,
    // cyto_node parent. Centralising here means n->C->cyto_id all goes through
    // one place and behaviour stays consistent.
    //
    //   n_to_C: passed in by caller (Se1.c.n_to_C) — maps model n particles
    //           to their cyto_node C. n refs land here.
    //   ref:    null/undefined → null (callers may legitimately have missing slots,
    //                                  eg a relativePlacement with only `top`/`bottom`)
    //           string         → returned as-is (already a cyto_id)
    //           TheC w/ cyto_id (a C from this scan) → its cyto_id
    //           TheC otherwise (an n from the model)  → look up via n_to_C
    resolveCytoId(ref: TheC | string | null | undefined, n_to_C: Map<TheC, TheC>): string | null {
        if (ref == null) return null
        if (typeof ref === 'string') return ref
        if (ref.sc?.cyto_id) return ref.sc.cyto_id as string
        const C = n_to_C.get(ref)
        if (C?.sc?.cyto_id) return C.sc.cyto_id as string
        // n that never made it into the graph (filtered by classify, or out of scope)
        // — return null rather than throw; callers decide whether that's fatal
        console.warn('resolveCytoId: no C for ref', ref?.sc)
        return null
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

    async make_wave(w: TheC, topC: TheC, adjacent: boolean,
                    backwards = false, departing?: TheC,
                    reset_Ze = false): Promise<TheC> {
        w.c.cyto_Ze ??= new Selection()
        const Ze: Selection = w.c.cyto_Ze

        if (reset_Ze) {
            Ze.sc.topD?.empty()   // forget all bD — everything will read as new
        }
        Ze.sc.topD = await Ze.r({ cyto_root: 'Ze' })

        const dur  = (w.sc.grawave_duration as number) ?? 0.3
        const wave = _C({ CytoWave:1, duration: dur })
        if (reset_Ze) wave.sc.absolute = 1
        // wave-local counter for constraints (they don't have cyto_ids anymore —
        // see cyto_assign_ids). wave.sc.constraints is a fresh object per wave,
        // so any unique-within-this-wave key works.
        let cons_i = 0
        await Ze.process({
            n:          topC,
            process_D:  Ze.sc.topD,
            match_sc:   {},
            trace_sc:   { tracing: 1 },
 
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
                return uD.i({ tracing: 1, ...C.sc })
            },
 
            traced_fn: async (D: TheD, bD: TheD | undefined, C: TheC) => {
                let label = C.c.Se1_D?.c.T.sc.n.sc.label
                let etc = label != null ? {label} : {}
 
                if (C.sc.cyto_cons) {
                    if (!wave.sc.constraints) wave.sc.constraints = {};
                    if (!C.sc.resolved_constraint) throw `!resolved`
                    wave.sc.constraints[`c${cons_i++}`] = C.sc.resolved_constraint;
                    return
                }
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
                if (C.sc.cyto_fold) {
                    // semantically-transparent (for now) container
                    //  helps partition resolve() space (~~ nicelybranching D**)
                    return
                }
                if (C.sc.cyto_migration) {
                    // these belong to a C** but only become part of adjacent waves if etc
                    return
                }
                if (!C.sc.cyto_node) { console.warn(`unknown datatype %cyto_root:`,C); T.sc.not = 1; return }


 
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
                    // overlay data for Cytui HTML overlay system
                    if (C.sc.overlay_str)  etc.overlay_str  = C.sc.overlay_str
                    if (C.sc.overlay_kind) etc.overlay_kind = C.sc.overlay_kind
                    if (C.sc.overlay_bg)   etc.overlay_bg   = C.sc.overlay_bg
                    wave.i({ upsert: 1, id, ...etc })
                } else if (style_ch || label_ch !== null || par_ch !== null) {
                    wave.i({ upsert: 1, id, ...etc,
                        ...(style_ch          ? { style:      style_ch         } : {}),
                        ...(label_ch !== null ? { label:      C.sc.label       } : {}),
                        ...(par_ch   !== null ? { new_parent: C.sc.parent_id ?? null } : {}),
                        // always pass overlay data through on updates too
                        ...(C.sc.overlay_str  ? { overlay_str:  C.sc.overlay_str  } : {}),
                        ...(C.sc.overlay_kind ? { overlay_kind: C.sc.overlay_kind } : {}),
                        ...(C.sc.overlay_bg   ? { overlay_bg:   C.sc.overlay_bg   } : {}),
                    })
                }
            },
 
            resolved_fn: async (_T: Travel, _N: Travel[], goners: TheD[]) => {
                // walk the Ze D subtree of every goner — catches nested nodes
                // (eg marble inside a goner leaf) that were never explicitly resolved
                const emit_removes = (g: TheD) => {
                    if (g.sc.the_edge_id) {
                        wave.i({ edge_remove: 1, id: g.sc.the_edge_id })
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
            if (source) walk(source)
        }
        let adjsay = adjacent ? ' adjacent' : ''
        let empsay = !wave.oa() ? ' empty' : ''
        V.cyto && console.log(`🌊 make_wave(): upsert x${wave.o({ upsert: 1 }).length}${empsay}${adjsay}`)
 
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

    async e_Cyto_animation_request(A, w, e) {
        const story_step = e?.sc.story_step as number
        await this.cyto_update_wave(w, story_step)

        if (!w.c.supports_takeTurns) return

        // At this point: cyto_scan done, archive updated, wave pushed to gn.sc.wave.
        // Wave is ready to be read synchronously by the client.
        const client = w.c.client_w as TheC | undefined
        if (client && w.c.wants_wave_done) {
            this.elvistwo(w, client, 'Cyto_wave_done', { story_step })
        }
        // Animation plays for grawave_duration. After that, the motion is
        // visually complete and the client can proceed to its next step.
        const dur = ((w.sc.grawave_duration as number) ?? 0.3) * 1000
        setTimeout(() => {
            if (client && w.c.wants_animation_done) {
                this.elvistwo(w, client, 'Cyto_animation_done', { story_step })
            }
        }, dur + 100)
    }

//#endregion

    })
    })
</script>