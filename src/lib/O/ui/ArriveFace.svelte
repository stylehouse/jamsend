<script lang="ts">
    // ArriveFace — the Supervisor as a rack in Mundo, on a Ground page that isn't the music page (spec/AtheoryArrive_todo.md
    //  §1.3, §1.5: one Supervisor, many Faces).  Otro draws it where the full SupervisorPanel used to sit in the sprawl.
//   A 1U unit (owner 2026-11-04: "a 1u rack thing. it could list"): one line — each Arrive row's mark and key, the rest of
//    the roster as a count — and a click lists them.
    //   One quiet line per Arrive row the page's Ground declared (Ground.g Ground_arrive) — no countdown (owner 2026-11-04: "too
    //    dynamic"); a row says "stalled" only once its stall clock has run out.  A row opens to say what it stands on: the A it
    //     reads, the row that meets it, and that A's Grounds (%GroundUsed / %TheACode).  ⋯ opens the whole roster (SupervisorPanel).
    //  IT JUDGES NOTHING — Supervisor_lines gives mark, tone and the give-up; this picks which rows and draws them.
    //  A Stuffica view (Ghost/A/Stuffica.g): one Seem over w:Supervisor's %Watch rows, keeping only what a line shows (verdict,
    //   patience, note, met, sentence).  It is walked through the door once a second — the Supervisor's verdicts move on its 1s
    //    tick and say nothing about who moved — and COMMITS only when a watch's verdict changed, so the rack redraws on news, not
    //     on the clock.  What a click does (list, open a row) arrives at the door as rows on the view's Seem (%TheAOpen).
    import { untrack } from "svelte"
    import { TheC } from "$lib/Stuff.svelte"
    import SupervisorPanel from "$lib/O/ui/SupervisorPanel.svelte"
    let { H = null }: { H?: any } = $props()

    class Look { v = $state(0); commit() { this.v++ } }
    const look = new Look()
    const Wv = new TheC({ c: {}, sc: { w: 'Arrive' } })
    const NAME = 'rack'
    let stood = false
    let guts = $state(false)

    let M = $derived(H?.top_House ? H.top_House() : H)
    const sup_w = () => M?.o?.({ A: 'Supervisor' })[0]?.o?.({ w: 'Supervisor' })[0] ?? null
    const loaded = () => typeof H?.Stuffica_door === 'function' && typeof H?.Supervisor_line === 'function'
    function refresh() {
        if (!loaded() || document.hidden) return
        if (!stood) {
            stood = true
            H.Stuffica_view(Wv, NAME, ['Watch'], look, { says: ['verdict', 'patience', 'note', 'met', 'sentence', 'orphan'] })
        }
        const pile = untrack(sup_w)
        H.Stuffica_door(Wv, 'refresh', () => {
            H.Stuffica_from(Wv, NAME, pile)
            return H.Stuffica_refresh(Wv, [NAME])
        }).catch((e: any) => console.warn('ArriveFace refresh', e))
    }
    $effect(() => {
        refresh()
        const iv = setInterval(refresh, 1000)
        return () => clearInterval(iv)
    })

    // Show: on a commit, each point's watch flattened by the Supervisor (its line), and what the screen asked to see
    let lines = $derived.by(() => {
        void look.v
        return untrack(() => (loaded() ? H.Stuffica_points(Wv, NAME).map((p: any) => p.c.C && H.Supervisor_line(p.c.C)).filter(Boolean)
            .sort((a: any, b: any) => (a.stage - b.stage) || (a.i - b.i)) : []))
    })
    let asked = $derived.by(() => {
        void look.v
        return new Set(untrack(() => Wv.o({ TheASeem: NAME })[0]?.o({ TheAOpen: 1 }).map((r: any) => String(r.sc.TheAOpen)) ?? []))
    })
    let listing = $derived(asked.has('list'))
    const flip = (what: string) => H.Stuffica_arrive(Wv, { view: NAME, ...(asked.has(what) ? { shut: what } : { open: what }) })

    let world = $derived.by(() => { void look.v; return untrack(sup_w) })
    let ours   = $derived(lines.filter((l: any) => l.key.startsWith('arrive.')))
    let others = $derived(lines.filter((l: any) => !l.key.startsWith('arrive.')))
    let loud   = $derived(others.filter((l: any) => l.tone === 'bad').length)

    // what a row stands on — read off the same rows the probe reads (Ground_arrive_A finds the A), never re-judged here
    function depends(key: string) {
        const watch = world?.o?.({ Watch: key })[0]
        if (!watch || !M) return null
        const sc = watch.sc
        const where = sc.in ? M.o({ H: sc.in })[0] : M
        const A = where && H?.Ground_arrive_A ? H.Ground_arrive_A(where, sc.of || key.replace(/^arrive\./, '')) : null
        const grounds = A ? A.o({ TheACode: 1 }).map((c: any) => ({ name: String(c.sc.TheACode).replace(/^Ground\//, ''),
            dige: c.sc.dige ? String(c.sc.dige).slice(0, 8) : '' })) : []
        const via = A ? Object.fromEntries(A.o({ GroundUsed: 1 }).filter((g: any) => g.sc.via).map((g: any) => [g.sc.GroundUsed, g.sc.via])) : {}
        const meets = sc.by ? `%${sc.by}${sc.until ? ':' + sc.until : ''}` : `%Arrived:${key.replace(/^arrive\./, '')}`
        return { A: sc.of, in: sc.in, found: !!A, meets, moves: sc.moves, grounds, via }
    }
</script>

{#if ours.length}
    <div class="rack">
        <button class="unit" title="the Ground's arrival — click to list" onclick={() => flip('list')}>
            <span class="tag">arrive</span>
            {#each ours as l (l.key)}<span class="chip {l.tone}" class:gaveup={l.gaveup}>{l.mark}{l.key.replace(/^arrive\./, '')}{l.gaveup ? ' stalled' : ''}</span>{/each}
            {#if others.length}<span class="chip more" class:loud={loud}>+{others.length}{loud ? ` ✗${loud}` : ''}</span>{/if}
        </button>
        {#if listing}
        {#each ours as l (l.key)}
            {@const d = asked.has(l.key) ? depends(l.key) : null}
            <div class="row {l.tone}" class:gaveup={l.gaveup}>
                <button class="line" onclick={() => flip(l.key)}>
                    <span class="mark">{l.mark}</span>
                    <span class="says">{l.sentence}</span>
                    {#if l.gaveup}<span class="stalled">stalled</span>{/if}
                </button>
                {#if d}
                    <div class="deps">
                        <div>reads A:{d.A}{d.in ? ` in H:${d.in}` : ''}{d.found ? '' : ' — not stood'} · met by {d.meets}{d.moves ? ` · moving: %${d.moves}` : ''}</div>
                        {#if l.note && !l.done}<div>now: {l.note}</div>{/if}
                        {#if d.grounds.length}
                            <div>stands on: {#each d.grounds as g, i}{i ? ', ' : ''}{g.name}{d.via[g.name] ? ` (via ${d.via[g.name]})` : ''}{/each}</div>
                        {/if}
                    </div>
                {/if}
            </div>
        {/each}
        <div class="foot">
            {#if others.length}
                <span class:loud={loud}>+{others.length} other watch{others.length === 1 ? '' : 'es'}{loud ? ` · ${loud} ✗` : ''}</span>
            {/if}
            <button class="guts" title="the whole roster (SupervisorPanel)" onclick={() => guts = !guts}>{guts ? '▾' : '⋯'}</button>
        </div>
        {#if guts}
            <SupervisorPanel {H} />
        {/if}
        {/if}
    </div>
{/if}

<style>
    .rack { font: 12px/1.4 ui-monospace, monospace; opacity: 0.85; padding: 2px 0 2px 4px; }
    .unit { all: unset; cursor: pointer; display: flex; gap: 0.8em; white-space: nowrap; overflow: hidden; }
    .tag { opacity: 0.5; }
    .chip.moot { opacity: 0.55; }
    .chip.gaveup { color: #b8574a; }
    .chip.more { opacity: 0.6; }
    .line { all: unset; cursor: pointer; display: block; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .mark { display: inline-block; width: 1.3em; opacity: 0.8; }
    .row.moot { opacity: 0.55; }
    .row.gaveup .mark, .stalled { color: #b8574a; }
    .stalled { margin-left: 0.6em; }
    .deps { margin: 1px 0 4px 1.3em; opacity: 0.75; white-space: normal; }
    .foot { display: flex; gap: 0.6em; opacity: 0.6; }
    .loud { color: #b8574a; }
    .guts { all: unset; cursor: pointer; padding: 0 2px; }
</style>
