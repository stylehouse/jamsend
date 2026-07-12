<script lang="ts">
    // Ghost: Story — mounts into the parent House via M.eatfunc({...}).
    // All methods below become House instance methods once eatfunc completes.
    //
    // ── This / The duality ───────────────────────────────────────────────────
    //
    //   This  — what is spontaneously happening right now, this session.
    //           Particles live as direct children of w, the Story work particle.
    //           Uppercase key: {Step:N}
    //           Carries: got_snap, exp_snap, first_snap, dige, ok, hollow, accepted, saved.
    //           Has {watched:'ave'} in sc so enroll_watched() picks it up and
    //           any version bump on a Step is visible to Storui as a reactive
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
    //   Story_plan registers Storui for Otro via H:Story/%watched:UIs so Otro can
    //   mount it automatically alongside whichever house it finds itself on.
    //   The same container holds Cytui etc (registered by w:Cyto on its first tick).
    //   H.UIs = C.o({}) is populated by enroll_watched() on every bump.

    let spect = `
    
    further design:
      snap after every Atime, and make the %see sparkle about things like airborne cinnamon.
       we currently snap after every Runtime (Run.c.runtime=false, it is minimally conceptualised)
      assertions, pointers
       crawl code forward by compiling pauses everywhere
      the UI
       with its diff space
        wants many Snap:*-possible data channels
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





        we should be matching every elvis that happens, so we can pause after one and record everything, then go on, to pull apart the action and really understand things

        we could be defining a template of stuff to get up to at snaptime.
         we do this trace thing as well which is kind of another channel of test data stuff, that we don't capture yet.

        so into that we could be adding a nice list of elvises that happened



        so I'd like to incorporate the idea of info channels ... somehow we pass out information from H%Run...
        was a bunch of this in 
    
    
    
    







    
    `

    import { objectify, TheC }             from "$lib/data/Stuff.svelte"
    import type { TheD }                  from "$lib/mostly/Selection.svelte"
    import { Selection, Travel }          from "$lib/mostly/Selection.svelte"
    import { depeel, peel, dig, exactly, ex }               from "$lib/Y.svelte"
    import { onMount, tick }                    from "svelte"
    import { now_in_seconds, now_in_seconds_with_ms }     from "$lib/p2p/Peerily.svelte"
    import { ANSWER_CALLS_TICK_MS, House } from "$lib/O/Housing.svelte"
    import Storui                       from "$lib/O/Storui.svelte"
    import { SoundSystem }              from "$lib/p2p/ftp/Audio.svelte"

    let { M } = $props()
    let V = { Story: 1 }   // set Story: 1 here to enable drive/analysis debug logs

    // ── colour palette ───────────────────────────────────────────────────────
    // Assigned in first-seen order via ensure_swatch().
    // Frontier always gets FRONTIER_COLOR.  Prepend an entry here to reserve a
    // colour for a well-known type before the auto-assign loop reaches it.
    const NOTE_PALETTE   = ['#7bc8a4','#7ab0d4','#c9a96e','#b08fc8','#d49a7a','#7abfb8','#a8b87a','#c87aaa','#a07878']
    const FRONTIER_COLOR = '#c55'

    onMount(async () => {
    await M.eatfunc({

//#region The helpers — canonical disk-backed toc tree

    step_c(container: TheC, n: number, key: string, soft=false): TheC|undefined {
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
        if (soft) return undefined
        const c = container.i(sc)
        container.bump_version()
        return c
    },

    The_step(w: TheC, n: number): TheC {
        return this.step_c(w.c.The, n, 'step')
    },

    // Story_demand_audio(w, secs, work) — the HARD audio demand.  A Book step whose ASSERTION needs the
    //  real voice calls this (NOT the soft Sound_gat, which just returns null and the caller skips).  The
    //   requirement is DISCOVERED by the call — Story needs no needs:audio tag on the Book.
    //    live context  → run work(gat) now, held by expecting()'s ttlilt for its wall-clock extent.
    //    cold context  → surface the "open share" gate on THIS tab (AudioContext_wanted, the very event
    //      Otro's merged gate listens for) and SIT up to `secs` for a human to grant it:
    //       granted in time → run work(gat) with the now-live voice (the test actually runs).
    //       `secs` elapses  → set w.c.step_blocked → the step lands a distinct UNTRIED verdict
    //         (!ok + error, nothing tried) — "couldn't run here", never "the audio delivery is broken".
    //   Fire-and-forget (expecting is non-blocking, holds Story via the ttlilt); the caller need not await.
    Story_demand_audio(w: TheC, secs: number, work: (gat: any) => Promise<any>): TheC {
        const H = this as House
        const top = H.top_House()
        let gat = (top.c as any).musu_gat
        if (typeof AudioContext !== 'undefined' && !gat) { gat = new SoundSystem({}); (top.c as any).musu_gat = gat }
        if (gat && !gat.AC_ready && typeof window !== 'undefined') {
            window.dispatchEvent(new CustomEvent('AudioContext_wanted', { detail: { gat } }))
        }
        return H.expecting(w, 'audio_demand', secs, async () => {
            const deadline = now_in_seconds_with_ms() + secs
            while (now_in_seconds_with_ms() < deadline) {
                if (gat && gat.AC_ready) break
                await new Promise(r => setTimeout(r, 200))
            }
            if (gat && gat.AC_ready) await work(gat)
            else (w.c as any).step_blocked = 'AudioContext not granted'
        })
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

//#endregion
//#region The/Styles|Opt|Plan — the Story's instructions

    // The_Styles(w): Story's specific way of finding its styles bucket —
    // it lives under w.c.The/{Styles:1}.  Other clients (Lang etc.)
    // can either call this with their own w that has a .c.The, or bring
    // their own plain TheC with {Styles:1} sc.
    The_Styles(w: TheC): TheC {
        const The = w.c.The as TheC
        if (!The) throw '!The for matstyles'
        return The.o({ Styles: 1 })[0] as TheC ?? The.i({ Styles: 1 })
    },
    
    The_Opt(w: TheC): TheC {
        // find-or-create The/{Opt:1}, the options bucket.
        // mirrors The_Styles — same pattern, same rules.
        const The = w.c.The as TheC
        if (!The) throw '!The for Opt'
        return (The.o({ Opt: 1 })[0] as TheC) ?? The.i({ Opt: 1 })
    },
 
    The_Plan(w: TheC): TheC {
        // find-or-create The/{Plan:1}, the phases bucket.
        const The = w.c.The as TheC
        if (!The) throw '!The for Plan'
        return (The.o({ Plan: 1 })[0] as TheC) ?? The.i({ Plan: 1 })
    },
 
    The_Plan_Prep(w: TheC, n: number,soft=false): TheC {
        // find-or-create The/Plan/{Prep:N}.
        // Delegates to step_c so it bumps planC version on creation,
        // using the same find-or-create idiom as The_step.
        return this.step_c(this.The_Plan(w), n, 'Prep',soft)
    },

    async Story_prepare_Prep(w:TheC,Run:House,run:TheC) {
        let n = run.c.step_n
        let Prep = this.The_Plan_Prep(w,n,true)
        run.c.Prep = Prep
        if (Prep) {
            let some = false
            // < inject w** at this step, similar to Opt/For/w:Such
            for (let ha of Prep.o()) {
                if (ha.sc.i_elvisto && ha.sc.e) {
                    let esc = {}
                    ha.o({esc:1}).map(n => esc[n.sc.esc] = n.sc.v)
                    Run.i_elvisto(ha.sc.i_elvisto,ha.sc.e,esc)
                    some = true
                }
                else {
                    throw `unknown Plan/Prep/* ${objectify(ha)}`
                }
            }
            if (some) {
                await new Promise(resolve => setTimeout(resolve, 100))
            }
        }
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
            } else if (sc.Styles != null && d === 1) {
                // reuse the Styles bucket created by Story_plan
                particle = this.The_Styles(w)
                ex(particle.sc, sc)
            } else if (sc.Opt != null && d === 1) {
                // reuse the Opt bucket created by Story_plan.
                // Children (For, bucket names, option particles) are inserted
                // generically below — the special case is only the bucket itself
                // so identity is stable (same C object as w.c.Opt).
                particle = this.The_Opt(w)
                ex(particle.sc, sc)
            } else if (sc.Plan != null && d === 1) {
                // reuse the Plan bucket created by Story_plan.
                particle = this.The_Plan(w)
                ex(particle.sc, sc)
            } else if (sc.Prep != null && d === 2 && parents[0] != null) {
                // Prep particles under Plan — use The_Plan_Prep for stable identity.
                // parents[1] is The/Plan; we check it is actually planC.
                const planC = this.The_Plan(w)
                if (parents[1] === planC) {
                    particle = this.The_Plan_Prep(w, sc.Prep as number)
                    ex(particle.sc, sc)
                } else {
                    // Prep at depth 2 but not under Plan — generic insert
                    particle = parent.i(sc)
                }
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
            if (ev.tag?.startsWith('begin')) {
                if (begin_t !== null) throw `sum_beliefs_time: nested begin without done`
                begin_t = ev.t
            } else if (ev.tag === 'done' || ev.tag?.startsWith('Exception')) {
                if (begin_t === null) throw `sum_beliefs_time: done without begin`
                total_ms += ev.t - begin_t
                begin_t = null
            }
        }
        if (begin_t !== null) throw `sum_beliefs_time: trace ends with unclosed begin`
        return total_ms / 1000
    },

    // ── spool_time_sample ─────────────────────────────────────────────────────
    // Append one seconds value to a {TimeTotal} particle, trim to 10 oldest-first,
    // recompute avg.  The particle is the caller's responsibility to find or create
    // (Auto uses a per-book one; Story uses The/TimeSpool/{TimeTotal:'beliefs'}).
    //
    // .at is wall-clock seconds — when this measurement was taken,
    // not the duration itself (which is in .sample).
    spool_time_sample(tt: TheC, seconds: number) {
        const H = this as House
        tt.i({ sample: Math.round(seconds * 1000) / 1000, at: now_in_seconds() })

        // sort oldest-first so whittle_N evicts from the front
        const samples = (tt.o({ sample: 1 }) as TheC[])
            .sort((a, b) => (a.sc.at as number) - (b.sc.at as number))
        H.whittle_N(samples, 10)

        // recompute avg from survivors
        const survivors = tt.o({ sample: 1 }) as TheC[]
        const avg = survivors.reduce((s, n) => s + (n.sc.sample as number), 0) / survivors.length
        tt.sc.avg = Math.round(avg * 1000) / 1000
    },

    // ── collect_time_sample ───────────────────────────────────────────────────
    // Called once on test completion (both new and check end-branches in
    // story_drive). Sums the beliefs-mutex time across every step that actually
    // ran this session (anything in This with a Run_trace), then spools one
    // sample into The/TimeSpool/{TimeTotal:'beliefs'} via spool_time_sample.
    //
    // Lives in The (not This) so it round-trips through toc.snap and accumulates
    // history across sessions — the whole point is being able to look back over
    // recent runs and see "is this test getting slower" / "roughly how long does
    // this test take to run".
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

        H.spool_time_sample(tt, run_total_seconds)

        // Per-step average: run total / steps that ran, spooled as a sibling TimeTotal
        //  so it averages across recent runs too — a glanceable "roughly how long each
        //  step takes" for the run bar (story_analysis surfaces it as avg_step).
        const st = (spool.o({ TimeTotal: 'step' })[0] as TheC)
                ?? spool.i({ TimeTotal: 'step', avg: 0 })
        H.spool_time_sample(st, run_total_seconds / ranSteps.length)

        ;V.Story && console.log(`⏱ TimeSpool/beliefs +sample=${run_total_seconds.toFixed(3)}s avg=${tt.sc.avg}s n=${tt.o({ sample: 1 }).length} step_avg=${st.sc.avg}s`)
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
//  Dispatched by the UI via storyH.i_elvisto('Story/Story', 'story_add_note', {…}).
//
//  note_sc format: { note:1, <typeKey>:<value>, … }
//    e.g. { note:1, frontier:1 }     — moves the frontier to this step
//         { note:1, todo:"fix me" }  — free-text annotation
//
//  The UI builds note_sc via peel(userstring) then prepends note:1.
//    peel("frontier")       → { frontier:1 }
//    peel("todo:fix me")    → { todo:"fix me" }

    async e_story_add_note(A: TheC, w: TheC, e?: TheC) {
        // note_sc from the UI: plain type keys, e.g. {frontier:1} or {todo:"fix me"}.
        // step_i_note prepends note:1 itself, so the UI does not need to include it.
        // frontier is a singleton: 'move' ensures only one exists across all steps.
        const n       = e?.sc.step_n  as number | undefined
        const note_sc = e?.sc.note_sc as Record<string,any> | undefined
        if (n == null || !note_sc) return
        const mode = ('frontier' in note_sc) ? 'move' : 'add'
        this.step_i_note(w, n, note_sc, mode)
    },

    async e_story_delete_note(A: TheC, w: TheC, e?: TheC) {
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

        // A step is "bad" (offerable to Accept All) when it mismatches OR when it
        //  passed against toc but its on-disk NNN.snap fixture drifted (disk_ok===false).
        const bad_count = thisC ? (thisC.o({ Step: 1 }) as any[])
            .filter(s => !s.sc.accepted && (!s.sc.ok || s.sc.disk_ok === false)).length : 0

        const an        = ave.oai({ story_analysis: 1 })
        an.sc.run_sc    = run ? { ...run.sc } : null
        an.sc.frontier  = frontier
        an.sc.open_at   = open_at
        an.sc.bad_count = bad_count
        an.sc.steps     = the_steps
        an.sc.notes     = notes
        // avg_step: averaged per-step time from The/TimeSpool (set on run completion by
        //  collect_time_sample) — null until the first run finishes.  Glanced in the run bar.
        an.sc.avg_step  = ((The?.o({ TimeSpool: 1 })[0] as TheC)?.o({ TimeTotal: 'step' })[0]?.sc.avg as number) ?? null
        ;V.Story && console.log(`📊 story_analysis: the_steps=${the_steps.length} live=${(w.c.This)?.o({Step:1}).length ?? 0} frontier=${frontier}`)
        ave.bump_version()
    },

    async e_story_sel(A: TheC, w: TheC, e?: TheC) {
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

    async e_story_accept_all(A: TheC, w: TheC) {
        // Accept every !ok step in This at once.  Used after a lenient run that
        // accumulated multiple mismatches.  Promotes all diges into The, marks
        // accepted, keeps got_snap for story_save to write (5-step trim cleans up
        // after save).
        const H   = this
        const run = w.o({ run: 1 })[0]
        if (!run) return
        // !ok mismatches plus disk-stale ok steps (disk_ok===false) — Accept All
        //  rewrites the drifted fixtures alongside the genuine mismatches.
        const allBad = (w.c.This?.o({ Step: 1 }) ?? []).filter(s => !s.sc.ok || s.sc.disk_ok === false)
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

    async e_story_accept(A: TheC, w: TheC, e?: TheC) {
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

    // ── entropy authoring — mint / unmint an Entcase from ui/EntropyArrest ──────
    //
    //  The UI never mutates The directly: it authors a plain draft descriptor and
    //   hands it here as a JSON string (cap_json) — elvisto args ride as scalar sc,
    //    and a nested locator would be a fatal object-in-sc, so it crosses the seam
    //     serialised.  entropy_mint turns it into the snap-safe %lematch/%spayer
    //      shape; story_save re-encodes The/** to toc.snap.  A restart re-reads the
    //       caps via entropy_rules — the UI tells the user so.  This is the only path
    //        that persists a cap, the deliberate "click OK to actually put them in"
    //         so we never drown in half-formed rules.
    async e_entropy_commit(A: TheC, w: TheC, e?: TheC) {
        const H = this
        const raw = e?.sc.cap_json as string | undefined
        if (!raw) return
        let draft: any
        try { draft = JSON.parse(raw) } catch { return }
        // a draft carries a means descriptor: spayer (needs a re), or a structural drop /
        //  dontSnap (no captures).  Back-compat: an older draft.spayer implies kind:'spayer'.
        const means = draft?.means ?? (draft?.spayer ? { kind: 'spayer', ...draft.spayer } : null)
        if (!draft?.slug || !means?.kind) return
        if (means.kind === 'spayer' && !means.re) return
        draft.means = means
        // draft.ref set ⇒ editing a SHARED cap: mint into the borrowed profile Waft's bucket and
        //  persist the profile's OWN toc.snap (Lies_waft_save) so every borrower gets it; the live
        //   C edit + story_analysis re-bites this run immediately.  No ref ⇒ a local cap in The.
        const ref = draft.ref as string | undefined
        if (ref) {
            const loc = H.entropy_profile_loc(ref)
            if (!loc) { console.warn(`entropy_commit: profile ${ref} not loaded — cannot edit shared cap`); return }
            H.entropy_mint_into(loc.ea, draft)
            loc.waft.bump_version()
            H.Lies_waft_save(loc.lies_w, loc.waft)
            // Lies_waft_save only QUEUES the write on loc.lies_w's req:Store (leading throttle → post_do);
            //  an idle editor wouldn't pump it until the next mo:main heartbeat (~seconds), so the profile's
            //   toc.snap lagged the live edit.  Keep the loop awake so the queued write lands this beat.
            H.top_House().demand_time_to_think(1000)
            H.story_analysis(w)
            ;V.Story && console.log(`🛑 entropy_commit (shared ${ref}) Entcase:${draft.slug} (${means.kind}${means.tol ? ' ' + means.tol : ''})`)
            return
        }
        H.entropy_mint(w, draft)
        H.story_analysis(w)
        H.story_save()
        ;V.Story && console.log(`🛑 entropy_commit Entcase:${draft.slug} (${means.kind}${means.tol ? ' ' + means.tol : ''})`)
    },

    async e_entropy_delete(A: TheC, w: TheC, e?: TheC) {
        const H = this
        const slug = e?.sc.slug as string | undefined
        if (!slug) return
        const ref = e?.sc.ref as string | undefined
        if (ref) {
            const loc = H.entropy_profile_loc(ref)
            if (loc && H.entropy_unmint_from(loc.ea, slug)) {
                loc.waft.bump_version()
                H.Lies_waft_save(loc.lies_w, loc.waft)
                H.top_House().demand_time_to_think(1000)   // pump the queued profile write this beat, not on the heartbeat
                H.story_analysis(w)
                ;V.Story && console.log(`🗑 entropy_delete (shared ${ref}) Entcase:${slug}`)
            }
            return
        }
        if (H.entropy_unmint(w, slug)) {
            H.story_analysis(w)
            H.story_save()
            ;V.Story && console.log(`🗑 entropy_delete Entcase:${slug}`)
        }
    },

    async e_story_resnap(A: TheC, w: TheC) {
        // Resnapture: anchor %first_snap (once) then re-fire snap_step_after_wave
        // to produce a fresh %got_snap.  The diff between the two is shown in
        // Storui's popup so you can see what changed while poking at the UI.
        //
        // first_snap is only captured if absent — subsequent Resnaps accumulate
        // got_snap drift away from the original anchor, not from each other.
        //
        // resnap_count increments each time; story_analysis spreads run.sc into
        // an.sc.run_sc so Storui's $effect detects the bump without a dedicated
        // channel.  resnap_n is the step being resnapped (always run.c.step_n).
        const H   = this
        const run = w.o({ run: 1 })[0]
        if (!run) return
        const n = run.c.step_n as number | undefined
        if (n == null) return

        const step = H.i_step(w, n)
        if (step.sc.got_snap && !step.sc.first_snap) step.sc.first_snap = step.sc.got_snap

        run.sc.resnap_n     = n
        run.sc.resnap_count = ((run.sc.resnap_count as number) ?? 0) + 1

        const resume = run.c.snap_step_after_wave as (() => Promise<void>) | undefined
        if (!resume) {
            console.warn('Resnap: no snap_step_after_wave on run.c (no step driven yet?)')
            return
        }
        if (run.sc.paused && run.sc.paused !== 2) run.sc.paused = 0
        run.c.driving = true
        H.story_analysis(w)   // pump resnap_count to Storui before snap arrives
        H.post_do(resume, { see: 'Resnapture' })
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
    // see lematch
    story_matching: [
        {
            // House-level particles: skip timers entirely. A %mo (mo:main — the
            //  interval pump) is runtime plumbing, not test signal, and its handle
            //  renders differently per host (a browser timer id vs a node Timeout),
            //  so it is pure snap noise. Skipping beats munging: the line never
            //  appears, in any channel or dige.
            matching_any: [{ sc_has: { H: 1 } }],
            means: {
                thence_matching: [
                    { matching_any: [{ sc_has: { mo: 1 } }],
                      means: { skip: true } },
                ]
            }
        },
        {
            // Actor / worker level: skip self-ref bookkeeping; mung timestamps
            matching_any: [{ sc_has: { A: 1 } }, { sc_has: { w: 1 } }],
            means: {
                thence_matching: [
                    { matching_any: [{ sc_only: { self: 1, est: 1 } }],
                      means: { skip: true } },
                    { matching_any: [{ sc_only: { self: 1, round: 1, age: 1 } }],
                      means: {
                          // age is a pure-noise sidecar timestamp → drop (munged out).
                          // round is the per-tick counter: it churns run-to-run (the
                          //  ticks a step takes is non-deterministic), so a kept round=N
                          //   flakes the dige every run.  v2 spay (EntropyArrest.md §8):
                          //    capture the value, tol:any → at compare it grafts got's round
                          //     onto exp's, unconditionally (a counter that could drift across
                          //      a band boundary would re-introduce the flake — the doc chose
                          //       the unconditional path).  The presence/shape of the counter
                          //        is still asserted; only its churning value is forgiven.
                          // The re matches the WHOLE token and the `=N` is OPTIONAL — because
                          //  depeel renders the canonical flag value 1 as a BARE key (round=1 →
                          //   `round`, round>1 → `round=N`).  Whether a step happens to land at
                          //    round 1 differs across runners (headless Story_cli boots in fewer
                          //     ticks than a browser), so one side serialises bare `round` and the
                          //      other `round=7`.  A `round={NUM}` re only matches the `=N` form, so
                          //       the bare side gives zero matches → match-count mismatch → graft
                          //        bails → a spurious Dif:change (the headless↔browser divergence).
                          //   No capture group: graft then rewrites capture-0 (the whole match), so
                          //    it reconciles the bare↔=N flip too, not just a value drift.  \b keeps
                          //     it off `background`/`roundtrip`.
                          munging: [{ these_sc: { age: 1 }, type: 'time' }],
                          spay: { re: '\\bround(?:=\\d+)?\\b', tol: 'any' },
                      } },
                    { matching_any: [{ sc_only: { wasLast: 1, at: 1 } }],
                      means: { munging: [{ these_sc: { at: 1 }, type: 'time' }] } },
                    { matching_any: [{ sc_only: { chaFrom: 1, was: 1, v: 1, at: 1 } }],
                      means: { munging: [{ these_sc: { at: 1 }, type: 'time' }] } },
                ]
            }
        },
        {
            // Lies real-IO epoch stamps — volatile `at`/`seeded`/`walked_at`/`noticed_at`
            //  on otherwise stable particles.  Mung them so a real w:Lies snap diffs on
            //   structure, not on WHEN a read/walk/seed/notice happened.  The content
            //    dige beside each stays, so a real change still shows.  Needed for the
            //     real Lang↔Lies channel (Book:LakeSurprise et al.) to settle as a gate.
            matching_any: [
                { sc_has: { known: 1, at: 1 } },          // Good/known,dige,kind:read,at
                { sc_has: { Waft: 1, seeded: 1 } },       // Waft:GhostList,lists,seeded
                { sc_has: { Funkcion: 1, walked_at: 1 } },// Funkcion:dirlist,…,walked_at
                { sc_has: { Doc: 1, noticed_at: 1 } },    // GhostList Doc rows,…,noticed_at
            ],
            means: { munging: [
                { these_sc: { at: 1 },         type: 'time' },
                { these_sc: { seeded: 1 },     type: 'time' },
                { these_sc: { walked_at: 1 },  type: 'time' },
                { these_sc: { noticed_at: 1 }, type: 'time' },
            ] },
        },
        {
            // GhostList's dirlist read — req:Store records reading the GhostList Good with a
            //  content `dige` that fingerprints the ghost-pile DIRECTORY LISTING.  That listing
            //   genuinely changes whenever the wormhole gains|loses a dir (a new Story Book, a
            //    Credulate folder), so the dige flaked the gate run-to-run for EVERY Book that
            //     folds the GhostList Waft (dontSnapGhostList) — yet the listing is the same
            //      test-irrelevant churn those Books already fold at the Waft.  Spay tol:any
            //       forgives the VALUE (grafts got→exp) while keeping the line, so no fixture
            //        re-records and the read stays observable.  SCOPED by the parent Good's
            //         waft_path, so LakeSurprise's REAL content reads still gate on their dige
            //          (the rule above deliberately keeps every other read's dige).
            matching_any: [{ sc_has: { Good: 1, waft_path: 'GhostList' } }],
            means: { thence_matching: [
                { matching_any: [{ sc_has: { known: 1, kind: 'read' } }],
                  means: {
                      munging: [{ these_sc: { at: 1 }, type: 'time' }],
                      spay: { re: 'dige:[0-9a-f]+', tol: 'any' },
                  } },
            ] },
        },
        {
            // Equipment Wafts (%equip — Keep | Cluster | Credence | GhostList): backstage
            //  fixtures whose guts churn every tick (a Keep's WaftTimes ledger, the cluster's
            //  Aim watchers) and are never test signal.  Fold the subtree — emit the Waft's
            //  own line so the snap still shows the equipment is present, prune below it.
            //   dontSnap not skip keeps the header, and an equip Waft can still enWaft to its
            //    OWN home: this rule only governs the enclosing w:Lies snap.
            //  Hardcoded, not a stored %lematch Entcase — a fixed structural rule nobody edits
            //   as C (you only reach for %lematch when the rule is C** you want enWaft-able).
            matching_any: [{ sc_has: { Waft: 1, equip: 1 } }],
            means: { dontSnap: true },
        },
        {
            // ttlilt timers carry until_ts — an absolute wall-clock deadline (now + ttl,
            //  set in Hovercraft when a req arms a timed pause).  It is non-deterministic
            //   every run, like %mo: a snap should diff on the presence/shape of the pause,
            //    not on WHEN it would expire.  The stable ttl rides in the ref string, so
            //     munging the value loses no test signal.  Catches both the req-nested and
            //      the w-level (of_w) ttlilt particles.
            matching_any: [{ sc_has: { ttlilt: 1 } }],
            means: { munging: [{ these_sc: { until_ts: 1 }, type: 'time' }] },
        },
        {
            // %Lango source terminals — the per-w ordering token `seq` (Backbone_plan P3) is a
            //  monotonic counter bumped on every mint; its BASE churns run-to-run with whatever
            //   boot cursor activity preceded the step (and headless boots in fewer ticks than a
            //    browser), so a kept seq=N flakes the gate like `round`/`at`.  Mung the value: the
            //     structure (which Lango on which carrier, its `to` target) stays the gate, only
            //      the ordering value is forgiven.  req:Langoer's verdict (req:Langoer,focus) is
            //       seq-INDEPENDENT (it names the winning Waft), so it still diffs.
            matching_any: [{ sc_has: { Lango: 1 } }],
            means: { munging: [{ these_sc: { seq: 1 }, type: 'count' }] },
        },
        {
            // Story work particle itself — any object ref on w that wasn't caught
            // by the rules above (The, toc_loaded, wh, run_path, etc.) is left to
            // the objectify() fallback in story_process_node, which puts it into
            // objecties.ref.  That ref is excluded from diff comparisons (only
            // stringies are diffed), so it is effectively munged without explicit
            // listing.  Add explicit munging entries here if a ref becomes noisy.
            matching_any: [{ sc_has: { Story: 1 } }],
            means: { thence_matching: [] }
        },
        {
            // source code comes out readable
            matching_any: [{ sc_has: { Compile:1, } }],
            means: {
                thence_matching: [
                    { matching_any: [{ sc_has: { Output:1, source:1, dige:1 } }],
                      means: { blockquote_these_sc: {source:1} } },
                ]
            }
        },
        {
            matching_any: [{ sc_has: { w: 'TextInca' } }],
            means: { thence_matching: [
                { matching_any: [{ sc_has: { enc_test: 1 } }],
                means: { blockquote_these_sc: { snap_output: 1 } } },
            ]},
        },
        {
            // reqy bookkeeping container — never interesting in a snap
            matching_any: [{ sc_only: { reqcons: 1 } }],
            means: { skip: true }
        },
        {
            // %see particles carrying a raw string payload (encode dumps, etc.)
            // BQ-renders the string key so multi-line text reads at odd indent.
            matching_any: [{ sc_has: { see: 1, string: 1 } }],
            means: { blockquote_these_sc: { string: 1 } },
        },
    ] as Array<any>,

    // classify one particle during the snap walk.
    // builds stringies (serialisable diff-comparable values),
    // ref (object values → stable ids via objectify — excluded from diff),
    // mung (keys deliberately excluded, e.g. timestamps).
    // sets T.sc.not=1 to skip the particle entirely.
    // sets D.sc.snap_line — the complete encoded line (indent + objecties + tab +
    //   stringies), used directly by story_snap and compared in traced_fn.
    story_process_node(n: TheC, T: Travel, D: TheD, entropy?: Array<any>) {
        // compile = story_matching ∪ entropy_rules(w.c.The) (EntropyArrest.md §3.2):
        //  the global default layer in code, plus this Book's authored per-test caps.
        //  At encode only the structural means bite (skip/mung/bq/drop); blank/band
        //   forgiveness is deferred to spay_normalize at compare time (the §2.3' pivot).
        const active: Array<any> = [
            ...this.story_matching,
            ...(entropy ?? []),
            ...(T.sc.up?.sc.thence_matching ?? []),
        ]
        const q: any = {
            d:      T.c.path.length - 1,
            rules:  active,
            loopy:  T.sc.loopy,   // integer serial — this is the shallowest/original appearance
        }
        const lines = this.enLine(n, q)

        if (q.skip) { T.sc.not = 1; return }
        if (!lines) throw "!lines"
        // a dontSnap means (EntropyArrest §5) emits this line but folds the subtree away;
        //  forward it onto the Travel so snap_H prunes T.sc.more, same as the n.sc.dontSnap
        //   node flag.
        if (q.dontSnap) T.sc.dontSnap = 1

        D.sc.stringies = q.stringies
        D.sc.objecties = q.objecties
        D.sc.copy = { ...n.sc }
        D.sc.snap_line = lines.join("\n")
        // a folded node leaves a trace so the snap shows its subtree was omitted on PURPOSE, not
        //  absent — but as a snapped flag, not prose: enLine stamps objecties.dontSnap=1 for a
        //   means fold (rides beside loopy → {"dontSnap":1}), and the %dontSnap node-flag already
        //    surfaces dontSnap:1 in its stringies.  No child count — that would churn the very
        //     line we fold to keep stable (a Keep's ledger only grows).
        if (q.mung?.length) { D.c.munged ??= []; D.c.munged.push(q.mung) }
        if (q.thence?.length) T.sc.thence_matching = q.thence
    },

    // ── snap_H ────────────────────────────────────────────────────────────────
    // The H-structure portion of the full snap.
    // Exactly what story_snap used to do — walk Run via Selection,
    // encode each particle as a snap line, return joined string.
    // snap_Se lives here; traced_fn compares snap_line strings across runs.

    async snap_H(Run: House, w?: TheC): Promise<string> {
        const lines: TheD[] = []
        const loopy_Cs = new Set<TheC>()   // C** that appeared more than once (loopy)
        // per-test EntropyArrest caps, compiled once per snap into matching rules (§3.2).
        //  At encode these contribute only structural means (drop); their blank/band
        //   spayers are consumed at compare time by spay_normalize / collect_spayers.
        const entropy = this.entropy_rules(w?.c.The as TheC | undefined)
        // %dontSnapVoronoiology (fig.1) — a Story-side snap concern: the fold still BUILDS its
        //  w:Voronoiology self-report, but this Book prunes it from the record (MusuReplica keeps
        //   its replication fixture clean).  Vanish entirely, like %boring, targeted at that world.
        const dropVoro = w ? Boolean((this as any).The_Opt_val(w, 'dontSnapVoronoiology')) : false

        Run.c.snap_Se ??= new Selection()
        const Se: Selection = Run.c.snap_Se

        await Se.process({
            n:                  Run,
            process_sc:         { snap_root: 1 },
            match_sc:           {},
            trace_sc:           { snap_node: 1 },
            loop_but_no_further: true,   // loopy C reaches each_fn with T.sc.loopy set

            each_fn: async (D: TheD, n: TheC, T: Travel) => {
                if (T.sc.loopy) {
                    // subsequent appearance of a C seen earlier in this walk
                    loopy_Cs.add(n)
                    return
                }
                this.story_process_node(n, T, D, entropy)
                if (T.sc.not) return
                if (T.c.path.length === 1) {
                    T.sc.more = (n.o({})).filter(c => !c.sc.snap_root)
                }
                // %boring: backstage infrastructure (a borrowed EntropyProfile Waft and
                //  its load Good) — vanish ENTIRELY from the snap, line and subtree, so a
                //   test that borrows a profile reads no differently from one that inlines it.
                //  T.sc.not (not just skipping lines.push) is what hides it: the loopy-ref
                //   rebuild pass below re-collects every D with a snap_line, and only T.sc.not
                //    survives that — story_process_node already stamped this node's snap_line.
                if (n.sc.boring || T.sc.boring) { T.sc.more = []; T.sc.not = true; return }
                // %dontSnapVoronoiology: the fold's projection world vanishes entirely from this snap.
                if (dropVoro && n.sc.w === 'Voronoiology') { T.sc.more = []; T.sc.not = true; return }
                // fold: a %dontSnap node emits its own line but hides its subtree.
                //  Snap-only — the node keeps pumping; orthogonal to inclusion. Used
                //  to retire compile scaffolding (w:Lies/w:Lang) from a runner snap
                //  once the apparatus is ready, leaving the run state legible.
                if (n.sc.dontSnap || T.sc.dontSnap) T.sc.more = []
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

        // ── ref pass: stamp loopy:N on originals, hid:1 stubs on revisits ────────
        // loop_but_no_further lets revisited C** reach each_fn with T.sc.loopy set
        // and T.sc.no_further set.  loopy_Cs collects those C**.
        // forward() replays all Ts; T.sc.no_further is the stub signal — the first
        // DFS encounter (no no_further) is always the structural home/original.
        // Idempotent: story_process_node fully rebuilds D.sc.snap_line each call.
        //
        // Stub format: stringies with every key set to 1 (a munged shadow —
        // reads like the object, hid:1 in objecties marks it as the shadow).
        if (loopy_Cs.size > 0) {
            let loopy_i = 0
            const loopy_ids = new Map<TheC, number>()
            for (const n of loopy_Cs) loopy_ids.set(n, loopy_i++)

            // encode pass: T.sc.no_further marks every revisit (set by loop_but_no_further
            // in dive_start when a C is seen for the second+ time).  That T is the stub;
            // the earlier T without no_further is the original.  No pre-scan needed.
            await Se.c.T!.forward(async (T: Travel) => {
                const n  = T.sc.n as TheC
                const id = loopy_ids.get(n)
                if (id === undefined) return

                if (!T.sc.no_further) {
                    // first DFS encounter — the structural home; re-encode with loopy integer
                    T.sc.loopy = id
                    this.story_process_node(n, T, T.sc.D, entropy)
                } else {
                    // revisit — stub: munged shadow, every key shown as :1
                    // hid:1 marks this as the shadow; the original carries loopy:N only
                    const d      = T.c.path.length - 1
                    const shadow = Object.fromEntries(Object.keys(n.sc ?? {}).map(k => [k, 1]))
                    T.sc.D.sc.snap_line = this.enL({ d, stringies: shadow, objecties: { loopy: id, hid: 1 } })
                }
            })

            // rebuild lines in walk order — loopy stubs now have snap_line too
            lines.length = 0
            await Se.c.T!.forward(async (T: Travel) => {
                if (T.sc.not || !T.sc.D?.sc.snap_line) return
                lines.push(T.sc.D)
            })
        }

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
    // cyto_scan always runs regardless of waitCyto so the wave is always in
    // the dige.  cyto_update_wave's version-check makes this free when RunH
    // hasn't changed since the last ambient Cyto tick.
    // < more of these %Snap:* channels could be commissioned by something wanting more readings

    async story_snap(w:TheC,run:TheC,Run: House): Promise<string> {
        const H = this as House

        // Voro imposed from above (fig.1, Story_settingoff): fold a useVoroCyto Book's inner worlds
        //  HERE, at snap time, so the fold's c.stuff (live render) and its w:Voronoiology self-report
        //   (this snap) are both current before snap_H encodes.  Skip w:Voronoiology itself — never
        //    fold the projection.  Fold-DRIVING demos (VoroMitosis/VoroRadio) lack the Opt and fold
        //     themselves inline, so they are untouched here.
        if (H.The_Opt_val(w, 'useVoroCyto'))
            for (const rw of (Run.o({ A: 1 }) as TheC[]).flatMap((a: TheC) => a.o({ w: 1 }) as TheC[]))
                if (rw.sc.w !== 'Voronoiology') await (H as any).Voro_crush_scan?.(rw)

        // Snap:H — indent +1 so content nests under the header
        const h_snap  = await this.snap_H(Run, w)
        const h_block = this.snap_indent(h_snap, 1)

        // Cyto is opt-in (Opt/useCyto).  Without it this Story has no Cyto of its own
        // (e.g. only Lang's Cyto is active, or none). Skip the cytowave block entirely —
        // it's not part of the model being tested, and waiting for it adds ~2s per step.
        //  Opt/dontSnapCyto folds the cytowave the same way while KEEPING the live Cyto
        //   commissioned (it still scans, animates, and gates waitCyto) — the graph is a view,
        //    not the subject, so a Book that wants to watch it needn't freeze the derived node
        //     positions into every fixture.
        if (!H.The_Opt_val(w, 'useCyto') || H.The_Opt_val(w, 'dontSnapCyto')) {
            return this.enL({ d: 0, stringies: { Snap: 'H' } }) + '\n' + h_block
        }

        // Snap:Cytowave — read whatever wave Cyto has currently.
        // Cyto is commissioned in Story_settingoff (just before step 1) and watches
        // Scannable (=Run) for version changes, so its wave is already current by the
        // time we snap.  No need to prod it here.
        // useCyto is guaranteed here (snap_H returned early above when off), so the world
        //  exists — Awo throws loudly if that invariant ever breaks.
        const cyto_w = H.Awo('Cyto') as TheC

        const wave     = cyto_w.c.gn?.sc.wave as any
        if (!wave) throw "!wave"
        const cw_block = this.snap_cytowave_str(wave)

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
        Run.c.no_ambient  = true   // story_drive owns the clock; suppress ambient tick
        Run.c.no_interval = true   // …so don't even arm the ambient %mo:main timer: it
                                   //  would re-fire main() every interval into a no-op
                                   //   (no_ambient), and its mo:main,interval particle is
                                   //    pure lies — Story never trickles on it.  Skipping
                                   //     reset_interval means no dead timer and nothing to
                                   //      draw (snap/Cyto/inspector); the %mo skip rule
                                   //       stays only as a net for other houses.
        // Inherit the boot-param role (?E=editor / ?B=runner) onto the Run House before its recipe
        //  runs — H.c.role is read here (the Run House), not on Mundo.  ??= so a Book booted from
        //   the Library (no param) still gets its recipe's own default.
        Run.c.role ??= (this.top_House() as any).c.boot_role

        if (!Run.oa({ A: 1 })) {
            const recipe = (Run as any)[`Run_A_${book}`] as Function | undefined
            if (recipe) {
                recipe.call(Run)
            } else {
                Run.i({ A: book }).i({ w: book })
            }

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
        //     /%UI:Story,component:Storui  — Otro mounts this via house.UIs
        //
        const H = this

        w.c.The  = w.i({ The:  1, story: book })
        // lazy-creates Styles bucket — encode_toc_snap walks The/** so this is free.
        // Matstyle ghost autovivifies entries here during cyto_scan.
        this.The_Styles(w)
        // phases bucket — stubbed; story_drive will consult this before each step.
        this.The_Plan(w)

        w.c.This = w.i({ This: 1, Story: book })

        const ave   = H.oai_enroll(H, { watched: 'ave' })
        // This appears in both w/* and ave
        ave.i(w.c.This)
        w.c.swatchC = ave.oai({ swatches: 1 })
        w.c.ave     = ave

        // live_poll — the overrun-monitor signal for Storui.  A stable same-object hold
        //  in the ave channel: poll_step writes the wedge tail into its .c and bumps its
        //   version DIRECTLY (the reactivity_docs "lever"), so the UI re-renders even while
        //    a wedged step keeps beliefs from ever flushing ave.  Everything rides in .c
        //     (Run ref, batch, flags) so nothing reaches the snap.
        w.c.live_poll = ave.oai({ live_poll: 1 })

        H.oai_enroll(H, { watched: 'actions' })

        // Register Storui in %watched:UIs so Otro can mount it for this house.
        // oai_enroll creates the container once and calls enroll_watched();
        // oai on the child is idempotent — subsequent Story_plan calls are no-ops.
        const uis = H.oai_enroll(H, { watched: 'UIs' })
        uis.oai({ UI: 'Story', component: Storui })

        const stylesC = this.The_Styles(w)
        H.watch_c(stylesC, async () => await H.story_save())

        // i The/Opt
        H.watch_c(this.The_Opt(w), async () => await H.story_save())

        // Cyto is NOT commissioned here.  Story_plan runs before the toc is decoded,
        //  so The/Opt/useCyto is not yet readable (it would always read false here).
        //   The commission moved to Story_settingoff, which runs once just before step 1
        //    with the toc decoded — see there.

        let total = 1   // user builds up the test step-by-step via Resume
        return w.i({ run: book, done: 0, total, paused: false, mode: 'new' })
    },

    Story_settingoff(w: TheC, Run: House, run: TheC) {
        // Called once, just before step 1 — toc decoded, Run wired.
        const H = this as House

        // ── commission Cyto ───────────────────────────────────────────
        // Stand up this Story's OWN Cyto world (e.g. the Leaf* tests) on demand, gated
        //  by The/Opt/useCyto.  This must run AFTER the toc is decoded — Story_plan runs
        //   before decode_toc_snap, when useCyto still reads false, so commissioning
        //    there silently never created A:Cyto/w:Cyto for a useCyto Book.  Doing it
        //     here, just before step 1, guarantees the Cyto world exists before
        //      snap_step's wave handshake calls i_elvisto('Cyto/Cyto', …) — otherwise
        //       that throws the fatal "no House has A:Cyto".  Idempotent on the create;
        //        a Book without useCyto never makes A:Cyto nor pays for its ticking.
        if (H.The_Opt_val(w, 'useCyto')) {
            if (!H.o({ A: 'Cyto' }).length) H.i({ A: 'Cyto' }).i({ w: 'Cyto' })
            const stylesC = this.The_Styles(w)
            const RunH = H.o({ H: 1, Run: 1 })[0]
            if (!RunH) throw "!H/%H,Run"
            const commission = new TheC({ c: {}, sc: {
                Scannable:          RunH,
                Styles:             stylesC,
                client_w:           w,
                supports_seek:      true,
                supports_takeTurns: true,
                wants_wave_done:      true,  // always — Story needs the wave before snapping
                wants_animation_done: true,  // Cyto sends these unconditionally
                                             //  Story ignores when !The/Opt/waitCyto
            }})
            // useVoroCyto rides ON the commission (fig.1) — the declared home for the fold switch;
            //  the imposition itself is Story-side in story_snap, but Cyto/◈ can read it here.
            if (H.The_Opt_val(w, 'useVoroCyto')) commission.sc.useVoroCyto = 1
            H.i_elvisto('Cyto/Cyto', 'Cyto_commission', { req: commission })
        }

        // The doorstep moment: gifts of Opt delivered for the journey.
        this.push_opt_to_run(w)

        // ── fig.1 · Voro is IMPOSED from above, like Cyto and Matstyle ──────────────────
        //  The fold ("crush") is a VIEWER.  A Book whose subject is not Voro never asks to be
        //   folded — Story imposes it, reading one toc Opt, right where it reads useCyto.  The old
        //    "blast" (stamp crush_wanted + voronoiology onto every Run/A/w) is GONE: no per-worker
        //     arming, and Voro_crush_scan/Voro_report carry no gate at all.
        //
        //    The/Opt (toc)          does                    read where
        //    ─────────────────────  ──────────────────────  ──────────────────────────────────────
        //    useCyto                commission a Cyto        Story_settingoff (above)
        //    useVoroCyto            impose the fold          story_snap → Voro_crush_scan per world
        //                             ↳ also stamped on the commission, beside Scannable/Styles
        //    dontSnapCyto           drop the cytowave        story_snap (skips Snap:cytowave)
        //    dontSnapVoronoiology   prune the projection     snap_H    (vanishes w:Voronoiology)
        //    waitCyto               block on animation       advance
        //
        //    Run/A:<Book>/
        //      w:<Book>        folded in place (c.stuff) at snap time — the Book never touched it
        //      w:Voronoiology  the fold's SELF-REPORT (Voro_report); snapped unless dontSnapVoronoiology
        //
        //  Exception BY SUBJECT: VoroMitosis (the fold) and VoroRadio (the radio that eats the fold)
        //   DRIVE Voro_crush_scan inline in their own do_fn — a test of the fold drives the fold — so
        //    they carry no useVoroCyto and Story imposes nothing on them.
    },

    push_opt_to_run(w: TheC) {
        // Walk The/Opt/For/* and for each {w:Name} bucket, find the matching
        // worker particle in Run (%A/%w:Name) and w.i() each option child into it.
        //
        // The/Opt/For/{w:Lang}     ← For/* must be {w:SomeName}, throws otherwise
        //   /{key:val, ...}             ← each child is i()'d verbatim into the target
        //   → Run/%A/%w:Lang       ← any A; matched by w key
        //
        // The option particles are the actual TheC objects from The**, so they
        // round-trip through toc.snap as part of The and don't need separate saving.
        const H    = this as any
        const optC = this.The_Opt(w)   // w.c.Opt is never assigned — go via The_Opt
 
        const forC = optC.o({ For: 1 })[0] as TheC | undefined
        if (!forC) return
 
        // get the Run sub-house; cheap when it already exists
        const sub = H.Story_subHouse(null, w)
        if (!sub) return
        const { Run } = sub
 
        for (const bucketC of forC.o({}) as TheC[]) {
            // For/* must be {w:SomeName} — anything else is a config error
            const w_name = bucketC.sc.w as string | undefined
            if (!w_name) throw `The/Opt/For/* must have a w key — got: ${JSON.stringify(bucketC.sc)}`
 
            // find Run/%A/%w:Name — search all actors for the matching worker
            const target = (Run.o({ A: 1 }) as TheC[])
                .flatMap(a => a.o({ w: w_name }) as TheC[])
                [0]
            if (!target) {
                // worker not yet mounted — safe to skip, push_opt_to_run is called
                // once at Story_plan time; the worker is responsible for reading
                // its own Opt on first tick if it mounts after plan time.
                continue
            }
 
            // i() each option child into the target's {Opt:1} container.
            // These are the real TheC objects from The**, so any future mutation
            // is visible in both The and the target without a second push.
            const targetOpt = target.oai({ Opt: 1 })
            for (const optParticle of bucketC.o({}) as TheC[]) {
                targetOpt.i(optParticle)
            }
        }
    },
    // The_Opt_val: find the first {key:*} child of The/Opt and return its value.
    //   Returns the stored value itself (number, string, truthy/falsy) — not just bool.
    The_Opt_val(w: TheC, key: string): boolean {
        return this.The_Opt(w).o({ [key]: 1 })[0]?.sc[key]
    },
    // ── o_Opt_k ──────────────────────────────────────────────────────────────
    //
    //   Read a named opt from w/{Opt:1}/{k:1}.
    //   Returns false when the Opt container or key particle is absent.
    //
    //   Other H%Run clients (Lies, Pantheate, …) call this directly
    //   instead of Story's The_Opt_val(), which has the full The/* hierarchy.
    o_Opt_k(w: TheC, k: string): boolean {
        return !!w.o({ Opt: 1 })[0]?.oa({ [k]: 1 })
    },

//#region w:Story

    async Story(A: TheC, w: TheC) {
        const H    = this
        // Stall — visibly, greppably — while the Creduler is still loading the runtime
        //  ghosts: the editor's compiled code must be live on H before any Story begins
        //   (Run_A_<Book> itself is one of those loaded methods).
        if (H.oa({ Creduler_pending: 1 })) return w.i({ waits: 'loadingcoding' })
        const sub  = H.Story_subHouse(A, w)
        if (!sub) return
        const { Run, book } = sub

        // Story_plan runs once — creates everything. If run exists, everything else does too.
        let run = w.o({ run: book })[0]
        if (!run) run = H.Story_plan(A, w, book)
        // < what's vanishing ave/Styles? when ~open_at it vanishes momentarily
        const ave = this.oai_enroll(this, { watched: 'ave' })
        if (!ave.oa({ Styles: 1 })) ave.i(this.The_Styles(w))

        const fs_safe  = (s: string) => s.replace(/[:/\\?*"|<>]/g, '-')
        const run_path = `Story/${fs_safe(book)}`
        const wh       = w.oai({ wh: 1 })   // off-pump queue: serial %req items, owner-driven

        if (!run.c.toc_loaded) {
            // ── load toc.snap ──────────────────────────────────────────────
            const toc_req = await wh.oai({ req: 'read_toc', wh_path: run_path, wh_op: 'read_toc' })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req }))
                return w.i({ see: '⏳ toc...' })

            // A FAILED read must never decode as an empty toc: decode('') flips the run
            //  to 'new' mode, and the next story_save writes a Step-less skeleton over
            //   the recorded fixture (that clobber shipped 2026-07-04 — a proxy runner's
            //    read_toc raced the editor's DirectoryListing.expand and got not_found
            //     for a Book that was on disk).  error → drop the req and re-ask, loudly,
            //      forever; the first not_found → re-ask ONCE to confirm before accepting
            //       new-Book status.  A genuinely new Book pays one extra round-trip.
            const reply = toc_req.sc.reply
            if (reply?.error || (reply?.not_found && !run.c.toc_notfound_once)) {
                if (reply?.not_found) run.c.toc_notfound_once = true
                wh.drop(toc_req)
                return w.i({ see: reply?.error
                    ? `📭 toc read failed: ${reply.error} — retrying`
                    : '📭 toc not found — confirming...' })
            }
            const toc_snap = reply?.toc_snap ?? ''
            H.decode_toc_snap(toc_snap, w)   // fills The + pre-creates hollow This/{Step:N}

            const step_count = (w.c.The)?.o({ step: 1 }).length ?? 0
            run.sc.mode      = step_count > 0 ? 'check' : 'new'
            run.sc.frontier  = H.The_frontier(w)   // restored from {note:1,frontier:1}
            w.c.run_path     = run_path
            w.c.wh           = wh
            run.c.toc_loaded = true
            w.c.exp_snaps    = {}            // fresh fixture cache per toc load (see preload below)
            delete run.c.exps_loaded
            H.story_analysis(w)
        }

        // ── open shared EntropyProfiles as canonical Lies Wafts ────────────
        // The/EntropyProfile,Wref:<path> borrows another Waft's EntropyArrest
        //  Entcases.  Open it as a real Lies Waft (deWaft'd to a live C tree that
        //   autosaves on edit; entropy_rules reads it off the roster).  Aim the open
        //    at the OUTSIDE Lies — `top_House().i_elvisto` resolves from Mundo's
        //     vantage, so _find_house lands on Mundo's `Lies,runner` (which sits
        //      outside the test's H:Run subtree, so the profile never enters the test
        //       snap and is cached across runs).  Where Mundo has no Lies (a plain
        //        editor), the resolver falls back to the nearest = the inner Run Lies,
        //         and the %boring / defer / acquire-filter guards below keep that inner
        //          case from disturbing the snap.  Timing: fire ONCE per profile, never
        //           block, and wait until the test's own (non-boring) Waft is open so an
        //            inner-Lies open can't reorder w:Lies's reqs before the Preps run.
        {
            const The = w.c.The as TheC | undefined
            const foreground_up = H.top_House().all_House.some((h: any) => {
                const lw = (h.o({ A: 'Lies' })[0] as TheC | undefined)?.o({ w: 'Lies' })[0] as TheC | undefined
                return !!lw && (lw.o({ Waft: 1 }) as TheC[]).some(wf => !wf.sc.boring)
            })
            if (foreground_up) for (const p of (The?.o({ EntropyProfile: 1 }) ?? []) as TheC[]) {
                const ref = p.sc.Wref as string | undefined
                if (!ref || p.c.opened) continue                   // fire-once (c. is runtime, unsnapped)
                if (H.entropy_profile_waft(ref)) { p.c.opened = true; continue }  // already in a roster
                H.top_House().i_elvisto('Lies/Lies', 'Lies_open_Waft', { path: ref })   // aim at the outside Lies
                p.c.opened = true
            }
        }

        // ── preload expected snaps (check mode) — so fuzz-ok can solve INLINE at check time ──
        // The sluggish path is per-step: a value-noise step pauses, loads its NNN.snap over the
        //  wh queue, forgives, resumes — a disk round-trip every step.  Instead, read every
        //   expected snap into memory ONCE here, before the drive starts (timing-safe: the run
        //    hasn't begun, exactly like toc.snap + the EntropyProfile open above).  Then
        //     snap_step grafts in-memory — microseconds, can't perturb a later step's numbers —
        //      and the pip goes green/caveat between steps with no pause.  One read per round
        //       (the wh queue is serial); returning early here gates the drive until it's done.
        //        A missing fixture caches as null and falls back to the pause / post-run sweep.
        if (run.sc.mode === 'check' && !run.c.exps_loaded) {
            const exps = (w.c.exp_snaps ??= {}) as Record<number, string | null>
            const need = ((w.c.The as TheC | undefined)?.o({ step: 1 }) ?? [])
                .map(s => s.sc.step as number)
                .filter(n => exps[n] === undefined)
            if (need.length) {
                const n   = need[0]
                const req = await wh.oai({ req: 'read_snap', wh_path: run_path, wh_op: 'read_snap', wh_step: n })
                if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req }))
                    return w.i({ see: `⏳ load ${H.pad(n)} (${need.length} left)...` })
                exps[n] = (req.sc.reply?.snap as string | undefined) ?? null
                wh.drop(req)
                H.main()
                return w.i({ see: `⏳ loaded ${H.pad(n)}` })
            }
            run.c.exps_loaded = true
            H.story_analysis(w)
        }

        if (run.sc.fetch_snap) {
            // ── fetch the expected snap for the failed step ────────────────
            // Just loads the file content into step.sc.exp_snap for the diff panel.
            // Dige verification is always handled by the check_snap block below —
            // we queue it here so it runs in the same beliefs round.
            const n        = run.sc.fetch_snap as number
            const snap_req = await wh.oai({ req: 'read_snap', wh_path: run_path, wh_op: 'read_snap', wh_step: n })
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
            // in Storui.  step.sc.checking is only set for snap_checking ok steps —
            // clearing it here unblocks poll_check in that path; for mismatches it
            // was never set so clearing is a no-op.
            const n        = run.sc.check_snap as number
            const snap_req = await wh.oai({ req: 'read_snap', wh_path: run_path, wh_op: 'read_snap', wh_step: n })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req }))
                return w.i({ see: `⏳ verify ${H.pad(n)}...` })

            const disk_snap = snap_req.sc.reply?.snap as string | undefined
            const step      = H.i_step(w, n)

            // Compare-time forgiveness (EntropyArrest.md §2.3'): a dige mismatch whose
            //  only differences fall inside acknowledged-noise spans is not a surprise.
            //   Normalize the got and the disk fixture on BOTH sides; if they agree, pass
            //    the step "OK with a caveat", clear the halt, and let the drive resume
            //     (the eventually-ok signal goes through — line ~1407 re-drives once paused
            //      clears, and do_step advances to n+1).  Nothing is re-recorded; the snap
            //       on disk stays honest.  In-app twin of the runner forgive in Story_cli.
            const forgiven = !!disk_snap && step.sc.ok === false && !!step.sc.got_snap
                && H.entropy_forgive(w, step.sc.got_snap as string, disk_snap as string, n)

            if (forgiven) {
                const disk_dige   = await dig(disk_snap as string)
                step.sc.disk_dige = disk_dige
                step.sc.disk_ok   = disk_dige === H.The_step_dige(w, n)  // honest: fixture vs toc
                step.sc.ok        = true
                step.sc.caveat    = true
                delete run.sc.failed_at
                delete run.sc.fetch_snap
                run.sc.paused   = 0          // line ~1407 re-drives; do_step advances to n+1
                run.sc.open_at  = null
                run.sc.frontier = 0          // the only outstanding mismatch is resolved
                H.The_set_frontier(w, 0)
                console.log(`⚖ Story: step ${H.pad(n)} forgiven (caveat) — acknowledged value-noise`)
            } else if (disk_snap) {
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

        if (run.sc.sweeping) {
            // ── post-run forgive sweep (EntropyArrest §10) ──────────────────────
            // Armed by do_step's check-completion branch once the run is OVER.  One step per
            //  round: load its NNN.snap through the wh queue (safe now — no live timings to
            //   perturb, §10.1) and run the same compare-time forgiveness the editor's pause
            //    uses.  A value-noise mismatch becomes OK-with-caveat; a real mismatch keeps
            //     %swept and stays red, pulling ok_pct down honestly.  When the last bad step is
            //      resolved we fire storyFinished, so Cred_run_outcome reads the swept result —
            //       green, tagged.  Nothing is re-recorded; the snap on disk stays honest.
            const n        = run.sc.sweeping as number
            const snap_req = await wh.oai({ req: 'read_snap', wh_path: run_path, wh_op: 'read_snap', wh_step: n })
            if (!H.i_elvis_req(w, 'Wormhole', 'wh_op', { req: snap_req }))
                return w.i({ see: `⏳ forgive ${H.pad(n)}...` })

            const disk_snap = snap_req.sc.reply?.snap as string | undefined
            const step      = H.i_step(w, n)
            if (disk_snap && step.sc.got_snap
                && H.entropy_forgive(w, step.sc.got_snap as string, disk_snap, n)) {
                const disk_dige   = await dig(disk_snap)
                step.sc.disk_dige = disk_dige
                step.sc.disk_ok   = disk_dige === H.The_step_dige(w, n)   // honest: fixture vs toc
                step.sc.ok        = true
                step.sc.caveat    = true
                delete step.sc.unexpected
                console.log(`⚖ Story: step ${H.pad(n)} forgiven (caveat) — post-run sweep`)
            } else {
                step.sc.swept = 1   // checked, genuinely !ok — don't re-pick (stays red)
            }
            step.bump_version()

            const next = H.story_sweep_next(w)
            if (next != null) {
                run.sc.sweeping = next
            } else {
                delete run.sc.sweeping
                // open the last step that's STILL bad after the sweep (lenient-editor review path)
                const last_bad = (w.c.This?.o({ Step: 1 }) ?? [])
                    .filter(s => !s.sc.ok)
                    .sort((a, b) => b.sc.Step - a.sc.Step)[0]
                run.sc.open_at = last_bad ? last_bad.sc.Step : null
                console.log(`✓ Story: check complete (sweep done)`)
                H.top_House().i_elvisto('Auto/Auto', 'storyFinished', { Book: w.sc.Book, mode: 'check' })
            }
            H.story_analysis(w)
            ;(wh.o({ req: 1, finished: 1 }) as TheC[]).forEach(nn => wh.drop(nn))
            H.main()
            return
        }

        if (!run.c.driving && !run.sc.paused) H.story_drive(Run, w, run)
        await H.story_ui(Run, w, run)
        if (this.The_Opt_val(w, 'trickle') && run.c.settled_off) Run.main(true)
        // drop settled wh reqs — the queue is a sub-host, nobody else prunes it
        ;(wh.o({ req: 1, finished: 1 }) as TheC[]).forEach(n => wh.drop(n))

        w.i({ see: `${book} ${run.sc.done} [${run.sc.mode}]${run.sc.paused ? ' ⏸' : ''}` })
    },

    // returned from w:Cyto as soon as the current step has a wave
    async e_Cyto_wave_done(A, w, e) {
        V.Story && console.log(`e:Cyto_wave_done step=${e?.sc.story_step}`)
        const run = w.o({ run: 1 })[0]
        if (!run?.c.awaiting_wave_done) return
        run.c.awaiting_wave_done = false
        run.c.driving = true
        // resume snap_step at the point after the wave is ready
        const resume = run.c.snap_step_after_wave as (() => Promise<void>) | undefined
        if (resume) {
            this.post_do(resume, { see: 'snap_step_after_wave' })
        }
    },
    // ── story_cyto_continue ───────────────────────────────────────────────────
    // Received from w:Cyto once Cytui has finished animating the current step.
    // Clears the waitCyto pause and starts a fresh story_drive — the drive
    // was already stopped cleanly by advance() so driving=false here.
    async e_Cyto_animation_done(A, w, e) {
        V.Story && console.log(`e:Cyto_animation_done step=${e?.sc.story_step}`)
        const run = w.o({ run: 1 })[0]
        if (!run?.c.awaiting_anim_done) return
        run.c.awaiting_anim_done = false
        if (run.sc.paused) return   // respect hard pause
        run.c.driving = true
        // animation finished — proceed to next step via advance
        const sub = this.Story_subHouse(null, w)
        if (!sub) return
        // advance() isn't exposed; easiest is to re-kick story_drive which falls
        // through schedule() → do_step for n+1. step_n gets incremented implicitly
        // by do_step reading run.sc.done+1, and run.sc.done was already set to n
        // in snap_step, so this does the right thing.
        run.c.driving = false   // story_drive early-returns if driving
        this.story_drive(sub.Run, w, run)
    },

    // ── post-run forgive sweep (EntropyArrest §10) ──────────────────────────────
    //  A value-noise mismatch (a dige diff whose only changes fall in acknowledged-noise
    //   spans) isn't a real failure — but proving that needs the expected snap loaded, which
    //    would perturb a LIVE run's timings (§10.1), the very numbers a spayer forgives.  So we
    //     never forgive mid-run: the runner flags each mismatch (snap_step) and drives on, and a
    //      lenient run accumulates !ok steps.  Once the run is OVER (do_step's check-completion
    //       branch), story_sweep_arm picks up those flagged steps and the sweep block in Story()
    //        loads each NNN.snap (safe now) and runs the same entropy_forgive the editor's pause
    //         uses — forgiven → ok+caveat, real mismatch → stays red.  The verdict is read AFTER
    //          the sweep, so it lands green+tagged with no re-push.  Nothing is re-recorded.

    // story_sweep_next — the next This/Step that finished !ok with a got_snap retained and not yet
    //  swept (forgiven steps flip to ok; genuinely-bad ones get %swept so the walk terminates).
    //   null when none remain.  The 5-step trim keeps got_snap for !ok steps, so it's there.
    story_sweep_next(w: TheC): number | null {
        const This = w.c.This as TheC | undefined
        if (!This) return null
        const cand = (This.o({ Step: 1 }) as TheC[])
            .filter(s => !s.sc.ok && s.sc.got_snap && !s.sc.swept)
            .sort((a, b) => (a.sc.Step as number) - (b.sc.Step as number))[0]
        return cand ? (cand.sc.Step as number) : null
    },

    // story_sweep_arm — arm the post-run forgive sweep if any step needs it.  Returns whether it
    //  armed; the caller then DEFERS storyFinished until the sweep block fires it (so the verdict
    //   reads the swept result).  No-op (false) on a clean run — finish immediately as before.
    story_sweep_arm(w: TheC, run: TheC): boolean {
        const next = (this as House).story_sweep_next(w)
        if (next == null) return false
        run.sc.sweeping = next
        return true
    },



//#region story_drive
//
//  All phases are closures over run and the drive locals.
//
//   Phase 1 — do_step  (inside H beliefs mutex via post_do)
//     checks termination conditions, fires Run.i_elvisto(Run,'think') after 1ms,
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
//     (when The/Opt/waitCyto is set and useCyto) or calls schedule() directly.
//
//   Phase 4 — poll_check  (plain setTimeout, snap_checking mode only)
//     waits for Story() to read NNN.snap from disk, verify its dige,
//     and clear step.sc.checking.  Then calls advance().

    story_drive(Run: House, w: TheC, run: TheC) {
        Run.c.run = run
        if (run.c.driving) return
        if (run.c.awaiting_wave_done || run.c.awaiting_anim_done) {
            console.log(`⏸ story_drive called while awaiting_*; ignored`)
            return
        }
        run.c.driving = true

        const H    = this as House
        const TICK_MS = ANSWER_CALLS_TICK_MS

        // quiesce_snap_time: optional seconds to wait after Atime before snapping.
        //   Set via The/Opt/{quiesce_snap_time:N} in toc.snap for picky tests.
        //   Falls back to the default 1.5×TICK threshold when absent.
        const quiesce_snap_time = H.The_Opt_val(w, 'quiesce_snap_time') ?? (TICK_MS / 1000) * 1.5

        // gallop-tighten opt-in (Technique A, Housing GALLOP_*): this Run's drain may go
        //  near-greedy while its todo is deep+sustained.  Presence-keyed opt-OUT — a Book
        //   asserting on mid-settle progress sets The/Opt/{no_gallop:1} to keep the loose
        //    50 ms cadence (a snapped `gallop:0` would read back as truthy "0" — avoid).
        if (H.The_Opt_val(w, 'no_gallop')) delete Run.c.gallop
        else Run.c.gallop = 1

        const update_status = async (label: string, cls = 'default') => {
            const wa = () => H.o({ watched: 'actions' })[0]
            await wa()?.r({ action: 1, role: 'status' }, { label, cls, disabled: true })
            wa()?.bump_version()
        }

        // runner_phase — best-effort progress blip up the editor channel as this Run steps.  The
        //  channel participant is the Creduler Lies under Mundo (top_House), found the same way
        //   Auto's storyFinished bridge finds it; Lies_runner_phase no-ops unless this is genuinely
        //    a runner with a live channel, so an editor's own Run or a bare dev Run costs only the
        //     lookup.  total = the recorded step count (the toc step lines) when 'new' mode hasn't
        //      stamped run.sc.total yet.
        const story_total = () => (run.sc.total as number | undefined)
            ?? ((w.c.The as TheC | undefined)?.o({ step: 1 }) ?? []).length
        const runner_phase = (phase: string, extra?: any) => {
            const Mundo = H.top_House()
            const liesW = Mundo.o({ A: 'Lies' })[0]?.o({ w: 'Lies' })[0] as TheC | undefined
            // Invoke ON Mundo, not on this Run House: Lies_role's inside-story guard returns
            //  undefined when `this` sits within a Story Run (>1 Lies in the tree), so the role —
            //   and the no-op gate — must be read from Mundo's vantage (where Auto's verdict bridge
            //    also calls it).  The Creduler w carries %runner, so the role still resolves there.
            if (liesW) (Mundo as any).Lies_runner_phase(liesW, phase, extra)
        }

        // is_runner — is this Run executing on a headless Lies%runner (a ?B= boot)?  The runner
        //  must NOT halt on a value-noise mismatch (no one is there to resume it, and loading the
        //   expected snap to forgive mid-run would perturb later steps' timings, EntropyArrest
        //    §10.1).  Instead it flags-and-continues and forgives in a post-run sweep.  boot_role
        //     rides on top_House (the same gate Auto's storyFinished bridge uses).
        const is_runner = () => (H.top_House() as any).c.boot_role === 'runner'

        // advance: called after snap_step completes and (for waitCyto path)
        // after the animation_done event has resumed the drive.
        const advance = async () => {
            const n = run.c.step_n as number
            if (n != null && H.The_step(w, n).o({ note: 1, pause: 1 }).length) {
                run.sc.paused = 2
            }
            if (run.sc.paused) { run.c.driving = false; return }
            await Run._resolve_runstepped()   // snap committed — fire Runstepped callbacks on Run
            schedule()
        }

        // Phase 1: do_step
        const do_step = async () => {
            if (!run.c.driving || run.sc.paused) {
                console.log(`⏸ do_step skipped: driving=${run.c.driving} paused=${run.sc.paused}`)
                schedule(); return
            }
            { const lp = w.c.live_poll as TheC | undefined   // fresh step (or run-end) — lower the monitor
              if (lp?.c.on) { lp.c.on = false; lp.bump_version() } }
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
                H.top_House().i_elvisto('Auto/Auto', 'storyFinished', { Book: w.sc.Book, mode: 'new' })
                return
            }
            if (run.sc.mode === 'check' && !H.The_step_dige(w, n)) {
                run.c.driving = false; run.sc.paused = 2
                // clear frontier when we reach the end — no outstanding mismatch
                run.sc.frontier = 0
                H.The_set_frontier(w, 0)
                H.collect_time_sample(w)   // append to The/TimeSpool before save
                H.story_save()
                // Post-run forgive sweep (EntropyArrest §10): the run is over, so loading the
                //  expected snaps to forgive value-noise steps no longer perturbs any timing.
                //   If there are flagged/!ok steps to sweep, hand off to the sweep block in
                //    Story() (it polls each NNN.snap through the wh queue) and let IT fire
                //     storyFinished once the last one resolves — so Cred_run_outcome reads the
                //      swept (green+tagged) result.  No bad steps → finish immediately as before.
                if (H.story_sweep_arm(w, run)) {
                    H.story_analysis(w)
                    await update_status('forgiving…', 'save')
                    H.main()
                    return
                }
                // if we ran lenient, open the last !ok step so the user can review it
                const last_bad = (w.c.This?.o({ Step: 1 }) ?? [])
                    .filter(s => !s.sc.ok)
                    .sort((a, b) => b.sc.Step - a.sc.Step)[0]
                if (last_bad) run.sc.open_at = last_bad.sc.Step
                H.story_analysis(w)
                await update_status('done ✓', 'start')
                console.log(`✓ Story: check complete at n=${n}`)
                H.top_House().i_elvisto('Auto/Auto', 'storyFinished', { Book: w.sc.Book, mode: 'check' })
                return
            }

            run.c.step_n     = n
            run.c.began_step = now_in_seconds_with_ms()
            // settingoff: once before the first step — toc decoded, Run wired, Opt gifts given.
            if (n === 1 && !run.c.settled_off) {
                run.c.settled_off = true
                H.Story_settingoff(w, Run, run)
            }
            // reset so ===0 detection below only fires for THIS step's alleviation
            Run.c.leave_running_until = null
            Run.c.runtime = true          // feebly_ponder and ponder are now live
            Run.trace_enable()
            Run.trace('step', String(n))
            await this.Story_prepare_Prep(w,Run,run)
            setTimeout(() => { if (run.c.driving) Run.i_elvisto(Run, 'think') }, 1)
            setTimeout(poll_step, TICK_MS)
        }

        // Phase 2: poll_step — wait for Run to go quiescent
        let wants_left_running = false
        let was_left_running = false
        let was_ttlilt_held = false       // ttlilt held us at some point this step
        let was_ttlilt_timed_out = false  // cleared by time-expiry, not req completion
        const poll_step = () => {
            if (!run.c.driving) return
            const f = Run.c.finished_run as number | null
            let not_in_Atime = f != null
                && f > (run.c.began_step as number)
            let long_after_Atime = not_in_Atime
                && (now_in_seconds_with_ms() - (f as number)) > quiesce_snap_time
            let dont_want_Atime = !Run.todo.length

            // < GONER prototype of ttlilt
            let dont_leave_running = () => {
                let leave_running = Run.c.leave_running_until > now_in_seconds_with_ms()
                if (!wants_left_running && leave_running) {
                    Run.trace('leave running...')
                    wants_left_running = true
                    was_left_running = true
                }
                // ===0: demanded and alleviated before any poll tick noticed it —
                //   satisfying code (keygen, heartbeat) zeroed it explicitly.
                //   null means this step never demanded time at all.
                if (Run.c.leave_running_until === 0 && !was_left_running) {
                    was_left_running = true
                }
                if (!leave_running) wants_left_running = false
                return !leave_running
            }
            // some H...req wants time to think
            const ttlilt_held = () => {
                const held = H.o_Story_req_ttlilt(Run)
                if (held && !wants_left_running) {
                    wants_left_running = true
                    was_ttlilt_held = true
                }
                if (!held && was_ttlilt_held) {
                    was_ttlilt_timed_out = !!Run.c.poll_ttlilt_expired
                    was_ttlilt_held = false
                }
                if (!held) wants_left_running = false
                return held
            }

            
            // the crux:
            let quiescent = long_after_Atime
                && dont_want_Atime
                && dont_leave_running()
                && !ttlilt_held()
            
            if (!quiescent) {
                // watchdog — actively re-drive a dropped wakeup so a stall can never harden into a
                //  permanent wedge.  The drive otherwise TRUSTS that a non-empty Run.todo will drain
                //   itself (the todo_version $effect → answer_calls).  But that path is async +
                //    50ms-throttled and defers some pushes through clear()/throttle, so a wakeup can
                //     be lost: the House goes idle (out of Atime — finished_run set, no cycle running)
                //      with todo STILL non-empty, and poll_step would then wait forever.  Seeing
                //       exactly that, we drive the drain ourselves rather than trust it.  not_in_Atime
                //        guards against re-entering a live cycle; answer_calls() is throttle-safe
                //         against repeats.  If it instead fires forever with todo never emptying,
                //          that's an infinite RE-ENQUEUE, not a lost wakeup — and the throttled
                //           'rekick' trace makes which-one-it-is loud (vs the old silent forever-wait).
                if (not_in_Atime && Run.todo.length) {
                    if (now_in_seconds_with_ms() - ((run.c.rekicked as number) ?? 0) > 1) {
                        run.c.rekicked = now_in_seconds_with_ms()
                        Run.trace('rekick', `todo:${Run.todo.length} idle:${(now_in_seconds_with_ms() - (f as number)).toFixed(2)}s`)
                    }
                    Run.answer_calls()
                }
                // step_stall: this step is dragging.  Blip the editor once past 2s, then re-blip
                //  about every second, so a wedged step reads as a live "still working n…" on the
                //   runner panel instead of dead air.  stall_blipped (a seconds stamp) is cleared
                //    when the step lands (snap_step), re-arming detection for the next step.
                const secs = now_in_seconds_with_ms() - (run.c.began_step as number)
                if (secs > 2 && now_in_seconds_with_ms() - ((run.c.stall_blipped as number) ?? 0) > 1) {
                    run.c.stall_blipped = now_in_seconds_with_ms()
                    runner_phase('step_stall', { n: run.c.step_n, total: story_total(), secs: Math.round(secs), book: w.sc.Book })
                }
                // overrun monitor — a step past 5s is wedged.  Publish the live trace tail on the
                //  ave-held live_poll particle and bump its version DIRECTLY, so Storui (reading
                //   lp.vers) refreshes even while a wedged step never flushes ave.  Paced here:
                //    on arming, and then ~every 3s when the trace has grown, we stash the latest
                //     ≤30 UNSHOWN events in lp.c.batch (older backlog skipped) and bump.  A static
                //      wedge bumps once and holds.  (Surfaced in the UI now, not the console.)
                const lp = w.c.live_poll as TheC | undefined
                if (lp && secs > 5) {
                    const fresh = !lp.c.on || lp.c.step !== run.c.step_n
                    const nowm  = now_in_seconds_with_ms()
                    const tlog  = Run.trace_log ?? []
                    const shown = (lp.c.shown as number) ?? 0
                    const due   = nowm - ((lp.c.beat as number) ?? 0) > 3
                    if (fresh || (due && tlog.length > shown)) {
                        if (fresh) {
                            lp.c.on = true; lp.c.step = run.c.step_n
                            lp.c.since = run.c.began_step; lp.c.Run = Run
                        }
                        lp.c.beat = nowm
                        const lo = Math.max(fresh ? 0 : shown, tlog.length - 30)
                        lp.c.batch = tlog.slice(lo).map((ev, i) => ({
                            kind: ev.kind, tag: ev.tag, key: lo + i, i,
                            d: (lo + i) > 0 ? ev.t - tlog[lo + i - 1].t : 0,
                        }))
                        lp.c.shown = tlog.length
                        lp.c.total = tlog.length
                        // last_t: performance.now() of the newest event.  The UI shows "idle Xs"
                        //  off this — for a wedged-idle trace it stops advancing while the step
                        //   clock keeps climbing, which IS the deadlock signature (heading 6).
                        lp.c.last_t = tlog.length ? tlog[tlog.length - 1].t : performance.now()
                        lp.bump_version()
                    }
                }
                setTimeout(poll_step, TICK_MS)
                return
            }
            let timed_out = was_left_running || was_ttlilt_timed_out
            was_left_running = false
            wants_left_running = false
            was_ttlilt_timed_out = false
            was_ttlilt_held = false   // defensive; should already be false at quiescence


            let ago = (now_in_seconds_with_ms() - (f as number))
            Run.trace('quiescent', timed_out ? `${ago.toFixed(3)} timeout` : ago.toFixed(3))
            ;V.Story && console.log(`⏱ poll_step quiescent n=${run.c.step_n} since ${ago.toFixed(3)} TICK=${TICK_MS}`)
            // on_step_ending: called once at quiescence, before the snap.
            Run.c.on_step_ending?.(timed_out ? 'timeout' : 'causal')
            Run.c.runtime = false         // feebly_ponder is now no-op; ponder throws
            H.post_do(snap_step, { see: 'story_snap' })
        }

        // Phase 3: snap_step — encode, compare, store, trim, then advance or verify
        const snap_step = async () => {
            if (!run.c.driving) return
            const n = run.c.step_n as number
            run.sc.done = n
            run.c.stall_blipped = undefined            // this step landed — re-arm stall detection
            run.c.rekicked      = undefined            // …and the watchdog rekick-trace throttle
            { const lp = w.c.live_poll as TheC | undefined   // …and lower the overrun monitor
              if (lp?.c.on) { lp.c.on = false; lp.bump_version() } }
            runner_phase('step_done', { n, total: story_total(), book: w.sc.Book })
            Run.trace('snap', String(n))

            // No own Cyto (default / !useCyto): bypass the wave handshake, snap immediately.
            if (!H.The_Opt_val(w, 'useCyto')) {
                await snap_step_after_wave()
                return
            }

            // Always wait for wave_done — the wave is test data, not decoration.
            run.c.awaiting_wave_done = true
            run.c.driving = false
            H.i_elvisto('Cyto/Cyto', 'Cyto_animation_request', { story_step: n })
            V.Story && console.log(`⏸ snap_step paused for Cyto_wave_done step=${n}`)
        }

        // Reachable by two paths:
        //  - Directly from snap_step if no own Cyto (default / !useCyto)
        //  - From e_Cyto_wave_done via run.c.snap_step_after_wave otherwise
        //      and if Opt/waitCyto, in snap_step_finish, we wait for e:Cyto_animation_done
        const snap_step_after_wave = async () => {
            if (!run.c.driving) {
                // we were resumed by the handler which set driving=true
                run.c.driving = true
            }
            const n = run.c.step_n as number
            const snap     = await this.story_snap(w, run, Run)
            const got_dige = await dig(snap)
            Run.trace('snapped', String(n))

            const step = H.i_step(w, n)
            step.sc.unrun = false
            step.sc.Run_trace = Run.trace_drain()
            step.bump_version()

            // Trim (got|exp)_snap 5 steps behind — best-effort GC.
            //   ok+!accepted:   already on disk unchanged, safe to drop —
            //                   UNLESS disk_ok===false: the fixture drifted and
            //                   Accept needs got_snap to rewrite it, so keep it.
            //   accepted+saved: written by story_save, safe to drop.
            //   exp_snap:       display-only, always safe to drop.
            // Skipped when keep_snaps toggle is on.
            const trim_n = n - 5
            if (trim_n >= 1 && !w.c.keep_snaps) {
                const old = H.i_step(w, trim_n)
                if (old.sc.ok && !old.sc.accepted && old.sc.disk_ok !== false) delete old.sc.got_snap
                if (old.sc.accepted && old.sc.saved)  delete old.sc.got_snap
                // first_snap is a session diff anchor paired with got_snap
                if (!old.sc.got_snap)                 delete old.sc.first_snap
                delete old.sc.exp_snap
            }

            // AUDIO-BLOCKED (a Story_demand_audio timed out this step): a step that DEMANDED the real
            //  voice and wasn't granted one within its window.  A distinct verdict — !ok, carries the
            //   error, but NOTHING WAS TRIED (no assertion ran) — so it reads as "couldn't run here",
            //    never as "the audio delivery is broken".  Skip the dige compare entirely and drive on
            //     (the runner doesn't halt on it).  step_blocked rides on w.c (off-snap), set inside the
            //      demand's ttlilt just before it settled, so it's here before the snap.  Generic: any
            //       w.c.step_blocked lands the untried verdict, audio is merely the first caller.
            if ((w.c as any).step_blocked) {
                const why = String((w.c as any).step_blocked)
                ;(w.c as any).step_blocked = null
                step.sc.got_snap = snap
                step.sc.dige = got_dige
                step.sc.ok = false
                step.sc.untried = true
                step.sc.error = why
                delete step.sc.caveat
                step.bump_version()
                H.story_analysis(w)
                await update_status(`⌛ ${H.pad(n)} — ${why}`, 'stop')
                console.log(`⌛ Story: step ${H.pad(n)} blocked — ${why} (nothing tried)`)
                await snap_step_finish()
                return
            }

            if (run.sc.mode === 'new') {
                step.sc.got_snap = snap
                step.sc.dige = got_dige
                step.sc.ok = true
                step.sc.accepted = true
                H.The_step(w, n).sc.dige = got_dige
                H.story_analysis(w)
                await update_status(`recording ${H.pad(n)}/${H.pad(run.sc.total)}`, 'save')
                await snap_step_finish()
            } else {
                const exp_dige = H.The_step_dige(w, n)
                let ok = exp_dige === got_dige
                V.Story && console.log(`🔍 n=${n} ok=${ok} exp=${exp_dige?.slice(0,8)} got=${got_dige.slice(0,8)}`)
                step.sc.got_snap = snap
                step.sc.dige = got_dige
                // fresh verdict — clear any caveat from a prior run; the inline forgive just below
                //  re-sets it if this dige mismatch is acknowledged value-noise.
                delete step.sc.caveat

                // INLINE fuzz-ok at check time (between steps): a dige mismatch that reconstructs
                //  through acknowledged-noise spayers passes OK-with-caveat RIGHT HERE — no pause,
                //   no per-step disk round-trip (the sluggish path).  The expected snaps were
                //    pre-loaded before the drive (timing-safe), so this is an in-memory graft of
                //     microseconds that can't perturb a later step's numbers.  A step with no
                //      cached fixture falls through to the pause (editor) / post-run sweep (runner).
                if (!ok) {
                    const exp = (w.c.exp_snaps as Record<number, string | null> | undefined)?.[n]
                    if (exp && H.entropy_forgive(w, snap, exp, n)) { ok = true; step.sc.caveat = true }
                }
                step.sc.ok = ok
                step.bump_version()   // verdict (ok/caveat) settled — wake the pip now, this step
                H.story_analysis(w)

                if (!ok && !w.c.lenient && !is_runner()) {
                    run.c.driving = false
                    run.sc.paused = 2
                    run.sc.failed_at = n
                    run.sc.fetch_snap = n
                    run.sc.check_snap = n
                    run.sc.frontier = n
                    if (run.sc.open_at == null) run.sc.open_at = n
                    H.The_set_frontier(w, n)
                    await update_status(`✗ step ${H.pad(n)}`, 'stop')
                    console.log(`⛔ Story: step ${H.pad(n)} mismatch`)
                    H.main()
                    return
                }
                // Runner flag-and-continue (EntropyArrest §10): reached only for an UNCACHED
                //  fixture (the inline forgive above already cleared the cached value-noise ones).
                //   The headless runner still doesn't pause or fetch mid-run — it flags the
                //    straggler and drives on; story_sweep_arm forgives it in a post-run sweep.
                if (!ok && is_runner()) step.sc.unexpected = 1
                if (!ok) console.log(`⚠ Story: step ${H.pad(n)} mismatch accepted (${is_runner() ? 'runner — flagged for sweep' : 'lenient'})`)
                await update_status(`${ok ? '✓' : '⚠'} ${H.pad(n)}`, ok ? 'default' : 'save')

                if (ok && w.c.snap_checking) {
                    step.sc.checking = true
                    run.sc.check_snap = n
                    H.main()
                    setTimeout(poll_check, TICK_MS)
                } else {
                    await snap_step_finish()
                }
            }
        }

        // Post-snap phase: pause for animation if waitCyto, else advance directly.
        // Reached from snap_step_after_wave (both modes) and poll_check.
        const snap_step_finish = async () => {
            if (H.The_Opt_val(w, 'waitCyto') && H.The_Opt_val(w, 'useCyto')) {
                run.c.awaiting_anim_done = true
                run.c.driving = false
                V.Story && console.log(`⏸ snap_step finished, paused for Cyto_animation_done`)
                return
            }
            advance()
        }

        const poll_check = () => {
            if (!run.c.driving) return
            const n = run.c.step_n as number
            const check_step = H.i_step(w, n)
            if (check_step.sc.checking) { setTimeout(poll_check, TICK_MS); return }
            if (check_step.sc.disk_ok === false) {
                check_step.sc.ok = false
                run.c.driving = false
                run.sc.paused = 2
                run.sc.failed_at = n
                run.sc.fetch_snap = n
                run.sc.frontier = n
                if (run.sc.open_at == null) run.sc.open_at = n
                H.The_set_frontier(w, n)
                update_status(`✗ disk ${H.pad(n)}`, 'stop')
                H.main()
                return
            }
            V.Story && console.log(`⏱ poll_check ok n=${n}`)
            snap_step_finish()   // not advance() — go through the waitCyto gate
        }

        const schedule = () => {
            if (!run.c.driving) return
            V.Story && console.log(`⏭ schedule driving=${run.c.driving} paused=${run.sc.paused}`)
            setTimeout(() => {
                if (!run.c.driving) return
                H.post_do(do_step, { see: 'story_step' })
            }, 200)
        }

        // Expose the two resume-points for handlers.
        run.c.snap_step_after_wave = snap_step_after_wave
        run.c.snap_step_finish     = snap_step_finish

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

        // Collect H%Run worker w/{Opt:1}/* into The/Opt/For/w:*/* so they
        // persist in toc.snap.  Opts added at runtime (via action button) won't
        // be in For yet — oai() is idempotent for already-multi-placed particles.
        const run_name = w.sc.Book as string | undefined
        const runH = run_name ? storyH.o({ H: run_name })[0] as House | undefined : undefined
        if (runH) {
            const For = storyH.The_Opt(w).oai({ For: 1 })
            for (const actor of runH.o({ A: 1 }) as TheC[]) {
                const wname  = actor.sc.A as string
                const gw     = actor.o({ w: wname })[0] as TheC | undefined
                const gwOpt  = gw?.o({ Opt: 1 })[0] as TheC | undefined
                if (!gwOpt) continue
                const opts   = gwOpt.o({}) as TheC[]
                if (!opts.length) continue
                const forW   = For.oai({ w: wname })
                for (const p of opts) forW.oai(p.sc)
            }
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
            const toc_req = await wh.oai({ req: 1, wh_path: run_path, wh_op: 'write_toc', wh_data: snap })
            storyH.i_elvis_req(w, 'Wormhole', 'wh_op', { req: toc_req })

            for (const step of all_steps) {
                if (step.sc.saved) continue
                if (!step.sc.got_snap || !step.sc.accepted) continue
                const n = step.sc.Step as number
                ;V.Story && console.log(`💾 writing snap n=${n}`)
                const snap_req = await wh.oai({
                    req: 1, wh_path: run_path, wh_op: 'write_snap',
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
        topH.i_elvisto('Auto/Auto', 'resetStory', bname ? { Book: bname } : {})
        console.log(`Otro: 🔄 ${this.name}/${bname} story_reset`)
    },


//#region mechanisms — Run wiring, story_ui

    async story_ui(this: House, Run: House, w: TheC, run: TheC) {
        const wa = this.o({ watched: 'actions' })[0]
        if (!wa) return
        const paused = run.sc.paused
        const mode   = run.sc.mode ?? 'new'

        // at_end: done has reached total while paused — next step doesn’t exist yet
        const at_end = (run.sc.done ?? 0) >= (run.sc.total ?? 1) && run.sc.paused

        await wa.roai({ action: 1, role: 'pause' }, {
            label: paused ? 'Resume' : 'Pause',
            icon:  paused ? '▶'     : '⏸',
            cls:   paused ? 'start' : 'stop',
            fn: () => {
                if (!run.sc.paused) {
                    run.sc.paused = 2
                    return
                }
                // Extend total when paused at the ceiling or blocked by a failed step
                if (at_end || run.sc.failed_at) {
                    run.sc.total = ((run.sc.total ?? 1) as number) + 1
                }
                if (run.sc.failed_at) delete run.sc.failed_at
                // seems to need this to get another step to fully work
                // < why it half does things without this...
                if (at_end) run.sc.mode = 'new'
                run.sc.paused = 0
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
        //     Surfaces corruption as step.sc.disk_ok===false in Storui.
        //   keep_snaps: suppress the 5-step trim of (got|exp)_snap.  Useful when you
        //     want to inspect snap content across many steps in the same session.
        await this.i_actions_to_c(w, 'snap_checking', { stashed: true, label: 'verify snaps' })
        await this.i_actions_to_c(w, 'keep_snaps',    { stashed: true, label: 'keep snaps'   })
        let Opt = this.The_Opt(w)
        // waitCyto and useCyto live in The/Opt so they round-trip through toc.snap.
        // waitCyto: after each snap, pause until Cyto's animation finishes before advancing.
        // useCyto: opt INTO Story's own Cyto (commission + wave handshake).  Default off —
        //   most tests don't want their own Cyto; the Leaf* tests are the main users.
        //   Both are per-Book — stored in The/Opt, not stashed, so they don't bleed
        //   across Books the way a stashed bool would.
        await this.i_actions_to_C(Opt, 'useCyto', { label: 'useCyto' })
        // waitCyto only means anything with useCyto on (it gates on this Book's own
        //  Cyto animation).  Posit the toggle only then; when useCyto is off, rm() the
        //   action so a previously-created waitCyto button disappears instead of
        //    lingering as a dead toggle.  rm() is replace()-backed, so the removal is
        //     tracked and the snap stays consistent.
        if (this.The_Opt_val(w, 'useCyto')) {
            await this.i_actions_to_C(Opt, 'waitCyto', { label: 'waitCyto' })
            // dontSnapCyto: keep the live Cyto (watch the graph animate) but fold its cytowave
            //  channel out of the fixture, so got_snap stops freezing volatile node positions.
            //   Like waitCyto it only means anything with useCyto on, so it rides the same gate;
            //    when useCyto is off the rm() below sweeps a now-meaningless button away.
            await this.i_actions_to_C(Opt, 'dontSnapCyto', { label: 'dontSnapCyto' })
        } else {
            await wa.rm({ action: 1, role: 'waitCyto' })
            await wa.rm({ action: 1, role: 'dontSnapCyto' })
        }
        // trickle: when toggled on, stores the current Book name (not boolean true).
        // This means only this Book gets the trickle treatment — other Books in
        // the same House don't accidentally inherit it from stashed.
        await this.i_actions_to_C(Opt, 'trickle', {
            label: 'trickle',
            on_change: (next: boolean) => {
                if (next) {
                    // we 
                    // on engage, wake them immediately?
                    // const sub = this.Story_subHouse(null, w)
                    // if (sub) sub.Run.main(true)
                }
            },
        })

        // < is this weird. Baroquely, an information channel in a button
        await wa.roai({ action: 1, role: 'status' }, {
            label:    `${mode} ${run.sc.failed_at ? '✗' + this.pad(run.sc.failed_at) : this.pad(run.sc.done ?? 0)}`,
            cls:      run.sc.failed_at ? 'stop' : mode === 'new' ? 'save' : 'default',
            disabled: true,
        })

        // ── Resnap button ─────────────────────────────────────────────────
        // Re-snaps the current step from where the model stands right now.
        // Useful when async work (bookmark walks, Cyto scans, UI interaction)
        // has changed observable state after the original snap.
        // e_story_resnap anchors %first_snap (once per step) then re-fires
        // snap_step_after_wave.  Storui detects resnap_count changing and
        // opens its fixed popup showing first<=>got.
        await wa.roai({ action: 1, role: 'resnap' }, {
            label: 'Resnap',
            icon:  '📸',
            cls:   'save',
            fn: () => { this.i_elvisto('Story/Story', 'story_resnap', {}) },
        })
    },



    })
    })
</script>