// Hashly.ts — the byte-identity hasher: sha256 as lowercase hex, one-shot AND incremental.
//  Wraps @noble/hashes the way Y.svelte.ts wraps @noble/ed25519 — a normal module owns the bare
//   package specifier so a .g can IMPORT this via a plain $lib/O path (the gen context resolves the
//    subpath here, not in the emitted header).  @noble is isomorphic (browser + node harness), sync,
//     and needs no SubtleCrypto — so the hash no longer awaits and no longer re-materializes a whole
//      asset just to digest it (the heist landing's memory high-water motivation).
//  FORMAT CONTRACT — do not drift: `sha256_hex` returns EXACTLY what the old crypto.subtle path did —
//   64 lowercase hex chars, each byte zero-padded, no prefix.  noble's bytesToHex is that same encoding
//    byte-for-byte (verified against the SubtleCrypto+padStart loop over empty / leading-zero / multi-KB
//     inputs), so every body_hash already pinned in a fixture|card keeps matching.  Ra_enid's first-16
//      slice of this value is therefore unchanged too.
import { sha256 } from '@noble/hashes/sha2.js';
import { bytesToHex } from '@noble/hashes/utils.js';

// sha256_hex — the one-shot: full sha256 hex of a whole byte array, the SubtleCrypto replacement.
export function sha256_hex(bytes: Uint8Array): string {
    return bytesToHex(sha256(bytes));
}

// sha256_incremental — a fresh streaming hasher: `.update(chunk)` per slice as bytes flow, then
//  `.hex()` once for the same 64-char lowercase digest the one-shot would give over the concatenation.
//   The heist landing feeds it each %Body chunk as it writes to disk, so the wire-side digest is ready
//    the instant the last chunk lands — an early breach tripwire that costs no read-back.  A digest()
//     finalizes noble's state, so hex() snapshots the running hash into a one-shot over what it has seen
//      (create→update…→digest), leaving the incremental hasher usable only up to that call — the landing
//       calls it exactly once, after the last chunk.
export function sha256_incremental(): { update: (chunk: Uint8Array) => void; hex: () => string } {
    const h = sha256.create();
    return {
        update: (chunk: Uint8Array) => { h.update(chunk); },
        hex: () => bytesToHex(h.digest()),
    };
}
