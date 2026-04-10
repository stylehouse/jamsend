<script lang="ts">
    // Ghost: Story — mounts into the parent House via M.eatfunc({...}).
    // All methods below become House instance methods once eatfunc completes.
    //
    // ── This / The duality ───────────────────────────────────────────────────
    //
    //   This  — what is spontaneously happening right now, this session.
    //           Particles live as direct children of w, the Story work particle.
    //           Uppercase key: {Step:N}
    //           Carries: got_snap, exp_snap, dige, ok, hollow, accepted, saved.
    //           Has {watched:'ave'} in sc so enroll_watched() picks it up and
    //           any version bump on a Step is visible to StoryRun as a reactive
    //           change, even though the Step is not inside the ave container.
    //
    //   The   — the canonical record; what was on disk plus what was accepted.
    //           Lives in w.c.The, a separate C-tree never walked by snap or saved.
    //           Direct children are heterogeneous buckets:
    //             {step:N, dige}              — one per recorded step
    //               /{note:1, frontier:1}     — singleton roaming note
    //               /{note:1, todo:"text"}    — user annotation
    //             {TimeSpool:1}               — persistent timing samples
    //               /{TimeTotal:'beliefs', avg}
    //                 /{sample, at}           — last 10 by .at, oldest evicted
    //           Mutation goes here, save writes here, decode rehydrates here.
    //           This is never reflected back into The — the only direction is
    //           decode-on-load, which puts disk → The.
    //
    //   This is analogous to the local / remote duality in git, but named to
    //   read naturally in prose: "This step" = live session, "The step" = record.
    //   The idiom is reusable anywhere there is a stored-thing ↔ live-thing joint.
    //
    // ── Swatches ─────────────────────────────────────────────────────────────
    //
    //   w/%watched:swatches  — one {note_coloring:"type", color:"#hex"} per key.
    //   Built lazily by ensure_swatch() before any note of that type reaches the UI.
    //   Fatal for the UI to encounter a note type with no swatch.
    //
    // ── exactly() — the wildcard dodge ──────────────────────────────────────
    //
    //   Numeric 1 is the wildcard value in this C system:
    //     o({Step:1})            — matches ALL particles that have a "Step" key
    //     o(exactly({Step:1}))   — matches ONLY Step === 1 (literal number one)
    //
    //   exactly() (from Y.ts) stringifies all values so the C engine sees a
    //   non-wildcard string and does a literal equality test.  Future language
    //   tooling may fold this into o()'s second argument.
    //
    // ── UI registration ──────────────────────────────────────────────────────
    //
    //   Story_plan registers StoryRun into H:Story/%watched:UIs so Otro can
    //   mount it automatically alongside whichever house it finds it on.
    //   The same container holds Cytui (registered by w:Cyto on its first tick).
    //   H.UIs = C.o({}) is populated by enroll_watched() on every bump.

    let spect = `
    
    further design:
      assertions, pointers
       crawl code forward by compiling pauses everywhere
      the UI
       with its diff space
        wants a multiplex of Snap:*-possible data channels
         interfaces to inflate This**
           is what some notes said around stylehouse / ive/The
            see also &complace, claude could perhaps straighten it out
          and suggest things to become part of The**
           the good things promoted
         that may just be in memory for researching things
        horizontal scroll
       pips
        show tiny grains for business as below
        have an open-Snap side or a graph-play side to click


    here's some claudables for going beyond this level of complicated.

        I want to hide the self,round in the Snap:H too
        but when that raises more than one since the last Story, that's %interesting:elvis_reverb, or something...

        perhaps we want to make an assertion, that finds that thing (below A or w - put the same matching object in two other matchings)

        checks if its increased more than one

        and puts an extra little bright green dot in the pip, to indicate elvis made things to do and did them.





        we have blocked off its      {"mung":["id"]}mo:main,interval:3.6 when under H:Story haven't we?

         we basically synthesize it when we want to.

        we should be matching every elvis that happens, so we can pause after one and record everything, then go on, to pull apart the action and really understand things

        at the moment  we have Snap:H, Snap:cytowave...

        we could be defining a template of stuff to get up to at snaptime. we do this trace thing as well which is kind of another channel of test data stuff, that we don't store.

        so into that we could be adding a nice list of elvises that happened



        so I'd like to incorporate the idea of info channels ... somehow we pass out information from H%Run...
        was a bunch of this in 
    
    
    
    







    
    `

    import { objectify, TheC }            from "$lib/data/Stuff.svelte"
    import type { TheD }                  from "$lib/mostly/Selection.svelte"
    import { Selection, Travel }          from "$lib/mostly/Selection.svelte"
    import { depeel, peel, dig, exactly, ex }               from "$lib/Y.svelte"
    import { onMount }                    from "svelte"
    import { now_in_seconds, now_in_seconds_with_ms }     from "$lib/p2p/Peerily.svelte"
    import { ANSWER_CALLS_TICK_MS, House } from "$lib/O/Housing.svelte"
    import StoryRun                       from "$lib/O/ui/StoryRun.svelte"

    let { M } = $props()
    let V = { Story: 0 }   // set Story: 1 here to enable drive/analysis debug logs

    // ── colour palette ───────────────────────────────────────────────────────
    // Assigned in first-seen order via ensure_swatch().
    // Frontier always gets FRONTIER_COLOR.  Prepend an entry here to reserve a
    // colour for a well-known type before the auto-assign loop reaches it.
    const NOTE_PALETTE   = ['#7bc8a4','#7ab0d4','#c9a96e','#b08fc8','#d49a7a','#7abfb8','#a8b87a','#c87aaa','#a07878']
    const FRONTIER_COLOR = '#c55'

    onMount(async () => {
    await M.eatfunc({

//#region The helpers — canonical disk-backed toc tree

    step_c(container: TheC, n: number, key: string): TheC {
        // Universal find-or-create for any step-keyed particle.
        // Works for both The/{step:n} and This/{Step:n} (and any future container).
        // Always bumps container version on creation so watchers see the new particle.
        //
        //   step_c(w.c.The,  n, 'step')  — The's canonical record
        //   step_c(w.c.This, n, 'Step')  — This's live session record
        //
        // exactly() stringifies n → "n"; Stuff coerces it back to a number in o_kv,
        // so this correctly finds {step:2} regardless of whether n is number or string.
        const sc: Record<string,any> = {}
        sc[key] = n
        const existing = container.o(exactly(sc))[0]
        if (existing) return existing
        const c = container.i(sc)
        container.bump_version()
        return c
    },

    The_step(w: TheC, n: number): TheC {
        return this.step_c(w.c.The, n, 'step')
    },

    The_step_dige(w: TheC, n: number): string | undefined {
        return (w.c.The)?.o(exactly({ step: n }))[0]?.sc.dige
    },

    The_frontier(w: TheC): number {
        // read the frontier step number from the {note:1,frontier:1} particle.
        // o({note:1,frontier:1}) — both values are wildcard 1, matching any particle
        // that has both "note" and "frontier" keys.  That is exactly what we want.
        // returns 0 when absent (clean / no unreviewed mismatch).
        for (const s of (w.c.The).o({ step: 1 })) {
            if ((s.o({ note: 1, frontier: 1 })).length > 0) {
                return s.sc.step
            }
        }
        return 0
    },

    The_set_frontier(w: TheC, n: number) {
        // move the singleton {note:1,frontier:1} note to step n, or clear (n=0).
        // "thing.drop(thing)" — the particle drops itself; the container checks
        // liveness before returning particles, so the old reference is immediately
        // invalidated and will not appear in future queries.
        const The = w.c.The
        for (const s of The.o({ step: 1 })) {
            for (const fr of s.o({ note: 1, frontier: 1 })) {
                fr.drop(fr)
            }
        }
        if (n > 0) {
            this.The_step(w, n).i({ note: 1, frontier: 1 })
            this.ensure_swatch(w, 'frontier')
        }
    },


//#region This helpers — live session step particles and colour swatches

    i_step(w: TheC, n: number): TheC {
        // find-or-create the live This/{Step:n} particle inside w.c.This.
        // w.c.This is the session step container, wired in Story_plan/Story().
        // Delegates to step_c which bumps version on creation.
        return this.step_c(w.c.This, n, 'Step')
    },

    step_i_note(w: TheC, n: number, note_sc: Record<string,any>, mode: 'add'|'move'|'remove') {
        // Unified note mutation on The/%step:N.  Always calls story_analysis().
        //
        //   'add'    — add note_sc as a new child of step n; ensure its swatch.
        //   'move'   — remove note_sc from every step first, then add to step n.
        //              Use for singleton notes (frontier) that must be unique globally.
        //   'remove' — drop the first matching note from step n.
        //
        // note:1 is always prepended so it appears first in any data UI display,
        // and if the caller already included it the spread is benign.
        // e.g. step_i_note(w, 3, {frontier:1}, 'move')
        //      → note_sc becomes {note:1, frontier:1}
        //
        // .matches() is used for removal — it honours the C wildcard rules,
        // which is correct here: we want "find the note that looks like this sc".
        note_sc = { note: 1, ...note_sc }

        const H   = this as House
        const The = w.c.The

        if (mode === 'move' || mode === 'remove') {
            for (const s of The.o({ step: 1 })) {
                for (const existing of s.o({ note: 1 })) {
                    if (existing.matches(note_sc)) {
                        existing.drop(existing)   // thing.drop(thing)
                        break
                    }
                }
            }
        }

        if (mode === 'add' || mode === 'move') {
            H.The_step(w, n).i(note_sc)
            for (const key of Object.keys(note_sc).filter(k => k !== 'note')) {
                H.ensure_swatch(w, key)
            }
        }

        H.story_analysis(w)
    },

    ensure_swatch(w: TheC, type: string) {
        // Ensure {note_coloring:type, color:"#hex"} exists in swatchC.
        // swatchC is cached on w.c from Story_plan.
        // Must be called before any note of a new type reaches story_analysis().
        const sw = w.c.swatchC
        const all_sw = sw.o({ note_coloring: 1 })
        if (all_sw.find(s => s.sc.note_coloring === type)) return

        const non_frontier = (sw.o({ note_coloring: 1 }))
            .filter(s => s.sc.note_coloring !== 'frontier')
        const color = type === 'frontier'
            ? FRONTIER_COLOR
            : NOTE_PALETTE[non_frontier.length % NOTE_PALETTE.length]
        sw.i({ note_coloring: type, color })
    },


//#region snap codec
    // ── encode_toc_snap ───────────────────────────────────────────────────────
    // Walk The/** with Travel for infinite depth. The only inline rule is the
    // %step skip below — every other particle (TimeSpool, TimeTotal, sample,
    // notes, future siblings of step) is encoded by simply rendering its sc and
    // recursing into its children at depth+1. Adding a new bucket under The is
    // therefore zero-code: the codec already round-trips it.
    //
    // %step rule: a step is just {step:N, dige}. The sibling NNN.snap file is
    // implied by step:N — no snap_link field on disk, the decoder reconstructs
    // it (or any code that needs it just calls pad(N)+'.snap'). Steps with
    // neither dige nor notes are skipped (lean toc.snap, matches old behaviour).
    //
    // depth-0 sort: steps come first in numeric order, other buckets after, so
    // toc.snap reads the same way as before with TimeSpool tucked at the bottom.
    async encode_toc_snap(w: TheC): Promise<string> {
        const book  = w.sc.Book
        const lines: string[] = [this.enL({ d: 0, stringies: { story: book } })]
        const The   = w.c.The as TheC

        const T = new Travel()
        await T.dive({
            n:        The,
            match_sc: {},
            each_fn:  async (n: TheC, T: Travel) => {
                const depth = T.c.path.length - 1

                if (depth === 0) {
                    // The itself — story root already emitted above.
                    // Sort children: %step ascending, then everything else.
                    const children = n.o({}) as TheC[]
                    const steps  = children.filter(c => c.sc.step != null)
                        .sort((a, b) => (a.sc.step as number) - (b.sc.step as number))
                    const others = children.filter(c => c.sc.step == null)
                    T.sc.more = [...others,...steps]
                    return
                }

                // %step skip rule: nothing worth saving for this step
                if (n.sc.step != null && !n.sc.dige && !(n.o({ note: 1 }).length)) {
                    T.sc.not = 1
                    return
                }

                lines.push(this.enL({ d: depth, stringies: { ...n.sc } }))
            },
        })

        return lines.join('\n') + '\n'
    },

    // ── decode_toc_snap ───────────────────────────────────────────────────────
    // Mirror of encode_toc_snap. Walks lines in order, maintains a parents[]
    // stack indexed by depth: parents[d-1] is the C that a depth-d line gets
    // inserted into. parents[0] is The itself, so depth-1 lines become direct
    // children.
    //
    // %step inline rule: a line with a `step` key uses The_step() (find-or-
    // create by step number) so the identity is the step number, not line
    // position. The NNN.snap sibling file is implied by step:N — nothing on
    // disk points at it explicitly, code that needs the path just builds
    // pad(N)+'.snap'.
    //
    // Everything else: parent.i(sc) — generic insert. notes register their
    // swatch so the UI doesn't fatal-error on first render.
    //
    // not safe to call more than once.
    decode_toc_snap(snap: string, w: TheC) {
        if (!snap) return
        const The = w.c.The as TheC

        // parents[d] = the C that a line at depth d+1 should be inserted under
        const parents: TheC[] = [The]

        for (const line of snap.split('\n').filter(Boolean)) {
            let parsed: ReturnType<typeof this.deL> | null = null
            try { parsed = this.deL(line) } catch { continue }
            if (!parsed) continue
            const sc: Record<string, any> = { ...parsed.stringies }
            const d = parsed.d as number

            if (d === 0) continue   // story root — informational, validation hook

            const parent = parents[d - 1] ?? The
            let particle: TheC

            if (sc.step != null) {
                // %step inline rule (mirror of encoder)
                particle = this.The_step(w, sc.step as number)
                ex(particle.sc, sc)
            } else {
                particle = parent.i(sc)
                if (sc.note) {
                    for (const key of Object.keys(sc).filter(k => k !== 'note')) {
                        this.ensure_swatch(w, key)
                    }
                }
            }

            parents[d] = particle
        }
    },

    // ── sum_beliefs_time ──────────────────────────────────────────────────────
    // Pair-walk a Run_trace and sum the time spent inside the beliefs mutex.
    // Each {kind:'beliefs', tag:'begin'} must be followed by a matching
    // {kind:'beliefs', tag:'done'}; nested begins or unmatched ones mean the
    // trace is malformed and silently ignoring would hide a real bug, so we
    // throw. Returns seconds (trace t is performance.now() ms).
    sum_beliefs_time(trace: any[]): number {
        let total_ms = 0
        let begin_t: number | null = null
        for (const ev of trace ?? []) {
            if (ev.kind !== 'beliefs') continue
            if (ev.tag === 'begin') {
                if (begin_t !== null) throw `sum_beliefs_time: nested begin without done`
                begin_t = ev.t
            } else if (ev.tag === 'done') {
                if (begin_t === null) throw `sum_beliefs_time: done without begin`
                total_ms += ev.t - begin_t
                begin_t = null
            }
        }
        if (begin_t !== null) throw `sum_beliefs_time: trace ends with unclosed begin`
        return total_ms / 1000
    },

    // ── collect_time_sample ───────────────────────────────────────────────────
    // Called once on test completion (both new and check end-branches in
    // story_drive). Sums the beliefs-mutex time across every step that actually
    // ran this session (anything in This with a Run_trace), then appends one
    // sample to The/TimeSpool/{TimeTotal:'beliefs'}.
    //
    // Lives in The (not This) so it round-trips through toc.snap and accumulates
    // history across sessions — the whole point is being able to look back over
    // recent runs and see "is this test getting slower" / "roughly how long does
    // this test take to run". This is session-only and would die on reload.
    //
    // Trim: keep only the most recent 10 samples per TimeTotal. Sort ascending
    // by .at so the oldest sit at the front of the array, then whittle_N drops
    // from the front (and calls .drop() so they vanish from o() results).
    // avg is recomputed from the survivors so a future chart can read it
    // without re-summing.
    collect_time_sample(w: TheC) {
        const H    = this as House
        const This = w.c.This as TheC
        const ranSteps = (This?.o({ Step: 1 }) ?? [])
            .filter((s: TheC) => Array.isArray(s.sc.Run_trace) && s.sc.Run_trace.length)
        if (!ranSteps.length) return

        let run_total_seconds = 0
        for (const step of ranSteps) {
            run_total_seconds += H.sum_beliefs_time(step.sc.Run_trace as any[])
        }

        // The_bucket-style find-or-create directly under The. TimeSpool is the
        // namespace, TimeTotal:'beliefs' is the key (other categories can sit
        // alongside as siblings later).
        const The   = w.c.The as TheC
        const spool = (The.o({ TimeSpool: 1 })[0] as TheC) ?? The.i({ TimeSpool: 1 })
        const tt    = (spool.o({ TimeTotal: 'beliefs' })[0] as TheC)
                   ?? spool.i({ TimeTotal: 'beliefs', avg: 0 })

        // append. .at is wall-clock seconds — when this measurement was taken,
        // not the test duration itself (which is in .sample).
        tt.i({ sample: Math.round(run_total_seconds * 1000) / 1000, at: now_in_seconds() })

        // sort oldest-first so whittle_N evicts from the front
        const samples = (tt.o({ sample: 1 }) as TheC[])
            .sort((a, b) => (a.sc.at as number) - (b.sc.at as number))
        H.whittle_N(samples, 10)

        // recompute avg from survivors
        const survivors = tt.o({ sample: 1 }) as TheC[]
        const avg = survivors.reduce((s, n) => s + (n.sc.sample as number), 0) / survivors.length
        tt.sc.avg = Math.round(avg * 1000) / 1000

        ;V.Story && console.log(`⏱ TimeSpool/beliefs +sample=${run_total_seconds.toFixed(3)}s avg=${tt.sc.avg}s n=${survivors.length}`)
    },

    parse_snap(s: string) {
        // snap string → array of deL-parsed line objects, nulls filtered
        if (!s) return []
        return s.split('\n').filter(Boolean)
            .map(l => this.deL(l))
            .filter(x => x !== null)
    },


//#region note event handlers
//
//  Dispatched by the UI via storyH.elvisto('Story/Story', 'story_add_note', {…}).
//
//  note_sc format: { note:1, <typeKey>:<value>, … }
//    e.g. { note:1, frontier:1 }     — moves the frontier to this step
//         { note:1, todo:"fix me" }  — free-text annotation
//
//  The UI builds note_sc via peel(userstring) then prepends note:1.
//    peel("frontier")       → { frontier:1 }
//    peel("todo:fix me")    → { todo:"fix me" }

    async story_add_note(A: TheC, w: TheC, e?: TheC) {
        // note_sc from the UI: plain type keys, e.g. {frontier:1} or {todo:"fix me"}.
        // step_i_note prepends note:1 itself, so the UI does not need to include it.
        // frontier is a singleton: 'move' ensures only one exists across all steps.
        const n       = e?.sc.step_n  as number | undefined
        const note_sc = e?.sc.note_sc as Record<string,any> | undefined
        if (n == null || !note_sc) return
        const mode = ('frontier' in note_sc) ? 'move' : 'add'
        this.step_i_note(w, n, note_sc, mode)
    },

    async story_delete_note(A: TheC, w: TheC, e?: TheC) {
        const n        = e?.sc.step_n  as number | undefined
        const note_idx = e?.sc.note_idx as number | undefined
        if (n == null || note_idx == null) return
        const notes = this.The_step(w, n).o({ note: 1 })
        const noteC = notes[note_idx]
        if (noteC) noteC.drop(noteC)   // thing.drop(thing)
        this.story_analysis(w)
    },


//#region analysis — story_analysis, story_sel, story_accept


    // story_analysis: write scalar state into ave/{story_analysis:1} and bump ave.
    // Called after every mutation that should surface in the UI.
    // Steps and swatches are not serialised here — they are live children of
    // This/swatchC inside ave, re-read fresh by the UI on every bump.
    story_analysis(w: TheC) {
        const run      = w.o({ run: 1 })[0]
        const The      = w.c.The
        const ave      = w.c.ave
        const thisC    = w.c.This
        if (!ave || !thisC) return   // Story_plan hasn't run yet
        const frontier = (run?.sc.frontier as number) ?? 0

        let open_at = run?.sc.open_at ?? null
        const failed_at = run?.sc.failed_at
        if (failed_at != null && open_at == null) open_at = run.sc.open_at = failed_at

        // w.c.This = w/%This,Story:book — visible in Stuffing directly.
        // No separate mirror needed; This is the real particle, not a copy.

        // notes from The/%step:n — keyed by step number.
        const notes: Record<number, TheC[]> = {}
        for (const s of (w.c.The).o({ step: 1 })) {
            const n   = s.sc.step
            const N = s.o({ note: 1 })
            if (N.length) notes[n] = N
        }

        // the_steps: plain {n, dige} snapshot from The — the canonical expected set.
        // The UI builds the full strip skeleton from this, overlaying live stepsC data
        // for steps that have actually run this session.  sorted ascending.
        const the_steps = ((w.c.The)?.o({ step: 1 }))
            .map(s => ({ n: s.sc.step as number, dige: s.sc.dige }))
            .sort((a, b) => a.n - b.n)

        const bad_count = thisC ? (thisC.o({ Step: 1 }) as any[]).filter(s => !s.sc.ok && !s.sc.accepted).length : 0

        const an        = ave.oai({ story_analysis: 1 })
        an.sc.run_sc    = run ? { ...run.sc } : null
        an.sc.frontier  = frontier
        an.sc.open_at   = open_at
        an.sc.bad_count = bad_count
        an.sc.steps     = the_steps
        an.sc.notes     = notes
        ;V.Story && console.log(`📊 story_analysis: the_steps=${the_steps.length} live=${(w.c.This)?.o({Step:1}).length ?? 0} frontier=${frontier}`)
        ave.bump_version()
    },

    async story_sel(A: TheC, w: TheC, e?: TheC) {
        const run = w.o({ run: 1 })[0]
        if (run) run.sc.open_at = e?.sc.open_at ?? null

        // if opening a step that has no exp_snap yet (e.g. lenient run that didn't
        // fetch it), queue a fetch now so the diff panel can show it on demand.
        const n = run?.sc.open_at as number | undefined
        if (n != null && run) {
            const step = this.i_step(w, n)
            if (!step.sc.exp_snap && this.The_step_dige(w, n)) {
                run.sc.fetch_snap = n
                this.main()
            }
        }

        this.story_analysis(w)
    },

    async story_accept_all(A: TheC, w: TheC) {
        // Accept every !ok step in This at once.  Used after a lenient run that
        // accumulated multiple mismatches.  Promotes all diges into The, marks
        // accepted, keeps got_snap for story_save to write (5-step trim cleans up
        // after save).
        const H   = this
        const run = w.o({ run: 1 })[0]
        if (!run) return
        const allBad = (w.c.This?.o({ Step: 1 }) ?? []).filter(s => !s.sc.ok)
        ;V.Story && console.log(`✅ story_accept_all: ${allBad.length} steps`)
        for (const step of allBad) {
            const n = step.sc.Step
            if (step.sc.dige) H.The_step(w, n).sc.dige = step.sc.dige
            step.sc.accepted = true
            // got_snap kept — story_save reads it; 5-step trim handles cleanup
        }
        run.sc.frontier = 0
        H.The_set_frontier(w, 0)
        delete run.sc.failed_at
        delete run.sc.fetch_snap
        run.sc.paused  = 0
        run.sc.open_at = null
        H.story_analysis(w)
        H.story_save()
        const sub = H.Story_subHouse(A, w)
        if (sub) H.story_drive(sub.Run, w, run)
    },


//#region story_accept

    async story_accept(A: TheC, w: TheC, e?: TheC) {
        // Accept a mismatch at step n:
        //   1. Clone This/{Step:n}.dige → The/{step:n}.dige.  The now reflects reality.
        //   2. Mark stepC.sc.accepted = true so the UI can dull the pip distinctively.
        //   3. got_snap is kept — story_save reads it inside post_do.
        //      The 5-step trim handles cleanup for accepted+saved steps behind us,
        //      so there is no race between story_accept and the post_do.
        //   4. Advance the frontier note in The (for save/reload bookkeeping).
        //   5. Clear failure state; resume the drive.
        const H   = this
        const run = w.o({ run: 1 })[0]
        if (!run) return
        const n = e?.sc.accept_n as number | undefined
        if (n == null) return

        const The_all  = (w.c.The).o({ step: 1 })
        const max_step = Math.max(0, ...The_all.map(s => s.sc.step as number))

        if (n >= max_step) {
            run.sc.frontier = 0
            H.The_set_frontier(w, 0)
        } else {
            run.sc.frontier = n
            H.The_set_frontier(w, n)
        }

        // This → The: promote the accepted dige into the canonical record
        const step = H.i_step(w, n)
        if (step.sc.dige) H.The_step(w, n).sc.dige = step.sc.dige
        step.sc.accepted = true
        // got_snap kept — story_save reads it; trim loop handles cleanup behind us
        ;V.Story && console.log(`✅ story_accept n=${n} dige=${step.sc.dige?.slice(0,8)} frontier=${run.sc.frontier}`)

        delete run.sc.failed_at
        delete run.sc.fetch_snap
        run.sc.paused  = 0
        run.sc.open_at = null

        H.story_analysis(w)
        H.story_save()

        const sub = H.Story_subHouse(A, w)
        if (sub) H.story_drive(sub.Run, w, run)
    },


//#region snap encoding — walk Run and encode to snap lines
//
//  story_snap walks the Run sub-House via Selection and encodes each particle
//  as a snap line.  story_matching rules govern what gets skipped, munged, or
//  traced (re-identified across runs by a stable identity).
//
//  story_process_node sets D.sc.snap_line (indent + objecties + tab + stringies)
//  directly on the D particle, so story_snap just collects Ds and joins their
//  snap_line strings at the end.  traced_fn compares snap_line strings across
//  runs for change detection — no separate snap_copy accumulation needed.
//
//  Any object or function value not covered by munging rules falls through to
//  the objectify() path and ends up in objecties.ref — it is present in the
//  snap line but excluded from the diff comparison (which only uses stringies).
//  This is the "deL munges any ref still on %Story we didn't know about" rule:
//  unknown refs are automatically neutralised rather than causing errors or
//  polluting the diff.

    story_matching: [
        {
            // House-level particles: mung timer ids (they change every run)
            matching_any: [{ sc: { H: 1 } }],
            means: {
                thence_matching: [
                    { matching_any: [{ sc_only: { mo: 1, interval: 1, id: 1 } }],
                      means: { munging: [{ sc: { id: 1 }, type: 'timer_id' }] } },
                ]
            }
        },
        {
            // Actor / worker level: skip self-ref bookkeeping; mung timestamps
            matching_any: [{ sc: { A: 1 } }, { sc: { w: 1 } }],
            means: {
                thence_matching: [
                    { matching_any: [{ sc_only: { self: 1, est: 1 } }],
                      means: { skip: true } },
                    { matching_any: [{ sc_only: { self: 1, round: 1, age: 1 } }],
                      means: { munging: [{ sc: { age: 1 }, type: 'time' }] } },
                    { matching_any: [{ sc_only: { wasLast: 1, at: 1 } }],
                      means: { munging: [{ sc: { at: 1 }, type: 'time' }] } },
                    { matching_any: [{ sc_only: { chaFrom: 1, was: 1, v: 1, at: 1 } }],
                      means: { munging: [{ sc: { at: 1 }, type: 'time' }] } },
                ]
            }
        },
        {
            // Story work particle itself — any object ref on w that wasn't caught
            // by the rules above (The, toc_loaded, wh, run_path, etc.) is left to
            // the objectify() fallback in story_process_node, which puts it into
            // objecties.ref.  That ref is excluded from diff comparisons (only
            // stringies are diffed), so it is effectively munged without explicit
            // listing.  Add explicit munging entries here if a ref becomes noisy.
            matching_any: [{ sc: { Story: 1 } }],
            means: { thence_matching: [] }
        },
    ] as Array<any>,

    // classify one particle during the snap walk.
    // builds stringies (serialisable diff-comparable values),
    // ref (object values → stable ids via objectify — excluded from diff),
    // mung (keys deliberately excluded, e.g. timestamps).
    // sets T.sc.not=1 to skip the particle entirely.
    // sets D.sc.snap_line — the complete encoded line (indent + objecties + tab +
    //   stringies), used directly by story_snap and compared in traced_fn.
    story_process_node(n: TheC, T: Travel, D: TheD) {
        const active: Array<any> = [
            ...this.story_matching,
            ...(T.sc.up?.sc.thence_matching ?? []),
        ]
        const q: any = { d: T.c.path.length - 1, rules: active }
        const line = this.enLine(n, q)

        if (q.skip) { T.sc.not = 1; return }

        D.sc.stringies = q.stringies
        D.sc.objecties = q.objecties
        D.sc.copy = { ...n.sc }
        D.sc.snap_line = line ?? ''
        if (q.mung?.length) { D.c.munged ??= []; D.c.munged.push(q.mung) }
        if (q.thence?.length) T.sc.thence_matching = q.thence
    },

    // ── snap_H ────────────────────────────────────────────────────────────────
    // The H-structure portion of the full snap.
    // Exactly what story_snap used to do — walk Run via Selection,
    // encode each particle as a snap line, return joined string.
    // snap_Se lives here; traced_fn compares snap_line strings across runs.

    async snap_H(Run: House): Promise<string> {
        const lines: TheD[] = []

        Run.c.snap_Se ??= new Selection()
        const Se: Selection = Run.c.snap_Se

        await Se.process({
            n:          Run,
            process_sc: { snap_root: 1 },
            match_sc:   {},
            trace_sc:   { snap_node: 1 },

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                this.story_process_node(n, T, D)
                if (T.sc.not) return
                if (T.c.path.length === 1) {
                    T.sc.more = (n.o({})).filter(c => !c.sc.snap_root)
                }
                lines.push(D)
            },

            trace_fn: async (uD: TheD, n: TheC, _T: Travel) => {
                const identity = Object.fromEntries(
                    Object.keys(n.sc).map(k => [`the_${k}`, n.sc[k]])
                )
                return uD.i({ snap_node: 1, ...identity })
            },

            traced_fn: async (D: TheD, bD: TheD | undefined) => {
                D.sc.changed = bD?.sc.snap_line != null && D.sc.snap_line !== bD.sc.snap_line
                D.sc.is_new  = !bD
            },
        })

        return lines.map(D => D.sc.snap_line as string).join('\n') + '\n'
    },




    // ── story_snap ────────────────────────────────────────────────────────────
    // Full snap as a deL-able tree:
    //
    //   \t{"Snap":"H"}                       d=0
    //     [snap_H content shifted to d=1+]
    //   \t{"Snap":"cytowave"}                d=0
    //     \t{"node":"w:farm","compound":1,...}   d=1
    //       \t{"background-color":"#0a1f0a"}     d=2
    //       ...
    //
    // cyto_scan always runs regardless of intoCyto so the wave is always in
    // the dige.  cyto_update_wave's version-check makes this free when RunH
    // hasn't changed since the last ambient Cyto tick.

    async story_snap(Run: House): Promise<string> {
        const H = this as House

        // Snap:H — indent +1 so content nests under the header
        const h_snap  = await this.snap_H(Run)
        const h_block = this.snap_indent(h_snap, 1)

        // Snap:Cytowave — always scan
        const cyto_A = H.o({ A: 'Cyto' })[0] as TheC | undefined
        const cyto_w = cyto_A?.o({ w: 'Cyto' })[0] as TheC | undefined
        if (cyto_w) {
            if (!cyto_w.c.plan_done) throw "wake w:Cyto before wanting graph"
            if (!cyto_w.c.plan_done) H.Cyto_plan(cyto_w)
            await H.cyto_update_wave(cyto_w)
        }
        const wave     = cyto_w?.c.gn?.sc.wave as any
        const cw_block = this.snap_cytowave_str(wave)   // d_base=1, already nested

        return this.enL({ d: 0, stringies: { Snap: 'H' } })        + '\n' + h_block
            + this.enL({ d: 0, stringies: { Snap: 'cytowave' } }) + '\n' + cw_block
    },


//#region Story_plan

    Story_subHouse(A: TheC, w: TheC) {
        // Get-or-create the Run sub-House for this Book and wire its actors.
        // Called every tick from Story() — cheap when the House and actors already exist.
        // Returns { Run, book } or null when Book is missing or Run_A_<Book> is absent.
        const book = w.sc.Book
        if (!book) { w.i({ see: '!Book' }); return null }

        const Run  = this.subHouse(book)
        Run.sc.Run = 1
        Run.c.no_ambient = true   // story_drive owns the clock; suppress ambient tick

        if (!Run.oa({ A: 1 })) {
            const init_fn = (Run as any)[`Run_A_${book}`] as Function | undefined
            if (!init_fn) { w.i({ error: `!Run_A_${book}` }); return null }
            init_fn.call(Run)
        }
        return { Run, book }
    },

    Story_plan(A: TheC, w: TheC, book: string) {
        // Called once when there is no %run yet — no run means no The/This either.
        // Creates all C structure fresh; wires w.c.* for the session.
        //
        //   w/%The,story:book   — canonical toc; from disk.
        //     /%step:N,dige
        //       /%note:1,...
        //   w/%This,Story:book  — live session steps (also placed in ave for reactivity).
        //     /%Step:N          — ok/dige/got_snap/exp_snap/accepted/saved
        //   H/%watched:ave
        //     /%swatches:1
        //     /%This,Story:book — same C particle as w's This (multi-placed)
        //     /%story_analysis:1
        //   H/%watched:UIs
        //     /%UI:Story,component:StoryRun  — Otro mounts this via house.UIs
        //
        const H = this

        w.c.The  = w.i({ The:  1, story: book })
        w.c.This = w.i({ This: 1, Story: book })

        const ave   = H.oai_enroll(H, { watched: 'ave' })
        ave.i(w.c.This)                          // This appears in both w and ave
        w.c.swatchC = ave.oai({ swatches: 1 })
        w.c.ave     = ave

        H.oai_enroll(H, { watched: 'actions' })

        // Register StoryRun in %watched:UIs so Otro can mount it for this house.
        // oai_enroll creates the container once and calls enroll_watched();
        // oai on the child is idempotent — subsequent Story_plan calls are no-ops.
        const uis = H.oai_enroll(H, { watched: 'UIs' })
        uis.oai({ UI: 'Story', component: StoryRun })
        let total = 5
        return w.i({ run: book, done: 0, total, paused: false, mode: 'new' })
    },


//#region w:Story

    async Story(A: TheC, w: TheC) {
        const H    = this
        const sub  = H.Story_subHouse(A, w)
        if (!sub) return
        const { Run, book } = sub

        // Story_plan runs once — creates everything. If run exists, everything else does too.
        let run = w.o({ run: book })[0]
        if (!run) run = H.Story_plan(A, w, book)

        const fs_safe  = (s: string) => s.replace(/[:/\\?*"|<>]/g, '-')
        const run_path = `Story/${fs_safe(book)}`
        const wh       = await H.requesty_serial(w, 'wh')

        if (!run.c.toc_loaded) {
            // ── load toc.snap ──────────────────────────────────────────────
            // Wormhole.read_toc handles toc.json → toc.snap migration transparently
            // (reads toc.json if toc.snap absent, converts, writes toc.snap, returns).
            const toc_req = await wh.oai({ wh_path: run_path, wh_op: 'read_toc' })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req }))
                return w.i({ see: '⏳ toc...' })

            const toc_snap = toc_req.sc.reply?.toc_snap ?? ''
            H.decode_toc_snap(toc_snap, w)   // fills The + pre-creates hollow This/{Step:N}

            const step_count = (w.c.The)?.o({ step: 1 }).length ?? 0
            run.sc.mode      = step_count > 0 ? 'check' : 'new'
            run.sc.frontier  = H.The_frontier(w)   // restored from {note:1,frontier:1}
            w.c.run_path     = run_path
            w.c.wh           = wh
            run.c.toc_loaded = true
            H.story_analysis(w)
        }

        if (run.sc.fetch_snap) {
            // ── fetch the expected snap for the failed step ────────────────
            // Just loads the file content into step.sc.exp_snap for the diff panel.
            // Dige verification is always handled by the check_snap block below —
            // we queue it here so it runs in the same beliefs round.
            const n        = run.sc.fetch_snap as number
            const snap_req = await wh.oai({ wh_path: run_path, wh_op: 'read_snap', wh_step: n })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req }))
                return w.i({ see: `⏳ snap ${H.pad(n)}...` })

            let Step = H.i_step(w, n)
            Step.sc.exp_snap = snap_req.sc.reply?.snap ?? '(not found)'
            Step.bump_version()
            delete run.sc.fetch_snap
            run.sc.check_snap ??= n   // verify dige in the block below
            H.story_analysis(w)
        }

        if (run.sc.check_snap) {
            // ── single dige verify — runs for both mismatch and snap_checking steps ─
            // Mismatch path:      fetch_snap queues check_snap (same beliefs round).
            // snap_checking path: snap_step queues check_snap on ok steps.
            //
            // If disk dige ≠ toc dige the file is stale or corrupt.  We promote
            // disk_dige into The so the diff panel shows the right "expected" content
            // and Accept works normally from there.  step.sc.disk_ok surfaces the fact
            // in StoryRun.  step.sc.checking is only set for snap_checking ok steps —
            // clearing it here unblocks poll_check in that path; for mismatches it
            // was never set so clearing is a no-op.
            const n        = run.sc.check_snap as number
            const snap_req = await wh.oai({ wh_path: run_path, wh_op: 'read_snap', wh_step: n })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req }))
                return w.i({ see: `⏳ verify ${H.pad(n)}...` })

            const disk_snap = snap_req.sc.reply?.snap as string | undefined
            const step      = H.i_step(w, n)
            if (disk_snap) {
                const disk_dige = await dig(disk_snap)
                const exp_dige  = H.The_step_dige(w, n)
                const ok        = disk_dige === exp_dige
                step.sc.disk_ok   = ok
                step.sc.disk_dige = disk_dige
                if (!ok) {
                    // promote disk version into The so fetch_snap / diff already loaded correctly
                    H.The_step(w, n).sc.dige = disk_dige
                    console.warn(`⚠ disk dige mismatch n=${n}: disk=${disk_dige.slice(0,8)} toc=${exp_dige?.slice(0,8)}`)
                }
            } else {
                // file missing entirely — toc.snap claims a dige but NNN.snap is gone
                step.sc.disk_ok   = false
                step.sc.disk_dige = null
                console.warn(`⚠ disk snap missing n=${n}`)
            }
            delete run.sc.check_snap
            step.sc.checking = false   // unblocks poll_check (snap_checking ok path only)
            H.story_analysis(w)
        }

        if (!run.c.driving && !run.sc.paused) H.story_drive(Run, w, run)
        await H.story_ui(Run, w, run)
        w.i({ see: `${book} ${run.sc.done} [${run.sc.mode}]${run.sc.paused ? ' ⏸' : ''}` })
    },

    // ── story_cyto_continue ───────────────────────────────────────────────────
    // Received from w:Cyto once Cytui has finished animating the current step.
    // Clears the intoCyto pause and starts a fresh story_drive — the drive
    // was already stopped cleanly by advance() so driving=false here.
    async story_cyto_continue(A: TheC, w: TheC) {
        V.Story && console.log(`e:story_cyto_continue() -> w:${w.sc.w}`)
        const run = w.o({ run: 1 })[0]
        if (!run) return
        if (run.sc.paused >= 2) return   // strong pause holds
        run.sc.paused = 0
        delete run.c.cyto_waiting
        const sub = this.Story_subHouse(A, w)
        if (sub) this.story_drive(sub.Run, w, run)
    },


//#region story_drive
//
//  All phases are closures over run and the drive locals.
//
//   Phase 1 — do_step  (inside H beliefs mutex via post_do)
//     checks termination conditions, fires Run.elvisto(Run,'think') after 1ms,
//     then hands off to poll_step.
//
//   Phase 2 — poll_step  (plain setTimeout chain, no mutex)
//     waits for Run to go quiescent (finished_run timestamp fresh and stable),
//     then queues snap_step.
//
//   Phase 3 — snap_step  (inside H beliefs mutex via post_do)
//     encodes the snap, compares diges, stores on This/{Step:N}.
//     Trims (got|exp)_snap 5 steps behind (unless keep_snaps toggle is on).
//     If snap_checking and ok: sets step.sc.checking, queues poll_check.
//     Otherwise calls advance() — which either hands off to w:Cyto
//     (when w.c.intoCyto is set) or calls schedule() directly.
//
//   Phase 4 — poll_check  (plain setTimeout, snap_checking mode only)
//     waits for Story() to read NNN.snap from disk, verify its dige,
//     and clear step.sc.checking.  Then calls advance().

    story_drive(Run: House, w: TheC, run: TheC) {
        if (run.c.driving) return
        run.c.driving = true

        const H    = this as House
        const TICK = ANSWER_CALLS_TICK_MS

        const update_status = async (label: string, cls = 'default') => {
            const wa = () => H.o({ watched: 'actions' })[0]
            await wa()?.r({ action: 1, role: 'status' }, { label, cls, disabled: true })
            wa()?.bump_version()
        }

        // advance: called at the end of each completed step instead of schedule().
        // When w.c.intoCyto is set, pauses the drive and hands control to w:Cyto.
        // Cyto will scan the farm, publish a grawave, then after its animation
        // duration fires story_cyto_continue back to w:Story to resume.
        // When intoCyto is absent, falls through to schedule() as before.
        const advance = () => {
            // step just completed — check for a pause note
            const n = run.c.step_n as number
            if (n != null && H.The_step(w, n).o({ note: 1, pause: 1 }).length) {
                run.sc.paused = 2
            }

            if (w.c.intoCyto) {
                run.sc.paused = Math.max((run.sc.paused as number) || 0, 1)
                run.c.driving = false
                H.top_House().elvisto('Cyto/Cyto', 'story_cyto_step', { story_step: run.c.step_n })
                return
            }
            if (run.sc.paused) return   // strong pause holds before schedule()
            schedule()
        }

        // Phase 1: do_step
        const do_step = async () => {
            if (!run.c.driving || run.sc.paused) {
                console.log(`⏸ do_step skipped: driving=${run.c.driving} paused=${run.sc.paused}`)
                schedule(); return
            }
            const n = ((run.sc.done ?? 0) as number) + 1
            ;V.Story && console.log(`▷ do_step n=${n} mode=${run.sc.mode}`)
            ;V.Story && console.log(`The at n=${n}:`, (w.c.The)?.o({step:1}).map((s:any)=>s.sc.step+'→'+(s.sc.dige?s.sc.dige.slice(0,6):'no-dige')).join(', '))
            ;V.Story && console.log(`The_step_dige(${n}) =`, H.The_step_dige(w, n))
            
            if (run.sc.mode === 'new' && n > ((run.sc.total ?? 30) as number)) {
                run.c.driving = false; run.sc.paused = 2
                H.collect_time_sample(w)   // append to The/TimeSpool before save
                H.story_analysis(w)
                H.story_save()
                await update_status('recorded ✓', 'start')
                console.log(`✓ Story: complete (${run.sc.total} steps)`)
                H.top_House().elvisto('Auto/Auto', 'storyFinished', { Book: w.sc.Book, mode: 'new' })
                return
            }
            if (run.sc.mode === 'check' && !H.The_step_dige(w, n)) {
                run.c.driving = false; run.sc.paused = 2
                // clear frontier when we reach the end — no outstanding mismatch
                run.sc.frontier = 0
                H.The_set_frontier(w, 0)
                // if we ran lenient, open the last !ok step so the user can review it
                const last_bad = (w.c.This?.o({ Step: 1 }) ?? [])
                    .filter(s => !s.sc.ok)
                    .sort((a, b) => b.sc.Step - a.sc.Step)[0]
                if (last_bad) run.sc.open_at = last_bad.sc.Step
                H.collect_time_sample(w)   // append to The/TimeSpool before save
                H.story_analysis(w)
                H.story_save()
                await update_status('done ✓', 'start')
                console.log(`✓ Story: check complete at n=${n}`)
                H.top_House().elvisto('Auto/Auto', 'storyFinished', { Book: w.sc.Book, mode: 'check' })
                return
            }

            run.c.step_n     = n
            run.c.began_step = now_in_seconds_with_ms()
            Run.trace_enable()
            Run.trace('step', String(n))
            setTimeout(() => { if (run.c.driving) Run.elvisto(Run, 'think') }, 1)
            setTimeout(poll_step, TICK)
        }

        // Phase 2: poll_step — wait for Run to go quiescent
        const poll_step = () => {
            if (!run.c.driving) return
            const f = Run.c.finished_run as number | null
            const quiescent = f != null
                && f > (run.c.began_step as number)
                && (now_in_seconds_with_ms() - f) < TICK * 1.5
            if (!quiescent) { setTimeout(poll_step, TICK); return }
            ;V.Story && console.log(`⏱ poll_step quiescent n=${run.c.step_n}`)
            H.post_do(snap_step, { see: 'story_snap' })
        }

        // Phase 3: snap_step — encode, compare, store, trim, then advance or verify
        const snap_step = async () => {
            if (!run.c.driving) return
            const n = run.c.step_n as number
            run.sc.done       = n
            Run.trace('snap', String(n))

            const snap     = await this.story_snap(Run)
            const got_dige = await dig(snap)
            Run.trace('snapped', String(n))

            const step    = H.i_step(w, n)
            step.sc.unrun = false
            const run_trace = Run.trace_drain()
            step.sc.Run_trace = run_trace
            step.bump_version()

            // Trim (got|exp)_snap 5 steps behind — best-effort GC.
            //   ok+!accepted:   already on disk unchanged, safe to drop.
            //   accepted+saved: written by story_save, safe to drop.
            //   exp_snap:       display-only, always safe to drop.
            // Skipped when keep_snaps toggle is on.
            const trim_n = n - 5
            if (trim_n >= 1 && !w.c.keep_snaps) {
                const old = H.i_step(w, trim_n)
                if (old.sc.ok && !old.sc.accepted)   delete old.sc.got_snap
                if (old.sc.accepted && old.sc.saved)  delete old.sc.got_snap
                delete old.sc.exp_snap
            }

            if (run.sc.mode === 'new') {
                step.sc.got_snap = snap
                step.sc.dige     = got_dige
                step.sc.ok       = true
                step.sc.accepted = true   // new-mode steps are self-accepting; save loop uses this
                H.The_step(w, n).sc.dige = got_dige
                H.story_analysis(w)
                await update_status(
                    `recording ${H.pad(n)}/${H.pad(run.sc.total)}`, 'save')
                advance()

            } else {
                const exp_dige = H.The_step_dige(w, n)
                const ok       = exp_dige === got_dige
                ;V.Story && console.log(`🔍 n=${n} ok=${ok} exp=${exp_dige?.slice(0,8)} got=${got_dige.slice(0,8)}`)
                step.sc.got_snap = snap
                step.sc.dige     = got_dige
                step.sc.ok       = ok

                H.story_analysis(w)

                if (!ok && !w.c.lenient) {
                    run.c.driving     = false
                    run.sc.paused     = 2
                    run.sc.failed_at  = n
                    run.sc.fetch_snap = n
                    run.sc.check_snap = n   // fetch_snap also sets this, but be explicit
                    run.sc.frontier   = n
                    if (run.sc.open_at == null) run.sc.open_at = n
                    H.The_set_frontier(w, n)
                    await update_status(`✗ step ${H.pad(n)}`, 'stop')
                    console.log(`⛔ Story: step ${H.pad(n)} mismatch — exp=${exp_dige?.slice(0,8)} got=${got_dige.slice(0,8)}`)
                    H.main(); return
                }
                if (!ok) console.log(`⚠ Story: step ${H.pad(n)} mismatch accepted (lenient)`)
                await update_status(`${ok ? '✓' : '⚠'} ${H.pad(n)}`, ok ? 'default' : 'save')
                ;V.Story && console.log(`✔ snap_step ok=${ok} n=${n}${ok && w.c.snap_checking ? ', verifying' : ', advancing'}`)

                // snap_checking: queue a disk dige verify for this step and wait
                // for Story() to process it before advancing.  poll_check unblocks
                // once Story() clears step.sc.checking.  Only fires on ok steps —
                // mismatches already have fetch_snap wired, which reads the disk snap.
                if (ok && w.c.snap_checking) {
                    step.sc.checking  = true
                    run.sc.check_snap = n
                    H.main()
                    setTimeout(poll_check, TICK)
                } else {
                    advance()
                }
            }
        }

        // Phase 4: poll_check — wait for Story() to verify disk snap (snap_checking only).
        // If disk_ok === false the file on disk doesn't match toc.snap's recorded dige.
        // check_snap has already promoted disk_dige into The, so we just pause like a
        // normal mismatch and let the user Accept from the diff panel.
        const poll_check = () => {
            if (!run.c.driving) return
            const n          = run.c.step_n as number
            const check_step = H.i_step(w, n)
            if (check_step.sc.checking) { setTimeout(poll_check, TICK); return }

            if (check_step.sc.disk_ok === false) {
                check_step.sc.ok  = false
                run.c.driving     = false
                run.sc.paused     = 2
                run.sc.failed_at  = n
                run.sc.fetch_snap = n
                run.sc.frontier   = n
                if (run.sc.open_at == null) run.sc.open_at = n
                H.The_set_frontier(w, n)
                update_status(`✗ disk ${H.pad(n)}`, 'stop')
                H.main()
                return
            }

            ;V.Story && console.log(`⏱ poll_check ok n=${n}`)
            advance()
        }

        const schedule = () => {
            if (!run.c.driving) return
            ;V.Story && console.log(`⏭ schedule driving=${run.c.driving} paused=${run.sc.paused}`)
            setTimeout(() => {
                if (!run.c.driving) return
                H.post_do(do_step, { see: 'story_step' })
            }, 200)
        }

        schedule()
        console.log(`▶ Story: drive started for ${run.sc.run}`)
    },


//#region story_save — write toc.snap and any unsaved NNN.snap files
//
//  NNN.snap write condition: step has got_snap and accepted.
//   — new mode:   all steps are accepted=true; got_snap set in snap_step.
//   — check mode: only mismatches the user accepted carry accepted=true;
//                 ok steps are already on disk unchanged and their got_snap
//                 is trimmed away by the 5-step trim in snap_step.
//
//  got_snap is NOT deleted in story_accept — it stays until post_do writes it.
//  The 5-step trim (accepted+saved) handles cleanup after the file is written.
//  There is therefore no race between story_accept and the post_do here.

    async story_save(this: House) {
        const storyH = this
        const A      = storyH.o({ A: 'Story' })[0]
        const w      = A?.o({ w: 'Story' })[0]
        if (!w) return

        const wh        = w.c.wh as any
        const run_path  = w.c.run_path
        const run       = w.o({ run: 1 })[0]
        const frontier  = (run?.sc.frontier as number) ?? 0
        const The       = w.c.The
        const thisC     = w.c.This
        const all_steps = thisC ? thisC.o({ Step: 1 }) : []
        if (!all_steps.length && !The?.o({ step: 1 }).length) return
        ;V.Story && console.log(`💾 story_save: to_write=${all_steps.filter(s=>s.sc.got_snap&&s.sc.accepted&&!s.sc.saved).length}`)

        // sync frontier note so toc.snap reflects the current state exactly
        const all_the_steps = The.o({ step: 1 })
        const max_step      = Math.max(0, ...all_the_steps.map(s => s.sc.step as number))
        if (frontier > 0 && frontier < max_step) {
            storyH.The_set_frontier(w, frontier)
        } else {
            storyH.The_set_frontier(w, 0)   // clean: no outstanding mismatch
        }

        const snap       = await storyH.encode_toc_snap(w)
        const step_count = all_the_steps.filter(s => !!s.sc.dige).length

        if (!wh || !run_path) {
            storyH.stashed ??= {}
            storyH.stashed[`${run?.sc.run}.snap`] = snap
            return
        }
        // go async to let story drive forward first
        setTimeout(() => {
        storyH.post_do(async () => {
            const toc_req = await wh.i({ wh_path: run_path, wh_op: 'write_toc', wh_data: snap })
            storyH.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req })

            for (const step of all_steps) {
                if (step.sc.saved) continue
                if (!step.sc.got_snap || !step.sc.accepted) continue
                const n = step.sc.Step as number
                ;V.Story && console.log(`💾 writing snap n=${n}`)
                const snap_req = await wh.i({
                    wh_path: run_path, wh_op: 'write_snap',
                    wh_step: n, wh_data: step.sc.got_snap,
                })
                storyH.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req })
                step.sc.saved = true
            }

            const tag = frontier > 0 ? ` frontier:${frontier}` : ' clean'
            console.log(`💾 wormhole: ${run_path} (${step_count} steps${tag})`)
        }, { see: 'story_save' })
        },0)
    },


//#region story_reset

    story_reset(this: House) {
        // H:Story is a child of H:Mundo — Auto owns the lifecycle.
        // Delegate via elvis so Auto's picks_a_book() runs (tears down and
        // rebuilds H:Story cleanly rather than trying to reset in place).
        const topH = this.top_House()
        // find our book name from the Story worker so Auto knows what to restart
        const bname = (this.o({ A: 'Story' })[0] as TheC | undefined)
            ?.o({ w: 'Story' })[0]?.sc.Book as string | undefined
        topH.elvisto('Auto/Auto', 'resetStory', bname ? { Book: bname } : {})
        console.log(`🔄 ${this.name} reset`)
    },


//#region mechanisms — Run wiring, story_ui

    async story_ui(this: House, Run: House, w: TheC, run: TheC) {
        const wa = this.o({ watched: 'actions' })[0]
        if (!wa) return
        const paused = run.sc.paused
        const mode   = run.sc.mode ?? 'new'

        const at_end = (run.sc.done ?? 0) >= (run.sc.total ?? 30)
            && run.sc.paused
        
        await wa.roai({ action: 1, role: 'pause' }, {
            label: at_end ? '+step' : paused ? 'Resume' : 'Pause',
            icon:  at_end ? '+'    : paused ? '▶'      : '⏸',
            cls:   at_end ? 'save' : paused ? 'start'   : 'stop',
            fn: () => {
                if (!run.sc.paused) {
                    run.sc.paused = 2
                    return
                }
                if (at_end) {
                    run.sc.total = ((run.sc.total ?? 30) as number) + 1
                }
                run.sc.paused = 0
                run.sc.mode = 'new'
                if (!run.c.driving) this.story_drive(Run, w, run)
            },
        })
        wa.oai({ action: 1, role: 'save'   }, { label: 'Save',  icon: '💾', cls: 'save',   fn: () => this.story_save()  })
        wa.oai({ action: 1, role: 'reset'  }, { label: 'Reset', icon: '🔄', cls: 'remove', fn: () => this.story_reset() })

        await this.i_actions_to_c(w, 'lenient', {
            stashed: true, label: 'lenient',
            on_change: (next: boolean) => {
                if (next && run.sc.failed_at && !run.c.driving) {
                    delete run.sc.failed_at
                    run.sc.paused = 0
                    this.story_drive(Run, w, run)
                }
            },
        })

        // Toggle actions backed by w.c.* and optionally H.stashed.* (stashed:true).
        //   snap_checking: after each ok step, fetch NNN.snap from disk and verify its
        //     dige against toc.snap.  Adds one beliefs round per step (rarely needed).
        //     Surfaces corruption as step.sc.disk_ok===false in StoryRun.
        //   keep_snaps: suppress the 5-step trim of (got|exp)_snap.  Useful when you
        //     want to inspect snap content across many steps in the same session.
        await this.i_actions_to_c(w, 'snap_checking', { stashed: true, label: 'verify snaps' })
        await this.i_actions_to_c(w, 'keep_snaps',    { stashed: true, label: 'keep snaps'   })
        await this.i_actions_to_c(w, 'intoCyto',      { stashed: true, label: 'into Cyto'    })
        wa.oai({ action: 1, role: 'cyto_wipe' }, {
            label: 'wipe', icon: '⌀', cls: 'remove',
            fn: () => this.elvisto('Cyto/Cyto', 'cyto_wipe', {})
        })

        // < is this weird. Baroquely, an information channel in a button
        await wa.roai({ action: 1, role: 'status' }, {
            label:    `${mode} ${run.sc.failed_at ? '✗' + this.pad(run.sc.failed_at) : this.pad(run.sc.done ?? 0)}`,
            cls:      run.sc.failed_at ? 'stop' : mode === 'new' ? 'save' : 'default',
            disabled: true,
        })
    },



    })
    })
</script>