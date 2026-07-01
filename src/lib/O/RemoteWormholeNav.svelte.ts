// RemoteWormholeNav — the third w:Wormhole backend: method:remoteWormhole.
//
//  Same read_file / write_file / dir / bin_read / read_range contract as WormholeNav (FSA) and
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
//  Bytes: bin/read_range bytes ride base64 in the reply JSON for now — correct, but a 33% tax the
//   Cluster_spec rejects for file-sized payloads.  TODO: move bytes to the binary frame / offer_stream
//    path (the spine already carries frame.buffer off-snap).  read_range keeps the transfer to the
//     requested WINDOW regardless, so a 1.4GB asset never crosses whole.

import type { TheC } from '$lib/data/Stuff.svelte'
import type { GrantAtom } from '$lib/O/Funk/Grant'

const REQ_TIMEOUT_MS = 20_000

export class RemoteWormholeNav {
    is_remote = true                 // the DirectoryOpener / Wormhole seam recognises this
    is_opfs_github = false
    label = 'remoteWormhole'
    private H: any
    private w: TheC                  // w:Lies — where the Pier/channel lives
    private grant_of: () => GrantAtom | undefined   // read the held grant lazily (it can refresh)
    private pending = new Map<string, { resolve: (r: any) => void; reject: (e: any) => void }>()
    private seq = 0

    constructor(H: any, w_lies: TheC, grant_of: () => GrantAtom | undefined) {
        this.H = H; this.w = w_lies; this.grant_of = grant_of
    }

    private corr(): string {
        const me = this.H.Lies_self?.(this.w)?.prepub ?? 'r'
        return `${me}-${Date.now()}-${++this.seq}`
    }

    // one request → its matching reply.  The reply arrives via Lies_wormhole_reply_recv → _resolve.
    private send(op: string, params: Record<string, unknown>): Promise<any> {
        const grant = this.grant_of()
        if (!grant) return Promise.reject('remoteWormhole: no grant held')
        const corr = this.corr()
        const p = new Promise<any>((resolve, reject) => this.pending.set(corr, { resolve, reject }))
        this.H.Peeroleum_send_consumer(this.w, 'wormhole_req', { corr, grant, op, ...params })
        setTimeout(() => {
            const e = this.pending.get(corr)
            if (e) { this.pending.delete(corr); e.reject(`remoteWormhole: ${op} timed out`) }
        }, REQ_TIMEOUT_MS)
        return p
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

// the bytes off a reply: a binary frame carries them raw on frame.buffer (a Uint8Array view into the
//  decoded [header]\n[buffer] — copy to an exact own ArrayBuffer); the degenerate path carries base64.
function frame_bytes(r: any): ArrayBuffer | null {
    if (r.buffer != null) {
        const u8 = r.buffer instanceof Uint8Array ? r.buffer : new Uint8Array(r.buffer)
        return u8.slice().buffer        // .slice() copies the exact window off the larger frame buffer
    }
    if (r.bytes_b64 != null) return b64_to_buf(r.bytes_b64)
    return null
}

// ── base64 (chunked — a spread over a multi-MB Uint8Array blows the call stack) ───────────────
const B64_CHUNK = 0x8000
export function buf_to_b64(buf: ArrayBuffer): string {
    const bytes = new Uint8Array(buf)
    let s = ''
    for (let i = 0; i < bytes.length; i += B64_CHUNK)
        s += String.fromCharCode(...bytes.subarray(i, i + B64_CHUNK))
    return btoa(s)
}
export function b64_to_buf(b64: string): ArrayBuffer {
    const s = atob(b64 ?? '')
    const bytes = new Uint8Array(s.length)
    for (let i = 0; i < s.length; i++) bytes[i] = s.charCodeAt(i)
    return bytes.buffer
}
