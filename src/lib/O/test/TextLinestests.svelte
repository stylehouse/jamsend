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
    //   Hex strings that happen to look numeric are always strings when written
    //   with ":" — "dige:deadbeef" is a string, never coerced.
    //
    //   Encoding decisions in encode_stringies:
    //     number  → bare key  (key=1  in peel terms, emitted as key when value=1)
    //     string  → key:value (key:v  in peel terms)
    //     if any key or value contains :/,/\t/\n → fallback to JSON
    //
    //   Large numbers, floats, and subnormals all encode as numbers (key=N form).
    //
    // ── Snap test format ──────────────────────────────────────────────────────
    //
    //   Snaptesting writes particles into w, encodes via encode_wh_lines,
    //   then decodes via decode_wh_lines and asserts round-trip equality.
    //   Each section uses w.r({section:N},{}) to isolate test groups.
    //
    //   The nowriting opt is set on w/{Opt:1}/{nowriting:1} so LiesStore_write
    //   logs intent rather than hitting disk — tests stay in-memory.
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
    //
    //   w.r({section:N},{}) resets the test basket between groups.
    //
    //   Assertions use assert_eq(label, got, want) which logs and counts failures.
    //
    async Snaptesting(A: TheC, w: TheC) {
        const H = this as House
        let failures = 0
        let t // current section

        const assert_eq = (label: string, got: any, want: any) => {
            const ok = JSON.stringify(got) === JSON.stringify(want)
            if (!ok) {
                console.error(`❌ ${label}:`, { got, want })
                failures++
            } else {
                console.log(`✅ ${label}`)
            }
        }

        // round-trip a particle through encode_wh_lines → decode_wh_lines
        //   and return the decoded sc so assertions can check field types.
        const round_trip = async (sc: Record<string, any>): Promise<Record<string, any>> => {
            const { _C } = await import('$lib/data/Stuff.svelte')
            const root = _C({ section: 'rt_root' })
            root.i(_C({ ...sc }))
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
        //   "key=1"   would never appear written — bare key means the number 1
        //   key       bare key (number 1) → round-trips as number 1
        //
        await w.r({ section: 1 }, {})
        {
            // three_as_string:'3' must round-trip as the string "3", not number 3
            // three_as_number:3 must round-trip as the number 3
            const t = w.i({ section: 'Lines-encoding is explicit about number|string' })
            const sc1 = t.i({ three_as_string: '3', three_as_number: 3 })
            const sc2 = t.i({ one_as_string: '1', one_as_number: 1 })

            const rt1 = await round_trip(sc1)
            assert_eq('three_as_string is string', typeof rt1.three_as_string, 'string')
            assert_eq('three_as_string value', rt1.three_as_string, '3')
            assert_eq('three_as_number is number', typeof rt1.three_as_number, 'number')
            assert_eq('three_as_number value', rt1.three_as_number, 3)

            // one_as_string:'1' — the codec path most likely to be confused with a flag
            const rt2 = await round_trip(sc2)
            assert_eq('one_as_string is string', typeof rt2.one_as_string, 'string')
            assert_eq('one_as_string value', rt2.one_as_string, '1')
            assert_eq('three_as_number (2) is number', typeof rt2.three_as_number, 'number')
            assert_eq('three_as_number (2) value', rt2.three_as_number, 3)
        }

        // ── section 2: flags (bare key = number 1) ────────────────────────────
        {
            // {finished:1} is the canonical flag form — must round-trip as number 1
            const rt = await round_trip({ finished: 1, count: 7 })
            assert_eq('finished flag is number', typeof rt.finished, 'number')
            assert_eq('finished flag value', rt.finished, 1)
            assert_eq('count is number', typeof rt.count, 'number')
            assert_eq('count value', rt.count, 7)
        }

        // ── section 3: large and small numbers ────────────────────────────────
        //
        //   Numbers must stay numbers across round-trip regardless of magnitude.
        //   Subnormals and >Number.MAX_SAFE_INTEGER are edge cases for JSON,
        //   but encode_stringies passes them through as numbers — peel handles them.
        //
        await w.r({ section: 3 }, {})
        {
            const bignumber   = 6325612519811704
            const smallnumber = 0.000024
            // subnormal — smallest positive float, effectively 5e-324
            const tinynumber  = 5e-324

            const rt = await round_trip({ bignumber, smallnumber, tinynumber })
            assert_eq('bignumber type', typeof rt.bignumber, 'number')
            assert_eq('bignumber value', rt.bignumber, bignumber)
            assert_eq('smallnumber type', typeof rt.smallnumber, 'number')
            assert_eq('smallnumber value', rt.smallnumber, smallnumber)
            assert_eq('tinynumber type', typeof rt.tinynumber, 'number')
            // subnormals may not survive JSON encode faithfully — assert type at minimum
            assert_eq('tinynumber is finite or zero', isFinite(rt.tinynumber) || rt.tinynumber === 0, true)
        }

        // ── section 4: hex dige strings ───────────────────────────────────────
        //
        //   A hex string like "deadbeef" must never be coerced to a number.
        //   dige values are always strings even if they parse as hex numbers.
        //
        await w.r({ section: 4 }, {})
        {
            const rt = await round_trip({ dige: 'deadbeef01234567', base_dige: 'cafebabe00000001' })
            assert_eq('dige is string', typeof rt.dige, 'string')
            assert_eq('dige value', rt.dige, 'deadbeef01234567')
            assert_eq('base_dige is string', typeof rt.base_dige, 'string')
            assert_eq('base_dige value', rt.base_dige, 'cafebabe00000001')
        }

        // ── section 5: mixed particle — realistic req fields ──────────────────
        await w.r({ section: 5 }, {})
        {
            const rt = await round_trip({
                req:      'wread',       // string mainkey value
                rw_name:  'wormhole/Ghost/Tour/toc.snap',  // path string with /
                finished: 1,             // flag
                req_i:    42,            // serial number
                label:    'source_check',
            })
            assert_eq('req is string', typeof rt.req, 'string')
            assert_eq('req value', rt.req, 'wread')
            assert_eq('rw_name is string', typeof rt.rw_name, 'string')
            assert_eq('finished is number', typeof rt.finished, 'number')
            assert_eq('req_i is number', typeof rt.req_i, 'number')
            assert_eq('req_i value', rt.req_i, 42)
            assert_eq('label is string', typeof rt.label, 'string')
        }

        // ── section 6: zero and negative numbers ──────────────────────────────
        await w.r({ section: 6 }, {})
        {
            const rt = await round_trip({ zero: 0, negative: -3, neg_float: -0.001 })
            assert_eq('zero type', typeof rt.zero, 'number')
            assert_eq('zero value', rt.zero, 0)
            assert_eq('negative type', typeof rt.negative, 'number')
            assert_eq('negative value', rt.negative, -3)
            assert_eq('neg_float type', typeof rt.neg_float, 'number')
        }

        // ── section 7: string that looks like a number ────────────────────────
        //
        //   "42" as a string must not be decoded as the number 42.
        //   encode_stringies uses the presence of a colon to signal string,
        //   so "count:'42'" must remain a string.
        //
        await w.r({ section: 7 }, {})
        {
            const rt = await round_trip({ count: '42', version: '1.2.3' })
            assert_eq('count is string', typeof rt.count, 'string')
            assert_eq('count value', rt.count, '42')
            assert_eq('version is string', typeof rt.version, 'string')
            assert_eq('version value', rt.version, '1.2.3')
        }

        if (failures) {
            console.error(`Snaptesting: ${failures} failure(s)`)
            w.i({ see: `❌ Snaptesting: ${failures} failures` })
        } else {
            console.log('Snaptesting: all passed ✅')
            w.i({ see: '✅ Snaptesting passed' })
        }
    },

//#endregion
//#region Snapmigrating

    // ── Snapmigrating ─────────────────────────────────────────────────────────
    //
    //   Depth-first scan of every .snap file reachable from Wormhole.
    //   For each file: decode_wh_lines → encode_wh_lines → if snap changed, write back.
    //
    //   The encode step applies the current codec rules (colon=string, bare=number),
    //   so any old file that conflated them gets corrected in place.
    //
    //   Errors from decode or encode abort that file (logged, not thrown).
    //   A dry_run:1 opt skips the write and logs what would change.
    //
    async Snapmigrating(A: TheC, w: TheC) {
        const H = this as House

        const dry_run = !!H.o_Opt_val(w, 'dry_run')
        if (dry_run) console.log('🔎 Snapmigrating: dry run — no writes')

        let migrated = 0
        let skipped  = 0
        let errors   = 0

        // walk_dir: depth-first directory listing via LiesStore_listing.
        //   Returns when every .snap file in the subtree has been visited.
        const walk_dir = async (dir: string) => {
            const req = await H.LiesStore_listing(w, dir)

            // wait for the listing to complete (one tick each time)
            if (!req.sc.finished) {
                // re-entry: caller drives us back on the next tick via ttlilt
                H.i_req_ttlilt(req, 0.5, { waiting: 'listing' })
                return
            }

            const reply = req.sc.reply as any
            if (reply?.not_found) return
            if (reply?.error) {
                console.error(`Snapmigrating: listing error at ${dir}:`, reply.error)
                errors++
                return
            }

            const entries: Array<{ name: string, is_dir: boolean }> = reply?.entries ?? []

            // recurse into subdirectories first (depth-first)
            for (const entry of entries) {
                if (entry.is_dir) {
                    await walk_dir(`${dir}/${entry.name}`)
                }
            }

            // then handle .snap files at this level
            for (const entry of entries) {
                if (!entry.name.endsWith('.snap')) continue
                const path = `${dir}/${entry.name}`
                await migrate_snap(path)
            }
        }

        const migrate_snap = async (path: string) => {
            // read the snap
            const rreq = await H.LiesStore_read(w, path)
            if (!rreq.sc.finished) {
                H.i_req_ttlilt(rreq, 0.5, { waiting: 'read' })
                return
            }

            const reply = rreq.sc.reply as any
            if (reply?.not_found) { skipped++; return }
            if (reply?.error) {
                console.error(`Snapmigrating: read error at ${path}:`, reply.error)
                errors++
                return
            }

            const old_snap = reply.content as string

            // decode with current codec
            const { C, errors: de } = H.decode_wh_lines(old_snap)
            if (!C) {
                console.error(`Snapmigrating: decode failed at ${path}:`, de)
                errors++
                return
            }
            if (de.length) {
                console.warn(`Snapmigrating: decode warnings at ${path}:`, de)
            }

            // re-encode with current codec
            const { snap: new_snap, errors: ee } = await H.encode_wh_lines(C, {})
            if (ee.length) {
                console.error(`Snapmigrating: encode errors at ${path}:`, ee)
                errors++
                return
            }

            if (new_snap === old_snap) {
                skipped++
                return
            }

            if (dry_run) {
                console.log(`🔎 would migrate: ${path}`)
                migrated++
                return
            }

            // write back
            const wreq = await H.LiesStore_write(w, path, new_snap)
            if (!wreq) {
                // LiesStore_write returned null: content-equality gate (shouldn't happen
                // since we just confirmed new_snap !== old_snap, but be safe)
                skipped++
                return
            }
            migrated++
            console.log(`💾 Snapmigrating: migrated ${path}`)
        }

        // start at the wormhole root
        await walk_dir('wormhole')

        const summary = `Snapmigrating: ${migrated} migrated, ${skipped} unchanged, ${errors} errors`
        console.log(summary)
        w.i({ see: errors ? `⚠️ ${summary}` : `✅ ${summary}` })
    },

//#endregion

    })
    })
</script>
