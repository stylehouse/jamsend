<script lang="ts">
    import { onMount } from "svelte";

    let {M} = $props()

    onMount(() => {
        M.main()
    })
    M.eatfunc({
        broadcaster(A,w) {
            w.r({these:33,switch:99})
            return
            let tr = A.r({A:'transmit'})
            let en = A.r({A:'encoders'})
            let me = A.r({A:'media'})
        },
        transmit(A,w) {
            
        }
    })
</script>