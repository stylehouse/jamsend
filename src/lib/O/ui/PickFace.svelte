<script lang="ts">
    // PickFace — ONE kept track in a NESTED %Haul cell (the human 2026-07-28 "nodulate down the folder
    //  hierarchy ... one for the hierarchy one for the list of tracks").  A %Pick is a track the keep will
    //   pull; under the nested glass a keep goes BARE and each of its picks draws as its own chip beside the
    //    %HaulBar controls cell.  Click un-keeps it (drops the pick → the chip escorts out of the scope).  A
    //     landed pick wears ✓; the track you're hearing (the keep's seed) wears ♪.  Props { n, H } — n is the
    //      LIVE %Pick particle; n.c.up is its %Haul (stamped by Heist_keep_default_pick / _toggle).
    let { n, H } = $props()
    const A = H as any

    // the pull lands the record off the beat (pick.sc.landed flips on a tick), which a bare H.version derive
    //  can miss between bumps — poll a slow clock beside it (the HaulFace/UptimeFace idiom).
    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 500); return () => clearInterval(iv) })

    let face = $derived.by(() => {
        void H?.version
        void tick
        void n?.vers                    // the pick's own bumps — pick.bump() flips landed at the beat, not the poll
        const sc = n?.sc ?? {}
        const keep = n?.c?.up
        void keep?.vers
        const seed = keep ? String(keep.sc?.seed ?? '') : ''
        const ref = String(sc.ref ?? '')
        return {
            title: String(sc.title || ref || 'a track'),
            artist: String(sc.artist || ''),
            landed: !!sc.landed,
            seed: ref !== '' && ref === seed,   // the track you're hearing right now
        }
    })

    function unkeep() {
        const keep = n?.c?.up
        if (!keep) return
        A?.post_do?.(() => { A?.Heist_keep_pick_toggle?.(keep, String(n.sc.ref)) }, { see: 'unkeep track' })
    }
</script>

<button class="pk" class:landed={face.landed} class:seed={face.seed} onclick={unkeep}
    title={face.landed ? 'landed in your collection' : (face.seed ? "the track you're hearing — click to skip" : 'keeping — click to skip')}>
    <span class="pk-tick">{face.landed ? '✓' : face.seed ? '♪' : '⇊'}</span>
    <span class="pk-name">{face.title}{#if face.artist}<span class="pk-artist"> — {face.artist}</span>{/if}</span>
</button>

<style>
    /* the whole chip is the un-keep button (HaulFace's .kf-track precedent); pointer-events:auto re-arms
       only its own max-content footprint, so overlapping neighbour cells still hover through. */
    .pk {
        pointer-events: auto;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 5px;
        width: max-content;
        max-width: 200px;
        padding: 3px 8px;
        background: transparent;
        border: none;
        color: #e0cfd8;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        font-size: 10px;
        text-align: left;
        opacity: 0.85;
    }
    .pk-tick { color: #7fe8bf; flex: none; font-size: 9px; }
    .pk.landed { opacity: 1; }
    .pk.landed .pk-tick { color: #57c777; }
    .pk.seed .pk-name { color: #7fe8bf; }
    .pk-name { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 175px; }
    .pk-artist { opacity: 0.65; font-size: 9px; }
    .pk:hover { color: #fff; opacity: 1; }
    .pk:hover .pk-name { text-decoration: line-through; }
</style>
