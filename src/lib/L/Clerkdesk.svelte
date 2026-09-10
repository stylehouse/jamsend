<script lang="ts">
    import { is_testing } from "$lib/L/testing"
    // Clerkdesk — the literal desktop of a clerk who expanding-foams information.
    //
    //  THE ASK (the owner, 2026-09-09, tired, three sentences that turned out to be one thing):
    //   *"I'm unimpressed with its ability to change Doc quickly… and it forgets what it was going in
    //    there to look at if that takes too long. so where do we keep what to look at and what we're
    //     doing etc?"* — then: *"we need to design the literal desktop of some clerk who
    //      expanding-foams information."*
    //
    //  WHY THIS IS A SURFACE AND NOT A STORE.  The errand was never not kept.  Every search delivery
    //   already writes a moment into today's Aside — `about` (what you went in there to look at,
    //    stamped at mint on the owner's own words), `FromWhat` (where you came from), a %Doc per ghost
    //     and a %Point per visit.  `Lies_resolve_locator` already resolves the locator form and its own
    //      comment calls itself "the reader %FromWhat was waiting for".  Shelf, label and resolver were
    //       all built; nothing had ever DRAWN them.  So this file adds no state of its own — it is a
    //        rendering of `Lagoon_errands`, which is a reading of a shelf Lagoon does not own.
    //
    //  THE POINT OF IT BEING A DESK.  The three complaints are one mechanism: changing Doc is slow, the
    //   wait is where intent dies, and intent dies because nothing holds it in front of you during the
    //    wait.  So the desk's job is to be legible AT ALL TIMES, especially while something loads.  It
    //     never blanks on a slow answer and never clears on a re-ask: `held` keeps the last good trail
    //      on screen and the strip only dims, because a desk that empties while you fetch something is
    //       the exact failure being fixed.
    //
    //  NOT FOAM YET, AND DELIBERATELY.  A soap foam is a Voronoi tessellation, which is what the
    //   Voro/Vyto glass already draws — so the eventual rendering is that glass given a new subject,
    //    not a new engine.  But the glass is the VISUAL branch's front door (`Glassbeast_todo`), so
    //     that is a ruling for the owner and marked as such in `Clerkdesk_todo §0`.  Until then: cells
    //      in a wrap, sized by weight, which is the honest first cut and holds still enough to read.
    let { H } = $props()

    function lagoon_w(): any {
        const top = (H as any).top_House?.()
        return top?.o({ A: 'Lagoon' })[0]?.o({ w: 'Lagoon' })[0] ?? null
    }

    // `held` is the desk's whole trick: the last answer STAYS while a new one is in flight, so the
    //  surface never goes blank at exactly the moment you needed to remember what you were doing.
    let held = $state<any>(null)
    let refusal = $state('')
    let asking = $state(false)
    function ask() {
        const lw = lagoon_w()
        if (!lw) { refusal = 'no A:Lagoon standing — ghost_load Ghost/L/Lagoon.g --stand=Lagoon'; return }
        const out = (H as any).Lagoon_errands?.(lw, 60)
        if (!out) { refusal = 'the Lagoon ghost is not loaded on this tab'; return }
        if (out.error) { refusal = out.error; return }
        refusal = ''
        held = out
    }
    $effect(() => {
        ask()
        const iv = setInterval(ask, 1500)
        return () => clearInterval(iv)
    })

    // a moment's WEIGHT is how often you went back to it — the desk's only ranking, and the only
    //  thing size means here.  Capped so one obsessive afternoon cannot make the rest unreadable.
    const weight = (m: any) => Math.min(1, (m.visits ?? 1) / 6)
    const cell_px = (m: any) => (0.74 + 0.5 * weight(m)).toFixed(2) + 'rem'
    const tail = (p: string) => (p ?? '').split('/').filter(Boolean).slice(-1)[0] ?? p

    // ── THE HEADING — what we are really up to, in your words ────────────────────────────────────
    //  The owner, 2026-09-10: *"we need a heading where I can track what we're really up to… which
    //   docs are we actively working on and just in the vicinity of?"*  Three things, one band: the
    //    name you give the day, and the two rings the trail already knows.
    //  The heading is EDITED HERE and WRITTEN BY LIES — this face may not touch the shelf, and neither
    //   may Lagoon (it reads).  `draft` holds what you are typing so a 1.5s re-ask cannot yank the
    //    caret out from under you; it commits on blur or Enter and then lets the read own the value
    //     again.  A field that fights its own poll is the classic version of this bug.
    let draft = $state<string | null>(null)
    const shown_heading = () => draft ?? held?.heading ?? ''
    function commit() {
        const w = (H as any).o?.({ A: 'Lies' })[0]?.o({ w: 'Lies' })[0]
            ?? (H as any).top_House?.()?.o({ A: 'Lies' })[0]?.o({ w: 'Lies' })[0]
        if (w && draft != null) (H as any).Lies_aside_heading?.(w, draft)
        draft = null
        ask()
    }

    let open = $state('')
    const key = (m: any) => `${m.day}·${m.what}`
    // going back to an errand is the SAME delivery the searchbar makes, so it lands the same way and
    //  is recorded the same way — a desk that reopens a moment must not invent a second road to it.
    function resume(m: any, d: any) {
        const pt = (d.points ?? [])[0] ?? m.about
        ;(H as any).i_elvisto?.('Lies/Lies', 'Lies_ghost_pick', pt ? { path: d.doc, point: pt } : { path: d.doc })
    }
</script>

<div class="cd">
    <div class="cd-top">
        <span class="cd-name">clerk’s desk</span>
        {#if held}
            <span class="cd-note">
                {held.total} errand{held.total === 1 ? '' : 's'} · {held.days.length} day{held.days.length === 1 ? '' : 's'}
                {#if held.gone}· <span class="cd-gone-n">{held.gone} since renamed</span>{/if}
                {#if !held.atlas}· no census, nothing checked{/if}
            </span>
        {/if}
    </div>

    <!-- the heading band: what we're up to, then the two rings.  `working` = docs you came BACK to
         today; `vicinity` = docs you passed through once.  A claim about the work, not the code. -->
    {#if held}
        <input class="cd-heading" placeholder="what are we really up to?"
               value={shown_heading()}
               oninput={(e) => draft = (e.currentTarget as HTMLInputElement).value}
               onblur={commit}
               onkeydown={(e) => { if (e.key === 'Enter') (e.currentTarget as HTMLInputElement).blur() }} />
        {#if held.working?.length || held.vicinity?.length}
            <div class="cd-rings">
                {#if held.working?.length}
                    <div class="cd-ring">
                        <span class="cd-ring-name">working on</span>
                        {#each held.working as r (r.doc)}
                            <button class="cd-chip work" class:gone={r.gone} class:testing={is_testing(r.doc)}
                                    title="{r.visits} visits today — {r.about.join(' · ')}"
                                    onclick={() => resume({ about: r.about[0] }, { doc: r.doc, points: r.about })}>
                                {tail(r.doc)}<span class="n">{r.visits}</span>
                            </button>
                        {/each}
                    </div>
                {/if}
                {#if held.vicinity?.length}
                    <div class="cd-ring">
                        <span class="cd-ring-name">in the vicinity</span>
                        {#each held.vicinity as r (r.doc)}
                            <button class="cd-chip near" class:gone={r.gone} class:testing={is_testing(r.doc)}
                                    title="passed through once today — {r.about.join(' · ')}"
                                    onclick={() => resume({ about: r.about[0] }, { doc: r.doc, points: r.about })}>
                                {tail(r.doc)}
                            </button>
                        {/each}
                    </div>
                {/if}
            </div>
        {/if}
    {/if}

    {#if refusal && !held}
        <div class="cd-none bad">{refusal}</div>
    {:else if held && !held.errands.length}
        <div class="cd-none">nothing on the desk yet — search for something and open it, and the errand lands here</div>
    {:else if held}
        <!-- the desk proper: one cell per moment, sized by how often you came back to it.  The label
             IS the errand — what you went in there to look at — not the file you ended up in. -->
        {#each held.days as d (d.day)}
            {@const mine = held.errands.filter((m: any) => m.day === d.day)}
            {#if mine.length}
                <div class="cd-day">▤ {d.day.replace(/^Aside\//, '')}<span class="n">{d.visits} visit{d.visits === 1 ? '' : 's'}</span></div>
                <div class="cd-cells" class:asking>
                    {#each mine as m (key(m))}
                        <button class="cd-cell" class:on={open === key(m)}
                                style="font-size: {cell_px(m)}"
                                title="{m.visits} visit{m.visits === 1 ? '' : 's'} · {m.docs.map((x: any) => x.doc).join(' · ')}"
                                onclick={() => open = open === key(m) ? '' : key(m)}>
                            {m.about ?? '(unlabelled)'}{#if m.visits > 1}<span class="n">{m.visits}</span>{/if}
                        </button>
                    {/each}
                </div>
                {#each mine.filter((m: any) => key(m) === open) as m (key(m))}
                    <!-- the errand opened: what it touched, and the way back.  A stale path is HISTORY —
                         the visit happened — so it is marked and still offered, never hidden. -->
                    <div class="cd-open">
                        {#each m.docs as doc}
                            <div class="cd-doc" class:gone={doc.gone} class:testing={is_testing(doc.doc)}>
                                <button class="cd-go" disabled={!!doc.gone}
                                        title={doc.gone ? 'the census cannot place this path — the visit happened, the file has since moved or gone' : `open ${doc.doc}`}
                                        onclick={() => resume(m, doc)}>{doc.gone ? '⌦' : '↦'}</button>
                                <span class="cd-path">{doc.doc}</span>
                                {#if doc.points?.length}<span class="cd-pts">{doc.points.join(' · ')}</span>{/if}
                            </div>
                        {/each}
                        {#if m.from_waft}
                            <div class="cd-from">↩ came from <b>{tail(m.from_waft)}</b> — {m.from_tail}</div>
                        {/if}
                    </div>
                {/each}
            {/if}
        {/each}
    {/if}
</div>

<style>
    .cd { display: flex; flex-direction: column; gap: 0.2rem; font-size: 0.8rem; padding: 0.3rem 0.4rem; }
    .cd-top { display: flex; align-items: baseline; gap: 0.5rem; }
    .cd-name { color: #cfe0ff; letter-spacing: 0.04em; }
    .cd-note { color: rgba(140, 160, 200, 0.7); font-size: 0.74rem; }
    .cd-gone-n { color: rgba(224, 180, 110, 0.8); }
    .cd-none { color: rgba(140, 160, 200, 0.6); padding: 0.3rem 0.1rem; }
    .cd-none.bad { color: rgba(224, 150, 130, 0.85); }
    /* the heading — the one thing on the desk you WRITE.  Underlined rather than boxed: it is a
       label on the day, not a form field, and a box would make the desk look like a dialog. */
    .cd-heading {
        background: none; border: none; border-bottom: 1px solid rgba(120, 140, 195, 0.3);
        font-family: inherit; font-size: 0.94rem; color: #dce8ff;
        padding: 0.1rem 0.15rem; width: 100%; outline: none;
    }
    .cd-heading::placeholder { color: rgba(140, 160, 200, 0.45); font-style: italic; }
    .cd-heading:focus { border-bottom-color: rgba(143, 211, 200, 0.7); }
    .cd-rings { display: flex; flex-direction: column; gap: 0.12rem; margin: 0.15rem 0 0.1rem; }
    .cd-ring { display: flex; flex-wrap: wrap; gap: 0.15rem 0.28rem; align-items: baseline; }
    .cd-ring-name { color: rgba(140, 160, 200, 0.5); font-size: 0.68rem; letter-spacing: 0.05em; flex: none; width: 6.4rem; }
    .cd-chip {
        background: none; border: none; font-family: inherit; cursor: pointer;
        border-bottom: 1px solid transparent; padding: 0 0.1rem; font-size: 0.76rem;
    }
    /* the rings differ by WEIGHT, not by colour: one is what you are doing, the other is where you
       happen to be, and that is a difference of emphasis rather than of kind. */
    .cd-chip.work { color: #cfe0ff; border-bottom-color: rgba(143, 211, 200, 0.5); }
    .cd-chip.near { color: rgba(150, 168, 200, 0.75); }
    .cd-chip:hover { color: #e8f0ff; border-bottom-color: rgba(150, 190, 240, 0.6); }
    .cd-chip.gone { color: rgba(140, 160, 200, 0.4); text-decoration: line-through; }
    .cd-chip.testing { color: #5ab; }
    .cd-chip .n { color: rgba(140, 160, 200, 0.5); font-size: 0.72em; vertical-align: super; margin-left: 0.15em; }
    .cd-day { color: rgba(140, 160, 200, 0.55); font-size: 0.72rem; margin-top: 0.25rem; }
    .cd-day .n { margin-left: 0.4em; color: rgba(140, 160, 200, 0.4); }
    /* the cells.  A re-ask only DIMS them — the desk must never go blank while something loads, which
       is the whole failure it exists to fix. */
    .cd-cells { display: flex; flex-wrap: wrap; gap: 0.15rem 0.3rem; align-items: baseline; transition: opacity 0.2s; }
    .cd-cells.asking { opacity: 0.72; }
    .cd-cell {
        background: none; border: none; border-bottom: 1px solid rgba(120, 140, 195, 0.2);
        font-family: inherit; line-height: 1.2; cursor: pointer; padding: 0 0.15rem;
        color: rgba(196, 210, 238, 0.94);
    }
    .cd-cell:hover { color: #e8f0ff; border-bottom-color: rgba(150, 190, 240, 0.6); }
    .cd-cell.on { color: #8fd3c8; border-bottom-color: rgba(143, 211, 200, 0.7); }
    .cd-cell .n { color: rgba(140, 160, 200, 0.5); font-size: 0.68em; vertical-align: super; margin-left: 0.2em; }
    .cd-open {
        display: flex; flex-direction: column; gap: 0.1rem;
        margin: 0.15rem 0 0.35rem 0.6rem; padding-left: 0.55rem;
        border-left: 1px solid rgba(143, 211, 200, 0.35);
    }
    .cd-doc { display: flex; align-items: baseline; gap: 0.35rem; font-size: 0.76rem; }
    .cd-doc.gone .cd-path { color: rgba(140, 160, 200, 0.45); text-decoration: line-through; }
    .cd-doc.testing .cd-path { color: #5ab; }
    .cd-go {
        background: none; border: none; cursor: pointer; font-family: inherit;
        color: rgba(143, 211, 200, 0.8); padding: 0 0.15rem; flex: none;
    }
    .cd-go:disabled { color: rgba(224, 180, 110, 0.6); cursor: default; }
    .cd-path { color: #aab; }
    .cd-pts { color: rgba(140, 160, 200, 0.6); }
    .cd-from { color: rgba(140, 160, 200, 0.65); font-size: 0.74rem; }
    .cd-from b { color: rgba(196, 210, 238, 0.9); font-weight: normal; }
</style>
