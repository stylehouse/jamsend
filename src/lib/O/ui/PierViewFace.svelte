<script lang="ts">
    // PierViewFace — the PIER CELL: one friend, opened from their green dot in the Door (owner 2026-10-14: "the
    //  others green dots should be able to open a Pier cell to star, write notes on, and ban them" … "it should be a
    //   whole new Cell that disappears when exited").  The particle is %PierView,of:<pub> — a REFERRING particle on the
    //    client world, grappled only while focused (Sounditron_commission), so navigating away folds it; ✕ drops it.
    //  Face contract: { n: TheC, H: House } — imperative mount, react off H.version.
    //  Star + note are MY private marks (pier_marks.ts, the House stash); ban is the signed forget (Swarm_pier_forget —
    //   a %NotGrant per feature + UnInvite), two presses, then the cell closes.
    import DeleteX from './micro/DeleteX.svelte'
    import { pier_marks, pier_mark_set } from './pier_marks'
    let { n, H } = $props()
    let pose = $derived.by(() => { void H?.version; return String(n?.c?.pose ?? 'big') })
    let small = $derived(pose === 'small')
    let pub = $derived.by(() => { void H?.version; return String(n?.sc?.of ?? '') })
    let tick = $state(0)
    $effect(() => { const t = setInterval(() => tick++, 2000); return () => clearInterval(t) })
    // the friend, read off the live ledger: name, liveness, whether music is granted
    let pier = $derived.by(() => {
        void H?.version
        void tick
        try {
            const me = H?.Swarm_live_self?.()
            const p = me ? (H?.Swarm_peering?.(me)?.o?.({ Pier: 1, pub })?.[0] ?? null) : null
            if (!p) return null
            const page = p.o?.({ Peering: 1 })?.[0]
            const heard = p.c?.heard_at ? Math.round((Date.now() - p.c.heard_at) / 1000) : null
            return {
                name: String(p.sc.friendly || page?.sc?.friendly || ''),
                pub8: pub.slice(0, 8),
                heard,
                music: !!H?.Swarm_pier_live?.(p, 'Music'),
                since: p.sc.since ? new Date(+p.sc.since * 1000).toLocaleDateString() : '',
            }
        } catch { return null }
    })
    let mark = $derived.by(() => { void H?.version; void tick; return pier_marks(H)[pub] ?? {} })
    let note_draft = $state('')
    $effect(() => { void pub; note_draft = pier_marks(H)[pub]?.note ?? '' })
    function star() { pier_mark_set(H, pub, { star: mark.star ? '' : '1' }) }
    function note_save() { pier_mark_set(H, pub, { note: note_draft.trim() }) }
    function close() { try { H?.Sounditron_pier_close?.() } catch {} }
    function ban() {
        try { H?.Swarm_pier_forget?.(null, pub) } catch {}
        close()
    }
</script>

{#if small}
    <div class="pv-bud" title={pier?.name || pub.slice(0, 8)}>{mark.star ? '★' : '●'}</div>
{:else}
<div class="pv">
    <div class="pv-head">
        <span class="pv-dot" class:here={pier?.heard != null && pier.heard < 40}>●</span>
        <span class="pv-name">{mark.star ? '★ ' : ''}{pier?.name || pub.slice(0, 8)}</span>
        <span class="pv-pub">{pub.slice(0, 8)}</span>
        <button class="pv-x" onclick={close} title="close — back to the Door">✕</button>
    </div>
    <div class="pv-facts">
        {#if !pier}not a friend any more{:else}
            {pier.heard == null ? 'not heard this session' : pier.heard < 40 ? 'here now' : `heard ${pier.heard}s ago`}
            {pier.music ? ' · ♪ music shared' : ''}{pier.since ? ` · friends since ${pier.since}` : ''}
        {/if}
    </div>
    <div class="pv-row">
        <button class="pv-btn" class:on={!!mark.star} onclick={star} title={mark.star ? 'unstar' : 'star — starred friends sit first in the Door'}>{mark.star ? '★ starred' : '☆ star'}</button>
        <DeleteX inline ondelete={ban} confirm="ban?" glyph="⊘ ban"
            title="ban — ends the friendship with a signed revocation; they can be re-invited later" />
    </div>
    <textarea class="pv-note" rows="4" bind:value={note_draft} placeholder="a note about them — only you see it"
        onblur={note_save}
        onkeydown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); note_save(); (e.target as HTMLElement).blur() } }}></textarea>
</div>
{/if}

<style>
    /* pointer-events:none on the root, auto on every control — the glass_kinds contract (LinkFace/HaulFace record why) */
    .pv {
        pointer-events: none;
        display: flex; flex-direction: column; gap: 0.7rem;
        /* a COMPACT NATURAL BOX, not 100%×100% (owner 2026-10-14: "Pier cell thinks its too wide") — a face that fills the
           column reads as "stretched" to Cellui's fit and only scales by height; a natural box lets the fit inscribe it in
            the blob like the Door's */
        width: 20rem; max-width: 100%; box-sizing: border-box; padding: 0.8rem 1rem;
        color: #f4e6c8; overflow: hidden;
    }
    .pv-head { display: flex; align-items: baseline; gap: 0.5rem; }
    .pv-dot { color: #5a4a5f; font-size: 0.9rem; }
    .pv-dot.here { color: #7fe8bf; text-shadow: 0 0 4px #7fe8bf; }
    .pv-name { font-size: 1.5rem; font-weight: 700; color: #e8d7f5; }
    .pv-pub { font-size: 0.7rem; opacity: 0.5; font-family: monospace; }
    .pv-x {
        pointer-events: auto; margin-left: auto; cursor: pointer; background: rgba(0,0,0,0.25);
        border: 1px solid rgba(255,255,255,0.15); color: #f4e6c8; border-radius: 6px; padding: 0.1rem 0.5rem; font-size: 0.9rem;
    }
    .pv-facts { font-size: 0.85rem; opacity: 0.75; }
    .pv-row { display: flex; align-items: center; gap: 1rem; }
    .pv-btn {
        pointer-events: auto; cursor: pointer; background: rgba(0,0,0,0.25); color: #f4e6c8;
        border: 1px solid rgba(240, 208, 128, 0.35); border-radius: 6px; padding: 0.25rem 0.7rem; font-size: 0.95rem;
    }
    .pv-btn.on { color: #f0d080; border-color: #f0d080; background: rgba(240, 208, 128, 0.12); }
    .pv-row :global(*) { pointer-events: auto; }
    .pv-note {
        pointer-events: auto; width: 100%; box-sizing: border-box; resize: vertical; font: inherit; font-size: 0.95rem;
        color: #eee; background: rgba(0,0,0,0.3); border: 1px solid rgba(170,150,220,0.3); border-radius: 6px; padding: 0.4rem 0.6rem;
    }
    .pv-bud {
        pointer-events: none; display: flex; align-items: center; justify-content: center;
        width: 100%; height: 100%; font-size: 2rem; color: #7fe8bf;
    }
</style>
