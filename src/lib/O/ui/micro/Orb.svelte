<script lang="ts">
    // Orb — the small border-circle toggle that opens a thing's edit/crud affordances.
    //   Shared by PeelInput's row and Waft's live-Funkcion adornment so the look is
    //    defined once.  A ui/micro/ bit.
    let { active = false, onclick, title = 'edit / add / delete' }: {
        active?:  boolean
        onclick:  () => void
        title?:   string
    } = $props()
</script>

<button class="mx-orb" class:mx-orb-active={active} {title} {onclick} aria-label={title}></button>

<style>
    .mx-orb {
        background: none; border: 1px solid #334; border-radius: 50%;
        width: 0.72rem; height: 0.72rem; padding: 0; flex-shrink: 0; cursor: pointer;
        transition: border-color 0.1s, box-shadow 0.1s;
    }
    .mx-orb:hover   { border-color: #557; box-shadow: 0 0 3px #4467 }
    .mx-orb-active  { border-color: #88a; box-shadow: 0 0 4px #446a }
</style>
