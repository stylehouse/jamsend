<script lang="ts">
    // DocDiff.svelte — minimal line-level diff for the surprise_read conflict view.
    //
    //   Shows the user's pending text (mine) against what is now on disk (theirs)
    //   as a unified add/remove list, theirs → mine:
    //     '-'  a line on disk that mine dropped (their change you'd overwrite)
    //     '+'  a line mine adds (your edit not yet on disk)
    //     ' '  unchanged context
    //
    //   Plain DMP line diff on raw source — unlike H.compute_diff (snap-specialised,
    //   peel-normalised), this treats lines as opaque source text, which is what a
    //   Doc file is.  Long unchanged runs collapse to a single elided marker so the
    //   panel stays scannable.
    import { diff_match_patch } from 'diff-match-patch'

    let { mine, theirs }: { mine: string; theirs: string } = $props()

    type Row = { kind: 'same' | 'add' | 'del' | 'elide'; line?: string; count?: number }

    const CONTEXT = 3   // unchanged lines kept around each change before eliding

    let rows = $derived.by((): Row[] => {
        const dmp = new diff_match_patch()
        // diff_linesToChars_/diff_charsToLines_ are the lib's line-mode helpers,
        //  exposed only off the instance — cast as Text.svelte's compute_diff does.
        const enc = (dmp as any).diff_linesToChars_(theirs ?? '', mine ?? '')
        const raw = dmp.diff_main(enc.chars1, enc.chars2, false)
        ;(dmp as any).diff_charsToLines_(raw, enc.lineArray)

        const flat: Row[] = []
        for (const [op, text] of raw as [number, string][]) {
            const lines = text.split('\n')
            if (lines[lines.length - 1] === '') lines.pop()   // trailing newline isn't a line
            for (const line of lines)
                flat.push({ kind: op === 0 ? 'same' : op === 1 ? 'add' : 'del', line })
        }

        // Collapse runs of unchanged lines that are >2·CONTEXT away from any change.
        const keep = new Array(flat.length).fill(false)
        for (let i = 0; i < flat.length; i++) {
            if (flat[i].kind === 'same') continue
            for (let j = Math.max(0, i - CONTEXT); j <= Math.min(flat.length - 1, i + CONTEXT); j++)
                keep[j] = true
        }
        const out: Row[] = []
        let run = 0
        for (let i = 0; i < flat.length; i++) {
            if (flat[i].kind !== 'same' || keep[i]) {
                if (run) { out.push({ kind: 'elide', count: run }); run = 0 }
                out.push(flat[i])
            } else run++
        }
        if (run) out.push({ kind: 'elide', count: run })
        return out
    })
</script>

<div class="dd-diff">
    {#each rows as r}
        {#if r.kind === 'elide'}
            <div class="dd-line dd-elide">⋯ {r.count} unchanged line{r.count === 1 ? '' : 's'}</div>
        {:else}
            <div class="dd-line dd-{r.kind}"><span class="dd-gut">{r.kind === 'add' ? '+' : r.kind === 'del' ? '-' : ' '}</span>{r.line}</div>
        {/if}
    {/each}
</div>

<style>
    .dd-diff {
        max-height: 14rem; overflow: auto;
        font-family: monospace; font-size: 0.7rem; line-height: 1.35;
        background: #0b0b10; border: 1px solid #1c1c28; border-radius: 3px;
        padding: 0.2rem 0; margin-top: 0.25rem;
    }
    .dd-line {
        white-space: pre; padding: 0 0.4rem;
    }
    .dd-gut { display: inline-block; width: 1ch; color: #556; user-select: none; }
    .dd-same  { color: #778; }
    .dd-add   { color: #7c9; background: #0e1a10; }
    .dd-add .dd-gut { color: #6a9; }
    .dd-del   { color: #c87; background: #1a0e0e; }
    .dd-del .dd-gut { color: #c66; }
    .dd-elide { color: #445; font-style: italic; padding: 0 0.4rem; }
</style>
