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
        tips    = new Map<string, string>(),
        onpick,
        title = '',
    }: {
        items:    { id: string, label: string }[]
        pointed?: Set<string>
        // id → inline style string (the minimap's heat box-shadow), applied per
        // button so the hive carries the same trail glow as the strip.  Kept apart
        // from items so a heat tick never re-clusters.
        styles?:  Map<string, string>
        // id → hover-tooltip text (native title, so \n splits lines).  Falls back
        // to the label when an id has no tip.  Like styles, kept out of items so a
        // tip change never re-clusters.
        tips?:    Map<string, string>
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

    // char span of the contiguous token-run `key` (len tokens long) within ts, or null
    const RUN_SEP = ''
    // The run must sit at the name's START or END so the split is a clean prefix or
    // suffix, never an awkward interior stem (…trustclaim_Idzeug_number…).  start is
    // preferred, then end; an interior-only occurrence returns null (name won't join).
    function key_of(ts: Tok[], i: number, len: number): string {
        return ts.slice(i, i + len).map(t => t.text.toLowerCase()).join(RUN_SEP)
    }
    function run_span(ts: Tok[], key: string, len: number): { start: number, end: number } | null {
        if (len > ts.length) return null
        if (key_of(ts, 0, len) === key)          return { start: ts[0].start, end: ts[len - 1].end }
        const e = ts.length - len
        if (e > 0 && key_of(ts, e, len) === key) return { start: ts[e].start, end: ts[ts.length - 1].end }
        return null
    }

    // Names cluster ONLY IN SOURCE ORDER: a cluster is a maximal run of ADJACENT names
    //  sharing one edge-anchored stem.  Walking left→right and never reaching over an
    //  intervening name keeps the hive's vertical order identical to the file's — so a
    //  stem's scattered occurrences stay put instead of being dragged together, and the
    //  viewport puck (which spans the on-screen chips top→bottom) stays tight.
    let clusters = $derived.by<Cluster[]>(() => {
        const n = items.length
        if (!n) return []

        // per name: its edge-anchored token-runs (anchored at the name's START or END
        //  only, never an awkward interior stem) keyed lowercased → token length.  An
        //  intersection of these sets across a run of names is exactly the stems they
        //  ALL share, and the length lets us anchor on the longest.
        const runs = items.map(it => {
            const ts = tokenise(it.label)
            const set = new Map<string, number>()
            for (let len = 1; len <= ts.length; len++) {
                const ks = key_of(ts, 0, len)
                if (!set.has(ks)) set.set(ks, len)
                const e = ts.length - len
                if (e > 0) { const ke = key_of(ts, e, len); if (!set.has(ke)) set.set(ke, len) }
            }
            return set
        })

        const out: Cluster[] = []
        let i = 0
        while (i < n) {
            // grow the contiguous run [i..j] while SOME stem stays shared by all of it;
            //  the moment the next name shares nothing, the run ends at j.
            let shared = new Map(runs[i])
            let j = i
            while (j + 1 < n) {
                const next = new Map<string, number>()
                for (const [k, len] of shared) if (runs[j + 1].has(k)) next.set(k, len)
                if (next.size === 0) break
                shared = next
                j++
            }
            // anchor on the LONGEST surviving stem — Idzeugi_advice beats bare Idzeugi.
            //  A lone name keeps its whole self (its longest run) as the anchor and so
            //  renders bare, exactly as a singleton should.
            let bestKey = '', bestTokens = 0
            for (const [k, len] of shared) if (len > bestTokens) { bestKey = k; bestTokens = len }

            const members: Member[] = []
            let anchor_text = ''
            for (let m = i; m <= j; m++) {
                const it   = items[m]
                const ts   = tokenise(it.label)
                const span = run_span(ts, bestKey, bestTokens)
                // bestKey is in `shared`, so every member carries it — but a stem string
                //  can be ambiguous under the empty join, so fall back to bare if the
                //  slice doesn't line up rather than dropping the chip.
                if (!span) {
                    members.push({ id: it.id, label: it.label, prefix: '', suffix: '', bare: true })
                    continue
                }
                const prefix = it.label.slice(0, span.start)
                const suffix = it.label.slice(span.end)
                // first member's slice keeps the anchor's real casing + inner separators
                if (!anchor_text) anchor_text = it.label.slice(span.start, span.end)
                members.push({
                    id: it.id, label: it.label, prefix, suffix,
                    bare: prefix === '' && suffix === '',
                })
            }
            out.push({ anchor: anchor_text || items[i].label, members, order: i })
            i = j + 1
        }
        return out
    })

    // Walk the clusters in source order and bucket runs of consecutive singletons
    // (lone names, nothing shared) into one compact wrap each — so a singleton keeps
    // its place in the list rather than being dragged to the end, while still
    // stacking tightly instead of spawning a padded cluster box.
    type Row = { kind: 'cluster', cluster: Cluster } | { kind: 'singles', items: Member[] }
    function is_single(c: Cluster) { return c.members.length === 1 && c.members[0].bare }
    let rows = $derived.by<Row[]>(() => {
        const out: Row[] = []
        let bucket: Member[] | null = null
        for (const c of clusters) {
            if (is_single(c)) {
                if (!bucket) { bucket = []; out.push({ kind: 'singles', items: bucket }) }
                bucket.push(c.members[0])
            } else {
                bucket = null
                out.push({ kind: 'cluster', cluster: c })
            }
        }
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

    // With edge-only runs a member is cleanly one-sided: a prefix member clings on the
    // LEFT (its distinctive part precedes the stem), a suffix member clings on the RIGHT.
    // The bare member (the name that IS the stem) makes the stem itself clickable.
    function left_members(c: Cluster)   { return c.members.filter(m => m.prefix) }
    function suffix_members(c: Cluster)  { return c.members.filter(m => m.suffix && !m.prefix) }
    function bare_member(c: Cluster)     { return c.members.find(m => m.bare) }
</script>

<!-- one leaf button — plain text (no nested sub-buttons inside a leaf; a sub-stem that
     is itself a name shows as its own standalone single instead) -->
{#snippet leaf(m: Member, text: string, cls: string)}
    <button class="hive-btn {cls}"
            class:hive-pointed={pointed.has(m.id)}
            data-mid={m.id}
            style={styles.get(m.id) ?? ''}
            title={tips.get(m.id) ?? m.label}
            onclick={() => pick(m.id)}>{text}</button>
{/snippet}

<!-- the shared stem, written once; clickable when a name IS it, else a span whose
     sub-stems still link out when they are names themselves -->
{#snippet stem(c: Cluster, bm: Member | undefined)}
    {#if bm}
        <button class="hive-anchor hive-anchor-real"
                class:hive-pointed={pointed.has(bm.id)}
                data-mid={bm.id}
                style={styles.get(bm.id) ?? ''}
                title={tips.get(bm.id) ?? bm.label}
                onclick={() => pick(bm.id)}>{c.anchor}</button>
    {:else}
        <span class="hive-anchor">{#each parts(c.anchor, '') as p}{#if p.linkId}<span
                    class="hive-nest" role="button" tabindex="0"
                    title={p.text}
                    onclick={(e) => { e.stopPropagation(); pick(p.linkId!) }}>{p.text}</span>{:else}{p.text}{/if}{/each}</span>
    {/if}
{/snippet}

<div class="hive">
    {#if title}<div class="hive-title">{title}</div>{/if}

    {#each rows as row, ri (ri)}
        {#if row.kind === 'cluster'}
            {@const c     = row.cluster}
            {@const lefts = left_members(c)}
            {@const sufs  = suffix_members(c)}
            {@const bm    = bare_member(c)}
            <div class="hive-cluster">
                {#if lefts.length && sufs.length}
                    <!-- both sides cling → left-leaning prefixes up-left; the stem is
                         absolutely anchored to the right column's left edge (the spot just
                         left of the right leaves) and positioned rightward from there, low
                         near the bottom leaf — so its place is set by the right leaves, not
                         by how wide the left column happens to be. -->
                    <div class="hive-row hive-both">
                        <div class="hive-col hive-leftcol">
                            {#each lefts as m (m.id)}{@render leaf(m, m.prefix, 'hive-pre')}{/each}
                        </div>
                        <div class="hive-col hive-rightcol">
                            {@render stem(c, bm)}
                            {#each sufs as m (m.id)}{@render leaf(m, m.suffix, 'hive-suf')}{/each}
                        </div>
                    </div>
                {:else if lefts.length}
                    <!-- leaves only on the left → stem beside them on the right -->
                    <div class="hive-row hive-leftonly">
                        <div class="hive-col hive-leftcol">
                            {#each lefts as m (m.id)}{@render leaf(m, m.prefix, 'hive-pre')}{/each}
                        </div>
                        {@render stem(c, bm)}
                    </div>
                {:else if sufs.length}
                    <!-- leaves only on the right → stem beside them on the left -->
                    <div class="hive-row hive-rightonly">
                        {@render stem(c, bm)}
                        <div class="hive-col hive-rightcol">
                            {#each sufs as m (m.id)}{@render leaf(m, m.suffix, 'hive-suf')}{/each}
                        </div>
                    </div>
                {:else}
                    {@render stem(c, bm)}
                {/if}
            </div>
        {:else}
            <!-- a run of lone names: no cluster box, just a tight wrapped stack in place -->
            <div class="hive-singles">
                {#each row.items as m (m.id)}{@render leaf(m, m.label, 'hive-single')}{/each}
            </div>
        {/if}
    {/each}
</div>

<style>
    .hive {
        display: flex;
        flex-direction: column;
        align-items: flex-start;          /* cells size to their content, not full width */
        gap: 1px;
        padding: 1px 4px 4px;
        font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
        font-size: 11px;                  /* slightly bigger than the strip's 8px chips */
        line-height: 1.1;                 /* tight — vertical space is at a premium */
        color: #aab;
    }
    .hive-title {
        font-size: 8px;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        color: #778;
        padding-left: 2px;
    }

    /* one cluster: a flex spine.  The stem's horizontal place signals where leaves
       cling — prefixes-only put it on the right of them, suffixes-only on the left,
       both put it in the middle.  Columns auto-size, so no pixel maths or overlap. */
    /* the rounded cell around a stemmed cluster.  A min-width keeps a narrow cluster
       (1 left, 2 right) from reading as a skinny sliver; a short left leaf just leaves
       slack inside, never overlapping. */
    .hive-cluster {
        min-width: 184px;
        border: 1px solid hsla(210, 45%, 58%, 0.30);
        border-radius: 9px;
        padding: 0 8px 0 6px;
        margin-right: 10px;   /* mirror the left breathing room; also room for the heat halo */
    }
    .hive-row { display: flex; gap: 6px; }
    .hive-col { display: flex; flex-direction: column; align-items: flex-start; gap: 1px; }

    /* both-sided spines get a wider channel between the columns so the stem reads as a
       centred spine rather than crowding the right leaves */
    .hive-both { gap: 20px; }

    /* both sides: prefixes left-leaning up-left.  The right column is the positioning
       context; the stem is absolutely anchored to its LEFT edge (the spot just left of
       the right leaves) via right:100%, then dialled rightward from there by STEM_NUDGE,
       and dropped to near the bottom leaf by STEM_RISE.  Its horizontal place is thus set
       by the right leaves, independent of the left column's width. */
    .hive-both { align-items: flex-start; }
    /* a standard-width left zone: pushes the right leaves across to a consistent x and
       leaves room for the one or two short left leaves to sit left of the indented stem */
    .hive-both .hive-leftcol { min-width: 82px; }
    .hive-both .hive-rightcol { position: relative; }
    .hive-both .hive-rightcol .hive-anchor {
        position: absolute;
        right: calc(100% + 5px);   /* 100% = the right leaves' left edge; +5px sits in the channel just left of it */
        bottom: 3px;               /* near, but a touch above, the bottom leaf */
        white-space: nowrap;
    }

    /* one-sided: the stem sits centred beside the single stack */
    .hive-leftonly  { align-items: center; }
    .hive-rightonly { align-items: center; }

    /* lone names — a tight wrapped stack, no cluster chrome or padding */
    .hive-singles {
        display: flex;
        flex-wrap: wrap;
        gap: 1px 4px;
        padding: 1px 0 1px 4px;
    }

    .hive-anchor {
        font-weight: 600;
        color: #d7e2f0;
        padding: 0 2px;
        white-space: nowrap;
    }

    .hive-btn, .hive-anchor-real {
        font: inherit;
        line-height: 1.15;
        background: rgba(120, 140, 180, 0.10);
        color: #d7e2f0;
        border: 1px solid hsla(210, 40%, 60%, 0.22);
        border-radius: 3px;
        padding: 0 3px;
        cursor: pointer;
        white-space: nowrap;
        transition: background 0.1s, color 0.1s, border-color 0.1s;
    }
    .hive-btn:hover, .hive-anchor-real:hover {
        background: rgba(150, 180, 230, 0.22);
        border-color: hsla(210, 60%, 70%, 0.5);
    }
    /* the method text wears the legacy minimap's pink; the stem/spine stays neutral */
    .hive-btn       { color: rgba(225, 195, 245, 0.88); }
    .hive-btn:hover { color: #efdcff; }
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
