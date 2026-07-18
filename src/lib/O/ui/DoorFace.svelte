<script lang="ts">
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
                friends = ((H.Swarm_peering(self)?.o({ Pier: 1 }) ?? []) as any[]).map((p: any) => ({
                    name: String(p.sc.friendly || String(p.sc.pub).slice(0, 8)),
                    music: !!p.o({ Grant: 'Music' })[0],
                    records: p.o({ IveGot: 1, by: 'records' })[0]?.sc?.count,
                    here: !!p.c?.heard_at && Date.now() - p.c.heard_at < 12000,
                }))
            }
        } catch { friends = [] }
        return {
            nick: self?.sc?.nick as string | undefined,
            prepub: self?.sc?.prepub ? String(self.sc.prepub).slice(0, 8) : undefined,
            born: self?.sc?.born as string | undefined,
            newborn: !!self?.sc?.born && self.sc.born === today,
            door,
            friends,
        }
    })
</script>

<div class="df">
    <div class="df-title">🚪 {face.nick ?? 'no self yet'}
        {#if face.prepub}<span class="df-pub">{face.prepub}</span>{/if}
        {#if face.newborn}<span class="df-born">✨ born today</span>{/if}
    </div>
    {#if face.door?.landed}
        <div class="df-invite">📨 invite from <b>{face.door.from}</b></div>
    {/if}
    {#if face.door?.note}
        <div class="df-note">{face.door.note}</div>
    {/if}
    {#each face.friends as f}
        <div class="df-friend">
            <span class="df-dot" class:here={f.here}>●</span>
            <span class="df-name">{f.name}</span>
            {#if f.music}<span class="df-tag">♪ granted</span>{/if}
            {#if f.records != null}<span class="df-tag dim">{f.records} records</span>{/if}
        </div>
    {/each}
    {#if !face.friends.length && !face.door?.landed}
        <div class="df-note">no piers sealed — invite a friend from the panel</div>
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
    .df-friend { display: flex; align-items: center; gap: 5px; font-size: 10px; margin-top: 2px; }
    .df-dot { color: #5a4a5f; font-size: 8px; }
    .df-dot.here { color: #7fe8bf; text-shadow: 0 0 4px #7fe8bf; }
    .df-tag { font-size: 8px; color: #b48fc9; }
    .df-tag.dim { opacity: 0.6; }
</style>
