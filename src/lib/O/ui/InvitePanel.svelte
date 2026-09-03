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
    import { replaceState } from "$app/navigation"   // shallow-router bar rewrite — raw history.replaceState warns

    //  ARRIVAL (2026-08-12) — the THIRD dress, and a display mode for the same reason `inglass` is one
    //   (the owner asked for "a new component just for this purpose"; this file's own rule above says
    //    otherwise, and it is the right rule — a second copy of mint→URL→parse→seal→spent is a second
    //     thing to keep green against Book SwarmInvite).  It is what the Butler mounts while an invite
    //      is being worked through, and it suppresses everything that is ABOUT YOU rather than about
    //       the friend on screen: the identity title, the identity chips + `＋ new identity`, the
    //        `invite a friend` mint, and the friends list.  The owner: *"we shouldn't show them the
    //         `⨳ dawn-kazoo 5a1ff221 ✎` and `+new identity` and `invite a friend` UI stuff there"*.
    //  WHY A PROP AND NOT `{#if invite}` — the panel cannot see the difference on its own.  `invite`
    //   STAYS set after a successful join (only a refusal calls `strip_iz`), so keying off it would
    //    hide the mint for the rest of the tab's life; and the Butler ALSO opens this door for a
    //     friendless person with no token at all, where `invite a friend` is the only thing to do.
    //      The caller knows which of the two it is (`landing_seen`); the panel does not.
    let { H, inglass = false, arrival = false }: { H: any, inglass?: boolean, arrival?: boolean } = $props()

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
    // NAME BEFORE INVITE, AS A JAMMED PROCESS (the owner 2026-08-28: "must have a name to get the
    //  Invite worked on" then "it should be UI process spawning, and jam the Invite before it begins" —
    //   NOT a thrown error, NOT a dead button).  Pressing invite unnamed SPAWNS the invite process and
    //    jams it at its first stage: the namer (already rendered whenever `!named`) becomes step 1 of
    //     the thing you started, and the moment the name lands the process resumes on its own — the QR
    //      appears without a second press.  The name-ask stays loose everywhere else; the invite is the
    //       one act the name exists for (it rides the QR, the friend sees it at the seal), so the rule
    //        is SELF-APPLIED here at the spawn — the ghost mint stays clean and never complains.
    let mint_wanted = $state(false)
    $effect(() => { if (named && mint_wanted) { mint_wanted = false; mint() } })
    async function mint() {
        err = ''
        if (!named && !iz) { mint_wanted = true; return }
        try {
            // the door must be dialable before anyone scans — force the station standup here too
            //  (idempotent; the $effect usually beat us to it)
            const w = H.Swarm_station_world?.()
            if (w && typeof H.Swarm_station_up === 'function' && H.Swarm_station_up(w, self)) stood = true
            // no nonce any more: the %Idzeug IS the issuer and assigns the number (Onboard_todo §0
            //  2026-08-12).  Minting no longer plants a particle per invite — it winds one counter.
            url = await H.Swarm_invite_url(null, self, { Music: 1 }, location.origin + location.pathname)
            open_big()
        } catch (e) { err = String(e) }
    }

    // ── BLOTTER — the printed SHEET, and it is A GRID OF QR CODES AND NOTHING ELSE ────────────
    //  Swarm_spec §6.2's second invite kind, given the face `Swarm_mint_blotter` (Book SwarmBlotter)
    //   has been waiting for since it landed.  Since 2026-08-12 it is a RANGE MINT: printing winds
    //    the issuer's number past 126 and no `%Blotter` — nor any per-serial particle — survives it.
    //     The sheet is a physical object once it leaves here; the app only remembers the numbers.
    //  ⚠ THE LAYOUT IS THE OLD GARDEN'S, VERBATIM — `p2p/ui/ShareButton.svelte` `createComposite()`,
    //   whose numbers (`margin 400`, `PADDING 130`, `OVERLAP_PERCENT -0.18`, the `ceil(sqrt(n·0.77))-1`
    //    grid) were TUNED BY HAND until 126 cells fell exactly onto the page.  They are not a
    //     derivation and there is nothing to improve here: a "cleaner" formula, a header, cut lines,
    //      per-cell captions, a size chooser — all of that was tried on 2026-08-09 and thrown out by
    //       the owner, who had already got this rendering perfectly and did not ask for furniture.
    //        **The sheet draws QR codes on white. Nothing else goes on it.**  126 is THE count.
    //  NOT A CHAIN (§6.3a): a blotter mints plain single-use serials, never `chain:1` — the two
    //   invite kinds part at the mint, and this one stays "works once, back to the origin".
    //  ⚠ AND IT STORES NO GRAY PIXELS (2026-08-09, the owner, with a zoomed capture of the module
    //   edges: *"be ideal if we could not store any gray pixels"*).  A QR is a 1-bit image; every
    //    intermediate gray in it is damage.  qrious is innocent — its canvas renderer fills integer
    //     `fillRect`s, so what it draws is pure.  THREE lossy steps sat downstream of it, and the
    //      prototype had all three too:
    //       1. `svelte-qrcode` returns `toDataURL('image/jpeg')` — a LOSSY encode of a crisp bitmap
    //           before the compositor ever sees it.  So we do not use it here: qrious is driven
    //            directly onto an offscreen canvas per cell.
    //       2. `drawImage` into a FRACTIONAL box (a 175px source into 174.3px) resamples bilinearly,
    //           which is the 2px ramp on every module edge in that capture.  Cells are now drawn
    //            canvas→canvas at an INTEGER size and integer position, i.e. a straight pixel copy.
    //       3. `toBlob('image/jpeg')` re-softens the lot.  It is PNG now — lossless.  (Nobody has
    //           weighed the two files; do not assume which is bigger.)
    //      Rounding the cell to a whole pixel moves the hand-tuned layout by ≤0.3px per cell, which
    //       is why it is allowed; nothing else about the geometry changes.
    const SHEET_N   = 126                  // the count the hand-tuned layout was fitted to
    let sheet_on    = $state(false)        // is the sheet face open
    let sheet_busy  = $state(false)
    let sheet_err   = $state('')
    let sheet_png   = $state<string | null>(null)
    let sheet_era   = 0                    // bumped by every mint AND every close — a plain let, not
                                           //  $state: it gates an in-flight promise, never a render

    // the old garden's numbers, moved not rewritten.  `rows` genuinely is one less than the row count
    //  used to draw (the -1s leave slack); that is part of what makes 126 fit, so it stays.
    function sheet_layout(n: number) {
        const MARGIN = 400, OVERLAP = -0.18, PAD = 130
        const W = 2480 - MARGIN, H4 = 3508 - MARGIN
        const cols = Math.max(1, Math.ceil(Math.sqrt(n * 0.77)) - 1)
        const rows = Math.max(1, Math.ceil(n / cols) - 1)
        const ec = cols * (1 - OVERLAP) + OVERLAP
        const er = rows * (1 - OVERLAP) + OVERLAP
        const qr = Math.min((W - 2 * PAD) / ec, (H4 - 2 * PAD) / er)
        return { W, H4, PAD, cols, qr, gap: qr * OVERLAP }
    }

    // BUSY FROM THE FIRST CLICK, and the face does not change until there is a sheet to show: 126
    //  serials is 126 signatures plus 126 QR generations, which is seconds, and a button that stays
    //   live through that gets pressed again — a second click would mint a whole second sheet's worth
    //    of ledger.  So `sheet_busy` gates the button (and its own re-entry), the button wears a
    //     spinner while it runs, and `sheet_on` only flips once the composite exists.
    async function mint_sheet() {
        if (sheet_busy) return
        sheet_err = ''; sheet_busy = true
        const era = ++sheet_era
        if (sheet_png) { URL.revokeObjectURL(sheet_png); sheet_png = null }
        try {
            const w = H.Swarm_station_world?.()
            if (w && typeof H.Swarm_station_up === 'function' && H.Swarm_station_up(w, self)) stood = true
            // no tag, because THE SHEET DOES NOT SURVIVE ITS OWN PRINTING (the owner 2026-08-12:
            //  *"their Invites wander off into the world. we have no idea they're a group,
            //   ongoingly"*).  Minting winds the issuer's number past 126 and hands back 126 tokens;
            //    two sheets in one session simply take the next 126 numbers, so nothing can collide.
            const base = location.origin + location.pathname
            const izzes = await H.Swarm_mint_blotter(w ?? null, self, { Music: 1 }, SHEET_N)
            // closed mid-mint: drop out rather than leave the button disabled forever (the serials
            //  themselves are minted and remain perfectly good in the ledger).
            if (era !== sheet_era) return
            await compose_sheet((izzes as string[]).map(iz => base + '?Iz=' + encodeURIComponent(iz)), era)
        } catch (e) { sheet_err = String(e) }
        if (era === sheet_era) sheet_busy = false
    }

    async function compose_sheet(urls: string[], era: number) {
        // dynamic import: qrious touches `document`, and /BigSoundland server-renders.
        //  NOTE it is currently only a TRANSITIVE dep (svelte-qrcode → qrious 4.0.2, hoisted), so
        //   this resolves but is undeclared.  Declaring it is one line in package.json + a lockfile
        //    touch, which is not a thing to do casually here (see CLAUDE.md on the shared
        //     node_modules) — flagged rather than done.
        const QRious = (await import('qrious')).default as any
        const L = sheet_layout(urls.length)
        const cell = Math.round(L.qr)          // WHOLE pixels — see the header: this is the fix
        const step = L.qr - L.gap
        const cv = document.createElement('canvas')
        cv.width = L.W; cv.height = L.H4
        const ctx = cv.getContext('2d')
        if (!ctx) { sheet_err = 'this browser gave no 2d canvas'; return }
        ctx.fillStyle = '#ffffff'; ctx.fillRect(0, 0, L.W, L.H4)
        // one reusable canvas: qrious resets and repaints it per value, and we copy it out each time
        const one = document.createElement('canvas')
        for (let i = 0; i < urls.length; i++) {
            // `padding` left unset on purpose so qrious CENTRES the code in its cell (given a padding
            //  it pins to the top-left corner instead).  MEASURED at cell=174: a 41-module code at
            //   4px a module = 164px, leaving 5px (1.25 modules) inside the cell — but the layout's
            //    negative overlap sets the cells 205.7px apart, so adjacent codes are 41.7px ≈ 10
            //     modules of white apart.  Well over the 4 the spec wants, and the reason the cells
            //      can be packed this tight at all.
            new QRious({ element: one, value: urls[i], size: cell, level: 'M',
                         background: '#ffffff', foreground: '#000000' })
            ctx.drawImage(one, Math.round(L.PAD + (i % L.cols) * step),
                               Math.round(L.PAD + Math.floor(i / L.cols) * step))   // 1:1, no resample
            // 126 QRs in one go locks the tab up; yield often enough that the spinner and any
            //  belief-loop timer still get a turn
            if (i % 12 === 11) await new Promise(r => setTimeout(r))
            if (era !== sheet_era) return
        }
        const blob = await new Promise<Blob | null>(r => cv.toBlob(r, 'image/png'))   // LOSSLESS
        if (era !== sheet_era) return
        if (blob) { sheet_png = URL.createObjectURL(blob); sheet_on = true }
        else sheet_err = 'the sheet did not render to an image'
    }

    function sheet_close() {
        sheet_era++
        if (sheet_png) { URL.revokeObjectURL(sheet_png); sheet_png = null }
        sheet_on = false; sheet_err = ''; sheet_busy = false
    }
    // the object URL must not outlive the panel
    $effect(() => () => { if (sheet_png) URL.revokeObjectURL(sheet_png) })

    // ── LAND legacy (#-fragment relic — Swarm_spec §6.2 rung 1) ───────────────────────────────
    //  Parse-only: the old ledger and key live in the old garden's Dexie until the rung-2
    //   migrator, so the door is HONEST — it names the inviter and says the link cannot verify
    //    here yet, rather than dialing into a deny('unknown').
    function legacy_of(href: string) {
        try {
            if (typeof H?.Swarm_legacy_of_url !== 'function') return null
            return H.Swarm_legacy_of_url(href)
        } catch { return null }
    }
    let landed_relic = $derived.by(() => {
        void H?.version
        if (typeof location === 'undefined') return null
        return legacy_of(location.href)
    })
    // …AND ONE THAT WAS PASTED RATHER THAN OPENED (2026-08-12).  The two sources deserve the same
    //  answer and were not getting it: `Swarm_token_parse` refuses an old link, so pasting one said
    //   *"that link's invite did not parse — ask for a fresh one"* — which reads as "you mistyped it"
    //    about a link that is perfectly well formed and was simply minted by the old garden.  The
    //     right report already existed three lines down; it was only ever wired to `location`.
    let paste_relic: any = $state(null)
    let relic = $derived(landed_relic || paste_relic)

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
    // a device link now rides wholly in the ANCHOR (`#Iz=…&fc=…`, 2026-08-30) — read the fragment
    //  beside the query so an anchor-form landing counts as a scan-landing too (old ?Iz links still land).
    const hash_iz = (() => { try { return typeof location !== 'undefined' ? (new URLSearchParams(String(location.hash || '').slice(1)).get('Iz') || '') : '' } catch { return '' } })()
    const landed_url = !!boot_param('Iz') || !!hash_iz
    let iz = $state<string>(boot_param('Iz') || hash_iz || '')
    let invite = $state<any>(null)       // the parsed token {prepub, serial, to, params} — the offer's face
    // ANY My<Post> token is a DEVICE link (Division_todo §0a role-aware helm): MyCave grows a Cave,
    //  MyCaptain resurrects the Captain — both ride the ferry path, never the friend-redeem.  One
    //   predicate over the conferred-Post shape, so a new Post never falls through to auto-join.
    const device_link = (t: any) => { const f = String(t?.to || ''); return f.startsWith('My') && f.length > 2 }
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
        if (t) {
            invite = t
            // the %Invite AUTOVIVIFY (Portability §7): the token the URL carried becomes a
            //  particle with a lifecycle on the station world — the Door and the glass can
            //   show the offer as a thing, not a string. Soft: pre-station, the next parse
            //    pass (H.version rides this effect) retries via Swarm_redeem's own note.
            try { H.Swarm_invite_note?.(H.Swarm_station_world?.(), iz) } catch {}
        }
        else iz_err = 'the invite did not parse — ask for a fresh QR'
    })
    // ── …AND A RELIC BECOMES AN ORDINARY OFFER (rung 2, 2026-08-12) ──────────────────────────────
    //  Until today an old link could only be NAMED.  Now that the old garden's account has been
    //   migrated onto this door — one `%Idzeug:1,to:Music,next:<old high water>` standing for every
    //    link it ever posted — an old serial resolves exactly like a new one, so the honest move is to
    //     stop treating a relic as a special case in the UI at all: render it as the token it is and
    //      let the SAME landing face, the same name-ask, and the same JOIN carry it.
    //  THE ADVICE IS KEPT ASIDE because it is the re-signing domain, and only the raw string will do
    //   — a reconstructed one would differ in key order and re-sign to a different MAC.  It rides the
    //    hello beside the token (Swarm_redeem's 4th argument) and nowhere else.
    //  ARMED EVEN WHEN IT CANNOT WIN: a relic from some OTHER garden parses the same and arms the same,
    //   and its refusal ('not_ours' / 'forged') then reads back through the ordinary join report. That
    //    is better than guessing here — this panel cannot know which gardens the door holds keys for,
    //     and a button that fails with a reason beats a dead end that pre-judges.
    let relic_advice = $state<string>('')
    $effect(() => {
        void H?.version
        if (!relic || invite || iz_err || typeof H?.Swarm_legacy_token !== 'function') return
        const tok = H.Swarm_legacy_token(relic)
        if (!tok) return                      // shapeless relic (no n, a short sign) — the note below still names it
        const t = H.Swarm_token_parse?.(tok)
        if (!t) return
        relic_advice = String(relic.advice || '')
        iz = tok
        invite = { ...t, friendly: relic.friendly }
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
        // Don't re-redeem when a device-link ceremony is already live on this tab (ferry_awaiting rehydrated
        //  from a reload): the soul is inbound and LinkDevice drives it from here, so a second single-use
        //   redeem only fails and (worse) used to nuke the ?Iz.  The FIRST landing has no live ferry yet, so
        //    this never blocks the opening redeem.
        let ceremony_live = false
        try { ceremony_live = !!(H?.Swarm_link_active?.(null)) } catch {}
        // A DEVICE LINK NEVER AUTO-JOINS (owner 2026-08-30): becoming a body of the soul is a consent, and it now
        //  lives in the Link cell's `offer` phase.  The effect below parks that offer and runs the redeem only when
        //   the human accepts there — so a scanned MyCave no longer silently redeems under their hands.
        if (!landed_url || !invite || !self || !stood || !born_today || !named || auto_fired || joined || ceremony_live || device_link(invite)) return
        auto_fired = true
        joined = '… joining by itself'
        join()
    })
    // WHISK TO THE LINK CELL (owner 2026-08-31: naming at the Door "leads to the usual Door … but doesn't
    //  actually whisk me away to [the Link]").  The MyCave card below PROMISED "opening in the Link panel"
    //   but leaned on a ghost-side auto-surface that doesn't fire after the name-gate — so the human sat on
    //    the Door reading a promise.  Make it TRUE: focus the %Link belly cell directly, exactly as the Door's
    //     own "link a device" button does (`Sounditron_link_open`, self-resolving its world).  ONCE, and only
    //      when NAMED (the ferry needs a name first — the whole reason the name-gate runs before this) and the
    //       landing is a MyCave device link.  Idempotent with any auto-surface: both just focus the same cell.
    let whisked = $state(false)
    $effect(() => {
        if (whisked || !invite || !device_link(invite) || !named || !stood) return
        whisked = true
        try { H?.Sounditron_link_open?.() } catch {}
    })
    // (The DEVICE-LINK OFFER BRIDGE that lived here for a few hours on 2026-08-30 is GONE, on the owner's
    //  ruling: "relying on a certain cell being mounted to hear a message is quite the design dissonance."
    //   The `ferry_offer` consent is now parked GHOST-SIDE at Swarm standup off the landed ?Iz URL, and the
    //    Link cell's "understand — continue" runs the redeem itself while it is — by definition — mounted for
    //     the click.  This panel keeps only the friend-invite paths; a MyCave shows the quiet handoff below.)
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
        if (typeof window === 'undefined') return
        const u = new URL(window.location.href)
        // A RELIC LIVES IN THE FRAGMENT (rung 2), and the `?Iz` early-return below used to leave one
        //  in the bar forever: an old link spent on its first visit re-armed on every reload and then
        //   failed 'spent' — precisely the dead-blob loop this function exists to break, and it also
        //    meant a relic join never got its `?I=` pin, so the reload minted a stranger and left the
        //     new friendship on the old key. Only ever clears a fragment we PARSED as a relic; a
        //      plain #anchor belongs to somebody else and stays.
        const had_relic = !!landed_relic && !!u.hash
        // an anchor-form device link (`#Iz=…&fc=…`) lives wholly in the fragment — clear it like the
        //  relic case, but ONLY when the fragment actually parses an Iz; a plain #anchor stays.
        const had_hash_iz = (() => { try { return !!new URLSearchParams(String(u.hash || '').slice(1)).get('Iz') } catch { return false } })()
        if (!u.searchParams.has('Iz') && !had_relic && !had_hash_iz) return
        u.searchParams.delete('Iz')
        if (had_relic || had_hash_iz) u.hash = ''
        if (pin_prepub) u.searchParams.set('I', pin_prepub)
        try { replaceState(u.pathname + u.search + u.hash, {}) } catch {}
    }
    // a landed ?Iz that will not parse is a DEAD token (malformed, or a single-use blob already
    //  spent on an earlier scan) — clean it out of the bar so a reload starts fresh instead of
    //   re-surfacing the same dead offer.  Only the URL's OWN token (landed_url); a pasted one
    //    lives in the paste row, not the location.
    $effect(() => {
        // Never strip a device-link (MyCave) token on a parse hiccup: it must stay in the bar for the
        //  whole adopt (owner: "it needs to stay in the URL").  Only clean out a truly dead FRIEND token.
        if (iz_err && landed_url && !/\*My[A-Z]/.test(String(iz))) strip_iz()
    })
    // JOIN — the frontier rung, live: our own station up, a %Pier promoted to the inviter's
    //  prepub, the ws open + hello-bound, then the proven redeem. The seal (their pier_accept)
    //   lands asynchronously — watch for the account %Pier so "joined" means SEALED, not just
    //    "hello sent".
    async function join() {
        joined = ''
        // NAME-GATE (owner 2026-08-30) — accepting a Grant means the inviter seals a friendship with
        //  YOU, so you must be someone first.  The button is already `named`-gated and the namer is
        //   step 1, but ⏎-on-focus and any stale caller reach here directly; refuse rather than seal
        //    an anon prepub the friend then has to squint at.  The name row stays on screen (it is
        //     rendered whenever `!named`), so this reads as "finish step 1", not a dead end.
        if (!named) { joined = '✎ name yourself first — the name rides your hello and the friend sees it at the seal'; return }
        // A PASTED DEVICE-LINK LANDS, IT DOES NOT FRIEND-REDEEM (2026-08-29, owner: pasting the MyCave invite
        //  "wanted my name input … then I am just back at the Door UI, like it forgot to kick the Link").  The
        //   cause: `iz_from` lifts only the `?Iz` token, dropping the `#fc=` seal fragment the account is sealed
        //    under — so the in-place redeem can never unseal, and the ceremony dead-ends after the name.  A
        //     SCANNED link works only because the whole URL (fragment included) sits in the address bar and
        //      LinkDevice drives `ferry_awaiting` off it.  So route a pasted MyCave to the SAME path: navigate to
        //       the whole pasted URL.  Mirrors the `?Adopt=` branch in paste_load — a deliberate page move, not a
        //        redeem.  A landed ?Iz (landed_url) already has its fragment in the bar and is left untouched.
        if (device_link(invite) && !landed_url) {
            if (paste_full) { try { window.location.href = paste_full; return } catch {} }
            joined = '⚠ paste the WHOLE device link — the seal after the # got left off, so the soul can’t cross'
            return
        }
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
        // `relic_advice` is '' for every modern token, so this call is unchanged for them; for an old
        //  garden link it carries the raw advice the door re-signs to verify (Swarm_legacy_presig).
        const claim = await H.Swarm_redeem(w, self, iz, relic_advice)
        // SPENT even on refusal: a single-use ?Iz is consumed by the attempt, so drop it either way
        //  — a lingering dead blob only re-fails on reload.
        if (!claim) {
            // A device-link (MyCave) landing KEEPS its ?Iz through the entire adopt.  A null claim here is
            //  the RELOAD case — the token was already spent on the first pass and the ferry ceremony is
            //   live again from the rehydrated ferry_awaiting; finalize_url (LinkDevice) owns the bar, not
            //    this.  Stripping now is exactly the "I dropped the Adopt again" regression.  A friend invite
            //     still drops its dead single-use token.
            if (!device_link(invite)) strip_iz()
            joined = device_link(invite)
                ? '… the adopt is already under way on this device — resuming'
                : '✗ the inviter refused or is unreachable — the rebuff rides the identity'
            return
        }
        // the ?Iz is SPENT the moment the redeem lands — swap the address bar to ?I=<prepub>
        //  RIGHT HERE, not after the seal-watch: gating the swap on an 8s seal window stranded
        //   ?Iz whenever the seal ran late, and a reload then re-presented a dead blob ("did
        //    not verify").  PIN first (Clustation_pin's why): a role-tagged default self is
        //     stored only under its role, and an unpinned ?I=<prepub> reload would mint a
        //      stranger — the friendship left on the old key.  Pin gates only the ?I= SET; the
        //      ?Iz DROP is unconditional (a spent token must never survive, pinned or not).
        // KEEP THE DEVICE-LINK URL until the ceremony is COMPLETE (owner 2026-08-29: "keep the initial
        //  ?Iz=…*MyCave*…#fc= url, avoid shortening it to ?I=<self>").  A MyCave redeem is only the FIRST step —
        //   the soul still has to cross and be CONSUMED; pinning ?I=<blank self> now would make a reload forget
        //    the ceremony and resume as the blank device ("it's trying to become eed, which it should be when
        //     this procedure is complete").  So leave the ?Iz=…MyCave…#fc= in the bar — Swarm_ferry_consume
        //      (LinkDevice) drops it and pins the NEW soul once the device has definitely become it.  Friend
        //       (Music) invites strip as before; a REFUSAL above still strips either kind (a dead token must go).
        if (!device_link(invite)) {
            const pinned = self?.sc?.prepub ? await H.Clustation_pin?.() : null
            strip_iz(pinned ? String(self.sc.prepub) : undefined)
        }
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
    // THE RAW PASTED URL, FRAGMENT AND ALL — because `iz_from` reads only `?Iz` and a device-link
    //  (MyCave) carries its seal in the `#fc=` FRAGMENT (Swarm_ferry_link returns `<base>?Iz=…#fc=<secret>`),
    //   which searchParams never sees.  A pasted MyCave link must LAND on the whole URL, not friend-redeem a
    //    seal-less token — so keep the absolute URL here and let `join()` navigate to it.  '' unless the paste
    //     parsed as an absolute URL with a fragment.
    let paste_full = $state('')
    function url_with_frag(text: string): string {
        try { const u = new URL(String(text || '').trim()); return u.hash ? u.toString() : '' } catch { return '' }
    }
    function iz_from(text: string): string {
        const s = String(text || '').trim()
        if (!s) return ''
        try {
            const u = new URL(s)
            const p = u.searchParams.get('Iz'); if (p) return p
            // anchor form (`#Iz=…&fc=…`) — the fragment parses as params
            const h = new URLSearchParams(String(u.hash || '').slice(1)).get('Iz'); if (h) return h
        } catch {}
        const m = s.match(/[?&#]Iz=([^&\s]+)/)
        if (m) return decodeURIComponent(m[1])
        return s   // assume a bare token
    }
    // adopt_from — is this pasted text a LINK-A-DEVICE (?Adopt=) link?  A device-adoption is a different
    //  act from a friend invite (it shares your identity, not a Pier), so pasting one here does NOT redeem
    //   as a friend — it routes to the adoption LAND face (the bodily warning + the live SAS).  Empty if not.
    //  SANITY: a device link is a whole URL the copy button minted (origin + path + ?Adopt=…), so we accept
    //   ONLY a well-formed absolute URL carrying an `Adopt` param — no loose `[?&]Adopt=` regex on arbitrary
    //    text (owner 2026-08-29: "more sanity about URL-formed-s only … we should let that throw").  A non-URL
    //     simply fails `new URL` and is not an adopt link; the throw IS the sanity check.  Silent (returns '')
    //      so the per-keystroke paste_try stays quiet; the LOUD path (paste_load) tells a malformed one apart.
    function adopt_from(text: string): string {
        const s = String(text || '').trim()
        if (!s) return ''
        try { const p = new URL(s).searchParams.get('Adopt'); if (p) return p } catch {}
        return ''
    }
    // looks_adopt — the text is TRYING to be a device link (mentions Adopt=) but adopt_from rejected it (not a
    //  proper URL).  Lets the loud paste_load flag it instead of silently mis-routing it as a friend token.
    function looks_adopt(text: string): boolean {
        return /[?&#]Adopt=/.test(String(text || ''))
    }
    // the QUIET twin of paste_load, run on every keystroke: identical accept path, but it never
    //  writes an error and never clears one the loud path put there.  Silence is the whole contract —
    //   every prefix of a valid link fails to parse, so a chatty version would flash a complaint at
    //    someone who is simply still pasting.  Once a token parses there is nothing left to confirm.
    function paste_try() {
        if (invite) return                      // an offer is already on screen; don't fight it
        if (adopt_from(paste)) return           // a device link — leave it for paste_load to route (?Adopt=)
        const tok = iz_from(paste)
        if (!tok) return
        const t = H?.Swarm_token_parse?.(tok)
        // A RELIC IS NOT A PREFIX, so the quiet twin may act on one.  The silence contract is about
        //  half-typed links — but `Swarm_legacy_of_url` demands a whole shape (16 hex, three
        //   dash-parts, a decodable advice), which no prefix of a modern link can wear by accident.
        if (!t) { const old = legacy_of(paste); if (old) paste_relic = old; return }
        paste_relic = null
        const full = url_with_frag(paste)
        // A COMPLETE DEVICE LINK IS THE ACT — GO there (owner 2026-08-30: pasting a device link "just says
        //  'opening in the Link panel' without going there").  This field's whole contract is "a valid paste
        //   lands the offer instantly"; for a MyCave that means navigating to the WHOLE URL (fragment and all,
        //    which `full` non-empty guarantees), so it re-lands as landed_url → the offer effect arms ferry_offer
        //     → the Link cell asks consent.  A seal-less paste (no #fc → full empty) stays SILENT here — showing
        //      the "opening in the Link panel" note without navigating was the lie; ⏎ (paste_load) explains why.
        if (device_link(t)) {
            if (full) { try { window.location.href = full; return } catch {} }
            return
        }
        iz = tok; invite = t; iz_err = ''; joined = ''; auto_fired = false; join_over = false; join_focused = false
        paste_full = full
    }
    function paste_load() {
        paste_err = ''
        // A LINK-A-DEVICE link routes to the adoption LAND face (?Adopt=), never the friend redeem — it
        //  shares your identity, so it must land on the warned + SAS-checked screen, not seal quietly.
        const ad = adopt_from(paste)
        if (ad) { try { window.location.href = location.origin + location.pathname + '?Adopt=' + encodeURIComponent(ad) } catch { paste_err = 'could not open the device link' }; return }
        // a malformed device link (has Adopt= but isn't a proper URL): flag it rather than mis-routing to friend redeem.
        if (looks_adopt(paste)) { paste_err = 'that device link looks broken — paste the whole URL (it should start with http…)'; return }
        const tok = iz_from(paste)
        if (!tok) { paste_err = 'paste an invite link (or its ?Iz token)'; return }
        const t = H?.Swarm_token_parse?.(tok)
        if (!t) {
            // OLD GARDEN FIRST, then the generic refusal — an old link IS an invite, just not one
            //  this door can honour yet, and telling its holder to "ask for a fresh one" without
            //   naming who sent it or why is the least useful true thing we could say.
            const old = legacy_of(paste)
            if (old) { paste_relic = old; return }
            paste_err = 'that link’s invite did not parse — ask for a fresh one'
            return
        }
        paste_relic = null
        // a NEW pasted invite re-arms the door: without clearing join_over, a second link after a
        //  spent first one lands on a panel with no join button at all.
        iz = tok; invite = t; iz_err = ''; joined = ''; auto_fired = false; join_over = false; join_focused = false
        paste_full = url_with_frag(paste)
        // A PASTED DEVICE LINK LANDS ON ITS WHOLE URL (owner 2026-08-30).  The friend "⨝ join" button — which
        //  used to do this navigate for a MyCave — is gone now that the consent lives in the Link cell; so route
        //   the paste the same way here.  `iz_from` drops the `#fc=` seal, so we MUST reload on the full pasted
        //    URL (fragment and all): landing arms ferry_offer (the effect above) and the Link cell asks consent.
        if (device_link(t)) {
            if (paste_full) { try { window.location.href = paste_full; return } catch {} }
            paste_err = 'paste the WHOLE device link — the seal after the # got left off, so the soul can’t cross'
        }
    }
</script>

<!-- Escape closes the big QR face (top-level — svelte:window may not sit inside a block) -->
<svelte:window onkeydown={(e) => { if (big && e.key === 'Escape') { sheet_close(); big = false } }} />

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
        <!-- the old garden's invite: recognized, named, and — since the migration — redeemable.
             The note only carries what the LANDING FACE below cannot: that this is an old link, so
             nobody is surprised when it works, or when a foreign one doesn't. -->
        <div class="ip-land">
            <span class="ip-title">🕰 an old garden invite — from <b>{relic.friendly}</b></span>
            {#if invite}
                <span class="ip-note">the old garden's key lives on this door now, so this link still works — joining grants {invite.to}, not the old {relic.granted} trust</span>
            {:else}
                <span class="ip-note">it granted the old {relic.granted} trust and this door cannot read its number — ask {relic.friendly} for a fresh QR</span>
            {/if}
        </div>
    {/if}
    {#if invite || iz_err}
        <!-- the LANDING face: this page was opened from a scanned invite -->
        <div class="ip-land">
            {#if invite && device_link(invite)}
                <!-- A DEVICE LINK, not a friend invite (owner 2026-08-30: the "⨝ join eed" was landing "in amongst
                     the Door UI"; "separate that, take us to the Link cell already").  The consent now lives in the
                     Link cell's `offer` phase (LinkDevice, driven by top.c.ferry_offer parked in the effect below);
                     the Door just shows a quiet handoff so nothing about becoming-a-body is decided amid the friends. -->
                <span class="ip-title">🔗 a device link from <b>{invite.friendly || invite.prepub}</b></span>
                <span class="ip-note">{joined || 'opening in the Link panel — you can become them there'}</span>
            {:else if invite}
                <span class="ip-title">📨 an invite from <b>{invite.friendly || invite.prepub}</b> — {invite.to}</span>
                {#if !named}
                    <!-- THE HINT IS ONE SHORT SENTENCE (the owner 2026-08-12: *"just say 'your
                         friends will see this name' under it"*).  What was here read *"what do
                         friends call you? f5da6599b8505881 will see this name — then you join by
                         yourself"* — it asked the question the placeholder already asks, repeated
                         the inviter's raw hex pub back at someone who has no idea what a pub is,
                         and then announced a mechanism (the auto-join) that announces itself
                         perfectly well when it fires.  Three jobs in one line, under a text box.
                         The plural is deliberate: this name outlives THIS invite and every friend
                         after it sees it, so "your friends" is the truer promise than naming the
                         one person who happens to be at the door. -->
                    {@render namer('your friends will see this name')}
                {/if}
                {#if named}
                    <!-- STEP 2, the terminal act — the biggest thing on the panel, and it NAMES the
                         person.  "join" alone is a verb with no object; "join Lefto" is the sentence
                         the listener came here to complete.  Suppressed once a join is under way so
                         the button cannot read as still-waiting while it dials.
                         NAME-GATE, BOTH ENDS (owner 2026-08-30: *"before partaking EITHER end of any
                          Grant-like thing"*).  The mint end already jams on `!named`; the ACCEPT end
                           is here, and it used to admit any NON-newborn identity (`named || !born_today`)
                            — an older nameless self could seal a friendship the inviter would then see
                             as a bare prepub.  Now the door is symmetric: the namer above (rendered
                              while `!named`) is step 1 for everyone, and JOIN only appears once you are
                               named.  The auto-join effect is already `named`-gated, so this only
                                closes the manual button's older-identity loophole. -->
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
            {#if !inglass && !arrival}
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
                 machine, since a role-default page shares one identity across every tab.
                 NOT IN THE GLASS (the owner 2026-08-09: *"it shouldn't list the Identities on this
                  tab or offer '+ new identity', leave that under the hood"*) — identity juggling is
                   a tester's move, not a listener's; the ?I= machinery stays, only this dress hides
                    the chips.  The strip-above-the-glass form keeps them. -->
            {#if !inglass && !arrival}
            <span class="ip-row ip-ids">
                {#each roster.filter(r => !r.active) as r}
                    <button class="ip-idchip" onclick={() => go_identity(r.prepub)}
                        title="switch this tab to be {r.friendly || r.nick} · {r.prepub}">↪ {r.friendly || r.nick}</button>
                {/each}
                <button class="ip-idchip fork" onclick={() => go_identity('new')}
                    title="fork a fresh identity — this tab becomes a brand-new Pier (?I=new)">＋ new identity</button>
            </span>
            {/if}
            {#if !named && !iz}
                <!-- the hint knows when it is step 1 of a spawned invite: the jam names itself -->
                {@render namer(mint_wanted ? 'name yourself — your invite mints the moment you do' : 'what do friends call you? the name rides your invites')}
            {/if}
            <!-- said BEFORE the mint button, never after: the point is to stop someone minting a QR a
                 friend will scan for nothing.  Stated as what is certain (no folder ⇒ no sharing) and
                 NOT as a promise that listening still works — that is a separate claim nobody here has
                 tested on a real Safari, and a welcome screen is the wrong place to guess. -->
            {#if no_fsa}
                <span class="ip-note ip-warn">⚠ this browser can’t open your music folder — to share your own music, open BigSoundland in Chrome</span>
            {/if}
            {#if arrival}
                <!-- ARRIVAL — no mint half at all.  Not "the button is hidden": the whole
                     mint→show→refresh block is out, because on this screen the person's job is to
                     finish joining the friend who invited them.  Offering them a QR of their OWN to
                     hand to someone else, three lines under `⨝ join Lefto`, is a second call to
                     action competing with the one the screen exists for. -->
            {:else if !url}
                <!-- THE MINT IS A CALL TO ACTION, NOT A CHIP (the owner 2026-08-10: *"the Invite…
                     needs to look more like a button"*).  This is the same finding the two-step door
                     already recorded two blocks up — "the single action the whole page exists to
                     invite was visually indistinguishable from `copy link`" — and the fix landed
                     there on `that's me →` and `join X` while the MINT half kept its `.ip-act`.  So
                     this is not a new opinion about styling, it is the existing one finally applied
                     to the button it was written about.  Same `.ip-go` accent, deliberately NOT the
                     join green: green is the terminal act of the landing side, indigo is "start
                     something", and two greens would flatten a distinction the panel is making.
                     IT GOES STILL WHEN IT IS NOT THE ACT (see `.ip-still`), because `.ip-go`'s
                     breath is the panel's only movement and the comment on it is right that it must
                     not compete with itself: while the name row is up, step 1 is the name and the
                     namer's own button is already breathing; once you HAVE friends, minting is a
                     thing you occasionally do rather than the reason you are here.  Both are durable
                     state, not a clock — the same ruling that dropped `born_today` from the note. -->
                <!-- …AND, BESIDE IT, THE ONE LINK OFF THIS PAGE (the owner 2026-08-12: *"we need to
                     link to the github README on the Door… next to the Invite button"*).  It rides
                     HERE and nowhere else on purpose:
                       · not on the `arrival` screen — that person is three lines from `⨝ join Lefto`
                          and a link that navigates away mid-join is the same competing-action
                          mistake the block above already rules out for the mint button itself;
                       · not once a QR is up — that state has its own two buttons and a phone
                          pointed at the screen, and a third control that leaves the page is the
                          worst possible moment for it.
                     So its audience is exactly the friendless door: someone looking at a button
                      whose whole promise is social, with no way to find out what the thing IS.
                     Quiet by construction — `.ip-readme` is a text link, not a `.ip-act`: the mint
                      is the act, and this must not read as a second one. -->
                <span class="ip-row ip-mintrow">
                    <button class="ip-go ip-go-mint" class:ip-still={friends.length > 0 || (!named && !iz)}
                            onclick={mint} title="mint a single-use Music invite and show its QR">invite a friend</button>
                    <a class="ip-readme" href="https://github.com/stylehouse/jamsend#readme"
                       target="_blank" rel="noopener noreferrer"
                       title="what jamsend is, on github">README↗</a>
                </span>
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
                <!-- JUST THE FIELD (the owner 2026-08-11: *"the 'paste an invite link' is just the
                     field, no need for accept?"*).  Right — pasting a link IS the act; a second click
                     to confirm what you just pasted is a step that only exists because the field
                     could not tell whether you were done.  It can: `paste_try` parses on input and
                     acts only when a REAL token appears, so a valid paste lands the offer instantly
                     and a half-typed one says nothing.  ⏎ still runs the loud version, which is what
                     surfaces "that link's invite did not parse" — the one thing a silent field must
                     never do on its own, since every prefix of a good link is a bad link. -->
                <span class="ip-row">
                    <input class="ip-name wide" bind:value={paste} placeholder="paste an invite or device link"
                        oninput={paste_try}
                        onkeydown={(e) => { if (e.key === 'Enter') { e.preventDefault(); paste_load() } }} />
                </span>
                {#if paste_err}<span class="ip-note">⚠ {paste_err}</span>{/if}
            {/if}
            <!-- the door speaks: every failed hello|redeem is a %rebuff on the identity — show the
                 recent ones so a denied scan is a NAMED event here, not silence (hello_unknown
                 was invisible through the whole 2026-07-18 two-tab session) -->
            {#each rebuffs as r}
                <span class="ip-note" title={r.sc.say}>🚪 {r.sc.rebuff}{r.sc.say ? ' — ' + r.sc.say : ''}{r.sc.n ? ' ×' + r.sc.n : ''}</span>
            {/each}
        </div>
    {:else}
        <span class="ip-note">⏳ identity…</span>
    {/if}
    {#if friends.length && !inglass && !arrival}
        <!-- the sealed friendships — each a %Pier under our page, its Music grant the proof;
             the ♪ count is their last boast (%IveGot), the tally the sum of every counted shelf.
             IN-GLASS this is DoorFace's friends list — which says strictly more (the pulse rung,
              the half-seal warning, suggestions) — so the panel yields it rather than competing. -->
        <div class="ip-friends">
            {#if tally && tally.piers > 0}
                <span class="ip-tally">♪ {tally.records} records reachable · {tally.piers} {tally.piers === 1 ? 'shelf' : 'shelves'} counted</span>
            {/if}
            {#each friends as p (p.sc.pub)}
                <span class="ip-friend" title={p.sc.pub}>{p.sc.friendly || p.sc.pub}{p.o({ Grant: 'Music' })[0] ? ' · ⇄ Music' : ''}{ivegot(p) != null ? ' · ♪ ' + ivegot(p) : ''}</span>
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
    <div class="ip-overlay" use:portal onclick={() => { sheet_close(); big = false }}>
        <button class="ip-big-x" onclick={() => { sheet_close(); big = false }} title="close (Esc or click anywhere)">✕</button>
        {#if sheet_on}
            <!-- SHEET mode — a card, so the download link is clickable.  The "any click closes" rule
                 above is for the full-bleed QR (there was nothing but a sliver of margin to escape
                 by); here the backdrop still closes and the card does not. -->
            <div class="ip-sheet" onclick={(e) => e.stopPropagation()}>
                <img class="ip-sheet-img" src={sheet_png} alt="a printable sheet of invite QR codes" />
                <a class="ip-sheet-go" href={sheet_png} download="qr-blotter.png">⬇ download A4 · 210×297mm @ 300dpi</a>
            </div>
        {:else}
            <div class="ip-big">
                <InviteQR {url} size={big_size} pad={Math.max(20, Math.floor(big_size / 24))} bg="#ffffff" bare caption="" />
                <span class="ip-big-cap">scan to join — single-use, dies after its first scan · click anywhere to close</span>
                <!-- the other invite kind (Swarm_spec §6.2): a printable page of one-time tickets.
                     stopPropagation only on this one button — the QR above still closes on any click. -->
                <span class="ip-big-row" onclick={(e) => e.stopPropagation()}>
                    <button class="ip-sheet-chip" disabled={sheet_busy} onclick={mint_sheet}
                        title="mint {SHEET_N} one-time invites as one printable A4 page">
                        {#if sheet_busy}<span class="ip-spin" aria-label="minting"></span>{:else}blotter{/if}
                    </button>
                </span>
                {#if sheet_err}<span class="ip-big-cap">⚠ {sheet_err}</span>{/if}
            </div>
        {/if}
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
    /* THE LANDING HEADLINE IS THE BIGGEST THING ON THE PANEL (the owner 2026-08-12: *"this entire
       thing should be bigger font size"*).  It had been sharing `.ip-title` with the identity line —
       a chip that names which self this tab is — and those two are not the same weight at all: one
       is furniture, the other is the single sentence explaining why this screen exists.  Only the
       landing face is scaled, so the mint side's `⨳ name · pub · ✎` stays the quiet chip it should be.
       `nowrap` is dropped here: an inviter with a long name (or a raw 16-hex pub, which is the common
       case until they name themselves) must wrap rather than push the card wide. */
    .ip-land > .ip-title {
        font-size: 1.35rem; font-weight: 600; line-height: 1.25;
        white-space: normal; margin-bottom: 0.1rem;
    }
    /* in the glass the panel is a narrow column beside the music, not a fullscreen welcome — the
       same sentence, sized for the room it is standing in (matching `.ip.inglass .ip-note`). */
    .ip.inglass .ip-land > .ip-title { font-size: 1.05rem; }
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
    /* the MINT — the primary act of the inviting half, sized between step 1 and step 2: bigger than
        a chip so it reads as the thing to press, smaller than `join` because nobody has committed to
         anything yet.  Keeps `.ip-go`'s indigo (see the markup for why it is not the join green). */
    .ip-go-mint { font-size: 0.95rem; padding: 0.45rem 1.1rem; }
    /* STILL, but still a button — the loudness is the size and the fill, and only the MOVEMENT is
        conditional.  Dropping the animation is not a downgrade to `.ip-act`: a person with friends
         must still be able to find the invite instantly, they just should not be nagged toward it. */
    .ip-still { animation: none; box-shadow: none; }
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
    /* the mint row: the button sets the height, the link sits on its centre line rather than
       stretching to it — a full-height link would read as a second button. */
    .ip-mintrow { align-items: center; gap: 0.7rem; flex-wrap: wrap; }
    /* deliberately the QUIETEST thing in the block — dimmer than `.ip-note`'s siblings are loud,
       underlined only on hover, so it is findable by someone looking for it and invisible to
       someone getting on with the invite. */
    .ip-readme {
        color: #7a7aa8; font-size: 0.75rem; text-decoration: none;
        border-bottom: 1px dotted #4a4a6a; padding-bottom: 1px; white-space: nowrap;
    }
    .ip-readme:hover { color: #aeaee6; border-bottom-color: #7a7aa8; }
    .ip-readme:focus-visible { outline: 2px solid #6a6aff; outline-offset: 2px; border-radius: 2px; }
    .ip-name {
        background: #1a1a26; border: 1px solid #44446a; color: #dde;
        border-radius: 5px; font-size: 0.78rem; padding: 0.15rem 0.5rem; width: 11rem;
    }
    .ip-name:focus { border-color: #77a; outline: none; }
    /* the paste field has no button beside it any more, so it takes the whole row */
    .ip-name.wide { width: 100%; min-width: 11rem; }
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
    .ip-big-row { display: flex; align-items: center; gap: 0.4rem; flex-wrap: wrap; justify-content: center; cursor: default; }

    /* ── the blotter sheet ── a paper-white card on the same warm overlay: what you are looking at
       IS a page, so it should read as one rather than as more app chrome. */
    .ip-sheet {
        display: flex; flex-direction: column; align-items: center; gap: 0.5rem;
        max-width: min(92vw, 46rem); max-height: 88vh; cursor: default;
    }
    .ip-sheet-img {
        max-width: 100%; max-height: 62vh; width: auto;
        background: #fff; border: 1px solid #b99; box-shadow: 0 8px 26px rgba(60,30,0,0.28);
        /* the preview is a heavy downscale of a 1-bit page; let it drop pixels rather than blur
           them, so what you see on screen is the same kind of image as the one you download */
        image-rendering: pixelated;
    }
    /* the spinner — a `transform` animation on purpose: minting 126 serials is a burst of signing
       work on the main thread, and rotation is one of the few things a browser can keep animating
       off it.  A spinner that freezes exactly when the work starts is worse than none. */
    .ip-spin {
        display: inline-block; width: 0.85em; height: 0.85em; vertical-align: -0.1em;
        border: 2px solid rgba(74,48,15,0.3); border-top-color: #4a300f; border-radius: 50%;
        animation: ip-spin 0.7s linear infinite;
    }
    @keyframes ip-spin { to { transform: rotate(360deg); } }
    @media (prefers-reduced-motion: reduce) {
        .ip-spin { animation-duration: 2.4s; }
    }
    .ip-sheet-go {
        background: #4a300f; color: #f3e3bd; text-decoration: none;
        padding: 0.5rem 1rem; border-radius: 6px; font-size: 0.9rem;
    }
    .ip-sheet-go:hover { background: #2d1c06; }
    .ip-sheet-chip {
        background: rgba(255,255,255,0.5); border: 1px solid #a8763f; color: #4a300f;
        cursor: pointer; font-size: 0.78rem; padding: 0.15rem 0.6rem; border-radius: 5px;
        /* fixed width so swapping the label for the spinner does not make the button jump */
        min-width: 4.6rem; min-height: 1.55rem;
    }
    .ip-sheet-chip:hover:not(:disabled) { background: #fff; }
    .ip-sheet-chip:disabled { opacity: 0.45; cursor: default; }
</style>
