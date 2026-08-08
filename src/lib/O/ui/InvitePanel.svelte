<script lang="ts">
    // InvitePanel — the Invite front door's live face (Swarm_spec §10.1). Two directions in one
    //  chunky panel:
    //   MINT — resolve the machine's LIVE identity (Swarm_live_self: the one signing key Auto's
    //    Clustation_concrete stood up — never a parallel self), mint a single-use invite, show it
    //     as a scannable QR. The inviter stays on this screen; the invite is online-scan (the
    //      handshake needs both present — a photographed QR is dead after its first scan).
    //   LAND — this page was OPENED from a scanned ?Iz= link: parse the compact token (the
    //    presig only the ISSUER can check — the door proves it, not us), show the offer, and
    //     offer JOIN — which stands our own station, promotes a %Pier to the issuer's prepub,
    //      and redeems over the REAL relay (Swarm_spec §10.1's frontier rung: the two
    //       BigSoundlands become for each other).
    //  The mint→URL→parse→seal→spent arc is PROVEN by Book SwarmInvite (green, deterministic);
    //   this panel is only the eyes and buttons over those verbs.
    //  IN-GLASS (2026-08-09): the same panel is now ALSO the invite half of DoorFace, seated in a
    //   Vyto cell rather than a strip above the page (the owner: fullscreen Vyto, "with Invite
    //    management in there").  `inglass` is a DISPLAY mode, never a second implementation — the
    //     mint→URL→parse→seal→spent arc Book SwarmInvite proves stays one code path.  It (a) drops
    //      the panel's box chrome so the cell wall is the only frame, (b) suppresses the two blocks
    //       DoorFace already carries — the identity title and the friends list — so the cell does not
    //        say everything twice, and (c) PORTALS the fullscreen QR (see `portal` below).
    //  The strip mount stays on the non-glass views on purpose: a scanned ?Iz must be joinable BEFORE
    //   any glass commissions, and the boot-diagnostic page is where that person lands.
    import InviteQR from "$lib/O/ui/micro/InviteQR.svelte"
    import { boot_param } from "$lib/boot"

    let { H, inglass = false }: { H: any, inglass?: boolean } = $props()

    // PORTAL — the fullscreen QR must escape the cell.  `.ip-overlay` is `position: fixed`, and a
    //  fixed element is positioned against the VIEWPORT only while no ancestor carries a transform;
    //   Vyto's molds are seated with translateZ (occlusion order), which makes the nearest
    //    transformed ancestor the containing block instead — so in-glass the "fill screen" QR would
    //     be trapped inside the Door cell, scaled by its --fit, and clipped.  Re-home the node to the
    //      document (or to the fullscreen element, which is the only subtree that paints while
    //       fullscreen is on) and it is viewport-sized again wherever it was declared.
    function portal(el: HTMLElement) {
        const home = () => (document.fullscreenElement ?? document.body) as HTMLElement
        let at: HTMLElement | null = null
        const move = () => { const t = home(); if (t !== at) { at = t; t.appendChild(el) } }
        move()
        document.addEventListener('fullscreenchange', move)
        return {
            destroy() {
                document.removeEventListener('fullscreenchange', move)
                el.remove()
            },
        }
    }

    // the live self resolves once the Creduler deposits Swarm.g's verbs AND Auto stands the
    //  identity — both bump H.version.  LATCHED plain $state, not a $derived (reactivity_docs):
    //   Swarm_live_self() can THROW transiently mid-Atime and return null, and a $derived that
    //    momentarily went null collapsed the {#if self} block, destroying the your-name <input>
    //     and kicking focus out of it as you typed.  Assign ONLY on a truthy, CHANGED ref; never
    //      back to null once set — the identity never un-exists, so the latch is honest.
    let self = $state<any>(null)
    $effect(() => {
        void H?.version
        if (typeof H?.Swarm_live_self !== 'function') return
        let v: any = null
        try { v = H.Swarm_live_self() } catch { v = null }
        if (v && v !== self) self = v
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

    // ── SHARE and the new-seal BOAST have MOVED to SwarmStandup.svelte (2026-08-09).  They are
    //  standup, not display, and this panel is now sometimes a FACE — mounted only while the Door
    //   cell is roomy enough to draw one.  Anything whose absence breaks the wire must not hang off
    //    that.  The station effect above stays here as well because it is idempotent and this
    //     panel's auto-join gate reads `stood` directly.
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

    // ── NAME FIRST — an identity is GENERATED nameless; asking the name is the door's FIRST
    //  move, before a scanned ?Iz gets handled: the hello should carry who you are, and the
    //   inviter should watch a NAMED friend seal — not an anon prepub that renames later.
    //    Persists via Clustation_friendly (thang_put under prepub + role tags).
    // LATCHED like self (same reactivity_docs disease): a rename never un-names, so once a
    //  friendly has been seen the name-ask branch stays closed even if a mid-Atime read can't see
    //   it for a tick.  name_save also sets it directly on success (no wait for the next bump).
    let named = $state(false)
    $effect(() => { void H?.version; if (!named && self?.sc?.friendly) named = true })
    let name_draft = $state('')
    let name_err = $state('')
    async function name_save() {
        name_err = ''
        try {
            const ok = await H?.Clustation_friendly?.(name_draft)
            if (!ok) { name_err = 'not saved — is the identity still standing up? try again'; return }
            named = true
        } catch (e) { name_err = 'not saved — ' + String(e).slice(0, 60) }
    }

    // ── RENAME ANYTIME + SWITCH IDENTITY ─────────────────────────────────────────────────────
    //  A name is not a one-time gate: the ✎ re-opens the editor whenever, persisting the same way
    //   (Clustation_friendly).  The roster shows WHICH self this tab is and the others this machine
    //    holds; a switch is a ?I=<prepub> boot (a fresh fork is ?I=new), so it RELOADS as that Pier
    //     with the address bar carrying it — the way to be two Piers on one machine (presence needs
    //      two distinct pubs; a role-default page shares one identity across every tab).
    let renaming = $state(false)
    function rename_open() { name_draft = self?.sc?.friendly || ''; name_err = ''; renaming = true }
    async function rename_save() { await name_save(); if (!name_err) renaming = false }
    let roster = $derived.by(() => {
        void H?.version
        try { return typeof H?.Clustation_roster === 'function' ? (H.Clustation_roster() as any[]) : [] } catch { return [] }
    })
    function go_identity(tag: string) {
        if (typeof window === 'undefined') return
        const u = new URL(window.location.href)
        u.searchParams.set('I', tag)
        u.searchParams.delete('Iz')     // a deliberate switch drops any stale landing token
        window.location.assign(u.toString())
    }

    // ── LAND (?Iz= in this page's own URL, OR a link pasted below) ────────────────────────────
    //  `iz` is the token we'll redeem — seeded from a scan-landing ?Iz, but the paste-a-link row
    //   (below) can REPLACE it so you accept an invite as the identity you're ALREADY booted as
    //    (the enclosing page's ?I), never a fresh role-default.  `landed_url` remembers we opened
    //     FROM a scan, so only that path auto-joins / hides the paste row.
    const landed_url = !!boot_param('Iz')
    let iz = $state<string>(boot_param('Iz') || '')
    let invite = $state<any>(null)       // the parsed token {prepub, serial, to, params} — the offer's face
    let iz_err = $state('')
    let joined = $state('')
    // the join button has been spent — see join().  Separate from `joined` (the progress LINE) because
    //  a failure writes a line AND wants the button back, so one string cannot say both.
    let join_over = $state(false)
    // …and the keyboard: once the name is in, the ONLY remaining act is join, so put the caret on it
    //  and let Enter finish the door (the human 2026-08-08: "is it focused? so we can hit enter only").
    //   Gated on `named` — while the name row is still up, the typing field owns the focus.  Fires once
    //    (a plain let, deliberately NOT $state: re-running this effect must not re-steal focus).
    let join_btn = $state<HTMLButtonElement | null>(null)
    let join_focused = false
    $effect(() => {
        if (!join_btn || join_focused || !named) return
        join_focused = true
        join_btn.focus()
    })
    $effect(() => {
        void H?.version
        if (!iz || invite || iz_err || typeof H?.Swarm_token_parse !== 'function') return
        const t = H.Swarm_token_parse(iz)
        if (t) invite = t
        else iz_err = 'the invite did not parse — ask for a fresh QR'
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

    // CAN THIS BROWSER SHARE AT ALL? (Onboard_todo §0 item 2, 2026-08-08.)  Sharing means opening a
    //  local music folder, which is the File System Access API — so on Safari or Firefox the whole
    //   MINT half of this panel is a door onto nothing, and until now it said so nowhere.  Someone
    //    lands on BigSoundland in the wrong browser, gets the friendly welcome and an "invite a
    //     friend" button, and only discovers the truth after a friend has scanned their QR.  That is
    //      the worst possible moment to find out, and it wastes the friend's time too.
    //  Read the SAME predicate the sharing layer reads (`Shares.svelte:22` →
    //   `F.P.directory_compat_mode = !('showDirectoryPicker' in window)`) rather than a fresh
    //    sniff, so the panel and the machine can never disagree about what this browser can do.
    //  SET IN AN EFFECT, NOT AT INIT: /BigSoundland server-renders, and `window` on the server would
    //   make the SSR pass and the hydration pass disagree about whether to draw the warning.  An
    //    effect only ever runs client-side, so the first paint simply has no warning and it appears
    //     on hydration — which is also the honest order, since the answer is a client fact.
    let no_fsa = $state(false)
    $effect(() => { no_fsa = typeof window !== 'undefined' && !('showDirectoryPicker' in window) })
    $effect(() => {
        // NAMED gates the auto-join: the newborn tells us who they are first, THEN the door
        //  handles the invite by itself — the one question a brand-new visitor must answer.
        //  Only a SCAN-landing (?Iz in the URL) auto-joins: a pasted link is already a deliberate
        //   act, so it keeps the explicit JOIN button rather than firing under the paster's hands.
        if (!landed_url || !invite || !self || !stood || !born_today || !named || auto_fired || joined) return
        auto_fired = true
        joined = '… joining by itself'
        join()
    })
    // the DOOR BEACON — the glass's DoorFace reads this (runtime .c, never snapped): the same
    //  landing state this panel holds privately, shared so the prioritised face can show it.
    $effect(() => {
        if (H?.c) H.c.door = { iz: !!iz, landed: !!invite, from: invite?.friendly || invite?.prepub || '', note: joined || iz_err || '' }
    })
    // strip_iz — drop the spent-or-complete invite token from the address bar (the human: "the
    //  Invite should be removed from the page location if spent or complete").  A single-use ?Iz
    //   that has been redeemed — successfully OR refused — is DEAD, and a reload that re-presented
    //    it only ever showed "did not verify".  So drop it on every terminal state, not just the
    //     pinned-success path that used to gate it.  Optionally pin the identity onto the bar in the
    //      same replaceState (?I=<prepub>) so the reload resumes as this self, never a role stranger.
    function strip_iz(pin_prepub?: string) {
        if (typeof window === 'undefined' || !window.history?.replaceState) return
        const u = new URL(window.location.href)
        if (!u.searchParams.has('Iz')) return
        u.searchParams.delete('Iz')
        if (pin_prepub) u.searchParams.set('I', pin_prepub)
        window.history.replaceState(null, '', u.toString())
    }
    // a landed ?Iz that will not parse is a DEAD token (malformed, or a single-use blob already
    //  spent on an earlier scan) — clean it out of the bar so a reload starts fresh instead of
    //   re-surfacing the same dead offer.  Only the URL's OWN token (landed_url); a pasted one
    //    lives in the paste row, not the location.
    $effect(() => {
        if (iz_err && landed_url) strip_iz()
    })
    // JOIN — the frontier rung, live: our own station up, a %Pier promoted to the inviter's
    //  prepub, the ws open + hello-bound, then the proven redeem. The seal (their pier_accept)
    //   lands asynchronously — watch for the account %Pier so "joined" means SEALED, not just
    //    "hello sent".
    async function join() {
        joined = ''
        // the button SPENDS ITSELF (2026-08-08, the human: "the Join button doesn't vanish when we hit
        //  it").  A disabled-but-present button reads as "still waiting for me" while the dial is
        //   already in flight, and the listener taps it again.  join_over hides it the instant it
        //    fires — and is put BACK on the failure returns below, because a vanished button with a
        //     ⚠ beside it and no way to retry is worse than the double-tap it was fixing.
        join_over = true
        const w = H.Swarm_station_world?.()
        if (!w || !H.Swarm_station_up(w, self)) { joined = '⚠ the transport ghosts are still booting — try again in a moment'; join_over = false; return }
        H.Swarm_station_pier(w, self, invite.prepub)
        joined = '… dialing the inviter'
        const port = () => w.o({ transport: 1, type: 'websocket' })[0]?.c?.port
        if (!await wait_for(() => port()?.ws?.readyState === 1 || null, 8000)) {
            joined = '⚠ the relay did not answer — is the dev server reachable from this tab?'
            join_over = false
            return
        }
        await sleep(400)   // one beat for the signed hello-bind to land at the relay
        const claim = await H.Swarm_redeem(w, self, iz)
        // SPENT even on refusal: a single-use ?Iz is consumed by the attempt, so drop it either way
        //  — a lingering dead blob only re-fails on reload.
        if (!claim) { strip_iz(); joined = '✗ the inviter refused or is unreachable — the rebuff rides the identity'; return }
        // the ?Iz is SPENT the moment the redeem lands — swap the address bar to ?I=<prepub>
        //  RIGHT HERE, not after the seal-watch: gating the swap on an 8s seal window stranded
        //   ?Iz whenever the seal ran late, and a reload then re-presented a dead blob ("did
        //    not verify").  PIN first (Clustation_pin's why): a role-tagged default self is
        //     stored only under its role, and an unpinned ?I=<prepub> reload would mint a
        //      stranger — the friendship left on the old key.  Pin gates only the ?I= SET; the
        //      ?Iz DROP is unconditional (a spent token must never survive, pinned or not).
        const pinned = self?.sc?.prepub ? await H.Clustation_pin?.() : null
        strip_iz(pinned ? String(self.sc.prepub) : undefined)
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
    }

    // ── PASTE A LINK — accept an invite as the identity you're ALREADY booted as ─────────────────
    //  The invite URL carries a ?Iz the SENDER minted; opening it cold would boot a role-default
    //   self (fine for testing, wrong for a real user who already IS someone here).  Instead paste
    //    the link HERE: we lift its ?Iz onto our live `self` and surface the same landing face +
    //     JOIN.  Accepts a full URL, a `?Iz=…` tail, or a bare token.
    let paste = $state('')
    let paste_err = $state('')
    function iz_from(text: string): string {
        const s = String(text || '').trim()
        if (!s) return ''
        try { const p = new URL(s).searchParams.get('Iz'); if (p) return p } catch {}
        const m = s.match(/[?&]Iz=([^&\s]+)/)
        if (m) return decodeURIComponent(m[1])
        return s   // assume a bare token
    }
    function paste_load() {
        paste_err = ''
        const tok = iz_from(paste)
        if (!tok) { paste_err = 'paste an invite link (or its ?Iz token)'; return }
        const t = H?.Swarm_token_parse?.(tok)
        if (!t) { paste_err = 'that link’s invite did not parse — ask for a fresh one'; return }
        // a NEW pasted invite re-arms the door: without clearing join_over, a second link after a
        //  spent first one lands on a panel with no join button at all.
        iz = tok; invite = t; iz_err = ''; joined = ''; auto_fired = false; join_over = false; join_focused = false
    }
</script>

<!-- Escape closes the big QR face (top-level — svelte:window may not sit inside a block) -->
<svelte:window onkeydown={(e) => { if (big && e.key === 'Escape') big = false }} />

<!-- the name-ask: the first-time move, rendered wherever an unnamed self is about to act -->
{#snippet namer(hint: string)}
    <!-- STEP 1 OF A TWO-STEP DOOR, and it must LOOK like a step (2026-08-08, the human: "the 'that's
         me' → 'join' needs to be much more pronounced for UX, prompting them to click them").  This is
         the one moment a stranger becomes a friend, and both buttons were wearing `.ip-act` — the same
         muted chip as every secondary control in the panel — so the single action the whole page exists
         to invite was visually indistinguishable from "copy link".  `.ip-go` is the accent: bright,
         larger hit area, and a slow breath so the eye lands on it without the page shouting. -->
    <span class="ip-row">
        <input class="ip-name" bind:value={name_draft} placeholder="your name"
            onkeydown={(e) => { if (e.key === 'Enter') name_save() }} />
        <!-- disabled until something is typed: the greyed button is what says "type first", far more
             cheaply than an error message appearing after the click. -->
        <button class="ip-go" class:ip-waiting={!name_draft.trim()}
            disabled={!name_draft.trim()} onclick={name_save}>that's me →</button>
    </span>
    <span class="ip-note">{hint}</span>
    {#if name_err}<span class="ip-note">⚠ {name_err}</span>{/if}
{/snippet}
<div class="ip" class:inglass>
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
                {#if !named}
                    {@render namer(`what do friends call you? ${invite.friendly || 'your friend'} will see this name${born_today ? ' — then you join by yourself' : ''}`)}
                {/if}
                {#if named || !born_today}
                    <!-- STEP 2, the terminal act — the biggest thing on the panel, and it NAMES the
                         person.  "join" alone is a verb with no object; "join Lefto" is the sentence
                         the listener came here to complete.  Suppressed once a join is under way so
                         the button cannot read as still-waiting while it dials. -->
                    {#if !join_over}
                        <button class="ip-go ip-go-join" bind:this={join_btn} onclick={join}>
                            ⨝ join {invite.friendly || invite.prepub}
                        </button>
                        <span class="ip-note">one tap or ⏎ — they will see your name and you will hear their music</span>
                    {/if}
                {/if}
                {#if joined}<span class="ip-note">{joined}</span>{/if}
                <!-- the joiner's version, deliberately QUIETER and placed AFTER the join button: they
                     came here to hear someone else's music, and that half is not what FSA gates.  It
                     would be wrong to put a warning between them and the one act they arrived to do —
                     but wrong too to let them find out only when their own sharing silently never works. -->
                {#if no_fsa}
                    <span class="ip-note ip-warn">⚠ sharing your own music back needs Chrome — this browser can’t open a music folder</span>
                {/if}
            {:else}
                <span class="ip-note">{iz_err}</span>
            {/if}
        </div>
    {/if}
    {#if self}
        <div class="ip-mint">
            <!-- IN-GLASS the identity line is DoorFace's own title (name · prepub · ✎ · ✨), so this
                 one stands down rather than saying it a second time three pixels away. -->
            {#if !inglass}
            <span class="ip-title">
                ⨳ <b>{self.sc.friendly || self.sc.nick || self.sc.prepub}</b>
                <span class="ip-pub" title="your address (prepub) — this is who you are on the wire">{String(self.sc.prepub ?? '').slice(0, 8)}</span>
                {#if !renaming}<button class="ip-pen" onclick={rename_open} title="change your name — friends see this">✎</button>{/if}
            </span>
            {/if}
            {#if renaming}
                <span class="ip-row">
                    <input class="ip-name" bind:value={name_draft} placeholder="your name"
                        onkeydown={(e) => { if (e.key === 'Enter') rename_save(); if (e.key === 'Escape') renaming = false }} />
                    <button class="ip-act" onclick={rename_save} title="save">✓</button>
                    <button class="ip-act" onclick={() => renaming = false} title="cancel">✕</button>
                </span>
                {#if name_err}<span class="ip-note">⚠ {name_err}</span>{/if}
            {/if}
            <!-- SWITCH IDENTITY — which self this tab is, and the others this machine holds.  A
                 switch RELOADS as ?I=<prepub> (fork = ?I=new): the way to run two Piers on one
                 machine, since a role-default page shares one identity across every tab. -->
            <span class="ip-row ip-ids">
                {#each roster.filter(r => !r.active) as r}
                    <button class="ip-idchip" onclick={() => go_identity(r.prepub)}
                        title="switch this tab to be {r.friendly || r.nick} · {r.prepub}">↪ {r.friendly || r.nick}</button>
                {/each}
                <button class="ip-idchip fork" onclick={() => go_identity('new')}
                    title="fork a fresh identity — this tab becomes a brand-new Pier (?I=new)">＋ new identity</button>
            </span>
            {#if !named && !iz}
                {@render namer('what do friends call you? the name rides your invites')}
            {/if}
            <!-- said BEFORE the mint button, never after: the point is to stop someone minting a QR a
                 friend will scan for nothing.  Stated as what is certain (no folder ⇒ no sharing) and
                 NOT as a promise that listening still works — that is a separate claim nobody here has
                 tested on a real Safari, and a welcome screen is the wrong place to guess. -->
            {#if no_fsa}
                <span class="ip-note ip-warn">⚠ this browser can’t open your music folder — to share your own music, open BigSoundland in Chrome</span>
            {/if}
            {#if !url}
                <button class="ip-act" onclick={mint} title="mint a single-use Music invite and show its QR">invite a friend</button>
                <!-- NO `born_today` HERE (dropped 2026-08-08, Onboard_todo §0 item 1).  This note explains
                     what the button DOES, and the moment that explanation is worth having is "you have no
                     friends yet" — which is durable state.  `born_today` is a CLOCK bolted onto that, and
                     it silently withheld the welcome from the person who most needs it: someone who minted
                     an identity yesterday, never got a friend, and came back today.  Dropping it can only
                     widen the note to people with zero friends, which is exactly its audience. -->
                {#if !friends.length && !iz}
                    <span class="ip-note">✨ you are new here — this button makes a QR a friend scans, and their music reaches your radio</span>
                {/if}
            {:else}
                <InviteQR {url} size={140} caption="" />
                <span class="ip-row">
                    <button class="ip-act" onclick={open_big} title="fill the screen so a phone camera can grab it across the table">fill screen</button>
                    <button class="ip-act" onclick={mint} title="the shown one stays spendable until scanned; this mints a fresh nonce">fresh QR</button>
                </span>
            {/if}
            {#if err}<span class="ip-note">{err}</span>{/if}
            <!-- paste-a-link: accept an invite as THIS identity (the enclosing ?I), never a fresh
                 role-default.  Hidden when we OPENED from a scan (the landing face already has it)
                 or an offer is already on screen. -->
            {#if !landed_url && !invite}
                <span class="ip-row">
                    <input class="ip-name" bind:value={paste} placeholder="paste an invite link"
                        onkeydown={(e) => { if (e.key === 'Enter') paste_load() }} />
                    <button class="ip-act" onclick={paste_load} title="accept an invite as this identity — not a fresh one">accept</button>
                </span>
                {#if paste_err}<span class="ip-note">⚠ {paste_err}</span>{/if}
            {/if}
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
    {#if friends.length && !inglass}
        <!-- the sealed friendships — each a %Pier under our page, its Music grant the proof;
             the ♪ count is their last boast (%IveGot), the tally the sum of every counted shelf.
             IN-GLASS this is DoorFace's friends list — which says strictly more (the pulse rung,
              the half-seal warning, suggestions) — so the panel yields it rather than competing. -->
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
    <div class="ip-overlay" use:portal onclick={() => big = false}>
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
    /* IN-GLASS — the cell wall is the frame, so the panel drops its own box entirely and stacks in
       one column (the strip's inline-flex row was a shape for a wide page, not for a cell).  Nothing
        else changes: same controls, same code path, one voice less shouting. */
    .ip.inglass {
        display: flex; flex-direction: column; align-items: flex-start; gap: 0.4rem;
        padding: 0; background: none; border: none; color: inherit;
    }
    .ip.inglass .ip-note { max-width: 15rem; }
    .ip.inglass .ip-name { width: 9rem; }
    .ip-mint, .ip-land { display: flex; flex-direction: column; align-items: flex-start; gap: 0.35rem; }
    .ip-title { white-space: nowrap; }
    .ip-act {
        background: #232338; border: 1px solid #44446a; color: #ccd;
        cursor: pointer; font-size: 0.78rem; padding: 0.15rem 0.6rem; border-radius: 5px;
    }
    .ip-act:hover { border-color: #77a; color: #fff; }

    /* ── the two-step call to action ──────────────────────────────────────────────────────────
       `.ip-go` is deliberately louder than `.ip-act`: filled rather than outlined, a full stop
        larger, and a wide hit area, because on a phone this is a thumb target reached once.  The
         breath animation is slow (2.6s) and low-amplitude — enough to catch the eye on a page the
          user has just landed on cold, not enough to nag while they read.  It is the only moving
           thing in the panel, so it does not compete with itself. */
    .ip-go {
        background: linear-gradient(180deg, #4a4ad2, #3a3aa8);
        border: 1px solid #7b7bff; color: #fff; font-weight: 650;
        cursor: pointer; font-size: 0.9rem; padding: 0.4rem 1rem; border-radius: 7px;
        box-shadow: 0 0 0 0 rgba(123, 123, 255, 0.5);
        animation: ip-breath 2.6s ease-in-out infinite;
    }
    .ip-go:hover { background: linear-gradient(180deg, #5b5bee, #4646bd); border-color: #a5a5ff; }
    /* waiting = nothing typed yet.  Flat, still and unmistakably not-yet-clickable — the greyed
        button teaches the order of operations without a word of instruction. */
    .ip-go.ip-waiting, .ip-go:disabled {
        background: #232338; border-color: #3a3a52; color: #6a6a80;
        cursor: default; animation: none; box-shadow: none;
    }
    /* step 2 outranks step 1: it is the act itself, and by now the user has committed. */
    .ip-go-join {
        font-size: 1rem; padding: 0.5rem 1.2rem;
        background: linear-gradient(180deg, #2ea36a, #1f7d50); border-color: #4fd897;
    }
    .ip-go-join:hover { background: linear-gradient(180deg, #37bd7c, #26905d); border-color: #7ff0b8; }
    /* the join button is FOCUSED on arrival so ⏎ finishes the door — which is only useful if the
        listener can SEE where the key will land.  :focus-visible (not :focus) so a mouse click does
         not leave a ring behind it; the default UA outline is invisible on this gradient. */
    .ip-go:focus-visible {
        outline: 2px solid #eaffef; outline-offset: 3px;
    }
    @keyframes ip-breath {
        0%, 100% { box-shadow: 0 0 0 0 rgba(123, 123, 255, 0.45); }
        50%      { box-shadow: 0 0 0 6px rgba(123, 123, 255, 0); }
    }
    /* a pulsing control is exactly what a motion-sensitive user asked not to be shown; the colour
        and the size already carry the whole message, so drop only the movement. */
    @media (prefers-reduced-motion: reduce) {
        .ip-go { animation: none; }
    }
    .ip-note { font-size: 0.72rem; color: #889; max-width: 22rem; }
    /* the capability warning — warm amber, not alarm red.  Nothing has gone WRONG here and the
       person has done nothing incorrect; they are simply in a browser that cannot do one half of
       this.  Red would read as an error to be fixed on the spot and would sour a welcome screen. */
    .ip-warn { color: #e0a45c; }
    .ip-row { display: flex; gap: 0.4rem; }
    .ip-name {
        background: #1a1a26; border: 1px solid #44446a; color: #dde;
        border-radius: 5px; font-size: 0.78rem; padding: 0.15rem 0.5rem; width: 11rem;
    }
    .ip-name:focus { border-color: #77a; outline: none; }
    .ip-pub { font-size: 0.66rem; color: #778; font-family: monospace; margin-left: 0.35rem; }
    .ip-pen {
        background: none; border: none; color: #889; cursor: pointer;
        font-size: 0.72rem; padding: 0 0.25rem;
    }
    .ip-pen:hover { color: #fff; }
    .ip-ids { flex-wrap: wrap; gap: 0.3rem; }
    .ip-idchip {
        background: #1a1a26; border: 1px solid #383850; color: #99a;
        cursor: pointer; font-size: 0.68rem; padding: 0.1rem 0.45rem; border-radius: 5px;
    }
    .ip-idchip:hover { border-color: #77a; color: #fff; }
    .ip-idchip.fork { border-style: dashed; color: #8a8; }
    .ip-idchip.fork:hover { border-color: #7a7; color: #dfd; }
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
