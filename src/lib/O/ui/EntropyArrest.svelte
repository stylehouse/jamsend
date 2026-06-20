<script lang="ts">
    // EntropyArrest.svelte — author an Entcase (an acknowledged-noise rule) from a click
    //   on a noisy diff line.  Mints a live %Entcase under The/EntropyArrest; entropy_rules
    //   compiles it into a spay rule, and the live-app verdict forgives it at compare
    //   (EntropyArrest.md §8 — the captures+graft model).
    //
    // ── the single draft, the DevTools-breadcrumb discipline ──────────────────
    //   A diff click does NOT mint a cap — it seeds ONE in-flight draft, the only "live"
    //   thing here.  Clicking another diff line re-points it (never accumulates); nothing
    //   reaches toc.snap until OK.  So you can poke around the diff without drowning in caps.
    //
    // ── the locator: one ' / '-split peelable text field (§8.6) ────────────────
    //   The locator (`at`) is a plain text field of peelables split by ' / ', outer→leaf
    //   (e.g. `A:Lang / self,round`).  Plain text ⇒ Ctrl-Z for free, no segment widget.
    //   Each chunk peels into one %lematch level's sc.  Seeded including the parent's match.
    //
    // ── the spayer (§8): captures + tolerance ──────────────────────────────────
    //   re carries capture groups (the noise); the edges are anchors.  tol is `band`
    //   (within factor× of exp's value) or `any` (graft wholesale — hashes/sigs/timestamps).
    //   H.entropy_suggest proposes re+tol from the clicked line vs its prev.
    //
    // Props:
    //   H        — the Story sub-House (elvisto target for commit/delete)
    //   w        — the Story world (w.c.The holds the EntropyArrest bucket)
    //   seed     — { left, right, parent? } snap-line texts from a clicked Dif:change row
    //   step_n   — the currently open step (offered as the cap's scope), or null
    //   on_done  — clear the parent's seed once a draft is committed or cancelled

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { peel, depeel } from "$lib/Y.svelte"

    // ── the fuzz tub: wind the suggested re's head|tail anchors down toward greedy ───
    //   entropy_suggest hands back the re's `parts` (anchors + captures).  The captures
    //    are the fixed core; the anchors before the first / after the last capture are the
    //     head / tail, and each fuzz slider winds its side down a notch at a time.  The
    //      wind-down is "strip-value-then-trim": the anchor nearest the capture loses its
    //       value first, then the far landmark drops, then the nearest key drops too — so
    //        `want={INT}.kind:cold.resolved` goes `…kind.+resolved` → `…kind` → `want={INT}`.
    //   The `.+` always absorbs the stripped value, which peel renders to the RIGHT of the key
    //    — so for a TAIL token (core on its left) the gap is on the far side (`kind.+resolved`),
    //     but for a HEAD token (core on its right) the gap faces the core, so the `.+` is the
    //      head's CORE-facing bridge (`compile.dige.+secs={NUM}`, not `compile.+dige.secs…`).
    //   Each level therefore carries its own core-facing bridge (`.` normal, `.+` once the near
    //    value is stripped).  The tub vanishes the moment you hand-edit re.
    const SPAY_TAG = /\{(?:INT|NUM|TOK)\}/         // a part carrying a capture group

    // the bare-flag form of an anchor token: the key before its first : or = (kind:cold → kind)
    function key_of(tok: string): string { return tok.split(/[:=]/)[0] }

    // one wind-down level: `str` is the side's anchor text, `bridge` the connector to the core
    type Notch = { str: string, bridge: string }
    // drop a level identical to the one before it (a valueless single token yields a dup notch)
    function dedupe(seq: Notch[]): Notch[] {
        return seq.filter((s, i) => i === 0 || s.str !== seq[i - 1].str || s.bridge !== seq[i - 1].bridge)
    }

    // one side's wind-down, full (index 0) → greedy ('' last).  `near` is the token nearest the
    //  core (survives longest).  A `.+` only appears when there is a near VALUE to absorb — a
    //   bare flag (`time`, `dim`) has nothing to strip, so it goes full → greedy with no spurious
    //    `time.+compile` notch.  When there is a value, the `.+` lands on the TAIL inside the side
    //     text (far side of the key, `kind.+resolved`) but on the HEAD as the core bridge (the
    //      value sits between the head key and the core, `compile.dige.+secs`).
    function fuzz_seq(tokens: string[], side: 'head' | 'tail'): Notch[] {
        const join = (ts: string[]) => ts.join('.')
        if (!tokens.length) return [{ str: '', bridge: '' }]
        const near_tok = side === 'tail' ? tokens[0] : tokens[tokens.length - 1]
        const near = key_of(near_tok)
        const valued = /[:=]/.test(near_tok)                  // a value to strip → a `.+` is warranted
        const rest = side === 'tail' ? tokens.slice(1) : tokens.slice(0, -1)
        const seq: Notch[] = [{ str: join(tokens), bridge: '.' }]
        if (side === 'tail') {
            if (valued && rest.length) seq.push({ str: `${near}.+${join(rest)}`, bridge: '.' })
            if (valued || rest.length) seq.push({ str: near, bridge: '.' })
        } else {
            if (valued && rest.length) seq.push({ str: `${join(rest)}.${near}`, bridge: '.+' })
            if (valued || rest.length) seq.push({ str: near, bridge: valued ? '.+' : '.' })
        }
        seq.push({ str: '', bridge: '' })
        return dedupe(seq)
    }

    type FuzzModel = { core: string, head_seq: Notch[], tail_seq: Notch[] }
    // split the parts into head anchors | capture core | tail anchors, and precompute each
    //  side's wind-down sequence.  null when there is no capture to anchor around.
    function fuzz_model(parts: string[]): FuzzModel | null {
        if (!parts.length) return null
        let fc = -1, lc = -1
        parts.forEach((p, i) => { if (SPAY_TAG.test(p)) { if (fc < 0) fc = i; lc = i } })
        if (fc < 0) return null
        return {
            core:     parts.slice(fc, lc + 1).join('.'),
            head_seq: fuzz_seq(parts.slice(0, fc), 'head'),
            tail_seq: fuzz_seq(parts.slice(lc + 1), 'tail'),
        }
    }
    // render the re at the current head|tail fuzz levels (clamped to each sequence).  The head
    //  attaches with its bridge on the core side; the tail's bridge is always a plain `.`.
    function compose_re(m: FuzzModel, h: number, t: number): string {
        const H = m.head_seq[Math.min(h, m.head_seq.length - 1)]
        const T = m.tail_seq[Math.min(t, m.tail_seq.length - 1)]
        let re = m.core
        if (H.str) re = `${H.str}${H.bridge}${re}`
        if (T.str) re = `${re}${T.bridge}${T.str}`
        return re
    }

    let { H, w, seed, step_n, on_done }: {
        H:       House
        w:       TheC | undefined
        seed:    { left: string, right: string, parent?: string | null } | null
        step_n:  number | null
        on_done: () => void
    } = $props()

    //#region draft fields — discrete state (no segment widget, just inputs)
    let active   = $state(false)
    let at_text  = $state('')                       // the ' / '-split peelable locator
    let noisy    = $state<string | undefined>()     // the changed key (drives the auto-slug + wildcard)
    let re_text  = $state('')
    // the fuzz tub rides the suggested re's structured parts.  re_dirty latches the moment
    //  the user hand-edits re — the parts no longer describe it, so the sliders retire.
    let re_parts = $state<string[]>([])
    let re_dirty = $state(false)
    let h_fuzz   = $state(0)
    let t_fuzz   = $state(0)
    let fuzz     = $derived(re_parts.length ? fuzz_model(re_parts) : null)
    // while the tub is live the sliders own re — recompose it as they move.  The effect never
    //  reads re_text, so writing it can't loop; once re_dirty it stops, leaving the field manual.
    $effect(() => {
        if (re_dirty || !fuzz) return
        re_text = compose_re(fuzz, h_fuzz, t_fuzz)
    })
    function wheel_fuzz(e: WheelEvent, which: 'h' | 't', max: number) {
        e.preventDefault()
        const v = (which === 'h' ? h_fuzz : t_fuzz) + (e.deltaY > 0 ? 1 : -1)
        const c = Math.max(0, Math.min(max, v))
        if (which === 'h') h_fuzz = c; else t_fuzz = c
    }
    // the handler kind, a 4-way mutex: band|any are spayer tolerances (a capture re forgives
    //  a value), drop|dontSnap are structural means (no captures — drop omits the whole line,
    //   dontSnap keeps the line but folds its subtree away).  band|any need the re/tol fields;
    //    drop|dontSnap don't.
    let mode     = $state<'band' | 'any' | 'drop' | 'dontSnap'>('band')
    let is_spayer = $derived(mode === 'band' || mode === 'any')
    // the fuzz tub shows only for a spayer with anchors to wind down, and retires on hand-edit
    let show_tub = $derived(is_spayer && !re_dirty && !!fuzz && (fuzz.head_seq.length > 1 || fuzz.tail_seq.length > 1))
    let factor   = $state(1.5)
    let scope_on = $state(false)
    // slug auto-derives from the form beneath until the user edits it (§8.6)
    let slug_edited = $state(false)
    let slug_manual = $state('')
    let slug = $derived(slug_edited ? slug_manual : derive_slug(at_text, noisy))

    // existing authored caps — read straight from The (tracked on its version so a
    //  commit/delete refreshes the list without a restart)
    let caps = $derived.by((): TheC[] => {
        const The = w?.c.The as TheC | undefined
        void The?.version
        const ea = The?.o({ EntropyArrest: 1 })[0] as TheC | undefined
        void ea?.version
        return (ea?.o({ Entcase: 1 }) ?? []) as TheC[]
    })
    //#endregion

    //#region seed — a diff click re-points the one draft
    let _seed_seen: typeof seed = null   // plain: no reactive subscribe
    $effect(() => {
        const s = seed
        if (s && s !== _seed_seen) { _seed_seen = s; seed_into_fields(s) }
    })

    // a value that LOOKS like churn — a timestamp / path / long id: a run of ≥3 digits, or
    //  digit groups joined by `-` or `/` (`2026-06-21`, `042649`, `Ting/2026-06-21/042649`).
    //   We don't know which keys are noisy a priori, but a date/path value is a reliable tell;
    //    `lens:DocTing` / `state:live` carry no such run and stay literal.
    function noisy_val(v: any): boolean {
        return typeof v === 'string' && /\d{3,}|\d+[-/]\d+/.test(v)
    }

    // depeel a snap line into one locator chunk.  Two wildcardings, both "err vague after the
    //  mainkey" — a too-loose locator is safe (it just no-ops where it over-matches; the spayer's
    //   re does the precise work), an over-anchored one silently stops forgiving the moment a
    //    pinned value drifts:
    //   - from `wildcard_from` onward, bareword every key (the noisy key and everything after it),
    //      so a trailing churner (`all=…,write=0`) doesn't over-anchor;
    //   - on ANY non-mainkey key whose value looks noisy (a `waft:Ting/2026-06-21/042649` date/path),
    //      bareword it even when it sits BEFORE the clicked key — this is the parent-line over-anchor
    //       (a pinned `waft:` value is full of diff noise).  The first key (the type tag) stays literal.
    function loc_chunk(line: string, wildcard_from?: string): string {
        const sc = { ...(H.deL(line)?.stringies ?? {}) } as Record<string, any>
        const ks = Object.keys(sc)
        if (wildcard_from) {
            const from = ks.indexOf(wildcard_from)
            if (from >= 0) for (const k of ks.slice(from)) sc[k] = 1
        }
        for (const k of ks.slice(1)) if (noisy_val(sc[k])) sc[k] = 1
        return depeel(sc)
    }

    function seed_into_fields(s: { left: string, right: string, parent?: string | null }) {
        const got = H.deL(s.right) ?? H.deL(s.left)
        if (!got) return
        const gs = got.stringies as Record<string, any>
        const ps = (H.deL(s.left)?.stringies ?? {}) as Record<string, any>
        // noisy key: the first key whose value CHANGED prev→got — numeric (a counter/timing) OR
        //  a structured string whose embedded numbers churn (a mainkey path/timestamp like
        //   `Waft:Ting/2026-06-21/034032`).  It is the wildcard-from point, so the locator pins
        //    the stable keys before it and barewords the mutating value + everything after
        //     (`Waft,takes`, not `Waft:Ting/…,takes`).  Fall back to the first numeric.
        let nk = Object.keys(gs).find(k => ps[k] !== undefined && ps[k] !== gs[k])
        nk ??= Object.keys(gs).find(k => typeof gs[k] === 'number')
        noisy = nk

        // locator: parent match (if passed) ' / ' leaf line, leaf's noisy value wildcarded
        const leaf = loc_chunk(s.right, nk)
        at_text = s.parent ? `${loc_chunk(s.parent)} / ${leaf}` : leaf

        // spayer: ask the engine for a capture-style regex + tolerance, and seed the fuzz
        //  tub from its structured parts (a fresh draft starts at full precision, head|tail 0).
        const sug = H.entropy_suggest(s.right, s.left)
        re_dirty = false; h_fuzz = 0; t_fuzz = 0
        if (sug) { re_text = sug.re; mode = sug.tol as 'band' | 'any'; factor = sug.factor ?? 1.5; re_parts = sug.parts }
        // no suggestion: a numeric noisy key still defaults to band (the common case);
        //  only a non-numeric locator falls back to any.  No parts ⇒ no fuzz tub.
        else     { re_text = nk ? `${nk}={NUM}` : ''; mode = nk ? 'band' : 'any'; factor = 1.5; re_parts = [] }

        slug_edited = false; slug_manual = ''
        scope_on = false
        active = true
    }
    //#endregion

    //#region slug derivation
    function chunks(at: string): string[] {
        return at.split(/\s+\/\s+/).map(c => c.trim()).filter(Boolean)
    }
    function derive_slug(at: string, nk: string | undefined): string {
        const cs = chunks(at)
        if (!cs.length) return nk || 'cap'
        const leafmk = Object.keys(peel(cs[cs.length - 1]))[0] ?? 'c'
        const prefix = cs.slice(0, -1)
            .map(c => { const o = peel(c) as Record<string, any>; const k = Object.keys(o)[0]; return o[k] === 1 ? k : String(o[k]) })
            .join('_')
        const tail = nk && nk !== leafmk ? `${leafmk}-${nk}` : leafmk
        return prefix ? `${prefix}_${tail}` : tail
    }
    //#endregion

    //#region commit / delete / edit
    function reset() {
        active = false; at_text = ''; noisy = undefined
        re_text = ''; mode = 'band'; factor = 1.5; scope_on = false
        slug_edited = false; slug_manual = ''
        re_parts = []; re_dirty = false; h_fuzz = 0; t_fuzz = 0
    }
    function commit() {
        const s = slug.trim()
        if (!s) return
        const lematch = chunks(at_text).map(c => ({ sc: peel(c) }))
        if (!lematch.length) return
        // means descriptor by kind: band|any → a spayer (re + tol[+factor]); drop|dontSnap →
        //  a bare structural kind.  A spayer with no re is incomplete — bail.
        let means: { kind: string, [k: string]: any }
        if (is_spayer) {
            if (!re_text.trim()) return
            means = mode === 'band' ? { kind: 'spayer', re: re_text, tol: 'band', factor }
                                    : { kind: 'spayer', re: re_text, tol: 'any' }
        } else {
            means = { kind: mode }
        }
        const cap = { slug: s, lematch, means, scope_step: scope_on && step_n != null ? step_n : undefined }
        H.i_elvisto('Story/Story', 'entropy_commit', { cap_json: JSON.stringify(cap) })
        reset(); on_done()
    }
    function cancel() { reset(); on_done() }

    function del_cap(cap: TheC) {
        H.i_elvisto('Story/Story', 'entropy_delete', { slug: String(cap.sc.Entcase) })
    }

    function segs_from_lematch(lm: TheC): TheC[] {
        const kid = lm.o({ lematch: 1 })[0] as TheC | undefined
        return kid ? [lm, ...segs_from_lematch(kid)] : [lm]
    }
    // the handler rides on a flat %means particle inside the leaf %lematch — a spayer
    //  (%means,spayer,re:…,tol:…) or a structural kind (%means,drop / %means,dontSnap).
    function cap_spayer(cap: TheC): TheC | undefined {
        const lm = cap.o({ lematch: 1 })[0] as TheC | undefined
        const leaf = lm ? segs_from_lematch(lm).at(-1) : undefined
        return leaf?.o({ means: 1 })[0] as TheC | undefined
    }
    // the means kind, as the 4-way mode: a structural drop/dontSnap, else the spayer tol.
    function cap_means_kind(cap: TheC): 'band' | 'any' | 'drop' | 'dontSnap' | '?' {
        const mn = cap_spayer(cap)
        if (!mn) return '?'
        if (mn.sc.drop != null)     return 'drop'
        if (mn.sc.dontSnap != null) return 'dontSnap'
        return (mn.sc.tol ?? (mn.sc.kind === 'band' ? 'band' : 'any')) as 'band' | 'any'
    }
    function lematch_chunks(lm: TheC): string {
        return segs_from_lematch(lm)
            .map(seg => { const { lematch, ...sc } = seg.sc as Record<string, any>; return depeel(sc) })
            .join(' / ')
    }
    // re-sugar a stored raw capture regex back to {NUM}/{TOK} for the field, so an
    //  older cap reads as legibly as a freshly-suggested one.  Text.spay_desugar is
    //   the inverse applied at compare time; both sides agree.
    function resugar(re: string): string {
        return re
            .replace(/\(\\d\+\(\?:\\\.\\d\+\)\?\)/g, '{NUM}')   // (\d+(?:\.\d+)?)
            .replace(/\(\\d\+\)/g, '{INT}')                     // (\d+)
            .replace(/\(\[\^,\\s\]\+\)/g, '{TOK}')              // ([^,\s]+)
            .replace(/\(\\S\+\?\)/g, '{TOK}')                   // (\S+?) — legacy form
    }
    function edit_cap(cap: TheC) {
        const lm = cap.o({ lematch: 1 })[0] as TheC | undefined
        const sp = cap_spayer(cap)
        const k  = cap_means_kind(cap)
        at_text     = lm ? lematch_chunks(lm) : ''
        re_text     = resugar((sp?.sc.re as string) ?? '')
        // an existing cap's re is loaded as-is (no structured parts to drive the fuzz tub) —
        //  treat it as hand-authored so the sliders stay retired; re-suggest from a diff click
        //   to get them back.
        re_parts    = []; re_dirty = true; h_fuzz = 0; t_fuzz = 0
        mode        = k === '?' ? 'band' : k
        factor      = (sp?.sc.factor as number) ?? 1.5
        noisy       = undefined
        slug_edited = true
        slug_manual = String(cap.sc.Entcase)
        scope_on    = cap.o({ scope: 1 })[0] != null
        active      = true
    }

    // one-line summary of an existing cap for the CRUD list
    function cap_path(cap: TheC): string {
        const lm = cap.o({ lematch: 1 })[0] as TheC | undefined
        return lm ? lematch_chunks(lm) : '∅'
    }
    function cap_tol(cap: TheC): string {
        return cap_means_kind(cap)
    }
    //#endregion
</script>

{#if active || caps.length}
<div class="ea">
    <div class="ea-hdr">
        <span class="ea-title">EntropyArrest</span>
        {#if active}<span class="ea-sub">drafting</span>{/if}
    </div>

    <!-- existing authored caps — CRUD list -->
    {#each caps as cap (cap.sc.Entcase)}
        <div class="ea-cap">
            <span class="ea-cap-tol ea-tol-{cap_tol(cap)}">{cap_tol(cap)}</span>
            <span class="ea-cap-slug">{cap.sc.Entcase}</span>
            <span class="ea-cap-path">{cap_path(cap)}</span>
            <span class="ea-spacer"></span>
            <button class="ea-mini" title="load into the draft to edit" onclick={() => edit_cap(cap)}>edit</button>
            <button class="ea-mini ea-del" title="delete this cap" onclick={() => del_cap(cap)}>×</button>
        </div>
    {/each}

    <!-- the single in-flight draft -->
    {#if active}
        <div class="ea-draft">
            <!-- slug (auto-derives until edited) -->
            <div class="ea-row">
                <span class="ea-flabel">cap</span>
                <input class="ea-input ea-slug" placeholder="slug" value={slug}
                       class:derived={!slug_edited}
                       oninput={(e) => { slug_manual = (e.target as HTMLInputElement).value; slug_edited = true }} />
            </div>

            <!-- the locator: one ' / '-split peelable text field -->
            <div class="ea-row">
                <span class="ea-flabel">at</span>
                <input class="ea-input ea-at" placeholder="A:Lang / self,round" value={at_text}
                       oninput={(e) => at_text = (e.target as HTMLInputElement).value} />
            </div>

            <!-- the handler kind: band|any forgive a value (spayer); drop|dontSnap are
                 structural (drop the line / fold the subtree).  factor rides band only. -->
            <div class="ea-row">
                <span class="ea-flabel">means</span>
                <div class="ea-kinds">
                    {#each ['band','any','drop','dontSnap'] as t (t)}
                        <button class="ea-kindbtn" class:on={mode === t}
                                class:structural={t === 'drop' || t === 'dontSnap'}
                                onclick={() => mode = t as typeof mode}>{t}</button>
                    {/each}
                </div>
                {#if mode === 'band'}
                    <label class="ea-field">factor
                        <input class="ea-input ea-num" type="number" step="any" value={factor}
                               oninput={(e) => factor = Number((e.target as HTMLInputElement).value)} />
                    </label>
                {/if}
            </div>

            {#if is_spayer}
                <div class="ea-row ea-fields">
                    <label class="ea-field ea-field-wide">re
                        <input class="ea-input ea-re" placeholder={'round={NUM}'} value={re_text}
                               oninput={(e) => { re_text = (e.target as HTMLInputElement).value; re_dirty = true }} />
                    </label>
                </div>
            {:else}
                <div class="ea-row ea-note">
                    {mode === 'drop'
                        ? 'drops the whole matched line from the snap (got and exp) — for a structural surprise spay can\'t forgive (an added/removed row).'
                        : 'keeps the matched line but folds its subtree away — stops snapping any further in.'}
                </div>
            {/if}

            <!-- scope + fuzz + commit.  The fuzz tub rides here, compact, between the step
                 scope and the buttons: two short handles converging on `fuzz` — left winds the
                  re's head anchors down toward greedy, right the tail.  Drag or wheel; retires
                   the moment you hand-edit re. -->
            <div class="ea-row ea-foot">
                {#if step_n != null}
                    <label class="ea-check" title="limit to this step; off = all steps">
                        <input type="checkbox" checked={scope_on}
                               onchange={(e) => scope_on = (e.target as HTMLInputElement).checked} />
                        only step {step_n}
                    </label>
                {/if}
                {#if show_tub && fuzz}
                    <span class="ea-fuzz-wrap" title="wind the re's head | tail anchors down toward a greedy match — drag or wheel">
                        <input class="ea-fuzz ea-fuzz-l" type="range" min="0" max={fuzz.head_seq.length - 1} step="1"
                               value={h_fuzz} disabled={fuzz.head_seq.length < 2}
                               oninput={(e) => h_fuzz = Number((e.target as HTMLInputElement).value)}
                               onwheel={(e) => wheel_fuzz(e, 'h', fuzz.head_seq.length - 1)} />
                        <span class="ea-fuzz-lbl">fuzz</span>
                        <input class="ea-fuzz ea-fuzz-r" type="range" min="0" max={fuzz.tail_seq.length - 1} step="1"
                               value={t_fuzz} disabled={fuzz.tail_seq.length < 2}
                               oninput={(e) => t_fuzz = Number((e.target as HTMLInputElement).value)}
                               onwheel={(e) => wheel_fuzz(e, 't', fuzz.tail_seq.length - 1)} />
                    </span>
                {/if}
                <span class="ea-spacer"></span>
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
    .ea-cap-tol { font-size: 0.66rem; border-radius: 2px; padding: 0 0.22rem; flex-shrink: 0 }
    .ea-tol-band { background: #2a2410; color: #cb6 }
    .ea-tol-any  { background: #102a2a; color: #6cc }
    .ea-tol-drop     { background: #2a1018; color: #c69 }
    .ea-tol-dontSnap { background: #1a1226; color: #a8d }
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

    .ea-input {
        background: #0d0d14; border: 1px solid #333; border-radius: 3px;
        color: #aaa; font-family: monospace; font-size: 0.74rem;
        padding: 0.15rem 0.3rem; outline: none;
    }
    .ea-input:focus { border-color: #446 }
    .ea-slug { width: 14rem }
    .ea-slug.derived { color: #678; font-style: italic }   /* auto-derived until edited */
    .ea-at   { flex: 1; min-width: 10rem }
    .ea-re   { flex: 1; min-width: 8rem }
    .ea-num  { width: 4.5rem }

    /* the fuzz tub: |_O_fuzz_O_| — compact, in the footer between the step scope and the
       buttons.  Two short handles converging on `fuzz`: left winds the re's head anchors
        down, right the tail. */
    .ea-fuzz-wrap {
        display: inline-flex; align-items: center; gap: 0.3rem;
        padding: 0.1rem 0.4rem; margin-left: 0.4rem;
        background: #0b0f17; border: 1px solid #2a3850; border-radius: 999px;
    }
    .ea-fuzz {
        -webkit-appearance: none; appearance: none;
        width: 3rem; height: 3px; background: #243044; border-radius: 2px; outline: none;
        cursor: ew-resize;
    }
    .ea-fuzz-r { transform: scaleX(-1) }            /* handle starts at the right, winds inward */
    .ea-fuzz::-webkit-slider-thumb {
        -webkit-appearance: none; appearance: none;
        width: 11px; height: 11px; border-radius: 50%;
        background: #6cc; border: 1px solid #0b0f17;
    }
    .ea-fuzz::-moz-range-thumb {
        width: 11px; height: 11px; border-radius: 50%;
        background: #6cc; border: 1px solid #0b0f17;
    }
    .ea-fuzz:disabled { opacity: 0.3; cursor: default }
    .ea-fuzz-lbl {
        font-family: monospace; font-size: 0.6rem; color: #668;
        letter-spacing: 0.06em; flex-shrink: 0; user-select: none;
    }

    /* a 4-way segmented mutex (band | any | drop | dontSnap): buttons share borders
       (-1px) and the active one rides on top.  drop|dontSnap are tinted apart as the
       structural category — they forgive nothing, they omit. */
    .ea-kinds { display: flex }
    .ea-kindbtn {
        position: relative;
        background: #0d0d14; border: 1px solid #243044; border-radius: 3px;
        color: #567; cursor: pointer; font-family: monospace; font-size: 0.7rem;
        padding: 0.1rem 0.4rem;
    }
    .ea-kindbtn:not(:first-child) { margin-left: -1px }
    .ea-kindbtn.structural { color: #946 }
    .ea-kindbtn:hover { color: #9bd }
    .ea-kindbtn.on { background: #16263a; color: #bdf; border-color: #468; z-index: 1 }
    .ea-kindbtn.structural.on { background: #2a1226; color: #d9f; border-color: #639 }

    .ea-note {
        font-family: monospace; font-size: 0.66rem; color: #768;
        padding: 0.1rem 0.2rem 0.1rem 2.75rem; line-height: 1.3;
    }

    .ea-fields { gap: 0.5rem; flex-wrap: wrap }
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
