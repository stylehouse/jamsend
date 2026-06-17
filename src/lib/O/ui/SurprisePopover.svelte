<script lang="ts">
    // SurprisePopover — the surprise_read conflict, lifted out of the doc list into
    // a popover that pops out of the Interest channel.
    //
    //   When a Doc's auto-save was parked because disk diverged under the open edit
    //   (req_LiesStore_writeCarefully stamps good/%surprise_read — text/dige/disk_dige
    //   on sc, theirs off-snap on c.disk_text), the IDE escalates it as a "something
    //   big wants your attention" moment.  Interests *are* channels; the surprise_read
    //   is this Interest's business, so the escalation surface lives beside the
    //   InterestStrip rather than buried in the doc row.  The inline DocRow row remains
    //   as a fallback; this popover is the primary surface.
    //
    //   Storui flavour: a position:fixed Vexpandy at the top of the viewport (popup
    //   mode), so the editor stays usable while it's up.  V collapses to a slim bar;
    //   Esc dismisses it (the conflict persists in the inline row); resolving the
    //   conflict — keep mine / take theirs — clears it.  No × kill button (Waft_spec:
    //   dismissal of the Interest itself lives in PeelInput, not here).
    //
    //   The Good/%surprise_read is *acquired separately* from the Interest — Good lives
    //   under w:Lies/req:Store, the Interest is a Lang-side roster row — but the
    //   attention escalation belongs to the Interest.  We reach w:Lies the same way
    //   Liesui does: H.ave's %examining particle carries c.w, and bumps its version
    //   when w:Lies ticks (watch_c), so this stays live without a parent re-render.

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import Vexpandy from "$lib/O/ui/Vexpandy.svelte"
    import DocDiff  from "$lib/O/ui/DocDiff.svelte"

    let { H }: { H: House } = $props()

    // ── reach w:Lies (mirror Liesui) ──────────────────────────────────────
    let ex: TheC | undefined = $state()
    $effect(() => { ex = H.ave.ob({ examining: 1 })[0] as TheC | undefined })

    // ── scan w:Lies/req:Store for the first Good carrying a surprise_read ──
    //   ex.ob() tracks the examining version (bumps each w:Lies tick), so a freshly
    //   stamped surprise is picked up.  void g.vers per Good subscribes to the
    //   conflict being stamped / cleared on that Good.
    type Conflict = { path: string; mine: string; theirs: string | undefined }
    let conflict: Conflict | null = $derived.by(() => {
        ex?.ob()
        const w = ex?.c?.w as TheC | undefined
        if (!w) return null
        const store = (w.ob({ req: 'Store' }) as TheC[])[0] as TheC | undefined
        if (!store) return null
        for (const g of store.ob({ Good: 1, type: 'text/Doc' }) as TheC[]) {
            void g.vers
            const sr = (g.o({ surprise_read: 1 }) as TheC[])[0] as TheC | undefined
            if (sr) {
                void sr.version
                return {
                    path:   g.sc.path as string,
                    mine:   (sr.sc.text as string | undefined) ?? '',
                    theirs: sr.c.disk_text as string | undefined,
                }
            }
        }
        return null
    })

    // ── open / dismiss ────────────────────────────────────────────────────
    //   Shown whenever a conflict exists and the user hasn't dismissed it.  A new
    //   conflict (different path) re-arms it; resolving clears `conflict` outright.
    let dismissed = $state(false)
    let expanded  = $state(true)
    let last_path = $state<string | null>(null)
    $effect(() => {
        const p = conflict?.path ?? null
        if (p !== last_path) { last_path = p; dismissed = false; expanded = true }
    })
    let open = $derived(!!conflict && !dismissed)

    // Esc dismisses the whole popover (Vexpandy's own Esc only collapses the body).
    $effect(() => {
        if (!open) return
        const handler = (e: KeyboardEvent) => {
            if (e.key === 'Escape') { e.preventDefault(); dismissed = true }
        }
        window.addEventListener('keydown', handler)
        return () => window.removeEventListener('keydown', handler)
    })

    // ── actions ─────────────────────────────────────────────────────────
    //   keep / take run in Lies (same legs the inline row fires); the resolution
    //   clears good/%surprise_read, so `conflict` goes null and the popover closes.
    function keep_mine()   { if (conflict) H.i_elvisto('Lies/Lies', 'Lies_surprise_keep_mine',   { path: conflict.path }) }
    function take_theirs() { if (conflict) H.i_elvisto('Lies/Lies', 'Lies_surprise_take_theirs', { path: conflict.path }) }

    // Escalate to Lies: the reusable "bigger expression of the situation" hop.
    //   Open the doc (its DocRow glows + carries the inline keep/take/diff), dismiss
    //   the popover, then scroll the Lies House into view.  The short delay lets the
    //   popover's fixed bar clear before scroll_to_house measures — same as Storui's
    //   go_to_diff.  scroll_to_house is the durable seam on top_House (prefer it over
    //   NaviScroll, which is likely retiring).
    function escalate() {
        if (!conflict) return
        const path = conflict.path
        H.i_elvisto('Lang/Lang', 'Dock_open', { path })
        dismissed = true
        setTimeout(() => H.top_House().scroll_to_house?.(H), 50)
    }
</script>

{#if open && conflict}
    <Vexpandy bind:expanded popup={true}>
        {#snippet header()}
            <span class="srp-warn" title="this file changed on disk while you were editing — your save is held">
                ⚠ disk changed under your edit
            </span>
            <span class="srp-path" title={conflict.path}>{conflict.path}</span>
            <button class="srp-btn srp-keep"  onclick={keep_mine}
                    title="overwrite disk with your edit">keep mine</button>
            <button class="srp-btn srp-take"  onclick={take_theirs}
                    title="discard your edit and reload from disk">take theirs</button>
            <button class="srp-goto" onclick={escalate}
                    title="open in editor and scroll to Lies">go to Lies ↓</button>
        {/snippet}
        {#snippet children()}
            {#if conflict.theirs !== undefined}
                <DocDiff mine={conflict.mine} theirs={conflict.theirs} />
            {:else}
                <div class="srp-note">disk version not loaded (page reloaded) — “take theirs” to fetch it.</div>
            {/if}
        {/snippet}
    </Vexpandy>
{/if}

<style>
    /* Header bar lives inside Vexpandy's .vx-popup-hdr (flex row).  Warm-amber to
       match the inline conflict row (.ls-conflict) so the two surfaces read as one. */
    .srp-warn {
        font-size: 11px; color: #d39; white-space: nowrap; flex-shrink: 0;
    }
    .srp-path {
        font-family: 'Berkeley Mono', ui-monospace, monospace;
        font-size: 11px; color: #9ab; flex: 1;
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .srp-btn {
        font-size: 11px; border-radius: 3px; cursor: pointer;
        padding: 1px 7px; white-space: nowrap; flex-shrink: 0;
    }
    .srp-keep { background: #15301a; border: 1px solid #2a5a2a; color: #7c9; }
    .srp-keep:hover { background: #1c3e22; color: #9eb; }
    .srp-take { background: #301512; border: 1px solid #5a2a24; color: #c87; }
    .srp-take:hover { background: #3e1c18; color: #e9a; }
    .srp-goto {
        background: none; border: none; color: #888; cursor: pointer;
        font-size: 11px; padding: 1px 4px; flex-shrink: 0; text-decoration: underline;
    }
    .srp-goto:hover { color: #c4aaee; }
    .srp-note { font-size: 11px; color: #976; padding: 6px 10px; }
</style>
