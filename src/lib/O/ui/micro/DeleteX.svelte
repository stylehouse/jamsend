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
    //   `confirm` — WHAT THE ARMED PILL SAYS (the owner 2026-08-09: "should take a param for the confirm
    //    language, here we would have cancel, which everyone's familiar with").  The armed state is a
    //     promise about what the second press does, and for the heist ✕ that is not deleting anything —
    //      it drops an intent and keeps every file already landed.  Saying `delete?` there was a lie in
    //       the one place a lie costs most: the moment someone decides whether to press again.  Default
    //        stays `delete?` so every existing chip × is untouched.
    let { ondelete, title = 'delete', glyph = '×', big = false, confirm = 'delete?' }: {
        ondelete: () => void
        title?:   string
        glyph?:   string
        big?:     boolean
        confirm?: string
    } = $props()
    // the hover title says the same word the pill does — one string to pass, not two to keep in step.
    //  Trailing '?' is the pill's questioning form, not part of the verb: "cancel?" → "click again to cancel".
    const verb = $derived(confirm.replace(/\?+$/, ''))

    let armed = $state(false)
    let timer: ReturnType<typeof setTimeout> | undefined
    // FIRED — the button admits it has been pressed (the owner 2026-08-09: *"can we get it to disable
    //  once clicked so the user at least gets some feedback that the button has undertaken
    //   something"*).  The confirmed press hands off to machinery whose visible result may lag (a
    //    drop that must ride a commission + a think cycle), and until now the button just sat there
    //     looking pressable — so the natural read was "it didn't take" and the natural move was to
    //      press again, into a handler that had already run.  Once fired it DISABLES and says
    //       "<verb>…" in place, dimmed: the press is acknowledged on the spot, whatever the glass
    //        does next.  Normally the cell departs and unmounts this whole component; the 15s
    //         re-enable is only the honesty valve for the abnormal case — if nothing consumed the
    //          cell by then, something is wrong and the user deserves a button back, not a corpse.
    let fired = $state(false)
    let fired_t: ReturnType<typeof setTimeout> | undefined
    // THE BUTTON DISARMED ITSELF (the owner 2026-08-09: *"none of the path bit X buttons do anything,
    //  in the Heist"* … *"even the X delete? one for the whole Heist"*).  Arming CHANGES THIS BUTTON'S
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
        if (fired) return
        if (armed) {
            disarm()
            fired = true
            fired_t = setTimeout(() => { fired = false }, 15000)
            ondelete()
        }
        else { armed = true; armedAt = performance.now(); timer = setTimeout(disarm, 2200) }
    }
</script>

<!-- ARMING MUST NOT MOVE ANYTHING (see the note above).  The grace stops the button believing the
     leave it caused, but if the row had already re-wrapped the second click would land on empty
     space instead — the button would be armed somewhere the pointer no longer is.  So the armed
     pill comes OUT OF FLOW: a ghost of the unarmed glyph holds the original footprint, and the pill
     is positioned over it.  Nothing outside this component moves when it arms, which makes the
     second press land exactly where the first one did — the only place a human will look for it. -->
<!-- FIRED rides the same out-of-flow rig as ARMED (ghost holds the footprint, pill floats over it):
     the acknowledgement must not reflow the row any more than the arm was allowed to. -->
<span class="mx-wrap" class:mx-wrap-armed={armed || fired}>
    {#if armed || fired}<span class="mx-ghost" class:mx-big={big} aria-hidden="true">{glyph}</span>{/if}
    <button class="mx-del" class:mx-armed={armed} class:mx-fired={fired} class:mx-big={big}
            disabled={fired}
            title={fired ? `${verb} underway` : armed ? `click again to ${verb}` : title}
            onclick={click} onmouseleave={leave}>{fired ? `${verb}…` : armed ? confirm : glyph}</button>
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
           `pointer-events: none` and each control re-arms it — HeistFace calls that its hard contract
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
    /* fired — pressed, acknowledged, working.  The pill's shape survives (same padding family as
       armed) but everything urgent about it drains out: dim, quiet, no pointer, no hover invite. */
    .mx-fired, .mx-big.mx-fired {
        color: #c9b2b6; background: #3a2226;
        font-size: 0.7rem; padding: 0.05rem 0.3rem;
        opacity: 0.6; cursor: default;
    }
    .mx-big.mx-fired { width: auto; height: auto; border-radius: 9px; padding: 0.12rem 0.4rem; font-size: 0.72rem; box-shadow: none; }
    .mx-fired:hover { color: #c9b2b6; background: #3a2226; }

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
