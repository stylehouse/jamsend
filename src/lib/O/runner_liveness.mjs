// runner_liveness.mjs — the ONE home for the editor↔runner channel-liveness thresholds
//  and the verdict that reads them.  Deliberately a plain `.mjs` (no TS syntax) so BOTH sides
//   import the SAME numbers: the ghost (LiesLies.svelte, through Vite/`$lib`) AND the node CLI
//    (scripts/runner_ask.mjs, run by raw `node`, which cannot import a `.ts`).  `checkJs` is on,
//     so this file is type-checked too — keep it clean JS.
//
//  Before this module, the three death criteria drifted: DEAD/SLUGGISH lived inline in
//   Lies_keepalive, LIVE inline in Lies_runner_roster, and the CLI invented its OWN 8s bail —
//    BELOW even sluggish (9s), so a merely-busy tab read as dead and `--watch` went false-RED.
//     Now the rack badge, the reaper, and the CLI all read from here.

// SLUGGISH — heard something, but our ping isn't coming home: the peer is BUSY (think-quiesced),
//  NOT gone.  A surface-it-only state; NEVER tear the channel on sluggish.
export const SLUGGISH_MS = 9000
// DEAD — nothing inbound AT ALL past this: the carrier really is gone → the editor re-dials, the
//  CLI declares the runner dead.  The one true "fatal" boundary.
export const DEAD_MS = 20000
// LIVE — the editor's roster lapses a runner's live grant (ready|book|engaged|ac) past this;
//  identity stays known, only the live claims clear.
export const LIVE_MS = 45000
// PIER_CULL — a promoted Pier (an addressed transport) to a runner silent this long is an address
//  to nobody → reap it (re-promotion on the next dispatch is one oai, so a cull costs nothing).
export const PIER_CULL_MS = 5 * 60 * 1000

/**
 * liveness — the pure verdict, shared so rack, reaper and CLI never disagree on "is it dead?".
 *  All times are epoch ms.  `heard` = newest inbound frame of ANY kind (the half-open-proof
 *   signal — a frame arriving IS the carrier working); `last` = our ping's last round-trip home;
 *    `progress` = last time the peer made forward progress (a run step advanced).  Fresh progress
 *     is positive proof of life that OUTRANKS silence, so a busy-but-advancing runner is never
 *      called dead.  A caller that has no ping RTT (the CLI) passes `last:0` — sluggish then never
 *       fires and the verdict is simply live-until-DEAD, which is exactly its semantic.
 * @param {{ now:number, heard?:number, last?:number, progress?:number }} t
 * @returns {'live'|'sluggish'|'dead'|'unknown'}
 */
export function liveness({ now, heard = 0, last = 0, progress = 0 }) {
	const seen = Math.max(heard, progress)
	if (!seen) return 'unknown'                       // never heard anything — can't judge
	if (now - seen > DEAD_MS) return 'dead'           // silent past the fatal boundary
	if (last && now - last > SLUGGISH_MS) return 'sluggish'  // hearing it, but our ping is late
	return 'live'
}
