<script module lang="ts">
    import type { TheC } from "$lib/data/Stuff.svelte"

    // storying_run — the Storying kind's verdict computer.  NOT pumped: Lies calls it on an EVENT
    //  (Lies_reflect_storying — when a run_result lands) and once on Waft load, never every tick.
    //   find the matching run_result:
    //     %of_Book → by book field, latest by at  (one Book runs several docks)
    //     %of_dock → by dock path
    //   stamp funk.c.verdict  (NOT req%ok — "the closure ran" ≠ "the test passed")
    //     phase: good (every step) | bad | working (no result yet)
    //   off-snap, self-contained C ops — the host (Waft) never sees any of this.
    export function storying_run(_host: TheC, funk: TheC, ww: TheC): void {
        const book = funk.sc.of_Book as string | undefined
        const path = funk.sc.of_dock as string | undefined
        let rr: TheC | undefined
        if (book) {
            rr = (ww.o({ run_result: 1 }) as TheC[])
                .filter(r => r.sc.book === book)
                .sort((a, b) => Number(b.sc.at ?? 0) - Number(a.sc.at ?? 0))[0]
        } else if (path) {
            rr = ww.o({ run_result: 1, path })[0] as TheC | undefined
        } else return
        const pass  = rr ? Math.round(Number(rr.sc.ok_pct ?? (rr.sc.ok ? 1 : 0)) * Number(rr.sc.done ?? 1)) : 0
        const total = rr ? Number(rr.sc.done ?? 1) : 0
        const phase = !rr ? 'working' : (total > 0 && pass === total) ? 'good' : 'bad'
        const dige  = rr?.sc.dige as string | undefined
        const prev  = funk.c.verdict as { phase?: string, pass?: number, total?: number, dige?: string } | undefined
        if (prev && prev.phase === phase && prev.pass === pass && prev.total === total && prev.dige === dige) return
        funk.c.verdict = { phase, pass, total, dige }
        funk.bump_version()
    }
</script>

<script lang="ts">
    // Storying.svelte — the Storying Funkcion KIND: a Credence test-light.  Bound to a
    //  Book (%of_Book) or a dock (%of_dock), it shows that target's last verdict as
    //   ✓ green / ✗ red / ◴ working, and a click runs it.  Waft hosts this component
    //    knowing nothing about Stories, verdicts, or run_results — all of that lives here
    //     and in storying_run above; the host only mounts the kind and passes the funk.
    import type { House } from "$lib/O/Housing.svelte"
    // TheC comes from the module script above (its imports are in scope here).

    let { H, funk, raw = false }: { H: House, funk: TheC, raw?: boolean } = $props()

    // funk.c.verdict is stamped off-snap by storying_run (driven by Lies_reflect_storying when a run_result lands); track funk.version.
    let v     = $derived((() => { void funk.version; return (funk.c.verdict as any) ?? { phase: 'working' } })())
    let bound = $derived((funk.sc.of_Book ?? funk.sc.of_dock) as string | undefined)
    // brand_new — a Book that has NEVER recorded a green run wears ✦ NEW until its first green.
    //  Authored as %brand_new (rides `1`) on the board's Storying cell; Lies_reflect_storying strips
    //   it on the first green verdict.  Never-green is the DURABLE truth (no NNN.snap on disk) and
    //    'working' can't carry it — run_result is TTL'd, so a fresh board reads every cell as working.
    let is_new = $derived((() => { void funk.version; return !!funk.sc.brand_new })())
    // the light shown: a real red|green verdict always wins; else NEW if never-green; else awaiting.
    let disp   = $derived(v.phase === 'good' ? 'good' : v.phase === 'bad' ? 'bad' : is_new ? 'new' : 'working')
    const leaf = (p: any) => String(p ?? '').split('/').pop()

    // A dock cell fires the "run it now" intent Esc does (Lies_run_arm → runner runs off the
    //  Rungo).  A Book cell asks the editor→runner "become Book" remote control (e_Lies_become_book:
    //   editor ships the frame, runner does resetStory{Book}).  Either way ack optimistically.
    function strike() {
        if (funk.sc.of_dock)      H.i_elvisto('Lies/Lies', 'Lies_run_arm',     { path: funk.sc.of_dock as string })
        else if (funk.sc.of_Book) H.i_elvisto('Lies/Lies', 'Lies_become_book', { book: funk.sc.of_Book as string, needAC: funk.sc.needAC, needsFSA: funk.sc.needsFSA })
        funk.c.verdict = { ...(funk.c.verdict as any ?? {}), phase: 'working' }
        funk.bump_version()
    }
</script>

{#if raw}
    <div class="fk-raw">Funkcion:{funk.sc.Funkcion}{bound ? ` → ${bound}` : ''}</div>
{:else}
    <button class="fk fk-{disp}" onclick={strike}
        title="Credence cell · click to run · {bound ?? 'unbound'} — {disp === 'good' ? `green, ${v.pass}/${v.total} steps` : disp === 'bad' ? `red, ${v.pass}/${v.total} steps` : disp === 'new' ? 'never recorded a green run — brand new' : 'awaiting a run'}{v.dige ? ` @ ${String(v.dige).slice(0,8)}` : ''}">
        <span class="fk-ico">{disp === 'good' ? '✓' : disp === 'bad' ? '✗' : disp === 'new' ? '✦' : '◴'}</span>
        <span class="fk-name">{funk.sc.of_Book ?? funk.sc.Funkcion}</span>
        {#if disp === 'new'}<span class="fk-newtag">NEW</span>{/if}
        {#if v.total}<span class="fk-steps">{v.pass}/{v.total}</span>{/if}
        {#if funk.sc.of_dock}<span class="fk-dock">{leaf(funk.sc.of_dock)}</span>{/if}
    </button>
{/if}

<style>
    /* the test-light — reuses the Langui ✓/✗/◴ good/bad/working idiom. */
    .fk {
        display: inline-flex; align-items: center; gap: 0.35rem; margin: 0.15rem 0;
        padding: 0.15rem 0.5rem; border-radius: 5px; cursor: pointer;
        border: 1px solid #2a2a3a; background: #14141e;
        font-family: monospace; font-size: 0.74rem; color: #99a;
        transition: filter 0.1s, transform 0.06s;
    }
    .fk:hover  { filter: brightness(1.3); }
    .fk:active { transform: translateY(1px); }
    .fk-ico   { font-size: 0.9rem; line-height: 1; }
    .fk-name  { color: #c4c4d4; }
    .fk-steps { font-variant-numeric: tabular-nums; }
    .fk-dock  { color: #667; font-size: 0.7rem; }
    .fk-good    { border-color: rgba(106, 208, 160, 0.4); background: rgba(106, 208, 160, 0.08); color: #6ad0a0; }
    .fk-good    .fk-name { color: #8fe4c0; }
    .fk-bad     { border-color: rgba(255, 136, 136, 0.4); background: rgba(255, 136, 136, 0.08); color: #f88; }
    .fk-bad     .fk-name { color: #f9a; }
    .fk-working { border-color: #3a3420; color: #c4a86a; }
    /* brand-new: never recorded a green run — amber ✦ with a NEW pill, distinct from ◴ working. */
    .fk-new     { border-color: rgba(224, 176, 96, 0.5); background: rgba(224, 176, 96, 0.09); color: #e0b060; }
    .fk-new     .fk-name { color: #f0c887; }
    .fk-newtag  { font-size: 0.6rem; font-weight: bold; letter-spacing: 0.05em; color: #1a1408; background: #e0b060; padding: 0.02rem 0.28rem; border-radius: 3px; }
    .fk-raw {
        font-family: monospace; font-size: 0.74rem; color: #8a7a5a; padding: 0.1rem 0.2rem;
    }
</style>
