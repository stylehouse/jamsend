<script lang="ts">
    // TreeFace — ANY PARTICLE, DRAWN AS ITSELF (the human 2026-08-07: "showing a recursive tree of plain
    //  C** data in a useful way ... a cell can kind of be a component or a rendering of the C data all
    //   labelled ... and recurse C**").
    //
    //  Every other face in GLASS_KINDS is bespoke: it knows what a Radio is, what a Heist is, and draws
    //   that meaning.  This one knows NOTHING and draws the particle — mainkey, scalars, children,
    //    recursively.  That is the point.  It is the face for the parts of the tree nobody has designed a
    //     face for yet, and the one that keeps working when the shape changes underneath it.
    //
    //  READ-ONLY AND SC-ONLY, deliberately.  It renders `sc` (the encoded, persisted half) and walks
    //   children through `o({})` — never `.c`, which holds runtime refs and backlinks and would recurse
    //    straight into the House, the parent chain, and every cycle in the graph.  `.c` is summarised as a
    //     COUNT of interesting keys, never followed.  Nothing here writes: a diagnostic that perturbed
    //      what it measures would be worthless (the same stance ShuffleFace takes).
    //
    //  BOUNDED BY CONSTRUCTION.  A cell is small and a crate subtree is thousands of records, so the walk
    //   caps depth and per-level breadth and SAYS SO when it truncates ("… N more") rather than quietly
    //    showing a prefix — a silent cut reads as "that's all there is", which is the expensive kind of lie.
    let { n, H, depth_cap = 3, kid_cap = 12 } = $props()

    // sc keys that are furniture on nearly every particle — they crowd out the ones that carry meaning.
    //  Shown only when a node has nothing else to say, so nothing is truly hidden.
    const DULL = new Set(['face', 'crew', 'dontSnap', 'created_at', 'active', 'new', 'not_found'])

    let open = $state<Record<string, boolean>>({})
    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 1200); return () => clearInterval(iv) })

    type Row = { key: string, depth: number, mk: string, val: string,
                 pairs: [string, string][], kids: number, cref: number, more: number, leaf: boolean }

    const mainkey_of = (p: any): string => {
        const ks = Object.keys(p?.sc ?? {})
        return ks.length ? ks[0] : '?'
    }
    // a value worth printing: scalars only.  An object in sc is a mint bug (fatal at encode) — say so
    //  rather than rendering "[object Object]", because seeing it here is how you find it.
    const show = (v: any): string => {
        if (v === 1 || v === '1') return ''          // a snapped boolean rides as 1-or-absent: the KEY is the fact
        if (v == null) return '∅'
        if (typeof v === 'object') return '⚠object-in-sc'
        const s = String(v)
        return s.length > 28 ? s.slice(0, 27) + '…' : s
    }

    let rows = $derived.by((): Row[] => {
        void tick
        void H?.version
        const out: Row[] = []
        // `tree_root` lets a bare marker particle stand for something else — the %Tree organ carries no
        //  state of its own, it is a place to hang this face, and what it wants drawn is the WORLD it sits
        //   in.  Rides `.c` because it is a ref (an object in `.sc` is fatal at encode).
        const root = (n?.c?.tree_root ?? n) as any
        if (!root?.sc) return out
        const walk = (p: any, depth: number, key: string) => {
            const ks = Object.keys(p.sc ?? {})
            const mk = ks.length ? ks[0] : '?'
            const pairs: [string, string][] = []
            for (const k of ks.slice(1)) {
                if (DULL.has(k)) continue
                pairs.push([k, show(p.sc[k])])
            }
            if (!pairs.length) for (const k of ks.slice(1)) pairs.push([k, show(p.sc[k])])
            let kids: any[] = []
            try { kids = p.o({}) ?? [] } catch { kids = [] }
            // .c is COUNTED, never walked — it holds live refs (up, source_n, the House) and cycles.
            let cref = 0
            try { for (const k of Object.keys(p.c ?? {})) if (p.c[k] != null) cref++ } catch { cref = 0 }
            const shown = kids.slice(0, kid_cap)
            out.push({ key, depth, mk, val: show(p.sc[mk]), pairs, kids: kids.length, cref,
                       more: Math.max(0, kids.length - shown.length), leaf: !kids.length })
            if (depth >= depth_cap) return
            if (kids.length && open[key] === false) return
            let i = 0
            for (const ch of shown) { walk(ch, depth + 1, key + '/' + i + ':' + mainkey_of(ch)); i++ }
        }
        walk(root, 0, mainkey_of(root))
        return out
    })
</script>

<div class="tf">
    {#each rows as r (r.key)}
        <div class="tf-row" style="padding-left:{r.depth * 8}px">
            {#if r.kids}
                <button class="tf-tw" onclick={() => (open[r.key] = open[r.key] === false)}
                        title={open[r.key] === false ? 'expand' : 'collapse'}>{open[r.key] === false ? '▸' : '▾'}</button>
            {:else}
                <span class="tf-tw tf-leaf">·</span>
            {/if}
            <span class="tf-mk">{r.mk}{#if r.val}<span class="tf-mkv">:{r.val}</span>{/if}</span>
            {#each r.pairs as [k, v]}
                <span class="tf-kv" class:flagonly={!v}><span class="tf-k">{k}</span>{#if v}<span class="tf-v">{v}</span>{/if}</span>
            {/each}
            {#if r.kids}<span class="tf-n">{r.kids}</span>{/if}
            {#if r.cref}<span class="tf-c" title="{r.cref} runtime ref(s) on .c — never encoded, never walked here">c{r.cref}</span>{/if}
            {#if r.more}<span class="tf-more">… {r.more} more</span>{/if}
            {#if r.depth === depth_cap && r.kids}<span class="tf-more">↓ deeper</span>{/if}
        </div>
    {/each}
    {#if !rows.length}<div class="tf-more">nothing standing here</div>{/if}
</div>

<style>
    .tf { font-family: ui-monospace, 'SF Mono', Menlo, monospace; font-size: 9px; line-height: 1.45; color: #cdd6e0; }
    .tf-row { display: flex; align-items: baseline; gap: 3px; flex-wrap: wrap; white-space: nowrap; }
    .tf-tw {
        background: none; border: 0; padding: 0; margin: 0; cursor: pointer;
        color: #7f9fc8; font-size: 9px; width: 8px; flex: none;
    }
    .tf-leaf { color: #47506080; cursor: default; }
    /* the mainkey is what the thing IS — it gets the weight; everything else is a property of it */
    .tf-mk { color: #ffd869; font-weight: 700; }
    .tf-mkv { color: #d8b45a; font-weight: 400; }
    .tf-kv {
        background: rgba(127, 159, 200, 0.12); border-radius: 2px; padding: 0 3px;
        border: 1px solid rgba(127, 159, 200, 0.18);
    }
    /* a key with no value IS the value — a snapped boolean rides as 1-or-absent */
    .tf-kv.flagonly { background: rgba(127, 232, 191, 0.14); border-color: rgba(127, 232, 191, 0.3); }
    .tf-k { color: #8fa8c4; }
    .tf-v { color: #e8eef4; }
    .tf-k + .tf-v::before { content: ':'; color: #5d6b7a; }
    .tf-n { color: #7fe8bf; }
    .tf-c { color: #6a7280; }
    .tf-more { color: #8a7fb0; font-style: italic; }
</style>
