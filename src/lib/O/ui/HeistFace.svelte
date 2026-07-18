<script lang="ts">
    // HeistFace — the Pirating flow in the glass, one face per %Heist.  IMPOSED by mainkey
    //  (FACE_MAINKEYS, glass_faces.ts — no %Heist ever wears sc.face; the world and every
    //   sealed Musu Book stay Voro-blind).  Two honest shapes, rendered by what stands:
    //    POSED  — Sounditron's nugget: the sentence rides the mainkey value + %Need children,
    //             met:1 arriving as the world provides (the witness keeps them honest).
    //    SOFT   — Heist.g's arc: sc.wish + %Lead answers accumulating; CHOOSING a Lead
    //             condenses the wish (at/chose stamp on — the built pull machinery takes
    //              over from there; the un-chosen Leads stay, scaffolding not ledger).
    let { n, H } = $props()

    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 1000)
        return () => clearInterval(iv)
    })

    let face = $derived.by(() => {
        void H?.version
        void tick
        const sc = n?.sc ?? {}
        const needs = (n?.o?.({ Need: 1 }) ?? []).map((d: any) => ({ text: String(d.sc.Need), met: !!d.sc.met }))
        const leads = (n?.o?.({ Lead: 1 }) ?? []).map((d: any) => ({
            d,
            tune: String(d.sc.tune ?? d.sc.id ?? ''),
            pier: String(d.sc.pier ?? '').slice(0, 8),
            chosen: sc.chose != null && sc.chose === d.sc.id,
        }))
        const mainval = typeof sc.Heist === 'string' && sc.Heist !== '1' ? sc.Heist : ''
        return {
            sentence: String(sc.wish ?? mainval ?? ''),
            soft: !!(sc.wish && !sc.at),
            at: sc.at ? String(sc.at).slice(0, 8) : undefined,
            from: sc.from as string | undefined,
            needs,
            leads,
        }
    })

    const take = (lead: any) => {
        const tune = String(lead.d?.sc?.tune ?? '')
        const artist = tune.includes(' — ') ? tune.split(' — ')[0] : 'unknown'
        ;(H as any)?.Heist_condense?.(n, lead.d, artist, 'radio')
    }
</script>

<div class="hf">
    <div class="hf-title">🏴 {face.sentence || 'a heist'}</div>
    {#if face.from}<div class="hf-from">from {face.from}</div>{/if}
    {#if face.at}<div class="hf-at">→ condensed at {face.at}</div>{/if}
    {#each face.needs as need}
        <div class="hf-need" class:met={need.met}>{need.met ? '✓' : '·'} {need.text}</div>
    {/each}
    {#each face.leads as lead}
        <div class="hf-lead" class:chosen={lead.chosen}>
            <span class="hf-tune">{lead.chosen ? '★' : '♪'} {lead.tune}</span>
            <span class="hf-pier">{lead.pier}</span>
            {#if face.soft}
                <button class="hf-btn" onclick={() => take(lead)} title="choose this lead — harden the wish">take</button>
            {/if}
        </div>
    {/each}
    {#if face.soft && !face.leads.length}
        <div class="hf-note">a wish on the wind — no leads yet</div>
    {/if}
</div>

<style>
    .hf {
        pointer-events: none;
        width: max-content;
        max-width: 300px;
        padding: 7px 11px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #e0cfd8;
        text-align: left;
    }
    .hf-title { font-size: 11px; font-weight: 700; color: #e8a9c0; }
    .hf-from, .hf-at { font-size: 9px; opacity: 0.7; }
    .hf-at { color: #7fe8bf; opacity: 0.9; }
    .hf-need { font-size: 9px; opacity: 0.6; margin-top: 1px; }
    .hf-need.met { opacity: 0.95; color: #7fe8bf; }
    .hf-lead {
        display: flex;
        align-items: center;
        gap: 6px;
        font-size: 10px;
        margin-top: 2px;
    }
    .hf-lead.chosen .hf-tune { color: #ffd869; }
    .hf-tune { max-width: 190px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .hf-pier { font-size: 8px; opacity: 0.5; font-family: monospace; }
    .hf-btn {
        pointer-events: auto;
        cursor: pointer;
        background: #38141f;
        color: #e8a9c0;
        border: 1px solid #d94f7a;
        border-radius: 8px;
        font-size: 9px;
        padding: 1px 7px;
        line-height: 1.4;
        flex: none;
    }
    .hf-btn:hover { background: #d94f7a; color: #1a0810; }
    .hf-note { font-size: 9px; opacity: 0.55; font-style: italic; margin-top: 2px; }
</style>
