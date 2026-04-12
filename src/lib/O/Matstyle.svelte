<script lang="ts">
    // Matstyle.svelte — ghost.
    //
    // Auto-swatch system for Cyto nodes.  Classifies n** particles by their
    // first sc key ("mainkey"), autovivifies a matstyle for each new type,
    // and produces cytoscape-compatible style objects.
    //
    // Replaces the hardcoded cyto_nstyle branches entirely.
    //
    // ── stylesC — the shared matstyle bucket ─────────────────────────────
    //
    //   All CRUD functions take stylesC as an explicit first argument rather
    //   than reaching for Story's The/Styles via Awo('Story').  This lets
    //   Cyto clients (Story, LangTiles, anything else) supply their own
    //   stylesC via the commission req — or share Story's by passing the
    //   same TheC through.
    //
    //   The_Styles(w) is retained as Story's persistence helper — it's how
    //   Story finds/creates its own {Styles:1} bucket under w.c.The.  Other
    //   clients can call it too if they want a The-backed bucket, or they
    //   can bring their own plain TheC.
    //
    //   Save-on-change is no longer triggered from inside matstyle_update.
    //   Instead, the stylesC owner (Story) does watch_c(stylesC, save_fn)
    //   in Story_plan — so every mutation through these helpers bumps
    //   stylesC.version and the watch fires, regardless of who called it.
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
    //   matstyle_restyle(cyto_w, key) walks the latest CytoStep's topC via
    //   C.c.source_n backlinks, recomputes styles for matching nodes,
    //   and pushes a targeted wave.  No full rescan needed.
    //   cyto_w is now explicit — caller decides which graph instance to
    //   restyle (could be H:Story's Cyto, or H:LangTiles's Cyto).

    import { _C, objectify, type TheC } from "$lib/data/Stuff.svelte"
    import { throttle } from "$lib/Y.svelte"
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

    mainkey(n: TheC): string | undefined {
        const keys = Object.keys(n.sc ?? {})
        return keys.length ? keys[0] : undefined
    },


//#endregion
//#region The_Styles — Story's persistence finder

    // The_Styles(w): Story's specific way of finding its styles bucket —
    // it lives under w.c.The/{Styles:1}.  Other clients (LangTiles etc.)
    // can either call this with their own w that has a .c.The, or bring
    // their own plain TheC with {Styles:1} sc.
    The_Styles(w: TheC): TheC {
        const The = w.c.The as TheC
        if (!The) throw '!The for matstyles'
        return The.o({ Styles: 1 })[0] as TheC ?? The.i({ Styles: 1 })
    },

//#endregion
//#region CRUD — all take stylesC explicitly

    matstyle_all(stylesC: TheC): TheC[] {
        return stylesC.o({ matstyle: 1 }) as TheC[]
    },

    matstyle_for(stylesC: TheC, key: string): TheC | undefined {
        return stylesC.o({ matstyle: key })[0] as TheC | undefined
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

    matstyle_get_or_create(stylesC: TheC, key: string): TheC {
        let ms = this.matstyle_for(stylesC, key)
        if (ms) return ms

        const existing = stylesC.o({ matstyle: 1 }) as TheC[]
        const idx = existing.length

        if (idx >= this.MATSTYLE_PALETTE.length) {
            console.error(`matstyle palette exhausted at ${idx}`)
        }
        const bg = this.MATSTYLE_PALETTE[Math.min(idx, this.MATSTYLE_PALETTE.length - 1)]

        ms = stylesC.i({ matstyle: key })
        ms.i({ style: 'background-color', v: bg })

        this.matstyle_seed_known(ms, key)
        stylesC.bump_version()   // watch_c on stylesC will pick this up for save
        return ms
    },

    matstyle_seed_known(ms: TheC, key: string) {
        const S = (prop: string, v: any) => this.ms_css_set(ms, prop, v)
        const M = (name: string, props: Record<string, any>) => this.ms_meta_set(ms, name, props)
    
        const seeds: Record<string, () => void> = {
            w: () => { 
                M('is_compound', { v: 1 })
                M('label', { fmt: '%s', keys: 'w' })
            },
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
                                       S('border-color','#5a5a9a'); S('border-width',1)
                                    //    M('is_compound', { v: 1 })
                                       M('label', { fmt: '%s', keys: 'hand' }) },
        }
        seeds[key]?.()
    },

//#endregion
//#region apply — matstyle → cytoscape style

    matstyle_apply(ms: TheC, n: TheC): {
        label: string, style: Record<string, any>,
        isCompound?: boolean, matstyles_desc: string
    } {
        const label = this.matstyle_label(ms, n)
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

        const isCompound = !!this.ms_meta(ms, 'is_compound')?.sc.v
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

    // Label format — new %meta:label,fmt:"%s",keys:"w" 
    //    Default when absent: cyto_label(n) (existing behaviour).
    //    fmt||="%s" is sprintf-style %s substitution from the named keys.

    matstyle_label(ms: TheC, n: TheC): string {
        const lm = this.ms_meta(ms, 'label')
        if (!lm?.sc.fmt) return (lm && this.mainkey(n)) ?? this.cyto_label(n)
        const keys = String(lm.sc.keys ?? '').split('+').filter(Boolean)
        let i = 0
        return String(lm.sc.fmt).replace(/\\n/g,"\n").replace(/%(s|d)/g, (_, t) => {
            const v = n.sc[keys[i++]]
            if (v == null) return ''
            return t === 'd' ? Number(v).toFixed(3) : String(v)
        })
    },


//#endregion
//#region restyle — live edit reactivity

    // Walk latest CytoStep topC via C.c.source_n backlinks,
    // recompute styles for nodes matching changed_key,
    // push a targeted wave.
    // Caveat: this updates style + label only.
    //
    // cyto_w and stylesC are now both explicit — caller decides which
    // graph instance's nodes to restyle and where the updated ms lives.
    // Save-on-change is handled by watch_c on stylesC, not here.
    matstyle_restyle(cyto_w: TheC, stylesC: TheC, changed_key: string) {
        const H = this
        if (!cyto_w) return

        const latest = (cyto_w.o({ CytoStep: 1 }) as TheC[])
            .sort((a, b) => (a.sc.step_n as number) - (b.sc.step_n as number)).at(-1)
        const topC = latest?.sc.C as TheC
        if (!topC) return

        const ms = H.matstyle_for(stylesC, changed_key)
        if (!ms) return

        const wave = _C({ CytoWave: 1, duration: 0.3 })
        const walk = (C: TheC) => {
            for (const nc of C.o({ cyto_node: 1 }) as TheC[]) {
                const n = nc.c.source_n as TheC
                if (n && H.mainkey(n) === changed_key) {
                    const nd = H.matstyle_apply(ms, n)
                    nc.sc.style = nd.style
                    nc.sc.label = nd.label
                    nc.sc.matstyles = nd.matstyles_desc
                    wave.i({ upsert: 1, id: nc.sc.cyto_id,
                        style: nd.style, label: nd.label })
                }
                walk(nc)
            }
        }
        walk(topC)

        if (wave.oa({ upsert: 1 })) H._cyto_push(cyto_w, wave)
    },

//#endregion
//#region update

    // Called from UI editor.  prop is flat UI name, mapped to %style or %meta.
    //
    // stylesC and cyto_w are now both explicit.  Save-on-change happens
    // through watch_c on stylesC (wired by the stylesC owner, eg Story)
    // — matstyle_update just bumps stylesC.version and lets the watch fire.
    matstyle_update(cyto_w: TheC, stylesC: TheC, key: string, prop: string, value: any) {
        const ms = this.matstyle_for(stylesC, key)
        if (!ms) return

        const style_map: Record<string, string> = {
            bg:           'background-color',
            color:        'color',
            shape:        'shape',
            size:         'width',
            border_width: 'border-width',
            border_color: 'border-color',
        }
        // ── style props (background-color, color, shape, width, border-*) ────
        // These map a flat UI prop name (bg, color, shape, size, ...) to the
        // real cytoscape css property name stored under %style:$prop,v:$val.
        //
        // value === null is the editor's "remove this row" signal — drop the
        // %style:$prop child entirely so the matstyle falls back to the default.
        // ms_css_set already drops when val matches MATSTYLE_DEFAULTS, but here
        // we drop unconditionally because the user explicitly clicked ×.
        //
        // 'size' is a UI convenience that maps to 'width' but also mirrors to
        // 'height' — keeps nodes square without exposing two inputs.  If the
        // user later wants non-square nodes we'd add a separate 'height' prop.
        if (style_map[prop]) {
            const css_prop = style_map[prop]
            if (value == null) {
                const ex = ms.o({ style: css_prop })[0]
                if (ex) ex.drop(ex)
            } else {
                this.ms_css_set(ms, css_prop, value)
                if (prop === 'size') this.ms_css_set(ms, 'height', value)
            }
        }
        else if (prop === 'is_compound') {
            if (value) this.ms_meta_set(ms, 'is_compound', { v: 1 })
            else { const m = this.ms_meta(ms, 'is_compound'); if (m) m.drop(m) }
        }
        else if (prop === 'label_keys') {
            if (value == null || value === '') {
                const m = this.ms_meta(ms, 'label'); if (m) m.drop(m)
            } else {
                const lm = this.ms_meta(ms, 'label') ?? ms.i({ meta: 'label' })
                lm.sc.keys = value
                delete lm.sc.key   // canonicalise to plural
            }
        }
        else if (prop === 'label_fmt') {
            const lm = this.ms_meta(ms, 'label')
            if (!lm) return
            if (value) lm.sc.fmt = value
            else delete lm.sc.fmt
        }
        else if (prop === 'dose_drives') {
            if (value)  this.ms_meta_set(ms, 'dose', { drives: 'size' })
            else { const m = this.ms_meta(ms, 'dose'); if (m) m.drop(m) }
        }
        else if (prop === 'dose_key') {
            const dm = this.ms_meta(ms, 'dose')
            if (dm) dm.sc.key = value
        }
        else if (prop.startsWith('dose_')) {
            const sub = prop.slice(5)   // min, max, cap
            const dm = this.ms_meta(ms, 'dose')
            if (dm) dm.sc[sub] = Number(value)
        }
    
        ms.bump_version()
        stylesC.bump_version()   // watch_c on stylesC will pick this up for save
        this.matstyle_restyle(cyto_w, stylesC, key)
    },

//#endregion

    })
    })
</script>