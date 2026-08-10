<script lang="ts">
    // SupervisorPanel — THE GUTS, outside the glass (the owner 2026-08-10: *"the one in the cell must
    //  be very simple and small and have anything we want in the UX, the UIs:Supervisor can have all
    //   the rest of the guts of it, for devs"*).
    //
    //  THE THREE SURFACES, and which one this is:
    //     SupervisorFace  — the Vyto cell.   Tiny, quiet while well.  The listener's.
    //     Butler          — the arrival.     The permission tap + the arc.  Also the listener's.
    //     this            — UIs:'Supervisor'. Every row including the healthy ones, the probe NAMES,
    //                                          the latches, the patience clock, the notice ring and
    //                                           the reporting ladder.  A developer's instrument, and
    //                                            it should show what the other two would be wrong to.
    //
    //  IT JUDGES NOTHING — `Supervisor_lines` decides the order, the mark and the tone (see that
    //   function's header: this panel used to carry its own copy of all three, which is how three
    //    surfaces end up with three opinions about which row is worst).  What this adds is DETAIL the
    //     others must not show: the probe method name, the arming reason, the raw kind.
    //
    //  PROPS: hosts mount registered UIs as `<svelte:component this={ui.sc.component} H={house} />` —
    //   `H` and nothing else.  An earlier cut asked for an `n` it was never handed, so `n.c.up` was
    //    undefined and it printed "nothing registered" over a full roster.  `n` stays optional for a
    //     host that does pass one.
    let { n = null, H = null }: { n?: any, H?: any } = $props()

    // `.c.notices` is a plain array and `.c.deadline` a wall clock — neither bumps a version, so the
    //  live half of this panel polls, exactly as the Butler does and for the same reason.
    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 500)
        return () => clearInterval(iv)
    })

    // Find the world the way the model does (Supervisor_w: top House → A:Supervisor → w:Supervisor)
    //  rather than hardcoding a House.  `n.c.up` wins when a host does pass a row, so this can't be
    //   wrong about which Supervisor it is showing on a page that somehow has two.
    let world = $derived.by(() => {
        void n?.version
        void H?.version
        void tick
        if (n?.c?.up) return n.c.up
        const M = H?.top_House ? H.top_House() : H
        return M?.o?.({ A: 'Supervisor' })[0]?.o?.({ w: 'Supervisor' })[0] ?? null
    })

    // THE PREFS, and this panel is where they come BACK ON. The Butler carries the off-switch (it is
    //  where you are annoyed by the screen); a switch that can only ever be turned off is a trap, and
    //   a dev panel is exactly the "semi-hidden" place to find the other half of it. Read in an
    //    $effect, not the derived below, because the first read mirrors the House stash into a
    //     particle — a derived that mutates is a derived that will one day loop.
    const PREFS = [
        { key: 'butler.quiet', label: 'skip the arrival screen', note: 'the Butler does not hold this tab' },
    ]
    let prefs: Record<string, number> = $state({})
    $effect(() => {
        void tick
        const w = world
        if (!w || !H?.Supervisor_pref) return
        for (const p of PREFS) prefs[p.key] = H.Supervisor_pref(w, p.key)
    })
    function flip(key: string) {
        const w = world
        if (!w || !H?.Supervisor_pref_set) return
        prefs[key] = H.Supervisor_pref_set(w, key, !prefs[key])
    }

    let view = $derived.by(() => {
        void tick
        const w = world
        void w?.version
        const row = (w?.o?.({ Supervisor: 1 }) ?? [])[0] ?? n
        void row?.version
        const cfg = (w?.o?.({ Logging: 1 }) ?? [])[0]
        return {
            found: !!w,
            say: String(row?.sc?.say ?? ''),
            loud: Number(row?.sc?.loud ?? 0),
            lines: (w && H?.Supervisor_lines) ? H.Supervisor_lines(w) : [],
            dials: (w && H?.Supervisor_dials) ? H.Supervisor_dials(w) : [],
            notices: (w && H?.Supervisor_noticed) ? [...H.Supervisor_noticed(w)].reverse() : [],
            log: cfg ? {
                dormant: String(cfg.sc.dormant ?? ''),
                trouble: String(cfg.sc.trouble ?? ''),
                sent: String(cfg.sc.sent ?? '0'),
                every: String(cfg.sc.every ?? ''),
                retry: String(cfg.sc.retry_in ?? ''),
            } : null,
        }
    })

    function ago(at: number) {
        const s = Math.max(0, Math.round((Date.now() - at) / 1000))
        return s < 60 ? s + 's' : Math.round(s / 60) + 'm'
    }
</script>

<div class="panel">
    <div class="head" class:calm={!view.loud}>
        <span class="title">Supervisor</span>
        <span class="say">{view.say}</span>
    </div>

    <!-- THE DIALS — the overall states, above the watches, because "have we got a Pier" is the
         question you arrive with and "is the share beat advancing" is the one you arrive at. Each
         reading already carries its own PARTS from the model ("2 sealed · 1 sealing"); a face that
         reduced that to a tick would be re-committing the half-seal bug this dial exists for. -->
    {#if view.dials.length}
        <div class="dials">
            {#each view.dials as d (d.key)}
                <div class="dial {d.state}">
                    <span class="m">{d.mark}</span>
                    <span class="lab">{d.label}</span>
                    <span class="read">{d.reading}</span>
                </div>
            {/each}
        </div>
    {/if}

    <!-- TWO DIFFERENT EMPTIES, and conflating them wasted a round: "I cannot find a Supervisor at
         all" and "I found one and its roster is empty" point at opposite halves of the machine.
         Same rule as the model's unknown-vs-wrong split. -->
    {#if !view.found}
        <div class="empty">no w:Supervisor on this House — Supervisor_up has not run here</div>
    {:else if !view.lines.length}
        <div class="empty">nothing registered — nothing is watched</div>
    {:else}
        <table>
            <tbody>
                {#each view.lines as l (l.key)}
                    <tr class={l.tone}>
                        <td class="m">{l.mark}</td>
                        <td class="k">{l.key}</td>
                        <td class="s">
                            {#if l.arrival}<span class="flag" title="the declared ARRIVAL — the Butler holds the screen until this is met">⚑</span>{/if}
                            {l.sentence}
                            <!-- the NOTE is the attribution — "no A:Vyto in any of 2 House(s)" is a
                                 diagnosis, "?" is a riddle. §5: attribution before action. -->
                            {#if l.note}<span class="note">{l.note}</span>{/if}
                            <!-- the ADVICE is what a LISTENER is told once we gave up on this claim.
                                 It shows here too so a dev can see the sentence that reached them
                                 without having to reproduce the give-up. -->
                            {#if l.advice}<span class="advice">{l.gaveup ? '→ ' : '(on give-up) '}{l.advice}</span>{/if}
                        </td>
                        <!-- the probe NAME is guts, and guts is this panel's job: it is the one thing
                             that turns "? no probe named X" into a grep. Neither the cell nor the
                             Butler may show it — it is not a sentence for a listener. -->
                        <td class="fn">{l.fn}</td>
                        <td class="kind">
                            {#if l.waiting}waiting {l.left}s{#if l.because} ({l.because}){/if}
                            {:else if l.kind === 'milestone'}{l.met ? 'done' : 'milestone'}
                            {:else}standing{/if}
                        </td>
                    </tr>
                {/each}
            </tbody>
        </table>
    {/if}

    <!-- THE NOTICE RING — what actually happened, newest first (the owner: *"Supervisor should notice
         any interesting thing happen"*). Entirely on `.c`, so it costs no snap and churns no fixture;
         this is the only surface that shows it, because it is history and the other two are about
         now. -->
    {#if view.notices.length}
        <div class="noticed">
            {#each view.notices as ev}
                <div class="ev">
                    <span class="when">{ago(ev.at)}</span>
                    <span>{ev.sentence}{#if ev.n > 1} ×{ev.n}{/if}</span>
                </div>
            {/each}
        </div>
    {/if}

    {#if view.found}
        <div class="prefs">
            {#each PREFS as p (p.key)}
                <button class="pref" class:on={prefs[p.key]} onclick={() => flip(p.key)} title={p.note}>
                    <span class="m">{prefs[p.key] ? '☑' : '☐'}</span>{p.label}
                </button>
            {/each}
        </div>
    {/if}

    {#if view.log}
        <div class="log">
            reporting:
            {#if view.log.dormant}<span class="dim">dormant — {view.log.dormant}</span>
            {:else if view.log.trouble}<span class="bad">{view.log.trouble}{#if view.log.retry} · retry in {view.log.retry}s{/if}</span>
            {:else}<span class="dim">{view.log.sent} sent · every {view.log.every}s</span>{/if}
        </div>
    {/if}
</div>

<style>
    .panel { font-size: .85em; line-height: 1.35; color: #ddd8d0; padding: .5em .6em;
             border: 1px solid #3a3a3a; border-radius: 4px; background: #1b1b1b; overflow-x: auto; }
    .head { display: flex; gap: .6em; align-items: baseline; margin-bottom: .4em;
            padding-bottom: .3em; border-bottom: 1px solid #333; }
    .title { font-weight: 600; letter-spacing: .04em; flex: 0 0 auto; }
    .say { flex: 1 1 auto; min-width: 0; color: #ffd9a8; }
    .head.calm .say { color: #7f8a7f; }
    table { border-collapse: collapse; width: 100%; }
    td { padding: .12em .4em .12em 0; vertical-align: top; }
    .m { width: 1.2em; text-align: center; }
    .k { color: #8fa6c4; white-space: nowrap; font-family: ui-monospace, monospace; font-size: .92em; }
    .s { width: 100%; }
    .kind { white-space: nowrap; opacity: .5; font-size: .9em; }
    .fn { white-space: nowrap; opacity: .45; font-size: .85em;
          font-family: ui-monospace, monospace; }
    .note { display: block; opacity: .55; font-size: .92em; }
    .advice { display: block; font-size: .92em; color: #9fc4dd; }
    .flag { color: #d8c98a; margin-right: .25em; }
    .prefs { margin-top: .45em; padding-top: .3em; border-top: 1px solid #333;
             display: flex; flex-wrap: wrap; gap: .4em; }
    .pref { background: none; border: 1px solid #3a3a3a; border-radius: 3px; cursor: pointer;
            color: #9aa5b5; font: inherit; font-size: .95em; padding: .15em .5em; }
    .pref .m { margin-right: .35em; }
    .pref.on { color: #d8c98a; border-color: #5a5240; }
    tr.good  .m { color: #7fbf7f; }
    tr.bad   { color: #ff9b8a; }
    tr.todo  { color: #cfc8bb; }
    tr.blind { color: #9aa5b5; }
    tr.waiting { color: #d8c98a; }
    .empty { opacity: .6; }
    .dials { display: flex; flex-direction: column; gap: .1em; margin-bottom: .45em;
             padding-bottom: .35em; border-bottom: 1px solid #333; }
    .dial { display: flex; gap: .5em; align-items: baseline; }
    .dial .m { width: 1.2em; text-align: center; flex: 0 0 auto; }
    .dial .lab { flex: 0 0 8em; opacity: .65; }
    .dial .read { flex: 1 1 auto; min-width: 0; }
    .dial.yes .m     { color: #7fbf7f; }
    .dial.part       { color: #d8c98a; }
    .dial.no         { color: #b6b0a6; }
    .dial.unknown    { color: #9aa5b5; }
    .noticed { margin-top: .45em; padding-top: .3em; border-top: 1px solid #333;
               display: flex; flex-direction: column; gap: .1em; opacity: .8; font-size: .95em; }
    .ev { display: flex; gap: .5em; }
    .when { flex: 0 0 2.6em; text-align: right; opacity: .45;
            font-variant-numeric: tabular-nums; font-size: .9em; }
    .log { margin-top: .45em; padding-top: .3em; border-top: 1px solid #333; opacity: .85; }
    .dim { opacity: .6; }
    .bad { color: #ff9b8a; }
</style>
