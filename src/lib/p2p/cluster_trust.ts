// cluster_trust — sign/verify privileged frames against the secret cluster Idento flock.
//
//  The authentication the relay/editor channel lacks today: a privileged frame (gen_write, the
//   incoming dock_push) carries header.sign = ed25519(canonical-header) by a cluster KEY; a verifier
//    checks it against CLUSTER_TRUSTED_PUBS and drops anything unsigned or foreign. This closes the
//     unauthenticated-relay RCE — see scripts/gen-cluster-identos.ts for minting the flock.
//
//  Importable by BOTH node (scripts/, src/lib/server/relay.ts) and the browser app — but only the
//   PUBLIC half (loadTrustedPubs/verifyHeader) is browser-safe. A signer (signHeader) needs a private
//    key, which must stay node-side; never ship CLUSTER_IDENTO_*_KEY to a browser bundle.
import * as ed from '@noble/ed25519'

const enhex = ed.etc.bytesToHex
const dehex = ed.etc.hexToBytes
const enc   = (s: string) => new TextEncoder().encode(s)

// The signed unit is the header MINUS its own sign field, key-sorted so signer and verifier
//  serialise identically regardless of property order. body integrity rides header.body_hash
//   (already wired in the Peeroleum spine), so signing the header covers the body by reference.
export function canonicalHeader(header: Record<string, unknown>): string {
	const { sign: _drop, ...rest } = header as any
	const sorted: Record<string, unknown> = {}
	for (const k of Object.keys(rest).sort()) sorted[k] = rest[k]
	return JSON.stringify(sorted)
}

// The flock's trusted public keys (full 64-hex), from CLUSTER_TRUSTED_PUBS. Empty ⇒ NOT configured:
//  callers must treat an empty set as "trust nothing" (fail closed), never "trust everything".
export function loadTrustedPubs(env: Record<string, string | undefined> = process.env): string[] {
	return (env.CLUSTER_TRUSTED_PUBS ?? '').split(',').map(s => s.trim()).filter(Boolean)
}

// This process's own signing key for a role, or undefined if absent (e.g. a verify-only host).
export function loadRoleKey(role: string, env: Record<string, string | undefined> = process.env): string | undefined {
	return env[`CLUSTER_IDENTO_${role.toUpperCase().replace(/[^A-Z0-9]/g, '_')}_KEY`]
}

// Browser-side counterparts. The browser has no process.env: vite.config bakes the PUBLIC trust
//  anchors via `define`. CRITICAL: the access must be the EXACT literal `import.meta.env.VITE_CLUSTER_*`
//   — a cast or `?.` between the tokens defeats Vite's textual define swap, leaving it undefined at
//    runtime (the bug that silently disabled the no-key warning). Only browser code calls these.
export function browserTrustedPubs(): string[] {
	const raw = import.meta.env.VITE_CLUSTER_TRUSTED_PUBS ?? ''
	return String(raw).split(',').map((s: string) => s.trim()).filter(Boolean)
}
export function browserRole(): string | undefined {
	const r = import.meta.env.VITE_CLUSTER_ROLE
	return r ? String(r) : undefined
}

// pretty_pubkey: the 16-hex routing address (header.from) derived from a full pub. Mirrors Idento.
export const prepubOf = (pubHex: string): string => pubHex.slice(0, 16)

// The cryptographic body commitment for a privileged frame: full sha256 hex over the body STRING.
//  Both signer and verifier (relay) MUST use this. The spine's Peeroleum_body_digest is the same
//   algorithm (sha256) over the raw buffer bytes — they agree in strength now that the spine dropped
//    its forgeable FNV digest, the difference is only the input (string body vs raw Uint8Array buffer),
//     so a header.sign over body_hash genuinely pins the payload. crypto.subtle is present in both the
//      browser and node (global webcrypto), so one impl serves both sides.
export async function sha256hex(data: string): Promise<string> {
	const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(data))
	return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('')
}

// Sign a header with a private key (hex). Returns the hex signature to set as header.sign.
export async function signHeader(header: Record<string, unknown>, privHex: string): Promise<string> {
	const sig = await ed.signAsync(enc(canonicalHeader(header)), dehex(privHex))
	return enhex(sig)
}

// Verify header.sign against the trusted flock. Returns the matching full pubkey when valid (so the
//  caller can log/authorise by identity), or null when unsigned, malformed, or foreign. Fail-closed:
//   an empty trusted set, a missing sign, or a from/prepub that matches no trusted key all → null.
export async function verifyHeader(
	header: Record<string, unknown>,
	trustedPubs: string[],
): Promise<string | null> {
	const sign = (header as any).sign
	if (typeof sign !== 'string' || !sign || !trustedPubs.length) return null
	const from = (header as any).from
	// Prefer the pub whose prepub matches header.from (the claimed signer); fall back to trying all
	//  so a frame that omits/garbles `from` still can't pass on a key it wasn't signed by.
	const ordered = typeof from === 'string'
		? [...trustedPubs.filter(p => prepubOf(p) === from), ...trustedPubs.filter(p => prepubOf(p) !== from)]
		: trustedPubs
	const msg = enc(canonicalHeader(header))
	let sig: Uint8Array
	try { sig = dehex(sign) } catch { return null }
	for (const pub of ordered) {
		try { if (await ed.verifyAsync(sig, msg, dehex(pub))) return pub } catch { /* try next */ }
	}
	return null
}

// ── Capability certificates (Cluster_spec §2.8) — the APP-LEVEL trust layer, distinct from the
//  frame-signing above. Frame-signing answers *who sent this frame*; a capability cert answers
//   *what an Id may DO* — run code, restart a host service, honour a `%Rungo`. A single TYRANT
//    pubkey is the root of trust; it signs a cert delegating capabilities to a grantee pub. Any peer
//     resolves a cert OFFLINE against the baked tyrant pub — no network, no relay enforcement. This
//      is NOT a new privileged frame: a cert rides opaque in app-level payload (a `%Trust` particle,
//       a field on the hello) and is checked by the app/runner layer, never by the spine or relay.
//        The flat CLUSTER_TRUSTED_PUBS set above is the degenerate, one-level form of this chain.
//
//  Shallow by design ("probably just for the one other"): one hop, tyrant → grantee, not a deep PKI.
//   The cert is plain JSON; cert.sign = ed25519(canonicalCert) by the tyrant key. canonicalCert
//    drops `sign` and key-sorts, exactly like canonicalHeader, so signer and verifier serialise alike.
export type Capability = 'run-code' | 'restart' | 'allocate' | string

export interface TrustCert {
	grantee: string      // full 64-hex pub the capabilities are delegated TO
	can: Capability[]    // the capabilities granted (a member '*' is a wildcard — grants anything)
	not_after?: number   // optional epoch-ms expiry; absent ⇒ never expires (a long-lived flock cert)
	issued?: number      // optional epoch-ms issue time (informational; minting stamps it)
	note?: string        // optional human label (informational, not part of the trust decision)
	sign?: string        // ed25519(canonicalCert) by the tyrant key
}

// The signed unit of a cert — the cert MINUS its own sign, key-sorted (mirrors canonicalHeader).
export function canonicalCert(cert: Record<string, unknown>): string {
	const { sign: _drop, ...rest } = cert as any
	const sorted: Record<string, unknown> = {}
	for (const k of Object.keys(rest).sort()) sorted[k] = rest[k]
	return JSON.stringify(sorted)
}

// Mint (sign) a cert with the TYRANT's private key. Node-side only — the tyrant key never ships to a
//  browser. Stamps `issued` if absent. Returns the cert with `sign` set. The tyrant is contacted
//   only to MINT (here); checking (verifyCert/resolveCapability) is offline against the public root.
export async function mintCert(
	cert: Omit<TrustCert, 'sign'>,
	tyrantPrivHex: string,
	now = 0,
): Promise<TrustCert> {
	const body: TrustCert = { ...cert, issued: cert.issued ?? now }
	const sign = enhex(await ed.signAsync(enc(canonicalCert(body)), dehex(tyrantPrivHex)))
	return { ...body, sign }
}

// Verify a cert against the tyrant root pub. Fail-closed: false on a missing/garbled sign, a sign by
//  the wrong key, an empty tyrant pub, or an expired cert (now > not_after). `now` is passed in
//   (epoch-ms) so the caller owns the clock — a test pins it, app code passes Date.now().
export async function verifyCert(
	cert: TrustCert | null | undefined,
	tyrantPub: string,
	now: number,
): Promise<boolean> {
	if (!cert || typeof cert.sign !== 'string' || !cert.sign || !tyrantPub) return false
	if (typeof cert.not_after === 'number' && now > cert.not_after) return false
	let sig: Uint8Array
	try { sig = dehex(cert.sign) } catch { return false }
	try { return await ed.verifyAsync(sig, enc(canonicalCert(cert)), dehex(tyrantPub)) }
	catch { return false }
}

// Does `grantee` hold `capability`, proven by a cert in `certs` rooted at the tyrant? Resolves the
//  SHALLOW chain (one hop): a cert whose grantee matches, whose `can` includes the capability (or the
//   wildcard '*'), tyrant-signed and unexpired. Fail-closed: no matching valid cert ⇒ false. `grantee`
//    may be a full pub or its prepub (16-hex routing addr) — we accept either, so a frame's `from`
//     (a prepub) resolves against a cert that names the full pub.
export async function resolveCapability(
	grantee: string,
	capability: Capability,
	certs: TrustCert[],
	tyrantPub: string,
	now: number,
): Promise<boolean> {
	if (!grantee || !tyrantPub || !Array.isArray(certs)) return false
	for (const cert of certs) {
		if (!cert || typeof cert.grantee !== 'string') continue
		if (cert.grantee !== grantee && prepubOf(cert.grantee) !== grantee) continue
		if (!Array.isArray(cert.can) || !(cert.can.includes(capability) || cert.can.includes('*'))) continue
		if (await verifyCert(cert, tyrantPub, now)) return true
	}
	return false
}

// The tyrant root pub — node-side (CLUSTER_TYRANT_PUB) and browser-side (VITE_CLUSTER_TYRANT_PUB,
//  baked by vite.config like the trusted-pubs anchor). Empty ⇒ no tyrant configured: callers MUST
//   fail closed (deny every capability), never "allow everything". Mirrors loadTrustedPubs's posture.
export function loadTyrantPub(env: Record<string, string | undefined> = process.env): string {
	return (env.CLUSTER_TYRANT_PUB ?? '').trim()
}
export function browserTyrantPub(): string {
	const raw = import.meta.env.VITE_CLUSTER_TYRANT_PUB ?? ''
	return String(raw).trim()
}
