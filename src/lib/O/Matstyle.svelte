<script lang="ts">
    // Matstyle.svelte — ghost.
    //
    // Auto-swatch system for Cyto nodes.  Classifies n** particles by their
    // first sc key ("mainkey"), autovivifies a matstyle for each new type,
    // and produces cytoscape-compatible style objects.
    //
    // Replaces the hardcoded cyto_nstyle branches.  %w compound containers
    // keep their own structural styling via matstyle_w_style (not in The).
    //
    // ── mainkey ──────────────────────────────────────────────────────────
    //
    //   The type identity of a particle: its first sc key, regardless of
    //   whether the value is 1 or something else.  leaf, sunshine, hand,
    //   protein, etc.  The first key of any sc in the population should
    //   never occur as a non-first key of any sc in the population — i.e.
    //   mainkeys are mutually exclusive type tags.
    //
    // ── mainkey_match ────────────────────────────────────────────────────
    //
    //   Generalized rule matcher extracted from enLine.  Takes n + rules,
    //   returns {skip, munging, thence, mainkey} without touching Travel.
    //   enLine in Text.svelte calls this internally for DRY.
    //
    // ── The/Styles ───────────────────────────────────────────────────────
    //
    //   Persisted alongside The/step:N in toc.snap.
    //   encode_toc_snap walks all The/** with Travel, so Styles:1 and its
    //   matstyle:* children are encoded for free.
    //
    //     The/
    //       Styles:1
    //         matstyle:leaf, bg:#1a5a2a, color:#b0ffb0, shape:ellipse, size:20
    //         matstyle:sunshine, bg:#8a7010, color:#331800, shape:diamond, size:44,
    //                  dose_drives:size, dose_min:22, dose_max:66
    //
    // ── dose_drives ──────────────────────────────────────────────────────
    //
    //   A matstyle with dose_drives:'size' reads n.sc.dose and interpolates
    //   between dose_min and dose_max.  The normalized range is [0, dose_cap]
    //   where dose_cap defaults to 10 (adjustable per matstyle).
    //   Applied AFTER the base size from the matstyle, as a multiplier on
    //   the size field.

    import { _C, objectify, type TheC } from "$lib/data/Stuff.svelte"
    import { onMount } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region palette

    // 40 maximally-distinct colours via golden-angle HSL stepping.
    // Vary saturation and lightness band to avoid adjacent hues looking alike.
    // Stored as hex strings; assigned in emergence order to new mainkeys.
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
            const s = 48 + (i % 3) * 10      // 48, 58, 68
            const l = 38 + (i % 4) * 6       // 38, 44, 50, 56
            colors.push(hsl(h, s, l))
        }
        return colors
    })(),

    MATSTYLE_SHAPES: [
        'ellipse', 'rectangle', 'round-rectangle', 'diamond',
        'hexagon', 'star', 'triangle', 'pentagon', 'tag',
    ] as string[],

//#endregion
//#region mainkey

    // The type identity of a particle: first key of n.sc.
    mainkey(n: TheC): string | undefined {
        const keys = Object.keys(n.sc ?? {})
        return keys.length ? keys[0] : undefined
    },

    // Generalized rule matcher.  Extracted from enLine for DRY.
    //
    // Rule schema (same as story_matching):
    //   { matching_any: [ {sc:{...}} | {sc_only:{...}} ],
    //     means: { skip?, munging?: [{sc:{key:1}, type}], thence_matching? } }
    //
    // Returns classification without touching Travel or encoding.
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
//#region The_Styles

    // The/Styles:1 container — lazy-created under w.c.The.
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

//#endregion
//#region autovivify

    // Called during cyto_scan when a new mainkey appears.
    // Seeds with a colour from the palette + sensible defaults.
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

        ms = styles_c.i({
            matstyle: key,
            bg,
            color: '#ccc',
            shape: 'ellipse',
            size: 20,
            border_color: '#333',
            border_width: 0,
        })

        this.matstyle_seed_known(ms, key)
        this.matstyle_schedule_save()
        return ms
    },

    // Override defaults for well-known types.  Runs once on first creation.
    matstyle_seed_known(ms: TheC, key: string) {
        const seeds: Record<string, Record<string, any>> = {
            leaf:              { bg: '#1a5a2a', color: '#b0ffb0', shape: 'ellipse', size: 20,
                                 dose_drives: 'size', dose_min: 14, dose_max: 32 },
            sunshine:          { bg: '#8a7010', color: '#331800', shape: 'diamond', size: 44,
                                 dose_drives: 'size', dose_min: 22, dose_max: 66 },
            poo:               { bg: '#5c3010', color: '#c88040', shape: 'ellipse', size: 20,
                                 dose_drives: 'size', dose_min: 18, dose_max: 28 },
            mouthful:          { bg: '#4a7a20', color: '#003300', shape: 'ellipse', size: 10,
                                 dose_drives: 'size', dose_min: 6, dose_max: 46 },
            material:          { bg: '#3a2810', color: '#ffe8c0', shape: 'round-rectangle', size: 20,
                                 dose_drives: 'size', dose_min: 18, dose_max: 36 },
            producing:         { bg: '#142060', color: '#9ab4ff', shape: 'round-rectangle', size: 42 },
            protein:           { bg: '#3a1a4a', color: '#ddc8ff', shape: 'hexagon', size: 24,
                                 dose_drives: 'size', dose_min: 18, dose_max: 42 },
            shelf:             { bg: '#1a4828', color: '#90ffc0', shape: 'round-rectangle', size: 24 },
            wants_enzyme:      { bg: '#6a1a08', color: '#ff9070', shape: 'star', size: 22 },
            wants_to_produce:  { bg: '#6a1a08', color: '#ff9070', shape: 'star', size: 22 },
            hand:              { bg: '#1a1a28', color: '#8888bb', shape: 'round-rectangle', size: 24,
                                 border_color: '#5a5a9a', border_width: 1, is_compound: 1 },
        }
        const s = seeds[key]
        if (s) Object.assign(ms.sc, s)
    },

//#endregion
//#region apply

    // Build a cytoscape-compatible {label, style, isCompound} from matstyle + live n.
    // Replaces the old cyto_nstyle() entirely.
    matstyle_apply(ms: TheC, n: TheC): { label: string, style: Record<string, any>, isCompound?: boolean } {
        const label = this.cyto_label(n)
        const style: Record<string, any> = {}

        style['background-color'] = ms.sc.bg ?? '#242424'
        style.color = ms.sc.color ?? '#666'
        style.shape = ms.sc.shape ?? 'ellipse'

        let size = (ms.sc.size as number) ?? 20

        // dose_drives: interpolate size from n.sc[dose_key]
        // dose_key defaults to 'dose'; could be 'complexity', 'units', 'amount', etc.
        if (ms.sc.dose_drives === 'size') {
            // find dose-like value: check common keys
            const dose_key = ms.sc.dose_key ?? 'dose'
            let dv = n.sc[dose_key] as number | undefined
            // fallback: scan for 'complexity', 'units', 'amount' if dose not found
            if (dv == null) {
                for (const alt of ['dose', 'complexity', 'units', 'amount']) {
                    if (n.sc[alt] != null) { dv = n.sc[alt] as number; break }
                }
            }
            if (dv != null) {
                const cap = (ms.sc.dose_cap as number) ?? 10
                const min_sz = (ms.sc.dose_min as number) ?? 10
                const max_sz = (ms.sc.dose_max as number) ?? 40
                const t = Math.min(Math.max(dv, 0), cap) / cap
                size = min_sz + t * (max_sz - min_sz)
            }
        }

        style.width = Math.round(size)
        style.height = Math.round(size)

        if (ms.sc.border_width) {
            style['border-color'] = ms.sc.border_color ?? '#333'
            style['border-width'] = ms.sc.border_width
            style['border-style'] = ms.sc.border_style ?? 'solid'
        }

        const isCompound = !!ms.sc.is_compound
        if (isCompound) {
            style['background-opacity'] = 0.6
            style['text-valign'] = 'top'
            style['font-size'] = '8px'
            style['font-style'] = 'italic'
            style.padding = '7px'
        }

        return { label, style, isCompound }
    },

    // %w compound containers get structural styling, not matstyle-driven.
    // Hue derived deterministically from the w name.
    matstyle_w_style(wname: string): Record<string, any> {
        const hue = (wname.split('').reduce((a, c) => a + c.charCodeAt(0), 0) * 137.508) % 360
        const hx = (h: number, s: number, l: number) => this.hsl_to_hex(h, s, l)
        return {
            'background-color': hx(hue, 20, 10), 'background-opacity': 0.5,
            'border-color': hx(hue, 30, 25), 'border-width': 1, 'border-style': 'dashed',
            'text-valign': 'top', 'text-halign': 'center', padding: '12px',
            'font-size': '9px', 'font-weight': 'bold', 'font-style': 'italic',
            color: hx(hue, 25, 35),
        }
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
//#region save + update

    _matstyle_save_timer: null as ReturnType<typeof setTimeout> | null,

    // Throttled auto-save — 5s after last matstyle change.
    matstyle_schedule_save() {
        if (this._matstyle_save_timer) clearTimeout(this._matstyle_save_timer)
        this._matstyle_save_timer = setTimeout(() => {
            this._matstyle_save_timer = null
            this.story_save?.()
        }, 5000)
    },

    // Called from the UI editor when a property changes.
    // Mutates ms.sc directly, bumps graph, schedules save.
    matstyle_update(w: TheC, key: string, prop: string, value: any) {
        const ms = this.matstyle_for(w, key)
        if (!ms) return
        ms.sc[prop] = value
        this.matstyle_schedule_save()
        // bump graph so Cytui's $effect re-fires
        const wa = this.o({ watched: 'graph' })?.[0]
        wa?.bump_version()
        this.main()
    },

//#endregion

    })
    })
</script>
