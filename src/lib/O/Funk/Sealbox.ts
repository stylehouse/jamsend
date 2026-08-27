// Sealbox — symmetric authenticated encryption for the LinkDevice account transfer.
//
//  The ceremony (Portability_doc §10 "Division") moves the account Waft as relay frames under
//   a code-derived key: the relay is an unauthenticated forwarder, so assume an eavesdropper on
//    the wire.  Idento ($lib/Y.svelte) is ed25519 + SHA-256 ONLY — it signs and it hashes, it
//     never keeps a secret — so this is the ONE symmetric brick the codebase needs, built on
//      WebCrypto (AES-GCM under an HKDF-SHA-256 key), zero new deps.  It sits beside Grant.ts
//       (the ed25519 capability atom) as its secrecy-side twin: Grant proves WHO said a thing,
//        Sealbox keeps a thing UNREADABLE to everyone but the holder of the code.
//
//  Modelled on Grant.ts's shape — a tiny pure module a .g Book imports (the IMPORT() idiom) and
//   the real ceremony calls the same way, so a green Book exercises the SHIPPING code, never a
//    parallel copy that could drift.
//
//  The two operations:
//    seal   — derive a key from (secret IKM, salt), encrypt the plaintext with a FRESH random
//              96-bit IV.  The frame is `iv ‖ ciphertext‖tag`, hex-encoded (the codebase's habit
//               — sigs, cids, prepubs are all hex; greppable, snap-legible, base64-edge-free).
//              CIPHERTEXT IS NON-DETERMINISTIC BY DESIGN: a fixed IV reused under one AES-GCM key
//               is the catastrophic nonce-reuse break, so a fresh IV per seal is mandatory, and a
//                Book therefore asserts BEHAVIOUR (unseal∘seal = identity; a flipped byte throws;
//                 a wrong code throws), NEVER the bytes — the determinism law's crypto corollary.
//    unseal — re-derive the same key, verify-and-decrypt.  THROWS on a wrong code or a tampered
//              frame: AES-GCM's tag IS the authentication, so this fails closed exactly like
//               verify_grant — a hostile frame crashes the open, it never half-decrypts.
//
//  WHAT THE KEY IS DERIVED FROM is deliberately left to the caller (ikm + salt strings): Phase 1
//   is the brick, and Phase 3 (the beacon + issue) decides the actual shared secret — a code, or
//    an ephemeral-pub agreement.  The brick's contract holds whatever those turn out to be.

import { enhex, dehex } from '$lib/Y.svelte'

// domain separation: this info string binds a derived key to THIS use (the LinkDevice account
//  transfer, v1), so the same (ikm, salt) can never yield a colliding key for some later use.
const SEALBOX_INFO = 'jamsend-linkdevice-account-v1'
const IV_BYTES = 12                       // 96 bits — the AES-GCM standard, and what a fresh nonce wants

const enc = (s: string): Uint8Array => new TextEncoder().encode(s)
const dec = (b: ArrayBuffer | Uint8Array): string =>
    new TextDecoder().decode(b instanceof Uint8Array ? b : new Uint8Array(b))

// ── the derived key ──────────────────────────────────────────────────────────────────────────
//  HKDF-SHA-256 from the secret IKM, salted by (the ceremony hands both pubs — a value an
//   eavesdropper knows, which is exactly what a salt is for: domain-separating, not secret).
//    The key is non-extractable — it never leaves WebCrypto, so even a compromised heap dump of
//     the C tree cannot leak it (it was never a particle; it was never hex).
export async function seal_key(ikm: string, salt: string): Promise<CryptoKey> {
    if (!ikm) throw 'seal_key: empty ikm'
    const base = await crypto.subtle.importKey('raw', enc(ikm), 'HKDF', false, ['deriveKey'])
    return await crypto.subtle.deriveKey(
        { name: 'HKDF', hash: 'SHA-256', salt: enc(salt || ''), info: enc(SEALBOX_INFO) },
        base,
        { name: 'AES-GCM', length: 256 },
        false,
        ['encrypt', 'decrypt'],
    )
}

// ── seal ───────────────────────────────────────────────────────────────────────────────────
//  Returns the wire frame as hex: iv(12) ‖ ciphertext(includes the 16-byte GCM tag).  A fresh
//   random IV every call — so two seals of the same plaintext differ, and that difference is a
//    FEATURE the Book leans on to prove the nonce is live.
export async function seal(ikm: string, salt: string, plaintext: string): Promise<string> {
    const key = await seal_key(ikm, salt)
    const iv = crypto.getRandomValues(new Uint8Array(IV_BYTES))
    const ct = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, enc(plaintext)))
    const frame = new Uint8Array(iv.length + ct.length)
    frame.set(iv, 0)
    frame.set(ct, iv.length)
    return enhex(frame)
}

// ── unseal ─────────────────────────────────────────────────────────────────────────────────
//  Re-derive, split the IV back off the front, verify-and-decrypt.  THROWS on any failure — a
//   wrong code, a flipped byte, a truncated frame — because a caller must never mistake a
//    tampered account for a real one.  Fails closed.
export async function unseal(ikm: string, salt: string, frameHex: string): Promise<string> {
    const frame = dehex(frameHex)
    if (!frame || frame.length <= IV_BYTES) throw 'unseal: frame too short'
    const iv = frame.slice(0, IV_BYTES)
    const ct = frame.slice(IV_BYTES)
    const key = await seal_key(ikm, salt)
    // crypto.subtle.decrypt rejects (does not resolve) on a bad tag — the fails-closed guarantee.
    const plain = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, ct)
    return dec(plain)
}
