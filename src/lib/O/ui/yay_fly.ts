// THE FLYING ♥ — one window listener for the `jam-yay` event RadioFace throws (a ♥ press, a burnt-down 👎 fuse): a glyph flies from
//  the press into the Yay cell, wherever it is drawn — YayFace marks its own root `data-yay-fly`, bud or main, so / (Vyto) and /Radio
//   (Cellui) are one road (owner 2026-11-12: *"the love does not seem to fly any more"* — on / nobody was listening).  The first heart
//    mints that cell, so the flight waits for it to appear (≤4s).  Installed once, on first import.
function fly(from: { x: number, y: number, glyph?: string }, tries = 0) {
    const to = document.querySelector('[data-yay-fly]') as HTMLElement | null
    if (!to || !to.getBoundingClientRect().width) {
        if (tries < 40) setTimeout(() => fly(from, tries + 1), 100)
        return
    }
    const r = to.getBoundingClientRect()
    const el = document.createElement('div')
    el.className = 'yay-fly'
    el.textContent = from.glyph || '♥'
    el.style.cssText = `position:fixed;left:${from.x}px;top:${from.y}px;z-index:50001;pointer-events:none;color:#f4b8c8;`
        + `font-size:28px;transform:translate(-50%,-50%);text-shadow:0 0 12px rgba(244,184,200,0.8)`
    document.body.appendChild(el)
    const dx = r.left + r.width / 2 - from.x, dy = r.top + r.height / 2 - from.y
    const reduce = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches
    const anim = el.animate([
        { transform: 'translate(-50%,-50%) scale(1)', opacity: 1 },
        { transform: `translate(calc(-50% + ${dx * 0.5}px), calc(-50% + ${dy * 0.5 - 60}px)) scale(1.5)`, opacity: 1, offset: 0.45 },
        { transform: `translate(calc(-50% + ${dx}px), calc(-50% + ${dy}px)) scale(0.6)`, opacity: 0.2 },
    ], { duration: reduce ? 1 : 750, easing: 'cubic-bezier(.3,.7,.4,1)' })
    anim.onfinish = () => {
        el.remove()
        to.animate?.([{ transform: 'scale(1)' }, { transform: 'scale(1.25)' }, { transform: 'scale(1)' }], { duration: reduce ? 1 : 300 })
    }
}
if (typeof window !== 'undefined' && !(window as any).__yay_fly) {
    ;(window as any).__yay_fly = 1
    window.addEventListener('jam-yay', (e: Event) => { const d = (e as CustomEvent).detail; if (d) fly(d) })
}
export {}
