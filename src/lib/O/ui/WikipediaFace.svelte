<script lang="ts">
    // WikipediaFace — Cell:Wikipedia, "click for a random page" (spec/WikipediaCell_todo.md).
    //  A READER, like every other face: the queue is `%Page` rows under the `%Wikipedia` anchor (n), the
    //   one wearing `shown` is the card, and the only verb is `Sounditron_wiki_roll` (Sounditron.g) — the
    //    fetch, the promote and the top-up all live there and log as 📖.  Reads off H.version like the
    //     Door does; the ghost bumps the anchor when the queue moves.
    //  BECOMING THE BELLY IS THE PRESS (the owner: "click it, get a random Wikipedia page"): the first
    //   time the cell takes the room with nothing shown it rolls on its own; ⟳ rolls again.  The link
    //    to the full article is a separate, later action — a new tab, never an iframe.
    let { n, H } = $props()

    const w = () => n?.c?.up
    const roll = (why: string) => { try { (H as any)?.Sounditron_wiki_roll?.(w(), why) } catch (e) { console.warn('📖⚠ roll threw', e) } }
    const wander = (title: string) => { try { (H as any)?.Sounditron_wiki_wander?.(w(), title) } catch (e) { console.warn('📖⚠ wander threw', e) } }

    // ── the section HTML, made ours.  Wikipedia's parse output is trusted-ish, but it goes in via
    //  {@html}, so it is rebuilt through an ALLOWLIST (unknown tags unwrap to their children, no
    //   attributes survive but the few named here), the furniture is cut (edit links, reference
    //    superscripts, navboxes, hatnotes, empty paragraphs), images get absolute https srcs, and every
    //     link is decided: a /wiki/ article link becomes a WANDER press (data-wander=<title>), a
    //      namespace|anchor link is unwrapped, anything external opens a new tab.
    const KEEP = new Set(['p', 'b', 'i', 'em', 'strong', 'u', 's', 'ul', 'ol', 'li', 'a', 'img', 'br', 'h2', 'h3', 'h4', 'h5', 'blockquote', 'dl', 'dt', 'dd', 'sup', 'sub', 'small', 'cite', 'q', 'code', 'pre', 'table', 'thead', 'tbody', 'tr', 'td', 'th', 'caption', 'figure', 'figcaption', 'div', 'span'])
    const CUT = 'script, style, link, .mw-editsection, sup.reference, .reference, .mw-empty-elt, .navbox, .hatnote, .noprint, .mw-references-wrap, .reflist, .ambox, .metadata, .side-box, .mbox-small, .sistersitebox, .thumbcaption .magnify, .mw-cite-backlink, .noexcerpt, .mw-kartographer-container'
    function ours(html: string): string {
        try {
            const doc = new DOMParser().parseFromString(html, 'text/html')
            for (const el of Array.from(doc.querySelectorAll(CUT))) el.remove()
            const walk = (node: Element) => {
                for (const kid of Array.from(node.children)) {
                    walk(kid)
                    const tag = kid.tagName.toLowerCase()
                    if (!KEEP.has(tag)) { kid.replaceWith(...Array.from(kid.childNodes)); continue }
                    const attrs: Record<string, string> = {}
                    if (tag === 'a') {
                        const href = kid.getAttribute('href') ?? ''
                        const m = /^\/wiki\/([^#?]+)/.exec(href)
                        if (m && !/:/.test(m[1])) { attrs['data-wander'] = decodeURIComponent(m[1]).replace(/_/g, ' '); attrs.href = 'https://en.wikipedia.org' + href }
                        else if (/^(https?:)?\/\//.test(href)) { attrs.href = href.startsWith('//') ? 'https:' + href : href; attrs.target = '_blank'; attrs.rel = 'noopener noreferrer'; attrs.class = 'ext' }
                        else { kid.replaceWith(...Array.from(kid.childNodes)); continue }
                    } else if (tag === 'img') {
                        const src = kid.getAttribute('src') ?? ''
                        if (!/^(https:)?\/\//.test(src)) { kid.remove(); continue }
                        attrs.src = src.startsWith('//') ? 'https:' + src : src
                        attrs.alt = kid.getAttribute('alt') ?? ''
                        attrs.loading = 'lazy'
                    }
                    for (const a of Array.from(kid.attributes)) kid.removeAttribute(a.name)
                    for (const [k, v] of Object.entries(attrs)) kid.setAttribute(k, v)
                }
            }
            walk(doc.body)
            for (const p of Array.from(doc.body.querySelectorAll('p'))) if (!p.textContent?.trim() && !p.querySelector('img')) p.remove()
            return doc.body.innerHTML
        } catch (e) {
            console.warn('📖⚠ section html refused', e)
            return ''
        }
    }
    // the lead's FIRST real paragraph (the owner: "the first paragraph in the article") — section 0 through
    //  the same allowlist, then the first <p> with a sentence in it (the infobox and coordinates come first
    //   in the raw lead; the empty-<p> sweep already dropped the hollow ones).
    function lead_ours(html: string): string {
        const doc = new DOMParser().parseFromString(ours(html), 'text/html')
        for (const p of Array.from(doc.body.querySelectorAll('p'))) if ((p.textContent?.trim().length ?? 0) >= 60) return p.outerHTML
        return ''
    }
    // a click anywhere in the section: a wander link hops, everything else is left to the browser
    function on_click(ev: MouseEvent) {
        const a = (ev.target as Element | null)?.closest?.('a[data-wander]') as HTMLAnchorElement | null
        if (!a) return
        ev.preventDefault()
        wander(a.dataset.wander ?? '')
    }

    let view = $derived.by(() => {
        void H?.version
        const rows: any[] = (n?.o?.({ Page: 1 }) ?? [])
        const shown = rows.find((p) => p.sc.shown) ?? null
        // rebuilt ONCE per page and cached on its .c — H.version ticks every second, DOMParser needn't
        if (shown?.c?.html && shown.c.html_ours === undefined) shown.c.html_ours = ours(String(shown.c.html))
        if (shown?.c?.lead_html && shown.c.lead_ours === undefined) shown.c.lead_ours = lead_ours(String(shown.c.lead_html))
        const html: string = shown?.c?.html_ours ?? ''
        const lead: string = shown?.c?.lead_ours ?? ''
        return {
            page: shown ? { title: String(shown.sc.title ?? ''), url: String(shown.sc.url ?? ''), section: String(shown.sc.section ?? ''), extract: String(shown.sc.extract ?? ''), thumb: shown.sc.thumb ? String(shown.sc.thumb) : null, html, lead } : null,
            rolling: Boolean(n?.c?.rolling),
            big: n?.c?.pose === 'big',
        }
    })

    // auto-roll once when the cell takes the room empty (a bud never fetches — it costs nothing at rest)
    $effect(() => {
        if (view.big && !view.page && !view.rolling) roll('belly')
    })
</script>

<div class="wf" class:big={view.big}>
    {#if !view.big}
        <!-- the bud IS the W (static/Wikipedia-W-visual-balanced.svg, black glyph) — masked, so it wears
             the cell colour instead of ink; Cello handles the press (switcheroo), nothing to do here -->
        <div class="wf-w" title="a random Wikipedia page"></div>
    {:else if view.page}
        <div class="wf-card">
            {#if view.page.thumb}<img class="wf-thumb" src={view.page.thumb} alt="" loading="lazy" />{/if}
            <div class="wf-body">
                <div class="wf-title">{view.page.title}</div>
                {#if view.page.lead}
                    <!-- svelte-ignore a11y_click_events_have_key_events -->
                    <!-- svelte-ignore a11y_no_static_element_interactions -->
                    <div class="wf-lead wf-section-html" onclick={on_click}>{@html view.page.lead}</div>
                {:else if view.page.html && view.page.extract}<p class="wf-lead">{view.page.extract}</p>{/if}
                {#if view.page.html}
                    <!-- {@html} is rebuilt through the allowlist above; the click is delegated to the wander links inside -->
                    <!-- svelte-ignore a11y_click_events_have_key_events -->
                    <!-- svelte-ignore a11y_no_static_element_interactions -->
                    <div class="wf-section-html" onclick={on_click}>{@html view.page.html}</div>
                {:else if view.page.extract}<div class="wf-extract">{view.page.extract}</div>{/if}
                <!-- the verbs ride a STICKY bar at the foot of the scroll (owner: "fixed on the screen all the
                     time") — the section scrolls under it; the reroll is the big one -->
                <div class="wf-row">
                    <a class="wf-link" href={view.page.url} target="_blank" rel="noopener noreferrer">read the article →</a>
                    <button class="wf-roll" onclick={() => roll('press')} disabled={view.rolling} title="another random page">{view.rolling ? '…' : '⟳'}</button>
                </div>
            </div>
        </div>
    {:else}
        <button class="wf-start" onclick={() => roll('press')} disabled={view.rolling}>
            {view.rolling ? '📖 fetching…' : '📖 random Wikipedia page'}
        </button>
    {/if}
</div>

<style>
    .wf {
        display: flex; flex-direction: column; gap: 0.35rem;
        font-family: system-ui, sans-serif; color: #b8c8e8;
        width: 100%; height: 100%; padding: 0.4rem 0.55rem; overflow: hidden; box-sizing: border-box;
    }
    .wf-w {
        width: 62%; aspect-ratio: 2560 / 1980; margin: auto; background: #d6e0fa;
        -webkit-mask: url(/Wikipedia-W-visual-balanced.svg) center / contain no-repeat;
        mask: url(/Wikipedia-W-visual-balanced.svg) center / contain no-repeat;
    }
    .wf-start {
        all: unset; cursor: pointer; text-align: center;
        padding: 0.5rem 0.7rem; border-radius: 0.6rem;
        background: rgba(108, 143, 208, 0.14); border: 1px solid rgba(108, 143, 208, 0.4);
        color: #b8c8e8; font-size: 0.85rem; font-weight: 600;
    }
    .wf-start:hover { background: rgba(108, 143, 208, 0.24); }
    .wf-start:disabled { opacity: 0.6; cursor: default; }
    .wf-card { display: flex; flex-direction: column; gap: 0.3rem; min-height: 0; }
    /* big = the off-edge takeover belly (Cellui TAKEOVER): the mold is the reading room, the face-scroll
       scrolls — so the face flows at natural height and never clips itself. */
    .wf.big { align-items: center; height: auto; overflow: visible; }
    .wf.big .wf-card, .wf.big .wf-start { width: 100%; max-width: 58rem; }
    .wf-thumb {
        width: 100%; max-height: 5.5rem; object-fit: cover; border-radius: 0.4rem;
        border: 1px solid rgba(108, 143, 208, 0.3);
    }
    /* big: the picture floats right and the title + extract wrap around it, magazine-style.
       (-webkit-box line-clamp ignores floats, so the big extract clips by height instead.) */
    .wf.big .wf-card { display: block; }
    .wf.big .wf-thumb { float: right; width: 44%; max-height: 24rem; margin: 0.3rem 0 0.8rem 1.4rem; }
    .wf.big .wf-body { display: block; }
    .wf-body { display: flex; flex-direction: column; gap: 0.2rem; min-height: 0; }
    .wf-title { font-size: 0.88rem; font-weight: 700; color: #d6e0fa; }
    .wf.big .wf-title { font-size: 1.7rem; line-height: 1.2; margin-bottom: 0.6rem; }
    .wf-extract {
        font-size: 0.72rem; line-height: 1.3; color: rgba(184, 200, 232, 0.85);
        display: -webkit-box; -webkit-line-clamp: 4; line-clamp: 4; -webkit-box-orient: vertical; overflow: hidden;
    }
    /* no overflow:hidden here — that makes the extract its own block-formatting context, which sits
       BESIDE a float as a narrowed column instead of wrapping under it once the picture ends. */
    .wf.big .wf-extract { display: block; font-size: 1.15rem; line-height: 1.6; -webkit-line-clamp: unset; line-clamp: unset; overflow: visible; }
    .wf.big .wf-row {
        clear: both; position: sticky; bottom: 0; z-index: 2;
        margin: 0.6rem -0.55rem 0; padding: 0.6rem 0.9rem;
        background: linear-gradient(to top, rgba(14, 20, 32, 0.96) 70%, rgba(14, 20, 32, 0));
        border-top: 1px solid rgba(108, 143, 208, 0.18);
    }
    /* the section body — Wikipedia's structure in our type; the blue underline is the point */
    /* the lead — the article's first paragraph, set apart from the random section under it */
    .wf-lead { font-size: 1.15rem; line-height: 1.6; color: #d6e0fa; margin: 0 0 1.1em; }
    .wf-lead :global(p) { color: #d6e0fa; }
    .wf-section-html { font-size: 1.15rem; line-height: 1.6; color: rgba(184, 200, 232, 0.9); }
    .wf-section-html :global(p) { margin: 0 0 0.8em; }
    .wf-section-html :global(a) { color: #7fb0ff; text-decoration: underline; text-decoration-color: rgba(127, 176, 255, 0.55); text-underline-offset: 2px; cursor: pointer; }
    .wf-section-html :global(a:hover) { color: #a8ccff; text-decoration-color: #a8ccff; }
    .wf-section-html :global(a.ext) { text-decoration-style: dotted; }
    /* the section's own heading leads the body (h2); its sub-headings step down from it */
    .wf-section-html :global(h2) { color: #d6e0fa; font-size: 1.35em; margin: 0 0 0.5em; padding-bottom: 0.2em; border-bottom: 1px solid rgba(108, 143, 208, 0.3); }
    .wf-section-html :global(h3) { color: #d6e0fa; font-size: 1.12em; margin: 1em 0 0.4em; }
    .wf-section-html :global(h4), .wf-section-html :global(h5) { color: #d6e0fa; font-size: 1em; margin: 0.9em 0 0.3em; }
    .wf-section-html :global(ul), .wf-section-html :global(ol) { padding-left: 1.4em; margin: 0 0 0.8em; }
    .wf-section-html :global(blockquote) { border-left: 3px solid rgba(108, 143, 208, 0.4); margin: 0 0 0.8em; padding-left: 0.8em; }
    .wf-section-html :global(img) { max-width: 40%; height: auto; float: right; clear: right; margin: 0.2rem 0 0.6rem 1rem; border-radius: 0.4rem; }
    .wf-section-html :global(figure) { float: right; clear: right; max-width: 40%; margin: 0.2rem 0 0.6rem 1rem; }
    .wf-section-html :global(figure img) { max-width: 100%; float: none; margin: 0; }
    .wf-section-html :global(figcaption) { font-size: 0.75em; color: rgba(184, 200, 232, 0.6); }
    .wf-section-html :global(table) { border-collapse: collapse; font-size: 0.85em; margin: 0 0 0.8em; max-width: 100%; display: block; overflow-x: auto; }
    .wf-section-html :global(td), .wf-section-html :global(th) { border: 1px solid rgba(108, 143, 208, 0.25); padding: 0.2em 0.5em; vertical-align: top; }
    .wf-section-html :global(sup), .wf-section-html :global(sub) { font-size: 0.7em; }
    .wf-row { display: flex; align-items: center; justify-content: space-between; gap: 0.4rem; margin-top: 0.15rem; }
    .wf-link { font-size: 0.68rem; letter-spacing: 0.02em; color: #6c8fd0; text-decoration: none; }
    .wf.big .wf-link { font-size: 1rem; }
    .wf.big .wf-roll {
        font-size: 3.6rem; line-height: 1; font-weight: 400; padding: 0.15rem 0.7rem; border-radius: 1rem;
        background: rgba(108, 143, 208, 0.18); border: 1px solid rgba(108, 143, 208, 0.55); color: #d6e0fa;
    }
    .wf.big .wf-roll:hover { background: rgba(108, 143, 208, 0.32); }
    .wf-link:hover { text-decoration: underline; }
    .wf-roll {
        all: unset; cursor: pointer; line-height: 1; padding: 0.15rem 0.4rem; border-radius: 0.4rem;
        border: 1px solid rgba(108, 143, 208, 0.35); color: #b8c8e8; font-size: 0.85rem;
    }
    .wf-roll:hover { background: rgba(108, 143, 208, 0.18); }
    .wf-roll:disabled { opacity: 0.5; cursor: default; }
</style>
