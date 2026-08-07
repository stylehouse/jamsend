<script lang="ts">
    // BeatFace — the session's NARRATOR, not a step-ladder.  The human 2026-07-28 found the old face (7
    //  dots + "4/7" + "⏳ a peer to come online" + a creeping bar) "stupid... just a list of assertions or
    //   steps" and asked for "a sentence [that] opens".  So the boot now unfolds as ONE living sentence:
    //    the CURRENT beat spoken as a full present-tense clause (its wait woven into the words, not a bar),
    //     trailing the compact past of everything already stood up.  No dots, no N/7, no progress bar.
    //  Everything read here rides .c (runtime, never snapped): beat number, wait beacon, settled note — so
    //   the recorded fixture never carries a racing countdown (zero drift), and the 1s self-tick (never a
    //    world bump) drives the "still…" creep — the UptimeFace law (no re-tessellate, no spastic movement).
    //  Pointer stance: pointer-events:none (the glass stays pannable); no buttons here.
    let { n, H } = $props()

    // 8 since 2026-08-08: a beat was inserted at 7 (the music runs) and the report moved to 8, because
    //  the Book used to end BEFORE the thing it exists to prove — see Sounditron_todo §0.  These arrays
    //   are 1-indexed with a leading '' and must stay the same length as the beats in Sounditron.g.
    const TOTAL = 8
    // each boot beat in two voices — NOW: the living present clause; PAST: the terse thing it became.
    const NOW = ['', 'the glass is forming', 'the machine is standing up', 'waiting for the relay to answer',
        'looking over who we could reach', 'reaching out for a friend to come online',
        'making sure sound runs here', 'listening for the music to start', 'summing it all up']
    const PAST = ['', 'the glass formed', 'the machine stood up', 'the relay answered',
        'the neighbourhood’s surveyed', 'reached out for a friend', 'sound runs here', 'the music ran', 'summed up']

    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 1000)
        return () => clearInterval(iv)
    })

    let face = $derived.by(() => {
        void H?.version
        void tick
        const c: any = n?.c ?? {}
        const beat = +(c.beat ?? 0)
        const w = c.wait as { for?: string, since?: number, budget?: number } | null | undefined
        let waited = 0, over = false
        if (w && w.since) {
            waited = Math.max(0, (Date.now() - w.since) / 1000)
            over = waited > Math.max(1, +(w.budget ?? 1))
        }
        const done = beat >= TOTAL || !!c.settled
        // the trail: every beat behind us, folded to its terse past voice — the sentence's growing history.
        const trail: string[] = []
        for (let b = 1; b <= Math.min(beat - 1, TOTAL); b++) trail.push(PAST[b])
        const now = (beat >= 1 && beat <= TOTAL) ? NOW[beat] : 'waking up'
        return { beat, now, trail, done, settled: (c.settled as string) ?? '', waited, over }
    })

    const secs = (s: number) => (s < 10 ? s.toFixed(0) : Math.round(s).toString())
</script>

<div class="bf">
    {#if face.done}
        <!-- Boot finished: say NOTHING. The human 2026-08-06: "the 'all set — the machine's alive…' I
             could do without, there's not much room." A narrator that keeps talking after its story has
             ended is just furniture, and here it was furniture parked in the scarcest space on the glass.
             The settled note still earns its line; the "nothing is wrong" reassurance is DiagFace's job
             now, and it says it in three words while also being able to say when something IS wrong. -->
        {#if face.settled}<div class="bf-trail">{face.settled}</div>{/if}
    {:else}
        <!-- the living tail: after a few seconds the clause admits it's "still" at it, and a faint elapsed
             slips in — patience made into words, not a bar the human called stupid. -->
        <div class="bf-now" class:waiting={face.over}>
            {face.waited > 4 ? 'still ' : ''}{face.now}…{#if face.waited > 2}<span class="bf-wt" class:over={face.over}> {secs(face.waited)}s</span>{/if}
        </div>
        {#if face.trail.length}
            <div class="bf-trail">{face.trail.join(' · ')}</div>
        {/if}
    {/if}
</div>

<style>
    .bf {
        pointer-events: none;
        width: max-content;
        max-width: 250px;
        padding: 7px 11px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #dcd8ee;
        text-align: left;
    }
    /* the living clause — the sentence that's currently opening */
    .bf-now { font-size: 12px; font-weight: 700; line-height: 1.3; }
    .bf-now.waiting { color: #e6c48a; }
    .bf-wt { font-size: 10px; font-weight: 400; opacity: 0.6; font-variant-numeric: tabular-nums; }
    .bf-wt.over { color: #e0a86a; opacity: 0.9; }
    /* the trail of what already came up — small, quiet, wraps as it grows */
    .bf-trail { font-size: 9px; opacity: 0.5; margin-top: 4px; line-height: 1.35; font-style: italic; }
</style>
