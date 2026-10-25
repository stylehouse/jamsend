// boot_param — read a boot-time parameter, abstracting WHERE it comes from so the same
//  call works in the browser and in node (the UIless Story runner, jsdom or bare):
//
//    • browser:  the URL query string        ?B=Editron&W=Ghost/Net/Easy
//    • node:     an env var (UPPERCASED name)  B=Editron  W=Ghost/Net/Easy
//
//  The boot knobs: `A` (top-level world, default Auto), `B` (a Story Book for Auto to activate —
//   ?B=Editron boots the editor, ?B=PereStaple the runner), `W` (the Waft a Book opens).
//  Returns undefined when unset, so callers apply their own default (e.g. `|| 'Auto'`).
//  jsdom defines an (empty) `location`, so under vitest the URL branch simply misses and we
//   fall through to env — i.e. a CLI run drives the same knobs the browser drives via the URL.
//  `process` is absent in the browser bundle, hence the typeof guard (no ReferenceError).
export function boot_param(name: string): string | undefined {
    if (typeof location !== 'undefined' && location.search) {
        const v = new URLSearchParams(location.search).get(name)
        if (v != null) return v
    }
    if (typeof process !== 'undefined' && process.env) {
        const v = process.env[name.toUpperCase()]
        if (v != null && v !== '') return v
    }
    return undefined
}

// A persisted per-tab preference (localStorage, survives reload) — a sibling to the URL/env params
//  above.  `hasAudioContext` is the durable INTENT set by IdHatch's tickbox: this tab AIMS to provide
//   a real AudioContext (for real-time audio Books).  The LIVE fact is separate — whether a gat
//    actually resumed — and stays ephemeral; this only records the aim, so Otro can demand the gesture
//     up-front and a ticked runner lands audio-ready before dispatch sends it a Book.  Browser-guarded
//      (no localStorage under node), defaults off; a flip takes effect on the next reload (like socklog).
// PER-INVITE DISMISSAL — "I saw this invite and I am not dealing with it now", remembered against
//  the TOKEN so it releases that one invite and no other.  It exists to be the prerequisite the
//   Butler's own notes name: the owner has ruled that the door should hold on a discovered invite
//    "until it is fulfilled … certainly not letting you into the app until you have sorted that
//     out", and that hold may not ship while the only invites that can never be fulfilled — a dead
//      single-use token, a relay that never answers — have no exit but ▦.  A hold with a per-invite
//       release is a hold; a hold without one is the permanent trap this whole screen was rebuilt
//        to stop being.  So this lands FIRST, on its own, while the release-on-either-terminal
//         interim is still what actually governs `landing`.
//  KEYED BY TOKEN, not by "an invite was dismissed once": a single-use token IS unique, so a second
//   invite from the same friend still holds the screen, which is the whole point of "every Invite
//    it DISCOVERS".
//  localStorage, like `hasAudioContext` above and for the same reason — it must survive the reload
//   that the six-step flow's own token deletes itself across.  BOUNDED at the most recent 20: this
//    is a courtesy list, not a ledger, and an unbounded one on a shared machine is a slow leak.
//   Private-mode safe: a browser that refuses storage simply re-asks, which is the safe direction.
const DISMISSED_KEY = 'inviteDismissed'
function dismissed_list(): string[] {
    try {
        if (typeof localStorage === 'undefined') return []
        const raw = localStorage.getItem(DISMISSED_KEY)
        if (!raw) return []
        const v = JSON.parse(raw)
        return Array.isArray(v) ? v.filter((x) => typeof x === 'string') : []
    } catch { return [] }
}
export function invite_dismissed(token: string | undefined): boolean {
    if (!token) return false
    return dismissed_list().includes(token)
}
export function dismiss_invite(token: string | undefined): void {
    if (!token) return
    try {
        if (typeof localStorage === 'undefined') return
        const next = [token, ...dismissed_list().filter((t) => t !== token)].slice(0, 20)
        localStorage.setItem(DISMISSED_KEY, JSON.stringify(next))
    } catch { /* storage refused — the door will simply ask again next boot */ }
}

// ── THE PENDING INVITE (Arrival_todo 2026-10-25 B: "trying extra hard not to lose that invite!") ──────────────
//  A friend invite's ?Iz is stripped from the bar the moment its hello is sent (InvitePanel strip_iz), and the
//   %Invite row that tracks it is station-world furniture a reload forgets — so a reload, a crash or a tab kill
//    between "hello sent" and "sealed" lost the invite outright (the owner's phone, 2026-10-25).  Keep the token
//     here from the moment the page lands on it until it CONCLUDES (sealed, or the person chose to go on without
//      it), and put it back in the bar on the next boot, so the landing comes back exactly as it was.
//  Friend invites only: a device link (`*My…*`) keeps its own token in the bar for the whole adopt.
//  localStorage, like the dismiss list above: it has to survive exactly the reload this exists for.
const PENDING_KEY = 'invitePending'
export function invite_pending(): { iz: string, from?: string } | null {
    try {
        if (typeof localStorage === 'undefined') return null
        const v = JSON.parse(localStorage.getItem(PENDING_KEY) || 'null')
        return v && typeof v.iz === 'string' && v.iz ? v : null
    } catch { return null }
}
export function invite_pending_set(iz: string | undefined, from?: string): void {
    if (!iz || /\*My[A-Z]/.test(iz)) return
    try {
        if (typeof localStorage === 'undefined') return
        localStorage.setItem(PENDING_KEY, JSON.stringify(from ? { iz, from } : { iz }))
    } catch {}
}
export function invite_pending_clear(iz?: string): void {
    try {
        if (typeof localStorage === 'undefined') return
        const p = invite_pending()
        if (!p || (iz && p.iz !== iz)) return
        localStorage.removeItem(PENDING_KEY)
    } catch {}
}
// THE RESTORE, at module load — before any face reads boot_param('Iz').  A dispatch tab (?B=/?E=) and a tab
//  that already carries a token (in the query or the anchor) are left alone; so is an invite the person put
//   aside or sent elsewhere.  Whatever ?I= the bar carries stays: strip_iz pinned it so the reload is the same
//    person, and the restored token rides beside it.
;(() => {
    try {
        if (typeof location === 'undefined' || typeof history === 'undefined') return
        const u = new URL(location.href)
        if (u.searchParams.has('B') || u.searchParams.has('E') || u.searchParams.has('Iz')) return
        if (/(^#|&)Iz=/.test(u.hash || '')) return
        const p = invite_pending()
        if (!p || invite_dismissed(p.iz)) return
        u.searchParams.set('Iz', p.iz)
        if (p.from) u.searchParams.set('From', p.from)
        history.replaceState(history.state, '', u.pathname + u.search + u.hash)
        console.log('✉ restored a pending invite to the bar — it had not concluded before the last reload')
    } catch {}
})()
// The landing's own record of it: stash the URL's friend token as soon as any face sees it.
export function invite_pending_note(): void {
    const iz = boot_param('Iz')
    if (iz && !invite_dismissed(iz)) invite_pending_set(iz, boot_param('From'))
}

const AUDIO_KEY = 'hasAudioContext'
export function has_audio(): boolean {
    try { return typeof localStorage !== 'undefined' && localStorage.getItem(AUDIO_KEY) === '1' } catch { return false }
}
export function set_has_audio(on: boolean): void {
    try {
        if (typeof localStorage === 'undefined') return
        if (on) localStorage.setItem(AUDIO_KEY, '1'); else localStorage.removeItem(AUDIO_KEY)
    } catch { /* private-mode / disabled storage — the flag just won't persist */ }
}
