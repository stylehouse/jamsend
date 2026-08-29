<script lang="ts">
    // SchemeTree.svelte — the "tree / recursive blob-nesting" scheme (see spec/Cello_tree_scheme_todo.md).
    //  The C** tree IS the layout: every particle is a cello_blob-clipped cell, children physically
    //   INSIDE the parent's blob — organic containment, not a rigid box tree.  Three strata per cell
    //    (fibre-bundle completeness): mainkey band on the rim, sc k:v rows inside, and a dim `.c`
    //     count strip that is ALWAYS present even at c0.  Honesty channel: a crushed, dashed-wall
    //      collapse blob wherever the depth cap bent the picture.
    //  Contract (shared with sibling schemes so a switcher can swap): `let { H } = $props()`.
    //  Pure CSS layout — flex-wrap nesting + em-based shrink per level.  Arithmetic, not simulation.
    import { cello_blob, cello_seed } from '$lib/O/cello_blob'

    let { H } = $props()

    // ── caps: the walk is bounded so a huge world can never wedge the render ─────
    const NODE_CAP = 400     // total cells collected across the whole tree
    const DEPTH_CAP = 4      // levels below the root before the crushed honesty blob
    const KID_CAP = 12       // children shown per cell before the `… N more` truncation cell
    const SC_CAP = 8         // sc rows shown per cell before `+N…`
    const VAL_MAX = 28       // sc value truncation length

    // ── one collected tree node ──────────────────────────────────────────────────
    type TNode = {
        key: string                    // stable-ish render key
        mk: string                     // mainkey = Object.keys(n.sc)[0]
        rows: [string, string][]       // sc k:v rest ('' value = flag-only, key IS the value)
        more_sc: number                // sc rows beyond SC_CAP
        cref: number                   // Object.keys(n.c||{}).length — below-the-waterline count
        kids: TNode[]
        kids_omitted: number           // children beyond KID_CAP (or the node cap)
        deeper: number                 // children NOT descended into (depth cap) → crushed blob
        seed: number
        blob: string                   // clip-path polygon
        colour: { bg: string, color: string, border: string }
    }

    // ── colour: Matstyle ground if mixed in, else a deterministic hash-to-hue ────
    function hue_of(mk: string): number {
        let h = 2166136261
        for (let i = 0; i < mk.length; i++) { h ^= mk.charCodeAt(i); h = Math.imul(h, 16777619) }
        return (h >>> 0) % 360
    }
    function cell_colour(mk: string): { bg: string, color: string, border: string } {
        try {
            const g = (H as any)?.matstyle_ground?.(mk)
            if (g && g.bg) return g
        } catch { /* Matstyle not mixed in yet */ }
        const h = hue_of(mk)
        return {
            bg: `hsl(${h} 38% 11%)`,
            color: `hsl(${h} 65% 72%)`,
            border: `hsl(${h} 50% 38%)`,
        }
    }

    // ── sc rest → rows.  A snapped flag rides as '1'; render it flag-only. ───────
    function sc_rows(sc: any): { rows: [string, string][], more: number } {
        const rows: [string, string][] = []
        let more = 0
        const keys = Object.keys(sc)
        for (let i = 1; i < keys.length; i++) {
            if (rows.length >= SC_CAP) { more = keys.length - 1 - SC_CAP; break }
            const raw = sc[keys[i]]
            if (raw === undefined || raw === null) continue
            let v = String(raw)
            if (v === '1') v = ''                          // flag-only: the key IS the value
            else if (v.length > VAL_MAX) v = v.slice(0, VAL_MAX - 1) + '…'
            rows.push([keys[i], v])
        }
        return { rows, more }
    }

    // ── the recursive walk — defensive at every step, bounded by the caps ────────
    //  Scan pattern follows Cellui's scan_cells (H > A* > w* > children), extended to
    //  recurse the WHOLE tree: at every node, children come from `n.ob({})`; at the H
    //  root the A-actors are asked for first so they lead the top row.
    function build_tree(): TNode | null {
        try {
            void (H as any)?.version    // subscribe: re-run when the tree bumps
            if (!H) return null

            const seen = new Set<any>()
            let count = 0
            let serial = 0

            const kids_of = (n: any): any[] => {
                try { return ((n?.ob?.({}) ?? []) as any[]).filter(k => k && k.sc) }
                catch { return [] }
            }

            const build = (n: any, depth: number): TNode | null => {
                try {
                    if (!n || !n.sc || seen.has(n)) return null
                    const mk = Object.keys(n.sc)[0]
                    if (!mk) return null
                    seen.add(n)
                    count++

                    const { rows, more } = sc_rows(n.sc)
                    const id = (n.sc as any).pub || (n.sc as any).id || mk
                    const seed = cello_seed(String(id) + ':' + mk)

                    const node: TNode = {
                        key: mk + ':' + String(id) + ':' + (serial++),
                        mk, rows, more_sc: more,
                        cref: Object.keys(n.c || {}).length,
                        kids: [], kids_omitted: 0, deeper: 0,
                        seed,
                        blob: cello_blob(seed, { wobble: 0.05, squish: 0.97 }),
                        colour: cell_colour(mk),
                    }

                    const raw_kids = kids_of(n)
                    if (raw_kids.length) {
                        if (depth >= DEPTH_CAP) {
                            node.deeper = raw_kids.length   // honesty: crushed blob, not silence
                        } else {
                            for (const kid of raw_kids) {
                                if (node.kids.length >= KID_CAP || count >= NODE_CAP) {
                                    node.kids_omitted = raw_kids.length - node.kids.length
                                    break
                                }
                                const built = build(kid, depth + 1)
                                if (built) node.kids.push(built)
                            }
                        }
                    }
                    return node
                } catch (err) {
                    console.warn('[SchemeTree] node build error:', err)
                    return null
                }
            }

            // the H root cell — synthesise if the House wears no sc of its own
            const H_any = H as any
            const root_mk = (H_any.sc && Object.keys(H_any.sc)[0]) || 'H'
            const root_sc = H_any.sc ? sc_rows(H_any.sc) : { rows: [] as [string, string][], more: 0 }
            const root: TNode = {
                key: 'H:root',
                mk: root_mk,
                rows: root_sc.rows, more_sc: root_sc.more,
                cref: Object.keys(H_any.c || {}).length,
                kids: [], kids_omitted: 0, deeper: 0,
                seed: cello_seed('H:root'),
                blob: cello_blob(cello_seed('H:root'), { wobble: 0.04, squish: 0.97 }),
                colour: cell_colour(root_mk),
            }
            if (H_any.sc) seen.add(H_any)
            count++

            // Cellui's scan order: actors first, then everything else at H's shelf
            //  (the seen-set dedups the overlap; below each, ob({}) recursion covers w* > children).
            const top: any[] = []
            try { for (const A of (H_any.ob?.({ A: 1 }) ?? []) as any[]) top.push(A) } catch { /* shrug */ }
            try { for (const n of (H_any.ob?.({}) ?? []) as any[]) top.push(n) } catch { /* shrug */ }
            for (const n of top) {
                if (root.kids.length >= KID_CAP || count >= NODE_CAP) {
                    const remaining = top.filter(t => t && t.sc && !seen.has(t)).length
                    if (remaining) root.kids_omitted = remaining
                    break
                }
                const built = build(n, 1)
                if (built) root.kids.push(built)
            }
            return root
        } catch (err) {
            console.warn('[SchemeTree] scan error:', err)
            return null
        }
    }

    const root = $derived.by(build_tree)

    // the crushed honesty blob — squish 0.35 reads as squeezed, not empty
    function crush_blob(seed: number): string {
        return cello_blob(seed + 7, { wobble: 0.05, squish: 0.35, points: 12 })
    }
    const TRUNC_BLOB = cello_blob(cello_seed('trunc'), { wobble: 0.05, squish: 0.55, points: 10 })
</script>

<!-- ─────────────────────────────────────────────────────────────────────────── -->
<!-- SCHEME TREE — recursive blob-nesting.  Cells within cells; the wall IS the  -->
<!-- bracket.  Nesting shrinks via em cascade (.st-kids font-size); no layout    -->
<!-- engine, no physics.                                                         -->
<!-- ─────────────────────────────────────────────────────────────────────────── -->

{#snippet cell(node: TNode)}
    <div
        class="st-cell"
        style="
            --bg: {node.colour.bg};
            --fg: {node.colour.color};
            --bd: {node.colour.border};
            clip-path: {node.blob};
        "
    >
        <!-- wall stroke: inset shadow traces the clipped polygon -->
        <div class="st-wall"></div>

        <!-- 1. MAINKEY BAND — what the thing IS, on the rim -->
        <div class="st-mk">⌒ {node.mk}</div>

        <!-- 2. SC BAND — k:v scalar rows, flag-only keys bare -->
        {#if node.rows.length || node.more_sc > 0}
            <div class="st-sc">
                {#each node.rows as row (row[0])}
                    <span class="st-row">{row[1] === '' ? row[0] : row[0] + ':' + row[1]}</span>
                {/each}
                {#if node.more_sc > 0}
                    <span class="st-row st-more">+{node.more_sc}…</span>
                {/if}
            </div>
        {/if}

        <!-- 3. .C STRIP — always present, even at c0: the stratum is structural -->
        <div class="st-cstrip">c{node.cref}<span class="st-dots"> {'·'.repeat(Math.min(node.cref, 8))}</span></div>

        <!-- 4. CHILD AREA — nested blob cells, flex-wrap, em-shrunk -->
        {#if node.kids.length || node.kids_omitted > 0 || node.deeper > 0}
            <div class="st-kids">
                {#each node.kids as kid (kid.key)}
                    {@render cell(kid)}
                {/each}
                {#if node.kids_omitted > 0}
                    <div class="st-trunc" style="clip-path: {TRUNC_BLOB};">… {node.kids_omitted} more</div>
                {/if}
                {#if node.deeper > 0}
                    <!-- honesty mark: depth-capped subtree → crushed, dashed-wall blob -->
                    <div
                        class="st-crush"
                        style="--fg: {node.colour.color}; --bd: {node.colour.border}; clip-path: {crush_blob(node.seed)};"
                    >
                        <div class="st-crush-ring"></div>
                        <span>▸ {node.deeper} deeper</span>
                    </div>
                {/if}
            </div>
        {/if}
    </div>
{/snippet}

<div class="st-stage">
    {#if root}
        {@render cell(root)}
    {:else}
        <div class="st-empty">no tree — H not commissioned yet</div>
    {/if}
</div>

<style>
    .st-stage {
        width: 100%;
        height: 100%;
        overflow: auto;
        background: #0b0b12;
        padding: 10px;
        box-sizing: border-box;
        font-family: ui-monospace, 'SF Mono', Menlo, monospace;
        font-size: 13px;
    }

    .st-empty {
        color: #606080;
        font-size: 11px;
        padding: 16px;
    }

    /* ── one blob cell ────────────────────────────────────────────────────── */
    .st-cell {
        position: relative;
        background: var(--bg);
        color: var(--fg);
        padding: 0.9em 1.1em 0.8em;
        min-width: 6em;
        max-width: 100%;
        box-sizing: border-box;
        flex: 1 1 auto;
    }

    /* the wall: an inset ring in the border colour, clipped to the same blob */
    .st-wall {
        position: absolute;
        inset: 0;
        pointer-events: none;
        box-shadow: inset 0 0 0 2px var(--bd);
        opacity: 0.6;
    }

    /* 1. mainkey band on the rim */
    .st-mk {
        font-weight: 700;
        font-size: 0.82em;
        letter-spacing: 0.04em;
        color: var(--fg);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        border-bottom: 1px solid color-mix(in srgb, var(--bd) 45%, transparent);
        padding-bottom: 0.25em;
        margin-bottom: 0.3em;
    }

    /* 2. sc band — TreeFace's monospace rows, framed in charm */
    .st-sc {
        display: flex;
        flex-wrap: wrap;
        gap: 0.15em 0.7em;
        font-size: 0.68em;
        line-height: 1.5;
        color: color-mix(in srgb, var(--fg) 85%, #ffffff);
        word-break: break-all;
    }
    .st-row { white-space: nowrap; max-width: 100%; overflow: hidden; text-overflow: ellipsis; }
    .st-more { opacity: 0.5; }

    /* 3. .c strip — dimmer hue, always shown, reads below the sc band */
    .st-cstrip {
        font-size: 0.62em;
        color: color-mix(in srgb, var(--fg) 40%, #555);
        border-top: 1px dotted color-mix(in srgb, var(--bd) 35%, transparent);
        margin-top: 0.35em;
        padding-top: 0.2em;
    }
    .st-dots { letter-spacing: 0.15em; opacity: 0.6; }

    /* 4. child area — flex-wrap nesting; the em cascade shrinks each level */
    .st-kids {
        display: flex;
        flex-wrap: wrap;
        align-items: flex-start;
        gap: 0.45em;
        margin-top: 0.5em;
        font-size: 0.92em;
    }

    /* kid-cap truncation cell — small grey blob, never a silent cut */
    .st-trunc {
        background: #26262e;
        color: #9a9aae;
        font-size: 0.68em;
        padding: 0.7em 1.2em;
        align-self: center;
        white-space: nowrap;
    }

    /* depth-cap honesty mark — the CRUSHED blob with a dashed wall */
    .st-crush {
        position: relative;
        background: color-mix(in srgb, var(--bd) 22%, #101016);
        color: var(--fg);
        font-size: 0.68em;
        padding: 1.1em 1.6em;
        align-self: center;
        white-space: nowrap;
        display: flex;
        align-items: center;
        justify-content: center;
        opacity: 0.9;
    }
    /* dashed ring inside the crushed blob: the clip cuts it into the blob wall,
       and the dashes say "this boundary is a display artifact, not a structural one" */
    .st-crush-ring {
        position: absolute;
        inset: 6%;
        border: 1px dashed var(--bd);
        border-radius: 50%;
        pointer-events: none;
    }
</style>
