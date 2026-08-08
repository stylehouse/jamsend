// BigQualand — the common bit under the two Big*land toplevels: /BigWordland (L/, the editor
//  room — Lies+Lang in disguise) and /BigSoundland (V/BigSoundland, the music scape — Voronoi stained
//   glass).  The *aufheben* of the two: what they share is lifted out here so each can be its own
//    room over one substrate.
//
//  What they SHARE (this file): the boot.  The SAME machine underneath both — construct H:Mundo,
//   activate a Book under Auto, pump `think` — with the one hard-won OOM trap baked in so neither
//    room re-learns it (never read the $state H inside the construction $effect; compute on a local
//     `h` and assign H once, else the effect self-retriggers, allocating a House per tick → multi-GB).
//   `boot_qualand({book, role})` returns reactive `H` + `houses`; a caller aliases them with
//    `$derived` and the rest of its room reads them unchanged.
//
//  What they DON'T share: the room.  BigWordland floats every H.UI loose (Lies summoned); BigSoundland
//   mounts one Cyto full-bleed.  Those stay in their own files — the aufheben preserves the two
//    rooms, it doesn't collapse them into one.
//
//  What "checks it came up right" (owner): NOT a separate qual Story — the BOOK does it.  Each room
//   boots an Editron-shaped diagnostic Book (Educarium for Word; a Sounditron — "is a track playing?"
//    — for Sound) that LURKS in the background: it probes the real end-user environment and, when the
//     environment falls short (no audio, no peers online, a compile fault), surfaces coherent error
//      messages so a real user becomes a reporting test-probe ("something's wrong — here are the errors
//       — try reloading", which the community can then chew on).  So the `book` param below IS that
//        seam; there is no extra verdict to wire — boot_qualand stands the Book up and the Book, being
//         a Story, watches itself.  (Sound's TWO valid outcomes: a track playing, OR no peers online.)
import { House } from "$lib/O/Housing.svelte"
import { onDestroy } from "svelte"

export type QualandOpts = {
    book: string                       // the Book Auto activates (editor Book, or a music Book)
    // the cluster/identity ROLE of the page.  FOUR values, but they collapse to TWO machine boot_roles:
    //  'word'|'editor' → editor (compile+write, the room); 'sound'|'runner' → runner (run it).  The finer
    //   word|sound is carried as H.c.id_role and drives the auto-assumed identity (a /BigSoundland tab is
    //    always the 'sound' identity, /BigWordland always 'word').  It NEVER reaches the machine, which
    //     only ever sees editor|runner — the whole spine's role checks stay two-valued.
    role: 'editor' | 'runner' | 'word' | 'sound'
}

export type Qualand = {
    readonly H: House                  // H:Mundo, once constructed
    readonly houses: House[]           // H** — the live tree, refreshed as it grows
}

// boot_qualand — MUST be called synchronously from a component's <script> (it registers $effect and
//  onDestroy on the calling component's lifecycle).  Returns getters, not plain values: alias them
//   with `let H = $derived(q.H)` / `let houses = $derived(q.houses)` to keep reactivity across the
//    module boundary — do NOT destructure (that snapshots and goes dead).
export function boot_qualand(opts: QualandOpts): Qualand {
    let H = $state<House>(null!)
    let houses = $state<House[]>([])
    let setup_done = $state(false)

    // construction — mirroring Otro.  The OOM trap: compute on the LOCAL `h`, set every `h.c.*` on it,
    //  assign the $state H exactly once, and NEVER read H in here.
    $effect(() => {
        const h = new House({ name: 'Mundo' })
        h.c.toplevel  = 'Auto'         // the Library/Story owner activates the Book
        h.c.book      = opts.book
        // the machine only knows editor|runner; word→editor, sound→runner.  The finer role rides id_role
        //  for the identity layer, and assume_identity tells Auto this page always mints/resumes one.
        h.c.boot_role = (opts.role === 'sound' || opts.role === 'runner') ? 'runner' : 'editor'
        ;(h.c as any).id_role = opts.role
        // Lies%humdinger — a Big*land room is an END-USER page, never a dispatch target.  It's machine-role
        //  runner (sound) or editor (word) and uses the full Lies stack, but must stay invisible to the
        //   editor's grid: no advertise, no going-cold, and no `from` on its pings (else Lies_pong would
        //    enroll it as a runner off the 5s heartbeat and Story runs would land on someone's music page).
        //     Derived from role here so no call site can forget it; the guards live in Lies_humdinger.
        if (opts.role === 'word' || opts.role === 'sound') (h.c as any).humdinger = true
        // H.c.production — THE DEPLOYMENT STANCE, stamped once beside humdinger so every ghost can read it
        //  (a .g cannot see import.meta, and location is not a thing a model layer should be sniffing).
        //   The owner, 2026-08-08: "in production we want no participation in any Cluster beyond sending to
        //    their peers via relay."  So this is the flag that says: music over the relay, and nothing else —
        //     no presence beacon, no roster row, no grant, no dispatch, no compile.
        //  FAIL CLOSED, and that is the whole design: a tab is non-production ONLY when it is a DEV BUILD
        //   AND not on a known production host.  Every other combination — a production build anywhere, a
        //    dev build served from jamsend.*, an unrecognised host on a prod bundle — reads production.  The
        //     cost of a false "dev" is an end-user's music page joining a stranger's cluster; the cost of a
        //      false "production" is that a developer has to notice their diagnostics are off.  Those are not
        //       the same size, so the doubt goes to production.
        //  Host list mirrors `src/lib/ghost/Trust.svelte`'s P.PROD — the existing idiom, kept in step.
        {
            const prod_host = typeof location !== 'undefined'
                && (location.host.startsWith('jamsend.') || location.host.startsWith('voula'))
            ;(h.c as any).production = !(import.meta.env.DEV && !prod_host)
        }
        ;(h.c as any).assume_identity = true
        H = h
        setTimeout(() => { houses = [H] }, 1)
    })

    // once the House has started: begin, pump think, and start tracking the growing H** tree
    $effect(() => {
        if (!H?.started || setup_done) return
        setup_done = true
        H.may_begin()
        setTimeout(() => { houses = H.all_House }, 1)
        H.i_elvisto(H, 'think')
    })
    $effect(() => {
        if (!setup_done) return
        houses = H.all_House
    })

    onDestroy(() => { H?.stop() })

    return {
        get H()      { return H },
        get houses() { return houses },
    }
}
