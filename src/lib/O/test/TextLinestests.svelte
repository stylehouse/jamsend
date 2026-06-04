<script lang="ts">
    // TextLinestests.svelte — codec and migration tests for the enLine|deLine codec.
    //
    // ── enLine|deLine codec rules ─────────────────────────────────────────────
    //
    //   The peel/depeel format encodes C particles as indented "k:v,k2:v2" lines.
    //
    //   equations have numbers, text has colons:
    //     key:1    — the string "1"
    //     key=1    — the number  1
    //     key      — same as key=1     (bare key → number 1, most common flag)
    //
    //   Strings are always written with ":" and always decoded as strings.
    //   Numbers are always written bare (or key=N) and decoded as numbers.
    //   The codec never coerces — "3" stays "3", 3 stays 3.
    //
    // ── Snap test format ──────────────────────────────────────────────────────
    //
    //   Each section:
    //     await w.r({section:N},{})       — wipe prior %section particles (re-entry safe)
    //     t = w.i({section:'...'})        — section particle, collects all marks
    //     const n = t.i({...data...})     — data particle (TheC returned by t.i())
    //     assert_eq(label, got, want)     — marks %pass or %fail into t
    //
    //   round_trip(n) takes the TheC from t.i(), encodes its .sc through
    //   encode_wh_lines → decode_wh_lines, and returns the decoded sc.
    //
    // ── Migration format ──────────────────────────────────────────────────────
    //
    //   Old .snap files may have used JSON-encoded numbers or string-coerced
    //   numbers in ways that predate the key:str / key=num split.  Snapmigrating
    //   depth-first walks every .snap under wormhole/ and re-encodes via
    //   decode_wh_lines → encode_wh_lines so the codec makes the decision.
    //
    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount }   from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region Snaptesting

    // ── Snaptesting ───────────────────────────────────────────────────────────
    //
    //   Round-trip tests for the number vs string encoding split.
    //   w thinks more than once — w.r({section:N},{}) wipes the prior section
    //   particle each entry so t is always freshly created by w.i().
    //
    async Snaptesting(A: TheC, w: TheC) {
        const H = this as House
        let failures = 0
        let t: TheC   // current section particle — all marks go in here

        const assert_eq = (label: string, got: any, want: any) => {
            const ok = JSON.stringify(got) === JSON.stringify(want)
            if (!ok) {
                console.error(`❌ ${label}:`, { got, want })
                t.i({ fail: label, got: String(got), want: String(want) })
                failures++
            } else {
                t.i({ pass: label })
            }
        }

        // round-trip n.sc through encode_wh_lines → decode_wh_lines.
        //   Takes the TheC returned by t.i() — its .sc is the data under test.
        //   Builds a throwaway root around a fresh copy for encoding so the
        //   live tree isn't disturbed.
        const round_trip = async (n: TheC): Promise<Record<string, any>> => {
            const { _C } = await import('$lib/data/Stuff.svelte')
            const root = _C({ rt_root: 1 })
            root.i(_C({ ...n.sc }))
            const { snap, errors } = await H.encode_wh_lines(root, {})
            if (errors.length) throw new Error(`encode errors: ${errors.join('; ')}`)
            const { C, errors: de } = H.decode_wh_lines(snap)
            if (!C) throw new Error(`decode returned null: ${de.join('; ')}`)
            if (de.length) throw new Error(`decode errors: ${de.join('; ')}`)
            const children = C.o() as TheC[]
            if (!children.length) throw new Error('no children after round-trip')
            return children[0].sc
        }

        // ── section 1: Lines-encoding is explicit about number|string ─────────
        //
        //   "key:1"   encodes the string "1" → round-trips as string "1"
        //   key       bare key (number 1)    → round-trips as number 1
        //
        await w.r({ section: 1 }, {})
        t = w.i({ section: 'Lines-encoding is explicit about number|string' })
        {
            const n1 = t.i({ three_as_string: '3', three_as_number: 3 })
            const rt1 = await round_trip(n1)
            assert_eq('three_as_string is string', typeof rt1.three_as_string, 'string')
            assert_eq('three_as_string value',     rt1.three_as_string,        '3')
            assert_eq('three_as_number is number', typeof rt1.three_as_number, 'number')
            assert_eq('three_as_number value',     rt1.three_as_number,        3)

            // one_as_string:'1' — most likely to be confused with a flag
            const n2 = t.i({ one_as_string: '1', one_as_number: 1 })
            const rt2 = await round_trip(n2)
            assert_eq('one_as_string is string', typeof rt2.one_as_string, 'string')
            assert_eq('one_as_string value',     rt2.one_as_string,        '1')
            assert_eq('one_as_number is number', typeof rt2.one_as_number, 'number')
            assert_eq('one_as_number value',     rt2.one_as_number,        1)
        }

        // ── section 2: flags (bare key = number 1) ────────────────────────────
        await w.r({ section: 2 }, {})
        t = w.i({ section: 'flags' })
        {
            const n = t.i({ finished: 1, count: 7 })
            const rt = await round_trip(n)
            assert_eq('finished flag is number', typeof rt.finished, 'number')
            assert_eq('finished flag value',     rt.finished,        1)
            assert_eq('count is number',         typeof rt.count,    'number')
            assert_eq('count value',             rt.count,           7)
        }

        // ── section 3: large and small numbers ────────────────────────────────
        //
        //   Numbers stay numbers across round-trip regardless of magnitude.
        //   bignumber > Number.MAX_SAFE_INTEGER — peel writes it bare.
        //   tinynumber is your 0.000000000000000000000000000000000000000000000004
        //   which rounds to the nearest representable float.
        //
        await w.r({ section: 3 }, {})
        t = w.i({ section: 'large and small numbers' })
        {
            const n = t.i({
                bignumber:   6325612519811704,
                smallnumber: 0.000024,
                tinynumber:  0.000000000000000000000000000000000000000000000004,
            })
            const rt = await round_trip(n)
            assert_eq('bignumber type',    typeof rt.bignumber,   'number')
            assert_eq('bignumber value',   rt.bignumber,          6325612519811704)
            assert_eq('smallnumber type',  typeof rt.smallnumber, 'number')
            assert_eq('smallnumber value', rt.smallnumber,        0.000024)
            assert_eq('tinynumber type',   typeof rt.tinynumber,  'number')
            // tinynumber rounds to the nearest float — just assert it survived as a number
            assert_eq('tinynumber is a number', Number.isFinite(rt.tinynumber) || rt.tinynumber === 0, true)
        }

        // ── section 4: mixed particle — realistic req fields ──────────────────
        await w.r({ section: 4 }, {})
        t = w.i({ section: 'realistic req fields' })
        {
            const n = t.i({
                req:      'wread',
                rw_name:  'wormhole/Ghost/Tour/toc.snap',
                finished: 1,
                req_i:    42,
                label:    'source_check',
            })
            const rt = await round_trip(n)
            assert_eq('req is string',      typeof rt.req,      'string')
            assert_eq('req value',          rt.req,             'wread')
            assert_eq('rw_name is string',  typeof rt.rw_name,  'string')
            assert_eq('finished is number', typeof rt.finished, 'number')
            assert_eq('req_i is number',    typeof rt.req_i,    'number')
            assert_eq('req_i value',        rt.req_i,           42)
            assert_eq('label is string',    typeof rt.label,    'string')
        }

        // ── section 5: zero and negative numbers ──────────────────────────────
        await w.r({ section: 5 }, {})
        t = w.i({ section: 'zero and negative numbers' })
        {
            const n = t.i({ zero: 0, negative: -3, neg_float: -0.001 })
            const rt = await round_trip(n)
            assert_eq('zero type',      typeof rt.zero,      'number')
            assert_eq('zero value',     rt.zero,             0)
            assert_eq('negative type',  typeof rt.negative,  'number')
            assert_eq('negative value', rt.negative,         -3)
            assert_eq('neg_float type', typeof rt.neg_float, 'number')
        }

        // ── section 6: strings that look like numbers ─────────────────────────
        //
        //   The colon in the encoded form is what tells the decoder "string".
        //   "42" stays "42", "0" stays "0", "1" stays "1" — never coerced.
        //
        await w.r({ section: 6 }, {})
        t = w.i({ section: 'strings that look like numbers' })
        {
            const n = t.i({ count: '42', zero_str: '0', version: '1.2.3', flag_str: '1' })
            const rt = await round_trip(n)
            assert_eq('count is string',    typeof rt.count,    'string')
            assert_eq('count value',        rt.count,           '42')
            assert_eq('zero_str is string', typeof rt.zero_str, 'string')
            assert_eq('zero_str value',     rt.zero_str,        '0')
            assert_eq('version is string',  typeof rt.version,  'string')
            assert_eq('version value',      rt.version,         '1.2.3')
            assert_eq('flag_str is string', typeof rt.flag_str, 'string')
            assert_eq('flag_str value',     rt.flag_str,        '1')
        }

        const summary = failures
            ? `❌ Snaptesting: ${failures} failure(s)`
            : '✅ Snaptesting passed'
        console.log(summary)
        w.i({ see: summary })
    },

//#endregion
//#region Snapmigrating

    // ── Snapmigrating ─────────────────────────────────────────────────────────
    //
    //   Depth-first scan of every .snap file under wormhole/.
    //   Each file is rewritten line-by-line: deL splits the line into
    //   {d, objecties, stringies}, the stringies are re-depeel'd with
    //   modern=true (numbers → k=N, strings → k:v), then the line is
    //   reassembled manually — because enL calls encode_stringies which
    //   calls depeel() still in legacy mode.
    //
    //   BQ key lines (odd leading-space count) and BQ body lines pass through
    //   verbatim — deL would throw on them and they carry no peel stringies.
    //   JSON-stringies lines pass through verbatim too.
    //
    //   Concurrency: at most MAX_INFLIGHT migrate_snap calls in flight at once,
    //   drained ≤ RATE_PER_SEC per second.  w.c.snap_dirs_todo is the queue;
    //   w.c.snap_inflight is the live set (path → true); w.c.snap_done_dirs
    //   prevents re-visiting on re-entry.
    //
    async Snapmigrating(A: TheC, w: TheC) {
        const H = this as House
        const { depeel } = await import('$lib/Y.svelte')

        const MAX_INFLIGHT  = 10
        const RATE_PER_SEC  = 3
        const TICK_MS       = Math.ceil(1000 / RATE_PER_SEC)

        const dry_run = !!H.o_Opt_val(w, 'dry_run')
        if (dry_run && !w.c.snap_dry_logged) {
            console.log('🔎 Snapmigrating: dry run — no writes')
            w.c.snap_dry_logged = true
        }

        // all state on w.c — survives re-entry
        w.c.snap_migrated   ??= 0
        w.c.snap_skipped    ??= 0
        w.c.snap_errors     ??= 0
        w.c.snap_dirs_todo  ??= ['wormhole'] as string[]
        w.c.snap_done_dirs  ??= new Set<string>()
        w.c.snap_inflight   ??= new Set<string>()   // paths currently being migrated
        w.c.snap_last_tick  ??= 0

        const dirs_todo  = w.c.snap_dirs_todo  as string[]
        const done_dirs  = w.c.snap_done_dirs  as Set<string>
        const inflight   = w.c.snap_inflight   as Set<string>

        // ── migrate_lines ─────────────────────────────────────────────────────
        //
        //   Rewrites peel-format stringies in each line with modern depeel.
        //   Must be stateful across lines to track BQ blocks correctly:
        //
        //   BQ key line:   exactly 2*d+1 leading spaces, matches /^(\w+):\s*\|$/
        //                  → pass through; enter BQ body mode for this depth
        //   BQ body lines: ≥ 2*d+3 leading spaces while in BQ body mode
        //                  → pass through verbatim (raw prose, not peel)
        //   Normal lines:  even spaces, not in BQ body → deL + re-depeel
        //   JSON-stringies: str_raw starts with '{' → pass through
        //
        //   deL is used for the structural split (handles objecties-tab correctly).
        //   Old fuzzy coerce rule (/^-?\d+\.?\d*$/) applied to str_raw segments
        //   to recover what old peel produced, then modern depeel re-emits.
        //
        const OLD_NUMERIC = /^-?\d+\.?\d*$/
        const BQ_KEY      = /^(\w+):\s*\|$/

        const migrate_lines = (snap: string): string => {
            const lines  = snap.split('\n')
            const out: string[] = []

            // bq_body_min: when > 0 we are inside a BQ body block;
            //   any line with ≥ bq_body_min spaces is a body line (pass through).
            //   Reset to 0 when a line with fewer spaces is seen.
            let bq_body_min = 0

            for (const raw of lines) {
                if (!raw.trim()) { out.push(raw); continue }

                const spaces = raw.match(/^ */)?.[0].length ?? 0

                // leaving a BQ body block when indent drops back
                if (bq_body_min > 0 && spaces < bq_body_min) bq_body_min = 0

                // inside BQ body — raw prose, never peel
                if (bq_body_min > 0) { out.push(raw); continue }

                // BQ key line: odd spaces + matches /key: |/
                if (spaces % 2 !== 0) {
                    const key_part = raw.slice(spaces).trimEnd()
                    if (BQ_KEY.test(key_part)) {
                        // body lines have ≥ spaces+2 leading spaces (2*d+3 where d=(spaces-1)/2)
                        bq_body_min = spaces + 2
                    }
                    out.push(raw)
                    continue
                }

                let parsed: { d: number, objecties: Record<string,any>, stringies: Record<string,any> } | null
                try { parsed = H.deL(raw) } catch { out.push(raw); continue }
                if (!parsed) { out.push(raw); continue }

                const { d, objecties } = parsed

                // JSON-stringies: already type-safe
                const tab     = raw.indexOf('\t')
                const str_raw = tab >= 0 ? raw.slice(tab + 1) : raw.slice(spaces)
                if (str_raw.startsWith('{')) { out.push(raw); continue }

                // apply old fuzzy coerce rule to str_raw to recover original types
                const recovered: Record<string, any> = {}
                for (const part of str_raw.split(',')) {
                    const ci = part.indexOf(':')
                    if (ci < 0) {
                        const k = part.trim(); if (k) recovered[k] = 1
                    } else {
                        const k = part.slice(0, ci)
                        const v = part.slice(ci + 1)
                        if (!k) continue
                        recovered[k] = OLD_NUMERIC.test(v) ? parseFloat(v) : v
                    }
                }

                const new_str = depeel(recovered, { modern: true })
                if (new_str === str_raw) { out.push(raw); continue }

                const ind      = '  '.repeat(d)
                const obj_part = Object.keys(objecties).length ? JSON.stringify(objecties) : ''
                out.push(obj_part ? `${ind}${obj_part}\t${new_str}` : `${ind}${new_str}`)
            }

            return out.join('\n')
        }

        // ── migrate_one ────────────────────────────────────────────────────────
        const migrate_one = async (path: string) => {
            if (inflight.has(path)) return
            inflight.add(path)

            try {
                const rreq = await H.LiesStore_read(w, path)
                if (!rreq.sc.finished) {
                    H.i_req_ttlilt(rreq, 0.5, { waiting: 'read' })
                    inflight.delete(path)
                    return
                }

                const reply = rreq.sc.reply as any
                if (reply?.not_found) { w.c.snap_skipped++; inflight.delete(path); return }
                if (reply?.error) {
                    console.error(`Snapmigrating: read error at ${path}:`, reply.error)
                    w.c.snap_errors++
                    inflight.delete(path)
                    return
                }

                const old_snap = reply.content as string
                const new_snap = migrate_lines(old_snap)

                if (new_snap === old_snap) {
                    w.c.snap_skipped++
                    inflight.delete(path)
                    return
                }

                if (dry_run) {
                    console.log(`🔎 would migrate: ${path}`)
                    w.c.snap_migrated++
                    inflight.delete(path)
                    return
                }

                const wreq = await H.LiesStore_write(w, path, new_snap)
                if (!wreq) { w.c.snap_skipped++; inflight.delete(path); return }

                w.c.snap_migrated++
                console.log(`💾 migrated: ${path}`)
            } finally {
                inflight.delete(path)
                H.update_see_snap(w)
            }
        }

        // ── walk one directory off the todo queue ──────────────────────────────
        const walk_one = async (dir: string) => {
            if (done_dirs.has(dir)) return
            done_dirs.add(dir)

            const req = await H.LiesStore_listing(w, dir)
            if (!req.sc.finished) {
                done_dirs.delete(dir)   // retry on next tick
                H.i_req_ttlilt(req, 0.5, { waiting: 'listing' })
                return
            }

            const reply = req.sc.reply as any
            if (reply?.not_found) return
            if (reply?.error) {
                console.error(`Snapmigrating: listing error at ${dir}:`, reply.error)
                w.c.snap_errors++
                return
            }

            const entries: Array<{ name: string, is_dir: boolean }> = reply?.entries ?? []

            // push subdirs onto the front of the queue (depth-first)
            const subdirs = entries
                .filter(e => e.is_dir)
                .map(e => `${dir}/${e.name}`)
                .filter(d => !done_dirs.has(d))
            dirs_todo.unshift(...subdirs)

            // queue .snap files
            for (const e of entries) {
                if (!e.name.endsWith('.snap')) continue
                const path = `${dir}/${e.name}`
                if (!inflight.has(path)) migrate_one(path)   // fire and don't await — rate below
            }
        }

        // ── drain: process dirs + respect rate limit ───────────────────────────
        const now = Date.now()
        if (now - (w.c.snap_last_tick as number) >= TICK_MS) {
            w.c.snap_last_tick = now

            // process up to one dir per tick
            while (dirs_todo.length && (inflight.size) < MAX_INFLIGHT) {
                const dir = dirs_todo.shift()!
                await walk_one(dir)
                break  // one dir per tick keeps the queue predictable
            }
        }

        H.update_see_snap(w)

        // re-enter until everything is done
        const still_going = dirs_todo.length > 0 || inflight.size > 0
        if (still_going) {
            H.demand_time_to_think(TICK_MS)
            return
        }

        const { snap_migrated: migrated, snap_skipped: skipped, snap_errors: errors } = w.c
        const summary = `Snapmigrating: ${migrated} migrated, ${skipped} unchanged, ${errors} errors`
        console.log(summary)
        w.i({ see: errors ? `⚠️ ${summary}` : `✅ ${summary}` })
    },

    // shows inflight names + running totals in w/%done
    update_see_snap(w: TheC) {
        const H       = this as House
        const inflight = w.c.snap_inflight as Set<string> | undefined
        const names    = inflight ? [...inflight].map(p => p.split('/').pop()) : []
        const label    = names.length
            ? `⏳ migrating (${w.c.snap_migrated ?? 0} done): ${names.join(', ')}`
            : `⏳ scanning… (${w.c.snap_migrated ?? 0} done)`
        const done = w.oai({ done: 1 })
        done.sc.see = label
    },

//#endregion

    })
    })
</script>
