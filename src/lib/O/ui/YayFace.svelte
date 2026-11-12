<script lang="ts">
    // YayFace — Cell:Yay (owner 2026-11-09, spec/AtheoryArrive_todo.md §6 (2)): every heart (yay) and nay, and what became of each.
    //  A READER: the rows are Heard's Cards (my Mag + my devices' mirrors, so both devices list the same), folded by Page_yays
    //   (Ghost/M/RadioPage.g) — this draws them and holds the two switches a ♥ obeys:
    //    · autoheist when yayed (Heard_autoheist, `Heist_defaults.auto`) — off ⇒ a ♥ is saved for later, listed here with ⇊;
    //    · ask before heisting (Heist_take_asks, `Heist_defaults.ask`) — the Heist form takes the main cell first.
    //  With no folder and no linked device, a heart is kept as "what we liked" and the cell introduces Link Devices.
    //  Small, it is a ♥ and a count; the ♥ you press on the radio flies into it (RadioPageFace).
    import { page_nav } from "$lib/O/ui/page_nav"
    let { n, H } = $props()
    const A = H as any

    let tick = $state(0)
    $effect(() => { const iv = setInterval(() => { tick++ }, 2000); return () => clearInterval(iv) })

    const W = () => n?.c?.up ?? A?.c?.radio_w ?? null
    let view = $derived.by(() => {
        void H?.version
        void tick
        const empty = { rows: [] as any[], later: [] as any[], heists: [] as any[], landed: 0, auto: true, ask: true, folder: false, devices: 0 }
        try {
            const w = W()
            if (!w) return empty
            const rows = (A?.Page_yays?.(w) ?? []) as any[]
            const ident = A?.Swarm_live_self?.()
            return {
                rows,
                later: rows.filter(r => r.later),
                heists: (A?.Page_yay_heists?.(w) ?? []) as any[],
                landed: (w.o?.({ Hauls: 1 })?.[0]?.o?.({ Haul: 1 }) ?? []).length as number,
                auto: !!A?.Heard_autoheist?.(),
                ask: !!A?.Heist_take_asks?.(),
                folder: !!A?.Crate_nav?.(),
                devices: ident ? (A?.Heard_trove_siblings?.(ident) ?? []).length : 0,
            }
        } catch { return empty }
    })
    let big = $derived(n?.c?.pose === 'big' || n?.c?.pose === 'main')
    let yays = $derived(view.rows.filter(r => r.react === 'take').length)
    let nays = $derived(view.rows.length - yays)
    // THE NAYS FOLD (owner 2026-11-12: *"Cell:Yay is getting a huge list of Nay I made"*) — a Nay is a done thing; the hearts are
    //  the list, the nays one line you can open
    let show_nays = $state(false)
    let yay_rows = $derived(view.rows.filter(r => r.react !== 'nay'))
    let nay_rows = $derived(view.rows.filter(r => r.react === 'nay'))

    function set(patch: Record<string, string>) {
        try { A?.Heist_defaults_set?.(patch) } catch {}
        try { A?.top_House?.()?.bump_version?.() } catch {}
    }
    // the ✕ on a row (owner 2026-11-12, *"the Yay|Nay should be deletable"*) — Heard_drop: the reaction stops counting, on every device
    const drop = (r: any) => { try { A?.Page_yay_drop?.(r.id, r.react) } catch (e) { console.warn('♥⚠ yay drop threw', e) } }
    const retry = (id: string) => { try { A?.Page_yay_retry?.(id) } catch (e) { console.warn('♥⚠ yay retry threw', e) } }
    const go = (id: string) => { try { A?.Page_yay_go?.(id) } catch (e) { console.warn('♥⚠ yay go threw', e) } }
    const link = () => page_nav(A, 'link_open', W())
    // a heart's Heist, made the main cell
    const open = (keep: any) => page_nav(A, 'focus_keep', W(), keep)

    function ago(ms: number): string {
        if (!ms) return ''
        const s = Math.max(0, Math.floor((Date.now() - ms) / 1000))
        if (s < 90) return 'just now'
        const m = Math.floor(s / 60)
        if (m < 60) return `${m}m ago`
        const h = Math.floor(m / 60)
        if (h < 24) return `${h}h ago`
        const d = Math.floor(h / 24)
        return d === 1 ? 'yesterday' : `${d}d ago`
    }
    // a Card's stamps are Heard_now — seconds or ms?  Heard_now is the radio's clock in ms on a live page; guard both
    const at_ms = (at: number) => at > 1e12 ? at : at * 1000
</script>

{#if !big}
    <div class="yf-bud" data-yay-fly title="your yays and nays — what became of each">
        <span class="yf-heart">♥</span>{#if yays}<span class="yf-n">{yays}</span>{/if}
        {#if view.later.length}<span class="yf-later" title="saved for later">⇊{view.later.length}</span>{/if}
    </div>
{:else}
    <div class="yf" data-yay-fly>
        <div class="yf-head">♥ {yays} yay{yays === 1 ? '' : 's'}{#if nays} · 👎 {nays}{/if}</div>
        <label class="yf-opt"><input type="checkbox" checked={view.auto} onchange={() => set({ auto: view.auto ? '0' : '1' })} />
            autoheist when yayed</label>
        <label class="yf-opt"><input type="checkbox" checked={view.ask} onchange={() => set({ ask: view.ask ? '0' : '1' })} />
            ask before heisting</label>

        {#if !view.folder && !view.devices}
            <div class="yf-intro">
                This device has no music folder, so a yay is kept here as <b>what we liked</b> — no bytes move yet.
                Link a device that has a folder (a computer) and it fetches your yays into it, keeping their albums' folders.
                <button class="yf-btn" onclick={link}>link a device…</button>
            </div>
        {/if}

        <!-- THE LIST SCROLLS (owner 2026-11-12: *"a vertical scrollbar in Yay, to stop it scaling way down when listing bigly… the copper
             anodes one"*) — capped, so Cellui fits the face by its head and the rows scroll under the fat copper bar (.scrollbig, app.css) -->
        <div class="yf-list scrollbig">
        {#if view.heists.length}
            <!-- EVERY HEIST RUNNING OR TO BE, ATOP (owner 2026-11-12) — a ♥'s, a ⇊'s or a ⏎'s; each opens its Heist -->
            <div class="yf-sec">heisting</div>
            {#each view.heists as h (h.keep?.sc?.seed ?? h.title)}
                <div class="yf-row">
                    <span class="yf-r">⇊</span>
                    <span class="yf-t">{h.title}{#if h.from} <span class="yf-a">— from {h.from}</span>{/if}
                        <button class="yf-fate yf-link" onclick={() => open(h.keep)} title="open its Heist">{h.line} →</button></span>
                </div>
            {/each}
        {/if}

        <!-- (DOWNLOAD LATER is a STYLE now, not a list — owner 2026-11-12: a saved-for-later ♥ is a yay row wearing ⇊) -->
        {#if view.landed}
            <!-- WHAT LANDED — the Hauls cell, reached from here now it has no minicell (owner 2026-11-12) -->
            <button class="yf-sec yf-link" onclick={() => page_nav(A, 'focus', 'Hauls')} title="the albums that landed, newest first">⇊ {view.landed} landed album{view.landed === 1 ? '' : 's'} →</button>
        {/if}
        <div class="yf-sec">yays</div>
        {#each yay_rows as r (r.react + r.id)}
            <div class="yf-row" class:nay={r.react === 'nay'} class:later={r.later}>
                <span class="yf-r">{r.react === 'nay' ? '👎' : '♥'}</span>
                <span class="yf-t">{r.title}{#if r.artist} <span class="yf-a">— {r.artist}</span>{/if}
                    {#if r.keep}
                        <button class="yf-fate yf-link" onclick={() => open(r.keep)} title="open its Heist">{r.fate} →</button>
                    {:else}
                        <span class="yf-fate">{r.fate}{#if r.at} · {ago(at_ms(r.at))}{/if}</span>
                    {/if}</span>
                {#if r.later}<button class="yf-btn" onclick={() => go(r.id)} title="saved for later — heist it now">⇊</button>{/if}
                {#if r.retry}<button class="yf-btn" onclick={() => retry(r.id)} title="heist it again">⇊</button>{/if}
                <button class="yf-x" onclick={() => drop(r)} title="forget this yay — it stops being heisted (a Heist already going keeps going)">✕</button>
            </div>
        {:else}
            <div class="yf-none">nothing yet — press ♥ on something you like</div>
        {/each}

        {#if nay_rows.length}
            <button class="yf-sec yf-link" onclick={() => { show_nays = !show_nays }} title="the tracks you said no to — never drawn into the pool again">
                {show_nays ? '▾' : '▸'} 👎 {nay_rows.length} nay{nay_rows.length === 1 ? '' : 's'}</button>
            {#if show_nays}
                {#each nay_rows as r (r.react + r.id)}
                    <div class="yf-row nay">
                        <span class="yf-r">👎</span>
                        <span class="yf-t">{r.title}{#if r.artist} <span class="yf-a">— {r.artist}</span>{/if}
                            <span class="yf-fate">{r.fate}{#if r.at} · {ago(at_ms(r.at))}{/if}</span></span>
                        <button class="yf-x" onclick={() => drop(r)} title="forget this nay — it may be pooled again">✕</button>
                    </div>
                {/each}
            {/if}
        {/if}
        </div>
    </div>
{/if}

<style>
    .yf-list { display: flex; flex-direction: column; gap: 0.3rem; max-height: 16rem; overflow-y: auto; overflow-x: hidden; padding-right: 0.3rem; }
    .yf-row.later .yf-t { font-style: italic; opacity: .8; }
    .yf-x { flex: none; margin-left: auto; background: none; border: 0; color: inherit; opacity: .35; cursor: pointer; font-size: .8em; padding: 0 .3em; }
    .yf-x:hover { opacity: 1; color: #e88; }
    .yf-bud { display: flex; align-items: center; justify-content: center; gap: 0.2rem; width: 100%; height: 100%;
        font-family: system-ui, sans-serif; color: #f4b8c8; font-weight: 700; }
    .yf-heart { font-size: 1.6rem; line-height: 1; }
    .yf-n { font-size: 0.9rem; }
    .yf-later { font-size: 0.7rem; opacity: 0.8; margin-left: 0.2rem; }
    /* a natural width, not 100%: Cellui scales a full-width ("stretched") face up to 1.56× and it spilled off the left edge (2026-11-09);
       a compact face is fitted INTO the cell, at any window size */
    /* pointer-events: auto — Cellui's mold is inert by contract and a face re-arms its own controls (DoorFace/RadioFace do); without it
       the switches, ⇊ and the Heist links never got a click (2026-11-09) */
    .yf { display: flex; flex-direction: column; gap: 0.3rem; width: 26rem; padding: 0.5rem 0.7rem; pointer-events: auto; box-sizing: border-box;
        font-family: system-ui, sans-serif; color: #e8d0d8; font-size: 0.85rem; }
    .yf-head { font-weight: 700; font-size: 1rem; color: #f4b8c8; }
    .yf-opt { display: flex; gap: 0.4rem; align-items: center; font-size: 0.8rem; opacity: 0.9; cursor: pointer; }
    .yf-intro { background: rgba(244, 184, 200, 0.08); border: 1px solid rgba(244, 184, 200, 0.25); border-radius: 0.5rem;
        padding: 0.45rem 0.55rem; font-size: 0.8rem; line-height: 1.35; }
    .yf-sec { margin-top: 0.35rem; font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.06em; opacity: 0.6; }
    .yf-row { display: flex; gap: 0.4rem; align-items: baseline; }
    .yf-row.nay { opacity: 0.6; }
    .yf-r { flex: none; }
    .yf-t { flex: 1; min-width: 0; }
    .yf-a { opacity: 0.7; }
    .yf-fate { display: block; font-size: 0.72rem; opacity: 0.65; }
    .yf-link { all: unset; cursor: pointer; text-decoration: underline dotted; text-underline-offset: 2px; }
    .yf-link:hover { opacity: 1; color: #f4b8c8; }
    .yf-btn { all: unset; cursor: pointer; padding: 0.15rem 0.5rem; margin-left: 0.3rem; border-radius: 0.4rem;
        background: rgba(244, 184, 200, 0.14); border: 1px solid rgba(244, 184, 200, 0.4); font-size: 0.8rem; }
    .yf-btn:hover { background: rgba(244, 184, 200, 0.26); }
    .yf-none { opacity: 0.6; font-style: italic; }
</style>
