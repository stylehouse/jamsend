<script lang="ts">
    // DeleteX — a delete affordance deliberately hard to hit by accident.
    //   A stray single click never deletes: the first click only ARMS it (the × swells
    //    into a red "delete?" pill); a second, deliberate click confirms.  Moving the
    //     pointer off it, or a short timeout, disarms — so it re-guards itself.
    //   The first of the ui/micro/ bits: tiny reusable scraps of form.
    let { ondelete, title = 'delete', glyph = '×' }: {
        ondelete: () => void
        title?:   string
        glyph?:   string
    } = $props()

    let armed = $state(false)
    let timer: ReturnType<typeof setTimeout> | undefined

    function disarm() { armed = false; if (timer) { clearTimeout(timer); timer = undefined } }
    function click() {
        if (armed) { disarm(); ondelete() }
        else { armed = true; timer = setTimeout(disarm, 2200) }
    }
</script>

<button class="mx-del" class:mx-armed={armed}
        title={armed ? 'click again to delete' : title}
        onclick={click} onmouseleave={disarm}>{armed ? 'delete?' : glyph}</button>

<style>
    .mx-del {
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
</style>
