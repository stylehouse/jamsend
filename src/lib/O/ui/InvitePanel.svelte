<script lang="ts">
    // InvitePanel — the Invite front door's live face (Swarm_spec §10.1). Two directions in one
    //  chunky panel:
    //   MINT — resolve the machine's LIVE identity (Swarm_live_self: the one signing key Auto's
    //    Clustation_concrete stood up — never a parallel self), mint a single-use invite, show it
    //     as a scannable QR. The inviter stays on this screen; the invite is online-scan (the
    //      handshake needs both present — a photographed QR is dead after its first scan).
    //   LAND — this page was OPENED from a scanned ?Iz= link: verify the blob, show who's
    //    inviting, and offer JOIN — which stands our own station, promotes a %Pier to the
    //     inviter's prepub, and redeems over the REAL relay (Swarm_spec §10.1's frontier rung:
    //      the two BigSoundlands become for each other).
    //  The mint→URL→parse→seal→spent arc is PROVEN by Book SwarmInvite (green, deterministic);
    //   this panel is only the eyes and buttons over those verbs.
    import InviteQR from "$lib/O/ui/micro/InviteQR.svelte"
    import { boot_param } from "$lib/boot"

    let { H }: { H: any } = $props()

    // the live self resolves once the Creduler deposits Swarm.g's verbs AND Auto stands the
    //  identity — both bump H.version, so a $derived off it settles without racing the boot.
    let self = $derived.by(() => {
        void H?.version
        try { return typeof H?.Swarm_live_self === 'function' ? H.Swarm_live_self() : null } catch { return null }
    })

    // ── STATION — being on this page IS being at the door ─────────────────────────────────────
    // Stand the live station (w:Swarm, the prepub-addressed relay socket + the armed swarm frame
    //  kinds) as soon as the self exists: the inviter must be dialable BEFORE anyone scans, and
    //   the landing side reuses the same standup. Swarm_station_up returns null while the
    //    transport ghosts are still depositing, so this retries on version bumps until it takes.
    let stood = $state(false)
    $effect(() => {
        void H?.version
        if (stood || !self || typeof H?.Swarm_station_up !== 'function') return
        const w = H.Swarm_station_world?.()
        if (w && H.Swarm_station_up(w, self)) stood = true
    })

    // ── FRIENDS — the sealed %Piers under the self's page, on both faces ──────────────────────
    let friends = $derived.by(() => {
        void H?.version
        try {
            if (!self || typeof H?.Swarm_peering !== 'function') return []
            return (H.Swarm_peering(self)?.o({ Pier: 1 }) ?? []) as any[]
        } catch { return [] }
    })

    const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
    async function wait_for<T>(fn: () => T | null | undefined, ms: number): Promise<T | null> {
        for (let t = 0; t < ms; t += 200) { const v = fn(); if (v) return v; await sleep(200) }
        return null
    }

    // ── MINT ──────────────────────────────────────────────────────────────────────────────────
    let url = $state('')
    let err = $state('')
    let big = $state(false)          // the full-screen QR face — opens on mint, click-away closes
    // most-of-the-screen, computed at open (a resize mid-showing is rare; re-open recomputes)
    let big_size = $state(320)
    function open_big() {
        big_size = Math.floor(Math.min(window.innerWidth * 0.92, window.innerHeight * 0.8))
        big = true
    }
    async function mint() {
        err = ''
        try {
            // the door must be dialable before anyone scans — force the station standup here too
            //  (idempotent; the $effect usually beat us to it)
            const w = H.Swarm_station_world?.()
            if (w && typeof H.Swarm_station_up === 'function' && H.Swarm_station_up(w, self)) stood = true
            // nonce: random hex live (a Book pins its own); the spend ledger rides the %Peering
            const nonce = Array.from(crypto.getRandomValues(new Uint8Array(6)), b => b.toString(16).padStart(2, '0')).join('')
            url = await H.Swarm_invite_url(null, self, { Music: 1 }, nonce, location.origin + location.pathname)
            open_big()
        } catch (e) { err = String(e) }
    }

    // ── LAND (?Iz= in this page's own URL) ────────────────────────────────────────────────────
    let iz = boot_param('Iz')
    let invite = $state<any>(null)       // the verified claim {to, by, prepub, friendly, ...}
    let iz_err = $state('')
    let joined = $state('')
    $effect(() => {
        void H?.version
        if (!iz || invite || iz_err || typeof H?.Swarm_verify_idzeug !== 'function') return
        H.Swarm_verify_idzeug(iz)
            .then((claim: any) => invite = claim)
            .catch((e: any) => iz_err = 'the invite did not verify — ' + String(e).slice(0, 80))
    })
    // JOIN — the frontier rung, live: our own station up, a %Pier promoted to the inviter's
    //  prepub, the ws open + hello-bound, then the proven redeem. The seal (their pier_accept)
    //   lands asynchronously — watch for the account %Pier so "joined" means SEALED, not just
    //    "hello sent".
    async function join() {
        joined = ''
        const w = H.Swarm_station_world?.()
        if (!w || !H.Swarm_station_up(w, self)) { joined = '⚠ the transport ghosts are still booting — try again in a moment'; return }
        H.Swarm_station_pier(w, self, invite.prepub)
        joined = '… dialing the inviter'
        const port = () => w.o({ transport: 1, type: 'websocket' })[0]?.c?.port
        if (!await wait_for(() => port()?.ws?.readyState === 1 || null, 8000)) {
            joined = '⚠ the relay did not answer — is the dev server reachable from this tab?'
            return
        }
        await sleep(400)   // one beat for the signed hello-bind to land at the relay
        const claim = await H.Swarm_redeem(w, self, iz)
        if (!claim) { joined = '✗ the inviter refused or is unreachable — the rebuff rides the identity'; return }
        joined = '… hello delivered — waiting for the seal'
        const sealed = await wait_for(() => H.Swarm_peering(self)?.o({ Pier: 1, pub: invite.prepub })[0], 8000)
        joined = sealed
            ? '✓ joined — ' + (claim.friendly || claim.prepub) + ' is a music Pier now'
            : '… hello delivered, but no accept yet — is the inviter tab still open?'
    }
</script>

<div class="ip">
    {#if invite || iz_err}
        <!-- the LANDING face: this page was opened from a scanned invite -->
        <div class="ip-land">
            {#if invite}
                <span class="ip-title">📨 an invite from <b>{invite.friendly || invite.prepub}</b> — {invite.to}</span>
                <button class="ip-act" onclick={join}>join</button>
                {#if joined}<span class="ip-note">{joined}</span>{/if}
            {:else}
                <span class="ip-note">{iz_err}</span>
            {/if}
        </div>
    {/if}
    {#if self}
        <div class="ip-mint">
            <span class="ip-title">⨳ <b>{self.sc.nick || self.sc.prepub}</b></span>
            {#if !url}
                <button class="ip-act" onclick={mint} title="mint a single-use Music invite and show its QR">invite a friend</button>
            {:else}
                <InviteQR {url} size={140} caption="" />
                <span class="ip-row">
                    <button class="ip-act" onclick={open_big} title="fill the screen so a phone camera can grab it across the table">fill screen</button>
                    <button class="ip-act" onclick={mint} title="the shown one stays spendable until scanned; this mints a fresh nonce">fresh QR</button>
                </span>
            {/if}
            {#if err}<span class="ip-note">{err}</span>{/if}
        </div>
    {:else}
        <span class="ip-note">⏳ identity…</span>
    {/if}
    {#if friends.length}
        <!-- the sealed friendships — each a %Pier under our page, its Music grant the proof -->
        <div class="ip-friends">
            {#each friends as p (p.sc.pub)}
                <span class="ip-friend" title={p.sc.pub}>⚯ {p.sc.friendly || p.sc.pub}{p.o({ Grant: 'Music' })[0] ? ' · ⇄ Music' : ''}</span>
            {/each}
        </div>
    {/if}
</div>

{#if url && big}
    <!-- the full-screen face: the QR takes most of the viewport, white-on-white multiplied into the
         warm backdrop — the modules stay ink, the quiet zone and cells take the tan (scan-safe: the
         blend only ever DARKENS toward the backdrop, never lightens the ink). Click-away closes. -->
    <div class="ip-overlay" onclick={() => big = false}>
        <div class="ip-big" onclick={(e) => e.stopPropagation()}>
            <InviteQR {url} size={big_size} pad={Math.max(20, Math.floor(big_size / 24))} bg="#ffffff" bare caption="" />
            <span class="ip-big-cap">scan to join — single-use, dies after its first scan</span>
        </div>
    </div>
{/if}

<style>
    .ip {
        display: inline-flex; align-items: flex-start; gap: 0.6rem; flex-wrap: wrap;
        padding: 0.35rem 0.5rem; border-radius: 8px;
        background: #14141c; border: 1px solid #2a2a38; color: #bbc;
        font-size: 0.8rem;
    }
    .ip-mint, .ip-land { display: flex; flex-direction: column; align-items: flex-start; gap: 0.35rem; }
    .ip-title { white-space: nowrap; }
    .ip-act {
        background: #232338; border: 1px solid #44446a; color: #ccd;
        cursor: pointer; font-size: 0.78rem; padding: 0.15rem 0.6rem; border-radius: 5px;
    }
    .ip-act:hover { border-color: #77a; color: #fff; }
    .ip-note { font-size: 0.72rem; color: #889; max-width: 22rem; }
    .ip-row { display: flex; gap: 0.4rem; }
    .ip-friends { display: flex; flex-direction: column; gap: 0.25rem; align-self: center; }
    .ip-friend {
        font-size: 0.75rem; color: #cb9; white-space: nowrap;
        padding: 0.1rem 0.5rem; border: 1px solid #443a2a; border-radius: 5px; background: #1c1812;
    }

    /* ── the full-screen face ── a warm amber-tan radial, lightest where the QR sits */
    .ip-overlay {
        position: fixed; inset: 0; z-index: 60;
        display: flex; align-items: center; justify-content: center;
        background: radial-gradient(circle at 50% 44%, #f3e3bd 0%, #e2bd85 46%, #a8763f 100%);
        cursor: pointer;
    }
    .ip-big { display: flex; flex-direction: column; align-items: center; gap: 0.5rem; cursor: auto; }
    /* the blend: the QR's white becomes the backdrop's tan exactly; its ink stays ink */
    .ip-big :global(img) { mix-blend-mode: multiply; display: block; }
    .ip-big-cap { font-size: 0.85rem; color: #4a300f; letter-spacing: 0.02em; }
</style>
