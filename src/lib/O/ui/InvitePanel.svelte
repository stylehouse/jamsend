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

    // ── REBUFFS — the door's recent denials, legible (%rebuff under the identity) ─────────────
    let rebuffs = $derived.by(() => {
        void H?.version
        try { return self ? ((self.o({ rebuff: 1 }) ?? []) as any[]).slice(-3) : [] } catch { return [] }
    })

    // ── FRIENDS — the sealed %Piers under the self's page, on both faces ──────────────────────
    let friends = $derived.by(() => {
        void H?.version
        try {
            if (!self || typeof H?.Swarm_peering !== 'function') return []
            return (H.Swarm_peering(self)?.o({ Pier: 1 }) ?? []) as any[]
        } catch { return [] }
    })

    // ── IVE GOT — the reachable-music tally (Radio_todo §9.1c): my shelf plus every sealed
    //  friend's last boast, the facts riding as %IveGot under each %Pier. World-scoped census —
    //   the station world holds no %Library yet (the real /music census is §9.1's build), so live
    //    this counts the friends' boasts; Book SwarmGot proves the whole loop with real shelves.
    let tally = $derived.by(() => {
        void H?.version
        try {
            if (!self || typeof H?.Swarm_ive_got_tally !== 'function') return null
            const w = H.Swarm_station_world?.()
            return w ? H.Swarm_ive_got_tally(w, self) : null
        } catch { return null }
    })
    const ivegot = (p: any) => p.o({ IveGot: 1, by: 'records' })[0]?.sc?.count
    // boast on every NEW seal (both faces run this — the joiner's seal lands async after join,
    //  the inviter's inside Swarm_hello). Zeros send too: an empty shelf is an honest boast, and
    //   it proves the live wire today. Growth-only, so a hearing (version bump) never re-boasts.
    // gossiped is a MONOTONIC high-water: a mid-Atime read can catch transacting state and
    //  flicker friends 1→0→1 — resetting the mark on shrink turned every flicker into a fresh
    //   boast (the 2026-07-18 ive_got storm, seq 300+).  Never lower it.
    let gossiped = 0
    $effect(() => {
        const n = friends.length
        if (n <= gossiped) return
        gossiped = n
        try {
            const w = H.Swarm_station_world?.()
            if (w && typeof H?.Swarm_gossip_music === 'function') H.Swarm_gossip_music(w, self)
        } catch {}
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

    // ── LAND legacy (#-fragment relic — Swarm_spec §6.2 rung 1) ───────────────────────────────
    //  Parse-only: the old ledger and key live in the old garden's Dexie until the rung-2
    //   migrator, so the door is HONEST — it names the inviter and says the link cannot verify
    //    here yet, rather than dialing into a deny('unknown').
    let relic = $derived.by(() => {
        void H?.version
        try {
            if (typeof location === 'undefined' || typeof H?.Swarm_legacy_of_url !== 'function') return null
            return H.Swarm_legacy_of_url(location.href)
        } catch { return null }
    })

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
    // AUTO-JOIN — a self BORN TODAY landing on a scanned invite joins by itself: the scan was
    //  the intent, and a brand-new visitor has no reason to hesitate at a button.  An older
    //   identity keeps the deliberate JOIN (maybe they don't want this friendship on this key).
    //    Gated on `stood` so the station is up before the dial; fires ONCE.
    let auto_fired = $state(false)
    let born_today = $derived.by(() => {
        void H?.version
        return !!self?.sc?.born && self.sc.born === new Date().toISOString().slice(0, 10)
    })
    $effect(() => {
        if (!invite || !self || !stood || !born_today || auto_fired || joined) return
        auto_fired = true
        joined = '… a self born today — joining by itself'
        join()
    })
    // the DOOR BEACON — the glass's DoorFace reads this (runtime .c, never snapped): the same
    //  landing state this panel holds privately, shared so the prioritised face can show it.
    $effect(() => {
        if (H?.c) H.c.door = { iz: !!iz, landed: !!invite, from: invite?.friendly || invite?.prepub || '', note: joined || iz_err || '' }
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
        // no seal — the inviter's pier_reject (heard by the station) rides the identity as a
        //  %rebuff,rejected_<why>; naming the why beats "is the tab still open?" every time.
        const denied = (self.o({ rebuff: 1 }) as any[]).filter(r => String(r.sc.rebuff).startsWith('rejected_')).at(-1)
        joined = sealed
            ? '✓ joined — ' + (claim.friendly || claim.prepub) + ' is a music Pier now'
            : denied
                ? '✗ the inviter denied the invite: ' + String(denied.sc.rebuff).slice(9) + ' — ask for a fresh QR'
                : '… hello delivered, but no accept yet — is the inviter tab still open?'
        // the ?Iz is CLAIMED — the address bar becomes this tab's identity (?I=<prepub>): a
        //  reload now RESUMES the sealed self instead of re-presenting a spent invite blob
        //   (which would only say "did not verify").  Same replaceState move as ?I=new's —
        //   but PIN first: a role-tagged default self is stored only under its role, and an
        //    unpinned ?I=<prepub> reload would mint a stranger (Clustation_pin's why).
        if (sealed && self?.sc?.prepub && typeof window !== 'undefined' && window.history?.replaceState) {
            const pinned = await H.Clustation_pin?.()
            if (pinned) {
                const url = new URL(window.location.href)
                url.searchParams.delete('Iz')
                url.searchParams.set('I', String(self.sc.prepub))
                window.history.replaceState(null, '', url.toString())
            }
        }
    }
</script>

<!-- Escape closes the big QR face (top-level — svelte:window may not sit inside a block) -->
<svelte:window onkeydown={(e) => { if (big && e.key === 'Escape') big = false }} />
<div class="ip">
    {#if relic}
        <!-- the old garden's invite: recognized, named, and honestly un-honourable (rung 1) -->
        <div class="ip-land">
            <span class="ip-title">🕰 an old garden invite — from <b>{relic.friendly}</b></span>
            <span class="ip-note">it granted the old {relic.granted} trust and its key has not moved into this door yet — ask {relic.friendly} for a fresh QR</span>
        </div>
    {/if}
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
            <!-- the door speaks: every failed hello|redeem is a %rebuff on the identity — show the
                 recent ones so a denied scan is a NAMED event here, not silence (hello_unknown
                 was invisible through the whole 2026-07-18 two-tab session) -->
            {#each rebuffs as r}
                <span class="ip-note" title={r.sc.say}>🚪 {r.sc.rebuff}{r.sc.say ? ' — ' + r.sc.say : ''}</span>
            {/each}
        </div>
    {:else}
        <span class="ip-note">⏳ identity…</span>
    {/if}
    {#if friends.length}
        <!-- the sealed friendships — each a %Pier under our page, its Music grant the proof;
             the ♪ count is their last boast (%IveGot), the tally the sum of every counted shelf -->
        <div class="ip-friends">
            {#if tally && tally.piers > 0}
                <span class="ip-tally">♪ {tally.records} records reachable · {tally.piers} {tally.piers === 1 ? 'shelf' : 'shelves'} counted</span>
            {/if}
            {#each friends as p (p.sc.pub)}
                <span class="ip-friend" title={p.sc.pub}>⚯ {p.sc.friendly || p.sc.pub}{p.o({ Grant: 'Music' })[0] ? ' · ⇄ Music' : ''}{ivegot(p) != null ? ' · ♪ ' + ivegot(p) : ''}</span>
            {/each}
        </div>
    {/if}
</div>

{#if url && big}
    <!-- the full-screen face: the QR takes most of the viewport, white-on-white multiplied into the
         warm backdrop — the modules stay ink, the quiet zone and cells take the tan (scan-safe: the
         blend only ever DARKENS toward the backdrop, never lightens the ink).  ANY click closes —
         the QR fills the screen, so a stopPropagation on it left only a sliver of escapable margin
         ("too hard to get out of", the human) — plus the ✕ and Escape (the svelte:window rides
         the template top, as it must). -->
    <div class="ip-overlay" onclick={() => big = false}>
        <button class="ip-big-x" onclick={() => big = false} title="close (Esc or click anywhere)">✕</button>
        <div class="ip-big">
            <InviteQR {url} size={big_size} pad={Math.max(20, Math.floor(big_size / 24))} bg="#ffffff" bare caption="" />
            <span class="ip-big-cap">scan to join — single-use, dies after its first scan · click anywhere to close</span>
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
    .ip-tally { font-size: 0.75rem; color: #9c8; white-space: nowrap; }

    /* ── the full-screen face ── a warm amber-tan radial, lightest where the QR sits */
    .ip-overlay {
        position: fixed; inset: 0; z-index: 60;
        display: flex; align-items: center; justify-content: center;
        background: radial-gradient(circle at 50% 44%, #f3e3bd 0%, #e2bd85 46%, #a8763f 100%);
        cursor: pointer;
    }
    .ip-big { display: flex; flex-direction: column; align-items: center; gap: 0.5rem; cursor: pointer; }
    /* the way out, unmissable: fat tap target riding the top-right of the overlay */
    .ip-big-x {
        position: absolute; top: 14px; right: 18px; z-index: 61;
        font-size: 28px; line-height: 1; padding: 10px 14px;
        background: rgba(0,0,0,0.18); color: #fff; border: none; border-radius: 10px; cursor: pointer;
    }
    .ip-big-x:hover { background: rgba(0,0,0,0.34); }
    /* the blend: the QR's white becomes the backdrop's tan exactly; its ink stays ink */
    .ip-big :global(img) { mix-blend-mode: multiply; display: block; }
    .ip-big-cap { font-size: 0.85rem; color: #4a300f; letter-spacing: 0.02em; }
</style>
