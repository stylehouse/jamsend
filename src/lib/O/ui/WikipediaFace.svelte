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

    let view = $derived.by(() => {
        void H?.version
        const rows: any[] = (n?.o?.({ Page: 1 }) ?? [])
        const shown = rows.find((p) => p.sc.shown) ?? null
        return {
            page: shown ? { title: String(shown.sc.title ?? ''), url: String(shown.sc.url ?? ''), extract: String(shown.sc.extract ?? ''), thumb: shown.sc.thumb ? String(shown.sc.thumb) : null } : null,
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
                {#if view.page.extract}<div class="wf-extract">{view.page.extract}</div>{/if}
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
    .wf.big .wf-row { clear: both; padding-top: 0.4rem; }
    .wf-row { display: flex; align-items: center; justify-content: space-between; gap: 0.4rem; margin-top: 0.15rem; }
    .wf-link { font-size: 0.68rem; letter-spacing: 0.02em; color: #6c8fd0; text-decoration: none; }
    .wf.big .wf-link { font-size: 1rem; }
    .wf.big .wf-roll { font-size: 1.1rem; padding: 0.3rem 0.7rem; }
    .wf-link:hover { text-decoration: underline; }
    .wf-roll {
        all: unset; cursor: pointer; line-height: 1; padding: 0.15rem 0.4rem; border-radius: 0.4rem;
        border: 1px solid rgba(108, 143, 208, 0.35); color: #b8c8e8; font-size: 0.85rem;
    }
    .wf-roll:hover { background: rgba(108, 143, 208, 0.18); }
    .wf-roll:disabled { opacity: 0.5; cursor: default; }
</style>
