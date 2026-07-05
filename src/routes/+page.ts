// The bare root / deliberately 404s for now.  BigSoundland (the music scape) moved to its
//  explicit /BigSoundland route — symmetric with /BigWordland (the editor room) and /Otro
//   (the classic toplevel).  Bots hammer /, so the root boots NO app: this load throws a 404
//    before any component mounts, which is the whole point — no boot_qualand, no Ghost, no
//     audio/WebRTC on the one path crawlers always hit.  `error()` is an EXPECTED error, so
//      SvelteKit returns a clean 404 without console-spamming a stack per bot.
//  Flip this to a landing page or a redirect(307,'/BigSoundland') when / earns a real door.
import { error } from '@sveltejs/kit'

export function load() {
    throw error(404, 'Not found — the rooms live at /BigSoundland and /BigWordland')
}
