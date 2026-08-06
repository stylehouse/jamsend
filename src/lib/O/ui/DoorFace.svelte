<script lang="ts">
    import { lifewatch } from './micro/lifetell'   // DIAGNOSTIC — strip with the rest of the remount probes
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
            door,
            friends,
            up,
        }
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
</script>

<div class="df">
    <div class="df-title">🚪 {face.name ?? 'standing you up…'}
        {#if face.prepub && !naming}
            <button class="df-edit" onclick={name_open} title="name yourself — friends see this">✎</button>
        {/if}
        {#if face.prepub}<span class="df-pub">{face.prepub}</span>{/if}
        {#if face.newborn}<span class="df-born">✨ born today</span>{/if}
    </div>
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
    {#each face.friends as f}
        <div class="df-friend">
            <span class="df-dot" class:here={f.rung === 'here'} class:fading={f.rung === 'fading'}
                title={f.ago == null ? `${f.name} — not heard this session (their tab is closed or away)` : `${f.name} — heard ${f.ago}s ago (their station's pulse heartbeat)`}>●</span>
            <span class="df-name">{f.name}</span>
            {#if f.music}<span class="df-tag">♪ granted</span>{/if}
            {#if f.seal === 1}
                <span class="df-half" title="half-sealed — {f.seal_missing}. Asks leave but answers die on the doorstep, so this link looks merely slow. It should heal itself; if it sits here, say so.">⚠ sealing — 1 of 2</span>
            {/if}
            {#if f.records != null}<span class="df-tag dim">{f.records} records</span>{/if}
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
    {#if !face.friends.length && !face.door?.landed}
        <div class="df-note">{face.newborn ? 'you are new here — the invite QR below is how a friend joins you' : 'no friends yet — mint an invite QR in the panel'}</div>
    {/if}
</div>

<style>
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
    .df-tag { font-size: 8px; color: #b48fc9; }
    /* the half-seal warning: amber and slightly alive, because a silently-half-working link is the
       one state that looks fine and isn't — it has to catch the eye without shouting */
    .df-half {
        font-size: 8px; color: #f0c060; border: 1px solid rgba(240, 192, 96, 0.35);
        border-radius: 3px; padding: 0 3px; animation: df-halfpulse 2.4s ease-in-out infinite;
    }
    @keyframes df-halfpulse { 0%, 100% { opacity: 0.6 } 50% { opacity: 1 } }
    .df-tag.dim { opacity: 0.6; }
</style>
