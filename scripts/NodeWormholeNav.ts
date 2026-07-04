// NodeWormholeNav — a node-fs nav for w:Wormhole, the UIless counterpart to the
//  browser WormholeNav (which wraps a DirectoryListing from the DirectoryOpener).
//  Production Housing.svelte.ts can't import node:fs (it's in the browser bundle), so
//   this lives in the harness and is injected through the A.c.nav seam the Wormhole
//    worker already leaves open (`if (!A.c.nav) …`).
//
// It is an OVERLAY: reads fall through real-repo → sandbox; writes land in the sandbox,
//  so booting compile-pipeline Books (Peregrination, Diffmatication, the Lake*/Leaf*
//   Peeroleum tests, LakeSurprise…) exercises their gen/ + Ghost/ writes WITHOUT
//    mutating the working tree.  The one exception is fixtures under wormhole/, which
//     pass through to the real repo only when `recording` is on (ACCEPT) — so re-record
//      lands real fixtures while plain runs leave even toc.snap untouched.
//
//   The FULL nav contract the worker uses (see Housing.svelte.ts Wormhole / fs_op + rw_op):
//    read_file / write_file / bin_read / bin_write / read_range / dir / dir_at — kept at PARITY with
//     the browser WormholeNav / OpfsOverlayNav / RemoteWormholeNav so the harness is never a partial
//      nav that a binary-writing Book trips over headlessly.
import { readFileSync, writeFileSync, mkdirSync, readdirSync, existsSync, statSync, openSync, readSync, closeSync } from 'node:fs'
import path from 'node:path'

const isDirAt = (p: string) => existsSync(p) && statSync(p).isDirectory()
const isFileAt = (p: string) => existsSync(p) && statSync(p).isFile()

export class NodeWormholeNav {
    base: string       // the real repo root — read-only fallback
    overlay: string    // a /tmp sandbox — where writes land
    recording: boolean // ACCEPT: let wormhole/ fixture writes pass through to base

    constructor(base: string, overlay: string, recording = false) {
        this.base = base
        this.overlay = overlay
        this.recording = recording
    }

    // fixture writes go to the real repo only while recording; everything else sandboxes
    private writeRoot(rel: string): string {
        return this.recording && rel.startsWith('wormhole/') ? this.base : this.overlay
    }

    async read_file(dir_path: string, filename: string): Promise<string | null> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        for (const root of [this.overlay, this.base]) {   // overlay shadows base
            const p = path.join(root, rel)
            if (isFileAt(p)) return readFileSync(p, 'utf8')
        }
        return null
    }

    async write_file(dir_path: string, filename: string, content: string): Promise<void> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        const abs = path.join(this.writeRoot(rel), rel)
        mkdirSync(path.dirname(abs), { recursive: true })
        writeFileSync(abs, content)
    }

    // bin_read — read_file's binary twin: the raw bytes (no utf8 decode).  Overlay shadows base, same fall-through.
    async bin_read(dir_path: string, filename: string): Promise<ArrayBuffer | null> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        for (const root of [this.overlay, this.base]) {   // overlay shadows base
            const p = path.join(root, rel)
            if (isFileAt(p)) { const b = readFileSync(p); return b.buffer.slice(b.byteOffset, b.byteOffset + b.byteLength) as ArrayBuffer }
        }
        return null
    }

    // bin_write — write_file's binary twin: raw bytes into the sandbox (fixtures pass through only while
    //  recording, same writeRoot rule).  Completes the contract so a headless boot can write binary (WAVs).
    async bin_write(dir_path: string, filename: string, bytes: Uint8Array | ArrayBuffer): Promise<void> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        const abs = path.join(this.writeRoot(rel), rel)
        mkdirSync(path.dirname(abs), { recursive: true })
        writeFileSync(abs, bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes))
    }

    // read_range — bin_read's SEEKABLE twin: bytes [offset, offset+len) only (len omitted ⇒ to EOF), never
    //  the whole file — a real fd read of just the window + the total size, matching the browser navs.
    async read_range(dir_path: string, filename: string, offset: number, len?: number): Promise<{ buffer: ArrayBuffer, size: number } | null> {
        const rel = [dir_path, filename].filter(Boolean).join('/')
        for (const root of [this.overlay, this.base]) {   // overlay shadows base
            const p = path.join(root, rel)
            if (!isFileAt(p)) continue
            const size = statSync(p).size
            const end = len == null ? size : Math.min(size, offset + len)
            const length = Math.max(0, end - offset)
            const buf = Buffer.alloc(length)
            const fd = openSync(p, 'r')
            try { if (length > 0) readSync(fd, buf, 0, length, offset) } finally { closeSync(fd) }
            return { buffer: buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength) as ArrayBuffer, size }
        }
        return null
    }

    // dir_at — dir() from a single '/'-joined path string (the discovery-site convenience).
    async dir_at(pth: string) { return this.dir(...pth.split('/').filter(Boolean)) }
    // returns a DirectoryListing-shaped object; .expand() merges base + overlay entries
    async dir(...parts: string[]): Promise<any | null> {
        const rel = parts.filter(Boolean).join('/')
        const roots = [this.base, this.overlay]
        if (!roots.some(r => isDirAt(path.join(r, rel)))) return null
        const nav = this
        return {
            name: parts[parts.length - 1] ?? '',
            directories: [] as { name: string }[],
            files: [] as { name: string }[],
            async expand() {
                const seen = new Map<string, boolean>()   // name → isDir (overlay shadows base)
                for (const root of roots) {
                    const d = path.join(root, rel)
                    if (!isDirAt(d)) continue
                    for (const ent of readdirSync(d, { withFileTypes: true })) seen.set(ent.name, ent.isDirectory())
                }
                this.directories = [...seen].filter(([, isd]) => isd).map(([name]) => ({ name }))
                this.files       = [...seen].filter(([, isd]) => !isd).map(([name]) => ({ name }))
            },
        }
    }
}
