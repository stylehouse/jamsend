<script lang="ts">
//#region Keep
// LiesKeep.svelte — the Keep ledger: Waft:Keep, the workspace that remembers.  (Backbone P4 / D7:
//  extracted from Lies.svelte so the attention-store lives in its own organ beside LiesStore/
//   LangHold/LiesCurse — file placement is organisational; these are eatfunc methods reached at
//    runtime through H, so the cut is by ownership, not by call graph.)
//
//   Owns the (scope,id,key)→value LAYOUT service (P5) plus the cfg|pref typed stores, the ledger
//   accumulators (note / mark_focus / push_cursor), the cursor-resume readers (resume_waft |
//   resume_what — the latter delegates to Lies' general Lies_resolve_locator, which STAYS in Lies
//   as the document-machine primitive gated by LakeLocate), and the editor boot driver
//   (Lies_keep_boot / _reopen).  Dual concern with Lies: Lies creates the Keep particle (Persist)
//   and holds the loose-locator resolver; LiesKeep holds the attention ledger over it.

import { type House } from "$lib/O/Housing.svelte"
import { TheC } from "$lib/data/Stuff.svelte"
import { boot_param } from "$lib/boot"
import { onMount } from "svelte"

let { M } = $props()

onMount(async () => {
await M.eatfunc({

    // ── The Keep — Waft:Keep, the workspace that remembers ──────────────────────
    //
    //   A first-class particle (spec/Cluster_design.md): the ledger of every Waft we
    //   find.  Each gets a /%WaftTimes,of_Waft:<path> bearing discovered_at (set once) +
    //   accessed_at (bumped on focus); under it a /%Cursor history (the last several
    //   positions, for resuming the cursor INSIDE the Waft).  The Keep ALSO keeps its OWN
    //   /%Cursor history — the last Wafts focused — so boot can auto-resume the last one
    //   when no ?W= is given.  Marked %boring: backstage, so it is never a switcher nib
    //   (the interest_roster skip) nor a focus candidate (Lies_focus_waft's filter).
    //   Persistence: the Keep SNAPS to its own home (a real Waft — reuses Lies_open_Waft /
    //    Persist / Lies_waft_save like every overlay).  So it loads ASYNC, and the ONLY
    //     creator is Persist — Lies_keep is a read-only getter (never oai), the accumulators
    //      no-op until it has materialised, and Lies_keep_boot stages the reopen.  (The Idento
    //       keeps riding stashed for crypto; attention snaps, a clean split.)

    //   Lies_keep — the Waft:Keep particle if it exists yet (read-only — Persist creates it).
    Lies_keep(w: TheC): TheC | undefined {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        // stamp %equip on first sight (and migrate an old %boring | kind:Keep Keep off):
        //  equip = out of the cursor's way (no nib, no focus, guts fold from the snap) yet
        //   line-VISIBLE — minimised is its own stored flag, absent here, so the Keep opens.
        if (keep && (keep.sc.boring || keep.sc.kind || !keep.sc.equip)) {
            delete keep.sc.boring
            delete keep.sc.kind
            keep.sc.equip = 'Keep'
            keep.bump_version()
        }
        return keep
    },

    //   Lies_keep_cfg_get / _set — the GENERAL per-Waft config store, backed by the Keep.
    //    A Waft's "how it's pitched|configured" (minimised now; scroll | other view-state
    //     later) rides on its WaftTimes record — NOT on the Waft particle — so it survives
    //      reload even for a dontSnap fixture (Cluster), and the Keep owns the attention state
    //       in one place (Cluster_design).  A flag rides 1-or-absent; get returns undefined when
    //        the Keep | record | key is absent, so the caller supplies the default.
    //   get uses a RAW Keep lookup (no Lies_keep migrate/bump) — safe to call inside a $derived.
    Lies_keep_cfg_get(w: TheC, path: string, key: string): any {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        const wt   = keep?.o({ WaftTimes: 1, of_Waft: path })[0] as TheC | undefined
        return wt?.sc[key]
    },
    Lies_keep_cfg_set(w: TheC, path: string, key: string, val: any): void {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        if (!keep) return                                    // no Keep yet (early boot | runner) — drop
        const wt = keep.oai({ WaftTimes: 1, of_Waft: path })
        if (val != null) wt.sc[key] = val
        else delete wt.sc[key]                               // 1-or-absent: open IS the absence
        keep.bump_version()   // ROOT bump so watch_c re-saves (a WaftTimes-only mutation won't)
    },

    //   Lies_keep_pref_get / _set — a GLOBAL (not per-Waft) preference, on the Keep ROOT.
    //    For pane-level UI state that belongs to no single Waft — the editor's expand height,
    //     say (Langui's V toggle).  Rides the Keep particle's own sc (1-or-absent), the one
    //      place that already persists (the Keep's own snap), so the pref survives reload
    //       without a phantom WaftTimes.  get is a RAW lookup (no migrate/bump) — $derived-safe;
    //        absent ⇒ undefined, caller supplies the default.  Mutating the root IS the bump.
    Lies_keep_pref_get(w: TheC, key: string): any {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        return keep?.sc[key]
    },
    Lies_keep_pref_set(w: TheC, key: string, val: any): void {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        if (!keep) return                                    // no Keep yet (early boot | runner) — drop
        if (val != null) keep.sc[key] = val
        else delete keep.sc[key]                             // 1-or-absent: collapsed IS the absence
        keep.bump_version()
    },

    //   Lies_keep_layout_host / _get / _set — the ONE (scope,id,key)→value LAYOUT service
    //    (Backbone_plan P5).  A pose | view-state lives on the Keep so it survives reload, and a
    //     client names a (scope, id, key) triple through this one front door rather than reaching
    //      for a store.  FOUR scopes, four homes under the one snapped Keep particle —
    //        'global'  id ignored     → the Keep ROOT sc          (global chrome: the editor expand)
    //        'waft'    id=<Waft path> → WaftTimes,of_Waft:<id>    (per-Waft: minimise | scroll)
    //        'lens'    id=<Lens id>   → Layout,of_Lens:<id>       (per-Lens: Brink pose | minimap_open)
    //      (the 'waft'|'global' homes are the same the cfg|pref stores above use — this is the unified
    //       door over them plus the new per-Lens Layout home; the typed stores stay for current callers
    //        until P6 migrates them onto this.)  get is a RAW lookup (no migrate/bump) → $derived-safe;
    //         absent ⇒ undefined so the caller supplies the default.  set is COALESCED — a write equal
    //          to the stored value is a no-op (no bump), so an ave→Keep mirror can't feed a write loop
    //           back (the write-only-on-user-change discipline that keeps the live↔snap loop from
    //            oscillating).  A flag rides 1-or-absent (null|undefined val deletes); set bumps the Keep
    //             ROOT so the top-only watch_c re-saves even for a WaftTimes|Layout CHILD mutation.
    Lies_keep_layout_host(w: TheC, scope: string, id: string, make = false): TheC | undefined {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        if (!keep) return undefined
        if (scope === 'global') return keep
        if (scope === 'waft')   return make ? keep.oai({ WaftTimes: 1, of_Waft: id })
                                            : keep.o({ WaftTimes: 1, of_Waft: id })[0] as TheC | undefined
        if (scope === 'lens')   return make ? keep.oai({ Layout: 1, of_Lens: id })
                                            : keep.o({ Layout: 1, of_Lens: id })[0] as TheC | undefined
        // 'doc' (#11): per-Doc scroll-as-LINE.  A DocScroll,of_Doc:<path> child holds `scroll_line` —
        //  the editor's top visible line, so reopening a doc restores its scroll across a reload and a
        //   different zoom|wrap (a line survives both; pixels don't).  Twin of Langui's in-memory,
        //    pixel-exact scrollCache, which only spans a session.
        if (scope === 'doc')    return make ? keep.oai({ DocScroll: 1, of_Doc: id })
                                            : keep.o({ DocScroll: 1, of_Doc: id })[0] as TheC | undefined
        return undefined
    },
    Lies_keep_layout_get(w: TheC, scope: string, id: string, key: string): any {
        return (this as House).Lies_keep_layout_host(w, scope, id)?.sc[key]
    },
    Lies_keep_layout_set(w: TheC, scope: string, id: string, key: string, val: any): void {
        const H    = this as House
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        if (!keep) return                                    // no Keep yet (early boot | runner) — drop
        const want = val != null ? val : undefined
        if (H.Lies_keep_layout_get(w, scope, id, key) === want) return   // coalesce — no feedback loop
        const host = H.Lies_keep_layout_host(w, scope, id, true)!
        if (want != null) host.sc[key] = want
        else delete host.sc[key]                             // 1-or-absent: the default IS the absence
        keep.bump_version()
    },

    //   Lies_keep_note — accumulate a Waft into the ledger: discovered_at once, accessed_at
    //    now.  No-op until the Keep has loaded (early boot opens catch up on next focus).
    Lies_keep_note(w: TheC, path: string): TheC | undefined {
        const keep = (this as House).Lies_keep(w)
        if (!keep) return undefined
        const wt  = keep.oai({ WaftTimes: 1, of_Waft: path })
        const now = Date.now()
        wt.sc.discovered_at ??= now
        wt.sc.accessed_at    = now
        keep.bump_version()   // watch_c watches the ROOT version only (Housing watch_c) — a
        return wt             //  descendant (WaftTimes) mutation won't trigger the save without this
    },

    //   Lies_keep_mark_focus — record a focus: bump the Waft's accessed_at AND push the
    //    Keep's OWN %Cursor (which Waft) so auto-resume-last knows where to return.
    Lies_keep_mark_focus(w: TheC, path: string): void {
        const H    = this as House
        const keep = H.Lies_keep(w)
        if (!keep) return
        H.Lies_keep_note(w, path)
        H.Lies_keep_push_cursor(keep, 'waft', path)
    },

    //   Lies_keep_push_cursor — record the latest %Cursor on a host (the Keep, or a WaftTimes).
    //    Keeps exactly ONE — the current position — reused in place.  (Was a capped-10 history,
    //     but only the last is ever read — resume_waft | resume_what — so the tail was dead
    //      weight bloating the snap.)  Any stragglers a legacy ledger left collapse on the next
    //       move, so an old multi-Cursor Keep self-cleans to a single latest of each.
    Lies_keep_push_cursor(host: TheC, key: string, val: string): void {
        const curs = host.o({ Cursor: 1 }) as TheC[]
        const cur  = curs[curs.length - 1] ?? host.i({ Cursor: 1 })
        cur.sc[key] = val
        cur.sc.at   = Date.now()
        for (const old of curs.slice(0, -1)) host.drop(old)   // collapse a legacy multi-entry ledger
        host.bump_version()
    },

    //   Lies_keep_resume_waft — the Waft to focus when no ?W= is given: the Keep's latest
    //    own %Cursor (the last thing focused).  undefined on a fresh Keep.
    Lies_keep_resume_waft(w: TheC): string | undefined {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        const curs = (keep?.o({ Cursor: 1 }) as TheC[] | undefined) ?? []
        return curs[curs.length - 1]?.sc.waft as string | undefined
    },

    //   Lies_keep_note_cursor — remember WHERE in a Waft the cursor sits: push a %Cursor onto
    //    the Waft's WaftTimes carrying the src's own mainkey:value (What:<name> | Doc:<path>) —
    //     the within-Waft tail of the FromWhat `Waft:<key>/…` locator (the WaftTimes already
    //      names the Waft).  Reads the WaftTimes (Lies_keep_note creates it on Waft-open) — a
    //       consumer, not a creator, so no oai churn on the hot want-land path.
    Lies_keep_note_cursor(w: TheC, waft_key: string, src: TheC): void {
        const H    = this as House
        const keep = H.Lies_keep(w)
        if (!keep) return
        const wt = keep.o({ WaftTimes: 1, of_Waft: waft_key })[0] as TheC | undefined
        if (!wt) return
        const mk = H.mainkey(src)
        if (!mk) return
        H.Lies_keep_push_cursor(wt, 'what', `${mk}:${(src.sc as any)[mk]}`)
        keep.bump_version()   // push_cursor bumped the WaftTimes child; bump the ROOT too so the
                              //  top-only watch_c fires and the Keep actually re-saves (see note)
    },

    //   Lies_keep_resume_what — resolve a Waft's last-remembered cursor (the latest %Cursor on
    //    its WaftTimes) back to a live particle inside the (re-opened) Waft.  undefined when
    //     nothing is remembered or the locator no longer resolves → the caller lands on first.
    Lies_keep_resume_what(w: TheC, waft: TheC, path: string): TheC | undefined {
        const H    = this as House
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        const wt   = keep?.o({ WaftTimes: 1, of_Waft: path })[0] as TheC | undefined
        const curs = (wt?.o({ Cursor: 1 }) as TheC[] | undefined) ?? []
        const loc  = curs[curs.length - 1]?.sc.what as string | undefined
        return H.Lies_resolve_locator(w, loc, waft)   // the within-Waft tail (What:<name> | Doc:<path>)
    },

    //   Lies_keep_reopen — reopen every Waft in the ledger (idempotent via Lies_open_Waft's
    //    Good dedup).  Seeds the first overlays on a fresh Keep so a brand-new editor still
    //     co-loads Easy + Music/Ality.
    Lies_keep_reopen(w: TheC): void {
        const H    = this as House
        const keep = H.Lies_keep(w)
        if (!keep) return
        let times  = keep.o({ WaftTimes: 1 }) as TheC[]
        if (!times.length) {
            for (const path of ['Ghost/Net/Easy', 'Ghost/Music/Ality']) H.Lies_keep_note(w, path)
            times = keep.o({ WaftTimes: 1 }) as TheC[]
        }
        for (const wt of times)
            H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path: wt.sc.of_Waft as string })
    },

    //   Lies_keep_boot — the editor boot driver (heartbeat, staged & gated by w.c flags):
    //    (1) open Waft:Keep once so Persist loads it from its snap home (or creates it fresh);
    //     (2) once it materialises, stamp it backstage + reopen its ledger (seeds if fresh);
    //      (3) when no ?W= was given, once the remembered last Waft is open, foreground it so
    //       the focus auto-resumes there.  (?W=, when present, already wins — Editron opens it
    //        first.)  Each step fires at most once; step 3 retries until its Waft reopens.
    Lies_keep_boot(w: TheC): void {
        const H = this as House
        if (H.Lies_role(w) !== 'editor') return
        if (!w.c.keep_opened) {
            w.c.keep_opened = 1
            H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path: 'Keep' })   // Persist loads/creates it
        }
        if (!w.c.keep_booted) {
            const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
            if (!keep) return                                              // wait for Persist
            w.c.keep_booted = 1
            H.Lies_keep(w)   // stamp equip:Keep (migrates off any old %boring|kind) — see Lies_keep
            H.Lies_keep_reopen(w)
        }
        if (!w.c.keep_resumed && !boot_param('W')) {
            const resume = H.Lies_keep_resume_waft(w)
            if (!resume) { w.c.keep_resumed = 1; return }                  // nothing remembered — keep Editron's default
            const rw = w.o({ Waft: resume })[0] as TheC | undefined
            if (!rw) return                                               // the remembered Waft particle is still reopening — wait
            // wait for its CONTENT too, so the concentric pair resumes WHOLE: the foreground
            //  runs Lies_keep_resume_what → Lies_locate_in_waft over this Waft's What|Doc tree,
            //   and if that tree is still mid-load it finds nothing and lands on first — the
            //    outer Waft resumes but the inner What is lost.  Bounded (~30 ticks) so an
            //     empty | slow Waft still foregrounds (land-on-first) rather than hanging.
            const ready = rw.o({ What: 1 }).length || rw.o({ Doc: 1 }).length
            if (!ready && ((w.c.keep_resume_waits = ((w.c.keep_resume_waits as number) ?? 0) + 1) < 30)) return
            w.c.keep_resumed = 1
            H.i_elvisto('Lies/Lies', 'Lies_foreground_waft', { path: resume })   // canonical foreground = focus + land (+ inner-what resume)
        }
    },

})
})
//#endregion
</script>
