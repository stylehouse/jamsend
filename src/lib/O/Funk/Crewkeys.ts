// Crewkeys — the signing keys as PARTICLES (Crew_todo §4a REFINED, the owner 2026-09-03: "the crap are
//  you using .c for? … everything basically wants to be snappable … the Crew is the distributable, it
//   contains the entire Crew's private keys and roles and grants").  Nothing about a key lives in `.c`
//    any more: an %Identity carries
//
//      Crew,soul:<S.pub>                       the crew's ONE name — what friends dial and grant to
//        Key,pub:<S.pub>,secret:<S.key>        the soul's secret (a scalar hex string — snap-clean)
//        mate:<prepub>,role:Captain,pub:<pub>  the founder: its own key IS the soul
//        mate:<prepub>,role:Cave,pub:<P.pub>   a mate: its OWN key, hellos + signs as P
//          Key,pub:<P.pub>,secret:<P.key>
//          Grant:Crew,by:S.pub,for:P.pub       its cert
//
//  EVERY identity is a crew of one from birth (crew_keys_home at the mint), so there is exactly one
//   place a key can be and one accessor pair to read it.  Which key a body WIELDS is read off its row's
//    role (Swarm_signas): a promoted Cave's row says Captain, so it signs as the soul — no key moves.
//  Shared by Swarm.g (IMPORT) and Auto.svelte's Clustation_concrete, so the boot-time mint and the
//   swarm agree byte for byte.  The Story snap MUNGS `secret` ({"mung":["secret"]}); the `page` export
//    protocol skips %Key and %Crew outright; Cyto skips %Key.
import type { TheC } from '$lib/data/Stuff.svelte'

export type Keypair = { pub: string; key: string }
export type Keyed = Keypair & { prepub: string }

export const prepub_of = (pub: string): string => String(pub || '').slice(0, 16)

const key_of = (k: TheC | undefined): Keypair | null =>
    k && (k as any).sc.pub && (k as any).sc.secret ? { pub: String((k as any).sc.pub), key: String((k as any).sc.secret) } : null

// the identity's /Crew (no mint)
export function crew_of(ident: TheC | null | undefined): TheC | null {
    if (!ident || typeof (ident as any).o !== 'function') return null
    return ((ident as any).o({ Crew: 1 }) as TheC[])[0] ?? null
}

// my row on the ledger — mate:<my prepub>
export function crew_myrow(ident: TheC | null | undefined): TheC | null {
    const crew = crew_of(ident)
    if (!crew) return null
    return ((crew as any).o({ mate: String((ident as any).sc.prepub || '') }) as TheC[])[0] ?? null
}

// crew_keys — MY OWN signing key: the %Key anywhere on /Crew whose pub is mine (prepub match — the
//  Identity tag IS prepub_of(pub)).  Null for a husk (an imported page, a puppet with no key yet).
export function crew_keys(ident: TheC | null | undefined): Keypair | null {
    const crew = crew_of(ident) as any
    if (!crew) return null
    const me = String((ident as any).sc.prepub || '')
    // MY ROW first (mate:<my prepub>): its own Key, or the soul Key when my pub IS the soul — this is
    //  what makes a Book's hand-seeded identity (a prepub that is not pub.slice(0,16)) resolve too.
    const row = crew.o({ mate: me })[0]
    if (row) {
        let k = key_of(row.o({ Key: 1 })[0])
        if (k) return k
        if (row.sc.pub && String(row.sc.pub) === String(crew.sc.soul || '')) { k = key_of(crew.o({ Key: 1, pub: String(row.sc.pub) })[0]); if (k) return k }
    }
    const mine = (k: TheC) => !!((k as any).sc.pub && (k as any).sc.secret && prepub_of(String((k as any).sc.pub)) === me)
    let k = (crew.o({ Key: 1 }) as TheC[]).find(mine)
    if (!k) for (const m of crew.o({ mate: 1 }) as TheC[]) { k = ((m as any).o({ Key: 1 }) as TheC[]).find(mine); if (k) break }
    return key_of(k)
}

// crew_soul — the SOUL's key {pub, key, prepub}: the %Key directly under /Crew matching crew.sc.soul.
//  A crew of one's soul is its own key.  Null when I merely know the soul's pub (a Cave that never got
//   the secret) — crew_soulpub still answers then.
export function crew_soul(ident: TheC | null | undefined): Keyed | null {
    const crew = crew_of(ident)
    if (!crew) return null
    const soul = String((crew as any).sc.soul || '')
    const k = ((crew as any).o({ Key: 1 }) as TheC[]).find((x) => String((x as any).sc.pub) === soul)
    const kp = key_of(k)
    return kp ? { ...kp, prepub: prepub_of(kp.pub) } : null
}

export function crew_soulpub(ident: TheC | null | undefined): string {
    const crew = crew_of(ident)
    return crew ? String((crew as any).sc.soul || '') : ''
}

// crew_keys_home — THE ONE SETTER.  Stand `keys` as this identity's own key on /Crew:
//   · no /Crew yet ⇒ a crew of ONE: Crew,soul:<pub> / Key / mate:<prepub>,role:Captain,pub:<pub>
//   · a /Crew stands whose soul is me ⇒ the soul Key is my key (find-or-create, secret refreshed)
//   · a /Crew stands under ANOTHER soul (I am a mate) ⇒ my Key lives under my row (role kept, Cave if new)
//  Idempotent; returns the %Key.  Peering is minted by the caller BEFORE this so the snap order stays
//   Peering-then-Crew (every fixture renders it so).
export function crew_keys_home(ident: TheC, keys: Keypair & { prepub?: string }): TheC | null {
    if (!ident || !keys || !keys.pub || !keys.key) return null
    const pub = String(keys.pub)
    const secret = String(keys.key)
    const prepub = String(keys.prepub || prepub_of(pub))
    const I = ident as any
    let crew = crew_of(ident) as any
    if (!crew) { crew = I.i({ Crew: 1, soul: pub }); crew.c.up = ident }
    if (!crew.sc.soul) { crew.sc.soul = pub; crew.bump() }
    const soul = String(crew.sc.soul)
    let row = crew.o({ mate: prepub })[0]
    if (!row) { row = crew.i({ mate: prepub, role: soul === pub ? 'Captain' : 'Cave', pub: pub }) }
    else if (String(row.sc.pub || '') !== pub) { row.sc.pub = pub; row.bump() }
    row.c.up = crew
    const home = soul === pub ? crew : row
    let k = home.o({ Key: 1, pub: pub })[0]
    if (!k) { k = home.i({ Key: 1, pub: pub, secret: secret }) }
    else if (String(k.sc.secret || '') !== secret) { k.sc.secret = secret; k.bump() }
    k.c.up = home
    return k as TheC
}

// crew_key_hold — HOLD another key on the ledger (the soul's, or a mate's own): under /Crew when it is
//  the soul, under that mate's row otherwise.  What the ferry merge and the stash rehydrate use.
export function crew_key_hold(ident: TheC, pub: string, secret: string): TheC | null {
    const crew = crew_of(ident) as any
    if (!crew || !pub || !secret) return null
    const soul = String(crew.sc.soul || '')
    let home = crew
    if (String(pub) !== soul) {
        // MY OWN key homes on MY OWN row — named by the identity's prepub, which is not always
        //  prepub_of(pub) (a hand-seeded Book identity). Deriving it from the pub minted a SECOND row and
        //   left crew_keys unable to find my key at all (2026-09-03 review).
        const me = String((ident as any).sc.prepub || '')
        const mine = me && (crew_keys(ident)?.pub === String(pub) || prepub_of(String(pub)) === me)
        const prepub = mine ? me : prepub_of(String(pub))
        let row = crew.o({ mate: prepub })[0]
        if (!row) { row = crew.i({ mate: prepub, role: 'Cave', pub: String(pub) }); row.c.up = crew }
        home = row
    }
    let k = home.o({ Key: 1, pub: String(pub) })[0]
    if (!k) { k = home.i({ Key: 1, pub: String(pub), secret: String(secret) }) }
    else if (String(k.sc.secret || '') !== String(secret)) { k.sc.secret = String(secret); k.bump() }
    k.c.up = home
    return k as TheC
}
