<script lang="ts">
    // LandMember — a pane NOT opened as code: the Doc as a stiff member, the hierarchical list of its objects (Wordland_todo §0
    //  "THE WEAVE").  Its body is the reader's beadchain (Lagoon_beads — regions in file order, each def under the bead its author
    //   drew it inside), each bead's defs laid as a StemHive (the minimap's stem-factoring hive), so a family of names reads as one
    //    shape.  Every def chip carries `data-mid` (StemHive's), and the member carries `data-pane`, which is how LandFace's wire layer
    //     finds both ends of a %Wire.  Pressing a def opens the pane as CodeMirror at it (`:pane code <n> <method>`).
    import StemHive from "$lib/O/ui/StemHive.svelte"
    let { n, doc, chain = [], at = '', lit = new Set<string>(), error = '', onpick, oncode, onclose }: {
        n: string, doc: string, chain?: any[], at?: string, lit?: Set<string>, error?: string,
        onpick?: (method: string) => void, oncode?: () => void, onclose?: () => void
    } = $props()
    // beads in file order; the defs outside every bead lead, as one unnamed bead
    let beads = $derived.by(() => {
        const out: { label: string, depth: number, items: { id: string, label: string }[] }[] = []
        const by = new Map<string, any>()
        const bead = (label: string, depth: number) => {
            let b = by.get(label)
            if (!b) { b = { label, depth, items: [] }; by.set(label, b); out.push(b) }
            return b
        }
        for (const c of chain) {
            if (c.kind === 'region') bead(c.label, c.depth ?? 1)
            else bead(c.bead ?? '', c.bead ? (c.depth ?? 1) : 0).items.push({ id: c.label, label: c.label })
        }
        return out.filter(b => b.items.length)
    })
    let pointed = $derived(new Set<string>([...(at ? [at] : []), ...lit]))
</script>

<div class="member" data-pane={n}>
    <div class="bar">
        <b>{n}</b> <span class="doc" title={doc}>{doc}</span>{#if at}<span class="at">· {at}</span>{/if}
        {#if oncode}<button type="button" title="open as code" onclick={oncode}>{'{ }'}</button>{/if}
        {#if onclose}<button type="button" title="close this pane" onclick={onclose}>×</button>{/if}
    </div>
    <div class="body">
        {#if error}<div class="none">{error}</div>{/if}
        {#each beads as b (b.label)}
            <div class="bead" data-bead={b.label} style="margin-left:{Math.max(0, b.depth - 1) * 0.8}rem">
                {#if b.label}<div class="bl">◆ {b.label}</div>{/if}
                <StemHive items={b.items} {pointed} onpick={(id: string) => onpick?.(id)} />
            </div>
        {/each}
    </div>
</div>

<style>
    .member { display: flex; flex-direction: column; min-width: 0; min-height: 0; border: 1px solid #23453a; border-radius: 6px;
        overflow: hidden; background: #0b1310 }
    .bar { display: flex; gap: 6px; align-items: baseline; padding: 2px 8px; background: #16281f; font: 11px ui-monospace, monospace }
    .doc { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; flex: 0 1 auto }
    .at { color: #8fd3b0 }
    button { background: none; border: none; color: #cfe3d8; cursor: pointer; padding: 0 2px }
    button:first-of-type { margin-left: auto }
    .body { flex: 1 1 auto; min-height: 0; overflow: auto; padding: 4px 6px }
    .bead { margin: 2px 0 6px; padding-left: 4px; border-left: 2px solid #23453a }
    .bl { font: 11px ui-monospace, monospace; color: #8fd3b0; opacity: .85 }
    .none { opacity: .6; font-size: 12px }
</style>
