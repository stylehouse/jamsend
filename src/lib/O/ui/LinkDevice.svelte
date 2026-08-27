<script lang="ts">
    // LinkDevice — the "spread out" front door (Division_todo §CEREMONY).  The DISTINCT, smaller sibling of
    //  InvitePanel's "invite a friend": here you divide YOURSELF across your own devices.  Three faces, one
    //   per role in the ceremony, chosen by the live state — never a mode toggle you can mis-tap:
    //    · OFFER   — this device shows a QR offering ITSELF as a body ("adopt me").  Press it on the device
    //                 you want to add (a desktop) and scan it from your main device.
    //    · LAND    — this page opened from a scanned ?Adopt= URL: the BODILY warning + confirm.  Only the
    //                 device that HOLDS your soul reaches here (it does the sealing).
    //    · CONSENT — an adoption arrived for this device: "become a Cave of <soul>?" — the device decides.
    //  The model underneath (Swarm_adopt_* in Ghost/S/Swarm.g) is proven green by Book SwarmSpread; this is
    //   pure wiring.
    //  ⚠ THE WARNING IS THE POINT: a friend-invite mis-scanned adds a friend; a divide mis-scanned shares
    //   your IDENTITY.  So LAND/CONSENT wear their own alarm colour and name exactly what is shared, and
    //    nothing here reuses the friend flow's welcome.
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

    // ── which face ──────────────────────────────────────────────────────────────────────────────
    function boot_param(k: string): string | null {
        try { return new URL(window.location.href).searchParams.get(k) } catch { return null }
    }
    let adopt_token = $state<string | null>(null)
    $effect(() => { adopt_token = boot_param('Adopt') })   // LAND face when a ?Adopt= is in the URL

    let pending = $state<any>(null)
    $effect(() => {
        H?.version
        const w = world()
        if (w && typeof H?.Swarm_adopt_pending === 'function') { try { pending = H.Swarm_adopt_pending(w) } catch { pending = null } }
    })

    let err = $state('')
    let trust = $state(false)   // "TOTAL TRUST" opens the one warning that matters — the account copies

    // the emoji SAS both devices READ before anything moves — EQUAL rows = one channel, no machine in the
    //  middle (the EmojiConfirm gate).  Computed per face from the same two pubs + nonce, so the two screens
    //   agree; a relay MITM that swapped a pub shows a different row and the humans catch it.
    let sas = $state('')
    $effect(() => {
        void H?.version
        const w = world()
        if (!w) { sas = ''; return }
        if (adopt_token && typeof H?.Swarm_adopt_sas_land === 'function') {
            H.Swarm_adopt_sas_land(w, adopt_token).then((r: string) => { sas = r || '' }).catch(() => { sas = '' })
        } else if (pending && typeof H?.Swarm_adopt_sas_consent === 'function') {
            H.Swarm_adopt_sas_consent(w).then((r: string) => { sas = r || '' }).catch(() => { sas = '' })
        } else { sas = '' }
    })

    // ── OFFER — this device offers itself ─────────────────────────────────────────────────────────
    let url = $state('')
    const qr_size = 180   // the QR sits in the top-left quarter of the beige oblong (a fixed first cut)
    async function offer() {
        err = ''
        try {
            const w = world()
            if (w && typeof H.Swarm_station_up === 'function' && H.Swarm_station_up(w, self)) stood = true
            url = await H.Swarm_adopt_offer_url(w, location.origin + location.pathname)
            if (!url) err = 'no live identity yet — wait a moment and retry'
        } catch (e) { err = String(e) }
    }

    // ── LAND — the soul-holder scanned an offer ────────────────────────────────────────────────────
    //  the ROLE is what the OFFER carries (the device chose it before the QR); we name it, and grant exactly
    //   that.  So the trust is role-specific — "make it my Cave", not a blank "trust this device".
    let land_role = $state('Cave')
    $effect(() => {
        void H?.version
        const w = world()
        if (adopt_token && w && typeof H?.Swarm_adopt_role === 'function') {
            try { land_role = H.Swarm_adopt_role(w, adopt_token) || 'Cave' } catch { land_role = 'Cave' }
        }
    })
    let landing = $state(false)
    let landed = $state('')
    async function make_cave() {
        landing = true; err = ''
        try {
            const r = await H.Swarm_adopt_land(world(), adopt_token)
            if (r === 'ok') {
                landed = 'sealed — waiting for the device to accept (its row must match this one)'
                try { const u = new URL(location.href); u.searchParams.delete('Adopt'); history.replaceState(null, '', u.toString()) } catch {}
            } else if (r === 'unreachable') {
                landed = 'no channel to that device yet — it must handshake with this one first'
            } else if (r === 'forged') {
                landed = 'the offer signature did not verify — a forged or corrupted link'
            } else if (r === 'noself') {
                landed = 'no live identity here yet — wait a moment and retry'
            } else {
                landed = 'could not read that device link'
            }
        } catch (e) { err = String(e) } finally { landing = false }
    }

    // ── CONSENT — this device was offered a role ───────────────────────────────────────────────────
    let consented = $state('')
    async function decide(yes: boolean) {
        err = ''
        try {
            const ident = await H.Swarm_adopt_consent(world(), yes)
            consented = yes ? (ident ? 'you are now a body of that soul' : 'could not join (the seal failed)') : 'declined'
            pending = null
        } catch (e) { err = String(e) }
    }

    const short = (s: string) => (s ? String(s).slice(0, 8) : '')
</script>

<!-- ONE FRAME, BOTH ENDS: the same blurb explains the act on the offering device AND the soul device, so
     the language is unified; only the action row below it differs by which side you're on. -->
<div class="ld-frame">
    <p class="ld-blurb">
        backup to or colonise other devices with your account, requires 
        <button class="ld-trust" onclick={() => trust = !trust}>TOTAL TRUST</button>.
    </p>
    {#if trust}
        <p class="ld-warn-note">
            It <b>copies your account</b> to the other device and then they become a team in music sharing.
            But it's you logged in forever, may sit <b>unencrypted at rest</b>.
        </p>
    {/if}

    {#if adopt_token}
        <div class="ld-face">
            {#if sas}<div class="ld-sas">this row must match the other device:<br /><b>{sas}</b></div>{/if}
            {#if landed}
                <div class="ld-note">{landed}</div>
            {:else}
                <p class="ld-deal">Make another device your <b>{land_role}</b> — it will hold your keys and
                    serve your library <b>as you</b>.</p>
                <div class="ld-row">
                    <button class="ld-go" onclick={make_cave} disabled={landing || !self}>{landing ? '…' : `make it my ${land_role}`}</button>
                    <a class="ld-cancel" href={location.origin + location.pathname}>cancel</a>
                </div>
            {/if}
        </div>
    {:else if pending}
        <div class="ld-face">
            {#if consented}
                <div class="ld-note">{consented}</div>
            {:else}
                <p class="ld-deal"><b>{short(pending.soulpub)}…</b> wants this device to become its
                    <b>{pending.role || 'Cave'}</b> — hold that identity and serve its library.</p>
                {#if sas}<div class="ld-sas">this row must match your main device:<br /><b>{sas}</b></div>{/if}
                <div class="ld-row">
                    <button class="ld-go" onclick={() => decide(true)}>yes, be its {pending.role || 'Cave'}</button>
                    <button class="ld-cancel-b" onclick={() => decide(false)}>no</button>
                </div>
            {/if}
        </div>
    {:else if url}
        <div class="ld-face">
            <div class="ld-cap-big">offer this device as your <b>Cave</b></div>
            <InviteQR {url} size={qr_size} bg="#e7dcbe" bare caption="" />
            <div class="ld-wait-big">scan or paste it from your main device · …waiting</div>
            <button class="ld-cancel-b" onclick={() => url = ''}>cancel</button>
        </div>
    {:else}
        <div class="ld-face">
            <button class="ld-link" onclick={offer} disabled={!self}
                title="add this device to your soul as a Cave">🔗 link this device</button>
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
    .ld-cancel { font-size: .85rem; opacity: .85; color: #f4e6c8; text-decoration: underline; }
    .ld-cancel:hover { opacity: 1; }
    .ld-cancel-b { background: none; border: none; color: inherit; font-size: .85rem; opacity: .8; text-decoration: underline; cursor: pointer; }
    .ld-link { font-size: .95rem; background: #d98a00; color: #000; font-weight: 700; border: none; border-radius: .5rem; padding: .5rem 1rem; cursor: pointer; }
    .ld-link:disabled { opacity: .4; cursor: default; }
    .ld-note { font-size: .95rem; }
    .ld-err { color: #ff6b6b; font-size: .8rem; }
    .ld-sas { font-size: .85rem; background: #0f0a02; border-radius: .4rem; padding: .5rem .7rem; line-height: 1.6; }
    .ld-sas b { font-size: 1.35rem; letter-spacing: .2rem; }
    .ld-cap-big { font-size: 1.05rem; font-weight: 600; }
    .ld-cap-big b { color: #ffcf70; }
    .ld-wait-big { font-size: .85rem; opacity: .7; }
</style>
