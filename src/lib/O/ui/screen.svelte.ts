// screen.svelte.ts — what a Stuffica face holds (Ghost/A/Stuffica.g; spec/AtheoryArrive_todo.md §7 "Stuffica, looked at again").
//
//  A face that draws a view needs the same five things, and ArriveFace and Stuffmush each wrote them out by hand: a screen world (a
//   loose w the views stand on), the counter a commit bumps, standing its views once the ghosts have loaded, the In movement (point a
//    view at a pile and walk it through the door, in UItime — never two at once), and reading under the counter.  A Screen is those,
//     once, so a face says only WHAT it shows:
//
//      const screen = new Screen(() => H, 'Arrive', [{ name: 'rack', kinds: ['Watch'], opts: { says: [...] } }], ['Supervisor_line'])
//      screen.seat('rack', pile)                       ← In (on a timer, or when the pile is swapped)
//      let lines = $derived.by(() => screen.read(() => H.Stuffica_points(screen.w, 'rack').map(...), []))   ← Show
//      screen.arrive('rack', { open: 'list' })         ← Out: a click is an arrival
//
//  Each view's ui handle (Stuffica_view's `ui`) is a Look: Stuffica_flush calls its commit(), which bumps that view's v AND the screen's.
//   A template reading through screen.read(fn, empty) re-runs on any commit; through screen.read(fn, empty, name), or Stuffica_points
//    (which reads the view's own handle), on that view's alone — Storica redraws its plan, live, snap and hand parts separately.
import { untrack } from 'svelte'
import { TheC } from '$lib/Stuff.svelte'

export type ScreenView = { name: string, kinds: string[], opts?: Record<string, any> }

// one view's commit counter — bumps the screen's too
class Look {
    v = $state(0)
    constructor(private screen: Screen) {}
    commit() { this.v++; this.screen.v++ }
}

export class Screen {
    v = $state(0)
    readonly w: TheC
    private stood = false
    private busy = false
    private looks = new Map<string, Look>()
    private chain: Promise<any> = Promise.resolve()

    // H is read through a getter: a face's H is a prop and may arrive late; needs — the ghost methods its reads call besides Stuffica's
    constructor(private get_H: () => any, w_name: string, private views: ScreenView[], private needs: string[] = []) {
        this.w = new TheC({ c: {}, sc: { w: w_name } })
    }

    get H() { return this.get_H() }

    // a view's counter (its ui handle) — what its part of the template reads
    look(name: string): Look {
        let look = this.looks.get(name)
        if (!look) {
            look = new Look(this)
            this.looks.set(name, look)
        }
        return look
    }

    // the ghosts are in: Stuffica's door and whatever else this face reads
    loaded(): boolean {
        const H = this.H
        return typeof H?.Stuffica_door === 'function' && this.needs.every((f) => typeof H?.[f] === 'function')
    }

    // In — point a view at the pile it shows and walk it through the door; stands the views on first use.  stirred: only when
    //  something it walked has moved since (Stuffica_stirred — for piles no Atheory run tells about).  Skipped while one is in flight,
    //   while the ghosts aren't loaded, and while the tab is hidden
    seat(name: string, pile: any, stirred = false) {
        if (this.busy || !this.loaded() || (typeof document !== 'undefined' && document.hidden)) return
        const H = this.H
        this.stand()
        if (stirred) {
            const seem = this.w.o({ TheASeem: name })[0]
            if (seem?.c.from === pile && !H.Stuffica_stirred(this.w, name)) return
        }
        this.busy = true
        H.Stuffica_door(this.w, 'refresh', () => {
            H.Stuffica_from(this.w, name, pile)
            return H.Stuffica_refresh(this.w, [name])
        }).catch((e: any) => console.warn(`${this.w.sc.w} refresh`, e)).finally(() => { this.busy = false })
    }

    // stand the views, once the ghosts are in (seat does it; a face with its own In calls it)
    stand() {
        if (this.stood || !this.loaded()) return
        this.stood = true
        for (const view of this.views) this.H.Stuffica_view(this.w, view.name, view.kinds, this.look(view.name), view.opts)
    }

    // In, by hand — fn through the door (UItime), one at a time: a refresh walks over awaits, and two at once would interleave.  For a
    //  face that seats several views from several piles in one go (Storica); seat() is the one-view case
    door(why: string, fn: () => any): Promise<any> {
        const H = this.H
        this.chain = this.chain.then(() => (typeof H?.Stuffica_door === 'function' ? H.Stuffica_door(this.w, why, fn) : fn()))
            .catch((e: any) => console.warn(`${this.w.sc.w} ${why}`, e))
        return this.chain
    }

    // Show — fn read under a counter and nothing else (untracked), or empty before the ghosts are in: the screen's (any commit), or one
    //  view's
    read<T>(fn: () => T, empty: T, name?: string): T {
        void (name ? this.look(name).v : this.v)
        return untrack(() => (this.loaded() ? fn() : empty))
    }

    // the rows a view's Seem holds of one kind, by value — what the screen asked for (%TheAOpen, %TheAPin …)
    asked(name: string, kind = 'TheAOpen'): Set<string> {
        return new Set(this.w.o({ TheASeem: name })[0]?.o({ [kind]: 1 }).map((r: any) => String(r.sc[kind])) ?? [])
    }

    // Out — a click is an arrival on a view (Stuffica_arrive: one take per burst)
    arrive(name: string, sc: Record<string, string>) {
        this.H?.Stuffica_arrive?.(this.w, { view: name, ...sc })
    }
}
