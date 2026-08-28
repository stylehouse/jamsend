<script lang="ts">
    // LinkDevice — the "spread out" front door (Division_todo §CEREMONY).  The DISTINCT, smaller sibling of
    //  InvitePanel's "invite a friend": here you divide YOURSELF across your own devices.  The model is the
    //   HANDSHAKE + FERRY (Swarm_ferry_* in Ghost/S/Swarm.g), NOT the old adopt-seal — that inverted the
    //    roles and never crossed, because Swarm_deliver has no pier to route over until a handshake forms one.
    //  The correct, proven order (SwarmRole forms the pier + cross-signs %Grant:MyCave; SwarmFerry proves the
    //   sealed account crosses):
    //    · LINK    — the SOUL device (the one that already IS you) mints an %Invite:MyCave and shows its QR
    //                 (`?Iz=<invite>#fc=<secret>`).  The seal secret rides the URL FRAGMENT, never the relay.
    //    · (the new device opens that URL → the ordinary invite-landing path redeems it → pier_hello/accept
    //       forms the %Pier BOTH ways + cross-signs MyCave → the soul device's Swarm_ferry_on_seal fires the
    //        instant the pier seals, ferrying the sealed account over it.)
    //    · RECEIVE — the new device HEARD the sealed account (Swarm_ferry_pending): the BODILY warning + the
    //                 #fc code from its own address bar → Swarm_ferry_consume imports it.  Becoming a body is
    //                  DECIDED here, never automatic.
    //  ⚠ THE WARNING IS THE POINT: a friend-invite mis-scanned adds a friend; this shares your IDENTITY.  So
    //   RECEIVE wears its own alarm colour and names exactly what is shared, and reuses none of the friend
    //    flow's welcome.  The redeem of the `?Iz=` half is left to the proven invite-landing path (InvitePanel
    //     / Butler) — a MyCave invite is an ordinary invite with a different grant feature.
    import InviteQR from "$lib/O/ui/micro/InviteQR.svelte"
    let { H } = $props()

    // the machine's live soul (may be null mid-standup), and the station world/up (dialable before a scan)
    let self = $state<any>(null)
    $effect(() => {
        H?.version
        if (typeof H?.Swarm_live_self !== 'function') return
        let v: any = null
        try { v = H.Swarm_live_self() } catch { v = null }
        if (v && v !== self) self = v
    })
    let stood = false
    $effect(() => {
        H?.version
        if (stood || !self || typeof H?.Swarm_station_up !== 'function') return
        const w = H.Swarm_station_world?.()
        if (w && H.Swarm_station_up(w, self)) stood = true
    })
    const world = () => H?.Swarm_station_world?.() ?? null

    let err = $state('')
    let trust = $state(false)   // "TOTAL TRUST" opens the one warning that matters — the account copies

    // the #fc seal secret from THIS page's own address bar (the QR carried it in the fragment, out of band).
    function frag_code(): string {
        try { const h = new URL(location.href).hash; const m = /(?:^#|&)fc=([^&]+)/.exec(h); return m ? decodeURIComponent(m[1]) : '' } catch { return '' }
    }

    // ── RECEIVE — a ferried account is parked, awaiting this device's consent ───────────────────────
    let pending = $state<any>(null)
    $effect(() => {
        H?.version
        const w = world()
        if (w && typeof H?.Swarm_ferry_pending === 'function') { try { pending = H.Swarm_ferry_pending(w) ? H.Swarm_ferry_peek?.(w) ?? {} : null } catch { pending = null } }
    })
    // the arriving soul's id, for the human to eyeball (salt is `<soulpub>:<mypub>`)
    const arriving_soul = () => { try { return String(pending?.frame?.salt || '').split(':')[0] } catch { return '' } }
    let received = $state('')
    async function receive(yes: boolean) {
        err = ''
        try {
            if (!yes) { await H.Swarm_ferry_consume(world(), '', false); received = 'declined'; pending = null; return }
            const code = frag_code()
            if (!code) { err = 'no seal code in this link — open the exact QR link from your soul device'; return }
            const soul = await H.Swarm_ferry_consume(world(), code, true)
            received = soul ? 'you are now a body of that soul — it lives on this device too' : 'could not join (wrong code, or the seal failed)'
            pending = null
        } catch (e) { err = String(e) }
    }

    // ── LINK — the soul device mints the invite+ferry link and shows its QR ─────────────────────────
    let url = $state('')
    const qr_size = 180   // the QR sits in the top-left quarter of the beige oblong (a fixed first cut)
    async function link() {
        err = ''
        try {
            const w = world()
            if (w && typeof H.Swarm_station_up === 'function' && H.Swarm_station_up(w, self)) stood = true
            url = await H.Swarm_ferry_link(w, self, location.origin + location.pathname)
            if (!url) err = 'no live identity yet — wait a moment and retry'
        } catch (e) { err = String(e) }
    }

    const short = (s: string) => (s ? String(s).slice(0, 8) : '')
    // the ORIGIN both devices must share — a cross-origin scan (localhost vs djamsend) lands on two
    //  different relays and the pier can NEVER seal ("nobody came online"), so name it right at the QR.
    let origin = $state('')
    $effect(() => { try { origin = new URL(location.href).host } catch { origin = '' } })
    // LIVE PEER FEEDBACK — the wait was silent (you couldn't tell a scan had landed until the late
    //  "nobody came online").  Read whether a MyCave pier has actually SEALED to this soul: the moment the
    //   other device handshakes, this flips ✓ and the ferry is already on its way (the pump-retry sends it).
    let peer_ready = $state(false)
    $effect(() => {
        void H?.version
        try {
            const p = self && typeof H?.Swarm_peering === 'function' ? H.Swarm_peering(self) : null
            const piers = p ? p.o({ Pier: 1 }) : []
            peer_ready = !!piers.find((x: any) => H.Swarm_pier_live?.(x, 'MyCave'))
        } catch { peer_ready = false }
    })
    // IS A LINK IN FLIGHT ON THIS TAB (an unspent secret / a parked account)?  A reload loses `url` but the
    //  soul's secret persists, so without this the face would show the plain "link a device" button over a
    //   live ceremony and a click would mint a SECOND one — the wedge you couldn't get out of.  When true and
    //    we have no local QR to show, the default face offers a real reset (Swarm_ferry_cancel clears House
    //     state, not just the component's `url`).
    let link_active = $state(false)
    $effect(() => {
        void H?.version
        try { link_active = !!H?.Swarm_ferry_pending?.(world()) || !!H?.Swarm_link_active?.(world()) } catch { link_active = false }
    })
    function cancel_link() {
        err = ''
        try { H?.Swarm_ferry_cancel?.(world()) } catch (e) { err = String(e) }
        url = ''; pending = null
    }
</script>

<!-- ONE FRAME, BOTH ENDS: the same blurb explains the act on the soul device AND the new device, so the
     language is unified; only the action row below it differs by which side you're on. -->
<div class="ld-frame">
    <p class="ld-blurb">
        <!-- the owner's sentence, dictated twice — keep it verbatim -->
        backup or colonise other devices, becoming a sloshway of cooperation and
        <button class="ld-trust" onclick={() => trust = !trust}>TOTAL TRUST</button>.
    </p>
    {#if trust}
        <p class="ld-warn-note">
            It <b>copies your account</b> to the other device and then they become a team in music sharing.
            But it's you logged in forever, may sit <b>unencrypted at rest</b>.
        </p>
    {/if}

    {#if pending}
        <div class="ld-face">
            {#if received}
                <div class="ld-note">{received}</div>
            {:else}
                <p class="ld-deal">A sealed account from <b>{short(arriving_soul())}…</b> is arriving over the
                    link — accept it and this device <b>becomes that soul</b> (a Cave of it), holding its keys
                    and serving its library <b>as it</b>.</p>
                <div class="ld-row">
                    <button class="ld-go" onclick={() => receive(true)}>accept — become this soul</button>
                    <button class="ld-cancel-b" onclick={() => receive(false)}>no</button>
                </div>
            {/if}
        </div>
    {:else if url}
        <div class="ld-face">
            <div class="ld-cap-big">link a device as your <b>Cave</b></div>
            <InviteQR {url} size={qr_size} bg="#e7dcbe" bare caption="" />
            {#if peer_ready}
                <div class="ld-connected">✓ the other device connected — ferrying your account now… accept it there</div>
            {:else}
                <div class="ld-wait-big">open this on the other device · …waiting for it to handshake, then I ferry</div>
                {#if origin}<div class="ld-origin">⚠ the other device must be on <b>{origin}</b> — same origin, or the two land on different relays and never meet</div>{/if}
            {/if}
            <button class="ld-cancel-b" onclick={cancel_link}>cancel</button>
        </div>
    {:else}
        <div class="ld-face">
            <button class="ld-link" onclick={link} disabled={!self}
                title="copy this account to another device as a Cave">🔗 link a device</button>
            {#if link_active}
                <!-- a link is still in flight (a secret survived a reload, or you navigated away mid-mint) —
                     the one honest way out, clearing House state so a fresh mint starts clean. -->
                <div class="ld-pending">a device-link is still pending on this tab
                    <button class="ld-cancel-b" onclick={cancel_link}>cancel it</button></div>
            {/if}
        </div>
    {/if}
    {#if err}<div class="ld-err">{err}</div>{/if}
</div>

<style>
    /* ONE FRAME both ends — the blurb explains the act; the face below is the only thing that differs. */
    .ld-frame {
        display: flex; flex-direction: column; align-items: center; gap: .8rem;
        width: 100%; max-width: 32rem; margin: 0 auto; text-align: center;
    }
    .ld-blurb { font-size: 1rem; line-height: 1.5; margin: 0; }
    .ld-trust {
        background: none; border: none; padding: 0; font: inherit; font-weight: 700; letter-spacing: .3px;
        color: #ffb300; text-decoration: underline dotted; cursor: pointer;
    }
    .ld-trust:hover { color: #ffd166; }
    .ld-warn-note { font-size: .9rem; line-height: 1.5; color: #e8c98a; border-left: 2px solid #d98a00; padding-left: .7rem; margin: 0; text-align: left; }
    .ld-warn-note b { color: #ffb300; }

    /* the ACTION face — a settled panel, generous, flowing (no fragile absolute positioning) */
    .ld-face {
        display: flex; flex-direction: column; align-items: center; gap: .7rem;
        width: 100%; padding: 1.1rem; box-sizing: border-box;
        background: #1a1206; color: #f4e6c8; border-radius: .6rem;
    }
    .ld-deal { font-size: .95rem; line-height: 1.5; margin: 0; max-width: 28rem; }
    .ld-deal b { color: #ffcf70; }
    .ld-row { display: flex; align-items: center; gap: .8rem; margin-top: .2rem; }
    .ld-go { background: #d98a00; color: #000; font-weight: 700; border: none; border-radius: .4rem; padding: .45rem 1rem; cursor: pointer; }
    .ld-go:disabled { opacity: .4; cursor: default; }
    .ld-cancel-b { background: none; border: none; color: inherit; font-size: .85rem; opacity: .8; text-decoration: underline; cursor: pointer; }
    .ld-link { font-size: .95rem; background: #d98a00; color: #000; font-weight: 700; border: none; border-radius: .5rem; padding: .5rem 1rem; cursor: pointer; }
    .ld-link:disabled { opacity: .4; cursor: default; }
    .ld-note { font-size: .95rem; }
    .ld-err { color: #ff6b6b; font-size: .8rem; }
    .ld-cap-big { font-size: 1.05rem; font-weight: 600; }
    .ld-cap-big b { color: #ffcf70; }
    .ld-wait-big { font-size: .85rem; opacity: .7; }
    .ld-origin { font-size: .8rem; line-height: 1.5; color: #e8c98a; background: #0f0a02; border-radius: .4rem; padding: .45rem .7rem; max-width: 26rem; }
    .ld-origin b { color: #ffcf70; }
    .ld-connected { font-size: .9rem; line-height: 1.5; color: #9be89b; background: #0c1a0c; border-radius: .4rem; padding: .5rem .8rem; font-weight: 600; }
    .ld-pending { font-size: .8rem; opacity: .8; display: flex; align-items: center; gap: .5rem; }
</style>
