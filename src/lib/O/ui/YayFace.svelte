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
        const empty = { rows: [] as any[], later: [] as any[], auto: true, ask: true, folder: false, devices: 0 }
        try {
            const w = W()
            if (!w) return empty
            const rows = (A?.Page_yays?.(w) ?? []) as any[]
            const ident = A?.Swarm_live_self?.()
            return {
                rows,
                later: rows.filter(r => r.later),
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

    function set(patch: Record<string, string>) {
        try { A?.Heist_defaults_set?.(patch) } catch {}
        try { A?.top_House?.()?.bump_version?.() } catch {}
    }
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
    <div class="yf-bud" title="your yays and nays — what became of each">
        <span class="yf-heart">♥</span>{#if yays}<span class="yf-n">{yays}</span>{/if}
        {#if view.later.length}<span class="yf-later" title="saved for later">⇊{view.later.length}</span>{/if}
    </div>
{:else}
    <div class="yf">
        <div class="yf-head">♥ {yays} yay{yays === 1 ? '' : 's'}{#if nays} · 👎 {nays}{/if}</div>
        <label class="yf-opt"><input type="checkbox" checked={view.auto} onchange={() => set({ auto: view.auto ? '0' : '1' })} />
            autoheist when yayed</label>
        <label class="yf-opt"><input type="checkbox" checked={view.ask} onchange={() => set({ ask: view.ask ? '0' : '1' })} />
            ask before heisting (the Heist form comes up first)</label>

        {#if !view.folder && !view.devices}
            <div class="yf-intro">
                This device has no music folder, so a yay is kept here as <b>what we liked</b> — no bytes move yet.
                Link a device that has a folder (a computer) and it fetches your yays into it, keeping their albums' folders.
                <button class="yf-btn" onclick={link}>link a device…</button>
            </div>
        {/if}

        {#if view.later.length}
            <div class="yf-sec">download later</div>
            {#each view.later as r (r.id)}
                <div class="yf-row">
                    <span class="yf-t">{r.title}{#if r.artist} <span class="yf-a">— {r.artist}</span>{/if}</span>
                    <button class="yf-btn" onclick={() => go(r.id)} title="heist it now">⇊</button>
                </div>
            {/each}
        {/if}

        <div class="yf-sec">everything</div>
        {#each view.rows as r (r.react + r.id)}
            <div class="yf-row" class:nay={r.react === 'nay'}>
                <span class="yf-r">{r.react === 'nay' ? '👎' : '♥'}</span>
                <span class="yf-t">{r.title}{#if r.artist} <span class="yf-a">— {r.artist}</span>{/if}
                    {#if r.keep}
                        <button class="yf-fate yf-link" onclick={() => open(r.keep)} title="open its Heist">{r.fate} →</button>
                    {:else}
                        <span class="yf-fate">{r.fate}{#if r.at} · {ago(at_ms(r.at))}{/if}</span>
                    {/if}</span>
            </div>
        {:else}
            <div class="yf-none">nothing yet — press ♥ on something you like</div>
        {/each}
    </div>
{/if}

<style>
    .yf-bud { display: flex; align-items: center; justify-content: center; gap: 0.2rem; width: 100%; height: 100%;
        font-family: system-ui, sans-serif; color: #f4b8c8; font-weight: 700; }
    .yf-heart { font-size: 1.6rem; line-height: 1; }
    .yf-n { font-size: 0.9rem; }
    .yf-later { font-size: 0.7rem; opacity: 0.8; margin-left: 0.2rem; }
    .yf { display: flex; flex-direction: column; gap: 0.3rem; width: 100%; padding: 0.5rem 0.7rem; box-sizing: border-box;
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
