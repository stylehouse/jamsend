<script lang="ts">
    // UI:Ballistics — a Funkcion kind: a havoc drum-pad.
    //   an ACTION, not a monitor — no run, never pumped; just a pad.
    //   click → e_Lies_strike() pops a limb out of Lies/Store
    //     (limb behaviour lives in Lies, HAVOC_LIMBS; this is only the face)
    //   hosted by FunkHost like any kind — Waft knows nothing about the limbs.
    //   the limb kind rides as kind: on the Funkcion:Ballistics embed.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H, funk, raw = false, examining }: {
        H: House, funk: TheC, raw?: boolean, examining?: TheC
    } = $props()

    let kind = $derived(funk.sc.kind as string)

    // a press flashes the pad warm for a beat.
    let struck = $state(false)
    function strike() {
        if (!kind) return
        H.i_elvisto('Lies/Lies', 'Lies_strike', { kind })
        struck = true
        setTimeout(() => { struck = false }, 180)
    }

    // a pad marked %arm self-arms — Lies_arm_engaged() strikes it when its %What is looked at.
    //   glow it while that What holds the %Spotlight, so the auto-fire is legible (a hit's warmth)
    //   reads the Spotlight src off examining, climbing to the What.
    function is_spotlight(what: TheC): boolean {
        void examining?.vers
        const spot = examining?.o?.({ Spotlight: 1 })?.[0] as any
        if (!spot?.sc.src) return false
        let node: any = spot.sc.src
        while (node) { if (node === what) return true; node = node.c?.up }
        return false
    }
    let engaged = $derived((() => {
        if (!funk.sc.arm) return false
        let what: any = funk
        while (what && what.sc?.What === undefined) what = what.c?.up
        return what ? is_spotlight(what) : false
    })())

    function raw_line(c: TheC): string {
        return Object.entries(c.sc).map(([k, v]) => v === 1 ? k : `${k}:${v}`).join(', ')
    }
</script>

{#if raw}
    <div class="bx-raw">{raw_line(funk)}</div>
{:else}
    <div class="bx">
        <button class="bx-pad" class:bx-hit={struck} class:bx-armed={!!funk.sc.arm} class:bx-engaged={engaged}
                title={(funk.sc.hint as string) ?? (funk.sc.arm ? `self-arming havoc: ${kind} (also strikeable)` : `strike havoc: ${kind}`)}
                onclick={strike}>
            <span class="bx-glyph">{(funk.sc.emoji as string) ?? '💥'}</span>
            <span class="bx-label">{kind}</span>
            {#if funk.sc.arm}<span class="bx-arm" title="self-arms when its What is looked at">⟳</span>{/if}
        </button>
    </div>
{/if}

<style>
    /* a Ballistics pad — struck to pop a limb out of the Lies/Store plumbing; presses
       down + flashes warm on a hit. */
    .bx { margin: 0.15rem 0; }
    .bx-pad {
        display: inline-flex; align-items: center; gap: 0.35rem;
        padding: 0.2rem 0.5rem;
        background: #1a1408; border: 1px solid #3a2c10; border-radius: 5px;
        color: #c9b48a; cursor: pointer;
        box-shadow: 0 2px 0 #0c0a04;
        transition: transform 0.06s, box-shadow 0.06s, background 0.12s, border-color 0.12s;
    }
    .bx-pad:hover  { background: #221a0c; border-color: #5a4418; color: #e8d4a4; }
    .bx-pad:active { transform: translateY(2px); box-shadow: 0 0 0 #0c0a04; }
    .bx-hit {
        background: #4a3410; border-color: #c89a3a;
        box-shadow: 0 0 10px rgba(200, 154, 58, 0.6); color: #ffe6a8;
    }
    .bx-glyph { font-size: 0.95rem; line-height: 1; }
    .bx-label { font-family: monospace; font-size: 0.74rem; }
    /* self-arming pad: a cooler cast + a ⟳ mark; warms (.bx-engaged) when its What holds
       the Spotlight and the limb self-fires. */
    .bx-armed { border-color: #2c3a4a; }
    .bx-armed:hover { border-color: #44627e; }
    .bx-arm { font-size: 0.7rem; color: #6a86a8; line-height: 1; }
    .bx-engaged {
        background: #14283a; border-color: #4a86c8;
        box-shadow: 0 0 9px rgba(74, 134, 200, 0.55); color: #cfe4ff;
    }
    .bx-engaged .bx-arm { color: #9cc4ee; }
    .bx-raw {
        font-family: monospace; font-size: 0.74rem; color: #8a7a5a; padding: 0.1rem 0.2rem;
    }
</style>
