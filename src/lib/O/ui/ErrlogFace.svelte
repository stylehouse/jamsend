<script lang="ts">
    // ErrlogFace — the Story ERROR CHANNEL's face (spec/Error_channel_todo.md), mounted by Cytui on a
    //  %Errlog particle (imposed by mainkey via glass_faces.ts FACE_MAINKEYS — the world stays Voro-blind,
    //   no snap byte changes to dress it).  The channel is LAZY: a clean run never mints an Errlog, so this
    //    face only ever exists when something was captured — it is the loud-when-broken tell.  Same posture as
    //     the .face-err crash tile: calm ✓ green when empty (defensive — normally the absence shows green in
    //      Storui instead), amber when only warnings, RED with the count + the latest lines when errors landed.
    //  Reads the %Err children each H.version bump; %Err carries { kind, where, msg, n(step), count }.
    //   Pointer-events:none root so the glass stays pannable (this face has no buttons to re-arm).
    let { n, H } = $props()

    let view = $derived.by(() => {
        void H?.version
        const kids = (n?.o?.({ Err: 1 }) ?? []) as any[]
        let errors = 0, warns = 0
        for (const c of kids) { if (c?.sc?.kind === 'warn') warns++; else errors++ }
        // latest 3, newest last in creation order → show reversed (newest first)
        const latest = kids.slice(-3).reverse().map((c) => ({
            kind:  (c?.sc?.kind as string) ?? 'error',
            where: (c?.sc?.where as string) ?? '?',
            msg:   (c?.sc?.msg as string) ?? '',
            step:  (c?.sc?.n as string) ?? '',
            count: +(c?.sc?.count ?? 1),
        }))
        const level = errors > 0 ? 'error' : (warns > 0 ? 'warn' : 'clean')
        return { errors, warns, total: kids.length, latest, level }
    })
</script>

<div class="ef" class:err={view.level === 'error'} class:warn={view.level === 'warn'}>
    {#if view.level === 'clean'}
        <div class="ef-head ef-ok">✓ no errors</div>
    {:else}
        <div class="ef-head">
            {view.errors > 0 ? '⛔' : '⚠'}
            <span class="ef-count">{view.errors}{view.warns > 0 ? ` · ${view.warns}⚠` : ''}</span>
            <span class="ef-label">{view.errors > 0 ? (view.errors === 1 ? 'error' : 'errors') : (view.warns === 1 ? 'warning' : 'warnings')}</span>
        </div>
        <ul class="ef-list">
            {#each view.latest as e}
                <li class="ef-item" class:ef-warn-item={e.kind === 'warn'}>
                    <span class="ef-icon">{e.kind === 'warn' ? '⚠' : '⛔'}</span>
                    <span class="ef-where">{e.where}{e.step ? ` ·${e.step}` : ''}{e.count > 1 ? ` ×${e.count}` : ''}</span>
                    <span class="ef-msg">{e.msg}</span>
                </li>
            {/each}
        </ul>
    {/if}
</div>

<style>
    .ef {
        pointer-events: none;
        width: max-content;
        max-width: 320px;
        padding: 7px 11px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        text-align: left;
        border-radius: 8px;
        color: #e8dcc0;
        background: #14261c;
        border: 1px solid #2e6b3a;
    }
    .ef.err  { background: #2a1414; border-color: #d0413a; color: #ffe1de; }
    .ef.warn { background: #2a2410; border-color: #d9a026; color: #fff0cf; }
    .ef-head { font-size: 12px; font-weight: 700; display: flex; align-items: baseline; gap: 5px; }
    .ef-ok { color: #7fd89a; }
    .ef-count { font-size: 14px; }
    .ef-label { font-size: 10px; opacity: 0.8; font-weight: 400; }
    .ef-list { list-style: none; margin: 5px 0 0; padding: 0; display: flex; flex-direction: column; gap: 3px; }
    .ef-item { font-size: 9px; line-height: 1.25; display: grid; grid-template-columns: auto auto 1fr; gap: 4px; align-items: baseline; }
    .ef-icon { font-size: 9px; }
    .ef-where { opacity: 0.75; white-space: nowrap; font-weight: 600; }
    .ef-msg { overflow-wrap: anywhere; opacity: 0.95; }
    .ef-warn-item { opacity: 0.85; }
</style>
