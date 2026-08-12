<script lang="ts">
    // InviteQR — the Invite front door's face: an on-screen QR of a ?Iz= invite URL, so a
    //   phone camera can scan-to-join (the "monkey business" — point a phone at the screen and
    //    it gains a %Pier to pull music from).  PURE presentation: it renders a url it is GIVEN;
    //     the mint (Swarm_mint_idzeug against the live self) happens in the .g and hands the url
    //      in.  Online-scan model — the inviter stays on this screen while the phone redeems, so
    //       the redeem's dial-home lands (Swarm_spec §10.1).
    //   Mirrors the proven p2p/ui/ShareButton QR usage of svelte-qrcode (already a dep); a
    //    reusable ui/micro/ scrap beside DeleteX/Orb.
    import QrCode from "svelte-qrcode"

    // pad — the QUIET ZONE, riding INSIDE the image (qrious padding): the QR spec wants ~4 modules
    //  of white on ALL sides or scanners misread. In-image is the only reliable place for it — a
    //   container's padding can be cropped/collapsed by styling (the old ShareButton generator ran
    //    padding=0 and sat flush at top+left, confounding scans) — and it costs no extra screen:
    //     the white scales with `size` instead of stacking chrome around it.
    // bg/ink — the QR's own colours (qrious background/foreground). Default is TAN on near-black
    //  ink, not white — softer on a dark app. For the blended full-screen face pass bg='#ffffff'
    //   and put mix-blend-mode:multiply on the img (bare=true drops the card chrome so the blend
    //    reads the backdrop): white multiplies to EXACTLY the backdrop colour while the ink stays
    //     ink — the QR takes any nice colour with zero contrast loss.
    let { url, size = 220, pad = 16, bg = '#ead9b6', ink = '#241a10', bare = false,
          caption = 'scan to join — point a phone camera here' }: {
        url:      string
        size?:    number
        pad?:     number
        bg?:      string
        ink?:     string
        bare?:    boolean
        caption?: string
    } = $props()

    let copied = $state(false)
    let timer: ReturnType<typeof setTimeout> | undefined

    // STOP THE CLICK HERE.  The fullscreen face (InvitePanel `.ip-overlay`) closes on ANY click by
    //  design — the QR fills the viewport, so a stopPropagation on it left no escapable margin.  This
    //   button is not part of that: letting it bubble copied the link AND tore the face down in the
    //    same tick, so the `✓ copied` it sets is never seen and the user cannot tell it worked.  Same
    //     carve-out the blotter chip already takes beside it.
    async function copy(e: MouseEvent) {
        e.stopPropagation()
        try { await navigator.clipboard.writeText(url) } catch { /* no clipboard — the link is still visible below */ }
        copied = true
        if (timer) clearTimeout(timer)
        timer = setTimeout(() => (copied = false), 1600)
    }
</script>

<div class="iq" class:iq-bare={bare}>
    {#if url}
        <div class="iq-qr"><QrCode value={url} {size} padding={pad} background={bg} color={ink} /></div>
        {#if caption}<p class="iq-cap">{caption}</p>{/if}
        <button class="iq-link" title="copy the invite link" onclick={copy}>
            {copied ? '✓ copied' : 'copy link'}
        </button>
    {:else}
        <p class="iq-empty">no invite yet</p>
    {/if}
</div>

<style>
    .iq {
        display: inline-flex; flex-direction: column; align-items: center; gap: 0.4rem;
        padding: 0.6rem; border-radius: 8px; background: #ead9b6;
    }
    /* bare — no card of its own: the full-screen blend face provides the backdrop */
    .iq-bare { background: transparent; padding: 0; }
    /* svelte-qrcode renders an <img>; keep its box crisp and white so a camera reads it */
    .iq-qr { line-height: 0; }
    .iq-cap { margin: 0; font-size: 0.72rem; color: #556; text-align: center; max-width: 15rem; }
    /* THE SECOND DOOR, and it is the one a laptop uses — a phone scans the QR, everyone else copies
        the link.  It sat at caption size (0.72rem, hairline border) reading as a footnote to the
         image; the owner asked for it bigger.  Sized as a real target now: ~44px tall, which is the
          touch minimum, and wide enough to hit without aiming. */
    .iq-link {
        background: none; border: 2px solid #99a; color: #334;
        cursor: pointer; font-size: 1rem; font-weight: 600; letter-spacing: 0.01em;
        padding: 0.6rem 1.4rem; border-radius: 8px; min-height: 2.75rem;
        margin-top: 0.2rem;
    }
    .iq-link:hover { border-color: #556; color: #112; background: rgba(0, 0, 0, 0.05); }
    .iq-link:active { transform: translateY(1px); }
    .iq-empty { margin: 0; font-size: 0.72rem; color: #99a; }
</style>
