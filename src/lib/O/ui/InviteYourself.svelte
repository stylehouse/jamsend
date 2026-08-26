<script lang="ts">
    // InviteYourself — the portability hatch on the Door (Portability_todo §9).  Beside "invite a
    //  friend" (mint %Invite:Music — *what I will serve you*) sits this: the invite whose redemption
    //   MAKES you, not befriends you (%Invite:MyCave, the LinkDevice ceremony, §7).  V1 is honest
    //    about its depth: the DIALOGUE is real — it is the one place a person learns what carrying
    //     an identity to a second device means — and the ceremony itself is NOT built yet, so the
    //      QR affordance renders disabled and says so, rather than pretending or hiding.
    //  No props: this component reads no House state yet.  When the ceremony lands it will take H
    //   and drive Swarm_invite_url with a role Feature; today it is documentation with a doorknob.
    let open = $state(false)
</script>

<div class="iy">
    <button class="iy-open" onclick={() => open = !open}
        title="carry your identity to a second device — opens a short explanation">
        🪞 invite yourself {open ? '▾' : '▸'}
    </button>
    {#if open}
        <div class="iy-note">
            <p>
                One identity, many bodies. Your phone is the <b>Captain</b> — the soul's home, the
                social hand; it needs no folder access at all. A station with a real filesystem is
                the <b>Cave</b> — where the library lives, where Heists are fulfilled, where
                everything is backed up. What you'd Heist wanders to the Cave and waits there as
                treasure; music flows back to the phone as listening copies. Authority stays with
                the Captain; durability lives with the Cave.
            </p>
            <p>
                Inviting yourself carries your one identity to a second device: the same key, a new
                body, each doing the work it is placed to do. <b>This will move your key</b> — treat
                the QR like your key. It is shown once, lives minutes, works once, and is never
                posted anywhere; both devices stay online and show the same emoji pair before
                anything moves.
            </p>
            <button class="iy-qr" disabled
                title="the LinkDevice ceremony is not built yet — this dialogue is the map, honestly ahead of the road">
                ▦ show the LinkDevice QR
            </button>
            <span class="iy-soon">not built yet — coming soon</span>
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
    .iy-qr {
        pointer-events: auto;
        background: #241733;
        color: #6a5a74;
        border: 1px dashed #5a4a66;
        border-radius: 6px;
        font-size: 9px;
        padding: 3px 8px;
        cursor: not-allowed;
    }
    .iy-soon { font-size: 8px; color: #8a7a94; font-style: italic; margin-left: 5px; }
</style>
