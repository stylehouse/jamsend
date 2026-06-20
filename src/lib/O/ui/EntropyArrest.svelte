<script lang="ts">
    // EntropyArrest.svelte — author a Snapcap (an acknowledged-noise rule) from a
    //   click on a noisy diff line.  EncodingSplatter (the ancestor) copies a snippet
    //   to the clipboard; this mints a live %Snapcap under The/EntropyArrest, which
    //   entropy_rules compiles into a spay rule on the next run (EntropyArrest.md §4).
    //
    // ── the single draft, the DevTools-breadcrumb discipline ──────────────────
    //   A diff click does NOT mint a cap — it seeds ONE in-flight draft, the only
    //   "live" thing here.  Clicking another diff line re-points that same draft (it
    //   never accumulates), exactly as selecting a new element re-points the path at
    //   the bottom of the DevTools Elements panel.  Nothing reaches toc.snap until OK.
    //   So you can poke around the diff without drowning in half-formed rules.
    //
    // ── the IOpath editor ─────────────────────────────────────────────────────
    //   The locator is a %lematch chain — a structural path into the C tree, outer→leaf
    //   (w:Story › req:wants › want).  This is the first UI editor of that whole path;
    //   each segment is a PeelInput, the one piece-editor Waft already leans on.  The
    //   %spayer leaf (how to neutralise the noise) is the kind-specific block below it.
    //
    // ── compare-time, not encode (the pivot, §2.3') ───────────────────────────
    //   We author a descriptor only; the snap on disk stays honest.  blank/band forgive
    //   at compare; the regex self-locates by its lookbehind, so the lematch mainly
    //   scopes this author view.  A restart re-reads the caps — the UI says so.
    //
    // Props:
    //   H        — the Story sub-House (elvisto target for commit/delete)
    //   w        — the Story world (w.c.The holds the EntropyArrest bucket)
    //   seed     — {left, right} snap-line texts from a clicked Dif:change row, or null
    //   step_n   — the currently open step (offered as the cap's scope), or null
    //   on_done  — clear the parent's seed once a draft is committed or cancelled

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { peel, depeel } from "$lib/Y.svelte"
    import PeelInput      from "$lib/O/ui/PeelInput.svelte"

    let { H, w, seed, step_n, on_done }: {
        H:       House
        w:       TheC | undefined
        seed:    { left: string, right: string } | null
        step_n:  number | null
        on_done: () => void
    } = $props()

    //#region draft model
    type Seg     = { sc: Record<string, any> }     // one %lematch level; first key is its mainkey
    type SpKind  = 'blank' | 'band' | 'drop'
    type Spayer  = {
        kind:  SpKind
        re?:   string
        first?: number
        factor?: number
        add_step_mult?: 1
        floor?: 1
        key?:  string                              // drop's target sc key
    }
    type Draft = {
        slug:    string
        lematch: Seg[]
        spayer:  Spayer
        note?:   string
        scope_step?: number
    }

    let draft = $state<Draft | null>(null)

    // existing authored caps — read straight from The (where they persist), tracked
    //  on The.version so a commit/delete updates the list without a restart.
    let caps = $derived.by((): TheC[] => {
        const The = w?.c.The as TheC | undefined
        void The?.version
        const ea = The?.o({ EntropyArrest: 1 })[0] as TheC | undefined
        void ea?.version
        return (ea?.o({ Snapcap: 1 }) ?? []) as TheC[]
    })
    //#endregion

    //#region seed — a diff click re-points the one draft
    let _seed_seen: { left: string, right: string } | null = null   // plain: no reactive subscribe
    $effect(() => {
        const s = seed
        if (s && s !== _seed_seen) {
            _seed_seen = s
            const d = draft_from_seed(s)
            if (d) { draft = d; open_seg = null }
        }
    })

    // Reduce a clicked diff line to a starting locator + an autogen spayer.  The got
    //  side names the particle; diffing it against prev finds the churning number.
    //  Single-segment locator for now (parent/descent widening is §4.4, deferred);
    //  the regex carries the real discriminator, the lematch just scopes the view.
    function draft_from_seed(s: { left: string, right: string }): Draft | null {
        const got  = H.deL(s.right) ?? H.deL(s.left)
        if (!got) return null
        const gs = got.stringies as Record<string, any>
        const ps = (H.deL(s.left)?.stringies ?? {}) as Record<string, any>
        const mk = Object.keys(gs)[0]
        if (!mk) return null

        // noisy key: first whose numeric value changed prev→got; else any numeric key
        let noisy = Object.keys(gs).find(k => typeof gs[k] === 'number' && ps[k] !== undefined && ps[k] !== gs[k])
        noisy ??= Object.keys(gs).find(k => typeof gs[k] === 'number')

        // locator seg: keep the mainkey + discriminators; wildcard the churning value
        //  (value 1 = "has key, any value") so it can't pin the noise it is forgiving.
        const seg_sc: Record<string, any> = { ...gs }
        if (noisy) seg_sc[noisy] = 1

        let spayer: Spayer
        if (!noisy) {
            spayer = { kind: 'blank', re: '' }
        } else if (Number.isFinite(gs[noisy]) && !Number.isInteger(gs[noisy])) {
            // a float — a timing; offer a band nailed at the prev value
            spayer = { kind: 'band', re: `(?<=${noisy}=)\\d+\\.\\d+`, first: (ps[noisy] ?? gs[noisy]) as number, factor: 10 }
        } else {
            spayer = { kind: 'blank', re: `(?<=${noisy}=)\\d+(\\.\\d+)?` }
        }

        return { slug: noisy ? `${mk}-${noisy}` : mk, lematch: [{ sc: seg_sc }], spayer }
    }
    //#endregion

    //#region segment (IOpath piece) editing — via PeelInput
    let open_seg = $state<number | null>(null)
    let seg_mk   = $state('')
    let seg_sc_s = $state('')

    function seg_mk_key(seg: Seg): string { return Object.keys(seg.sc)[0] ?? '?' }
    function seg_val(seg: Seg): string {
        const k = seg_mk_key(seg); const v = seg.sc[k]
        return v === 1 ? '*' : String(v ?? '')
    }
    function seg_rest(seg: Seg): string {
        const [, ...ks] = Object.keys(seg.sc)
        return depeel(Object.fromEntries(ks.map(k => [k, seg.sc[k]])))
    }

    function open_segment(i: number) {
        if (!draft) return
        const seg = draft.lematch[i]
        open_seg = i
        seg_mk   = seg_val(seg)
        seg_sc_s = seg_rest(seg)
    }
    function submit_segment(i: number) {
        if (!draft) return
        const seg    = draft.lematch[i]
        const mk_key = seg_mk_key(seg)
        // '*' or empty → wildcard (1); a digit-run → number; else string
        const mk_val = (seg_mk === '*' || seg_mk === '') ? 1
                     : /^-?\d+$/.test(seg_mk) ? Number(seg_mk) : seg_mk
        const rest   = seg_sc_s.trim() ? peel(seg_sc_s) : {}
        seg.sc = { [mk_key]: mk_val, ...rest }
        draft  = { ...draft }          // re-trigger
        open_seg = null
    }
    function drop_segment(i: number) {
        if (!draft || draft.lematch.length <= 1) return   // keep at least one
        draft.lematch.splice(i, 1)
        draft = { ...draft }
        open_seg = null
    }
    //#endregion

    //#region spayer editing
    function set_kind(k: SpKind) {
        if (!draft) return
        const re = draft.spayer.re ?? ''
        draft.spayer = k === 'drop'
            ? { kind: 'drop', key: draft.spayer.key ?? '' }
            : k === 'band'
            ? { kind: 'band', re, first: draft.spayer.first ?? 0, factor: draft.spayer.factor ?? 10 }
            : { kind: 'blank', re }
        draft = { ...draft }
    }
    function patch_spayer(p: Partial<Spayer>) {
        if (!draft) return
        draft.spayer = { ...draft.spayer, ...p }
        draft = { ...draft }
    }
    function patch_draft_slug(v: string)            { if (draft) draft = { ...draft, slug: v } }
    function patch_draft_scope(n: number | undefined) { if (draft) draft = { ...draft, scope_step: n } }
    //#endregion

    //#region commit / delete
    function commit() {
        if (!draft || !draft.slug.trim() || !draft.lematch.length) return
        H.i_elvisto('Story/Story', 'entropy_commit', { cap_json: JSON.stringify(draft) })
        draft = null
        on_done()
    }
    function cancel() { draft = null; open_seg = null; on_done() }

    function del_cap(cap: TheC) {
        H.i_elvisto('Story/Story', 'entropy_delete', { slug: String(cap.sc.Snapcap) })
    }
    function edit_cap(cap: TheC) { draft = draft_from_cap(cap); open_seg = null }

    function segs_from_lematch(lm: TheC): Seg[] {
        const { lematch, ...sc } = lm.sc as Record<string, any>
        const kid = lm.o({ lematch: 1 })[0] as TheC | undefined
        return kid ? [{ sc }, ...segs_from_lematch(kid)] : [{ sc }]
    }
    function draft_from_cap(cap: TheC): Draft {
        const lm = cap.o({ lematch: 1 })[0] as TheC | undefined
        const sp = cap.o({ spayer: 1 })[0] as TheC | undefined
        const { spayer, ...spfields } = (sp?.sc ?? { spayer: 1, kind: 'blank' }) as any
        return {
            slug:       String(cap.sc.Snapcap),
            lematch:    lm ? segs_from_lematch(lm) : [],
            spayer:     spfields as Spayer,
            note:       cap.o({ note:  1 })[0]?.sc.note as string | undefined,
            scope_step: cap.o({ scope: 1 })[0]?.sc.step as number | undefined,
        }
    }

    // one-line summary of an existing cap for the CRUD list
    function cap_path(cap: TheC): string {
        const lm = cap.o({ lematch: 1 })[0] as TheC | undefined
        if (!lm) return '∅'
        return segs_from_lematch(lm).map(seg => {
            const k = seg_mk_key(seg)
            const v = seg.sc[k] === 1 ? '*' : seg.sc[k]
            return seg_rest(seg) ? `${k}:${v},${seg_rest(seg)}` : `${k}:${v}`
        }).join(' › ')
    }
    function cap_kind(cap: TheC): string {
        return (cap.o({ spayer: 1 })[0]?.sc.kind as string) ?? '?'
    }
    //#endregion
</script>

{#if draft || caps.length}
<div class="ea">
    <div class="ea-hdr">
        <span class="ea-title">🛑 entropy arrest</span>
        <span class="ea-sub">{caps.length} cap{caps.length === 1 ? '' : 's'}{draft ? ' · drafting' : ''}</span>
    </div>

    <!-- existing authored caps — CRUD list -->
    {#each caps as cap (cap.sc.Snapcap)}
        <div class="ea-cap">
            <span class="ea-cap-kind ea-kind-{cap_kind(cap)}">{cap_kind(cap)}</span>
            <span class="ea-cap-slug">{cap.sc.Snapcap}</span>
            <span class="ea-cap-path">{cap_path(cap)}</span>
            <span class="ea-spacer"></span>
            <button class="ea-mini" title="load into the draft to edit" onclick={() => edit_cap(cap)}>edit</button>
            <button class="ea-mini ea-del" title="delete this cap" onclick={() => del_cap(cap)}>×</button>
        </div>
    {/each}

    <!-- the single in-flight draft -->
    {#if draft}
        <div class="ea-draft">
            <!-- slug -->
            <div class="ea-row">
                <span class="ea-flabel">cap</span>
                <input class="ea-input ea-slug" placeholder="slug" value={draft.slug}
                       oninput={(e) => patch_draft_slug((e.target as HTMLInputElement).value)} />
            </div>

            <!-- the IOpath breadcrumb: one PeelInput per %lematch segment -->
            <div class="ea-row ea-path-row">
                <span class="ea-flabel">at</span>
                <div class="ea-breadcrumb">
                    {#each draft.lematch as seg, i (i)}
                        {#if i > 0}<span class="ea-crumb-sep">›</span>{/if}
                        <div class="ea-crumb">
                            <PeelInput
                                label={seg_mk_key(seg)}
                                open={open_seg === i}
                                display_val={seg_val(seg)}
                                display_sc={seg_rest(seg)}
                                mk_ph="value / *"
                                sc_ph="k:v,k2"
                                mainkey={open_seg === i ? seg_mk : ''}
                                on_mk={(v) => seg_mk = v}
                                sc_str={open_seg === i ? seg_sc_s : ''}
                                on_sc={(v) => seg_sc_s = v}
                                submit_label="✓"
                                on_open={() => open_segment(i)}
                                on_submit={() => submit_segment(i)}
                                on_cancel={() => open_seg = null}
                                on_crud={{
                                    orb_open: open_seg === i,
                                    on_orb: () => open_seg === i ? (open_seg = null) : open_segment(i),
                                    on_cancel_orb: () => open_seg = null,
                                    on_del: () => drop_segment(i),
                                }} />
                        </div>
                    {/each}
                </div>
            </div>

            <!-- the %spayer leaf: how to neutralise -->
            <div class="ea-row">
                <span class="ea-flabel">spay</span>
                <div class="ea-kinds">
                    {#each ['blank','band','drop'] as k (k)}
                        <button class="ea-kindbtn" class:on={draft.spayer.kind === k}
                                onclick={() => set_kind(k as SpKind)}>{k}</button>
                    {/each}
                </div>
            </div>

            {#if draft.spayer.kind === 'drop'}
                <div class="ea-row ea-fields">
                    <label class="ea-field">key
                        <input class="ea-input" placeholder="age" value={draft.spayer.key ?? ''}
                               oninput={(e) => patch_spayer({ key: (e.target as HTMLInputElement).value })} />
                    </label>
                </div>
            {:else}
                <div class="ea-row ea-fields">
                    <label class="ea-field ea-field-wide">re
                        <input class="ea-input ea-re" placeholder="(?<=round=)\d+" value={draft.spayer.re ?? ''}
                               oninput={(e) => patch_spayer({ re: (e.target as HTMLInputElement).value })} />
                    </label>
                </div>
                {#if draft.spayer.kind === 'band'}
                    <div class="ea-row ea-fields">
                        <label class="ea-field">first
                            <input class="ea-input ea-num" type="number" step="any" value={draft.spayer.first ?? 0}
                                   oninput={(e) => patch_spayer({ first: Number((e.target as HTMLInputElement).value) })} />
                        </label>
                        <label class="ea-field">factor
                            <input class="ea-input ea-num" type="number" step="any" value={draft.spayer.factor ?? 10}
                                   oninput={(e) => patch_spayer({ factor: Number((e.target as HTMLInputElement).value) })} />
                        </label>
                        <label class="ea-check">
                            <input type="checkbox" checked={!!draft.spayer.add_step_mult}
                                   onchange={(e) => patch_spayer({ add_step_mult: (e.target as HTMLInputElement).checked ? 1 : undefined })} />
                            ×step
                        </label>
                        <label class="ea-check">
                            <input type="checkbox" checked={!!draft.spayer.floor}
                                   onchange={(e) => patch_spayer({ floor: (e.target as HTMLInputElement).checked ? 1 : undefined })} />
                            floor
                        </label>
                    </div>
                {/if}
            {/if}

            <!-- scope + commit -->
            <div class="ea-row ea-foot">
                {#if step_n != null}
                    <label class="ea-check" title="limit to this step; off = all steps">
                        <input type="checkbox" checked={draft.scope_step != null}
                               onchange={(e) => patch_draft_scope((e.target as HTMLInputElement).checked ? step_n! : undefined)} />
                        only step {step_n}
                    </label>
                {/if}
                <span class="ea-spacer"></span>
                <span class="ea-hint">restart to apply</span>
                <button class="ea-cancel" onclick={cancel}>cancel</button>
                <button class="ea-ok" onclick={commit}>OK</button>
            </div>
        </div>
    {/if}
</div>
{/if}

<style>
    .ea {
        margin: 0.3rem 0;
        background: #0a0e14;
        border: 1px solid #243044;
        border-radius: 3px;
        padding: 0.3rem 0.4rem;
        font-size: 0.78rem;
    }
    .ea-hdr { display: flex; align-items: center; gap: 0.4rem; margin-bottom: 0.25rem }
    .ea-title { color: #8ab; font-weight: bold; font-size: 0.8rem }
    .ea-sub   { color: #557; font-size: 0.72rem }

    /* existing caps */
    .ea-cap {
        display: flex; align-items: center; gap: 0.3rem;
        padding: 0.12rem 0.2rem; border-radius: 2px;
        font-family: monospace; font-size: 0.72rem;
    }
    .ea-cap:hover { background: #0e1420 }
    .ea-cap-kind { font-size: 0.66rem; border-radius: 2px; padding: 0 0.22rem; flex-shrink: 0 }
    .ea-kind-blank { background: #102a2a; color: #6cc }
    .ea-kind-band  { background: #2a2410; color: #cb6 }
    .ea-kind-drop  { background: #2a1020; color: #c68 }
    .ea-cap-slug { color: #9ab; flex-shrink: 0 }
    .ea-cap-path { color: #567; overflow: hidden; text-overflow: ellipsis; white-space: nowrap }
    .ea-spacer   { flex: 1 }
    .ea-mini {
        background: none; border: 1px solid #243044; border-radius: 2px;
        color: #678; cursor: pointer; font-size: 0.66rem; padding: 0.04rem 0.26rem; flex-shrink: 0;
    }
    .ea-mini:hover { color: #9bd; border-color: #356 }
    .ea-del:hover  { color: #f66; border-color: #633 }

    /* the draft */
    .ea-draft {
        margin-top: 0.25rem; padding: 0.3rem;
        background: #0c1018; border: 1px solid #2a3850; border-radius: 3px;
    }
    .ea-row { display: flex; align-items: center; gap: 0.35rem; margin: 0.18rem 0 }
    .ea-flabel {
        font-family: monospace; font-size: 0.7rem; color: #557;
        width: 2.4rem; flex-shrink: 0; text-align: right;
    }
    .ea-path-row { align-items: flex-start }
    .ea-breadcrumb {
        display: flex; align-items: center; gap: 0.15rem; flex-wrap: wrap; flex: 1; min-width: 0;
    }
    .ea-crumb-sep { color: #445; font-size: 0.8rem }
    .ea-crumb {
        display: flex; align-items: center;
        background: #0a0c12; border: 1px solid #1e2838; border-radius: 3px;
        padding: 0 0.15rem;
    }

    .ea-input {
        background: #0d0d14; border: 1px solid #333; border-radius: 3px;
        color: #aaa; font-family: monospace; font-size: 0.74rem;
        padding: 0.15rem 0.3rem; outline: none;
    }
    .ea-input:focus { border-color: #446 }
    .ea-slug { width: 12rem }
    .ea-re   { flex: 1; min-width: 8rem }
    .ea-num  { width: 5rem }

    .ea-kinds { display: flex; gap: 0.2rem }
    .ea-kindbtn {
        background: #0d0d14; border: 1px solid #243044; border-radius: 3px;
        color: #567; cursor: pointer; font-family: monospace; font-size: 0.7rem;
        padding: 0.1rem 0.4rem;
    }
    .ea-kindbtn:hover { color: #9bd }
    .ea-kindbtn.on { background: #16263a; color: #bdf; border-color: #468 }

    .ea-fields { gap: 0.5rem; flex-wrap: wrap; padding-left: 2.75rem }
    .ea-field {
        display: flex; align-items: center; gap: 0.25rem;
        font-family: monospace; font-size: 0.68rem; color: #567;
    }
    .ea-field-wide { flex: 1; min-width: 0 }
    .ea-check {
        display: flex; align-items: center; gap: 0.2rem;
        font-family: monospace; font-size: 0.68rem; color: #567; cursor: pointer;
    }

    .ea-foot { margin-top: 0.3rem }
    .ea-hint { color: #546; font-size: 0.66rem; font-style: italic }
    .ea-cancel {
        background: none; border: none; color: #556; cursor: pointer;
        font-size: 0.72rem; padding: 0.15rem 0.3rem;
    }
    .ea-cancel:hover { color: #99a }
    .ea-ok {
        background: #16263a; border: 1px solid #356; border-radius: 3px;
        color: #bdf; cursor: pointer; font-size: 0.74rem; padding: 0.15rem 0.6rem;
    }
    .ea-ok:hover { background: #1d3148; color: #dff }
</style>
