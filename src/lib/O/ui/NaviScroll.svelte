<script lang="ts">
    import { tick } from "svelte"

    let { H, houses, children } = $props()

    // ── constants ─────────────────────────────────────────────────────────────
    const HEADER_HEIGHT_REM = 1.75  // keep in sync with CSS (.house-header min-height)
    const RESTORE_WINDOW_MS = 3000  // after Mundo start / resetStory, seek newcomers

    function remToPx(rem: number) {
        return rem * parseFloat(getComputedStyle(document.documentElement).fontSize)
    }

    // direct children of house
    function childrenOf(house) {
        const ip = house?.c?.ip
        if (!ip) return []
        const depth = ip.split('_').length
        return houses.filter(h =>
            h.c?.ip?.startsWith(ip + '_')
            && h.c.ip.split('_').length === depth + 1
        )
    }

    // walk up from a house collecting names, excluding the root Mundo
    function house_path(house): string {
        const parts: string[] = []
        let h = house
        while (h?.up) {
            parts.unshift(h.name)
            h = h.up
        }
        return parts.join('/')
    }

    // find current house matching a stored path
    function house_by_path(path: string) {
        if (!path) return undefined
        const parts = path.split('/')
        let h = H
        for (const name of parts) {
            h = h?.subHouses.o({name})[0]
            if (!h) return undefined
        }
        return h
    }

    function scrollToHouseIdx(idx: number) {
        if (idx < 0 || idx >= houses.length) return
        const house = houses[idx]
        if (H?.stashed && house) {
            H.stashed.gazed_house_path = house_path(house)
        }
        _scrollToHouseEl(house, idx)
    }

    function _scrollToHouseEl(house, idx: number) {
        const header = document.getElementById(`house-${house.c.ip}`)
        if (!header) return

        const headerPx = remToPx(HEADER_HEIGHT_REM)
        const sticky_before = houses.slice(0, idx)
            .filter(h => h?.actions.o().length > 0).length
        const this_is_sticky = house?.actions.o().length > 0

        if (this_is_sticky) {
            const content = header.nextElementSibling as HTMLElement | null
            if (!content) return
            const contentTop = content.getBoundingClientRect().top + window.scrollY
            window.scrollTo({
                top: contentTop - (sticky_before + 1) * headerPx,
                behavior: 'smooth',
            })
        } else {
            const headerTop = header.getBoundingClientRect().top + window.scrollY
            window.scrollTo({
                top: headerTop - sticky_before * headerPx,
                behavior: 'smooth',
            })
        }
    }

    function scrollToHouseIp(ip: string) {
        scrollToHouseIdx(houses.findIndex(h => h.c?.ip === ip))
    }

    //#region gaze restoration
    // Track which House ips have appeared so we can detect newcomers.
    // Within RESTORE_WINDOW_MS of Mundo starting (or a resetStory elvis), if
    // the gazed ip turns up in all_House, seek to it.
    let seen_ips = new Set<string>()
    let restored_once = false   // don't chase the same ip forever

    // Mundo start: open restore window once
    $effect(() => {
        if (!H?.started) return
        H.c.restore_window_until = Date.now() + RESTORE_WINDOW_MS
        restored_once = false
    })

    // Whenever the houses list changes, note new ips and maybe seek the gazed one.
    let last_seen_deadline = 0
    $effect(() => {
        if (!houses?.length) return
        const gazed_path = H?.stashed?.gazed_house_path as string | undefined
        const deadline = H?.c?.restore_window_until ?? 0

        // new window opened since we last looked — reset
        if (deadline > last_seen_deadline) {
            last_seen_deadline = deadline
            restored_once = false
        }

        const current_ips = new Set(houses.map(h => h.c?.ip).filter(Boolean))
        const newcomers: string[] = []
        for (const ip of current_ips) {
            if (!seen_ips.has(ip)) newcomers.push(ip)
        }
        seen_ips = current_ips

        if (!gazed_path || restored_once) return
        if (Date.now() > deadline) return
        if (!newcomers.length) return

        const target = house_by_path(gazed_path)
        if (!target || !newcomers.includes(target.c.ip)) return

        restored_once = true
        setTimeout(async () => {
            await tick()
            scrollToHouseIpStable(target.c.ip)
        }, 50)
    })

    // Phase 1: poll fn() until two consecutive reads match (layout settled).
    // Phase 2: wait confirm_ms, read once more, must still match.
    // Phase 3: scroll to target, then for chase_ms keep re-reading every
    //          chase_interval_ms; if drift > 5px, scroll again. User scroll
    //          detection aborts phase 3 immediately.
    function settle_then_chase(
        fn: () => number | null,
        scroll_to: () => void,
        opts: {
            interval_ms?: number
            max_attempts?: number
            confirm_ms?: number
            chase_ms?: number
            chase_interval_ms?: number
            drift_px?: number
            still_ms?: number
        } = {},
    ) {
        const interval_ms       = opts.interval_ms       ?? 50
        const max_attempts      = opts.max_attempts      ?? 40
        const confirm_ms        = opts.confirm_ms        ?? 100
        const chase_ms          = opts.chase_ms          ?? 1500
        const chase_interval_ms = opts.chase_interval_ms ?? 100
        const drift_px          = opts.drift_px          ?? 5
        const still_ms          = opts.still_ms          ?? 500

        let prev: number | null = null
        let attempts = 0

        // ── phase 1: settle ────────────────────────────────────────────
        const settle_tick = () => {
            attempts++
            const v = fn()
            if (v == null) {
                if (attempts < max_attempts) setTimeout(settle_tick, interval_ms)
                return
            }
            if (prev != null && v === prev) {
                // two matched — phase 2
                setTimeout(() => confirm_tick(v), confirm_ms)
                return
            }
            prev = v
            if (attempts < max_attempts) setTimeout(settle_tick, interval_ms)
        }

        // ── phase 2: confirm ───────────────────────────────────────────
        const confirm_tick = (expected: number) => {
            const v = fn()
            if (v == null || v !== expected) {
                // lost it — back to settling
                prev = v
                if (attempts < max_attempts) setTimeout(settle_tick, interval_ms)
                return
            }
            // confirmed — phase 3
            begin_chase()
        }

        // ── phase 3: scroll + chase ────────────────────────────────────
        const begin_chase = () => {
            scroll_to()

            // snapshot scroll position right after scrollTo starts
            // (smooth scroll is async, so sample after a tick)
            let last_scroll_y = window.scrollY
            let user_scrolled = false
            const chase_start = Date.now()
            let last_drift_t = Date.now()   // last time target moved

            setTimeout(() => { last_scroll_y = window.scrollY }, chase_interval_ms)

            const chase_tick = () => {
                if (user_scrolled) return
                if (Date.now() - chase_start > chase_ms) return
                if (Date.now() - last_drift_t > still_ms) return   // bail if still

                const dy = Math.abs(window.scrollY - last_scroll_y)
                if (dy > drift_px) last_scroll_y = window.scrollY

                const v = fn()
                if (v != null && Math.abs(v - (prev ?? v)) > drift_px) {
                    // target drifted — re-scroll, update prev
                    prev = v
                    last_drift_t = Date.now()   // drift resets timer
                    scroll_to()
                    setTimeout(() => { last_scroll_y = window.scrollY }, chase_interval_ms)
                }

                setTimeout(chase_tick, chase_interval_ms)
            }

            // user scroll listener — any wheel/touch/keydown input aborts chase
            const abort = () => { user_scrolled = true }
            window.addEventListener('wheel',     abort, { once: true, passive: true })
            window.addEventListener('touchmove', abort, { once: true, passive: true })
            window.addEventListener('keydown',   abort, { once: true })
            // cleanup after chase window
            setTimeout(() => {
                window.removeEventListener('wheel',     abort)
                window.removeEventListener('touchmove', abort)
                window.removeEventListener('keydown',   abort)
            }, chase_ms + 100)

            setTimeout(chase_tick, chase_interval_ms)
        }

        settle_tick()
    }

    function scrollToHouseIpStable(ip: string) {
        const idx = houses.findIndex(h => h.c?.ip === ip)
        if (idx < 0) return
        const house = houses[idx]

        const measure = () => {
            const header = document.getElementById(`house-${house.c.ip}`)
            if (!header) return null
            const content = header.nextElementSibling as HTMLElement | null
            const el = (house?.actions?.length > 0 && content) ? content : header
            return Math.round(el.getBoundingClientRect().top + window.scrollY)
        }

        settle_then_chase(measure, () => scrollToHouseIdx(idx))
    }
</script>

{@render children({ scrollToHouseIdx, scrollToHouseIp, childrenOf })}
