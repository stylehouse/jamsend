<script lang="ts">
    // SchemeStaff.svelte — the "musical staff" scheme renderer.
    //  Renders the WHOLE C** tree as a scored field: every particle a horizontal
    //   STAFF ROW stacking in DFS/snap order.  See spec/Cello_universal_scheme_5_todo.md.
    //
    //  The fibre-bundle invariant, made structural:
    //   - clef zone  (jewel colour, per-mainkey)         — the TYPE
    //   - mainkey bar (bold label + sc[0] value)          — the name
    //   - sc notation field (pill/note glyphs on staff)   — BELIEVED k:v structure
    //   - under-staff wire (muted, ALWAYS present)        — the LIVE .c underbelly
    //
    //  Honesty channel: ▸N for a capped/collapsed subtree, dashed staff for a
    //   re-parented node.  Pure CSS/SVG, self-contained — no other files.
    //
    //  Shared contract with sibling schemes:  let { H } = $props()

    let { H } = $props()

    // ── cap — never walk more than this many nodes (field-scale sanity) ──────────
    const NODE_CAP = 400

    // ── one collected staff row ──────────────────────────────────────────────────
    type Row = {
        mk: string                          // mainkey (first sc key)
        depth: number                       // walk depth for indentation
        pairs: Array<[string, unknown]>     // sc k:v (mainkey excluded)
        head_val: unknown                   // sc[mainkey] value (rides the mainkey bar)
        c_keys: string[]                    // .c key names (for the undertone wire)
        c_count: number                     // number of live .c refs
        collapsed: number                   // > 0 = this many children hidden (▸N)
        reparented: boolean                 // shown out of its true C-tree parent (dashed)
        hue: number                         // fallback hue when Matstyle absent
        ground: { bg: string, color: string, border: string } | null
    }

    // ── hash a mainkey to a stable hue (fallback when Matstyle isn't mixed in) ───
    function hue_of(mk: string): number {
        let h = 0
        for (let i = 0; i < mk.length; i++) h = (h * 31 + mk.charCodeAt(i)) & 0xffff
        return h % 360
    }

    // ── per-mainkey Matstyle ground, guarded (may not be mixed in yet) ───────────
    function ground_of(mk: string): { bg: string, color: string, border: string } | null {
        try {
            const g = (H as any)?.matstyle_ground?.(mk)
            if (g && g.color) return g
        } catch { /* Matstyle not present */ }
        return null
    }

    // ── classify a .c ref kind → an undertone colour ─────────────────────────────
    //  runtime ref = blue, backlink (up/parent/source_n) = amber, House chain = purple.
    function wire_kind(key: string): string {
        if (key === 'up' || key === 'parent' || key === 'source_n' || key.endsWith('_of') || key.startsWith('back'))
            return '#c89838'   // amber — a backlink
        if (key === 'H' || key === 'house' || key === 'mutex' || key === 'tick')
            return '#9060c0'   // purple — House chain / structural
        return '#4a78c0'       // blue — a generic runtime ref
    }

    // ── DEFENSIVE tree walk: H > A* > w* > children, DFS/snap order ───────────────
    //  Copies Cellui's scan posture: try/catch the whole thing, never white-screen.
    //  Gate on H.version so $derived re-runs when the tree changes.
    function scan_rows(): Row[] {
        try {
            void (H as any)?.version
            if (!H) return []

            const out: Row[] = []
            const seen = new Set<unknown>()
            const H_any = H as any

            // build one Row from a live particle at a given depth
            const make_row = (n: any, depth: number, reparented: boolean, collapsed: number): Row | null => {
                if (!n || !n.sc) return null
                const keys = Object.keys(n.sc)
                const mk = keys[0]
                if (!mk) return null
                const pairs: Array<[string, unknown]> = []
                for (let i = 1; i < keys.length; i++) pairs.push([keys[i], n.sc[keys[i]]])
                const c = n.c || {}
                const c_keys = Object.keys(c)
                return {
                    mk,
                    depth,
                    pairs,
                    head_val: n.sc[mk],
                    c_keys,
                    c_count: c_keys.length,
                    collapsed,
                    reparented,
                    hue: hue_of(mk),
                    ground: ground_of(mk),
                }
            }

            // a particle's children via ob({}) (version-tracked) or o({}) fallback
            const children_of = (n: any): any[] => {
                try {
                    const kids = (n?.ob?.({}) ?? n?.o?.({}) ?? []) as unknown
                    return Array.isArray(kids) ? kids : []
                } catch { return [] }
            }

            // recursive DFS, honouring the global NODE_CAP
            const walk = (n: any, depth: number, reparented: boolean): void => {
                if (out.length >= NODE_CAP) return
                if (!n || seen.has(n)) return
                seen.add(n)
                let kids = children_of(n)
                // headroom left in the field before the global cap
                const remaining = NODE_CAP - out.length - 1
                let collapsed = 0
                if (remaining <= 0 && kids.length) {
                    collapsed = kids.length          // no room — collapse ALL children
                    kids = []
                } else if (kids.length > remaining) {
                    collapsed = kids.length - remaining
                    kids = kids.slice(0, remaining)
                }
                const row = make_row(n, depth, reparented, collapsed)
                if (row) out.push(row)
                for (const k of kids) {
                    if (out.length >= NODE_CAP) break
                    walk(k, depth + 1, false)
                }
            }

            // roots: H's actors > worlds > their subtrees, then H's direct children.
            // A missing ob just yields [], so the walk degrades gracefully.
            const actors = (H_any.ob?.({ A: 1 }) ?? []) as unknown
            for (const A of Array.isArray(actors) ? actors : []) {
                const worlds = (A?.ob?.({ w: 1 }) ?? []) as unknown
                for (const w of Array.isArray(worlds) ? worlds : []) walk(w, 0, false)
            }
            // direct children of H not reached under an actor/world — shown here for
            // layout though their true home may be elsewhere → dashed (re-parented).
            for (const n of children_of(H_any)) {
                if (out.length >= NODE_CAP) break
                if (seen.has(n)) continue
                walk(n, 0, true)
            }

            return out
        } catch (err) {
            console.warn('[SchemeStaff] scan error:', err)
            return []
        }
    }

    // ── the field, re-derived on every settled tick (H.version) ──────────────────
    const rows = $derived.by(() => {
        void (H as any)?.version
        return scan_rows()
    })

    // ── staff-body height class from sc density (§6) ─────────────────────────────
    function density_class(n: number): string {
        if (n <= 2) return 'thin'
        if (n <= 5) return 'medium'
        return 'full'
    }

    // ── pill glyph + display for one sc k:v (§7 vocabulary, condensed) ───────────
    type Pill = { key: string, glyph: string, val: string, kind: string, trunc: boolean }
    function pill_of(key: string, v: unknown): Pill {
        // boolean flag: value 1 / '1' / true → open diamond, key IS the claim
        if (v === 1 || v === '1' || v === true) return { key, glyph: '◆', val: '', kind: 'flag', trunc: false }
        if (v == null) return { key, glyph: '⬡', val: '∅', kind: 'null', trunc: false }
        if (typeof v === 'object') return { key, glyph: '⚠', val: '[obj]', kind: 'mint', trunc: false }
        const s = String(v)
        if (/^-?\d+(\.\d+)?$/.test(s)) return { key, glyph: '▣', val: s, kind: 'num', trunc: false }
        if (s.length > 24) return { key, glyph: '◈', val: s.slice(0, 24), kind: 'str', trunc: true }
        return { key, glyph: '▣', val: s, kind: 'str', trunc: false }
    }
    function pills_of(pairs: Array<[string, unknown]>): Pill[] {
        return pairs.map(([k, v]) => pill_of(k, v))
    }

    // ── clef swatch style for a row ──────────────────────────────────────────────
    function clef_style(r: Row): string {
        if (r.ground) return `background:${r.ground.color};box-shadow:inset 0 0 0 2px ${r.ground.border};`
        return `background:hsl(${r.hue} 55% 55%);box-shadow:inset 0 0 0 2px hsl(${r.hue} 55% 32%);`
    }
    // tinted staff background (kin to clef, low opacity)
    function staff_tint(r: Row): string {
        if (r.ground) return `${r.ground.color}22`
        return `hsl(${r.hue} 55% 55% / 0.13)`
    }
    function head_text(r: Row): string {
        const v = r.head_val
        if (v === 1 || v === '1' || v === true || v == null) return ''
        const s = String(v)
        return s.length > 18 ? s.slice(0, 18) + '…' : s
    }
</script>

<!-- ─────────────────────────────────────────────────────────────────────────── -->
<!-- STAFF FIELD — the snap as a living score. One STAFF ROW per particle,        -->
<!--  DFS/snap order, indented by depth.                                          -->
<!-- ─────────────────────────────────────────────────────────────────────────── -->
<div class="staff-field">
    {#if rows.length}
        {#each rows as r, i (i)}
            {@const dclass = density_class(r.pairs.length)}
            <div
                class="staff-row {dclass}"
                class:reparented={r.reparented}
                style="--indent:{r.depth * 8}px; --tint:{staff_tint(r)};"
            >
                <!-- CLEF ZONE — the per-mainkey colour jewel, no text -->
                <div class="clef" style={clef_style(r)} title={r.mk}>
                    {#if r.c_count}<span class="ccount">c:{r.c_count}</span>{/if}
                </div>

                <!-- STAFF STACK: mainkey bar + sc field over the undertone wire -->
                <div class="stack">
                    <!-- upper staff: mainkey bar ║ sc notation field -->
                    <div class="upper">
                        <span class="mkbar">
                            <span class="mk">{r.mk}</span>{#if head_text(r)}<span class="mkval">:{head_text(r)}</span>{/if}
                        </span>
                        <span class="dbar" aria-hidden="true">║</span>
                        <span class="scfield">
                            {#each pills_of(r.pairs) as p (p.key)}
                                <span class="pill {p.kind}" class:trunc={p.trunc} title="{p.key}{p.val ? ':' + p.val : ''}">
                                    <span class="glyph">{p.glyph}</span>
                                    <span class="pkey">{p.key}</span>{#if p.val}<span class="pval">{p.val}</span>{/if}{#if p.trunc}<span class="tail">…</span>{/if}
                                </span>
                            {/each}
                        </span>
                        {#if r.collapsed}
                            <span class="collapse" title="{r.collapsed} children not shown">▸{r.collapsed}</span>
                        {/if}
                    </div>

                    <!-- under-staff WIRE — the .c layer, ALWAYS drawn (blank = no refs) -->
                    <div class="wire" class:empty={!r.c_count}>
                        {#each r.c_keys as ck (ck)}
                            <span class="block" style="background:{wire_kind(ck)};" title={ck}></span>
                        {/each}
                    </div>
                </div>
            </div>
        {/each}
    {:else}
        <div class="staff-empty">no particles</div>
    {/if}
</div>

<style>
/* ── FIELD ─────────────────────────────────────────────────────────────────── */
.staff-field {
    display: flex;
    flex-direction: column;
    gap: 2px;
    width: 100%;
    height: 100%;
    min-height: 200px;
    padding: 8px 6px;
    background: #0a0a14;
    color: #c8c8e0;
    font-family: ui-monospace, 'SF Mono', Menlo, monospace;
    font-size: 0.72rem;
    overflow: auto;
    box-sizing: border-box;
}

/* ── STAFF ROW ─────────────────────────────────────────────────────────────── */
.staff-row {
    display: flex;
    flex-direction: row;
    align-items: stretch;
    margin-left: var(--indent, 0px);
    background: var(--tint, transparent);
    border-radius: 3px;
    min-height: 20px;
    overflow: hidden;
}
.staff-row.thin   { min-height: 16px; }
.staff-row.medium { min-height: 22px; }
.staff-row.full   { min-height: 28px; }

/* re-parented: dashed staff — "shown here for layout, lives elsewhere" */
.staff-row.reparented {
    outline: 1px dashed #6a6a90;
    outline-offset: -1px;
    opacity: 0.9;
}

/* ── CLEF ZONE ─────────────────────────────────────────────────────────────── */
.clef {
    flex: 0 0 22px;
    width: 22px;
    position: relative;
    border-radius: 3px 0 0 3px;
    display: flex;
    align-items: flex-end;
    justify-content: center;
}
.clef .ccount {
    font-size: 0.5rem;
    line-height: 1;
    color: #0a0a14;
    font-weight: 700;
    padding: 0 0 1px;
    opacity: 0.85;
    white-space: nowrap;
}

/* ── STAFF STACK ───────────────────────────────────────────────────────────── */
.stack {
    flex: 1 1 auto;
    display: flex;
    flex-direction: column;
    min-width: 0;
    padding-left: 6px;
}

/* ── UPPER STAFF: mainkey bar ║ sc field ───────────────────────────────────── */
.upper {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 4px;
    flex: 1 1 auto;
    min-width: 0;
    padding: 1px 0;
}
.mkbar {
    flex: 0 0 auto;
    white-space: nowrap;
    max-width: 160px;
    overflow: hidden;
    text-overflow: ellipsis;
}
.mk {
    font-weight: 700;
    letter-spacing: 0.02em;
    color: #e8e8ff;
}
.mkval { color: #9aa0c8; }
.dbar {
    flex: 0 0 auto;
    color: #55557a;
    font-weight: 700;
    user-select: none;
}
.scfield {
    flex: 1 1 auto;
    display: flex;
    flex-direction: row;
    flex-wrap: wrap;
    gap: 3px;
    min-width: 0;
    align-items: center;
}

/* ── SC PILLS ──────────────────────────────────────────────────────────────── */
.pill {
    display: inline-flex;
    align-items: center;
    gap: 2px;
    padding: 0 5px;
    border-radius: 8px;
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid rgba(255, 255, 255, 0.1);
    white-space: nowrap;
    max-width: 220px;
    overflow: hidden;
    line-height: 1.4;
}
.pill .glyph { font-size: 0.7em; opacity: 0.85; }
.pill .pkey  { color: #b8bce0; }
.pill .pval  { color: #e0e4ff; font-weight: 600; }
.pill.num .pval { font-variant-numeric: tabular-nums; }
.pill.flag { background: rgba(120, 180, 255, 0.1); }
.pill.flag .pkey { color: #9ac8ff; }
.pill.null { opacity: 0.6; }
.pill.mint {                       /* object-in-sc — the MINT BUG marker */
    background: rgba(230, 90, 90, 0.18);
    border-color: #c04040;
}
.pill.mint .pkey, .pill.mint .glyph { color: #ff9090; }
.pill.trunc { border-right: 1px dashed rgba(255, 255, 255, 0.4); }
.pill .tail { color: #7a7ea0; }

/* ── COLLAPSED-SUBTREE HONESTY MARK ────────────────────────────────────────── */
.collapse {
    flex: 0 0 auto;
    margin-left: auto;
    padding: 0 6px;
    color: #e8c46a;
    font-weight: 700;
    white-space: nowrap;
}

/* ── UNDER-STAFF WIRE — the .c layer, always present ───────────────────────── */
.wire {
    display: flex;
    flex-direction: row;
    gap: 2px;
    align-items: center;
    min-height: 6px;
    padding: 1px 0 2px;
    border-top: 1px solid rgba(255, 255, 255, 0.05);
}
.wire.empty {
    /* a blank wire is its own signal — "this particle has no live refs" */
    opacity: 0.5;
}
.wire.empty::before {
    content: '';
    display: block;
    height: 1px;
    width: 24px;
    background: repeating-linear-gradient(90deg, #33334a 0 3px, transparent 3px 6px);
}
.wire .block {
    display: inline-block;
    width: 14px;
    height: 5px;
    border-radius: 2px;
    opacity: 0.7;
}

/* ── EMPTY ─────────────────────────────────────────────────────────────────── */
.staff-empty {
    color: #555;
    font-size: 0.85rem;
    padding: 24px;
    text-align: center;
}
</style>
