// TwoFounder (2026-09-01, reworked 2026-09-02 for land-of-prepub/Phase D) — the two-founder
//  convergence gate the Books lack. Two identities of ONE soul (same soul keys, distinct body keys),
//   each deriving self+sibling as Captain founders, running the real gen/S/Swarm.go family_heal on
//    hand-built C particles. THE OLD WAR (dual-bare seats + era climb) cannot form anymore: a body IS
//     its own address (prepubOf(pub)) and the heal writes NO address column and signs NO charter —
//      this spec asserts exactly that: identical pub:role rosters on both tabs, zero address columns,
//       zero %Charter rows minted by the heal. Not a Book (no Plan/toc/fixture); direct-mount gate.
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/TwoFounder.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Swarm from '../src/lib/gen/S/Swarm.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

async function stub_house() {
	const H: any = new TheC({ c: {}, sc: { H: 'Mundo' } })
	H.eatfunc = async (obj: any) => { Object.assign(H, obj) }
	H.top_House = () => H
	H.mainkey = (n: any) => Object.keys(n.sc)[0]
	H.c.consenter = 1
	mount(Swarm, { target: document.body, props: { H } })
	for (let i = 0; i < 120 && !(typeof H.Swarm_family_heal === 'function'
		&& typeof H.Swarm_mint_keys === 'function'
		&& typeof H.Swarm_charter_wire === 'function'
		&& typeof H.Swarm_charter_absorb === 'function'); i++) await sleep(25)
	return H
}

function plantGrant(H: any, ident: any, forPub: string, feature: string, soulPub: string, friendly: string) {
	const peering = H.Swarm_peering(ident)
	const pier = peering.i({ Pier: 1, pub: forPub, friendly })
	pier.c.up = peering
	const page = pier.i({ Peering: 1, pub: forPub })
	page.c.up = pier
	const g = pier.i({ Grant: feature, by: soulPub, for: forPub })
	g.c.up = pier
	return pier
}

function roster(H: any, ident: any) {
	// pub:role only — the instance NAME is per-view (each tab labels a member by its own pier
	//  friendly until the roster mile syncs names), so it is not part of the convergence identity.
	return H.Swarm_body_roster(ident).map((b: any) => `${String(b.sc.pub).slice(0, 8)}:${b.sc.post}`).sort().join(' | ')
}
function payloadOf(H: any, ident: any) {
	const ch = H.Swarm_peering(ident).o({ Charter: 1 })[0]
	return ch ? { era: ch.sc.era, payload: ch.sc.payload } : { era: '-', payload: '-' }
}

test('two same-soul founders — observe war vs convergence', async () => {
	const H = await stub_house()
	expect(typeof H.Swarm_family_heal).toBe('function')

	const world: any = H.i({ A: 'Test' }).i({ w: 'Test' })
	world.c.up = H

	// ONE soul, two body keys
	const soul = await H.Swarm_mint_keys('TwoFounder-soul')
	const soulPub = String(soul.pub)
	const soulBare = String(soul.prepub)
	console.log('soul prepub=', soulBare, ' pub[:8]=', soulPub.slice(0, 8), ' prefix-ok=', soulPub.startsWith(soulBare))

	const acctA = world.i({ Account: 1, of: 'BodyA' }); acctA.c.up = world
	const A = H.Swarm_identity(acctA, { pub: soul.pub, key: soul.key, prepub: soul.prepub }, 'Grav')
	A.c.bodykey = await H.Swarm_mint_keys('TwoFounder-A-body')
	const acctB = world.i({ Account: 1, of: 'BodyB' }); acctB.c.up = world
	const B = H.Swarm_identity(acctB, { pub: soul.pub, key: soul.key, prepub: soul.prepub }, 'Gurn')
	B.c.bodykey = await H.Swarm_mint_keys('TwoFounder-B-body')

	const Apub = String(A.c.bodykey.pub)
	const Bpub = String(B.c.bodykey.pub)
	console.log('A body[:8]=', Apub.slice(0, 8), ' B body[:8]=', Bpub.slice(0, 8), ' A<B=', Apub < Bpub)

	// each derives BOTH itself (husk) and its sibling (member) as a Captain founder (full gossip simulated)
	plantGrant(H, A, Apub, 'MyCaptain', soulPub, 'selfA')
	plantGrant(H, A, Bpub, 'MyCaptain', soulPub, 'sibB')
	plantGrant(H, B, Bpub, 'MyCaptain', soulPub, 'selfB')
	plantGrant(H, B, Apub, 'MyCaptain', soulPub, 'sibA')

	console.log('derive A:', JSON.stringify(H.Swarm_family_derive(A).map((f: any) => ({ pub: String(f.pub).slice(0, 8), role: f.role, husk: f.husk }))))
	console.log('derive B:', JSON.stringify(H.Swarm_family_derive(B).map((f: any) => ({ pub: String(f.pub).slice(0, 8), role: f.role, husk: f.husk }))))

	for (let round = 1; round <= 3; round++) {
		await H.Swarm_family_heal(world, A)
		await H.Swarm_family_heal(world, B)
		const rA = roster(H, A), rB = roster(H, B)
		const chA = H.Swarm_peering(A).o({ Charter: 1 }).length
		const chB = H.Swarm_peering(B).o({ Charter: 1 }).length
		console.log(`round ${round}: A[${rA}] B[${rB}] charters=${chA}/${chB} identical=${rA === rB}`)
		// CONVERGENCE (land-of-prepub): both tabs derive the SAME pub:role roster — no seat map, no
		//  cross-absorb needed; the shared truth is the keys themselves.
		expect(rA, `round ${round}: identical rosters with no negotiation`).toBe(rB)
		// NO ADDRESS COLUMN: a body IS its own address; the heal scrubs the furniture.
		for (const b of H.Swarm_body_roster(A).concat(H.Swarm_body_roster(B))) {
			expect(b.sc.address, `round ${round}: no address column survives`).toBeUndefined()
		}
		// NO CHARTER: the heal signs nothing (the roster mile replaced the weld; membership = the key).
		expect(chA + chB, `round ${round}: the heal mints no %Charter`).toBe(0)
	}
})
