// charter_verify.ts — standalone proof of the Charter crypto semantics (Division_todo step 2),
//  independent of the Story machinery: replicates Swarm_charter_payload/parse/sign/verify/Charter_addr/
//   absorb in plain TS against the REAL signHeader/verifyHeader, and asserts the teeth.
//  run: node_modules/.bin/vite-node -c scripts/compile.vite.config.ts scratchpad/charter_verify.ts
import { signHeader, verifyHeader } from '../src/lib/p2p/cluster_trust'
import * as ed from '@noble/ed25519'

const enhex = (b: Uint8Array) => Array.from(b).map(x => x.toString(16).padStart(2, '0')).join('')

// mirror Swarm_charter_payload / parse
const payload_of = (roster: any[]) =>
    roster.map(e => `${e.pub}:${e.role}:${e.address}`).sort().join(';')
const parse = (p: string) => p.split(';').filter(Boolean).map(seg => {
    const b = seg.split(':'); return { pub: b[0], role: b[1], address: b.slice(2).join(':') }
})
// mirror Swarm_charter_sign (the header + merge)
async function sign(roster: any[], soulKey: string, soulPub: string, era: number) {
    const payload = payload_of(roster)
    const head: any = { era: String(era), payload, soul: soulPub }
    head.sign = await signHeader(head, soulKey)
    return { era: String(era), payload, sig: head.sign, soul: soulPub }
}
// mirror Swarm_charter_verify
async function verify(ch: any, soulPub: string) {
    if (!ch || !ch.sig || ch.payload == null) return false
    const head: any = { era: String(ch.era), payload: String(ch.payload), soul: String(ch.soul || soulPub) }
    head.sign = String(ch.sig)
    const who = await verifyHeader(head, [String(soulPub)])
    return who === String(soulPub)
}
// mirror Charter_addr
function addr(ch: any, role: string, bare: string) {
    if (!ch || ch.payload == null) return null
    const hits = parse(ch.payload).filter(e => e.role === role)
    if (!hits.length) return null
    hits.sort((a, b) => {
        const ap = a.address === bare ? 0 : 1, bp = b.address === bare ? 0 : 1
        if (ap !== bp) return ap - bp
        return a.address < b.address ? -1 : 1
    })
    return hits[0].address
}
// mirror Swarm_charter_absorb (era gate)
async function absorb(pier: any, ch: any, soulPub: string) {
    if (!await verify(ch, soulPub)) return 0
    if (pier.charter && +pier.charter.era >= +ch.era) return 0
    pier.charter = { era: ch.era, payload: ch.payload, sig: ch.sig, soul: ch.soul }
    return 1
}

let pass = 0, fail = 0
const ok = (name: string, cond: boolean) => { if (cond) { pass++ } else { fail++; console.log('  ✗ ' + name) } }

async function main() {
    const priv = ed.utils.randomPrivateKey()
    const soulPub = enhex(await ed.getPublicKeyAsync(priv))
    const soulKey = enhex(priv)
    const bare = soulPub.slice(0, 16)
    const roster1 = [
        { pub: 'capbodypub', role: 'Captain', address: bare },
        { pub: 'cavbodypub', role: 'Cave', address: bare + '_1' },
    ]
    const c1 = await sign(roster1, soulKey, soulPub, 1)

    ok('good verifies', await verify(c1, soulPub) === true)
    ok('Cave routes to _1', addr(c1, 'Cave', bare) === bare + '_1')
    ok('Captain routes to bare', addr(c1, 'Captain', bare) === bare)
    ok('unheld Post → null', addr(c1, 'Nobody', bare) === null)

    // teeth
    const bad_addr = { ...c1, payload: c1.payload.replace(bare + '_1', bare + '_9') }
    const bad_era = { ...c1, era: '99' }
    const bad_soul = { ...c1, soul: 'deadbeefdeadbeef' }
    const wrong_pub = enhex(await ed.getPublicKeyAsync(ed.utils.randomPrivateKey()))
    ok('moved address rejected', await verify(bad_addr, soulPub) === false)
    ok('bumped era rejected', await verify(bad_era, soulPub) === false)
    ok('swapped soul rejected', await verify(bad_soul, soulPub) === false)
    ok('wrong soul pub rejected', await verify(c1, wrong_pub) === false)

    // supersede / stale / forged over a pier
    const pier: any = {}
    ok('absorb era1', await absorb(pier, c1, soulPub) === 1)
    ok('routes off pier @ _1', addr(pier.charter, 'Cave', bare) === bare + '_1')
    const roster2 = [
        { pub: 'capbodypub', role: 'Captain', address: bare },
        { pub: 'cavbodypub', role: 'Cave', address: bare + '_2' },
    ]
    const c2 = await sign(roster2, soulKey, soulPub, 2)
    ok('era2 supersedes', await absorb(pier, c2, soulPub) === 1)
    ok('routes off pier @ _2', addr(pier.charter, 'Cave', bare) === bare + '_2')
    ok('stale era1 ignored', await absorb(pier, c1, soulPub) === 0)
    ok('still @ _2 after stale', addr(pier.charter, 'Cave', bare) === bare + '_2')
    const forged = { ...c2, era: '9', payload: c2.payload.replace(bare + '_2', bare + '_7') }
    ok('forged refused at absorb', await absorb(pier, forged, soulPub) === 0)

    // multi-Cave deterministic pick (bare-first then asc)
    const c3 = await sign([
        { pub: 'p1', role: 'Cave', address: bare + '_3' },
        { pub: 'p2', role: 'Cave', address: bare + '_1' },
    ], soulKey, soulPub, 3)
    ok('multi-Cave picks lowest suffix', addr(c3, 'Cave', bare) === bare + '_1')

    console.log(`\ncharter_verify: ${pass}/${pass + fail} passed` + (fail ? `  (${fail} FAILED)` : ' ✓'))
    if (fail) process.exit(1)
}
main()
