// Node proof for the CERT-CREW trust token — GRANT-BASED (owner's model, 2026-09-02 night):
//  "the Crew/Pier is ganged with us, has /Grant:Crew from the Captain; those are trusted by others."
//  A Cave holds NO soul key.  Its cert is a `Grant:Crew` the CAPTAIN cross-signed AT THE SEAL (by:soul,
//   for:cave-body-pub) — the exact grant primitive friends already verify.  A Cave's frame is its body-key
//    signature + that grant; a friend runs verify_grant against the soul it sealed to and, finding the
//     grant is BY that soul and FOR this body, trusts the Cave AS the Captain.  Minted at seal ⇒ the Cave
//      holds its cert immediately, so there is no post-ferry sync gap (the old Charter-carry problem).
//  This replicates Swarm_voucher_ok's grant-based cert-crew arm and hammers it with forgeries.  Run:
//   /app/node_modules/.bin/esbuild scripts/crew-cert-test.ts --bundle --platform=node --format=esm \
//      --packages=external --outfile=/app/scratchpad/crew-cert-test.mjs && node /app/scratchpad/crew-cert-test.mjs
import * as ed from '@noble/ed25519'
import { signHeader, verifyHeader, prepubOf } from '../src/lib/p2p/cluster_trust'
// mint_grant/verify_grant live inside Svelte (Idento uses runes), so replicate the SHAPE with the same
//  ed25519 primitive: a grant is a claim {to,by,for,time} signed by `by`.  The REAL verify_grant path is
//   Book-proven in the ghost; this locks the crew-arm LOGIC (issuer + for + body-sig).
async function mint_grant(grantor: any, forpub: string, to: string, _opt: any, time: number) {
	const claim: any = { to, by: grantor.pub, for: forpub, time: String(time) }
	claim.sign = await signHeader({ to: claim.to, by: claim.by, for: claim.for, time: claim.time }, grantor.key)
	return claim
}
async function verify_grant(atom: any) {
	const who = await verifyHeader({ to: atom.to, by: atom.by, for: atom.for, time: atom.time, sign: atom.sign }, [atom.by])
	if (who !== atom.by) throw 'verify_grant: bad signature'
	const { sign, ...claim } = atom
	return claim
}

const enhex = ed.etc.bytesToHex
async function mint() {
	const priv = ed.utils.randomPrivateKey()
	const pub = await ed.getPublicKeyAsync(priv)
	return { key: enhex(priv), pub: enhex(pub), prepub: enhex(pub).slice(0, 16) }
}
let fails = 0
const check = (name: string, ok: boolean) => { console.log(`${ok ? '  ✓' : '  ✗ FAIL'}  ${name}`); if (!ok) fails++ }

// the Cave's crew voucher: body-key-signed flat header + the Captain's Grant:Crew (by:soul, for:cavebody)
async function crew_voucher(cave: any, grant: any) {
	const vh: any = { control: 'crew', from: cave.prepub, pub: cave.pub, era: 1, ts: 1 }
	vh.sign = await signHeader({ control: vh.control, from: vh.from, pub: vh.pub, era: vh.era, ts: vh.ts }, cave.key)
	vh.grant = grant
	return vh
}
// the verifier: the EXACT checks of Swarm_voucher_ok's grant-based cert-crew arm (held = the sealed soul's pub)
async function voucher_ok_crew(vh: any, from: string, held: string) {
	if (!(vh.grant && String(vh.pub) !== String(held))) return 'not-a-crew-voucher'
	if (prepubOf(String(vh.pub)) !== String(from)) return 'crew prepub mismatch'
	let claim: any
	try { claim = await verify_grant(vh.grant) } catch (e) { return 'crew grant bad signature' }
	if (String(claim.by) !== String(held)) return 'crew grant not by the sealed soul'
	if (String(claim.for) !== String(vh.pub)) return 'crew grant not for this body'
	const cbare = { control: vh.control, from: vh.from, pub: vh.pub, era: vh.era, ts: vh.ts, sign: vh.sign }
	if ((await verifyHeader(cbare, [String(vh.pub)])) !== String(vh.pub)) return 'crew body signature bad'
	return 'ACCEPT'
}

async function main() {
	const eed = await mint()        // the Captain (soul) — the friend sealed to THIS pub (held)
	const cave = await mint()       // a real Cave — its own key
	const mallory = await mint()    // attacker
	const held = eed.pub

	console.log('\n— honest path —')
	const grant = await mint_grant({ pub: eed.pub, key: eed.key }, cave.pub, 'Crew' as any, {}, 1)  // by:eed for:cave
	check('captain-signed Grant:Crew verifies', !!(await verify_grant(grant).catch(() => null)))
	const vh = await crew_voucher(cave, grant)
	check('a genuine Cave crew-voucher (grant-carried) is ACCEPTED', (await voucher_ok_crew(vh, cave.prepub, held)) === 'ACCEPT')

	console.log('\n— forgeries, each refused —')
	// (1) grant FOR someone else (mallory presents eed's grant-for-cave, claiming to be cave)
	const vh1: any = { control: 'crew', from: cave.prepub, pub: mallory.pub, era: 1, ts: 1 }
	vh1.sign = await signHeader({ control: 'crew', from: cave.prepub, pub: mallory.pub, era: 1, ts: 1 }, mallory.key)
	vh1.grant = grant
	check('grant for a different body → refused', (await voucher_ok_crew(vh1, cave.prepub, held)) !== 'ACCEPT')

	// (2) grant by the WRONG captain (mallory mints her own Grant:Crew for the cave)
	const forged = await mint_grant({ pub: mallory.pub, key: mallory.key }, cave.pub, 'Crew' as any, {}, 1)
	const vh2 = await crew_voucher(cave, forged)
	check('grant by a different soul → refused', (await voucher_ok_crew(vh2, cave.prepub, held)) === 'crew grant not by the sealed soul')

	// (3) tampered grant signature
	const vh3 = await crew_voucher(cave, { ...grant, sign: forged.sign })
	check('tampered grant signature → refused', (await voucher_ok_crew(vh3, cave.prepub, held)) === 'crew grant bad signature')

	// (4) tampered body signature (mallory's sig under cave's header)
	const vh4 = await crew_voucher(cave, grant); vh4.sign = vh1.sign
	check('body signature not by the claimed body → refused', (await voucher_ok_crew(vh4, cave.prepub, held)) === 'crew body signature bad')

	// (5) real cave still accepts after all forgeries
	const vh5 = await crew_voucher(cave, grant)
	check('the real cave still accepts (no state bleed)', (await voucher_ok_crew(vh5, cave.prepub, held)) === 'ACCEPT')

	console.log('')
	console.log(fails ? `FAIL — ${fails} check(s) failed` : 'PASS — the grant-based crew cert accepts crew and refuses every forgery')
	process.exit(fails ? 1 : 0)
}
main().catch(e => { console.error(e); process.exit(1) })
