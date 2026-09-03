// calm — GIVE UP THE GLOW WHEN THE MACHINE IS STRUGGLING (owner 2026-09-03: "all the glowy effects on Door at
//  the moment are lagging the page... can we off them, or detect if the computer is going slow (low fps?)
//   and give up on them").  Infinite `filter: drop-shadow` animations repaint every frame; on a slow machine
//    they ARE the lag.  This measures the frame rate ONCE per page (a two-second rAF sample, started lazily
//     by the first face that asks) and, under ~40 fps — or when the OS asks for reduced motion — stamps
//      `data-calm` on <html>.  Component CSS then guards its glow with `:global(html[data-calm])`.
//  Never re-arms on its own: a page that was slow once stays calm until reload — glow that flickers on and
//   off as the fps wobbles would be worse than either state.  `calm_force(true|false)` is the manual override.
let started = false
export function calm_watch(): void {
    if (started || typeof window === 'undefined') return
    started = true
    try {
        const root = document.documentElement
        if (window.matchMedia?.('(prefers-reduced-motion: reduce)').matches) { root.dataset.calm = 'motion'; return }
        let frames = 0
        const t0 = performance.now()
        const tick = (t: number) => {
            frames++
            if (t - t0 < 2000) { requestAnimationFrame(tick); return }
            const fps = frames / ((t - t0) / 1000)
            if (fps < 40) { root.dataset.calm = String(Math.round(fps)); console.log(`🕯 calm — ${Math.round(fps)} fps measured, giving up the glow`) }
        }
        requestAnimationFrame(tick)
    } catch {}
}
export function calm_force(on: boolean): void {
    try { const root = document.documentElement; if (on) root.dataset.calm = 'forced'; else delete root.dataset.calm } catch {}
}
