<script lang="ts">
    // StemHive — a "button-hive" view of a bunch of similar names.
    //
    //   Feed it a flat list of names (methods, regions, anything) and it factors
    //   out the words they share and lays the rest out around them, so the eye can
    //   read the Venn-ness of a family of names at a glance:
    //
    //       [log_]
    //       [Tyranny_of_]   Idvoyage   [_verify]
    //                                  [_generate]
    //                                  [_arrange]
    //
    //   The shared stem (Idvoyage) is written ONCE as a central spine.  Each member
    //   contributes only its distinctive part — the prefix to the LEFT, the suffix
    //   to the RIGHT — as a bracketed button.  Where a member's affix is itself one
    //   of the names in the list, that part nests as its own button:
    //
    //       [ [Tyranny] _of_ ]   Idvoyage
    //
    //   ── How it clusters ──────────────────────────────────────────────────────
    //   Names are tokenised on `_` and on CamelCase boundaries (Tyranny|of|Idvoyage,
    //   log|Idvoyage, …).  Greedy: the most-shared stem across the remaining names
    //   becomes the next cluster's anchor; every name carrying it joins, aligned on
    //   that stem; the rest recurse.  A name with no shared stem stands alone.  Each
    //   name lands in exactly ONE cluster, so nothing is duplicated and source order
    //   is preserved (clusters sort by their earliest member).
    //
    //   ── Reusable ─────────────────────────────────────────────────────────────
    //   Knows nothing about Lang/Mapulen.  Props are plain:
    //     items   : { id, label }[]   — id is whatever the caller navigates by
    //     pointed : Set<id>           — ids to highlight (kept separate from items
    //                                   so toggling a highlight never re-clusters)
    //     onpick  : (id) => void      — fired when a name (or nested name) is picked
    //
    //   Layout is a flex spine per cluster, not absolute positioning — the anchor
    //   column lines up by being the one fixed-order flex child, so the affixes fan
    //   off it without us computing pixel offsets.

    let {
        items,
        pointed = new Set<string>(),
        styles  = new Map<string, string>(),
        onpick,
        title = '',
    }: {
        items:    { id: string, label: string }[]
        pointed?: Set<string>
        // id → inline style string (the minimap's heat box-shadow), applied per
        // button so the hive carries the same trail glow as the strip.  Kept apart
        // from items so a heat tick never re-clusters.
        styles?:  Map<string, string>
        onpick?:  (id: string) => void
        title?:   string
    } = $props()

    // ── tokenise ──────────────────────────────────────────────────────────────
    //   Stems with their char offsets, so a name can be sliced into prefix|anchor|
    //   suffix around any one stem and the original separators survive.  The regex
    //   matches: a run of caps that is NOT the start of a CamelCase word (an acronym
    //   like HTML), a CamelCase word, a lowercase run, or a digit run.  `_` and other
    //   punctuation match nothing, so they read as separators between tokens.
    type Tok = { text: string, start: number, end: number }
    const TOKEN = /[A-Z]+(?![a-z])|[A-Z][a-z]+|[a-z]+|[0-9]+/g
    function tokenise(name: string): Tok[] {
        const out: Tok[] = []
        let m: RegExpExecArray | null
        TOKEN.lastIndex = 0
        while ((m = TOKEN.exec(name))) out.push({ text: m[0], start: m.index, end: m.index + m[0].length })
        return out
    }

    type Member = {
        id:     string
        label:  string
        prefix: string   // text before the anchor stem (carries its trailing _)
        suffix: string   // text after the anchor stem (carries its leading _)
        bare:   boolean  // the whole name IS the anchor (no affix either side)
    }
    type Cluster = {
        anchor:  string      // the shared stem, displayed once
        members: Member[]
        order:   number      // earliest source index, for stable cluster ordering
    }

    // label (lowercased) → id, so an affix token that happens to be another name in
    // the list can nest as its own button.  First wins on a collision.
    let label_to_id = $derived.by(() => {
        const m = new Map<string, string>()
        for (const it of items) {
            const k = it.label.toLowerCase()
            if (!m.has(k)) m.set(k, it.id)
        }
        return m
    })

    let clusters = $derived.by<Cluster[]>(() => {
        const toks = new Map<string, Tok[]>()
        items.forEach(it => toks.set(it.id, tokenise(it.label)))
        const index = new Map<string, number>()
        items.forEach((it, i) => index.set(it.id, i))

        let remaining = [...items]
        const out: Cluster[] = []

        while (remaining.length) {
            // frequency of each stem across the remaining names, counted once per name
            const freq = new Map<string, number>()
            for (const it of remaining) {
                const seen = new Set<string>()
                for (const t of toks.get(it.id)!) {
                    const k = t.text.toLowerCase()
                    if (seen.has(k)) continue
                    seen.add(k)
                    freq.set(k, (freq.get(k) ?? 0) + 1)
                }
            }
            // most-shared stem; ties break toward the earliest-appearing stem so the
            // pick is deterministic (Map iteration is insertion order).
            let best = '', bestN = 1
            for (const [k, n] of freq) if (n > bestN) { best = k; bestN = n }

            if (!best) {
                // nothing shared left — each remaining name is its own bare cluster
                for (const it of remaining) {
                    out.push({
                        anchor: it.label,
                        members: [{ id: it.id, label: it.label, prefix: '', suffix: '', bare: true }],
                        order: index.get(it.id)!,
                    })
                }
                break
            }

            const members: Member[] = []
            const rest: typeof remaining = []
            let anchor_text = best
            let order = Infinity
            for (const it of remaining) {
                const ts  = toks.get(it.id)!
                const idx = ts.findIndex(t => t.text.toLowerCase() === best)
                if (idx < 0) { rest.push(it); continue }
                const t = ts[idx]
                anchor_text = t.text          // adopt a member's actual casing
                order = Math.min(order, index.get(it.id)!)
                const prefix = it.label.slice(0, t.start)
                const suffix = it.label.slice(t.end)
                members.push({
                    id: it.id, label: it.label, prefix, suffix,
                    bare: prefix === '' && suffix === '',
                })
            }
            out.push({ anchor: anchor_text, members, order })
            remaining = rest
        }

        out.sort((a, b) => a.order - b.order)
        return out
    })

    // An affix string → render parts: a token that matches another name in the list
    // becomes a nested button (linkId set); separators and non-matching tokens are
    // plain text.  selfId guards a name from linking to itself.
    type Part = { text: string, linkId?: string }
    function parts(str: string, selfId: string): Part[] {
        if (!str) return []
        const ts  = tokenise(str)
        const out: Part[] = []
        let cursor = 0
        for (const t of ts) {
            if (t.start > cursor) out.push({ text: str.slice(cursor, t.start) })
            const id = label_to_id.get(t.text.toLowerCase())
            out.push({ text: t.text, linkId: id && id !== selfId ? id : undefined })
            cursor = t.end
        }
        if (cursor < str.length) out.push({ text: str.slice(cursor) })
        return out
    }

    function pick(id: string) { onpick?.(id) }

    // The left-hanging list holds every member with a prefix — prefix-only members
    // show just their prefix (log_), members that vary on BOTH sides show their whole
    // name (claim_Idzeug_number) rather than a split [claim_]Idzeug[_number] bit.
    // Suffix-only members fan inline to the right of the stem.  The bare member (the
    // method that IS the anchor) makes the stem itself clickable.
    function left_members(c: Cluster)   { return c.members.filter(m => m.prefix) }
    function suffix_members(c: Cluster)  { return c.members.filter(m => m.suffix && !m.prefix) }
    function bare_member(c: Cluster)     { return c.members.find(m => m.bare) }
    function left_text(m: Member): string { return m.suffix ? m.label : m.prefix }
</script>

<div class="hive">
    {#if title}<div class="hive-title">{title}</div>{/if}

    {#each clusters as c (c.anchor + ':' + c.order)}
        <div class="hive-cluster">
            <!-- prefixes as a short list hanging above-and-left of the stem, so they
                 read as folded in over it -->
            {#if left_members(c).length}
                <div class="hive-prefixes">
                    {#each left_members(c) as m (m.id)}
                        <button class="hive-btn hive-pre"
                                class:hive-pointed={pointed.has(m.id)}
                                style={styles.get(m.id) ?? ''}
                                title={m.label}
                                onclick={() => pick(m.id)}>{#each parts(left_text(m), m.id) as p}{#if p.linkId}<span
                                        class="hive-nest" role="button" tabindex="0"
                                        title={p.text}
                                        onclick={(e) => { e.stopPropagation(); pick(p.linkId!) }}>{p.text}</span>{:else}{p.text}{/if}{/each}</button>
                    {/each}
                </div>
            {/if}

            <div class="hive-spine">
                <!-- the shared stem, written once; clickable when a method IS it -->
                {#if bare_member(c)}
                    {@const bm = bare_member(c)}
                    <button class="hive-anchor hive-anchor-real"
                            class:hive-pointed={pointed.has(bm!.id)}
                            style={styles.get(bm!.id) ?? ''}
                            title={bm!.label}
                            onclick={() => pick(bm!.id)}>{c.anchor}</button>
                {:else}
                    <span class="hive-anchor">{c.anchor}</span>
                {/if}

                <!-- suffixes fan inline to the right of the stem -->
                {#if suffix_members(c).length}
                    <div class="hive-suffixes">
                        {#each suffix_members(c) as m (m.id)}
                            <button class="hive-btn hive-suf"
                                    class:hive-pointed={pointed.has(m.id)}
                                    style={styles.get(m.id) ?? ''}
                                    title={m.label}
                                    onclick={() => pick(m.id)}>{#each parts(m.suffix, m.id) as p}{#if p.linkId}<span
                                            class="hive-nest" role="button" tabindex="0"
                                            title={p.text}
                                            onclick={(e) => { e.stopPropagation(); pick(p.linkId!) }}>{p.text}</span>{:else}{p.text}{/if}{/each}</button>
                        {/each}
                    </div>
                {/if}
            </div>
        </div>
    {/each}
</div>

<style>
    .hive {
        display: flex;
        flex-direction: column;
        gap: 6px;
        padding: 4px 4px 10px;
        font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
        font-size: 11px;                  /* slightly bigger than the strip's 8px chips */
        color: #aab;
    }
    .hive-title {
        font-size: 8px;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        color: #778;
        padding-left: 2px;
    }

    /* one cluster: a short prefix list hanging above, then the stem spine */
    .hive-cluster {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        border-left: 2px solid hsla(210, 50%, 55%, 0.25);
        padding: 3px 0 3px 4px;
        margin-bottom: 2px;
    }

    /* the short left-side list — stacked, sitting up-and-left of the stem so the
       variants read as folded in over it.  The spine's left indent puts the stem
       to the lower-right of this list. */
    .hive-prefixes {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 2px;
        margin-bottom: 1px;
    }

    /* the stem spine: ANCHOR with suffixes fanning inline to its right */
    .hive-spine {
        display: flex;
        align-items: center;
        gap: 4px;
        padding-left: 12px;               /* indent so the prefix list hangs to its left */
    }
    .hive-suffixes {
        display: flex;
        flex-wrap: wrap;
        gap: 3px;
    }

    .hive-anchor {
        font-weight: 600;
        color: #d7e2f0;
        padding: 0 2px;
        white-space: nowrap;
    }

    .hive-btn, .hive-anchor-real {
        font: inherit;
        background: rgba(120, 140, 180, 0.10);
        color: #b9c4d4;
        border: 1px solid hsla(210, 40%, 60%, 0.22);
        border-radius: 3px;
        padding: 1px 3px;
        cursor: pointer;
        white-space: nowrap;
        transition: background 0.1s, color 0.1s, border-color 0.1s;
    }
    .hive-btn:hover, .hive-anchor-real:hover {
        background: rgba(150, 180, 230, 0.22);
        color: #eef3fa;
        border-color: hsla(210, 60%, 70%, 0.5);
    }
    .hive-anchor-real { border-style: dashed; }

    /* nested name-button living inside an affix (a sub-stem that is itself a method) */
    .hive-nest {
        font: inherit;
        background: hsla(280, 45%, 55%, 0.18);
        color: #d6c6ec;
        border: 1px solid hsla(280, 50%, 65%, 0.4);
        border-radius: 2px;
        padding: 0 1px;
        margin: 0 1px;
        cursor: pointer;
    }
    .hive-nest:hover {
        background: hsla(280, 55%, 60%, 0.34);
        color: #f1e8ff;
    }

    /* working-Point highlight — matches the minimap's amber pointedat (lit + enlarged) */
    .hive-pointed {
        color: #ffd86b !important;
        border-color: rgba(255, 200, 80, 0.6) !important;
        background: rgba(255, 200, 80, 0.12) !important;
        font-weight: 700;
        font-size: 1.2em;
    }
</style>
