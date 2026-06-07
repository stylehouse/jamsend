<script lang="ts">
// Diffmatic.svelte — diff analysis methods for the Diffmatic frontend.
//
//   Lives alongside Hovercraft / Text as a pure-method ghost (no UI, no
//   snap-facing state).  Diffmaticui calls these from $derived / event
//   handlers; they must be synchronous where possible.
//
// ── Object correlation ────────────────────────────────────────────────────
//
//   The big idea: snap lines encode C particles.  Across two snaps the same
//   particle may drift in depth, acquire new sc fields, or disappear.  We
//   correlate by "identity key" (the stringies mainkey + its value) so the
//   UI can animate each particle from its old position to its new one.
//
//   dm_correlate(left_snap, right_snap) → DmCorrelation
//     DmCorrelation.particles — all particles seen in either snap, keyed by
//       identity, with {left_line, right_line, left_d, right_d, status}.
//       status: 'same' | 'changed' | 'added' | 'removed'
//     DmCorrelation.rows — DiffRow[] from compute_diff (for the text view)
//
// ── Time muting ───────────────────────────────────────────────────────────
//
//   A "mute pointer" covers a range of steps [from_n, to_n] and suppresses
//   per-step noise — instead it exposes only the net diff between the first
//   and last snap in the range.
//
//   dm_mute_range(steps, from_n, to_n) → DmMuteResult
//     Finds got_snap for from_n−1 (baseline) and to_n, diffs them.
//     Returns { rows, label } where label describes the collapsed range.
//
// ── Random inspiration ────────────────────────────────────────────────────
//
//   dm_inspire(steps, step_snaps) → DmInspiration[]
//     Scans all loaded step pairs, scores each diff by complexity
//     (added + removed lines weighted by depth), picks the most interesting
//     clusters, and returns an array of {step_n, headline, rows} sorted by
//     interestingness descending.
//
//   "Interesting" heuristics:
//     - deep mutations (high depth, many char-level changes) → structural insight
//     - sudden large additions after a run of small steps → breakthroughs
//     - lines that appear then disappear within a short window → volatility

import { _C, type TheC } from "$lib/data/Stuff.svelte"
import type { House }    from "$lib/O/Housing.svelte"
import { onMount }       from "svelte"

let { M } = $props()

onMount(async () => {
await M.eatfunc({

//#region Diffmatic

    // ── dm_identity ───────────────────────────────────────────────────────
    //
    //   Extract a stable identity string from one snap line.
    //   Uses deL to split, then takes the first key of stringies as the
    //   mainkey and its value as the discriminator.
    //   Lines that fail to decode (BQ body, blank) return null.
    dm_identity(line: string): string | null {
        const H = this as House
        try {
            const parsed = H.deL(line)
            if (!parsed) return null
            const keys = Object.keys(parsed.stringies)
            if (!keys.length) return null
            const mk  = keys[0]
            const val = parsed.stringies[mk]
            return `${mk}:${val}`
        } catch { return null }
    },

    // ── dm_correlate ─────────────────────────────────────────────────────
    //
    //   Correlate two snaps by particle identity.  Returns a map of all
    //   particles seen in either snap plus the raw DiffRow[] for text rendering.
    //
    //   Particles with the same identity at the same depth → 'same'.
    //   Same identity, different depth or stringies → 'changed'.
    //   Left-only → 'removed'.  Right-only → 'added'.
    //
    //   Depth is read from the line indent (2 spaces per level).
    dm_correlate(
        left_snap:  string,
        right_snap: string,
    ): {
        particles: Map<string, {
            identity:   string
            left_line:  string | null
            right_line: string | null
            left_d:     number
            right_d:    number
            status:     'same' | 'changed' | 'added' | 'removed'
        }>
        rows: any[]
    } {
        const H = this as House

        const index_snap = (snap: string) => {
            const m = new Map<string, { line: string, d: number }>()
            for (const line of snap.split('\n').filter(Boolean)) {
                const id = H.dm_identity(line)
                if (!id) continue
                const d  = H.depth_of(line)
                // first occurrence wins (shallowest is most canonical)
                if (!m.has(id)) m.set(id, { line, d })
            }
            return m
        }

        const left_idx  = index_snap(left_snap)
        const right_idx = index_snap(right_snap)
        const all_ids   = new Set([...left_idx.keys(), ...right_idx.keys()])

        const particles = new Map<string, any>()
        for (const id of all_ids) {
            const l = left_idx.get(id)
            const r = right_idx.get(id)
            let status: 'same' | 'changed' | 'added' | 'removed'
            if (!l)                                 status = 'added'
            else if (!r)                            status = 'removed'
            else if (l.d === r.d && l.line === r.line) status = 'same'
            else                                    status = 'changed'
            particles.set(id, {
                identity:   id,
                left_line:  l?.line  ?? null,
                right_line: r?.line  ?? null,
                left_d:     l?.d     ?? -1,
                right_d:    r?.d     ?? -1,
                status,
            })
        }

        const rows = H.squish_context(H.compute_diff(left_snap, right_snap))
        return { particles, rows }
    },

    // ── dm_mute_range ────────────────────────────────────────────────────
    //
    //   Collapse a step range into a single net diff.
    //   baseline: snap immediately before from_n (from_n-1's got_snap, or '').
    //   target:   got_snap of to_n.
    //   Returns rows + a human label for the collapsed pointer.
    dm_mute_range(
        step_snaps:  Record<number, string>,
        from_n:      number,
        to_n:        number,
    ): { rows: any[], label: string } {
        const H = this as House
        const baseline = step_snaps[from_n - 1] ?? ''
        const target   = step_snaps[to_n]        ?? ''
        if (!baseline && !target) return { rows: [], label: `steps ${from_n}–${to_n} (no snaps)` }
        const rows  = H.squish_context(H.compute_diff(baseline, target))
        const label = `steps ${from_n}–${to_n} (net)`
        return { rows, label }
    },

    // ── dm_score_diff ─────────────────────────────────────────────────────
    //
    //   Score a DiffRow[] by interestingness.
    //   Weights: added deep line > removed deep line > changed line > shallow add.
    //   Squish rows are neutral.
    dm_score_diff(rows: any[]): number {
        const H   = this as House
        let score = 0
        for (const row of rows) {
            if (row.kind === 'left_only') {
                const d = H.depth_of(row.line)
                score  += 2 + d
            } else if (row.kind === 'right_only') {
                const d = H.depth_of(row.line)
                score  += 2 + d
            } else if (row.kind === 'pair' && row.tag === 'changed') {
                score  += 1 + (row.ops?.length ?? 0) * 0.1
            }
        }
        return score
    },

    // ── dm_inspire ────────────────────────────────────────────────────────
    //
    //   Pick the most interesting step-to-step transitions.
    //   Returns up to `limit` inspirations sorted by score desc.
    //   Each inspiration has a concise headline derived from the dominant
    //   change type and the identity of the most-changed particle.
    dm_inspire(
        steps:       Array<{ n: number, dige: string, ok: boolean }>,
        step_snaps:  Record<number, string>,
        limit = 5,
    ): Array<{
        step_n:    number
        headline:  string
        rows:      any[]
        score:     number
    }> {
        const H      = this as House
        const result: Array<{ step_n: number, headline: string, rows: any[], score: number }> = []

        for (let i = 1; i < steps.length; i++) {
            const cur  = steps[i]
            const prev = steps[i - 1]
            const left  = step_snaps[prev.n]
            const right = step_snaps[cur.n]
            if (!left || !right) continue

            const rows  = H.squish_context(H.compute_diff(left, right))
            const score = H.dm_score_diff(rows)
            if (score < 1) continue

            // headline: what kind of change dominates?
            const added   = rows.filter((r: any) => r.kind === 'right_only').length
            const removed = rows.filter((r: any) => r.kind === 'left_only').length
            const changed = rows.filter((r: any) => r.kind === 'pair' && r.tag === 'changed').length

            // find the highest-depth changed or added line for the headline subject
            const notable = rows
                .filter((r: any) => r.kind !== 'squish' && r.kind !== 'pair' || r.tag === 'changed')
                .map((r: any) => {
                    const line = r.line ?? r.right ?? r.left ?? ''
                    return { line, d: H.depth_of(line) }
                })
                .sort((a: any, b: any) => b.d - a.d)[0]

            const subject = notable ? (H.dm_identity(notable.line) ?? notable.line.trim().slice(0, 30)) : ''
            const verb    = added > removed + changed ? 'grew'
                          : removed > added + changed ? 'shrank'
                          : changed > 0               ? 'shifted'
                          :                             'moved'
            const headline = subject ? `step ${cur.n}: ${subject} ${verb}` : `step ${cur.n}: ${verb} (${score | 0}pt)`

            result.push({ step_n: cur.n, headline, rows, score })
        }

        result.sort((a, b) => b.score - a.score)
        return result.slice(0, limit)
    },

//#endregion

})
})
</script>
