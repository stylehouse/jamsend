<script lang="ts">
    import { onMount } from "svelte";

    let {M} = $props()

    onMount(() => {
        M.main()
    })
    M.eatfunc({





        
//#endregion
//#region elvis
    // during main() is a time of instability in M**
    //   mingling threads of execution can cause eg double replace()
    //  so event handlers may post their jobs into this queue
    //  so they can happen just before next main(), thus stable and poised for affect
    // < better job queue?
    //    eg having all Modus on the page merge their intervals into a common rhythm
    //    and having misc like this await for a clearing
    //   time sharing is easier than space sharing?
    //    though %Tree** separates a lot of the computation...
    needs_your_attention: [] as Function[],
    i_elvis(fn) {
        this.needs_your_attention.push(fn)
        // and request main() ASAP
        //  < model wants, progress, which journeys are actively doing stuff
        this.main()
    },
    async o_elvis(fn) {
        for (let fn of this.needs_your_attention) {
            await fn()
        }
        this.needs_your_attention = []
    },




//#endregion
//#region Agency



    // process job, w
    async Aw_think(A,w) {
        let method = w.sc.w
        if (method && this[method]) {
            try {
                await w.r({waits:1},{})
                await w.r({error:1},{})
                await w.r({see:1},{})

                await this[method](A,w,w.sc.had)
            } catch (error) {
                w.i({error: error.message || String(error)})
                if (w.c.error_fn) {
                    let ok = await w.c.error_fn(error)
                    if (ok) return
                }
                console.error(`Error in method ${method}:`, error)
                // 
            }
        }
        else {
            if (method) w.i({error:`!method`})
            // < refer other %w to central stuck-trol?
            return
        }
    },
    // w can mutate
    async Aw_satisfied(A,w,sa) {
        // take instructions
        let next_method = w.sc.then || "out_of_instructions"
        let c = {w:next_method}
        if (sa.sc.with) c.had = sa.sc.with

        // change what this A is wanting
        let nu = A.i(c)
        // < how better to express about avoiding|kind-of being resolved
        // not resyncing nu/*
        nu.empty()
        // take %aim, ie keep pointers for the rest of A
        // < this kind of transfer wants a deep clone ideally?
        for (let ai of w.o({aim:1})) {
            nu.i(ai)
        }
        A.drop(w)
    },

    // all A/w think
    async agency_think() {
        let AwN = []
        let AN = []
        for (let A of this.current.o({A:1})) {
            await this.self_timekeeping(A)

            for (let w of A.o({w:1})) {
                await this.self_timekeeping(w)

                await this.Aw_think(A,w)
                AwN.push({A,w})
            }
            AN.push(A)
        }
        this.agency_officing(AwN,AN)
    },
    async agency_officing(AwN,AN) {
        // percolate w/ai/%path -> j/%path from this A
        await this.i_journeys_o_aims(AwN)
        for (let {A,w} of AwN) {
            // percolate w%unemits -> PF.unemit.*
            await this.i_unemits_o_Aw(A,w)
        }
        for (let {A,w} of AwN) {
            // w can mutate
            for (let sa of w.o({satisfied:1})) {
                await this.Aw_satisfied(A,w,sa)
            }
        }
        // < test effects of this... not sure
        // it's on now! see KEEP_WHOLE_w in comments for dependos
        const KEEP_WHOLE_w = true
        for (let A of AN) {
            // w can mutate sc eg %then
            //  so keep writing it down
            let ws = A.o({w:1})
            await A.replace({w:1},async () => {
                ws.map(w => {
                    KEEP_WHOLE_w ? A.i(w).is()
                        : A.i(w.sc)
                })
            })
        }
    },



//#endregion
//#region -> journey

    // name an A with a %w etc
    name_A_thing(A,th) {
        let thingsay = th.sc.w ? "."+th.sc.w
            : "?"
        return this.name_A(A)+thingsay
    },
    // name an A
    name_A(A) {
        return "A:"+A.sc.A
    },
    // < io tupling use
    async i_journeys_o_aims(AwN) {
        if (!this.Tr) return
        // replace a particular journey that comes from this A
        // have *%journey ideas first
        let AwjN = []
        for (let c of AwN) {
            let {A,w} = c
            let i = 0
            for (let ai of w.o({aim:1})) {
                // < are duplicate names ok? what to do about it?
                c.journey = this.name_A(A)+(i++ ? "+"+i : "")
                AwjN.push({...c,ai})
            }
        }
        let topD = this.Tr.sc.D
        // replace D/*%journey
        await topD.replace({journey:1,oaims:1}, async () => {
            for (let c of AwjN) {
                c.j = topD.i({journey:c.journey,oaims:1})
            }
        })
        // then replace what is in %journey
        for (let c of AwjN) {
            let {A,w,j,ai} = c

            // < method this? see PrevNextoid
            // i j/* o ai/*%path
            // console.log(`j:${j.sc.journey} ai path:${this.Se.j_to_uri(ai)}`)
            await j.replace({path:1}, async () => {
                for (let n of ai.o({path:1})) {
                    j.i(n.sc)
                }
            })
            await j.r({gaveup:1},{})
            // < note somehow this ai->j vectoring
        }

    },

    // percolate w%unemits -> PF.unemit.*
    // instead of addressing PF.emit()s to a %w,
    //  suppose each message type will be belong to one %w
    async i_unemits_o_Aw(A,w) {
        if (!w.sc.unemits) return
        for (let [type,handler] of Object.entries(w.sc.unemits)) {
            // type becomes+unbecomes type=ftp.$k when PF.emit is used
            this.PF.unemits[type] = async (data,{P,Pier}) => {
                let served = false
                // find and serve to all handlers
                for (let A of this.o({A:1})) {
                    for (let w of A.o({w:1})) {
                        let handler = w.sc.unemits?.[type]
                        if (handler) {
                            served = true
                            await handler(data,{P,Pier})
                        }
                    }
                }
                if (!served) {
                    return console.warn(`${this} unemit Aw !handler for message type:`, data);
                }
            }
        }
    },








//#endregion
//#region methods

    // eg M/%spare_worker=A:hunting indicates capacity to make more records
    async rest(A,w) {
        w.i({see:"At rest"})
        await A.r({resting:1})
    },
    // < specify radiostock worker, radiostream worker
    //    and handle resource contention
    // look for and engage one of them, supposing they just need reset
    async unrest():Promise<TheC|undefined> {
        for (let A of this.o({A:1})) {
            if (!A.oa({resting:1})) continue
            await A.c.reset_Aw()
            await A.r({resting:1},{})

            let was_reset = (A.o1({was_reset:1})[0] || 0) + 1
            await A.r({was_reset})
            
            this.main()
            return true
        }
    },
    async out_of_instructions(A,w) {
        console.warn("out_of_instructions!")
    },

    // do meandering
    // may not find very small collections of music
    //  where everything playable is within journey:auto's from-the-top-ness, so we avoid it
    // may not find tracks not in a directory, because we want directory then track
    async meander(A:TheC,w:TheC) {
        let loopy = 11
        let dir:TheD
        while (1) {
            if (loopy-- < 0) return w.i({error:'loooopy'})

            // where we're looking
            let ai = w.o({aim:1})[0]
            let supposed_path = ai && this.Se.j_to_uri(ai) || "??"
            let D
            if (ai) {
                D = this.Se.j_to_D(ai)

                let ope = D && D.o1({v:1,openity:1})[0]
                let aim = this.Se.j_to_uri(ai)
                if (D && ope <3) {
                    // we must wait for a Selection.process() for this
                    // < do only that journey if the others are docile?
                    return
                }
            }


            let inners = null
            if (D) {
                let good = await this.is_meander_satisfied(A,w,D)
                if (good) {
                    await w.r({satisfied:1,with:D})
                    return
                }
                // Tdebug(D.c.T,"meandering into")
                // keep meandering into D**, until none found
                // o D/*%Tree
                inners = D.oa(this.Se.c.trace_sc)
            }

            // o **%nib,dirs
            let dirs = inners
            if (!dirs) {
                dirs = this.get_sleeping_T().map(T => T.sc.D)

            }
            // pick one
            dir = dirs[this.prandle(dirs.length)]
            if (!dir) {
                console.log("cul-de-sac: "+supposed_path)
                // throw out w/%aim, try again from the top
                await w.replace({aim:1},async() => {
                })
                continue
            }
            if (dir == D) {
                throw `loopily: ${keyser(D)}`
            }

            ai = await w.r({aim:1})
            // < this could be r_path, return the old one?
            await ai.replace({path:1}, async () => {
                this.Se.i_path(ai,dir)
            })
            // and log how many times this process goes around:
            w.i({meanderings:1,uri:this.Se.D_to_uri(dir)})
        }

        // %aim spawns a journey, we follow up our %aim next time
    },

















    
    })
</script>