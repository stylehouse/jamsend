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
