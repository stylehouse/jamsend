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
    //  ── THE SIBLING ROUTE: THE DISK (owner 2026-08-29, the staging-editor held boot).  The ferry is the RELAY
    //   route to "this device becomes the soul"; the FSA stash is the DISK route to the same end —
    //    `Swarm_boot_seed` reads `.jamsend/account/<prepub>/toc.snap` at boot on a Dexie miss and restores the
    //     key WITHOUT any ceremony (Auto.svelte's disk-seed seam).  Same machine + same .jamsend + different
    //      ORIGIN (a different port, say) is exactly that case: no ferry needed, just the share grant + a boot
    //       as the mirrored prepub.  The ferry is for keys the disk does NOT hold (a genuinely other device).
    //        A future nicety: when a scanned Adopt names a soul whose account dir is ALREADY in this device's
    //         stash, say so and offer the disk restore instead of the full soul-copy.
    import InviteQR from "$lib/O/ui/micro/InviteQR.svelte"
    import Bandwidth from "$lib/O/ui/micro/Bandwidth.svelte"
    import { tick } from "svelte"
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

    // THE 1s HEARTBEAT — a mutex-INDEPENDENT clock on the macrotask queue.  Declared up top because the phase
    //  reads below lean on it: `.c` writes (ferry_confirm/pending/awaiting) never bump H.version, so under a
    //   Repli flood that saturates the belief mutex the ceremony's screen would never re-render off H.version
    //    alone.  Reading now_tick in the phase deriveds surfaces a parked confirm within 1s regardless.  Also
    //     grades the presence dots (its original job — decay "online" live even with no fresh pulse).
    let now_tick = $state(Date.now())
    $effect(() => {
        if (typeof window === 'undefined') return
        const id = setInterval(() => { now_tick = Date.now() }, 1000)
        return () => clearInterval(id)
    })

    let err = $state('')
    let trust = $state(false)   // "TOTAL TRUST" opens the one warning that matters — the account copies

    // the #fc seal secret from THIS page's own address bar (the QR carried it in the fragment, out of band).
    function frag_code(): string {
        try { const h = new URL(location.href).hash; const m = /(?:^#|&)fc=([^&]+)/.exec(h); return m ? decodeURIComponent(m[1]) : '' } catch { return '' }
    }
    // Does this device still carry the #fc code the ferry needs to unseal?  A hand-copied link often loses the
    //  URL fragment; without it the ceremony runs to the very end and only then fails at receive() with a
    //   cryptic error.  Surface it EARLY (a warning + a disabled "receive") so the Linkee's wait isn't wasted.
    let has_code = $derived.by(() => { void H?.version; try { return frag_code() !== '' } catch { return true } })

    // ── RECEIVE — a ferried account is parked, awaiting this device's consent ───────────────────────
    let pending = $state<any>(null)
    $effect(() => {
        H?.version; void now_tick   // ← now_tick: surface even when a Repli flood starves the belief mutex (see confirm)
        const w = world()
        if (w && typeof H?.Swarm_ferry_pending === 'function') { try { pending = H.Swarm_ferry_pending(w) ? H.Swarm_ferry_peek?.(w) ?? {} : null } catch { pending = null } }
    })
    // the arriving soul's id, for the human to eyeball (salt is `<soulpub>:<mypub>`)
    const arriving_soul = () => { try { return String(pending?.frame?.salt || '').split(':')[0] } catch { return '' } }
    // the arriving soul's chosen NAME, if the ferry frame carried it (Swarm_ferry_send) — so the most
    //  consequential screen names the soul ("receiving the soul of Steve"), not a raw pub8.  Display only.
    const arriving_name = () => { try { return String(pending?.frame?.friendly || '') } catch { return '' } }
    // the 3-glyph SAS the human matches against the soul device's Door screen (Swarm_ferry_sas reads the two
    //  pubs off THIS side's parked frame salt; equal rows on both screens ⇒ no relay swapped a pub).  Async →
    //   $state, recomputed whenever a fresh ferry parks.
    let sas = $state('')
    $effect(() => {
        void H?.version
        let active = false
        try { const tc = H?.top_House?.()?.c; active = !!pending || !!tc?.ferry_confirm || !!tc?.ferry_awaiting } catch { active = false }
        if (!active) { sas = ''; return }
        let cancelled = false
        ;(async () => {
            try { const row = await H?.Swarm_ferry_sas?.(); if (!cancelled) sas = String(row || '') }
            catch { if (!cancelled) sas = '' }
        })()
        return () => { cancelled = true }
    })
    let received = $state('')
    // in-flight feedback (owner 2026-08-29: "we need more visual feedback about this, I'm sitting there waiting").
    //  `taking` covers the receiver's unseal+import, `giving` the grantor's seal+ferry (set in do_confirm) — each
    //   turns its button into a live "…doing it now" so the human is never staring at a dead screen mid-transfer.
    let taking = $state(false)
    async function receive(yes: boolean) {
        err = ''
        try {
            if (!yes) { await H.Swarm_ferry_consume(world(), '', false); received = 'declined'; pending = null; return }
            const code = frag_code()
            if (!code) { err = 'no seal code in this link — open the exact QR link from your soul device'; return }
            taking = true
            const soul = await H.Swarm_ferry_consume(world(), code, true)
            received = soul ? 'you are now a body of that soul — it lives on this device too' : 'could not join (wrong code, or the seal failed)'
            pending = null
            if (soul) finalize_url(soul)
        } catch (e) { err = String(e) } finally { taking = false }
    }
    // CEREMONY COMPLETE — the device is now the soul.  Drop the spent ?Iz + #fc we KEPT through the ceremony
    //  (InvitePanel leaves a MyCave link in the bar until here, so a reload mid-adopt resumes from the URL), and
    //   pin ?I=<the NEW soul> so a reload now resumes AS it (eed), never re-triggering the adopt or reverting to
    //    the blank self ("it should be eed when this procedure is complete").
    function finalize_url(soul: any) {
        try {
            if (typeof window === 'undefined' || !window.history?.replaceState) return
            const u = new URL(location.href)
            u.searchParams.delete('Iz'); u.hash = ''
            if (soul?.sc?.prepub) u.searchParams.set('I', String(soul.sc.prepub))
            window.history.replaceState(null, '', u.toString())
        } catch {}
    }

    // ── LINK — the soul device mints the invite+ferry link and shows its QR ─────────────────────────
    let url = $state('')
    const qr_size = 180   // the QR sits in the top-left quarter of the beige oblong (a fixed first cut)
    // `minting` gives the "link a device" button immediate feedback while Swarm_ferry_link runs (it mints an
    //  invite + signs a ferry secret — a crypto beat that made the button feel dead/"unclickable", owner
    //   2026-08-29).  Guard against a double-mint too (a second click mid-await would mint a second link).
    let minting = $state(false)
    async function link() {
        if (minting) return
        err = ''
        minting = true
        const t0 = (typeof performance !== 'undefined') ? performance.now() : 0
        // PAINT THE PRESS FIRST (owner 2026-08-29 "it should have a touchdown effect so we know it happened" +
        //  "why is it slow").  Swarm_station_up is SYNCHRONOUS and setting ferry_secret/url bumps H.version →
        //   a full belly re-commission + Vyto fill_body solve; without a yield here that whole heavy beat runs
        //    BEFORE Svelte paints `minting`, so the button looks dead on press.  One frame's yield lets the
        //     "minting…" spinner (and the :active touchdown) show before we block.  The timing log below then
        //      says WHERE the wall-clock goes — station_up vs the presig mint vs the render that follows.
        await tick()
        if (typeof requestAnimationFrame !== 'undefined') { await new Promise((r) => requestAnimationFrame(() => r(null))) }
        try {
            const w = world()
            const t1 = (typeof performance !== 'undefined') ? performance.now() : 0
            if (w && typeof H.Swarm_station_up === 'function' && H.Swarm_station_up(w, self)) stood = true
            const t2 = (typeof performance !== 'undefined') ? performance.now() : 0
            url = await H.Swarm_ferry_link(w, self, location.origin + location.pathname)
            const t3 = (typeof performance !== 'undefined') ? performance.now() : 0
            console.log(`🔗 link a device — paint+yield ${(t1 - t0).toFixed(0)}ms · station_up ${(t2 - t1).toFixed(0)}ms · ferry_link ${(t3 - t2).toFixed(0)}ms · (render fan-out follows on the version bump)`)
            if (!url) err = 'no live identity yet — wait a moment and retry'
        } catch (e) { err = String(e) } finally { minting = false }
    }

    const short = (s: string) => (s ? String(s).slice(0, 8) : '')
    // (the cross-origin/relay warning that used to sit under the QR was removed 2026-08-28 — owner: "lose
    //  that stuff about relays".  Too much text on the sharing page; a mis-scan fails visibly enough.)
    // (The old `peer_ready` "✓ connected" flash lived here — removed 2026-08-28.  The confirm now lives IN this
    //  cell as its own "giving your soul to X" phase — the QR just swaps to it when the pier seals — so a status
    //   line under the QR was redundant junk.  See Division_todo §0 grantor-consent landing.)
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
        // "no" / cancel = the ONE dismiss now that the ceremony is its own surface: Sounditron_link_close tears
        //  down the ferry (Swarm_ferry_cancel, idempotent) AND drops top.c.link_lobby, so LinkSurface folds at
        //   once — no belly cell to un-focus anymore (owner 2026-08-29: the ceremony was pulled out of the belly).
        try { (H as any)?.Sounditron_link_close?.(world()) } catch (e) { err = String(e) }
        url = ''; pending = null; sent = ''
        try { (H?.ave as any)?.bump_version?.() } catch {}
    }

    // ── GRANTOR CONFIRM ("Linking", soul side) — a device sealed as our Cave, so Swarm_ferry_on_seal parked
    //  top.c.ferry_confirm and held the send.  The QR yields to THIS, alone in the cell; ✓ performs the copy.
    // ⚠ READS now_tick, NOT JUST H.version (owner 2026-08-29, "eed is hanging in the QRcode display still" under a
    //  Repli flood).  on_seal + poke park `ferry_confirm` on top.c — a `.c` write, which by the codebase law NEVER
    //   bumps H.version.  So the flip QR → "giving your soul" rides whatever OTHER bump comes next — and under a
    //    repli storm the belief mutex is saturated, so that bump is queued for seconds and the confirm never
    //     surfaces though it is parked on the wire.  now_tick is a 1s setInterval on the macrotask queue, INDEPENDENT
    //      of the belief mutex, so re-reading top.c off it un-wedges the ceremony within 1s regardless of the flood.
    let confirm = $derived.by(() => { void H?.version; void now_tick; try { return (H?.top_House?.()?.c?.ferry_confirm) ?? null } catch { return null } })
    // ── LINKEE "connecting" — a MyCave link was redeemed and a soul is inbound but hasn't landed yet (the
    //  dead-window fix): top.c.ferry_awaiting is armed at redeem (Swarm_redeem) and cleared when the sealed
    //   account arrives (Swarm_ferry_park → pending takes over) or on cancel.  Fills the blank wait.
    let awaiting = $derived.by(() => { void H?.version; void now_tick; try { return (H?.top_House?.()?.c?.ferry_awaiting) ?? null } catch { return null } })
    let sent = $state('')   // the "Linked" phase on the soul side, set once the account has crossed
    // ── RECEIVE-ACK (task #21): the other device CONSUMED the soul (ferry_got heard) — the honest "✓ received"
    //  that closes the arc, distinct from "sent" (which only means the frame left here).  Set by the hear funnel,
    //   which also retires the spent secret, so the ceremony truly ends when this lights.
    // void now_tick like `confirm` above: ferry_got is a top.c write off the hear funnel (never bumps H.version),
    //  so under a Repli flood eed would stay stuck on "waiting for its received" though the ack has landed.  The
    //   1s heartbeat surfaces the receive-ack regardless of the starved belief loop, closing the arc.
    let got = $derived.by(() => { void H?.version; void now_tick; try { return (H?.top_House?.()?.c?.ferry_got) ?? null } catch { return null } })
    // LINKOR ADVANCE — while the QR is up, keep asking whether a Cave pier has turned up live.  The instant one
    //  has, Swarm_ferry_poke parks ferry_confirm and the ladder swaps QR → "giving your soul" (the `confirm`
    //   phase wins).  Tied to reactivity (H.version bumps the moment the %Pier appears) so it leaves the QR the
    //    moment the Cave is ready — not waiting on the frame pump.  poke only PARKS; the human still confirms.
    $effect(() => {
        void H?.version; void now_tick   // ← now_tick: keep poking on the mutex-independent 1s heartbeat, so a WARM
                                         //    Cave parks the confirm even while a Repli flood has the belief loop queued
        // Poke whenever THIS tab holds a link in flight — while the QR is up (`url`) OR after a reload that
        //  lost `url` but kept the durable secret (Swarm_link_active is true off the stash twin).  poke reads
        //   the twin for its secret and re-parks ferry_confirm from the still-sealed Cave pier, so an eed
        //    refresh snaps straight back to "giving your soul" the instant reactivity ticks — not a blank cell.
        //     (poke self-guards on `ferrying` and needs a secret, so it's a no-op on the Linkee and mid-send.)
        try { if (url || H?.Swarm_link_active?.(world())) H?.Swarm_ferry_poke?.(world()) } catch {}
    })
    let giving = $state(false)
    async function do_confirm() {
        err = ''
        giving = true
        try {
            const ok = await H?.Swarm_ferry_confirm?.(world())
            if (ok) { sent = 'linked'; url = '' }
            else err = 'could not send — the device may have dropped; try again, or cancel'
        } catch (e) { err = String(e) } finally { giving = false }
    }

    // ── PRESENCE — is the OTHER device actually THERE right now? ─────────────────────────────────────
    //  Owner: "an online indicator on the giving your soul to, it's important to know if they're there" /
    //   "offline indicator at both ends".  Copying a soul into thin air is the worst kind of stuck, so
    //    each end reads the OTHER end's pier `heard_at` — the very pulse warmth DoorFace grades — and
    //     shows here/fading/away.  Graded against the shared `now_tick` heartbeat (declared up top) so it DECAYS
    //      live even when no new pulse lands (a derivation off H.version alone would freeze at the last-heard reading).
    // STEADY "I want linkage" ASK — while a soul is inbound this cell re-asks the soul device every 3s so its
    //  grantor-confirm stays parked through any reload on ITS end (owner: "a steady flow of I want Linkage sentiment
    //   from 495 to eed to keep it focused… 3s wire chatter for the Link ceremony").  Ceremony-scoped — this cell is
    //    only mounted while Swarm_link_active — and the ghost throttles to ~3s so the ~5s pulse fallback can't double
    //     it up.  Fires once immediately on mount so the first ask is snappy, then every 3s.  If we lose the other
    //      end we just keep asking (no giveup); the presence dot shows them offline and it re-lands when they return.
    // fire one "I want linkage" ask; force=true bypasses the ghost's ~3s throttle for eager first-contact / re-lock.
    function fire_ask(force: boolean) {
        try { if (H?.top_House?.()?.c?.ferry_awaiting) H?.Swarm_ferry_ask?.(world(), self, force) } catch {}
    }
    $effect(() => {
        if (typeof window === 'undefined') return
        fire_ask(true)                                   // pounce immediately on mount (fresh cell OR a reload)
        const id = setInterval(() => fire_ask(false), 3000)
        return () => clearInterval(id)
    })
    // the %Pier that stands for the OTHER end of whatever link phase we're in.  Linkor: the live MyCave
    //  pier we're about to pour the soul into (the same find the SAS uses).  Linkee: the soul device we
    //   sealed to — matched on the arriving soul's pub, falling back to the sole ceremony pier (mid-adopt
    //    a fresh Linkee holds exactly one).
    function other_pier(): any {
        try {
            const piers = (H?.Swarm_peering?.(self)?.o({ Pier: 1 }) ?? []) as any[]
            if (!piers.length) return null
            const tc = H?.top_House?.()?.c
            if (tc?.ferry_confirm) return piers.find((p: any) => H?.Swarm_pier_live?.(p, 'MyCave')) || null
            const soulpub = String(tc?.ferry_awaiting?.soul || arriving_soul() || '')
            if (soulpub) {
                const hit = piers.find((p: any) => {
                    const pp = String(p?.sc?.pub || '')
                    return pp && (pp === soulpub || pp.startsWith(soulpub) || soulpub.startsWith(pp))
                })
                if (hit) return hit
            }
            return piers[0] || null
        } catch { return null }
    }
    // {rung, ago} — the graded liveness of the other end, or null when there is no pier to read yet.  Same
    //  rungs as DoorFace (here <15s · fading <45s · else away); `heard_at` is warmed by ANY sealed frame
    //   from the peer (the hear funnel stamps it), so an active handshake reads "here" without waiting on a pulse.
    let presence = $derived.by(() => {
        void H?.version; void now_tick
        const p = other_pier()
        if (!p) return null
        const ha = p.c?.heard_at
        if (!ha) return { rung: 'away', ago: null }
        const ago = Math.round((now_tick - ha) / 1000)
        return { rung: ago < 15 ? 'here' : ago < 45 ? 'fading' : 'away', ago }
    })
    // POUNCE THE MOMENT THE OTHER END APPEARS (the "wants-to-happen" feel, owner 2026-08-29): when the soul device
    //  flips to online, fire a FORCED ask at once rather than waiting out the 3s idle — so the link leaps into the
    //   confirm as soon as both devices are present.  Linkee-only in effect (fire_ask no-ops without ferry_awaiting).
    let last_rung = ''
    $effect(() => {
        const r = presence?.rung || ''
        if (r === 'here' && last_rung !== 'here') fire_ask(true)
        last_rung = r
    })
</script>

{#snippet live_dot(pr)}
    {#if pr?.rung === 'here'}
        <span class="ld-live ld-live-here" title="online now — heard a heartbeat within the last few seconds">● online</span>
    {:else if pr?.rung === 'fading'}
        <span class="ld-live ld-live-fade" title="was here a moment ago — its heartbeat is going quiet">◐ fading</span>
    {:else}
        <span class="ld-live ld-live-away" title="not heard — the other device may be offline, asleep, or on another screen">○ offline</span>
    {/if}
{/snippet}

<!-- THE LINK CELL — one cell, one phase at a time, both ends (owner 2026-08-28: *"the Link / Lobby|QR sharing|
     Linking|Linked experience needs nailing"*, *"it's a huge deal copying your account… should be on its own
     in the Link cell. both should be"*).  So each phase OWNS the cell — never a row in a list, never crowded by
     a blurb.  Order = most-urgent first:
       received → the act is done (this device joined, or you declined)
       pending  → RECEIVER, "Linking": a sealed account is here — consent to become it (+ SAS match)
       confirm  → GRANTOR, "Linking": a device sealed as your Cave — confirm the copy (+ SAS match)
       sent     → GRANTOR, "Linked": the account crossed
       url      → GRANTOR, "QR sharing": the QR is up, waiting for the other device
       (else)   → "Lobby": the pitch + the one button.
     Both sides are dragged here by the auto-surface (Swarm_link_active → Sounditron_commission), so this cell
     is where the whole ceremony is seen and decided. -->
<div class="ld-frame">
    {#if received}
        <div class="ld-face">
            <div class="ld-cap-big">{received === 'declined' ? 'declined' : '✓ soul received'}</div>
            <p class="ld-deal">{received === 'declined' ? 'no soul was copied — nothing changed on this device.' : received}</p>
            <button class="ld-cancel-b" onclick={() => received = ''}>done</button>
        </div>
    {:else if pending}
        <!-- LINKEE, "receiving" — the mirror of the Linkor's "giving" (owner: one modality, two symmetric
             sentences).  A whole device becoming a new soul; the SAS is the anti-MITM check. -->
        <div class="ld-face">
            <div class="ld-cap-big">receiving the soul of <b>{arriving_name() || short(arriving_soul()) || 'a device'}</b> {@render live_dot(presence)}</div>
            <p class="ld-deal">this device becomes a <b>Cave</b> of it — holding its keys and serving its library <b>in its name</b>.</p>
            {#if !has_code}
                <p class="ld-warn-note">⚠ this link is missing its seal code — reopen the <b>full</b> QR link from your soul device (a copied link can drop the part after <b>#</b>).</p>
            {:else if sas}
                <p class="ld-sas" title="these three must match the other device's screen — if they differ a relay is in the middle: say no"><b>{sas}</b></p>
            {:else}
                <p class="ld-sas ld-sas-wait">···</p>
            {/if}
            {#if taking}
                <div class="ld-working"><span class="ld-spin"></span> unsealing the account and taking it on…</div>
            {:else}
                <div class="ld-row">
                    <button class="ld-go" onclick={() => receive(true)} disabled={!sas || !has_code}>receive this soul</button>
                    <button class="ld-cancel-b" onclick={() => receive(false)}>no</button>
                </div>
            {/if}
        </div>
    {:else if confirm}
        <!-- LINKOR, "giving" — the mirror of the Linkee's "receiving". -->
        <div class="ld-face">
            <div class="ld-cap-big">giving your soul to <b>{confirm.name || short(confirm.pub)}</b> {@render live_dot(presence)}</div>
            <p class="ld-deal">it becomes a <b>Cave</b> of you — holding your keys and serving your library <b>in your name</b>.</p>
            {#if sas}
                <p class="ld-sas" title="these three must match the other device's screen — if they differ a relay is in the middle: say no"><b>{sas}</b></p>
            {:else}
                <p class="ld-sas ld-sas-wait">···</p>
            {/if}
            {#if giving}
                <!-- REAL activity, not a dead spinner (owner 2026-08-29: "no cues in the UI at all about it
                     starting to come over").  Bandwidth reads the shared wire meter's tx bytes/s, so this JIGGLES with
                     the account actually leaving — and reads "…" only in the brief seal-before-send instant. -->
                <div class="ld-working"><span>sealing & ferrying your soul across…</span></div>
                <Bandwidth {H} dir="tx" label="crossing" />
            {:else}
                <div class="ld-row">
                    <button class="ld-go" onclick={do_confirm} disabled={!sas}>give my soul</button>
                    <button class="ld-cancel-b" onclick={cancel_link}>no</button>
                </div>
            {/if}
        </div>
    {:else if sent || got}
        <!-- "sent" is honest but half the arc ("the frame left here"); `got` is the whole of it — the other
             device consumed the soul (ferry_got, which also retired the spent secret).  One face, upgraded
             live the moment the ack lands.  done clears both (ferry_got is `.c` — never snapped). -->
        <div class="ld-face">
            <div class="ld-cap-big">{got ? '✓ soul received' : '✓ soul given'}</div>
            <p class="ld-deal">{got ? 'your other device took it on — you live there now too.' : 'sent to your other device — waiting for it to take the soul on…'}</p>
            {#if !got}<Bandwidth {H} dir="tx" label="waiting for its “received”" />{/if}
            <button class="ld-cancel-b" onclick={() => { sent = ''; try { const t = H?.top_House?.(); if (t?.c?.ferry_got) delete t.c.ferry_got } catch {} }}>done</button>
        </div>
    {:else if awaiting}
        <!-- LINKEE "connecting" — the link is redeemed and a soul is inbound, waiting on the OTHER device's
             human to confirm the send.  The dead-window fix: fills what used to be a blank Radio + a lone
             "✉ MyCave redeeming" row in the Door with an honest, reassuring wait. -->
        <div class="ld-face">
            <div class="ld-cap-big">receiving from <b>{short(awaiting.soul) || 'your other device'}</b> {@render live_dot(presence)}</div>
            <p class="ld-deal">waiting for it to <b>confirm</b> — the other device decides whether to send its soul here.</p>
            {#if sas}<p class="ld-sas" title="these three must match the other device's screen — if they differ a relay is in the middle: say no"><b>{sas}</b></p>{/if}
            {#if !has_code}<p class="ld-warn-note">⚠ heads up: this link is missing its seal code (the part after <b>#</b>) — reopen the full QR link, or the soul won't unseal here.</p>{/if}
            <!-- THE "IT'S COMING OVER" CUE (owner 2026-08-29: "no cues in the UI at all about it starting to come
                 over").  Bound to the wire's rx bytes: while the other device is still deciding this reads a gentle
                 "…"; the instant the soul starts crossing it jumps to live KB/s + a spark, so the wait never looks
                 frozen and the arrival is SEEN before `pending` swaps this whole face for the receive screen. -->
            <Bandwidth {H} dir="rx" label="listening for the soul" />
            <button class="ld-cancel-b" onclick={cancel_link}>cancel</button>
        </div>
    {:else if url}
        <!-- QR "sharing" — no heading, no "waiting…" line (owner: don't say "link a device as your Cave" or
             "waiting for it to connect"; just leave for the confirm screen when the Cave turns up).  The
             Swarm_ferry_poke effect above swaps this out for "giving your soul" the instant the pier is live.
             Compact + no-scroll: just the QR and a one-line scan hint. -->
        <div class="ld-face ld-face-qr">
            <InviteQR {url} size={qr_size} bg="#e7dcbe" bare caption="" />
            <div class="ld-wait-big">scan this with your other device</div>
            <button class="ld-cancel-b" onclick={cancel_link}>cancel</button>
        </div>
    {:else}
        <p class="ld-blurb">
            backup or colonise other devices, becoming a sloshway of cooperation and
            <button class="ld-trust" onclick={() => trust = !trust}>TOTAL TRUST</button>.
        </p>
        {#if trust}
            <p class="ld-warn-note">
                It <b>copies your account</b> to the other device and then they become a team in music sharing.
                But it's you logged in forever, may sit <b>unencrypted at rest</b>.
            </p>
        {/if}
        <div class="ld-face">
            <button class="ld-link" onclick={link} disabled={!self || minting}
                title="copy this account to another device as a Cave">
                {#if minting}<span class="ld-spin"></span> minting a link…{:else}🔗 link a device{/if}</button>
            {#if link_active}
                <div class="ld-pending">you have a device link in progress
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
    /* THE INTERACTIVE, SCROLLABLE COLUMN (glass_kinds contract).  LinkFace's root stays
       pointer-events:none so its full-bleed rectangular mold cannot shield Door/Radio — but the DEAD
       RIM is what must stay none, not the content.  This centered ≤32rem column re-arms `auto`, so
       scroll, text-selection and every button work inside it, while the transparent margins around it
       (where rim buds live) still let clicks through.  It owns the scroll (LinkFace no longer does), so
       the "link a device as your Cave…" body and its copy button are reachable when the ceremony is
       taller than the cell. */
    .ld-frame {
        pointer-events: auto;
        max-height: 100%; overflow-y: auto; overscroll-behavior: contain;
        /* CENTRE IN THE FILLED BOX (owner 2026-08-28 "the title is way up in the top left, 1/4 of the cell
           space is used", and 2026-08-29 "badly positioned").  Vytui fills the face root for the belly cell,
           but this column had no justify-content, so a SHORT phase (the lobby, the ✓ done screens) pinned to
           the top and left the lower ¾ an empty dead zone.  `safe center` centres when the phase fits and
           falls back to top-align when a TALL phase (a long confirm) overflows — so the scroll never clips
           its top.  `min-height:100%` makes the column actually own the whole filled box so the centring has
           room to act (and clicks land on the frame, not a gap behind it). */
        min-height: 100%;
        justify-content: safe center;
    }
    /* THE QR NEVER SCROLLS (owner: "QRcode thing looks bad when it scrolls, don't let it" — the dark-brown box
       under the heading).  The sharing phase is compact and fixed, so its column centres and hides overflow
       rather than growing a scrollbar across the QR. */
    .ld-frame:has(.ld-face-qr) { overflow: hidden; justify-content: center; }
    .ld-face-qr { gap: .5rem; padding: .8rem; }
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
    .ld-sas { font-size: .95rem; margin: .1rem 0 0; cursor: help; }
    .ld-sas b { font-size: 1.4rem; letter-spacing: 3px; }
    /* the safety code is still computing — a calm placeholder so the row never just vanishes (and the
       confirm button stays disabled until it lands, so you can't approve before you can check). */
    .ld-sas-wait { opacity: .6; font-style: italic; }
    .ld-deal b { color: #ffcf70; }
    /* in-flight feedback (owner: "I'm sitting there waiting") — a live spinner + sentence while the seal/unseal
       and ferry happen, so neither end stares at a dead button mid-transfer. */
    .ld-working { display: flex; align-items: center; gap: .5rem; margin-top: .3rem; font-weight: 600; color: #d98a00; }
    .ld-spin { width: .85rem; height: .85rem; border: 2px solid rgba(217,138,0,.3); border-top-color: #d98a00; border-radius: 50%; display: inline-block; animation: ld-spin 700ms linear infinite; }
    @keyframes ld-spin { to { transform: rotate(360deg); } }
    .ld-row { display: flex; align-items: center; gap: .8rem; margin-top: .2rem; }
    .ld-go { background: #d98a00; color: #000; font-weight: 700; border: none; border-radius: .4rem; padding: .45rem 1rem; cursor: pointer; }
    .ld-go:disabled { opacity: .4; cursor: default; }
    .ld-cancel-b { background: none; border: none; color: inherit; font-size: .85rem; opacity: .8; text-decoration: underline; cursor: pointer; }
    .ld-link { font-size: .95rem; background: #d98a00; color: #000; font-weight: 700; border: none; border-radius: .5rem; padding: .5rem 1rem; cursor: pointer; }
    .ld-link:disabled { opacity: .4; cursor: default; }
    /* TOUCHDOWN (owner 2026-08-29 "should have a touchdown effect so we know it happened").  `:active` is applied
       by the browser IN THE COMPOSITOR on pointer-down — before any JS/reactivity runs — so the press registers
       INSTANTLY even while the main thread is busy re-laying-out the belly.  A tiny depress + brighten; the
       transition makes the release settle smoothly (the start of the "nice and smooth" the owner wants). */
    .ld-link, .ld-go, .ld-cancel-b, .ld-trust { transition: transform .09s ease, filter .09s ease, background-color .12s ease; }
    .ld-link:active:not(:disabled), .ld-go:active:not(:disabled) { transform: scale(.955); filter: brightness(1.12); }
    .ld-cancel-b:active:not(:disabled), .ld-trust:active:not(:disabled) { transform: scale(.955); }
    .ld-note { font-size: .95rem; }
    .ld-err { color: #ff6b6b; font-size: .8rem; }
    .ld-cap-big { font-size: 1.05rem; font-weight: 600; }
    .ld-cap-big b { color: #ffcf70; }
    .ld-wait-big { font-size: .85rem; opacity: .7; }
    .ld-pending { font-size: .8rem; opacity: .8; display: flex; align-items: center; gap: .5rem; }
    /* PRESENCE — is the other device there? (owner: "offline indicator at both ends").  A small pill,
       whitespace-nowrap so it never wraps under the name; here glows, fading dims, away reads plainly grey. */
    .ld-live { font-size: .72rem; font-weight: 600; white-space: nowrap; vertical-align: middle;
               padding: .05rem .35rem; border-radius: .7rem; letter-spacing: .2px; }
    .ld-live-here { color: #093; background: rgba(64, 200, 96, .16); text-shadow: 0 0 6px rgba(64, 220, 96, .5); }
    .ld-live-fade { color: #a70; background: rgba(220, 160, 40, .14); }
    .ld-live-away { color: #977; background: rgba(150, 120, 120, .14); }
</style>
