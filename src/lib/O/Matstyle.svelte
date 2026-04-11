<script lang="ts">
    // Matstyle.svelte — ghost.
    //
    // Auto-swatch system for Cyto nodes.  Classifies n** particles by their
    // first sc key ("mainkey"), autovivifies a matstyle for each new type,
    // and produces cytoscape-compatible style objects.
    //
    // Replaces the hardcoded cyto_nstyle branches entirely.
    //
    // ── mainkey ──────────────────────────────────────────────────────────
    //
    //   Type identity of a particle: first key of n.sc, regardless of value.
    //   leaf, sunshine, hand, protein, etc.
    //   First keys are mutually exclusive type tags across the population.
    //
    // ── The/Styles schema ────────────────────────────────────────────────
    //
    //   Persisted in The alongside steps.  encode_toc_snap walks all
    //   The/** with Travel, so this encodes for free.
    //
    //     Styles:1
    //       matstyle:leaf
    //         style:background-color v:#1a5a2a
    //         style:color v:#b0ffb0
    //         style:shape v:ellipse
    //         style:width v:20
    //         meta:dose drives:size min:14 max:32 cap:10
    //       matstyle:sunshine
    //         style:background-color v:#8a7010
    //         style:shape v:diamond
    //         meta:dose drives:size min:22 max:66
    //
    //   Defaults are omitted (no border-width:0, no border-style:solid).
    //
    // ── cyto_node descriptor ─────────────────────────────────────────────
    //
    //   Each cyto_node particle gets:
    //     sc.matstyles = 'leaf+dose(1.86)'   — type + dose snapshot
    //     sc.style     = {...computed css}    — full cytoscape style (ref in snap)
    //
    // ── reactivity ───────────────────────────────────────────────────────
    //
    //   matstyle_restyle(key) walks the latest CytoStep's topC via
    //   C.c.source_n backlinks, recomputes styles for matching nodes,
    //   and pushes a targeted wave.  No full rescan needed.

    import { _C, objectify, type TheC } from "$lib/data/Stuff.svelte"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region palette

    // 40 maximally-distinct colours via golden-angle HSL stepping.
    MATSTYLE_PALETTE: (() => {
        const N = 40
        const colors: string[] = []
        const hsl = (h: number, s: number, l: number): string => {
            s /= 100; l /= 100
            const f = (n: number) => {
                const k = (n + h / 30) % 12
                const a = s * Math.min(l, 1 - l)
                const v = l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1))
                return Math.round(v * 255).toString(16).padStart(2, '0')
            }
            return `#${f(0)}${f(8)}${f(4)}`
        }
        for (let i = 0; i < N; i++) {
            const h = (i * 137.508) % 360
            const s = 48 + (i % 3) * 10
            const l = 38 + (i % 4) * 6
            colors.push(hsl(h, s, l))
        }
        return colors
    })(),

    MATSTYLE_SHAPES: [
        'ellipse', 'rectangle', 'round-rectangle', 'diamond',
        'hexagon', 'star', 'triangle', 'pentagon', 'tag',
    ] as string[],

//#endregion
//#region mainkey + mainkey_match

    mainkey(n: TheC): string | undefined {
        const keys = Object.keys(n.sc ?? {})
        return keys.length ? keys[0] : undefined
    },

    // Generalized rule matcher extracted from enLine.
    // Same schema as story_matching rules.
    mainkey_match(n: TheC, rules: any[] = []): {
        skip: boolean
        munging: any[]
        thence: any[]
        mainkey: string | undefined
    } {
        const munging: any[] = []
        const thence: any[] = []
        let skip = false
        const seen = new Set<string>()

        for (const rule of rules) {
            const matched = (rule.matching_any as any[]).some((entry: any) => {
                if (entry.sc_only) {
                    const want = Object.keys(entry.sc_only)
                    if (Object.keys(n.sc).length !== want.length) return false
                    return n.matches(entry.sc_only)
                }
                return n.matches(entry.sc)
            })
            if (!matched) continue
            for (const m of rule.means?.munging ?? []) munging.push(m)
            if (rule.means?.skip) skip = true
            for (const tw of rule.means?.thence_matching ?? []) {
                const key = JSON.stringify(tw)
                if (!seen.has(key)) { seen.add(key); thence.push(tw) }
            }
        }

        return { skip, munging, thence, mainkey: this.mainkey(n) }
    },

//#endregion
//#region The_Styles — container + CRUD

    The_Styles(w: TheC): TheC {
        const The = w.c.The as TheC
        if (!The) throw '!The for matstyles'
        return The.o({ Styles: 1 })[0] as TheC ?? The.i({ Styles: 1 })
    },

    matstyle_all(w: TheC): TheC[] {
        return this.The_Styles(w).o({ matstyle: 1 }) as TheC[]
    },

    matstyle_for(w: TheC, key: string): TheC | undefined {
        return this.The_Styles(w).o({ matstyle: key })[0] as TheC | undefined
    },

    // read: flat css object from all %style:* children
    ms_css(ms: TheC): Record<string, any> {
        const css: Record<string, any> = {}
        for (const s of ms.o({ style: 1 }) as TheC[]) {
            css[s.sc.style as string] = s.sc.v
        }
        return css
    },

    ms_css_get(ms: TheC, prop: string): any {
        return ms.o({ style: prop })[0]?.sc.v
    },

    ms_meta(ms: TheC, name: string): TheC | undefined {
        return ms.o({ meta: name })[0] as TheC | undefined
    },

    // write: set or remove if val matches default
    MATSTYLE_DEFAULTS: {
        'background-color': '#242424',
        'color': '#ccc',
        'shape': 'ellipse',
        'width': 20,
        'height': 20,
        'border-width': 0,
        'border-style': 'solid',
        'border-color': '#333',
    } as Record<string, any>,

    ms_css_set(ms: TheC, prop: string, val: any) {
        if (this.MATSTYLE_DEFAULTS[prop] === val) {
            const existing = ms.o({ style: prop })[0]
            if (existing) existing.drop(existing)
            return
        }
        ms.oai({ style: prop }).sc.v = val
    },

    ms_meta_set(ms: TheC, name: string, props: Record<string, any>) {
        const m = ms.oai({ meta: name })
        Object.assign(m.sc, props)
    },

//#endregion
//#region autovivify

    matstyle_get_or_create(w: TheC, key: string): TheC {
        let ms = this.matstyle_for(w, key)
        if (ms) return ms

        const styles_c = this.The_Styles(w)
        const existing = styles_c.o({ matstyle: 1 }) as TheC[]
        const idx = existing.length

        if (idx >= this.MATSTYLE_PALETTE.length) {
            w.i({ error: `matstyle palette exhausted at ${idx}` })
        }
        const bg = this.MATSTYLE_PALETTE[Math.min(idx, this.MATSTYLE_PALETTE.length - 1)]

        ms = styles_c.i({ matstyle: key })
        ms.i({ style: 'background-color', v: bg })

        this.matstyle_seed_known(ms, key)
        this.matstyle_schedule_save()
        return ms
    },

    matstyle_seed_known(ms: TheC, key: string) {
        const S = (prop: string, v: any) => ms.i({ style: prop, v })
        const M = (name: string, props: Record<string, any>) => ms.i({ meta: name, ...props })

        const seeds: Record<string, () => void> = {
            leaf:              () => { S('background-color','#1a5a2a'); S('color','#b0ffb0')
                                       M('dose', { drives:'size', min:14, max:32, cap:10 }) },
            sunshine:          () => { S('background-color','#8a7010'); S('color','#331800')
                                       S('shape','diamond'); S('width',44)
                                       M('dose', { drives:'size', min:22, max:66, cap:10 }) },
            poo:               () => { S('background-color','#5c3010'); S('color','#c88040')
                                       M('dose', { drives:'size', min:18, max:28, cap:8 }) },
            mouthful:          () => { S('background-color','#4a7a20'); S('color','#003300')
                                       S('width',10)
                                       M('dose', { drives:'size', min:6, max:46, cap:6 }) },
            material:          () => { S('background-color','#3a2810'); S('color','#ffe8c0')
                                       S('shape','round-rectangle')
                                       M('dose', { drives:'size', min:18, max:36, cap:20, key:'amount' }) },
            producing:         () => { S('background-color','#142060'); S('color','#9ab4ff')
                                       S('shape','round-rectangle'); S('width',42) },
            protein:           () => { S('background-color','#3a1a4a'); S('color','#ddc8ff')
                                       S('shape','hexagon'); S('width',24)
                                       M('dose', { drives:'size', min:18, max:42, cap:8, key:'complexity' }) },
            shelf:             () => { S('background-color','#1a4828'); S('color','#90ffc0')
                                       S('shape','round-rectangle'); S('width',24) },
            wants_enzyme:      () => { S('background-color','#6a1a08'); S('color','#ff9070')
                                       S('shape','star'); S('width',22) },
            wants_to_produce:  () => { S('background-color','#6a1a08'); S('color','#ff9070')
                                       S('shape','star'); S('width',22) },
            hand:              () => { S('background-color','#1a1a28'); S('color','#8888bb')
                                       S('shape','round-rectangle'); S('width',24)
                                       S('border-color','#5a5a9a'); S('border-width',1) },
        }
        seeds[key]?.()
    },

//#endregion
//#region apply — matstyle → cytoscape style

    matstyle_apply(ms: TheC, n: TheC): {
        label: string, style: Record<string, any>,
        isCompound?: boolean, matstyles_desc: string
    } {
        const label = this.cyto_label(n)
        const D = this.MATSTYLE_DEFAULTS
        const css = this.ms_css(ms)
        const style: Record<string, any> = {}

        style['background-color'] = css['background-color'] ?? D['background-color']
        style.color                = css['color']             ?? D['color']
        style.shape                = css['shape']             ?? D['shape']

        let size = Number(css['width'] ?? D['width'])
        let desc = ms.sc.matstyle as string

        // dose_drives:size interpolation
        const dm = this.ms_meta(ms, 'dose')
        if (dm?.sc.drives === 'size') {
            const dose_key = (dm.sc.key as string) ?? 'dose'
            let dv = n.sc[dose_key] as number | undefined
            if (dv == null) {
                for (const alt of ['dose','complexity','units','amount']) {
                    if (n.sc[alt] != null) { dv = n.sc[alt] as number; break }
                }
            }
            if (dv != null) {
                const cap    = Number(dm.sc.cap ?? 10)
                const min_sz = Number(dm.sc.min ?? 10)
                const max_sz = Number(dm.sc.max ?? 40)
                const t = Math.min(Math.max(dv, 0), cap) / cap
                size = min_sz + t * (max_sz - min_sz)
                desc += `+dose(${Math.round(dv * 100) / 100})`
            }
        }

        style.width  = Math.round(size)
        style.height = Math.round(size)

        const bw = Number(css['border-width'] ?? 0)
        if (bw > 0) {
            style['border-color'] = css['border-color'] ?? D['border-color']
            style['border-width'] = bw
            style['border-style'] = css['border-style'] ?? D['border-style']
        }

        const isCompound = !!ms.oa({ is_compound: 1 })
        if (isCompound) {
            style['background-opacity'] = 0.6
            style['text-valign'] = 'top'
            style['font-size']   = '8px'
            style['font-style']  = 'italic'
            style.padding        = '7px'
        }

        return { label, style, isCompound, matstyles_desc: desc }
    },

    hsl_to_hex(h: number, s: number, l: number): string {
        s /= 100; l /= 100
        const f = (n: number) => {
            const k = (n + h / 30) % 12
            const a = s * Math.min(l, 1 - l)
            const v = l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1))
            return Math.round(v * 255).toString(16).padStart(2, '0')
        }
        return `#${f(0)}${f(8)}${f(4)}`
    },

//#endregion
//#region restyle — live edit reactivity

    // Walk latest CytoStep topC via C.c.source_n backlinks,
    // recompute styles for nodes matching changed_key,
    // push a targeted wave.
    matstyle_restyle(changed_key: string) {
        const H = this
        let cyto_w
        try { cyto_w = H.o({ A: 'Cyto' })?.[0]?.o({ w: 'Cyto' })?.[0] } catch { return }
        if (!cyto_w) return

        const latest = (cyto_w.o({ CytoStep: 1 }) as TheC[])
            .sort((a, b) => (a.sc.step_n as number) - (b.sc.step_n as number)).at(-1)
        const topC = latest?.sc.C as TheC
        if (!topC) return

        let story_w
        try { story_w = H.Awo('Story') } catch { return }
        const ms = H.matstyle_for(story_w, changed_key)
        if (!ms) return

        const wave = _C({ CytoWave: 1, duration: 0.3 })
        const walk = (C: TheC) => {
            for (const nc of C.o({ cyto_node: 1 }) as TheC[]) {
                const n = nc.c.source_n as TheC
                if (n && H.mainkey(n) === changed_key) {
                    const nd = H.matstyle_apply(ms, n)
                    nc.sc.style = nd.style
                    nc.sc.matstyles = nd.matstyles_desc
                    wave.i({ upsert: 1, id: nc.sc.cyto_id, style: nd.style })
                }
                walk(nc)
            }
        }
        walk(topC)

        if (wave.oa({ upsert: 1 })) H._cyto_push(cyto_w, wave)
    },

//#endregion
//#region update + save

    _matstyle_save_timer: null as ReturnType<typeof setTimeout> | null,

    matstyle_schedule_save() {
        if (this._matstyle_save_timer) clearTimeout(this._matstyle_save_timer)
        this._matstyle_save_timer = setTimeout(() => {
            this._matstyle_save_timer = null
            if (typeof this.story_save === 'function') this.story_save()
        }, 5000)
    },

    // Called from UI editor.  prop is flat UI name, mapped to %style or %meta.
    matstyle_update(w: TheC, key: string, prop: string, value: any) {
        const ms = this.matstyle_for(w, key)
        if (!ms) return

        const style_map: Record<string, string> = {
            bg:           'background-color',
            color:        'color',
            shape:        'shape',
            size:         'width',
            border_width: 'border-width',
            border_color: 'border-color',
            border_style: 'border-style',
        }
        if (style_map[prop]) {
            this.ms_css_set(ms, style_map[prop], value)
            if (prop === 'size') this.ms_css_set(ms, 'height', value)
        }
        else if (prop === 'is_compound') {
            const existing = ms.o({ is_compound: 1 })[0]
            if (value && !existing)  ms.i({ is_compound: 1 })
            if (!value && existing)  existing.drop(existing)
        }
        else if (prop === 'dose_drives') {
            if (value)  this.ms_meta_set(ms, 'dose', { drives: 'size' })
            else { const m = this.ms_meta(ms, 'dose'); if (m) m.drop(m) }
        }
        else if (prop.startsWith('dose_')) {
            const sub = prop.slice(5)
            const dm = this.ms_meta(ms, 'dose')
            if (dm) dm.sc[sub] = value
        }

        this.matstyle_schedule_save()
        this.matstyle_restyle(key)
    },

//#endregion

    })
    })
</script>