<script lang="ts">
    // SchemeMesh.svelte — the "mesh / atom-weave field" scheme.
    //  Sibling to Cello: where Cello asks "which one thing?", Mesh asks "what is the WHOLE
    //   field of matter, at once?" and answers by rendering the live C tree as a dense,
    //    demarcated, decodable texture.  Pure CSS/SVG layout — no cytoscape, no physics.
    //  Contract shared by every scheme so a switcher can swap them: `let { H } = $props()`.
    //  See spec/Cello_mesh_scheme_todo.md.  Self-contained; no imports beyond cello_blob.
    import { cello_blob, cello_seed } from '$lib/O/cello_blob'

    let { H } = $props()

    // ── caps & sizing constants ──────────────────────────────────────────────────
    const MAX_NODES = 400     // hard cap so a huge tree can never hang the walk
    const MAX_DEPTH = 12      // depth guard for the recursive walk
    const PEB_CAP = 8         // sc pebbles shown per atom before "+N"
    const STUB_CAP = 6        // .c feather stubs drawn per atom before "+N"

    // ─────────────────────────────────────────────────────────────────────────────
    // ATOM record — one per particle
    // ─────────────────────────────────────────────────────────────────────────────
    type Peb = { k: string; v: string; hue: number; hollow: boolean }
    type Warp = {
        // graded honesty channel — see spec §5
        distorted: boolean
        effect: boolean       // sc.twist:'effect' — a Door, not a wound
        hue_shift: number     // degrees toward amber/red
        severity: number      // 0..1 opacity/label weighting
        badge: string         // short glyph shown on the pill
        note: string          // hover title
    }
    type Atom = {
        key: string
        mk: string           // mainkey
        depth: number
        label: string
        pebbles: Peb[]
        peb_more: number
        n_c: number          // .c ref count
        stub_more: number
        colour: { bg: string; color: string; border: string }
        blob: string         // clip-path polygon
        warp: Warp
    }

    // ── fallback colour when Matstyle isn't mixed in — hash mainkey → jewel hue ───
    function hash_hue(s: string): number {
        let h = 5381
        for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0
        // golden-angle spread for well-distributed hues
        return Math.abs(h * 137.508) % 360
    }
    function hsl(h: number, s: number, l: number): string {
        return `hsl(${((h % 360) + 360) % 360} ${s}% ${l}%)`
    }
    function fallback_colour(mk: string): { bg: string; color: string; border: string } {
        const h = hash_hue(mk)
        return { bg: hsl(h, 34, 13), color: hsl(h, 60, 78), border: hsl(h, 46, 52) }
    }
    function atom_colour(mk: string): { bg: string; color: string; border: string } {
        try {
            const g = (H as any)?.matstyle_ground?.(mk)
            if (g && g.bg) return g
        } catch { /* Matstyle not mixed in — fall through */ }
        return fallback_colour(mk)
    }

    // ── per-key hue for a pebble dot (function of KEY not value, per spec §2) ──────
    function key_hue(k: string): number {
        let h = 5381
        for (let i = 0; i < k.length; i++) h = ((h << 5) + h + k.charCodeAt(i)) | 0
        return Math.abs(h * 137.508) % 360
    }

    function short(v: unknown, cap = 22): string {
        let s: string
        try { s = typeof v === 'string' ? v : JSON.stringify(v) } catch { s = String(v) }
        if (s == null) s = String(v)
        return s.length > cap ? s.slice(0, cap - 1) + '…' : s
    }

    // ── the twist channel — detect the distortion classes from live matter ────────
    //  Returns a graded Warp.  Never throws (each probe guarded).
    function detect_warp(
        n: any,
        mk: string,
        sc_entries: [string, unknown][],
        n_c: number,
        compound: boolean,
    ): Warp {
        let hue_shift = 0
        let severity = 0
        let badge = ''
        const notes: string[] = []
        let effect = false

        try {
            // declared intentional distortion — a Door, drawn purple not amber
            if ((n?.sc as any)?.twist === 'effect') { effect = true; notes.push('twist:effect — by design') }

            // object|function value in sc (fatal at encode) — the worst wound
            for (const [k, v] of sc_entries) {
                if (v !== null && (typeof v === 'object' || typeof v === 'function')) {
                    hue_shift = Math.max(hue_shift, 60); severity = Math.max(severity, 1)
                    badge = '⚠'; notes.push(`object in sc — ${k}`)
                }
            }
            // undef sc value (the mint-bug marker)
            const undef_key = sc_entries.find(([, v]) => v === undefined)
            if (undef_key) {
                hue_shift = Math.max(hue_shift, 40); severity = Math.max(severity, 0.7)
                notes.push(`undef sc value — ${undef_key[0]}`)
            }
            // finished-but-undropped req — dead scaffolding still in the tree
            const is_req = mk === 'req' || (n?.sc as any)?.req !== undefined
            if (is_req && ((n?.sc as any)?.finished !== undefined)) {
                hue_shift = Math.max(hue_shift, 30); severity = Math.max(severity, 0.5)
                notes.push('finished but not dropped')
            }
            // .c foam — runtime refs piled far above typical; snap under-reports it
            if (n_c >= 12) {
                hue_shift = Math.max(hue_shift, 20); severity = Math.max(severity, 0.4)
                notes.push(`.c foam — ${n_c} runtime refs`)
            }
            // compound — a leaf-looking atom that actually nests children (hidden depth)
            if (compound) {
                severity = Math.max(severity, 0.3)
                notes.push('compound — hidden children')
            }
        } catch { /* honesty probe must never white-screen */ }

        const distorted = notes.length > 0
        return { distorted, effect, hue_shift, severity, badge, note: notes.join(' · ') }
    }

    // ── DEFENSIVE walk of H's whole tree → flat atom list, capped ─────────────────
    //  Copies Cellui's scan posture (H > A* > w* > children) but collects the WHOLE
    //   tree recursively via .o().  try/catch around everything → never white-screen.
    function scan_atoms(): Atom[] {
        try {
            void (H as any)?.version           // gate reactivity on H's version
            if (!H) return []

            const out: Atom[] = []
            const seen = new Set<any>()

            const kids = (n: any): any[] => {
                try {
                    const r = n?.o?.({})
                    return Array.isArray(r) ? r : []
                } catch { return [] }
            }

            const consider = (n: any, depth: number) => {
                if (out.length >= MAX_NODES) return
                if (!n || seen.has(n)) return
                seen.add(n)

                let sc: Record<string, unknown> = {}
                try { sc = n.sc || {} } catch { sc = {} }
                const all_keys = Object.keys(sc)
                const mk = all_keys[0] || '∅'
                const rest = all_keys.slice(1)

                let n_c = 0
                try { n_c = Object.keys(n.c || {}).length } catch { n_c = 0 }

                const sc_entries: [string, unknown][] = rest.map((k) => [k, sc[k]])
                const child_list = kids(n)
                const has_kids = child_list.length > 0

                const pebbles: Peb[] = sc_entries.slice(0, PEB_CAP).map(([k, v]) => ({
                    k,
                    v: short(v),
                    hue: key_hue(k),
                    hollow: v === undefined || (v !== null && typeof v === 'object'),
                }))
                const peb_more = Math.max(0, sc_entries.length - PEB_CAP)
                const stub_more = Math.max(0, n_c - STUB_CAP)

                const warp = detect_warp(n, mk, sc_entries, n_c, has_kids && rest.length === 0)

                let colour = atom_colour(mk)
                if (warp.distorted && warp.hue_shift > 0) {
                    // rotate the pill hue toward amber (or purple if declared effect)
                    const baseHue = hash_hue(mk)
                    const target = warp.effect ? 280 : 30 // amber ~30°, purple ~280° for doors
                    const mixHue = baseHue + (target - baseHue) * Math.min(1, warp.hue_shift / 60)
                    colour = { ...colour, border: hsl(mixHue, 70, 55), color: hsl(mixHue, 70, 78) }
                }

                const wobble = 0.05 + (warp.distorted
                    ? Math.min(0.17, warp.hue_shift / 300 + warp.severity * 0.06)
                    : 0)
                const id = (sc as any).pub || (sc as any).id || (sc as any).name || mk
                const blob = cello_blob(cello_seed(String(id) + ':' + out.length), { wobble, points: 12 })

                out.push({
                    key: mk + ':' + out.length,
                    mk,
                    depth,
                    label: String((sc as any).name || (sc as any).label || mk),
                    pebbles,
                    peb_more,
                    n_c,
                    stub_more,
                    colour,
                    blob,
                    warp,
                })

                if (depth < MAX_DEPTH) for (const c of child_list) consider(c, depth + 1)
            }

            // Root: H itself, then the Cellui-style H > A > w descent as a best-effort seed.
            consider(H, 0)
            const H_any = H as any
            try {
                for (const A of (H_any.o?.({ A: 1 }) ?? [])) {
                    consider(A, 1)
                    for (const w of (A.o?.({ w: 1 }) ?? [])) consider(w, 2)
                }
            } catch { /* Cellui-style descent is best-effort */ }

            return out
        } catch (err) {
            try { console.warn('[SchemeMesh] scan error:', err) } catch { /* noop */ }
            return []
        }
    }

    // ── derived atom list (re-runs when H.version bumps) ─────────────────────────
    const atoms = $derived.by(() => {
        void (H as any)?.version
        return scan_atoms()
    })

    // ── weave layout: band by depth, cluster by mainkey (pure arithmetic) ────────
    type Cluster = { mk: string; colour: Atom['colour']; atoms: Atom[] }
    type Band = { depth: number; clusters: Cluster[]; count: number }

    const bands = $derived.by((): Band[] => {
        try {
            const by_depth = new Map<number, Atom[]>()
            for (const a of atoms) {
                const arr = by_depth.get(a.depth) ?? []
                arr.push(a)
                by_depth.set(a.depth, arr)
            }
            const out: Band[] = []
            for (const depth of [...by_depth.keys()].sort((x, y) => x - y)) {
                const list = by_depth.get(depth)!
                const by_mk = new Map<string, Atom[]>()
                for (const a of list) {
                    const arr = by_mk.get(a.mk) ?? []
                    arr.push(a)
                    by_mk.set(a.mk, arr)
                }
                const clusters: Cluster[] = [...by_mk.entries()]
                    .sort((x, y) => y[1].length - x[1].length)
                    .map(([mk, as]) => ({ mk, colour: as[0].colour, atoms: as }))
                out.push({ depth, clusters, count: list.length })
            }
            return out
        } catch {
            return []
        }
    })

    const total = $derived(atoms.length)

    // ── inspect overlay: hover/tap surfaces the full atom (fibre bundle) ─────────
    let inspecting = $state<Atom | null>(null)
    function inspect(a: Atom) { inspecting = a }
    function close_inspect() { inspecting = null }
</script>

<!-- ─────────────────────────────────────────────────────────────────────────── -->
<!-- MESH FIELD — one surface for the whole population. depth→band, mainkey→cluster -->
<!-- ─────────────────────────────────────────────────────────────────────────── -->
<div class="mesh-field">
    <div class="mesh-hud">
        mesh · {total} atom{total === 1 ? '' : 's'}{total >= MAX_NODES ? ' (capped)' : ''}
    </div>

    {#if !bands.length}
        <div class="mesh-empty">empty field</div>
    {/if}

    {#each bands as band (band.depth)}
        <div class="mesh-band">
            <div class="mesh-band-tag">depth {band.depth} · {band.count}</div>
            <div class="mesh-band-body">
                {#each band.clusters as cluster (cluster.mk)}
                    <div
                        class="mesh-cluster"
                        style="--halo:{cluster.colour.border};"
                        title="{cluster.mk} × {cluster.atoms.length}"
                    >
                        {#each cluster.atoms as a (a.key)}
                            <button
                                class="mesh-atom"
                                class:distorted={a.warp.distorted}
                                class:effect={a.warp.effect}
                                style="
                                    --a-bg:{a.colour.bg};
                                    --a-fg:{a.colour.color};
                                    --a-bd:{a.colour.border};
                                    --a-op:{a.warp.distorted && !a.warp.effect ? 1 - a.warp.severity * 0.4 : 1};
                                    clip-path:{a.blob};
                                "
                                onmouseenter={() => inspect(a)}
                                onfocus={() => inspect(a)}
                                onclick={() => inspect(a)}
                                title={a.warp.note || a.label}
                                aria-label="{a.mk} atom"
                            >
                                <div class="mesh-atom-wall"></div>
                                <!-- mainkey pill -->
                                <div class="mesh-pill">
                                    {#if a.warp.badge}<span class="mesh-badge">{a.warp.badge}</span>{/if}
                                    {a.mk}
                                </div>
                                <!-- sc pebbles -->
                                {#if a.pebbles.length}
                                    <div class="mesh-pebbles">
                                        {#each a.pebbles as p (p.k)}
                                            <span
                                                class="mesh-peb"
                                                class:hollow={p.hollow}
                                                style="--dot:{hsl(p.hue, 55, 60)};"
                                            >
                                                <span class="mesh-peb-dot"></span>{p.k}:{p.v}
                                            </span>
                                        {/each}
                                        {#if a.peb_more}<span class="mesh-more">+{a.peb_more}</span>{/if}
                                    </div>
                                {/if}
                                <!-- separator + .c feather stubs -->
                                {#if a.n_c}
                                    <div class="mesh-sep"></div>
                                    <div class="mesh-stubs">
                                        {#each Array(Math.min(a.n_c, STUB_CAP)) as _, i (i)}
                                            <span class="mesh-stub"></span>
                                        {/each}
                                        {#if a.stub_more}<span class="mesh-more">+{a.stub_more}</span>{/if}
                                    </div>
                                {/if}
                            </button>
                        {/each}
                    </div>
                {/each}
            </div>
        </div>
    {/each}
</div>

<!-- ── FIBRE-BUNDLE INSPECT OVERLAY — floats over the field, never re-lays it ── -->
{#if inspecting}
    {@const a = inspecting}
    <button class="mesh-scrim" onclick={close_inspect} aria-label="close inspect"></button>
    <div class="mesh-overlay" style="--a-bg:{a.colour.bg};--a-fg:{a.colour.color};--a-bd:{a.colour.border};">
        <div class="mesh-ov-pill">{a.mk}{a.warp.badge ? ' ' + a.warp.badge : ''}</div>
        <div class="mesh-ov-section">
            <div class="mesh-ov-head">sc — believed structure</div>
            {#if a.pebbles.length || a.peb_more}
                {#each a.pebbles as p (p.k)}
                    <div class="mesh-ov-row" class:hollow={p.hollow}>· {p.k}: {p.v}{p.hollow ? '   ○ undef/obj' : ''}</div>
                {/each}
                {#if a.peb_more}<div class="mesh-ov-row dim">+{a.peb_more} more sc keys</div>{/if}
            {:else}
                <div class="mesh-ov-row dim">(no sc keys — a bare {a.mk})</div>
            {/if}
        </div>
        <div class="mesh-ov-section">
            <div class="mesh-ov-head">.c — runtime, not snapped</div>
            <div class="mesh-ov-row dim">⌁ {a.n_c} runtime ref{a.n_c === 1 ? '' : 's'}</div>
        </div>
        {#if a.warp.distorted}
            <div class="mesh-ov-twist" class:effect={a.warp.effect}>
                twist: {a.warp.effect ? 'door (by design)' : 'warp'} — {a.warp.note}
            </div>
        {/if}
        <div class="mesh-ov-foot">depth {a.depth}</div>
    </div>
{/if}

<style>
/* ── FIELD SURFACE ──────────────────────────────────────────────────────────── */
.mesh-field {
    position: relative;
    width: 100%;
    height: 100%;
    min-height: 300px;
    overflow: auto;
    background: #08080f;
    padding: 8px 10px 24px;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
    gap: 0;
}
.mesh-hud {
    position: sticky;
    top: 0;
    z-index: 3;
    align-self: flex-start;
    font-size: 0.62rem;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    color: #6a6a9a;
    opacity: 0.8;
    padding: 2px 6px;
    margin-bottom: 4px;
    background: rgba(8, 8, 15, 0.85);
    border-radius: 3px;
}
.mesh-empty {
    color: #444;
    font-size: 0.85rem;
    padding: 32px;
    text-align: center;
}

/* ── DEPTH BAND — separated by a ruled demarcation gap ──────────────────────── */
.mesh-band {
    position: relative;
    padding: 6px 0 10px;
    border-top: 1px solid #1c1c2c;   /* the band-gap ruled line */
}
.mesh-band:first-of-type { border-top: none; }
.mesh-band-tag {
    font-size: 0.56rem;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: #4a4a70;
    margin: 2px 0 6px;
}
.mesh-band-body {
    display: flex;
    flex-flow: row wrap;
    align-items: flex-start;
    gap: 14px;
}

/* ── MAINKEY CLUSTER — soft kinship halo, no hard box ───────────────────────── */
.mesh-cluster {
    display: flex;
    flex-flow: row wrap;
    align-content: flex-start;
    gap: 6px;
    padding: 8px;
    border-radius: 10px;
    /* the "groupology" — a subtle halo in the mainkey jewel colour, not a border box */
    box-shadow: 0 0 0 1px color-mix(in srgb, var(--halo) 30%, transparent),
                inset 0 0 22px -12px var(--halo);
    background: color-mix(in srgb, var(--halo) 6%, transparent);
    max-width: 100%;
}

/* ── ATOM ───────────────────────────────────────────────────────────────────── */
.mesh-atom {
    position: relative;
    width: 128px;
    min-height: 56px;
    padding: 4px 6px 6px;
    background: var(--a-bg, #141420);
    color: var(--a-fg, #9090c0);
    border: none;
    cursor: pointer;
    text-align: left;
    overflow: hidden;
    opacity: var(--a-op, 1);
    transition: transform 0.15s ease;
    box-sizing: border-box;
    /* clip-path (the cello_blob wall) set inline */
}
.mesh-atom:hover,
.mesh-atom:focus-visible { transform: scale(1.06); z-index: 2; outline: none; }
.mesh-atom-wall {
    position: absolute;
    inset: 0;
    box-shadow: inset 0 0 0 2px var(--a-bd, #404068);
    pointer-events: none;
}
.mesh-atom.distorted .mesh-atom-wall {
    box-shadow: inset 0 0 0 2px var(--a-bd, #404068),
                inset 0 0 14px -4px var(--a-bd);
}

/* ── MAINKEY PILL ───────────────────────────────────────────────────────────── */
.mesh-pill {
    position: relative;
    display: inline-flex;
    align-items: center;
    gap: 3px;
    font-size: 0.62rem;
    font-weight: 700;
    letter-spacing: 0.04em;
    color: var(--a-fg, #9090c0);
    background: color-mix(in srgb, var(--a-bd) 26%, transparent);
    padding: 1px 6px;
    border-radius: 6px;
    margin-bottom: 3px;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}
.mesh-badge { color: #ffcf5a; font-weight: 900; }
.mesh-atom.effect .mesh-pill { box-shadow: 0 0 0 1px #b08ee8; }

/* ── SC PEBBLES ─────────────────────────────────────────────────────────────── */
.mesh-pebbles {
    position: relative;
    display: flex;
    flex-flow: row wrap;
    gap: 2px 3px;
}
.mesh-peb {
    display: inline-flex;
    align-items: center;
    gap: 2px;
    font-size: 0.52rem;
    line-height: 1.3;
    color: var(--a-fg, #9090c0);
    background: rgba(255, 255, 255, 0.04);
    border-radius: 4px;
    padding: 0 3px;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}
.mesh-peb-dot {
    width: 5px;
    height: 5px;
    border-radius: 50%;
    background: var(--dot, #888);
    flex: 0 0 auto;
}
.mesh-peb.hollow .mesh-peb-dot {
    background: transparent;
    box-shadow: inset 0 0 0 1px var(--dot, #888);
}
.mesh-peb.hollow { color: #e0a860; }
.mesh-more {
    font-size: 0.5rem;
    color: #666;
    align-self: center;
}

/* ── SEPARATOR + .C FEATHER STUBS (the runtime substrate, quieter) ──────────── */
.mesh-sep {
    height: 0;
    border-top: 1px dashed color-mix(in srgb, var(--a-bd) 40%, transparent);
    margin: 3px 0 2px;
}
.mesh-stubs {
    display: flex;
    flex-flow: row wrap;
    align-items: center;
    gap: 3px;
    opacity: 0.6;
}
.mesh-stub {
    width: 10px;
    height: 0;
    border-top: 1px dashed var(--a-bd, #404068);
}

/* ── INSPECT OVERLAY (fibre bundle) ─────────────────────────────────────────── */
.mesh-scrim {
    position: fixed;
    inset: 0;
    background: rgba(4, 4, 10, 0.4);
    border: none;
    padding: 0;
    z-index: 20;
    cursor: default;
}
.mesh-overlay {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    z-index: 21;
    width: min(380px, 90vw);
    max-height: 80vh;
    overflow: auto;
    background: var(--a-bg, #12121e);
    color: var(--a-fg, #9090c0);
    border: 1px solid var(--a-bd, #404068);
    border-radius: 8px;
    padding: 0 0 10px;
    box-shadow: 0 12px 40px -8px rgba(0, 0, 0, 0.8);
    font-size: 0.72rem;
}
.mesh-ov-pill {
    font-weight: 800;
    letter-spacing: 0.05em;
    padding: 8px 12px;
    background: color-mix(in srgb, var(--a-bd) 30%, transparent);
    border-bottom: 1px solid var(--a-bd);
}
.mesh-ov-section { padding: 6px 12px; }
.mesh-ov-head {
    font-size: 0.56rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    opacity: 0.6;
    margin-bottom: 3px;
}
.mesh-ov-row { font-family: ui-monospace, monospace; font-size: 0.68rem; padding: 1px 0; }
.mesh-ov-row.dim { opacity: 0.55; }
.mesh-ov-row.hollow { color: #e0a860; }
.mesh-ov-twist {
    margin: 4px 12px 0;
    padding: 4px 8px;
    border-radius: 5px;
    font-size: 0.64rem;
    background: rgba(224, 168, 96, 0.14);
    color: #e8b870;
}
.mesh-ov-twist.effect {
    background: rgba(176, 142, 232, 0.16);
    color: #c8a8f0;
}
.mesh-ov-foot {
    font-size: 0.56rem;
    opacity: 0.5;
    padding: 4px 12px 0;
    text-transform: uppercase;
    letter-spacing: 0.06em;
}
</style>
