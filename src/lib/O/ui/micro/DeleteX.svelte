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

    function disarm() { armed = false; if (timer) { clearTimeout(timer); timer = undefined } }
    function click() {
        if (armed) { disarm(); ondelete() }
        else { armed = true; timer = setTimeout(disarm, 2200) }
    }
</script>

<button class="mx-del" class:mx-armed={armed} class:mx-big={big}
        title={armed ? 'click again to delete' : title}
        onclick={click} onmouseleave={disarm}>{armed ? 'delete?' : glyph}</button>

<style>
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
