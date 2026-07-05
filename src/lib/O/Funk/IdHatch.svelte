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
    import { socklog_armed, socklog_arm } from "$lib/O/sockcap"
    import { has_audio, set_has_audio } from "$lib/boot"

    // mounted as a Lens panel (LensHost) — the extra panel props (lens/funk/w) land in rest, ignored.
    let { H, ...rest }: { H: House } & Record<string, any> = $props()
    void rest

    let pasted = $state('')
    let msg    = $state('')
    // per-tab diagnostic: arm the /relay socket capture (sockcap → wormhole/_socklog).  Persisted in
    //  localStorage so Otro reads it BEFORE the channel boots; a flip takes effect on the next reload.
    let socklog_on = $state(socklog_armed())
    // The durable "this tab provides a real AudioContext" intent (IdHatch is where a tab becomes its
    //  %Identity, so its capabilities are declared here too).  Persisted per-tab; the live audio gate
    //   (Otro's "open share") is the runtime consequence — a ticked tab demands a gesture until AC_ready.
    let audio_on = $state(has_audio())

    // The ACTIVE %Identity's public face {prepub, nick}, polled live: the adopt lands via post_do
    //  on the tick (a C-tree mutation), which a derived off H.version wouldn't catch — and a fullscreen
    //   panel can well afford a slow poll.
    let poll = $state(0)
    onMount(() => { const iv = setInterval(() => poll++, 500); return () => clearInterval(iv) })
    let current = $derived.by(() => { void poll; return (H as any).Clustation_self?.(H) as { prepub: string; nick?: string } | undefined })
    // cluster-trust status of the active identity: is our pub in the CODE-PUSH allowlist (CLUSTER_TRUSTED_PUBS)?
    //  Flips to trusted only after a dev-server restart re-bakes the file `Set up cluster trust` writes.
    let trust = $derived.by(() => { void poll; return (H as any).Lies_cluster_trust_status?.() as { prepub?: string; in_set: boolean; configured: boolean } | undefined })

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
            const ok = await (H as any).Clustation_adopt?.(parsed.id)
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
    // Write .env.cluster-pubs (trust THIS editor + claude) + mint .env.cluster-claude if absent, via the
    //  editor's own FSA.  Rebuilds the trusted set to the two-entry model; runner pubs stay out (%Grant).
    async function setup() {
        msg = '⏳ writing cluster-trust files via the Wormhole…'
        msg = (await (H as any).Lies_cluster_setup?.()) ?? '✗ cluster-setup unavailable'
    }
    function toggle_socklog() {
        socklog_on = !socklog_on
        socklog_arm(socklog_on)
        msg = socklog_on
            ? '📡 socklog ARMED — reload this tab to start capturing /relay traffic to wormhole/_socklog.'
            : 'socklog off — reload to stop capturing.'
    }
    function toggle_audio() {
        audio_on = !audio_on
        set_has_audio(audio_on)
        msg = audio_on
            ? '🔊 this tab will provide AudioContext — reload, then tap “open share” once to grant the gesture.'
            : 'audio intent off — reload; this tab no longer offers a real AudioContext.'
    }
    function close() { (H as any).Lies_lens_dismiss?.('Panel', 'IdHatch') }
</script>

<FaceSucker altitude={88} fullscreen={true}>
    {#snippet content()}
        <div class="id-hatch">
            <h2>🪪 Cluster identity</h2>
            <p class="cur">{current
                ? `active: ${current.nick ?? ''} · addr ${current.prepub}…`
                : "none — this tab can't sign privileged frames (gen_write, ghost_compile) or join the grid"}</p>
            {#if current}
                <p class="trust" class:ok={trust?.in_set} class:warn={trust?.configured && !trust?.in_set}>
                    {#if !trust?.configured}
                        ⓘ cluster trust not enforced (no CLUSTER_TRUSTED_PUBS) — the relay warn-and-allows compiles.
                    {:else if trust?.in_set}
                        ✅ trusted — your compiled writes (gen_write) are authorised.
                    {:else}
                        ⚠️ NOT in the trust flock — the relay will REJECT your compiles. “Set up cluster trust” adds you.
                    {/if}
                </p>
            {/if}
            <div class="flags">
                <span class="flags-h">this tab:</span>
                <button class="flag" class:on={socklog_on} onclick={toggle_socklog}
                    title="capture this tab's /relay socket traffic to wormhole/_socklog — arms the tap on the next reload">
                    {socklog_on ? '☑' : '☐'} socklog capture
                </button>
                <button class="flag" class:on={audio_on} onclick={toggle_audio}
                    title="this tab aims to provide a real AudioContext for real-time audio Books — you tap “open share” once per load to grant the gesture">
                    {audio_on ? '☑' : '☐'} 🔊 provide AudioContext
                </button>
            </div>
            <p class="hint">Import an identity — paste a <code>.env.cluster-&lt;role&gt;</code> file (e.g. the
                <code>.env.cluster-claude</code> the setup writes, or one shared from another host):</p>
            <textarea bind:value={pasted} rows="5"
                placeholder="CLUSTER_IDENTO_CLAUDE_KEY=…&#10;CLUSTER_IDENTO_CLAUDE_PUB=…"></textarea>
            <div class="row">
                <button onclick={apply} disabled={!pasted.trim()}>Set identity</button>
                <button onclick={setup} disabled={!current} title="write .env.cluster-pubs (trust this editor + claude) + mint the claude key">Set up cluster trust</button>
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
    .trust { font-size: 0.85rem; margin: 0; opacity: 0.9; }
    .trust.ok { color: #6cc070; }
    .trust.warn { color: #e0a030; }
    .hint { font-size: 0.8rem; opacity: 0.75; margin: 0; }
    .flags { display: flex; align-items: center; gap: 0.4rem; flex-wrap: wrap; font-size: 0.8rem; }
    .flags-h { opacity: 0.55; }
    .flag { background: #14141c; border: 1px solid #333; border-radius: 4px; color: #99a; cursor: pointer; padding: 0.2rem 0.55rem; font-size: 0.8rem; font-family: monospace; }
    .flag.on { color: #6cc070; border-color: #3a5a3a; }
    .id-hatch textarea { width: 100%; font-family: monospace; font-size: 0.8rem; background: #000; color: #cfe0cf; border: 1px solid #333; border-radius: 4px; padding: 0.4rem; }
    .row { display: flex; gap: 0.5rem; flex-wrap: wrap; }
    .row button { padding: 0.3rem 0.7rem; border: none; border-radius: 4px; background: #2196F3; color: white; cursor: pointer; }
    .row button:disabled { opacity: 0.4; cursor: default; }
    .msg { font-family: monospace; font-size: 0.85rem; }
</style>
