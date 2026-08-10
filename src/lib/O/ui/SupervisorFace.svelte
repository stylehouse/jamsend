<script lang="ts">
    // SupervisorFace — THE ONE SANITY CELL (the owner 2026-08-09: *"I think I want to hide most of
    //  the interface we have so far. transfer and etc. I just don't care.  but I do care about having
    //   some overall sanity checking thing going on"*).  This is that cell, and the thing it replaces
    //    is a rank of idle HUDs each saying nothing at full volume.
    //  Mounted by the glass on the %Supervisor row (imposed by mainkey, glass_faces.ts — no snap byte).
    //
    //  IT IS DUMB ON PURPOSE.  Every decision — which watches are worth saying, in what order, with
    //   what glyph — is made in Supervisor.g and read off `n.c.speaking` / `n.sc.say`.  A face that
    //    re-derived the order would be a second opinion about health, and the first thing to drift.
    //
    //  IT IS USUALLY NOT HERE AT ALL (2026-08-10, the owner re-aiming the three surfaces: *"the
    //   Supervisor cell is smaller and simpler, perhaps not even there if nothing is out of line"*).
    //    Quiet-when-healthy taken all the way is ABSENCE: `Sounditron_glass` only grapples the
    //     %Supervisor row when the model says something is `amiss` (or under show_diag), because a
    //      cell costs a SEAT and the glass has a fixed number of them.  So this face renders almost
    //       exclusively in its loud state, and the calm branch below is what a developer sees with
    //        diagnostics open — not what a listener sees at rest.
    //  ITS SIBLINGS: the Butler is the mid-complexity log-looking one at boot; SupervisorPanel (▦) is
    //   the whole bollocking.  This one is the smallest and simplest of the three, and must stay so.
    let { n, H } = $props()

    // react off the particle's own version: Supervisor_say writes sc.say|sc.watches|sc.loud|sc.amiss
    //  every pass it changes, so the bump that matters always lands on this row.
    //  ROWS COME PRE-MARKED from `Supervisor_say` (`c.amiss_lines`, flattened by Supervisor_line).
    //   This face carried its OWN mark()/tone() pair until 2026-08-10 — two copies of one judgement,
    //    in the one surface whose entire value is being trusted at a glance.
    let view = $derived.by(() => {
        void n?.version
        void H?.version
        const say = String(n?.sc?.say ?? '')
        const loud = Number(n?.sc?.loud ?? 0)
        const amiss = Number(n?.sc?.amiss ?? 0)
        const watches = Number(n?.sc?.watches ?? 0)
        const rows = (n?.c?.amiss_lines ?? []) as any[]
        return { say, loud, amiss, watches, rows }
    })
</script>

<div class="sup" class:calm={!view.amiss}>
    <div class="head">
        <span class="say">{view.say}</span>
        {#if view.amiss > 1}<span class="more">+{view.amiss - 1}</span>{/if}
    </div>
    {#if view.rows.length}
        <!-- THREE, not six. This is the smallest of the three surfaces and a cell that lists six
             failures has become the panel in a smaller font; the count in the head says how many
             more there are, and ▦ is where you go to read them. -->
        <ul class="rows">
            {#each view.rows.slice(0, 3) as l (l.key)}
                <li class={l.tone}>
                    <span class="m">{l.mark}</span>
                    <span class="s">{l.sentence}</span>
                    {#if l.note}<span class="note">{l.note}</span>{/if}
                </li>
            {/each}
        </ul>
    {:else}
        <!-- nothing is amiss — which normally means this cell is not on the glass at all, so this is
             the show_diag view. The roster size is the only thing worth knowing at rest, and it is
             the honest answer to "how much is actually being watched" (zero means nothing registered,
             which the headline says out loud). -->
        <div class="rest">{view.watches} watching{#if view.loud} · {view.loud} outstanding{/if}</div>
    {/if}
</div>

<style>
    /* THE NATURAL BOX IS THE ASK.  The glass runs with the NEED FLOOR on (Sounditron's commission),
       so Vytui measures this element's natural box after a flush and Vyto_express floors the cell at
       need × 1.15 — which means a face that measures small GETS a small cell no matter what else it
       does.  The first cut of this face was compact-at-all-times and came out a speck beside %Now.
       So the two states ask for genuinely different room, and the size difference IS the signal:
       calm asks for a readable minimum, loud asks for enough to actually read the failures in. */
    .sup { display: flex; flex-direction: column; gap: .25em; width: 100%; height: 100%;
           padding: .35em .5em; box-sizing: border-box; overflow: hidden;
           min-width: 11em; min-height: 3em;
           font-size: .8em; line-height: 1.25; color: #e8e4dc; }
    /* MEASURED, NOT REASONED: at 24em/8em this cell came out 401×134 — the biggest mold on the glass,
       against the music's 74×99.  The floor had buried the dial (the need floor sets env_area
       directly, so a min-width IS a size demand and it outranks any dose).  15em/5em puts loud at
       roughly 2× the music, which is what "rivals" meant. */
    .sup:not(.calm) { min-width: 15em; min-height: 5em; font-size: .9em; }
    .sup.calm { color: #8d8a84; }
    .head { display: flex; align-items: baseline; gap: .4em; }
    .say { flex: 1 1 auto; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .sup:not(.calm) .say { color: #ffd9a8; }
    .more { flex: 0 0 auto; opacity: .6; font-variant-numeric: tabular-nums; }
    .rows { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: .1em;
            overflow: hidden; }
    .rows li { display: flex; gap: .35em; align-items: baseline; min-width: 0; }
    .m { flex: 0 0 auto; width: 1em; text-align: center; }
    .s { flex: 0 1 auto; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .note { flex: 0 1 auto; opacity: .55; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    li.bad   { color: #ff9b8a; }
    li.todo  { color: #cfc8bb; }
    li.blind { color: #9aa5b5; }
    .rest { opacity: .5; }
</style>
