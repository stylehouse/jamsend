// pier_marks — MY private marks on a friend (☆ star, a note), shared by the Door's list and the Pier cell.
//  Home: the House stash, `stashed.Pier_marks[pub] = { star?: '1', note?: string }`, which persists itself on any change
//   (Housing's deep $effect → Dexie).  Deliberately NOT on the %Pier: those are friendship-ledger rows whose stash keeps
//    only page + grants, and a star is taste, not membership.  Never leaves this browser (owner 2026-10-14).
export type PierMark = { star?: string, note?: string }

export function pier_marks(H: any): Record<string, PierMark> {
    try { return (H?.top_House?.()?.stashed?.Pier_marks ?? {}) as Record<string, PierMark> } catch { return {} }
}

// set or clear fields (an empty value deletes the key; an emptied mark deletes the entry) — replaced whole, so the
//  stash's deep watcher sees a new object and saves.
export function pier_mark_set(H: any, pub: string, patch: Record<string, string>) {
    try {
        const top = H?.top_House?.()
        if (!top?.stashed || !pub) return
        const all = { ...(top.stashed.Pier_marks ?? {}) }
        const m: Record<string, string> = { ...(all[pub] ?? {}), ...patch }
        for (const k of Object.keys(m)) if (!m[k]) delete m[k]
        if (Object.keys(m).length) all[pub] = m; else delete all[pub]
        top.stashed.Pier_marks = all
        top.bump_version?.()
    } catch {}
}
