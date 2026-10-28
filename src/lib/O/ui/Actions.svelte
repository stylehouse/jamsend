<script lang="ts">
    import type { TheC } from "$lib/Stuff.svelte"

    // H: the House whose button rack this is — given, a click ENTERS ATIME through H.UItime (the beliefs mutex), like a verb
    //  or a socket frame, so a button never reads or writes particles mid-tick (Verbs_todo §0, 2026-10-28).  Only the sync part
    //   of fn is held: a promise it returns runs its tail outside, never awaited inside the mutex (a tail that waits for the
    //    mutex itself would wedge).  role:pause (Story's ⏸) and anything marked instant stay instant — a pause must land while
    //     a long hold is running, which is exactly when it is wanted.  No H (a caller that hasn't passed one) = the old instant click.
    let { N, H }: { N: TheC[], H?: any } = $props()

    let actions = $derived(N)

    function call(a: TheC, f: (() => any) | undefined) {
        const go = () => {
            try {
                const back = f?.()
                if (back && typeof back.then === 'function') back.then(() => {}, (err: any) => console.warn(`Action "${a.sc.label}" failed:`, err))
            } catch (err) {
                console.warn(`Action "${a.sc.label}" failed:`, err)
            }
        }
        if (!H?.UItime || a.sc.role === 'pause' || a.sc.instant) return go()
        H.UItime(() => { go() }).catch((err: any) => console.warn(`Action "${a.sc.label}" could not enter:`, err))
    }
    function fire(a: TheC) {
        call(a, a.sc.fn)
    }
</script>

{#each actions as a}
    <!-- read a.vers so an in-place oai bump (cls/icon/disabled drift on the same
         ref) re-renders this item — the ref no longer changes per tick. -->
    {@const cls = (a.vers, a.sc.cls ?? 'default')}
    {#if a.sc.kind === 'dropdown'}
        <label class="dd" title={a.sc.label}>
            {#if a.sc.icon}<span class="dd-icon">{a.sc.icon}</span>{/if}
            <select
                class="dd-select btn btn-{cls}"
                value={(a.vers, a.sc.value) ?? ''}
                onchange={(e) => { const v = (e.target as HTMLSelectElement).value; call(a, () => a.sc.on_pick?.(v)) }}
                disabled={(a.vers, a.sc.disabled) ?? false}
            >
                {#each (a.sc.options ?? []) as opt}
                    <option value={opt.value}>{opt.label ?? opt.value}</option>
                {/each}
            </select>
        </label>
    {:else}
        <button
            onclick={() => fire(a)}
            class="btn btn-{cls}"
            title={a.sc.label}
            disabled={a.sc.disabled ?? false}
        >
            {a.sc.icon ?? a.sc.label}
        </button>
    {/if}
{/each}

<style>
.btn {
    padding: 0.3rem 0.6rem;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    line-height: 0.8;
    font-size: 0.8rem;
    transition: background 0.2s ease;
    background: #2196F3;
    color: white;
}
.btn:hover { background: #1976D2; }
.btn:disabled { opacity: 0.4; cursor: default; }

.btn-start  { background: #4CAF50; }
.btn-start:hover  { background: #45a049; }

.btn-stop   { background: #f44336; }
.btn-stop:hover   { background: #d32f2f; }

.btn-save   { background: #FF9800; }
.btn-save:hover   { background: #F57C00; }

.btn-big {
    padding: 0.4rem 0.8rem;
    font-weight: 600;
    font-size: 0.85em;
    background: #FF5722;
}
.btn-big:hover { background: #E64A19; transform: scale(1.05); }

.btn-remove {
    background: #f44336;
    font-weight: bold;
    width: 24px;
    height: 24px;
    padding: 0;
}
.btn-remove:hover { background: #d32f2f; transform: scale(1.1); }

.dd { display: inline-flex; align-items: center; gap: 0.3rem; }
.dd-icon { font-size: 0.9rem; opacity: 0.8; }
.dd-select {
    appearance: none; -webkit-appearance: none;
    padding-right: 1.4rem;
    background-image:
        linear-gradient(45deg, transparent 50%, white 50%),
        linear-gradient(135deg, white 50%, transparent 50%);
    background-position: calc(100% - 0.7rem) 50%, calc(100% - 0.4rem) 50%;
    background-size: 0.3rem 0.3rem;
    background-repeat: no-repeat;
    cursor: pointer;
    font-family: inherit;
}
.dd-select:focus { outline: 1px solid rgba(255,255,255,0.5); outline-offset: 1px; }
</style>