// door_census — WHO THE MEMBERSHIP DOOR KEEPS, read off a LIVE host, with no browser.
//
//  The door (`Swarm_peers` / `Swarm_pier_retired`, Ghost/S/Swarm.g) decides which peers the rest of the
//   app can see. Its unit gate is `scripts/MembershipDoor.spec.ts`; this is the other half — pointing the
//    same rule at REAL rows on a running host, because the shapes that matter (a Music revoke beside a
//     live Crew grant, a chrysalis link stamp, a nascent pier mid-seal) are ones a fixture only imitates.
//
//  It re-states the rule rather than importing the ghost on purpose: a second, independent reading is
//   what makes a disagreement meaningful. If this and the ghost ever differ on a real pier, ONE OF THEM IS
//    WRONG and that is exactly the thing worth finding. (Keep the two in step by hand; the rule is six
//     lines and it is written out below.)
//
//   node scripts/door_census.mjs                       # the local jamserve daemon
//   node scripts/door_census.mjs http://host:9099 tok  # any host exposing /c
//
//  Reads only. Never writes, never mints, never asks a peer anything.
const BASE = process.argv[2] || 'http://172.17.0.1:9099'
const TOKEN = process.argv[3] || 'sheeps'

// THE RULE, restated (Social_demarcation_todo §2.0). Retirement is decided on POSITIVE EVIDENCE — a
//  %NotGrant standing, or a link stamp unlinked — never on the mere absence of a grant, because a pier
//   with no grants is usually NASCENT (mid-seal) and still needs its route.
const liveFeature = (p, feature) => {
    const grants = p.grants.filter((g) => g.feature === feature)
    if (!grants.length) return false
    return !p.nots.some((n) => n.feature === feature
        && grants.some((g) => n.by === g.by && n.for === g.for))
}
const linklive = (p) => (p.link && !p.unlinked && !p.nots.some((n) => n.feature === 'MyCave' || n.feature === 'MyCaptain'))
    || liveFeature(p, 'MyCave') || liveFeature(p, 'MyCaptain')
const retired = (p) => {
    if (p.link && p.unlinked) return true
    if (!p.nots.length) return false                       // nascent or plainly live — not retired
    if (liveFeature(p, 'Music')) return false
    if (liveFeature(p, 'Crew')) return false
    if (linklive(p)) return false
    return true
}

const walk = (n, path, fn) => {
    fn(n, path)
    for (const k of n.kids || []) walk(k, path + '>' + (Object.keys(k.sc || {})[0] || '?'), fn)
}

const main = async () => {
    const url = `${BASE}/c?token=${encodeURIComponent(TOKEN)}&depth=9`
    let tree
    try { tree = await (await fetch(url)).json() }
    catch (e) { console.error(`✗ could not read ${BASE}/c — ${e.message}`); process.exit(2) }

    const piers = []
    walk(tree, '', (n, path) => {
        const sc = n.sc || {}
        if (!sc.Pier || !path.includes('Identity')) return       // the durable roster, not a transport route
        const kids = n.kids || []
        piers.push({
            pub: String(sc.pub || ''),
            friendly: String(sc.friendly || ''),
            since: sc.since ? String(sc.since) : '',
            link: !!sc.link,
            unlinked: !!sc.unlinked,
            grants: kids.filter((k) => k.sc.Grant).map((k) => ({ feature: k.sc.Grant, by: k.sc.by, for: k.sc.for })),
            nots: kids.filter((k) => k.sc.NotGrant).map((k) => ({ feature: k.sc.NotGrant, by: k.sc.by, for: k.sc.for })),
        })
    })

    if (!piers.length) { console.log(`no %Pier rows under any Identity at ${BASE} — nothing to census`); return }

    let kept = 0
    console.log(`\nthe membership door at ${BASE} — ${piers.length} pier(s)\n`)
    for (const p of piers) {
        const gone = retired(p)
        if (!gone) kept += 1
        const feats = ['Music', 'Crew', 'MyCave', 'MyCaptain'].filter((f) => liveFeature(p, f))
        const revoked = [...new Set(p.nots.map((n) => n.feature))]
        // WHY, not just WHETHER — a verdict you cannot audit is the thing this whole repair was against.
        const why = gone
            ? (p.link && p.unlinked ? 'link unbonded' : `revoked ${revoked.join('+')} and nothing else stands`)
            : (feats.length ? `live: ${feats.join(', ')}` : 'nascent — no revocation on record, still becoming')
        console.log(`  ${gone ? '✕ retired' : '✓ kept   '}  ${p.pub.slice(0, 8)}  ${(p.friendly || '—').padEnd(10)}  ${why}`
            + (revoked.length && !gone ? `   (revoked: ${revoked.join('+')})` : ''))
    }
    console.log(`\n  ${kept} kept · ${piers.length - kept} retired`)
    console.log(`  default Swarm_peers(ident) returns the kept; {live:'Music'} narrows further; {live:'all'} is the ledger.\n`)
}
main()
