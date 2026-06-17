<script lang="ts">
    // SurprisePopover — the surprise_read conflict, lifted out of the doc list and
    // thrown clear of the minimap as a diagram-label "explosion" wired to its Interest.
    //
    //   When a Doc's auto-save was parked because disk diverged under the open edit
    //   (req_LiesStore_writeCarefully stamps good/%surprise_read — text/dige/disk_dige
    //   on sc, theirs off-snap on c.disk_text), the IDE escalates it as a "something
    //   big wants your attention" moment.  Interests *are* channels; the surprise_read
    //   is this Interest's business, so the surface pops out of the Interest channel.
    //
    //   Geometry: a position:fixed bordered box that floats just LEFT of the minimap
    //   (over the editor, clear of the minimap proper), anchored to the active Interest
    //   cap (.isx-active) — its top-right corner sits off the cap's corner and a short
    //   connector line runs back to it, so it reads as a big label exploding off that
    //   Interest on the diagram.  The wider box gives the diff real room.  V collapses
    //   the body; Esc dismisses (the inline DocRow row remains as fallback); resolving
    //   the conflict — keep mine / take theirs — clears it.  No × kill button.
    //
    //   We reach w:Lies the same way Liesui does: H.ave's %examining particle carries
    //   c.w and bumps its version each w:Lies tick (watch_c), so this stays live.

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import Vexpandy from "$lib/O/ui/Vexpandy.svelte"
    import DocDiff  from "$lib/O/ui/DocDiff.svelte"

    let { H }: { H: House } = $props()

    const GAP = 26      // px the box sits left of the cap — the tail's reach
    const TAIL_H = 18   // px height of the speech-bubble tail base on the box edge

    // portal — relocate the box to <body>.  It's rendered under .lmm (the minimap),
    //  whose backdrop-filter establishes a containing block for fixed descendants;
    //  without this the box would anchor to the minimap rect, not the viewport, so its
    //  position:fixed coords wouldn't match the cap's getBoundingClientRect.
    function portal(node: HTMLElement | SVGElement) {
        document.body.appendChild(node)
        return { destroy() { node.remove() } }
    }

    // ── reach w:Lies (mirror Liesui) ──────────────────────────────────────
    let ex: TheC | undefined = $state()
    $effect(() => { ex = H.ave.ob({ examining: 1 })[0] as TheC | undefined })

    // ── scan w:Lies/req:Store for the first Good carrying a surprise_read ──
    type Conflict = { path: string; mine: string; theirs: string | undefined }
    let conflict: Conflict | null = $derived.by(() => {
        ex?.ob()
        const w = ex?.c?.w as TheC | undefined
        if (!w) return null
        const store = (w.ob({ req: 'Store' }) as TheC[])[0] as TheC | undefined
        if (!store) return null
        for (const g of store.ob({ Good: 1, type: 'text/Doc' }) as TheC[]) {
            void g.vers
            const sr = (g.o({ surprise_read: 1 }) as TheC[])[0] as TheC | undefined
            if (sr) {
                void sr.version
                return {
                    path:   g.sc.path as string,
                    mine:   (sr.sc.text as string | undefined) ?? '',
                    theirs: sr.c.disk_text as string | undefined,
                }
            }
        }
        return null
    })

    // ── open / dismiss ────────────────────────────────────────────────────
    let dismissed = $state(false)
    let expanded  = $state(true)
    let last_path = $state<string | null>(null)
    $effect(() => {
        const p = conflict?.path ?? null
        if (p !== last_path) { last_path = p; dismissed = false; expanded = true }
    })
    let open = $derived(!!conflict && !dismissed)

    // ── anchor to the owning Interest cap ──────────────────────────────────
    //   Owner = the Interest whose Waft contains the conflicted Doc (Lies_find_doc_in_-
    //   wafts → waft_key → the .isx-cap[data-waft] in the strip), falling back to the
    //   foreground .isx-active cap, then the strip.  Measure its left-centre in viewport
    //   coords: the box's top-right corner lands GAP px to its left at the same y, so the
    //   connector line points straight back at it.  (position:fixed + portal, not
    //   position:absolute: the minimap host clips absolute descendants — overflow:hidden —
    //   so a wide callout over the editor would be guillotined at the minimap edge.)
    let owner_waft = $derived.by(() => {
        const w = ex?.c?.w as TheC | undefined
        if (!w || !conflict) return undefined
        const found = H.Lies_find_doc_in_wafts(w, conflict.path) as { waft_key?: string } | undefined
        return found?.waft_key
    })
    function owner_cap_el(): HTMLElement | null {
        return ((owner_waft && document.querySelector(`.isx-cap[data-waft="${CSS.escape(owner_waft)}"]`))
             ?? document.querySelector('.isx-active')
             ?? document.querySelector('.isx')) as HTMLElement | null
    }

    let box_el = $state<HTMLElement>()
    // Box placement: rough — clientWidth (not innerWidth, which counts the scrollbar)
    //  so the box's right edge lands ~GAP left of the cap.  Exactness is the beam's job.
    //  Keep the last anchor when the cap is momentarily absent (a strip re-render) rather
    //  than dislodging the box to the fallback corner.
    let anchor = $state<{ rightPx: number; topY: number } | null>(null)
    function measure() {
        const cap = owner_cap_el()
        if (!cap) return
        const r = cap.getBoundingClientRect()
        anchor = { rightPx: document.documentElement.clientWidth - r.left, topY: r.top + r.height / 2 }
    }

    // The connector beam: drawn between the box's ACTUAL right edge and the cap's ACTUAL
    //  left edge (both measured), so it lands on the Interest exactly regardless of any
    //  drift in the box's CSS placement.  Re-measured after the box lays out.
    let beam = $state<{ left: number; top: number; width: number } | null>(null)
    function reflow_beam() {
        const cap = owner_cap_el()
        if (!cap || !box_el) return   // keep last beam — don't drop the tail on a re-render
        const cr = cap.getBoundingClientRect()
        const br = box_el.getBoundingClientRect()
        beam = { left: br.right, top: cr.top + cr.height / 2, width: Math.max(0, cr.left - br.right) }
    }
    $effect(() => {
        if (!open) return
        void conflict?.path; void owner_waft; void expanded   // re-sync on conflict / owner / size
        const sync = () => { measure(); reflow_beam() }
        sync()
        const id = requestAnimationFrame(sync)   // after the box lays out at the new anchor
        window.addEventListener('resize', sync)
        window.addEventListener('scroll', sync, true)
        return () => {
            window.removeEventListener('resize', sync)
            window.removeEventListener('scroll', sync, true)
            cancelAnimationFrame(id)
        }
    })

    let box_style = $derived(anchor
        ? `top:${Math.max(8, anchor.topY)}px; right:${anchor.rightPx + GAP}px;`
        : `top:56px; right:calc(var(--lte-minimap-w, 320px) + ${GAP}px);`)

    // Esc tucks it away to un-clutter without losing it: first Esc collapses the body
    //  to the slim header (quick "get this out of my way while I work"), a second Esc
    //  dismisses entirely.  Capture so it wins even while focus is in CodeMirror.
    $effect(() => {
        if (!open) return
        const handler = (e: KeyboardEvent) => {
            if (e.key !== 'Escape') return
            e.preventDefault()
            if (expanded) expanded = false   // tuck — header/connector stay, recoverable via V
            else          dismissed = true   // already tucked — let it go
        }
        window.addEventListener('keydown', handler, true)
        return () => window.removeEventListener('keydown', handler, true)
    })

    // ── actions ─────────────────────────────────────────────────────────
    function keep_mine()   { if (conflict) H.i_elvisto('Lies/Lies', 'Lies_surprise_keep_mine',   { path: conflict.path }) }
    function take_theirs() { if (conflict) H.i_elvisto('Lies/Lies', 'Lies_surprise_take_theirs', { path: conflict.path }) }

    // Escalate to Lies: open the doc (its DocRow glows + carries the inline keep/take/
    //  diff), dismiss, then scroll the Lies House into view (the durable seam).
    function escalate() {
        if (!conflict) return
        const path = conflict.path
        H.i_elvisto('Lang/Lang', 'Dock_open', { path })
        dismissed = true
        setTimeout(() => H.top_House().scroll_to_house?.(H), 50)
    }
</script>

{#if open && conflict}
    <!-- One portaled overlay holds both the box and the tail.  Portaling a SINGLE node
         (not two Svelte-managed siblings) keeps the strip/minimap DOM Svelte owns intact
         — appending two separate nodes to <body> corrupted it on the next re-render. -->
    <div class="srp-overlay" use:portal>
        {#if beam}
            <!-- speech-bubble tail: filled triangle from the box's right edge to the cap,
                 same fill/stroke as the box, behind it so the base tucks under. -->
            <svg class="srp-beam" aria-hidden="true"
                 style="left:{beam.left - 1}px; top:{beam.top - TAIL_H / 2}px; width:{beam.width + 1}px; height:{TAIL_H}px;">
                <path d="M0,0 L{beam.width + 1},{TAIL_H / 2} L0,{TAIL_H}"
                      fill="#160f06" stroke="#5a3010" stroke-width="1" stroke-linejoin="round" />
            </svg>
        {/if}
        <div class="srp" bind:this={box_el} style={box_style}>
        <div class="srp-hdr">
            <span class="srp-warn" title="this file changed on disk while you were editing — your save is held">
                ⚠ disk changed under your edit
            </span>
            <span class="srp-path" title={conflict.path}>{conflict.path}</span>
            <button class="srp-btn srp-keep"  onclick={keep_mine}
                    title="overwrite disk with your edit">keep mine</button>
            <button class="srp-btn srp-take"  onclick={take_theirs}
                    title="discard your edit and reload from disk">take theirs</button>
            <button class="srp-goto" onclick={escalate}
                    title="open in editor and scroll to Lies">go to Lies ↓</button>
            <Vexpandy bind:expanded />
        </div>
        {#if expanded}
            <div class="srp-body">
                {#if conflict.theirs !== undefined}
                    <DocDiff mine={conflict.mine} theirs={conflict.theirs} />
                {:else}
                    <div class="srp-note">disk version not loaded (page reloaded) — “take theirs” to fetch it.</div>
                {/if}
            </div>
        {/if}
        </div>
    </div>
{/if}

<style>
    /* The diagram-label box — floats clear of the minimap, off the Interest's corner.
       overflow:visible so the connector stub (::after) and the offset explosion plate
       (::before), which both sit outside the box, aren't clipped.  The body scrolls
       internally (DocDiff has its own max-height). */
    /* portaled overlay — full viewport, click-through; holds box + tail in one node. */
    .srp-overlay {
        position: fixed; inset: 0;
        z-index: 600;
        pointer-events: none;
    }
    .srp {
        position: fixed;
        z-index: 1;            /* above the tail within the overlay */
        pointer-events: auto;  /* the box is interactive; the overlay is not */
        width: clamp(360px, 44vw, 60vw);
        overflow: visible;
        display: flex; flex-direction: column;
        background: #160f06;
        border: 1px solid #5a3010;
        border-radius: 4px;
        box-shadow: 0 6px 30px rgba(0,0,0,0.7);
        font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
        font-size: 11px; color: #ccc;
    }
    /* speech-bubble tail — portaled sibling, sits just behind the box (lower z-index)
       so its base tucks under the box's right border into one continuous bubble. */
    .srp-beam {
        position: fixed;
        z-index: 0;            /* behind the box within the overlay — base tucks under */
        pointer-events: none;
        overflow: visible;
    }

    .srp-hdr {
        display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
        padding: 5px 10px; background: #1a1208; border-bottom: 1px solid #2a1c08;
        min-height: 28px; flex-shrink: 0;
    }
    .srp-warn { font-size: 11px; color: #d39; white-space: nowrap; flex-shrink: 0; }
    .srp-path {
        font-size: 11px; color: #9ab; flex: 1;
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .srp-btn {
        font-size: 11px; border-radius: 3px; cursor: pointer;
        padding: 1px 7px; white-space: nowrap; flex-shrink: 0;
    }
    .srp-keep { background: #15301a; border: 1px solid #2a5a2a; color: #7c9; }
    .srp-keep:hover { background: #1c3e22; color: #9eb; }
    .srp-take { background: #301512; border: 1px solid #5a2a24; color: #c87; }
    .srp-take:hover { background: #3e1c18; color: #e9a; }
    .srp-goto {
        background: none; border: none; color: #888; cursor: pointer;
        font-size: 11px; padding: 1px 4px; flex-shrink: 0; text-decoration: underline;
    }
    .srp-goto:hover { color: #c4aaee; }
    /* body fills below the header; DocDiff scrolls within its own max-height */
    .srp-body { display: flex; flex-direction: column; overflow: hidden; padding: 0 6px 6px; }
    .srp-note { font-size: 11px; color: #976; padding: 8px 6px; }
</style>
