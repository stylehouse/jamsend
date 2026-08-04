<script lang="ts">
    // The cluster-identity hatch (toggled by the 'Id' action, Auto.svelte) — THE control point for who
    //  this tab is.  An %Identity (Clustation) is minted HERE and nowhere else: persisted to the
    //   `identities` Thang, made active, its %Peering laid.  The very object ?I=<tag> resumes; the channel
    //    signs as the active one (Lies_cluster_idento), and a runner advertises as it.
    //  Two ways in, both explicit: boot ?I=new, or answer an identity ARREST with "Generate a new
    //   identity" (Auto.svelte Clustation_ensure_identity — a named ?I= this browser can't resume holds
    //    the whole boot rather than silently minting a stranger, the 2026-08-04 incident).
    //  Also the trust control point: "Set up cluster trust" writes .env.cluster-pubs through this tab's
    //   OWN FSA — see Cluster_spec §2.8a for why that is self-certifying and what bounds it.
    //  (Legacy .stashed.cluster_idento is no longer written; Lies_cluster_idento still reads it as a
    //   fallback, and Auto's boot adopts it into a first-class %Identity once.)
    import FaceSucker from "$lib/p2p/ui/FaceSucker.svelte"
    import { onMount } from "svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { socklog_armed, socklog_arm } from "$lib/O/sockcap"
    import { has_audio, set_has_audio } from "$lib/boot"

    // mounted as a Lens panel (LensHost) — the extra panel props (lens/funk/w) land in rest, ignored.
    let { H, ...rest }: { H: House } & Record<string, any> = $props()
    void rest

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
    // THE ARREST (Auto.svelte Clustation_ensure_identity, 2026-08-04): this tab booted with a named
    //  ?I=<tag> it holds no stored key for. A prepub is a PUBLIC address — the private half can never be
    //   reconstructed from it — so the only honest moves are "paste the real key" or "mint a new one, and
    //    know that you did". Auto and Lies_channel_up both halt while this is set, so the tab does nothing
    //     and stays off the wire until a human picks one. Same 500ms poll as `current` (a .c stamp, which
    //      no $derived off H.version would catch).
    let pending = $derived.by(() => { void poll; return (((H as any).top_House?.() ?? H).c?.identity_pending) as string | undefined })
    // why it was arrested — a plain miss ("no key stored here") reads very differently from a CORRUPT
    //  row (filed under one tag, holding another's keypair — the old silent-mint bug's residue), and the
    //   remedy differs too, so the hatch says which rather than making you guess.
    let pending_why = $derived.by(() => { void poll; return (((H as any).top_House?.() ?? H).c?.identity_pending_why) as string | undefined })

    // PASTE-A-.env IMPORT REMOVED (2026-08-04, the human: "this Cluster identity popup is the control
    //  point now"). The hatch used to accept a pasted .env.cluster-<role> and adopt its keypair. It went
    //   because it was ceremony around a capability the FSA already grants unconditionally — a tab that
    //    can reach the repo can just WRITE the trust file (Lies_cluster_setup does exactly that), so
    //     hand-carrying a secret through a textarea bought no security, only a second way to end up with
    //      an identity nobody chose. Minting here is now the ONE way a tab acquires one.
    //  The verb survives: Clustation_adopt is still called by Auto's legacy .stashed.cluster_idento
    //   migration, so re-surfacing an import later is a UI job, not a model change.
    //  KNOWN LOSS, deliberate: there is no longer any way to move an identity BETWEEN browsers/machines,
    //   and the only exit from an identity arrest is "Generate a new identity". If cross-machine identity
    //    transfer is ever wanted it needs a real design (see Cluster_spec §2.8a), not this textarea.
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
    // Resolve an arrest the OTHER way: mint a genuinely new identity and adopt it. Deliberately a
    //  separate, explicitly-labelled button rather than something the boot does for you — minting on a
    //   miss is exactly the silent substitution that caused this whole class of bug. The verb no-ops
    //    unless a miss is really pending, so a stale re-render can't mint behind your back.
    function generate() {
        const want = pending
        ;(H as any).post_do(async () => {
            const ok = await (H as any).Clustation_generate_for_pending?.(H)
            msg = ok
                ? `✓ new identity minted and active — the ?I= in the address bar now points at it, not ${want}. Reload-safe.`
                : '✗ nothing pending to resolve (or the identity layer is not mounted yet).'
        }, { see: 'generate_identity' })
        msg = '⏳ minting a new identity…'
    }
    function close() { (H as any).Lies_lens_dismiss?.('Panel', 'IdHatch') }
</script>

<FaceSucker altitude={88} fullscreen={true}>
    {#snippet content()}
        <div class="id-hatch">
            <h2>🪪 Cluster identity</h2>
            {#if pending}
                <p class="pending" role="alert">
                    ⚠ this tab booted as <code>{pending}</code> but cannot become it —
                    {pending_why ?? "no key for it is stored in this browser."}
                    A bare address can't be turned back into its private key. Boot is HELD (no channel, no
                    Story) until this is resolved:
                </p>
                <div class="row"><button onclick={generate}>Generate a new identity</button></div>
            {/if}
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
            <div class="row">
                <button onclick={setup} disabled={!current} title="write .env.cluster-pubs (trust this editor + claude) + mint the claude key">Set up cluster trust</button>
                <button onclick={copyId} disabled={!current}>Copy my public id</button>
                <button onclick={clear} disabled={!current}>Clear</button>
                <button onclick={close}
                    title={pending
                        ? 'the tab stays HELD until the identity is resolved — reopen with the 🪪 Id action'
                        : 'close the hatch'}>{pending ? 'Close (tab stays held)' : 'Close'}</button>
            </div>
            {#if msg}<p class="msg">{msg}</p>{/if}
        </div>
    {/snippet}
</FaceSucker>

<style>
    .id-hatch { max-width: 40rem; display: flex; flex-direction: column; gap: 0.6rem; }
    .id-hatch h2 { margin: 0; }
    .cur { font-family: monospace; opacity: 0.8; }
    .pending { font-size: 0.85rem; margin: 0; color: #e0a030; }
    .pending code { font-family: monospace; }
    .trust { font-size: 0.85rem; margin: 0; opacity: 0.9; }
    .trust.ok { color: #6cc070; }
    .trust.warn { color: #e0a030; }
    .flags { display: flex; align-items: center; gap: 0.4rem; flex-wrap: wrap; font-size: 0.8rem; }
    .flags-h { opacity: 0.55; }
    .flag { background: #14141c; border: 1px solid #333; border-radius: 4px; color: #99a; cursor: pointer; padding: 0.2rem 0.55rem; font-size: 0.8rem; font-family: monospace; }
    .flag.on { color: #6cc070; border-color: #3a5a3a; }
    .row { display: flex; gap: 0.5rem; flex-wrap: wrap; }
    .row button { padding: 0.3rem 0.7rem; border: none; border-radius: 4px; background: #2196F3; color: white; cursor: pointer; }
    .row button:disabled { opacity: 0.4; cursor: default; }
    .msg { font-family: monospace; font-size: 0.85rem; }
</style>
