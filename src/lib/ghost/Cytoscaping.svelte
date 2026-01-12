<script lang="ts">
    import { onMount } from "svelte";

    import { _C, keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
    import { erring, ex, grep, grop, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import Record from "./Records.svelte";
    import Cytoscape from "$lib/mostly/Cytoscape.svelte";
   
    let {M} = $props()

    onMount(async () => {
    await M.eatfunc({

        // on the PF Sharee
        async cytotermicaster(A,w) {
            w.i({see:"Some great visuals"})

            // "takes over" doing visuals for the Modus
            this.VJ = await w.r({VJ:w,UI_component:Cytoscape})
            for (let e of this.o_elvis(w,'IamyourUI')) {
                await w.r(sex({cytool:1},e.sc,'node_edger'))
            }
            if (!w.oa({cytool:1,node_edger:1})) return w.i({waits:'for UI'})

            let {np,io} = await this.termicaster_resources(A,w)
            // np frontend and io backend.
            // these two things talk to each other at either end
            //  ie their nowPlaying attracts our radiopiracy
            // when we have both they're doing different work, independently
            if (np) {
                let uri = np.sc.uri
                if (uri != w.o1({uri:1,descripted:1})[0]) {
                    // ask for it
                    if (!w.oa({uri,wants_descripted:1})) {
                        console.log(`want o_descripted`)
                        await this.PF.emit('o_descripted',{uri:np.sc.uri})
                        w.i({uri,wants_descripted:1})
                    }
                }
                else {
                    await w.r({uri,wants_descripted:1})
                    // we have the info!

                    w.i({see:"haveit",theinfo:"descripted"})
                }
            }
        },



        // we'll be connected to one or both of
        async termicaster_resources(A,w) {
            let raterm = this.o({A:'audio'})[0]?.o({w:'raterminal'})[0]
            w.i({see:1,raterm})
            let np
            if (raterm) {
                let no = raterm.o({nowPlaying:1})[0]
                // copy it here, shallowly except for %nowPlaying:he
                np = no && await w.r({...no.sc})
            }


            let racast = this.o({A:'audio'})[0]?.o({w:'racaster'})[0]
            w.i({see:1,racast})
            let io
            if (racast) {
                // copy %io:radiopiracy interfaces here
                await this.Miome(A,{io:'radiopiracy'})
                if (!A.oa({io:'radiopiracy'})) throw "not there!"
                io = A.o({io:'radiopiracy'})[0]
            }

            // when we have both they're doing different work, independently


            w.sc.unemits ||= {
                o_descripted: async ({uri}:{uri:string}) => {
                    w = this.refresh_C([A,w])
                    await this.c_mutex(w,'o_descripted', async () => {
                        w = this.refresh_C([A,w])

                        if (!io) throw "can't opiracy"
                        console.log(`got unemit opiracy: ${uri}`)
                        io.sc.opiracy(uri)
                    })
                },
                i_descripted: async ({uri,N}:{uri:string}) => {
                    w = this.refresh_C([A,w])
                    await this.c_mutex(w,'i_descripted', async () => {
                        w = this.refresh_C([A,w])

                        let de = await w.r({uri:1,descripted:1})
                        de.i({info:3})
                        de.i({info:6,above:1})
                        de.i({info:9,nearer:1})
                        this.i_elvis(w)
                    })
                },
            }
            return {np,io}
        },



        // in a DirectoryModus, a shipping clerk
        async rapiracy(A,w) {
            this.r({io:'radiopiracy'},{
                opiracy: async (uri) => {
                    w = this.refresh_C([A,w])

                    w.i({request_descripted:uri})
                    this.i_elvis(w)
                },
            })

            for (let rd of w.o({request_descripted:1})) {
                w.i({see:"gotta do something about",thisdescripted:rd})
            }
        }

        

    })
    })
</script>
