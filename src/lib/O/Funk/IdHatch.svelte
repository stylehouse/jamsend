<script lang="ts">
    // The cluster-identity hatch (toggled by the 'Id' action, Auto.svelte).  A browser tab can't read
    //  the node-side .env.cluster-<role> files, so you paste one here — and it becomes a first-class
    //   %Identity (Clustation): persisted to the `identities` Thang, made active, its %Peering laid.
    //    The very object ?I=<tag> produces; the channel signs as the active one (Lies_cluster_idento),
    //     and a runner advertises as it.  Flow stays: `cat .env.cluster-editor | xclip` → paste → Set.
    //   (Legacy .stashed.cluster_idento is no longer written; Lies_cluster_idento still reads it as a
    //    fallback, so an old key keeps working until you re-paste it to adopt it as an %Identity.)
    import FaceSucker from "$lib/p2p/ui/FaceSucker.svelte"
    import { onMount } from "svelte"
    import type { House } from "$lib/O/Housing.svelte"

    // mounted as a Lens panel (LensHost) — the extra panel props (lens/funk/w) land in rest, ignored.
    let { H, ...rest }: { H: House } & Record<string, any> = $props()
    void rest

    let pasted = $state('')
    let msg    = $state('')

    // The ACTIVE %Identity's public face {prepub, friendly}, polled live: the adopt lands via post_do
    //  on the tick (a C-tree mutation), which a derived off H.version wouldn't catch — and a fullscreen
    //   panel can well afford a slow poll.
    let poll = $state(0)
    onMount(() => { const iv = setInterval(() => poll++, 500); return () => clearInterval(iv) })
    let current = $derived.by(() => { void poll; return (H as any).Clustation_self?.(H) as { prepub: string; friendly?: string } | undefined })

    // Pull the first CLUSTER_IDENTO_<ROLE>_KEY + its matching _PUB (and the ROLE, for a friendly) out
    //  of pasted .env text.
    function parseEnv(text: string): { id: { pub: string; key: string }, role: string } | null {
        const env: Record<string, string> = {}
        for (const ln of text.split('\n')) {
            const m = ln.match(/^\s*([A-Z0-9_]+)\s*=\s*(.+?)\s*$/)
            if (m) env[m[1]] = m[2]
        }
        const keyK = Object.keys(env).find(k => /^CLUSTER_IDENTO_.+_KEY$/.test(k))
        if (!keyK) return null
        const pub = env[keyK.replace(/_KEY$/, '_PUB')]
        if (!pub || !/^[0-9a-f]{64}$/.test(pub) || !/^[0-9a-f]{64}$/.test(env[keyK])) return null
        const role = (keyK.match(/^CLUSTER_IDENTO_(.+)_KEY$/)?.[1] ?? '').toLowerCase()
        return { id: { pub, key: env[keyK] }, role }
    }

    function apply() {
        const parsed = parseEnv(pasted)
        if (!parsed) { msg = '✗ no valid CLUSTER_IDENTO_<ROLE>_KEY/_PUB found — paste a .env.cluster-<role> file.'; return }
        const short = parsed.id.pub.slice(0, 16)
        // Adopt on the tick (post_do): it mutates the C tree (A:Clustation, %Identity, %Peering) and
        //  awaits the Thangs persist — neither belongs in a raw click outside the mutex.
        ;(H as any).post_do(async () => {
            const ok = await (H as any).Clustation_adopt?.(parsed.id, parsed.role || undefined)
            msg = ok
                ? `✓ ${short}… adopted as an %Identity — signs now, persisted, on the grid. No reload.`
                : '✗ identity layer not ready (Thangs not mounted) — Set again in a moment.'
        }, { see: 'adopt_identity' })
        pasted = ''
        msg = `⏳ adopting ${short}…`
    }
    async function copyId() {
        const keys = (H as any).Clustation_active_identity?.(H) as { pub: string } | undefined
        if (!keys?.pub) { msg = 'no identity active yet — paste one first.'; return }
        try { await navigator.clipboard.writeText(keys.pub); msg = '✓ public identity copied to clipboard.' }
        catch { msg = keys.pub }
    }
    function clear() {
        ;(H as any).post_do(() => (H as any).Clustation_clear?.(H), { see: 'clear_identity' })
        msg = 'identity cleared (switched away — the saved key stays, re-selectable by ?I=<addr>).'
    }
    function close() { (H as any).Lies_lens_dismiss?.('Panel', 'IdHatch') }
</script>

<FaceSucker altitude={88} fullscreen={true}>
    {#snippet content()}
        <div class="id-hatch">
            <h2>🪪 Cluster identity</h2>
            <p class="cur">{current
                ? `active: ${current.friendly ?? current.prepub} — addr ${current.prepub}…`
                : "none — this tab can't sign privileged frames (gen_write, ghost_compile) or join the grid"}</p>
            <p>Paste a <code>.env.cluster-&lt;role&gt;</code> file — generate &amp; copy with:</p>
            <pre>npx vite-node scripts/gen-cluster-identos.ts
cat .env.cluster-editor | xclip -selection clipboard</pre>
            <textarea bind:value={pasted} rows="5"
                placeholder="CLUSTER_IDENTO_EDITOR_KEY=…&#10;CLUSTER_IDENTO_EDITOR_PUB=…"></textarea>
            <div class="row">
                <button onclick={apply} disabled={!pasted.trim()}>Set identity</button>
                <button onclick={copyId} disabled={!current}>Copy my public id</button>
                <button onclick={clear} disabled={!current}>Clear</button>
                <button onclick={close}>Close</button>
            </div>
            {#if msg}<p class="msg">{msg}</p>{/if}
        </div>
    {/snippet}
</FaceSucker>

<style>
    .id-hatch { max-width: 40rem; display: flex; flex-direction: column; gap: 0.6rem; }
    .id-hatch h2 { margin: 0; }
    .cur { font-family: monospace; opacity: 0.8; }
    .id-hatch pre { background: #0003; padding: 0.5rem; border-radius: 4px; font-size: 0.75rem; overflow-x: auto; }
    .id-hatch textarea { width: 100%; font-family: monospace; font-size: 0.8rem; }
    .row { display: flex; gap: 0.5rem; flex-wrap: wrap; }
    .row button { padding: 0.3rem 0.7rem; border: none; border-radius: 4px; background: #2196F3; color: white; cursor: pointer; }
    .row button:disabled { opacity: 0.4; cursor: default; }
    .msg { font-family: monospace; font-size: 0.85rem; }
</style>
