<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import type { SoundSystem } from "../ftp/Audio.svelte";

    let { gat }: { gat: SoundSystem } = $props();
    onMount(async () => {
        console.log("AC: somewhere")
        // < murk. something like an uncatchable throw happens to this try_init() call
        //    which does AC_OK() which attempts AC.resume()...
        //    basically calls to AC_OK() may disappear without a trace
        //     but the first time it comes with a warning: 
        //       The AudioContext was not allowed to start.
        //       It must be resumed (or created) after a user gesture on the page.
        setTimeout(try_init,0) 
        setTimeout(check_it,50) 
    })
    async function try_init() {
        // once to create .AC and try AC_OK() once:
        await gat.init()
    }
    async function check_it() {
        if (!gat.AC_ready) {
            window.dispatchEvent(new CustomEvent('AudioContext_wanted', { 
                detail: { gat } 
            }));
        }
        else {
            // console.log("AC: immediately ready")
        }
    }
</script>