// Node proof for the cluster-trust signing contract (src/lib/p2p/cluster_trust.ts), the
//  authentication the relay's gen_write gate (relay.ts) and the editor/runner/claude clients
//   rely on. No relay, no disk: it exercises the sign→verify roundtrip and every fail-closed
//    path a forged gen_write would take. Mirrors the signed-frame shape in
//     src/lib/O/spec/ClusterTrust_handover.md. Run:
//        npx vite-node -c scripts/compile.vite.config.ts scripts/cluster-trust-test.ts
//  Exits 0 on PASS, 1 on FAIL.
import * as ed from '@noble/ed25519'
import { createHash } from 'node:crypto'
import { signHeader, verifyHeader, loadTrustedPubs, prepubOf } from '../src/lib/p2p/cluster_trust'

const enhex = ed.etc.bytesToHex
let failures = 0
function check(name: string, ok: boolean) {
	console.log(`${ok ? '  ✓' : '  ✗ FAIL'}  ${name}`)
	if (!ok) failures++
}
const sha256 = (s: string) => createHash('sha256').update(s).digest('hex')

async function mint() {
	const priv = ed.utils.randomPrivateKey()
	const pub = await ed.getPublicKeyAsync(priv)
	return { privHex: enhex(priv), pubHex: enhex(pub) }
}

async function main() {
	// The cluster's trusted signer (e.g. the claude role) and a foreign key not in the flock.
	const claude = await mint()
	const foreign = await mint()
	const trusted = [claude.pubHex]

	const body = 'export const x = 1 // a compiled .go'
	// The signed unit: the gen_write header, body committed via a CRYPTOGRAPHIC sha256 (NOT the
	//  spine's collidable FNV — a signature over FNV would be forgeable).
	const header: Record<string, unknown> = {
		control: 'gen_write', path: 'gen/N/Foo.go', from: prepubOf(claude.pubHex), body_hash: sha256(body),
	}
	const sign = await signHeader(header, claude.privHex)

	// 1. A frame signed by a trusted key verifies, and names the signer.
	const signer = await verifyHeader({ ...header, sign }, trusted)
	check('trusted signature verifies', signer === claude.pubHex)
	check('verifier names the signer (for authorise-by-identity)', signer != null && prepubOf(signer) === header.from)

	// 2. A tampered header (path changed after signing) fails — the sign no longer matches.
	const tampered = await verifyHeader({ ...header, path: 'gen/N/Evil.go', sign }, trusted)
	check('tampered header rejected (path swapped post-sign)', tampered === null)

	// 3. A tampered body shows as a body_hash mismatch the relay re-checks (sha256(body) ≠ signed hash).
	check('tampered body caught by body_hash recheck', sha256(body + ' evil') !== header.body_hash)

	// 4. A foreign key's signature (valid sig, untrusted key) is dropped.
	const foreignSign = await signHeader(header, foreign.privHex)
	const foreignTry = await verifyHeader({ ...header, sign: foreignSign }, trusted)
	check('foreign signer rejected (valid sig, untrusted key)', foreignTry === null)

	// 5. An unsigned frame is dropped.
	const unsigned = await verifyHeader({ ...header }, trusted)
	check('unsigned frame rejected', unsigned === null)

	// 6. Fail-closed: an empty trusted set trusts nothing (never "trust everything").
	const noTrust = await verifyHeader({ ...header, sign }, [])
	check('empty trusted set is fail-closed', noTrust === null)

	// 7. loadTrustedPubs parses CLUSTER_TRUSTED_PUBS (comma list), empty when unset.
	check('loadTrustedPubs empty when unset', loadTrustedPubs({}).length === 0)
	check('loadTrustedPubs parses the flock', loadTrustedPubs({ CLUSTER_TRUSTED_PUBS: `${claude.pubHex}, ${foreign.pubHex}` }).length === 2)

	console.log(failures ? `\nFAIL — ${failures} check(s) failed` : '\nPASS — cluster-trust signing contract holds')
	process.exit(failures ? 1 : 0)
}

main().catch((e) => { console.error('cluster-trust-test threw:', e); process.exit(1) })
