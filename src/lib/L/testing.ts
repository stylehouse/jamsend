// testing.ts — WHICH DOCS ARE TESTING CODE, decided in exactly one place.
//
//  The owner, 2026-09-09: *"I want a clearer separation of the test codes… rename Voronation.g to
//   VoroTesting.g, and we should pattern match the Testing in results and style|organise them all
//    slightly differently… so we're exposing all these places where societies of language interact."*
//
//  That last clause is the reason this file exists rather than a regex pasted into three faces.  A
//   Testing doc is where one society of language (the Book dialect — beats, swears, snaps, fixtures)
//    speaks to another (a ghost's own verbs).  Marking it is not cosmetics; it is exposing a BORDER,
//     and a border drawn differently in each face is no border.  So: one predicate, imported by Atlas
//      (which KEEPS it — `%Doc,testing` in the census, filterable), by the two faces (which STYLE it),
//       and copied verbatim into runner_ask.mjs (which cannot import a $lib module).
//
//  The convention is `<Name>Testing.g` — it replaces `<Name>ation.g` (Voronation, Swarmation,
//   Atlantation…), which said the same thing in a way nothing could pattern-match without a list.
//    All thirteen were renamed 2026-09-09 (the L three, the Ghost/Story eight, Vyto's).  The old name
//     is NOT matched here on purpose: a new recipe that forgets the suffix should stay unstyled until
//      it is named, rather than pass on a spelling nothing else recognises.
//  Two names were judgment calls, not derivations — say so if they are wrong: `Peregrination.g →
//   PeerTesting.g` (the p2p Books) and `Radiation.g → RaTesting.g` (the Ra* product Books).  Book NAMES
//    (`Siphonation`, `Radiation`, fixtures under wormhole/Story/) did not move; a Book is its do_fn.
export const TESTING_RE = /Testing\.g$/

export function is_testing(path: string | null | undefined): boolean {
    return TESTING_RE.test(path ?? '')
}
