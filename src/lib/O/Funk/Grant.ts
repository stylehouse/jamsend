// Grant — a durable, self-contained capability atom for the cluster's new end.
//
//  Modelled on Peerily's trust molecules (grant_trust / verify_trust / say_trust in
//   Peerily.svelte.ts — out of bounds, so REPLICATED here, not reached into).  Peerily's
//    trusticle derives grantor|grantee from a live Pier's context; a %Grant can't, because
//     it is a LEAVE-AROUND atom — a particle sitting in a runner's Waft:Cluster, verifiable
//      off any connection.  So it carries its own grantor (`by`) and grantee (`for`) INSIDE
//       the signed domain: tamper-evident end to end, stronger than the Pier-context form.
//
//  The two operations the design names:
//    swap-IN  (verify_grant): rebuild the signed claim, check `by`'s signature over it.
//                              Peerily's grantor|grantee pubkey swap does exactly this in-Pier.
//    swap-OUT (grant_to_C / grant_of_C): externalise the atom as a %Grant C-particle you can
//                              leave around, and read it back.  This is the NEW half.
//
//  No `until`.  Grants are infinite by design: popularising click-to-renew trains an operator
//   to rubber-stamp grants (more insecure, and more snap/operator noise) than leaving a standing
//    grant in place.  The inverse of a grant is a signed REVOCATION (%NotGrant), not an expiry —
//     and a revocation needs a corpus to version against so a verifier can be lazy about finding
//      the latest safety state.  That corpus is a TODO (Cluster_spec); mint_revoke is the seed.
//
//  Crypto is Idento (ed25519, $lib/Y.svelte) — the same primitive Peerily signs trust with — and
//   the signed domain is sorted-key JSON, mirroring cluster_trust.ts's canonicalHeader so a claim
//    rebuilt from a particle (whose sc key order may differ) serialises identically to the mint.

import { Idento, type Pubkey, type Sighex } from '$lib/Y.svelte'
import type { TheC } from '$lib/data/Stuff.svelte'

export type TrustName = string            // the ability, e.g. 'remoteWormhole'

// the signed core — `by`/`for` ride inside it (self-contained).  All fields are STRINGS so an
//  atom survives a round-trip through a particle's sc (string-only) byte-for-byte: a number
//   would re-serialise differently (JSON 123 ≠ "123") and break the signature.  `opt` (e.g.
//    mode:'rw') folds in as extra string keys.
export type GrantClaim = {
    to: TrustName                         // ability granted (rides as the %Grant mainkey value)
    by: Pubkey                            // grantor (the signer)
    for: Pubkey                           // grantee (the bearer)
    time: string                          // issued-at, seconds, as a string
    [k: string]: string                   // opt scope keys (mode, …)
}
export type GrantAtom = GrantClaim & { sign: Sighex }

// %NotGrant — a signed revocation.  Same machinery, `not` in place of `to`.
export type RevokeClaim = { not: TrustName, by: Pubkey, for: Pubkey, time: string, [k: string]: string }
export type RevokeAtom  = RevokeClaim & { sign: Sighex }

const now_s = () => Math.floor(Date.now() / 1000)

// the signature domain: every key but `sign`, sorted, values forced to string.  Identical
//  inputs → identical bytes regardless of property order or number-vs-string drift.
function claim_json(atom: Record<string, unknown>): string {
    const { sign: _drop, ...rest } = atom as Record<string, unknown>
    const sorted: Record<string, string> = {}
    for (const k of Object.keys(rest).sort()) sorted[k] = String(rest[k])
    return JSON.stringify(sorted)
}

// ── mint (the grantor signs) ───────────────────────────────────────────────────────────────
//  grantor is the editor's cluster idento {pub, key}; granteePub the runner's full pub.  opt
//   folds extra scope (mode:'rw').  time is injectable for determinism in tests.
export async function mint_grant(
    grantor: { pub: string; key: string }, granteePub: Pubkey, to: TrustName,
    opt: Record<string, string> = {}, time: number = now_s(),
): Promise<GrantAtom> {
    if (!grantor?.key) throw 'mint_grant: grantor has no private key'
    const id = new Idento(); id.thaw(grantor)
    const claim: GrantClaim = { to, by: grantor.pub, for: granteePub, time: String(time), ...opt }
    const sign = await id.sig(claim_json(claim))
    return { ...claim, sign }
}

// ── verify (swap-in) ───────────────────────────────────────────────────────────────────────
//  rebuild the signed claim, check `by`'s signature.  Returns the claim on success; THROWS on a
//   bad/forged atom so the caller maps the failure to w:Wormhole/%error.  A verifier still has to
//    decide it TRUSTS `by` to issue this `to` (for the Wormhole: by === the editor's own pub).
export async function verify_grant(atom: GrantAtom): Promise<GrantClaim> {
    if (!atom?.sign) throw 'verify_grant: unsigned'
    if (!atom.by) throw 'verify_grant: no grantor'
    const ok = await new Idento().from_hex(atom.by).ver(atom.sign, claim_json(atom))
    if (!ok) throw `verify_grant: bad signature to:${atom.to} by:${atom.by.slice(0, 16)}`
    const { sign: _s, ...claim } = atom
    return claim as GrantClaim
}

// ── swap-OUT: the atom ⇄ a %Grant C-particle (the leave-around form) ─────────────────────────
//  mainkey Grant carries the ability (sc.Grant === to, like req:<Name>); by/for/time/sign + any
//   opt ride as scalar sc keys — all strings, all snap-clean.  i() so the create is tracked.
const GRANT_FIXED = ['to', 'by', 'for', 'time', 'sign']
export function grant_to_C(container: TheC, atom: GrantAtom): TheC {
    const sc: Record<string, string> = { Grant: atom.to, by: atom.by, for: atom.for, time: atom.time, sign: atom.sign }
    for (const [k, v] of Object.entries(atom)) if (!GRANT_FIXED.includes(k)) sc[k] = v as string
    return (container as any).i(sc)
}
// swap-IN read-back: a %Grant particle → the atom (mainkey value → to).
export function grant_of_C(n: TheC): GrantAtom {
    const sc = (n as any).sc as Record<string, string>
    const atom: Record<string, string> = { to: sc.Grant, by: sc.by, for: sc.for, time: sc.time, sign: sc.sign }
    for (const [k, v] of Object.entries(sc)) if (k !== 'Grant' && !GRANT_FIXED.includes(k)) atom[k] = v
    return atom as GrantAtom
}
// convenience: verify a %Grant particle in one call.
export const verify_C = (n: TheC): Promise<GrantClaim> => verify_grant(grant_of_C(n))

// ── revocation (the inverse; no expiry means this is the only way to end a grant) ────────────
//  Seed only — the standing-revocation CORPUS (versioned, fetch-latest) is the TODO that makes
//   a verifier able to be lazy about freshness.  Same sign/verify path as a grant.
export async function mint_revoke(
    grantor: { pub: string; key: string }, granteePub: Pubkey, not: TrustName,
    opt: Record<string, string> = {}, time: number = now_s(),
): Promise<RevokeAtom> {
    if (!grantor?.key) throw 'mint_revoke: grantor has no private key'
    const id = new Idento(); id.thaw(grantor)
    const claim: RevokeClaim = { not, by: grantor.pub, for: granteePub, time: String(time), ...opt }
    const sign = await id.sig(claim_json(claim))
    return { ...claim, sign }
}
export async function verify_revoke(atom: RevokeAtom): Promise<RevokeClaim> {
    if (!atom?.sign || !atom.by) throw 'verify_revoke: unsigned'
    const ok = await new Idento().from_hex(atom.by).ver(atom.sign, claim_json(atom))
    if (!ok) throw `verify_revoke: bad signature not:${atom.not} by:${atom.by.slice(0, 16)}`
    const { sign: _s, ...claim } = atom
    return claim as RevokeClaim
}
