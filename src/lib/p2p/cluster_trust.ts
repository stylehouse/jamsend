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

// Mint a fresh random cluster keypair (hex), the same shape gen-cluster-identos.ts writes. Browser-safe
//  (@noble is isomorphic; randomPrivateKey uses webcrypto getRandomValues). Used by the editor's
//   in-app cluster-setup to generate the claude CLI key without a node round-trip.
export async function mintClusterKey(): Promise<{ pub: string; key: string }> {
	const priv = ed.utils.randomPrivateKey()
	const pub  = await ed.getPublicKeyAsync(priv)
	return { pub: enhex(pub), key: enhex(priv) }
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
