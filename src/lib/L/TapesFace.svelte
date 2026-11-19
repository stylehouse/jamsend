<script lang="ts">
    // TapesFace — the cursor (Theory.g "The cursor", AtheoryArrive_todo §7): one tab's Atheory compartments as the `tapes` verb says
    //  them — where each stands, what arrived on its tapes (newest last), how often its move ran, and the rows the move decided.  A
    //   plain reader of one answer; asking again is the hole's (`:tapes` here, `:ask tapes --to=<pub>` for another tab).
    let { tapes }: { tapes: { tab?: string, compartments: any[] } } = $props()

    // the path minus the House it's on when that is the tab's own top: A:Radio>A:Arrive>w:Arrive
    const short = (at: string) => at.replace(/^H:[^>]*>/, '')
    // a tape line minus its TheAHeard:<n>,take:<t> lead — the number rides as a superscript
    const line_of = (l: string) => {
        const m = /^TheAHeard(?::(\d+))?,take(?::(\d+))?,?(.*)$/.exec(l)
        return m ? { n: m[1] ?? '1', take: m[2] ?? '1', rest: m[3] } : { n: '', take: '', rest: l }
    }
</script>

<div class="tapes">
    <div class="tab">{tapes.tab || 'a tab'} · {tapes.compartments.length} compartment{tapes.compartments.length === 1 ? '' : 's'}</div>
    {#each tapes.compartments as c (c.at)}
        <div class="c">
            <div class="at">{short(c.at)} <small>{c.at.split('>')[0]} · moved {c.woke}×</small></div>
            {#each c.ios as io (io.io)}
                <div class="io"><b>{io.io}</b> <small>heard {io.heard} · takes {io.takes}</small></div>
                {#each io.last as l}{@const t = line_of(l)}<div class="heard"><span class="n">{t.n}{t.take && t.take !== t.n ? '·' + t.take : ''}</span>{t.rest}</div>{/each}
            {/each}
            {#if c.rows.length}<div class="rows">{#each c.rows as r}<span class="row">{r}</span>{/each}</div>{/if}
        </div>
    {/each}
</div>

<style>
    .tapes { margin-top: 6px; font: 12px/1.45 ui-monospace, monospace; color: #cfe3d8 }
    .tab { font-weight: 600; color: #8fd3b0; margin-bottom: 4px }
    .c { border-left: 2px solid #2f6b55; padding: 3px 0 5px 8px; margin: 4px 0 }
    .at { color: #e6f4ec }
    .at small, .io small { opacity: .55; margin-left: 6px }
    .io { margin-top: 2px; color: #b6dcc8 }
    .heard { padding-left: 12px; white-space: pre-wrap; word-break: break-all; opacity: .85 }
    .n { display: inline-block; min-width: 3.2em; opacity: .45 }
    .rows { display: flex; flex-wrap: wrap; gap: 3px 5px; margin-top: 3px }
    .row { background: #16302a; border: 1px solid #2a5546; border-radius: 4px; padding: 0 5px; word-break: break-all }
</style>
