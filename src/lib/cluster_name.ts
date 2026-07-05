// cluster_name — a deterministic, memorable handle for a cluster prepub (the 16-hex routing
//  address).  The cluster network is PRIVATE, so an identity's human face needn't be unique or
//   cryptographic: the prepub stays the real address + verification key everywhere it matters
//    (to:<pub> routing, signing, the %Peering name) and this is purely a label to read in a
//     roster instead of hex.  Because it is a PURE function of the prepub, the same identity
//      always wears the same name, and any peer can name any pub it sees on the grid without the
//       name being stored, advertised, or agreed — nothing to drift or collide-on across the wire.
//   Cosmetic only: never key storage, routing, or trust off the name.  Collisions are possible
//    (1024 combos) and harmless — the prepub disambiguates.
const ADJ = [
    'copper', 'brass', 'tidal', 'coral', 'salt', 'drift', 'reef', 'palm',
    'moon', 'dusk', 'amber', 'indigo', 'jade', 'pearl', 'storm', 'calm',
    'deep', 'azure', 'gilded', 'hollow', 'velvet', 'mellow', 'brave', 'quiet',
    'wild', 'lone', 'swift', 'dawn', 'ember', 'slate', 'cobalt', 'verdant',
]
const NOUN = [
    'otter', 'heron', 'marlin', 'conch', 'mango', 'reef', 'tide', 'gull',
    'ray', 'eel', 'crab', 'drum', 'reed', 'lute', 'fife', 'harp',
    'chord', 'wave', 'dune', 'cove', 'sail', 'mast', 'anchor', 'koi',
    'squid', 'tern', 'moray', 'piano', 'kazoo', 'cicada', 'fern', 'skiff',
]

export function cluster_name(prepub: string | undefined | null): string {
    if (!prepub) return 'unknown'
    // fold every hex digit into two rolling indices so ALL 16 matter — two pubs sharing a
    //  prefix still diverge.  even digits steer the adjective, odd digits the noun.
    let a = 0, n = 0
    for (let i = 0; i < prepub.length; i++) {
        const v = parseInt(prepub[i], 16)
        if (Number.isNaN(v)) continue
        if (i % 2 === 0) a = (a * 16 + v) % ADJ.length
        else             n = (n * 16 + v) % NOUN.length
    }
    return `${ADJ[a]}-${NOUN[n]}`
}
