// RemoteWormholeNav — the third w:Wormhole backend: method:remoteWormhole.
//
//  Same read_file / write_file / bin_write / dir / bin_read / read_range contract as WormholeNav (FSA) and
//   OpfsOverlayNav (cloud) — but rooted in NO local filesystem.  Every call round-trips an rw-op
//    over the relay channel to a trusted EDITOR, which runs it against ITS own handle and replies.
//     A headless runner (a dockerised Chrome — no DirectoryAccess, OPFS illegal under a dev boot)
//      gets the real project tree this way, the editor invisible beneath it: the runner's own
//       Wormhole handler calls this nav exactly as it would a local one (Housing → Wormhole/rw_op),
//        so LiesStore et al. never learn the bytes came over the wire.
//
//  Authorisation rides every request as a %Grant atom (Funk/Grant.ts), minted+signed by the editor
//   and held in the runner's Waft:Cluster — presented back say_trust-style, re-verified each serve.
//   No connection state is trusted as authority; the signed atom is.
//
//  Correlation: replies are NOT auto-correlated to a request seq (the reply carries the editor's own
//   outbound seq).  So each request mints an app-level `corr`; the reply echoes it; _resolve matches.
//   The corr embeds our prepub, so a role-broadcast 'wormhole_reply' (the frozen editor spine has no
//    per-pub to:<pub> yet) only resolves on the runner that asked.
//
//  Bytes: bin/read_range replies are binary frames ([header JSON]\n[raw buffer]) — no base64 tax.
//   read_range keeps the transfer to the requested WINDOW regardless, so a 1.4GB asset never crosses whole.

import type { TheC } from '$lib/data/Stuff.svelte'
import type { GrantAtom } from '$lib/O/Funk/Grant'

const REQ_TIMEOUT_MS = 20_000
const RETRY_MS = 4_000   // re-emit a silent request every 4s (a healthy round-trip is ~300ms) with a fresh seq

export class RemoteWormholeNav {
    is_remote = true                 // the DirectoryOpener / Wormhole seam recognises this
    // Atime-async: this backend's promises settle off an INBOUND frame (wormhole_reply), whose
    //  delivery itself needs Atime — so an op must never be awaited under the beliefs mutex
    //   (the await would starve the very reply it waits on; every op sits its full REQ_TIMEOUT
    //    with the machine seized).  The Wormhole actor reads this flag and runs the op OFF
    //     Atime, finishing the req on the pass after it settles.  Disk navs (FSA/OPFS) resolve
    //      from the disk event loop, independent of Atime, and stay inline-awaitable.
    atime_async = true
    is_opfs_github = false
    label = 'remoteWormhole'
    private H: any
    private w: TheC                  // w:Lies — where the Pier/channel lives
    private grant_of: () => GrantAtom | undefined   // read the held grant lazily (it can refresh)
    private pending = new Map<string, { resolve: (r: any) => void; reject: (e: any) => void }>()
    private seq = 0
    // rolling round-trip tally (measure-before-optimise): so "is remoteWormhole actually slow" has a
    //  numeric answer without eyeballing every line.  Fed by rw_tally on each op's completion.
    private rw_n = 0; private rw_sum = 0; private rw_max = 0; private rw_slow = 0; private rw_naked = 0; private rw_retried = 0
    private rw_last_summary = 0

    constructor(H: any, w_lies: TheC, grant_of: () => GrantAtom | undefined) {
        this.H = H; this.w = w_lies; this.grant_of = grant_of
    }

    private corr(): string {
        const me = this.H.Lies_self?.(this.w)?.prepub ?? 'r'
        return `${me}-${Date.now()}-${++this.seq}`
    }

    // one request → its matching reply.  The reply arrives via Lies_wormhole_reply_recv → _resolve.
    //  Self-checking: a healthy round-trip is ~300ms, so silence is a fault worth narrating.
    //
    //  ACK-GATED RE-EMIT on silence (spec §8, the reconnect-epoch gap).  A runner that reloaded restarts its
    //   per-Pier seq LOW, colliding with seqs the editor's Pier already consumed+finished; the editor drops
    //    the reused-seq frame as a delivered-dup (a finished %req:unemit for that seq) — silently, without
    //     even a re-ack (confirmed on the wire) — so no reply ever comes and the read used to dead-wait the
    //      whole 20s before re-dispatching ("stuck 16s, not retrying").  We re-emit ONLY while the last emit
    //       is still UN-ACKED: an ack means the request LANDED and was processed (the ack fires right after
    //        req_unemit, which is also where the reply is sent), so re-sending would be a wasteful double-land
    //         (a 400KB bin_write especially) — if it's acked we just keep waiting for a merely-slow/lost reply.
    //          A NOT-acked silence is the collision (or a genuine transport loss): re-emit with a FRESH seq,
    //           which climbs monotonically past the editor's stale high-water until the request lands.  Same
    //            corr every attempt so the eventual reply still matches; the op is idempotent so a double-land
    //             is harmless.  Cures it from the SEND side — no change to the frozen editor spine.  The true
    //              root (editor resets the Pier epoch on re-hello + re-acks a dup) still wants doing.
    private send(op: string, params: Record<string, unknown>, buffer?: ArrayBuffer | Uint8Array): Promise<any> {
        const grant = this.grant_of()
        if (!grant) return Promise.reject('remoteWormhole: no grant held')
        const corr = this.corr()
        const what = `${op} ${[params.dir_path, params.filename].filter(Boolean).join('/')}`
        // ── timing instrument (measure-before-optimise): tell a genuinely-slow round-trip apart from a fault
        //     wearing slowness as a disguise.  t0→t_ack (emit→%acked) is the transport+delivery cost; the
        //      remainder (t_ack→reply) is the editor's serve cost; a TIMEOUT that never acked is the channel-
        //       down / mutex-starved / epoch-collision family — NOT latency.  tries>1 is the reconnect seq-climb.
        //        One line per op (debug when clean, warn when slow/faulty) + a throttled rolling summary, so
        //         "really slow" and "fix-networking-in-disguise" read as different shapes in the console.
        const t0 = Date.now()
        let t_ack = 0
        let tries = 1
        let last_seq: number | undefined
        let ackPoll: ReturnType<typeof setInterval>
        const logdone = (kind: string) => {
            clearInterval(ackPoll)
            const dt = Date.now() - t0
            this.rw_tally(dt, t_ack ? t_ack - t0 : null, tries)
            const timing = t_ack ? `${dt}ms (ack ${t_ack - t0}ms · reply +${Date.now() - t_ack}ms)` : `${dt}ms · NEVER acked`
            const bad = kind !== 'ok', slow = dt > 1500
            const line = `${bad ? '🕳✗' : slow ? '🕳🐌' : '🕳✓'} remoteWormhole ${what} — ${kind} in ${timing}; ${tries} tr${tries > 1 ? 'ies' : 'y'} (corr ${corr})`
            ;(bad || slow || tries > 1 ? console.warn : console.debug)(line)
        }
        const p = new Promise<any>((resolve, reject) => this.pending.set(corr, {
            resolve: (r: any) => { logdone('ok'); resolve(r) },   // reject is reached only from the timeout, which logs there
            reject: (e: any) => reject(e),
        }))
        // A binary op (bin_write) rides a RAW-bytes frame — app meta (corr/grant/op/path) on the header,
        //  the payload on frame.buffer (off-snap, body_hash-integrity), no base64 tax and no snapped emit
        //   bloat.  A text op rides the JSON consumer body.  Both correlate the reply by the same corr, and
        //    both return the emit's seq so we can watch it go %acked.
        const emit = async () => {
            last_seq = buffer != null
                ? await this.H.Lies_send_binary_consumer(this.w, 'wormhole_req', { corr, grant, op, ...params }, buffer)
                : this.H.Peeroleum_send_consumer(this.w, 'wormhole_req', { corr, grant, op, ...params })
        }
        void emit()
        // fast ack-time capture: the RETRY interval below is 4s — far too coarse to time a ~300ms ack.
        ackPoll = setInterval(() => {
            if (!this.pending.has(corr)) { clearInterval(ackPoll); return }
            if (!t_ack && this.acked(last_seq)) { t_ack = Date.now(); clearInterval(ackPoll) }
        }, 120)
        const retry = setInterval(() => {
            if (!this.pending.has(corr)) { clearInterval(retry); return }   // resolved/timed-out — stop
            if (this.acked(last_seq)) {   // it LANDED (+was processed) — don't re-send, the reply is just slow/lost
                console.warn(`🕳… remoteWormhole ${what} — seq ${last_seq} acked (landed) but no reply yet; waiting, not re-emitting (corr ${corr})`)
                return
            }
            tries++
            console.warn(`🕳↻ remoteWormhole ${what} — seq ${last_seq} un-acked after ${(RETRY_MS * (tries - 1)) / 1000}s, re-emitting with a fresh seq (try ${tries}; climbs past a stale reconnect high-water; corr ${corr})`)
            void emit()
        }, RETRY_MS)
        setTimeout(() => {
            clearInterval(retry)
            const e = this.pending.get(corr)
            if (e) {
                this.pending.delete(corr)
                const how = t_ack ? `acked at ${t_ack - t0}ms but no reply came` : 'never acked'
                logdone(`TIMEOUT — ${how}`)
                e.reject(`remoteWormhole: ${what} timed out after ${REQ_TIMEOUT_MS / 1000}s and ${tries} tries — ${how} (editor offline / grant refused / starved under the beliefs mutex / reply lost)`)
            }
        }, REQ_TIMEOUT_MS)
        return p
    }

    // acked — has the outbox %emit for `seq` on our consumer Pier been stamped %acked?  Mirrors
    //  Peeroleum_take_ack's walk (Peeroleum.g).  An ack proves the frame was DELIVERED and (on this
    //   codepath) processed, which is what gates the re-emit above.  Loose == to tolerate a snapped seq.
    private acked(seq: number | undefined): boolean {
        if (seq == null) return false
        const pier = this.w.o({ Peering: 1 })[0]?.o({ Pier: 1 })[0] as any
        const emit = pier?.o({ outbox: 1 })[0]?.o({ emit: 1 }).find((e: any) => e.sc.seq == seq)
        return !!emit?.sc.acked
    }

    // rw_tally — fold one completed op into the rolling stat and emit a THROTTLED summary line (single op →
    //  one summary; a burst → ~1/sec, plus an immediate one on any slow/never-acked op).  This is the line
    //   that actually answers "is it slow": a low avg with 0 never-acked means the transport is fine and any
    //    felt slowness is elsewhere; a high never-acked count means the ops aren't landing at all (fault, not
    //     latency); a high avg with acks landing fast means the EDITOR's serve is the cost (batch the walk).
    private rw_tally(dt: number, ackMs: number | null, tries: number): void {
        this.rw_n++; this.rw_sum += dt
        if (dt > this.rw_max) this.rw_max = dt
        if (dt > 1500) this.rw_slow++
        if (ackMs == null) this.rw_naked++
        if (tries > 1) this.rw_retried++
        const now = Date.now()
        if (now - this.rw_last_summary > 1000 || dt > 1500 || ackMs == null) {
            this.rw_last_summary = now
            console.log(`📊 remoteWormhole: ${this.rw_n} ops · avg ${Math.round(this.rw_sum / this.rw_n)}ms · max ${this.rw_max}ms · ${this.rw_naked} never-acked · ${this.rw_retried} retried · ${this.rw_slow} slow>1.5s`)
        }
    }

    // a devtools-callable snapshot (the nav is reachable as H.c.wormhole on the runner) — or wire into a
    //  runner_ask diag op later so the tally is scriptable, not just eyeballed.
    rw_stats() {
        return { ops: this.rw_n, avg: this.rw_n ? Math.round(this.rw_sum / this.rw_n) : 0, max: this.rw_max, never_acked: this.rw_naked, retried: this.rw_retried, slow: this.rw_slow }
    }

    // the editor → runner reply handler funnels here (keyed by corr).
    _resolve(corr: string, reply: any): void {
        const e = this.pending.get(corr)
        if (e) { this.pending.delete(corr); e.resolve(reply) }
    }

    async read_file(dir_path: string, filename: string): Promise<string | null> {
        const r = await this.send('read', { dir_path, filename })
        if (r.error) throw r.error
        return r.not_found ? null : (r.content ?? null)
    }

    async write_file(dir_path: string, filename: string, content: string): Promise<void> {
        const r = await this.send('write', { dir_path, filename, data: content })
        if (r.error) throw r.error
    }

    // bin_write — write_file's BINARY twin over the wire: the bytes cross as a raw frame (op:'bin_write'),
    //  so a generated WAV lands on the editor's disk exactly as a local WormholeNav.bin_write would.  The
    //   editor runs it against ITS nav and replies a small JSON {ok}|{error} — matched by corr like any op.
    //    This is what unblocks MusuGenerateTestsMusic on a headless/&remoteWormhole runner (no local share).
    async bin_write(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void> {
        const r = await this.send('bin_write', { dir_path, filename }, bytes)
        if (r.error) throw r.error
    }

    async bin_read(dir_path: string, filename: string): Promise<ArrayBuffer | null> {
        const r = await this.send('bin', { dir_path, filename })
        if (r.error || r.not_found) return null
        return frame_bytes(r)
    }

    // the seekable read — only [offset, offset+len) crosses the wire.
    async read_range(dir_path: string, filename: string, offset: number, len?: number): Promise<{ buffer: ArrayBuffer, size: number } | null> {
        const r = await this.send('read_range', { dir_path, filename, offset: String(offset), len: len == null ? '' : String(len) })
        if (r.error || r.not_found) return null
        const buffer = frame_bytes(r)
        if (!buffer) return null
        const size = Number(r.header?.size ?? r.size ?? buffer.byteLength)   // size rides the header on a binary reply
        return { buffer, size }
    }

    // dir_at — dir() from a single '/'-joined path string (the discovery-site convenience).
    async dir_at(path: string) { return this.dir(...path.split('/').filter(Boolean)) }
    // a DirectoryListing-shaped probe (the worker calls .expand() then reads .directories/.files).
    //  The remote list is taken eagerly, so expand() is a no-op.
    async dir(...parts: string[]): Promise<{ name: string, directories: { name: string }[], files: { name: string }[], expand(): Promise<void> } | null> {
        const r = await this.send('list', { dir_path: parts.join('/') })
        if (r.error || r.not_found) return null
        const entries = (r.entries ?? []) as { name: string, is_dir: boolean }[]
        return {
            name: parts[parts.length - 1] ?? '',
            directories: entries.filter(e => e.is_dir).map(e => ({ name: e.name })),
            files: entries.filter(e => !e.is_dir).map(e => ({ name: e.name })),
            async expand() { /* already populated */ },
        }
    }
}

// the bytes off a binary reply: frame.buffer is a Uint8Array view into the decoded [header]\n[buffer]
//  — copy to an exact own ArrayBuffer so callers own the memory.
function frame_bytes(r: any): ArrayBuffer | null {
    if (r.buffer != null) {
        const u8 = r.buffer instanceof Uint8Array ? r.buffer : new Uint8Array(r.buffer)
        return u8.slice().buffer        // .slice() copies the exact window off the larger frame buffer
    }
    return null
}

