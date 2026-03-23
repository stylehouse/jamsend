<script lang="ts">
    // Ghost: Cyto — mounts into the parent House via M.eatfunc({...}).
    //
    // w:Cyto runs ambientally: on each tick it finds H:LeafFarm (the Run sub-House
    // that Story is exercising), scans its particles for changes, and publishes a
    // grawave to H/%watched:graph → H.ave → Cytui.
    //
    // ── intoCyto handshake ───────────────────────────────────────────────────
    //
    //   When w:Story has w.sc.intoCyto set, story_drive calls advance() instead
    //   of schedule() after each completed step.  advance() elvisses here:
    //
    //     elvisto('Cyto', 'story_cyto_step', { story_step: n })
    //
    //   story_cyto_step scans RunH, publishes the wave, then after grawave_duration
    //   fires back:
    //
    //     elvisto('Story/Story', 'story_cyto_continue')
    //
    //   story_cyto_continue (in Story.svelte) clears the pause and starts a fresh
    //   story_drive.  Cyto never calls story_drive itself — Story-side throughout.
    //
    // ── grawave format ───────────────────────────────────────────────────────
    //
    //   { upsert: NodeDesc[], remove: string[], duration: number }
    //
    //   NodeDesc: { id: string, label: string, style: Record<string,any> }
    //
    //   Cytui applies upserts (animating existing nodes with node.animate()),
    //   removes gone ids, and relayouts.  It also maintains a full wave history
    //   so the ◀ ▶ walk-back buttons can rebuild state at any past point.
    //
    // ── particle identity rules (cyto_id) ────────────────────────────────────
    //
    //   Only particles with recognised shapes get a stable id; everything else
    //   returns null and is silently skipped.  Timekeeping noise ({self:1},
    //   {chaFrom:1}, {wasLast:1}, {sunny_streak:1}) is explicitly excluded.

    import { objectify, TheC } from "$lib/data/Stuff.svelte"
    import type { House }      from "$lib/O/Housing.svelte"
    import { onMount }         from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region w:Cyto

    // ── w:Cyto ───────────────────────────────────────────────────────────────
    // Ambient worker: finds H:LeafFarm, scans for particle changes,
    // publishes a grawave to H/%watched:graph → H.ave → Cytui.
    async Cyto(A: TheC, w: TheC) {
        const ok = this.cyto_update_wave(w)
        if (!ok) return w.i({ see: '⏳ no H:LeafFarm yet' })
        const gn = this.oai({ watched: 'graph' }).oai({ cyto_graph: 1 })
        w.i({ see: `📊 tick:${gn.sc.tick ?? 0}` })
    },

    // ── cyto_update_wave ─────────────────────────────────────────────────────
    // Context-free scan+publish.  Called both from w:Cyto (ambient) and from
    // story_cyto_step (intoCyto handshake).  Returns false when RunH is absent.
    cyto_update_wave(w: TheC): boolean {
        const H     = this as House
        const Story = H.o({ H: 'Story' })[0] as House | undefined
        const RunH  = Story?.o({ H: 'LeafFarm' })[0] as House | undefined
        if (!RunH) return false

        // Skip when nothing changed in RunH
        const tracking = w.oai({ cyto_tracking: 1 })
        const v = RunH.version
        if (tracking.sc.v === v) return true
        tracking.sc.v = v

        const wave = this.cyto_scan(w, RunH)

        // Publish to H/%watched:graph — drives H.ave → Cytui $effect
        const wa = H.oai({ watched: 'graph' })
        H.enroll_watched()
        const gn = wa.oai({ cyto_graph: 1 })
        gn.sc.wave = wave
        gn.sc.tick = ((gn.sc.tick as number) ?? 0) + 1
        wa.bump_version()

        return true
    },

    // ── cyto_scan ────────────────────────────────────────────────────────────
    // Walk RunH A→w→particles, diff against previous id set, return grawave.
    cyto_scan(w: TheC, RunH: House): { upsert: any[]; remove: string[]; duration: number } {
        const prev_n   = w.oai({ cyto_prev_ids: 1 })
        const prev_ids = new Set<string>((prev_n.sc.ids as string[]) ?? [])
        const seen     = new Set<string>()
        const upsert: any[] = []

        for (const A of RunH.o({ A: 1 }) as TheC[]) {
            for (const wk of A.o({ w: 1 }) as TheC[]) {
                for (const n of wk.o({}) as TheC[]) {
                    if (n.c.drop) continue
                    const id = this.cyto_id(n)
                    if (!id) continue
                    seen.add(id)
                    upsert.push(this.cyto_node(n, id))
                }
            }
        }

        const remove = [...prev_ids].filter(id => !seen.has(id))
        prev_n.sc.ids = [...seen]

        return {
            upsert,
            remove,
            duration: (w.sc.grawave_duration as number) ?? 0.3,
        }
    },

    // ── cyto_id ──────────────────────────────────────────────────────────────
    // Map a particle to a stable string id, or null to skip it entirely.
    // Timekeeping noise is explicitly excluded here rather than in cyto_scan
    // so that the exclusion logic is co-located with the identity rules.
    cyto_id(n: TheC): string | null {
        if (n.sc.leaf)                 return `leaf:${n.sc.leaf_id ?? n.sc.leaf}`
        if (n.sc.sunshine)             return `sun:${n.sc.A ?? 'sun'}`
        if (n.sc.poo)                  return `poo:${n.sc.A ?? 'poo'}`
        if (n.sc.material)             return `mat:${n.sc.material}`
        if (n.sc.producing)            return `prod:${n.sc.A ?? 'prod'}`
        if (n.sc.protein)              return `prot:${n.sc.protein_id ?? 'p'}`
        if (n.sc.shelf && n.sc.enzyme) return `enz_shelf`
        if (n.sc.wants_enzyme)         return `want_enz`
        if (n.sc.run)                  return `run:${n.sc.run}`
        // Timekeeping noise — skip silently
        if (n.sc.self)                 return null
        if (n.sc.chaFrom)              return null
        if (n.sc.wasLast)              return null
        if (n.sc.sunny_streak)         return null
        return null
    },

    // ── cyto_node ────────────────────────────────────────────────────────────
    // Map a particle to a Cytui node descriptor.
    // label = objectify(n) gives a compact human-readable summary.
    // style rules are keyed on particle shape; leaf size/colour scales with dose.
    cyto_node(n: TheC, id: string): any {
        const label = objectify(n)
        const style: any = {}

        if (n.sc.leaf) {
            // Green node; size and lightness scale with dose toward 2.0
            const d  = (n.sc.dose as number) ?? 0
            const sz = Math.round(16 + d * 18)
            style.backgroundColor = `hsl(120,65%,${30 + d * 16}%)`
            style.width  = sz
            style.height = sz
            style.color  = d > 1.2 ? '#002' : '#eee'

        } else if (n.sc.sunshine) {
            const d = (n.sc.dose as number) ?? 0
            style.backgroundColor = `hsl(48,92%,${44 + d * 12}%)`
            style.width  = 42
            style.height = 42
            style.shape  = 'diamond'
            style.color  = '#333'

        } else if (n.sc.poo) {
            const d  = (n.sc.dose as number) ?? 0
            const sz = Math.round(24 + Math.min(d, 8) * 2)
            style.backgroundColor = '#5a3010'
            style.width  = sz
            style.height = sz
            style.color  = '#c96'

        } else if (n.sc.material) {
            const amt = (n.sc.amount as number) ?? 0
            const sz  = Math.round(22 + Math.min(amt, 20) * 1.5)
            style.backgroundColor = `hsl(36,55%,${24 + Math.min(amt, 20) * 2}%)`
            style.width  = sz
            style.height = sz
            style.color  = '#fc9'

        } else if (n.sc.producing) {
            style.backgroundColor = '#1a3a70'
            style.width  = 44
            style.height = 44
            style.color  = '#8af'
            style.shape  = 'rectangle'

        } else if (n.sc.protein) {
            const cx = (n.sc.complexity as number) ?? 0
            style.backgroundColor = `hsl(280,45%,${20 + cx * 6}%)`
            style.width  = 30
            style.height = 30
            style.color  = '#ddf'

        } else if (n.sc.shelf) {
            const u = (n.sc.units as number) ?? 0
            style.backgroundColor = '#1a4020'
            style.width  = Math.round(24 + u * 1.5)
            style.height = 24
            style.color  = '#8d8'

        } else if (n.sc.wants_enzyme) {
            style.backgroundColor = '#402010'
            style.width  = 26
            style.height = 26
            style.color  = '#fa8'

        } else if (n.sc.run) {
            style.backgroundColor = '#181828'
            style.width  = 50
            style.height = 20
            style.shape  = 'round-rectangle'
            style.color  = '#88f'

        } else {
            style.backgroundColor = '#222'
            style.width  = 18
            style.height = 18
            style.color  = '#888'
        }

        return { id, label, style }
    },

//#endregion
//#region intoCyto handshake

    // ── story_cyto_step ──────────────────────────────────────────────────────
    // Received from w:Story / advance() when w.sc.intoCyto is set.
    // Scans RunH, publishes the wave, then after grawave_duration fires
    // story_cyto_continue back to w:Story so the drive can resume.
    async story_cyto_step(A: TheC, w: TheC, e: TheC) {
        // Re-resolve w:Cyto from H for tracking state — A/w here are Cyto's own
        this.cyto_update_wave(w)
        const dur = ((w.sc.grawave_duration as number) ?? 0.3) * 1000
        setTimeout(() => {
            this.elvisto('Story/Story', 'story_cyto_continue', {
                story_step: e?.sc.story_step,
            })
        }, dur + 80)
    },

//#endregion

    })
    })
</script>