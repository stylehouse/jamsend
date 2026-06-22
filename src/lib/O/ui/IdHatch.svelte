<script lang="ts">
    // The cluster-identity receiver hatch (toggled by the 'Id' action, Auto.svelte). A browser tab
    //  can't read the node-side .env.cluster-<role> files, so its signing key lives on H.stashed
    //   under 'cluster_idento' = {"pub","key"} — the same slot Lies_cluster_idento reads. Here you
    //    paste a role file to load it, or copy your public identity to share. Parsing the .env format
    //     keeps the flow to: `cat .env.cluster-editor | xclip -selection clipboard` → paste → Set.
    import FaceSucker from "$lib/p2p/ui/FaceSucker.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { H }: { H: House } = $props()

    let pasted = $state('')
    let msg    = $state('')
    // The cluster identity lives on the top House's Dexie-backed .stashed (NOT localStorage), distinct
    //  from the page's main Peering Id. $derived so it's read live — Set takes effect with no reload —
    //   and stashed's autosave persists it across reloads.
    const current = $derived(((H.stashed as any)?.cluster_idento ?? null) as { pub: string; key: string } | null)

    // Pull the first CLUSTER_IDENTO_<ROLE>_KEY + its matching _PUB out of pasted .env text.
    function parseEnv(text: string): { pub: string; key: string } | null {
        const env: Record<string, string> = {}
        for (const ln of text.split('\n')) {
            const m = ln.match(/^\s*([A-Z0-9_]+)\s*=\s*(.+?)\s*$/)
            if (m) env[m[1]] = m[2]
        }
        const keyK = Object.keys(env).find(k => /^CLUSTER_IDENTO_.+_KEY$/.test(k))
        if (!keyK) return null
        const pub = env[keyK.replace(/_KEY$/, '_PUB')]
        if (!pub || !/^[0-9a-f]{64}$/.test(pub) || !/^[0-9a-f]{64}$/.test(env[keyK])) return null
        return { pub, key: env[keyK] }
    }

    function apply() {
        const id = parseEnv(pasted)
        if (!id) { msg = '✗ no valid CLUSTER_IDENTO_<ROLE>_KEY/_PUB found — paste a .env.cluster-<role> file.'; return }
        ;(H.stashed as any).cluster_idento = id
        pasted = ''
        msg = `✓ identity set (addr ${id.pub.slice(0, 16)}…). Compiles sign now — no reload needed.`
    }
    async function copyId() {
        if (!current?.pub) { msg = 'no identity set yet — paste one first.'; return }
        try { await navigator.clipboard.writeText(current.pub); msg = '✓ public identity copied to clipboard.' }
        catch { msg = current.pub }
    }
    function clear() { delete (H.stashed as any).cluster_idento; msg = 'identity cleared.' }
    function close() { if (H.stashed) delete (H.stashed as any).showId }
</script>

<FaceSucker altitude={88} fullscreen={true}>
    {#snippet content()}
        <div class="id-hatch">
            <h2>🪪 Cluster identity</h2>
            <p class="cur">{current
                ? `loaded: addr ${current.pub.slice(0, 16)}…`
                : "none — this tab can't sign privileged frames (gen_write, ghost_update)"}</p>
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
