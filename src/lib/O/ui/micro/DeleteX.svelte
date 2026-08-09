<script lang="ts">
    // DeleteX — a delete affordance deliberately hard to hit by accident.
    //   A stray single click never deletes: the first click only ARMS it (the × swells
    //    into a red "delete?" pill); a second, deliberate click confirms.  Moving the
    //     pointer off it, or a short timeout, disarms — so it re-guards itself.
    //   The first of the ui/micro/ bits: tiny reusable scraps of form.
    //   `big` — the ORB form (the human 2026-08-07: "bigger and redder (background orb?)").  Opt-in,
    //    because this same component is every path chip's × and those must stay the quiet standard
    //     affordance the human asked for; a heist is a minute of filing, so ITS exit gets to be found
    //      at a glance.  One prop, two sizes, no second component to keep in step.
    let { ondelete, title = 'delete', glyph = '×', big = false }: {
        ondelete: () => void
        title?:   string
        glyph?:   string
        big?:     boolean
    } = $props()

    let armed = $state(false)
    let timer: ReturnType<typeof setTimeout> | undefined
    // THE BUTTON DISARMED ITSELF (the owner 2026-08-09: *"none of the path bit X buttons do anything,
    //  in the Haul"* … *"even the X delete? one for the whole Heist"*).  Arming CHANGES THIS BUTTON'S
    //   OWN SIZE — `×` (a 22px circle in the `big` form) swells into a `delete?` pill, wider and
    //    shorter — and these sit in a wrapping row of path chips.  So the act of arming reflows the
    //     row, the button moves out from under the stationary pointer, `mouseleave` fires, and it
    //      disarms.  The next click re-arms instead of confirming, forever: a control that looks
    //       perfectly alive (you SEE `delete?`) and can never fire.  Both reported buttons are this.
    //  The mouse-off disarm is belt-and-braces — the 2.2s timer is the actual re-guard — so it only
    //   has to stop believing a leave it caused itself.  A short grace does that without giving up
    //    "move away and it re-guards": a human moving off deliberately takes far longer than 400ms,
    //     and the self-inflicted leave arrives in the same frame as the arm.
    let armedAt = 0
    const SELF_LEAVE_GRACE = 400
    function disarm() { armed = false; if (timer) { clearTimeout(timer); timer = undefined } }
    function leave() {
        if (armed && performance.now() - armedAt < SELF_LEAVE_GRACE) return
        disarm()
    }
    function click() {
        if (armed) { disarm(); ondelete() }
        else { armed = true; armedAt = performance.now(); timer = setTimeout(disarm, 2200) }
    }
</script>

<!-- ARMING MUST NOT MOVE ANYTHING (see the note above).  The grace stops the button believing the
     leave it caused, but if the row had already re-wrapped the second click would land on empty
     space instead — the button would be armed somewhere the pointer no longer is.  So the armed
     pill comes OUT OF FLOW: a ghost of the unarmed glyph holds the original footprint, and the pill
     is positioned over it.  Nothing outside this component moves when it arms, which makes the
     second press land exactly where the first one did — the only place a human will look for it. -->
<span class="mx-wrap" class:mx-wrap-armed={armed}>
    {#if armed}<span class="mx-ghost" class:mx-big={big} aria-hidden="true">{glyph}</span>{/if}
    <button class="mx-del" class:mx-armed={armed} class:mx-big={big}
            title={armed ? 'click again to delete' : title}
            onclick={click} onmouseleave={leave}>{armed ? 'delete?' : glyph}</button>
</span>

<style>
    /* the wrap reserves the UNARMED footprint and anchors the armed pill over it.  inline-flex so it
       sits in the chip row exactly where the bare button used to. */
    .mx-wrap { position: relative; display: inline-flex; align-items: center; justify-content: center; }
    /* the ghost is the unarmed glyph, invisible, holding the space the pill vacated.  It carries the
       same size classes so `big`'s 22px disc reserves 22px and the small × reserves a small ×. */
    .mx-ghost { visibility: hidden; pointer-events: none; font-size: 0.82rem; padding: 0 0.15rem; }
    .mx-ghost.mx-big { display: inline-flex; width: 22px; height: 22px; padding: 0; font-size: 1rem; }
    /* armed: centred on the footprint, above its neighbours, never wrapping mid-word */
    .mx-wrap-armed .mx-del {
        position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%);
        z-index: 3; white-space: nowrap;
    }
    .mx-del {
        /* RE-ARM POINTER EVENTS (2026-08-07 — "the cancel heist ✕ is unclickable").  A voronoi glass
           cell's bbox overlaps its neighbours, so every face root in the glass sets
           `pointer-events: none` and each control re-arms it — HaulFace calls that its hard contract
           and states it in a comment.  A face can only re-arm its OWN markup, though: Svelte scopes
           styles, so `.kf-x { pointer-events: auto }` cannot reach inside this component, and dropping
           a DeleteX into such a face produced a button that renders perfectly and cannot be clicked.
           It has to be re-armed HERE, once, or every future glass consumer inherits the same dead
           button (DiagFace already had it too).  Outside a pointer-events:none root this is a no-op. */
        pointer-events: auto;
        background: none; border: none; color: #445;
        cursor: pointer; font-size: 0.82rem; padding: 0 0.15rem;
        border-radius: 3px; transition: color 0.1s, background 0.1s;
    }
    .mx-del:hover { color: #b55; }
    /* armed — the deliberate, harder-to-miss confirm state */
    .mx-armed {
        color: #fbb; background: #5a1a1a;
        font-size: 0.7rem; padding: 0.05rem 0.3rem;
    }
    .mx-armed:hover { color: #fff; background: #7a1a1a; }

    /* the ORB — a filled red disc you can find without hunting.  Sized in a fixed square with a 50%
       radius so it stays a true circle whatever glyph it carries; inline-flex centres that glyph
       optically rather than on the text baseline, which is what makes a × look off-centre in a disc. */
    .mx-big {
        display: inline-flex; align-items: center; justify-content: center;
        width: 22px; height: 22px; padding: 0;
        border-radius: 50%;
        background: #6e1520; color: #ffd7de;
        font-size: 1rem; line-height: 1;
        box-shadow: 0 0 0 1px #a3323f inset;
    }
    .mx-big:hover { background: #a3323f; color: #fff; box-shadow: 0 0 0 1px #d95566 inset; }
    /* armed, the orb relaxes into a pill — "delete?" cannot live inside a 22px circle. */
    .mx-big.mx-armed {
        width: auto; height: auto; border-radius: 9px;
        padding: 0.12rem 0.4rem; font-size: 0.72rem;
        background: #8a1a1a; color: #ffe3e3;
    }
</style>
