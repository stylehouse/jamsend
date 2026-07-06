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

    let { url, size = 220, caption = 'scan to join — point a phone camera here' }: {
        url:      string
        size?:    number
        caption?: string
    } = $props()

    let copied = $state(false)
    let timer: ReturnType<typeof setTimeout> | undefined

    async function copy() {
        try { await navigator.clipboard.writeText(url) } catch { /* no clipboard — the link is still visible below */ }
        copied = true
        if (timer) clearTimeout(timer)
        timer = setTimeout(() => (copied = false), 1600)
    }
</script>

<div class="iq">
    {#if url}
        <div class="iq-qr"><QrCode value={url} {size} /></div>
        <p class="iq-cap">{caption}</p>
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
        padding: 0.6rem; border-radius: 8px; background: #fff;
    }
    /* svelte-qrcode renders an <img>; keep its box crisp and white so a camera reads it */
    .iq-qr { line-height: 0; }
    .iq-cap { margin: 0; font-size: 0.72rem; color: #556; text-align: center; max-width: 15rem; }
    .iq-link {
        background: none; border: 1px solid #ccd; color: #445;
        cursor: pointer; font-size: 0.72rem; padding: 0.1rem 0.5rem; border-radius: 4px;
    }
    .iq-link:hover { border-color: #99a; color: #223; }
    .iq-empty { margin: 0; font-size: 0.72rem; color: #99a; }
</style>
