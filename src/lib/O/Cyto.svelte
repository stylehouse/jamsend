<script lang="ts">
    import { onMount } from "svelte";
    import { TheC, objectify } from "$lib/data/Stuff.svelte";
    import type { House } from "$lib/O/Housing.svelte";

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region w:Cyto

    // ── w:Cyto ──────────────────────────────────────────────────────────────
    // Ambient worker: finds H:LeafFarm, scans for particle changes,
    // publishes a grawave to H/%watched:graph → H.ave → Cytui.
    async Cyto(A: TheC, w: TheC, e: TheC) {
        const ok = this.cyto_update_wave()
        if (!ok) return w.i({ see: '⏳ no H:LeafFarm yet' })
        // see is set inside cyto_update_wave via w context stored in gn.sc.see_w
        // so just update here
        const gn = (this as House).oai({ watched: 'graph' }).oai({ cyto_graph: 1 })
        w.i({ see: `📊 tick:${gn.sc.tick ?? 0}` })
    },

    // ── core scan/publish (context-free, usable from any handler) ────────────
    cyto_update_wave(): boolean {
        const H     = this as House
        const Story = H.o({ H: 'Story' })[0] as House | undefined
        const RunH  = Story?.o({ H: 'LeafFarm' })[0] as House | undefined
        if (!RunH) return false

        // Locate w:Cyto to hold scan state across calls
        const cytoA = H.o({ A: 'Cyto' })[0] as TheC | undefined
        const cytoW = cytoA?.o({ w: 'Cyto' })[0] as TheC | undefined
        if (!cytoW) return false

        // Skip scan when nothing changed in RunH
        const tracking = cytoW.oai({ cyto_tracking: 1 })
        const v = RunH.version
        if (tracking.sc.v === v) return true
        tracking.sc.v = v

        const wave = this.cyto_scan(cytoW, RunH)

        // Publish to H/%watched:graph (drives H.ave → Cytui $effect)
        const wa = H.oai({ watched: 'graph' })
        H.enroll_watched()
        const gn = wa.oai({ cyto_graph: 1 })
        gn.sc.wave = wave
        gn.sc.tick = ((gn.sc.tick as number) ?? 0) + 1
        wa.bump_version()

        return true
    },

    // ── scan RunH and return a grawave ────────────────────────────────────────
    cyto_scan(w: TheC, RunH: House): { upsert: any[]; remove: string[]; duration: number } {
        const prev_n   = w.oai({ cyto_prev_ids: 1 })
        const prev_ids = new Set<string>((prev_n.sc.ids as string[]) ?? [])
        const seen     = new Set<string>()
        const upsert: any[] = []

        for (const A of RunH.o({ A: 1 }) as TheC[]) {
            for (const wk of A.o({ w: 1 }) as TheC[]) {
                for (const n of wk.o({}) as TheC[]) {
                    if (n.c.drop) continue
                    const id = this.cyto_id(n, A, wk)
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

    // ── particle → stable id ─────────────────────────────────────────────────
    cyto_id(n: TheC, A: TheC, w: TheC): string | null {
        if (n.sc.leaf)         return `leaf:${n.sc.leaf_id ?? n.sc.leaf}`
        if (n.sc.sunshine)     return `sun:${A.sc.A}/${w.sc.w}`
        if (n.sc.poo)          return `poo:${A.sc.A}/${w.sc.w}`
        if (n.sc.material)     return `mat:${A.sc.A}:${n.sc.material}`
        if (n.sc.producing)    return `prod:${A.sc.A}`
        if (n.sc.protein)      return `prot:${n.sc.protein_id ?? 'p'}`
        if (n.sc.shelf && n.sc.enzyme) return `enz_shelf:${A.sc.A}`
        if (n.sc.wants_enzyme) return `want_enz:${A.sc.A}`
        if (n.sc.run)          return `run:${n.sc.run}`
        // Timekeeping noise — skip
        if (n.sc.self)         return null
        if (n.sc.chaFrom)      return null
        if (n.sc.wasLast)      return null
        if (n.sc.sunny_streak) return null
        return null
    },

    // ── particle → cyto node descriptor ──────────────────────────────────────
    cyto_node(n: TheC, id: string): any {
        const label = objectify(n)
        const style: any = {}

        if (n.sc.leaf) {
            const d  = (n.sc.dose as number) ?? 0
            const sz = Math.round(16 + d * 18)
            // greener and larger as dose grows toward 2.0
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
            const d = (n.sc.dose as number) ?? 0
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
//#region cytick handshake

    // ── story_set_cytick ─────────────────────────────────────────────────────
    // Received by H:Story / A:Story / w:Story.
    // Toggle run.sc.cytick and re-analyse so StoryRun UI updates.
    async story_set_cytick(A: TheC, w: TheC, e: TheC) {
        const run = w.o({ run: 1 })[0]
        if (!run) return
        run.sc.cytick = !!e?.sc.cytick
        ;(this as any).story_analysis(w)
    },

    // ── story_cyto_step ──────────────────────────────────────────────────────
    // Sent by Story snap_step when cytick is on → H:Mundo / A:Cyto / w:Cyto.
    // Scans farm, then after grawave duration acks Story to continue.
    async story_cyto_step(A: TheC, w: TheC, e: TheC) {
        this.cyto_update_wave()
        const dur = ((w.sc.grawave_duration as number) ?? 0.3) * 1000
        setTimeout(() => {
            ;(this as House).elvisto('Story/Story', 'story_cyto_ack', {
                story_step: e?.sc.story_step,
            })
        }, dur + 80)
    },

    // ── story_cyto_ack ───────────────────────────────────────────────────────
    // Sent by story_cyto_step after animation; received by H:Story / w:Story.
    // Clears pause and restarts story_drive.
    async story_cyto_ack(A: TheC, w: TheC, e?: TheC) {
        const run = w.o({ run: 1 })[0]
        if (!run) return
        run.sc.paused = false
        delete (run.c as any).cyto_waiting

        // Story_subHouse is the new name for Story_init
        const sub = (this as any).Story_subHouse(A, w)
        if (sub) (this as any).story_drive(sub.Run, w, run)
    },

//#endregion

    })
    })
</script>