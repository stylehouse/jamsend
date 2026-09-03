<script lang="ts">
    // InviteYourself — the portability hatch on the Door (Portability_todo §9 / Division_todo §CEREMONY).
    //  Beside "invite a friend" (mint %Invite:Music — *what I will serve you*) sits this: the invite whose
    //   redemption MAKES you, not befriends you (the LinkDevice ceremony).  The DIALOGUE below is the one
    //    place a person learns what carrying an identity to a second device means; the ceremony is now
    //     BUILT (the %Ferry ceremony in Ghost/S/Swarm.g — the adopt road retired 2026-09-03), so the hatch opens the
    //      live LinkDevice flow (offer / land / consent) instead of the old disabled stub.
    import LinkDevice from "./LinkDevice.svelte"
    let { H } = $props()
    let open = $state(false)

    // AUTO-SURFACE an in-flight adoption — you shouldn't have to hunt into this hatch to service the very
    //  thing that just arrived.  Open when a ?Adopt= is landing (the soul side) OR an adoption is parked
    //   awaiting this device's consent (the adoptee side).  The warning inside then takes over the cell.
    $effect(() => {
        void H?.version
        try { if (new URL(location.href).searchParams.get('Adopt')) { open = true; return } } catch {}
    })
</script>

<div class="iy">
    <button class="iy-open" onclick={() => open = !open}
        title="carry your identity to a second device — opens a short explanation">
        🪞 Link Device {open ? '▾' : '▸'}
    </button>
    {#if open}
        <div class="iy-note">
            <LinkDevice {H} />
        </div>
    {/if}
</div>

<style>
    /* rides inside DoorFace's `.df` (pointer-events: none) — every interactive bit opts back in.
       Styled to the Door's register: small, dim, informative; the mint button stays the loud one. */
    .iy { margin-top: 3px; }
    .iy-open {
        pointer-events: auto;
        cursor: pointer;
        background: none;
        border: none;
        padding: 0;
        font-size: 9px;
        color: #8a7a94;
        text-align: left;
    }
    .iy-open:hover { color: #cbb8d8; }
    .iy-note {
        pointer-events: auto;
        margin-top: 3px;
        max-width: 260px;
        font-size: 9px;
        line-height: 1.45;
        color: #b9a6c4;
    }
    .iy-note p { margin: 0 0 5px 0; }
    .iy-note b { color: #d9a9ef; }
    /* TOTAL TRUST — inline clickable that opens the one warning that matters */
    .iy-trust {
        pointer-events: auto;
        background: none;
        border: none;
        padding: 0;
        font: inherit;
        font-weight: 700;
        letter-spacing: .3px;
        color: #ffb300;
        text-decoration: underline dotted;
        cursor: pointer;
    }
    .iy-trust:hover { color: #ffd166; }
    .iy-warn {
        border-left: 2px solid #d98a00;
        padding-left: 6px;
        color: #e8c98a;
    }
</style>
