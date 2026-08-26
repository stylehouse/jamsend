<script lang="ts">
    import { lifewatch } from './micro/lifetell'   // DIAGNOSTIC — strip with the rest of the remount probes
    import InvitePanel from './InvitePanel.svelte'
    import InviteYourself from './InviteYourself.svelte'
    // DoorFace — WHO AM I and WHO'S WITH ME, floating in the glass: the identity + front-door
    //  arc as the prioritised, for-the-user's-eyes face (the human's ?Iz ask, 2026-07-19).
    //   Mounted by Cytui on the %Door particle (glass_kinds.ts).  Everything here reads LIVE
    //    House state — the particle is only the cell anchor:
    //     · the self: Swarm_live_self (nick · prepub8 · born, with a ✨ badge on born-today)
    //     · the door: H.c.door — InvitePanel's landing beacon (a scanned ?Iz verifying,
    //        auto-joining, sealed) — runtime .c, never snapped
    //     · the friends: sealed %Piers with their Music grant, records boast, and the pulse
    //        liveness dot (pier.c.heard_at — green within 12s, dim beyond: a reloaded tab
    //         goes dim HERE, in the other client's glass)
    let { n, H } = $props()

    // DIAGNOSTIC (2026-08-04, the KeepFace remount hunt — strip with the rest of the probes): the
    //  second CONTROL rung, a face whose source particle the DOWNLOAD never touches.  If Door's
    //   serial climbs too, nothing about the churn is Repli-data-driven — it's the glass rebuilding.
    lifewatch(H, 'face:Door', () => 'door')

    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 1000)
        return () => clearInterval(iv)
    })

    let face = $derived.by(() => {
        void H?.version
        void tick
        let self: any = null
        try { self = typeof H?.Swarm_live_self === 'function' ? H.Swarm_live_self() : null } catch { self = null }
        const today = new Date().toISOString().slice(0, 10)
        const door = (H?.c?.door ?? {}) as any
        let friends: any[] = []
        try {
            if (self && typeof H?.Swarm_peering === 'function') {
                const rw = (H as any)?.c?.radio_w
                const playing = !!rw?.o?.({ Radio: 1 })?.[0]?.c?.rec
                friends = ((H.Swarm_peering(self)?.o({ Pier: 1 }) ?? []) as any[]).map((p: any) => {
                    // the latest suggestion FROM them (by === their pub), with its mirror rec
                    //  resolved by enid against their crate when the share already carried it —
                    //   resolvable means ▶ plays it right here.
                    const sug = (p.o({ Suggest: 1 }) as any[]).filter(s => s.sc.by === String(p.sc.pub)).at(-1)
                    let sug_rec: any = null
                    if (sug && rw) {
                        try {
                            const shelf = rw.o({ MusuThem: 1, pub: String(p.sc.pub) })[0]?.o({ stock: 1 })?.[0]
                            sug_rec = ((H as any)?.Ra_rec_find
                                ? (H as any).Ra_rec_find(shelf, { Record: 1, id: String(sug.sc.id) })
                                : shelf?.o({ Record: 1, id: String(sug.sc.id) })?.[0]) ?? null
                        } catch { sug_rec = null }
                    }
                    // presence in three honest rungs off heard_at (their pulse heartbeat, ~5s):
                    //  here (<15s ≈ 2 missed pulses) · fading (<45s) · away.  The old 12s window
                    //   flickered on one dropped pulse — "doesn't seem reliable", the human.
                    const ago = p.c?.heard_at ? Math.round((Date.now() - p.c.heard_at) / 1000) : null
                    const rung = ago == null ? 'away' : ago < 15 ? 'here' : ago < 45 ? 'fading' : 'away'
                    // SEAL COMPLETENESS — the half-seal, made visible (Radio_todo §0.9, 2026-08-06).
                    //  A whole %Pier holds BOTH grants: one signed by them, one signed by me.  Hold
                    //   only one and the link SILENTLY half-works — asks leave, answers die on the
                    //    doorstep ("🛰☠ deliver: no Pier"), and both ends read as merely SLOW.  That
                    //     cost a live evening, and `runner_ask world` could see it in one line while
                    //      the glass could not.  So the glass says it too: "sealing — 1 of 2".
                    //  Matched by PREFIX because `by` rides as a prepub here and a full pub elsewhere
                    //   (the grant mint form-matches whichever the beacon carried) — a prefix compare
                    //    is true for both and cannot false-positive across two different keys.
                    const my_pre = String(self?.sc?.prepub ?? '')
                    const their_pre = String(p.sc.pub ?? '')
                    const grants = (p.o({ Grant: 1 }) as any[])
                    const has = (who: string) => !!who && grants.some(g => {
                        const by = String(g.sc.by ?? '')
                        return by.startsWith(who) || who.startsWith(by)
                    })
                    const mine_ok = has(my_pre), theirs_ok = has(their_pre)
                    const seal = (mine_ok && theirs_ok) ? 2 : (mine_ok || theirs_ok) ? 1 : 0
                    return {
                        seal,
                        seal_missing: seal === 1 ? (mine_ok ? 'they never granted back' : 'we never granted back') : null,
                        pub: String(p.sc.pub),
                        name: String(p.sc.friendly || String(p.sc.pub).slice(0, 8)),
                        music: !!p.o({ Grant: 'Music' })[0],
                        records: p.o({ IveGot: 1, by: 'records' })[0]?.sc?.count,
                        rung,
                        ago,
                        sug: sug ? { title: sug.sc.title || sug.sc.id, note: sug.sc.note } : null,
                        sug_rec,
                        can_suggest: playing && !!p.o({ Grant: 'Music' })[0],
                    }
                })
            }
        } catch { friends = [] }
        // SORTED BY TIME LAST CONNECTED (the owner 2026-08-10: *"the Pier list should be sorted by
        //  time last connected"*).  `ago` is seconds since their last pulse (`pier.c.heard_at`), so
        //   ascending `ago` IS most-recent-first.  A pier that has never been heard has `ago: null`
        //    — it sorts LAST rather than first, which is the whole point of the ordering: the top of
        //     the list should be who is actually around.  Ties keep their walk order, which is
        //      stable, so a quiet list does not shuffle under the reader between ticks.
        friends.sort((a, b) => (a.ago == null ? Infinity : a.ago) - (b.ago == null ? Infinity : b.ago))
        // MY OWN TIME-ALIVE, folded in beside the peers (the human's §0.9 trim, 2026-08-06: "move
        //  the time-alive/uptime readout INTO the list of Piers — it is networky, it belongs beside
        //   the peers rather than owning a cell").  It reads the SAME `.c.since` the retired
        //    UptimeFace read, off the %Uptime row in the radio world; `.c` so it resets on reload,
        //     which is exactly the point — a near-zero reading right after a reload is the "did my
        //      reload land?" tell, and it now sits next to the friends' own here/fading/away rungs
        //       so the whole liveness picture is ONE reading instead of two cells.
        let up: { label: string, fresh: boolean } | null = null
        try {
            const since = +((H as any)?.c?.radio_w?.o?.({ Uptime: 1 })?.[0]?.c?.since ?? 0)
            if (since) {
                const secs = Math.max(0, Math.round((Date.now() - since) / 1000))
                const h = Math.floor(secs / 3600), m = Math.floor((secs % 3600) / 60), s = secs % 60
                up = { label: h ? `${h}h ${m}m` : (m ? `${m}m ${s < 10 ? '0' : ''}${s}s` : `${s}s`), fresh: secs < 10 }
            }
        } catch { up = null }
        return {
            name: (self?.sc?.friendly || self?.sc?.nick) as string | undefined,
            named: !!self?.sc?.friendly,
            prepub: self?.sc?.prepub ? String(self.sc.prepub).slice(0, 8) : undefined,
            born: self?.sc?.born as string | undefined,
            newborn: !!self?.sc?.born && self.sc.born === today,
            // 🎧 LISTENING-ONLY (MobilenoFSA_todo §0 #3): this browser can't open a folder, so it's a
            //  radio terminal — and its identity is mortal (Dexie only) until Linked Devices travels
            //   it.  Read live off H.c.listen_only (set in Housing's boot-role branch); the badge is
            //    the one honest place that whisper lives.
            listen_only: !!(H as any)?.c?.listen_only,
            door,
            friends,
            up,
        }
    })

    // ── THE PERSISTENCE ACK (Persistence_todo §5.3) — "an Invite should not be half-done and get
    //  lost": one glyph that says whether everything settled is actually ON DISK.  Reads the health
    //   card (Swarm_persist_diag), re-derived on the 1s tick so "settling…" resolves before your
    //    eyes.  Null (no glyph at all) when there's nothing to say: no identity yet, or a borrowed
    //     body that doesn't own the write (mirror_muted — the bare-name holder answers for disk).
    let settle = $derived.by(() => {
        void tick
        try {
            const d = (H as any)?.Swarm_persist_diag?.()
            if (!d) return null
            // the contested name outranks everything — it is the one state where "settled ✓" would
            //  be a lie twice over (two writers, either one clobbering the other).  §7.4h: DoorFace
            //   is the ruled surface for this warning, and resolution stays the human's.
            if (d.stolen) return { state: 'stolen' as const, why: d.settle_why }
            if (d.mirror_muted) return null
            if (d.mirror_owed) return { state: 'owed' as const, why: d.settle_why }
            if (d.settle_owed || d.stash_saving) return { state: 'settling' as const, why: d.settle_why }
            const at = Math.max(+d.mirror_at || 0, +d.stash_durable_at || 0)
            if (at) return { state: 'settled' as const, at, why: d.settle_why }
            return null
        } catch { return null }
    })

    // ── THE BODIES LINE (Portability_todo §9) — which bodies of this soul stand where.  Three
    //  sources, all live and all soft: the cohort card (`top_House().c.cohort` — the boot census's
    //   one consumer contract: {primary, vessel, taken, lockless, at}; absent = no cohort ran,
    //    which is every Book and any API-less browser), the session address (`Swarm_address` —
    //     bare <prepub> or a <prepub>_N suffix after a Steal Back / non-primary standup), and the
    //      %Sibling roster on the identity's %Peering (cooperative co-holders — family, the thing
    //       that keeps the 👥 alarm honest).  Null when there is NOTHING to say (no cohort, no
    //        siblings, bare address) — a single body at its bare name is the unremarkable default
    //         and the Door should not spend a line saying so.
    let bodies = $derived.by(() => {
        void H?.version
        void tick
        try {
            const ident = typeof H?.Swarm_live_self === 'function' ? H.Swarm_live_self() : null
            if (!ident) return null
            const coh = (H?.top_House?.()?.c?.cohort ?? null) as any
            const bare = String(ident.sc?.prepub ?? '')
            const addr = String(H?.Swarm_address?.(ident) ?? bare)
            const suffix = addr !== bare && addr.startsWith(bare + '_') ? addr.slice(bare.length) : ''
            const sibs = ((H?.Swarm_peering?.(ident)?.o({ Sibling: 1 }) ?? []) as any[]).map((s: any) => ({
                place: String(s.sc?.Sibling ?? ''),
                address: s.sc?.address ? String(s.sc.address) : '',
                role: s.sc?.role ? String(s.sc.role) : '',
            }))
            if (!coh && !sibs.length && !suffix && addr === bare) return null
            return {
                bare,
                addr,
                suffix,
                primary: coh ? !!coh.primary : null,   // null = no cohort census in this tab
                lockless: !!coh?.lockless,
                vessel: coh?.vessel ? String(coh.vessel) : '',
                sibs,
            }
        } catch { return null }
    })
    // an address, shortened for a tag: bare reads as the prepub8, a suffixed body as …_N —
    //  the suffix is the news, the prepub is already on the title line.
    function short_addr(a: string, bare: string) {
        if (!a) return ''
        if (a === bare) return a.slice(0, 8)
        if (bare && a.startsWith(bare + '_')) return '…' + a.slice(bare.length)
        return a.slice(0, 8)
    }

    // ── THE %Invite ROWS (Portability_todo §7/§9) — a landed invite is a visible THING.  The
    //  vivified %Invite particles live on the station world (Swarm_invite_note homes them there:
    //   export-blind, Book-blind), sc {Invite:<serial>, prepub, to, n, state}, state walking
    //    arrived → redeeming → (sealed|refused land later).  Read with a PURE o()[0] walk, never
    //     `Swarm_station_world()` — that verb is an oai and a probe on a 1s tick must not MINT the
    //      world it is asking about (the Swarm_probe_station ruling: "a probe that collects").
    let invites = $derived.by(() => {
        void H?.version
        void tick
        try {
            const A = H?.top_House?.()?.o?.({ A: 'Clustation' })?.[0]
            const w = A?.o?.({ w: 'Swarm' })?.[0]
            return ((w?.o?.({ Invite: 1 }) ?? []) as any[]).map((inv: any) => ({
                serial: String(inv.sc?.Invite ?? ''),
                prepub: inv.sc?.prepub ? String(inv.sc.prepub).slice(0, 8) : '',
                to: inv.sc?.to ? String(inv.sc.to) : '',
                n: inv.sc?.n ? String(inv.sc.n) : '',
                state: String(inv.sc?.state ?? 'arrived'),
            }))
        } catch { return [] }
    })

    // ── NAME YOURSELF — the first-time move: the chosen name (friendly) is what invites carry
    //  and what friends see; the auto-nick is only a stand-in.  Persists via Clustation_friendly.
    let naming = $state(false)
    let name_draft = $state('')
    let name_err = $state('')
    function name_open() {
        name_draft = face.named && face.name ? face.name : ''
        name_err = ''
        naming = true
    }
    async function name_save() {
        // the save can REFUSE (identity mid-standup) or THROW (persistence hiccup) — both must
        //  say so here, not strand an open box: the silent-reject was exactly the never-closing
        //   name box of 2026-07-19.
        name_err = ''
        try {
            const ok = await (H as any)?.Clustation_friendly?.(name_draft)
            if (ok) naming = false
            else name_err = 'not saved — try again in a moment'
        } catch (e) { name_err = 'not saved — ' + String(e).slice(0, 50) }
    }

    // ── SUGGEST — "you'd love this": send the PLAYING track to a friend, async to their being
    //  online (Swarm_suggest stashes + re-offers until their suggest_got).  ▶ on an arrived
    //   suggestion tunes the mirror record the share already carried over.
    function suggest(pub: string) {
        try {
            const w = (H as any)?.Swarm_station_world?.()
            const self = (H as any)?.Swarm_live_self?.()
            const rec = (H as any)?.c?.radio_w?.o?.({ Radio: 1 })?.[0]?.c?.rec
            if (w && self && rec) (H as any)?.Swarm_suggest?.(w, self, pub, rec, null)
        } catch {}
    }
    function tune_sug(rec: any) {
        try {
            const rw = (H as any)?.c?.radio_w
            const radio = rw?.o?.({ Radio: 1 })?.[0]
            if (radio && rec) (H as any)?.Radio_tune?.(radio, rec)
        } catch {}
    }

    // ── INVITE MANAGEMENT, IN THE GLASS (2026-08-09, the owner: fullscreen Vyto "with Invite
    //  management in there").  This cell was already WHO AM I and WHO'S WITH ME; the one missing
    //   verb was HOW ANYONE ELSE GETS HERE, and it was parked in a strip above the page — so the
    //    glass could never be the whole app.  InvitePanel comes in whole, in its `inglass` dress:
    //     one implementation, the one Book SwarmInvite proves, not a second copy of the arc.
    //  ALWAYS OPEN (2026-08-11 — this said "FOLDED BY DEFAULT", on the argument that cells are the
    //   scarce resource and the QR only matters in the minute you are inviting someone).  The
    //    scarcity is real and the conclusion was still wrong: the fold hid the cell's own reason for
    //     existing behind a control, and the room it saved was room this cell did not need saving.
    //      Drawing the panel grows the face, which grows the cell's measured need, and the sizing
    //       machinery gives it the space — which is the same mechanism the fold was leaning on,
    //        just without a click in front of it.
    // ── THE POSE (2026-08-10, the owner: *"there are cell positions|poses: Stretched (when Heist is
    //  forming), Big, Small.  Small has only name, maybe the door icon, that's nice"*).  The
    //   commissioner stamps `.c.pose` on the source particle — `big` for the belly, `small` for a
    //    bud — and the face decides how much of itself to draw.  Read live (H.version + the 1s tick
    //     already drive this component), defaulting to `big` so any glass that does not pose its
    //      cells gets exactly today's face.
    let pose = $derived.by(() => { void H?.version; void tick; return String(n?.c?.pose ?? 'big') })
    let small = $derived(pose === 'small')
    // THE INVITE PANEL'S OPEN STATE IS GONE (2026-08-11) — `c.inviting`, `invite_set()` and the
    //  auto-open latch all went with the fold.  Worth its headstone because the flag was carefully
    //   built: it lived on the PARTICLE rather than in component `$state` precisely so the model
    //    could put the panel away (`Sounditron.g`'s `onunmain`) when the Door stopped being the
    //     subject and came back as a bud with its QR still unfolded.  That problem is now solved one
    //      level up — a bud renders the `small` branch and never reaches the panel at all — so the
    //       mechanism has nothing left to protect.
    //  ⚠ `Sounditron.g:278` still deletes `s.c.inviting` in that `onunmain`; it is now a write to a
    //   key nobody reads. Harmless, but it should go on the next compile of that ghost.
    // the pier-list cap ("yay many") — five rows before the +N more toggle takes over.
    const PIERS_SHOWN = 5
    let piers_all = $state(false)
</script>

<!-- SMALL IS THE WHOLE FACE, not a folded version of it (*"Small has only name, maybe the door icon,
     that's nice"*).  One early return rather than `{#if !small}` sprinkled down the body: a bud must
     not merely LOOK quiet, it must not mount the friends walk, the QR panel or the 1s work at all —
     and a single branch is the only way to be sure of that by reading it. -->
{#if small}
    <div class="df df-small" title="the front door — press to open it">🚪</div>
{:else}
<div class="df">
    <div class="df-title">🚪 {face.name ?? 'standing you up…'}
        {#if face.prepub && !naming}
            <button class="df-edit" onclick={name_open} title="name yourself — friends see this">✎</button>
        {/if}
        {#if face.prepub}<span class="df-pub">{face.prepub}</span>{/if}
        {#if face.newborn}<span class="df-born">✨ born today</span>{/if}
        {#if face.listen_only}<span class="df-listen"
            title="listening only — this browser can't open a music folder, so you're a radio terminal. Your identity lives only in this browser: clearing site data forgets you (linked devices will fix that).">🎧 listening only</span>{/if}
        {#if settle?.state === 'stolen'}<span class="df-settle stolen"
            title="another live body of your identity is on the wire — two writers means either can clobber the other's ledger. This body keeps writing; close the other one (or Steal Back to a new address here).">👥 two of you</span>
        {:else if settle?.state === 'settled'}<span class="df-settle ok"
            title={`your ledger is on disk — last confirmed ${new Date(settle.at).toLocaleTimeString()}${settle.why ? ` (after ${settle.why})` : ''}`}>⛁ settled ✓</span>
        {:else if settle?.state === 'settling'}<span class="df-settle busy"
            title={`writing your ledger to disk now${settle.why ? ` (${settle.why})` : ''}…`}>⛁ settling…</span>
        {:else if settle?.state === 'owed'}<span class="df-settle owed"
            title="your ledger changed but no share folder is open to write it to — it lives only in this tab until you open one.">⛁ write owed</span>{/if}
    </div>
    <!-- INVITE SITS ABOVE THE PIER LIST (the owner 2026-08-10) — it was at the bottom, under a list
         that grows, so the one verb a newcomer needs was the one thing that walked off the cell as
         friends arrived.
         NO FOLD AT ALL ANY MORE (the owner 2026-08-11: *"we don't need a `<details>` like situation
          anymore, just have the invite button and hole"*).  This went through the whole argument in
           one sitting and landed past it: first the shut state had no affordance, then a rotating ▸
            marker was the fix, then — correctly — the fold itself was the thing to delete.  The Door
             cell IS the invite door; there was never anything behind the disclosure except the reason
              the cell exists, so every version of the toggle was chrome guarding an empty secret.
         The panel's own two controls (`invite a friend`, and the paste field) are the buttons and the
          hole; nothing needs to be opened to reach them.  A bud is unaffected — the `small` branch
           above returns 🚪 and never reaches this. -->
    {#if face.prepub}
        <div class="df-panel"><InvitePanel {H} inglass /></div>
        <!-- INVITE YOURSELF (Portability_todo §9) — the second gesture beside invite-a-friend:
             same rails, inverted consequence (its redemption makes you, not befriends you).  V1 is
             the explainer + an honestly-disabled LinkDevice hatch; see the component. -->
        <div class="df-panel"><InviteYourself /></div>
    {/if}
    {#if naming}
        <div class="df-naming">
            <input class="df-input" bind:value={name_draft} placeholder="what do friends call you?"
                onkeydown={(e) => { if (e.key === 'Enter') name_save(); if (e.key === 'Escape') naming = false }} />
            <button class="df-edit" onclick={name_save}>✓</button>
        </div>
        {#if name_err}<div class="df-note">⚠ {name_err}</div>{/if}
    {:else if face.prepub && !face.named}
        <div class="df-note">✎ name yourself — the name rides your invites</div>
    {/if}
    {#if face.door?.landed}
        <div class="df-invite">📨 invite from <b>{face.door.from}</b></div>
    {/if}
    {#if face.door?.note}
        <div class="df-note">{face.door.note}</div>
    {/if}
    <!-- the %Invite rows — each vivified invite is a thing with a lifecycle, shown as one small
         line: which offer (serial + what it grants), whose (prepub8), and where its state walk
         stands.  arrived|redeeming are the live states today; sealed|refused wear their colours
         for when the walk grows those legs. -->
    {#each invites as inv (inv.serial + inv.prepub)}
        <div class="df-invrow" class:sealed={inv.state === 'sealed'} class:refused={inv.state === 'refused'}
            title={`invite #${inv.serial} from ${inv.prepub}${inv.to ? ` — grants ${inv.to}` : ''}${inv.n ? ` (n ${inv.n})` : ''} — ${inv.state}`}>
            <span>✉ #{inv.serial}{inv.to ? ` ${inv.to}` : ''} from {inv.prepub}</span>
            <span class="df-invstate">{inv.state}</span>
        </div>
    {/each}
    {#if face.up}
        <!-- ME, at the head of the same list the friends stand in: one liveness reading, not two
             cells.  Deliberately styled DOWN from a friend row (this is context, they are the app). -->
        <div class="df-me" class:fresh={face.up.fresh}
            title="this tab has been up {face.up.label} — resets on reload, so a near-zero reading means the reload landed">
            <span class="df-dot here">●</span>
            <span class="df-name">you</span>
            <span class="df-tag dim">up {face.up.label}</span>
            {#if face.up.fresh}<span class="df-tag">fresh reload</span>{/if}
        </div>
    {/if}
    <!-- THE BODIES LINE — one quiet row, only when there is anything to say: this body's place
         (bare or …_N), whether it holds the bare name (primary), and each known %Sibling.  It sits
         under the me-row because it is the same reading — WHERE this soul stands — one level
         deeper.  Hover carries the long form; the row itself stays tag-sized. -->
    {#if bodies}
        <div class="df-bodies"
            title={'the bodies of this identity — one soul, many tabs/devices.'
                + (bodies.primary === null ? ' No cohort census ran in this tab.'
                    : bodies.primary ? ' This body holds the bare name (primary).'
                    : ' Another body holds the bare name; this one stands at a suffix.')
                + (bodies.lockless ? ' (no Web Locks here — primacy assumed, never arbitrated)' : '')
                + (bodies.sibs.length ? ` ${bodies.sibs.length} sibling ${bodies.sibs.length === 1 ? 'body' : 'bodies'} known.` : '')}>
            <span class="df-tag">🧬 this body{bodies.vessel ? ` ${bodies.vessel.slice(0, 6)}` : ''}
                · {bodies.suffix ? `at …${bodies.suffix}` : 'bare'}{#if bodies.primary !== null}&nbsp;· {bodies.primary ? 'primary' : 'not primary'}{/if}</span>
            {#each bodies.sibs as s (s.place)}
                <span class="df-tag dim"
                    title={`sibling body ${s.place}${s.role ? ` — ${s.role}` : ''}${s.address ? ` at ${s.address}` : ''}`}>👤
                    {s.place.slice(0, 6)}{s.address ? ` ${short_addr(s.address, bodies.bare)}` : ''}</span>
            {/each}
        </div>
    {/if}
    <!-- A PIER ROW IS THE LIGHT AND THE NAME, in that order (the owner 2026-08-09: *"other Piers
         should just say their name and the online light, the online first"*).  Everything the row
         used to SAY — ♪ granted, N records, the half-seal warning — moves into the dot's title and
         colour: the facts stay reachable under the hood, they just stop being furniture.  A
         half-sealed pier wears the amber dot; hover says why.  The ♪→ suggest stays: it is a verb,
         not a saying.  And the list is CAPPED (*"the list shouldn't be more than yay many long"*) —
         five rows, then one dim toggle for the rest. -->
    {#each (piers_all ? face.friends : face.friends.slice(0, PIERS_SHOWN)) as f}
        <div class="df-friend">
            <span class="df-dot" class:here={f.rung === 'here'} class:fading={f.rung === 'fading'} class:half={f.seal === 1}
                title={(f.ago == null ? `${f.name} — not heard this session (their tab is closed or away)` : `${f.name} — heard ${f.ago}s ago`)
                    + (f.music ? ' · ♪ granted' : '') + (f.records != null ? ` · ${f.records} records` : '')
                    + (f.seal === 1 ? ` · ⚠ sealing 1 of 2 — ${f.seal_missing}; should heal itself, say so if it sits` : '')}>●</span>
            <span class="df-name">{f.name}</span>
            {#if f.can_suggest}
                <button class="df-edit" onclick={() => suggest(f.pub)}
                    title="suggest the playing track to {f.name} — lands even if they're away">♪→</button>
            {/if}
        </div>
        {#if f.sug}
            <div class="df-sug">
                {#if f.sug_rec}
                    <button class="df-edit" onclick={() => tune_sug(f.sug_rec)} title="play their suggestion">▶</button>
                {/if}
                <span class="df-tag">suggests: {f.sug.title}</span>
                {#if f.sug.note}<span class="df-tag dim">{f.sug.note}</span>{/if}
                {#if !f.sug_rec}<span class="df-tag dim">arriving with the share…</span>{/if}
            </div>
        {/if}
    {/each}
    {#if face.friends.length > PIERS_SHOWN}
        <button class="df-more" onclick={() => piers_all = !piers_all}
            title={piers_all ? 'fold the list back to the first few' : 'show every pier'}>
            {piers_all ? '▾ fewer' : `+ ${face.friends.length - PIERS_SHOWN} more`}
        </button>
    {/if}
    {#if !face.friends.length && !face.door?.landed}
        <div class="df-note">{face.newborn ? 'you are new here — the invite is how a friend joins you' : 'no friends yet — the invite is how one arrives'}</div>
    {/if}

    <!-- (the Invite verb + panel moved ABOVE the pier list, 2026-08-10 — see the note up there.) -->
</div>
{/if}

<style>
    /* SMALL — THE ICON, AND LITERALLY NOTHING ELSE (the owner 2026-08-10: *"Door becomes only a Door
       icon"*).  The name came off with it: a bud is one glyph you recognise, and a nowrap line of text
       beside it is what made the box wide and flat rather than a thing.
       NO `height: 100%` HERE — that was a measurement feedback loop, and the owner watched it happen
       (*"the Door is tiny! its box is a good height but far too narrow"*).  The measure pass reads this
       element's offset box as the face's NATURAL size; height:100% makes that height THE MOLD'S OWN
       HEIGHT, so the cell was sized from itself on one axis and from the text on the other — an aspect
       that is not a fact about anything.  An intrinsic box is the only honest thing to hand a measurer:
       the glyph's own size, on both axes, which is square and reads as square. */
    .df.df-small { font-size: 30px; line-height: 1; padding: 2px; }
    .df {
        pointer-events: none;
        width: max-content;
        max-width: 300px;
        padding: 8px 12px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #ead9ef;
        text-align: left;
        border-radius: 10px;
        /* the sparkle: a slow-breathing halo — this face is FOR THE USER'S EYES */
        animation: df-breathe 3.2s ease-in-out infinite;
    }
    @keyframes df-breathe {
        0%, 100% { filter: drop-shadow(0 0 3px rgba(196, 130, 224, 0.35)); }
        50%      { filter: drop-shadow(0 0 10px rgba(196, 130, 224, 0.75)); }
    }
    .df-title { font-size: 12px; font-weight: 700; color: #d9a9ef; }
    /* the invite door — a quiet disclosure at the foot of the friends list, not a call to action
       competing with them.  It only shouts (via InvitePanel's own `.ip-go`) once it is open and
        there is actually a stranger to greet. */
    /* (`.df-open` and `.df-tri` went with the fold, 2026-08-11 — the disclosure chip and its rotating
        ▸ existed for about twenty minutes between "you wouldn't know that did anything" and "we don't
         need a <details> like situation anymore". The panel is simply always here now.) */
    /* the panel takes pointer events back — `.df` is pointer-events:none so the cell beneath stays
       draggable/clickable, and every interactive descendant has to opt back in. */
    .df-panel { pointer-events: auto; margin-top: 4px; max-width: 260px; }
    .df-edit {
        pointer-events: auto;
        cursor: pointer;
        background: none;
        color: #b48fc9;
        border: none;
        font-size: 10px;
        padding: 0 3px;
    }
    .df-edit:hover { color: #fff; }
    .df-naming { display: flex; gap: 3px; margin-top: 3px; }
    .df-input {
        pointer-events: auto;
        background: #241733;
        color: #ead9ef;
        border: 1px solid #8a6fae;
        border-radius: 6px;
        font-size: 10px;
        padding: 2px 6px;
        width: 170px;
    }
    .df-pub { font-size: 8px; opacity: 0.55; font-family: monospace; margin-left: 4px; }
    .df-born {
        font-size: 9px;
        color: #ffd869;
        margin-left: 5px;
        animation: df-twinkle 1.6s ease-in-out infinite;
    }
    @keyframes df-twinkle {
        0%, 100% { opacity: 1; }
        50%      { opacity: 0.45; }
    }
    /* 🎧 the listening-only badge — a quiet, honest tag on the self line, not an alarm: the mode
       works, it just can't hold a share, and hover carries the mortal-identity whisper. */
    .df-listen { font-size: 9px; color: #8fd0e8; margin-left: 5px; cursor: help; pointer-events: auto; }
    .df-settle { font-size: 9px; margin-left: 5px; cursor: help; pointer-events: auto; }
    .df-settle.ok { color: #7fc98a; }
    .df-settle.busy { color: #d8c56b; }
    .df-settle.owed { color: #e0965e; }
    .df-settle.stolen { color: #e06a6a; font-weight: 600; }
    .df-invite { font-size: 10px; margin-top: 3px; }
    .df-note { font-size: 9px; opacity: 0.7; font-style: italic; margin-top: 2px; }
    /* the friends ARE the app — they read at full size, not as a footnote ("friends list is
       tiny", the human 2026-07-19) */
    .df-friend { display: flex; align-items: center; gap: 6px; font-size: 13px; margin-top: 4px; }
    /* the me-row: same list, quieter voice — the friends read at full size, this is the context they sit in */
    .df-me { display: flex; align-items: center; gap: 6px; font-size: 11px; margin-top: 4px; opacity: 0.75; }
    .df-me .df-name { font-weight: 600; }
    .df-me.fresh .df-dot { color: #f0c060; text-shadow: 0 0 5px rgba(240, 190, 110, 0.8); }
    .df-friend .df-name { font-weight: 600; }
    .df-sug { display: flex; align-items: center; gap: 4px; font-size: 10px; margin-left: 16px; }
    .df-dot { color: #5a4a5f; font-size: 10px; }
    .df-dot.here { color: #7fe8bf; text-shadow: 0 0 4px #7fe8bf; }
    .df-dot.fading { color: #d8b86a; }
    /* the half-seal state now lives ON the dot (the row says only light + name): amber and slightly
       alive, because a silently-half-working link is the one state that looks fine and isn't. */
    .df-dot.half { color: #f0c060; animation: df-halfpulse 2.4s ease-in-out infinite; }
    @keyframes df-halfpulse { 0%, 100% { opacity: 0.6 } 50% { opacity: 1 } }
    .df-tag { font-size: 8px; color: #b48fc9; }
    .df-tag.dim { opacity: 0.6; }
    /* the bodies line — the same voice as a .df-tag row: small, dim, informative.  cursor:help +
       pointer-events:auto so the hover long-form is reachable through the .df pointer shield. */
    .df-bodies {
        display: flex; flex-wrap: wrap; align-items: baseline; gap: 6px;
        margin-top: 3px; cursor: help; pointer-events: auto;
    }
    /* a %Invite row — an arrived offer as a visible thing; the state word carries the colour:
       amber while it is in flight (arrived|redeeming), green sealed, red refused. */
    .df-invrow { display: flex; align-items: center; gap: 6px; font-size: 10px; margin-top: 2px; cursor: help; pointer-events: auto; }
    .df-invstate { font-size: 8px; color: #d8c56b; }
    .df-invrow.sealed .df-invstate { color: #7fc98a; }
    .df-invrow.refused .df-invstate { color: #e06a6a; }
    /* the +N more toggle — the cap's release valve, styled to whisper */
    .df-more {
        pointer-events: auto; cursor: pointer; background: none; border: none;
        font-size: 8px; color: #8a7a94; text-align: left; padding: 0;
    }
    .df-more:hover { color: #cbb8d8; }
</style>
