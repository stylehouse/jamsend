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
    //  QUIET WHEN HEALTHY is the whole design: with nothing wrong this draws one dim line and asks
    //   for no attention.  If you find yourself wanting it to show more at rest, that want belongs in
    //    the roster (register another watch), never here.
    let { n, H } = $props()

    // react off the particle's own version: Supervisor_say writes sc.say|sc.watches|sc.loud every
    //  pass it changes, so the bump that matters always lands on this row.
    let view = $derived.by(() => {
        void n?.version
        void H?.version
        const say = String(n?.sc?.say ?? '')
        const loud = Number(n?.sc?.loud ?? 0)
        const watches = Number(n?.sc?.watches ?? 0)
        const speaking = (n?.c?.speaking ?? []) as any[]
        return { say, loud, watches, speaking }
    })

    // ✗ broken now · ○ hasn't happened yet · ? nobody could look.  Mirrors Supervisor_mark; kept here
    //  only for the per-row list (the headline arrives already marked, in sc.say).
    function mark(w: any) {
        if (w?.sc?.verdict === 'wrong' && w?.sc?.kind === 'milestone') return '○'
        if (w?.sc?.verdict === 'wrong') return '✗'
        if (w?.sc?.verdict === 'unknown') return '?'
        return '○'
    }
    function tone(w: any) {
        if (w?.sc?.verdict === 'wrong' && w?.sc?.kind !== 'milestone') return 'bad'
        if (w?.sc?.verdict === 'unknown') return 'blind'
        return 'todo'
    }
</script>

<div class="sup" class:calm={!view.loud}>
    <div class="head">
        <span class="say">{view.say}</span>
        {#if view.loud > 1}<span class="more">+{view.loud - 1}</span>{/if}
    </div>
    {#if view.loud}
        <ul class="rows">
            {#each view.speaking.slice(0, 6) as w}
                <li class={tone(w)}>
                    <span class="m">{mark(w)}</span>
                    <span class="s">{w?.sc?.sentence ?? ''}</span>
                    {#if w?.sc?.note}<span class="note">{w.sc.note}</span>{/if}
                </li>
            {/each}
        </ul>
    {:else}
        <!-- nothing is wrong: the roster size is the only thing worth knowing at rest, and it is the
             honest answer to "how much is actually being watched" (a big number here is coverage;
             zero means nothing registered, which the headline says out loud). -->
        <div class="rest">{view.watches} watching</div>
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
