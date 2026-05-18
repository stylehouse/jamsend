<script lang="ts">
    // EncodingSplatter.svelte — per-Waft diagnostic panel for encode/decode errors.
    //
    // Shows complaints from Text.svelte's enWaft / deWaft:
    //   mung_error    — decode complaint: an object-valued sc key was skipped on load.
    //   encode_error  — encode complaint: unknown mainkey, or a mainkey with object sc,
    //                   surfaced by Lies_waft_save before aborting the write.
    //
    // Errors are grouped by mainkey, parsed out of the message string.
    // Each group has:
    //   - the raw messages
    //   - a "copy lematch" button: copies a WAFT_PROTOCOL entry to the clipboard
    //     that the dev can paste into Text.svelte to mute this mainkey permanently.
    //   - a session-only mute toggle (visual only — does not yet feed back into enWaft).
    //     < future: pass muted set to Lies_waft_save so it is forwarded to enWaft.
    //
    // Lematch snippet shape (for a skip rule):
    //   { matching_any: [{ mk: 'doc_rename_job' }], means: { skip: true } }
    //
    // Lematch snippet shape (for a mung/property rule):
    //   { matching_any: [{ mk: 'self' }], means: { omit_sc: { age: 1 } } }
    //
    // Props:
    //   waft — the Waft TheC particle (holds mung_error and encode_error children)

    import type { TheC } from '$lib/data/Stuff.svelte'

    let { waft }: { waft: TheC } = $props()

    // ── reactive error lists — both types live on waft directly ──────
    let mung_errors   = $derived((() => { void waft.version; return waft.o({ mung_error:   1 }) as TheC[] })())
    let encode_errors = $derived((() => { void waft.version; return waft.o({ encode_error: 1 }) as TheC[] })())
    let all_errors    = $derived([...mung_errors, ...encode_errors])

    // Session-only muted mainkeys.  Does not feed back to enWaft yet.
    let muted: Set<string> = $state(new Set())

    // ── error parsing ─────────────────────────────────────────────────
    //
    // enWaft / deWaft produce messages of the shape:
    //   "mung keys [age, foo] at depth 3 — path: Waft:Ghost/Tour > Doc:1 > self:1"
    //   "unknown mainkey 'doc_rename_job' at depth 2"
    //   "mung keys [x] at depth 2 — path: Waft:Ghost/Tour > mything:1"
    //
    // We extract:
    //   kind    — 'mung' | 'unknown' | 'other'
    //   mainkey — best guess at the offending mainkey
    //   props   — munged property names (for mung errors)

    type ParsedError = {
        raw:     string
        kind:    'mung' | 'unknown' | 'other'
        mainkey: string
        props:   string[]    // property names involved (mung only)
    }

    function parse_error(msg: string): ParsedError {
        // unknown mainkey: "unknown mainkey 'doc_rename_job' at depth N"
        const unknown_m = msg.match(/unknown mainkey ['"]?(\w+)['"]?/i)
        if (unknown_m) return { raw: msg, kind: 'unknown', mainkey: unknown_m[1], props: [] }

        // mung keys: "mung keys [age, foo] at depth N — path: ... > mainkey:1"
        const mung_m = msg.match(/mung keys \[([^\]]+)\]/)
        if (mung_m) {
            const props   = mung_m[1].split(',').map(s => s.trim()).filter(Boolean)
            // Extract mainkey from the path tail: "... > self:1" → "self"
            const path_m  = msg.match(/>\s*(\w+)[:\s]/)
            const mainkey = path_m ? path_m[1] : 'unknown'
            return { raw: msg, kind: 'mung', mainkey, props }
        }

        return { raw: msg, kind: 'other', mainkey: 'unknown', props: [] }
    }

    // ── group by mainkey ──────────────────────────────────────────────
    type Group = {
        mainkey: string
        kind:    'mung' | 'unknown' | 'other'
        errors:  ParsedError[]
        // union of all prop names seen for this mainkey
        props:   string[]
    }

    let groups = $derived.by((): Group[] => {
        const map = new Map<string, Group>()
        for (const err of all_errors) {
            const p = parse_error(err.sc.msg as string ?? '')
            const key = p.mainkey
            if (!map.has(key)) map.set(key, { mainkey: key, kind: p.kind, errors: [], props: [] })
            const g = map.get(key)!
            g.errors.push(p)
            for (const prop of p.props) {
                if (!g.props.includes(prop)) g.props.push(prop)
            }
        }
        return [...map.values()]
    })

    // ── lematch snippet generation ────────────────────────────────────

    function skip_snippet(mainkey: string): string {
        return `{ matching_any: [{ mk: '${mainkey}' }], means: { skip: true } }`
    }

    function omit_snippet(mainkey: string, props: string[]): string {
        const omit = props.map(p => `${p}: 1`).join(', ')
        return `{ matching_any: [{ mk: '${mainkey}' }], means: { omit_sc: { ${omit} } } }`
    }

    async function copy(text: string) {
        try {
            await navigator.clipboard.writeText(text)
        } catch {
            // fallback: select a hidden textarea
            const ta = document.createElement('textarea')
            ta.value = text
            document.body.appendChild(ta)
            ta.select()
            document.execCommand('copy')
            document.body.removeChild(ta)
        }
        recently_copied = text
        setTimeout(() => { if (recently_copied === text) recently_copied = '' }, 1400)
    }

    let recently_copied = $state('')
</script>

{#if groups.length}
<div class="sp">
    <div class="sp-hdr">
        <span class="sp-title">⛔ waft encode errors</span>
        <span class="sp-sub">{all_errors.length} complaint{all_errors.length === 1 ? '' : 's'}, {groups.length} type{groups.length === 1 ? '' : 's'}</span>
    </div>

    {#each groups as g (g.mainkey)}
        {@const is_muted = muted.has(g.mainkey)}
        <div class="sp-group" class:sp-group-muted={is_muted}>
            <div class="sp-group-hdr">
                <!-- mainkey badge -->
                <span class="sp-mk" class:sp-mk-muted={is_muted}>{g.mainkey}</span>
                <span class="sp-kind sp-kind-{g.kind}">{g.kind}</span>
                <span class="sp-count">{g.errors.length}×</span>
                <span class="sp-spacer"></span>

                <!-- copy skip rule -->
                <button class="sp-btn sp-btn-copy"
                        title="copy WAFT_PROTOCOL skip rule to clipboard"
                        onclick={() => copy(skip_snippet(g.mainkey))}>
                    {recently_copied === skip_snippet(g.mainkey) ? '✓ copied' : 'copy skip'}
                </button>

                <!-- copy omit rule (only for mung — has specific props) -->
                {#if g.kind === 'mung' && g.props.length}
                    <button class="sp-btn sp-btn-copy"
                            title="copy WAFT_PROTOCOL omit rule for {g.props.join(', ')}"
                            onclick={() => copy(omit_snippet(g.mainkey, g.props))}>
                        {recently_copied === omit_snippet(g.mainkey, g.props) ? '✓ copied' : `copy omit [${g.props.join(', ')}]`}
                    </button>
                {/if}

                <!-- session mute toggle -->
                <button class="sp-btn sp-btn-mute" class:sp-btn-muted={is_muted}
                        title={is_muted ? 'un-mute' : 'mute this session (visual only)'}
                        onclick={() => { const m = new Set(muted); is_muted ? m.delete(g.mainkey) : m.add(g.mainkey); muted = m }}>
                    {is_muted ? 'un-mute' : 'mute'}
                </button>
            </div>

            {#if !is_muted}
                <div class="sp-msgs">
                    {#each g.errors.slice(0, 3) as pe}
                        <div class="sp-msg">{pe.raw}</div>
                    {/each}
                    {#if g.errors.length > 3}
                        <div class="sp-msg sp-msg-more">…and {g.errors.length - 3} more</div>
                    {/if}
                </div>

                <!-- lematch hint -->
                <div class="sp-hint">
                    paste into <code>WAFT_PROTOCOL</code> in Text.svelte:
                </div>
                <pre class="sp-snippet">{g.kind === 'mung' && g.props.length
                    ? omit_snippet(g.mainkey, g.props)
                    : skip_snippet(g.mainkey)}</pre>
            {/if}
        </div>
    {/each}
</div>
{/if}

<style>
    .sp {
        margin: 0.3rem 0;
        background: #160a0a;
        border: 1px solid #5a2020;
        border-radius: 3px;
        padding: 0.3rem 0.4rem;
        font-size: 0.78rem;
    }
    .sp-hdr {
        display: flex; align-items: center; gap: 0.4rem;
        margin-bottom: 0.25rem;
    }
    .sp-title { color: #f66; font-weight: bold; font-size: 0.8rem }
    .sp-sub   { color: #844; font-size: 0.72rem }

    .sp-group {
        margin-bottom: 0.3rem;
        background: #110808;
        border: 1px solid #3a1818;
        border-radius: 2px;
        padding: 0.2rem 0.3rem;
    }
    .sp-group-muted { opacity: 0.4 }

    .sp-group-hdr {
        display: flex; align-items: center; gap: 0.25rem; flex-wrap: wrap;
        margin-bottom: 0.15rem;
    }
    .sp-mk       { font-family: monospace; color: #f8a; font-size: 0.8rem; font-weight: bold }
    .sp-mk-muted { color: #664 }

    .sp-kind         { font-size: 0.68rem; border-radius: 2px; padding: 0 0.2rem; flex-shrink: 0 }
    .sp-kind-unknown { background: #3a1020; color: #f44 }
    .sp-kind-mung    { background: #1a2a10; color: #8c6 }
    .sp-kind-other   { background: #1a1a30; color: #88a }

    .sp-count   { color: #664; font-size: 0.7rem; flex-shrink: 0 }
    .sp-spacer  { flex: 1 }

    .sp-btn {
        background: #1a1020; border: 1px solid #3a2030; border-radius: 2px;
        color: #a88; cursor: pointer; font-size: 0.68rem; padding: 0.1rem 0.3rem;
        white-space: nowrap; flex-shrink: 0;
    }
    .sp-btn:hover      { background: #241428; color: #c8a }
    .sp-btn-copy:hover { color: #afa }
    .sp-btn-mute       { color: #664 }
    .sp-btn-muted      { color: #884; border-color: #554 }
    .sp-btn-muted:hover { color: #aa6 }

    .sp-msgs { margin: 0.1rem 0 0.15rem 0 }
    .sp-msg  {
        font-family: monospace; font-size: 0.7rem; color: #a66;
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
        padding: 0.05rem 0;
    }
    .sp-msg-more { color: #664; font-style: italic }

    .sp-hint {
        font-size: 0.68rem; color: #664; margin-top: 0.1rem;
    }
    .sp-hint code { color: #886; font-family: monospace }

    .sp-snippet {
        margin: 0.15rem 0 0 0;
        padding: 0.2rem 0.3rem;
        background: #0a0a14;
        border: 1px solid #2a2030;
        border-radius: 2px;
        font-family: monospace;
        font-size: 0.68rem;
        color: #8a8;
        overflow-x: auto;
        white-space: pre;
    }
</style>
