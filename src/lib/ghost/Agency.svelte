<script lang="ts">
    import { keyser, type TheN } from "$lib/data/Stuff.svelte";
    import {Modus} from "$lib/mostly/Modus.svelte.ts";
    import { erring, nex } from "$lib/Y";
    import { onMount } from "svelte";

    let {M} = $props()
    const V = {}
    V.w = 1
    V.elvis = 1

    onMount(async () => {
    await M.eatfunc({





        
//#endregion
//#region elvis
    elvospec: `
        right. heading into the electronic hole.
        where do we go, from M**
         into M/A/w basically
          but it may have put an %e somewhere for something
           to set off a progress() or next()
        would replace the:
         that M/%io:radiostock interface
          so this protocol needs to talk-to|address the M?
           nah, just start from the A:*, search path of M...
          except for that one case of i_elvis now
           which does do_A() before agency_think()
           and shall simply point to '' at the A level?
         emit, perhaps
          would be handy to know where to put it on the other side
          perhaps one signs a map of what interfaces Pier is granted to
        I think...
          < agency_think() wants to be a Selection.process()
             of current events' journeys wanting to be D**
            or just a Travel? not even
        to keep it simple,
         A%elvis,Aw,... are put by your wild i_elvis()
         they route into A/w


        <  e%elvis:etype,uri,qua,v ...

    `,
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
    say_Aw(w) {
        let A = w.up
        return `${A.sc.A||'???'}/${w.sc.w||'???'}`
        return `A:${A.sc.A||'???'}/w:${w.sc.w||'???'}`
    },
    i_elvis(w,t,c) {
        // < interesting, needs trimming
        // let stack = new Error().stack
        setTimeout(() => {
            // by default, w wants to wake itself, probably from out of time
            t ||= 'noop'
            c ||= {}
            if (!(c.A || c.Aw)) c.A = w
            // this is the address scheme
            let given_A // might be a w
            let to_A
            if (c.A) {
                // given by object, derive a path of names (Aw)
                let w = given_A = c.A
                // < A is TheA, w is also and has w.up=A
                let A = to_A = w.up || w
                c.Aw = A.sc.A
                if (w != A) {
                    // they're pointing to a specific w by object
                    c.Aw += '/'+w.sc.w
                }
                delete c.A
            }
            if (c.Aw == null) throw "%elvis,!Aw"
            c = {elvis:t,...c}

            let from = this.say_Aw(w)
            let say = from
            if (from != c.Aw) say += ` -> ${c.Aw }`
            V.elvis && console.log(`🕺 ${say} e:${c.elvis} ${keyser(nex({},c,'elvis,Aw'))} `)

            // deliver it to an A
            let [Aname,...more] = c.Aw.split("/")
            // which could be on another Modus, they should have F/M*/A* unique names
            // < it can't pick a Pier modus from the Feature though...
            //    you've got to give something that replies, eg see return_fn
            let A
            for (let M of this.S.every_Modus()) {
                A = M.o({A:Aname})[0]
                if (A) break
            }
            if (!A) {
                // however, we don't know which PF it might be for from an F/M...
                //  so rely on them passing w which can .up.M to find Modus
                A = to_A.M.o({A:Aname})[0]
            }
            if (!A) throw `!A %elvis=${t},Aw=${c.Aw}`
            // gives eg A:way/%elvis to w:way if no more %Aw
            //  if there's only one A:way/w it'll deliver it there regardless
            //   since eg we can get e:noop returned while %satisfied changes w
            c.Aw = more.length ? more.join("/") : Aname
            A.i(c)

            // and request main() ASAP
            //  < model wants, progress, which journeys are actively doing stuff
            this.main()
        },11)
    },

    // the odd case of elvising to Modus itself ? used to do_A()
    Modus_i_elvis(t,c) {
        setTimeout(() => {
            this.i({elvis:t,...c})
            this.main()
        },11)
    },
    // serve the above, not in any A, doing whatever else afterwards
    async handle_elvising_to_Modus() {
        // for the sake of singularity, here's elvising Modus:
        for (let e of this.o({elvis:1})) {
            if (e.sc.elvis == 'do' && e.sc.fn) {
                await e.sc.fn()
            }
            else {
                throw "at Modus, e!does"
            }
            e.drop(e)
        }
    },

    // apply any A%elvis,Aw schemes to a set of A/w*
    // returns which of these w now have %elvis to handle, routed from A
    async elvised_A_w(A,wN:TheN) {
        let yes = [] as TheN
        let find_w = async (e) => {
            let [wname,...more] = e.sc.Aw.split("/")
            if (more.length) throw "more Aw"

            let itis = (w) => {
                yes.push(w)
                // transfer %elvis onto the %w
                w.i(nex({},e.sc,'Aw'))
                e.drop(e)
            }
            for (let w of wN){
                if (w.sc.w == wname) {
                    return itis(w)
                }
            }
            if (wN.length == 1) {
                // in the case of one A/w, we assume it has just changed into w:meander or so
                return itis(wN[0])
            }
            throw `A:${A.sc.A} /!w %elvis=${e.sc.elvis},Aw=${e.sc.Aw}`
        }
        for (let e of A.o({elvis:1})) {
            await find_w(e)
        }
        return yes
    },

    // application code services all awaiting w%elvis
    o_elvis(w,t) {
        let them = w.o({elvis:t})
        for (let e of them) {
            e.c.served = true
            w.i({see:'e',elviserved:t,e})
        }
        return them
    },
    // checks expected o_elvis() happened
    elvised_completely(A,w) {
        let them = w.o({elvis:1})
        them.length && this.o_elvis(w,'noop')
        for (let e of them.filter(e => e.c.served)) {
            e.drop(e)
        }
        for (let e of them.filter(e => !e.c.served)) {
            throw `A:${A.sc.A}/w:${w.sc.w}/%elvis=${e.sc.elvis} not served`
        }
    },

    // on SharesModus are two undeveloped w for testing elvising
    async ragate(A,w) {
        // < what to do as|with the bunch of music shares? redundancy?
            w.i({see:"This big thing","Tis all":1})
            // await this.Stuffusion_innersmuddle(A,w)
        return
        if (w.o1({round:1,self:1})[0] % 2) {
            this.i_elvis(w,'yap',{Aw:'raglance',te:'some'})
            this.i_elvis(w,'yap',{Aw:'raglance',te:'lots'})
            // Helper to schedule test messages
            const yap = (delay: number, te: string | string[]) => {
                setTimeout(() => {
                    const tes = Array.isArray(te) ? te : [te]
                    tes.forEach(t => this.i_elvis(w,'yap', {Aw: 'raglance', te: t}))
                }, delay)
            }
            // Compressed test data
            yap(34, 'grunge')
            yap(88, 'rowing')
            yap(133, 'mountains')
            yap(600, ['lots', 'grunge', 'eek'])
            yap(933, 'grunge')
        }
        
    },
    async raglance(A,w) {
        // < what to do as|with the bunch of music shares? redundancy?
        for (let e of this.o_elvis(w,'yap')) {
            w.i({see:"thisyap",that:`goes ${e.sc.te}`})
        }
    },


//#endregion
//#region Agency



    // all A/w think
    async agency_think() {
        await this.handle_elvising_to_Modus()

        let AN = this.o({A:1})
        // if some A have pending events, concentrate on them
        let eventedAN = AN.filter(A => A.oa({elvis:1}))
        AN = eventedAN.length ? eventedAN : AN
        let AwN = []
        for (let A of AN) {
            await this.self_timekeeping(A)

            // gives eg A:way an w:way if empty
            let wN = this.procure_ways(A)
            // if some A/w attract pending events, concentrate on them
            let eventedwN = await this.elvised_A_w(A,wN)
            wN = eventedwN.length ? eventedwN : wN

            for (let w of wN) {
                await this.self_timekeeping(w)

                let verb = eventedwN.length ? 'elvis' : 'think'
                V.w>1 && console.log(`${verb} A:${A.sc.A} / w:${w.sc.w}`)
                await this.Aw_think(A,w)
                AwN.push({A,w})
            }
            // javascript facts: this for AN is not done enumerating
            //  if you do this we never leave this loop:
            // AN.push(A)
        }
        
        // wrapped in mutex for each w involved
        let soupup = async (N) => {
            let fn = N[0]
            if (typeof fn == 'function') return await fn()
            await this.c_mutex(fn,'Aw_think', async () => {
                await soupup(N.slice(1))
            })
        }
        // soupup([...AwN.map(c => c.w), async () => {
            await this.agency_officing(AwN,AN)
        // }])
    },
    procure_ways(A):TheN {
        let wN = A.oa({w:1})
        if (!wN) {
            if (A.c.template_w_sc) {
                // one other w may be reset to, see Areset(A)
                wN = [A.i({...A.c.template_w_sc})]
            }
            if (!wN) {
                wN = [A.i({w:A.sc.A})]
            }
        }
        if (wN[0]) A.c.template_w_sc ||= {...wN[0].sc}
        return wN
    },

    // process job, w
    async Aw_think(A,w) {
        // < make these TheA? which does this:
        w.up = A
        A.M = this



        let method = w.sc.w
        if (method && this[method]) {
            try {
                await this.c_mutex(w,'Aw_think', async () => {
                    await w.r({waits:1},{})
                    await w.r({error:1},{})
                    await w.r({see:1},{})

                    await this[method](A,w,w.sc.had)

                    // in-method-error-throwing problems of officing
                    this.elvised_completely(A,w)
                })
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

    // return true if a w doesn't need to happen

    async w_ambiently_sleeping(w,times:number=4) {
        await w.r({self:1,sleeping:1},{})
        // has an event to process
        if (w.oa({elvis:1})) return false
        // h
        let round = w.o1({round:1,self:1})
        if (round == 1) return false
        if (!(round % times)) return false
        w.i({self:1,sleeping:`not the ${times}-1 time`})
        return true
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
    // w can mutate
    async Aw_satisfied(A,w,sa) {
        // take instructions
        let next_method = w.sc.then || "out_of_instructions"
        let c = {w:next_method}
        if (sa.sc.with) c.had = sa.sc.with

        // change what this A is wanting
        let nu = A.i(c)
        nu.up = A
        // want to attend it immediately
        this.i_elvis(w,'noop',{A:nu,way_thenced:1})
        // < GOING? we're not replacing w anymore? just drop and insert
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
        let topD = this.Tr.sc.D
        // < why are there no %journeys at this point? huh?
        for (let j of topD.o({journey:1,oaims:1})) {
            // let was = j.oa({path:1}) ? this.Se.j_to_uri(j) : '??'
            // console.log(`${this.constructor.name} journeys were: ${j.sc.journey} to ${was}`)
        }

        for (let c of AwN) {
            let {A,w} = c
            let i = 0
            for (let ai of w.o({aim:1})) {
                // < are duplicate names ok? what to do about it?
                let jc = {...c,ai}
                jc.journey = this.name_A(A)+(i++ ? "+"+i : "")
                AwjN.push(jc)


                let to = ai.o1({summary:1})[0]
                jc.path_was = to
                await ai.r({summary:this.Se.j_to_uri(ai),of_where:'its going'})
                jc.path_now = ai.o1({summary:1})[0]
            }
        }
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
                // < i_j_j(j,j)
                for (let n of ai.o({path:1})) {
                    j.i(n.sc)
                }
            })
            // a tiny Selection.process() watching path change
            if (c.path_now != c.path_was) {
                V.w && console.log(`changed journey: j:${j.sc.journey}\t${c.path_was}\t->\t${c.path_now}`)
                // < also eg w:radiostock/%waits:A:Directory should there and back
                this.i_elvis(w,'putjourney',{Aw:'Directory',from:w.sc.w,reply:A})
            }

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
//#region util
    async requesty_serial(w,t) {
        let reqserialc = {}
        reqserialc['requesty_'+t+'_serial'] = 1
        let reqc = {}
        reqc['requesty_'+t] = 1
        let req_serial:TheC
        let ison = async () => {
            console.log(`requesty_serial(w,${t})`)
            req_serial = w.o({...reqserialc})[0]
            req_serial ||= await w.r({...reqserialc,i:1})
            req_serial.sc.i ||= 7
            ison = async () => {}
        }
        return {
            pending: w.o(({...reqc})).length,
            async i(c) {
                await ison()
                let req = await w.r({...reqc,...c},{...c})
                req.sc.req_i ||= req_serial.sc.i++
                return req
            },
            o(sc={}) {
                // you can use sc to check for existing workpiece id before you .i()
                //  if your quest has a bouncy beginning (tries to i many times)
                return w.o(({...reqc,...sc}))
            },
        }
    },







//#endregion
//#region methods

    // eg M/%spare_worker=A:hunting indicates capacity to make more records
    async rest(A,w) {
        w.i({see:"At rest"})
        w.r({aim:1},{})
        await A.r({resting:1})
    },

    // just dropping the w should bring them back!
    async Areset(A) {
        await this.c_mutex(this,'Areset',async () => {
            await A.r({w:1},{})
        })
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
            
            this.main() // < can it aim at A/* ?
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
        if (A.c.meander_then) {
            w.sc.then = A.c.meander_then
        }

        // check we're finding anything, avoid spinning in edge cases
        // anything includes directories
        let found_anything = false
        if (w.sc.seems_to_be_empty) {
            if (await this.w_ambiently_sleeping(w,6)) return
        }
        const GIVE_UP = 16
        if (w.o({meanderings:1}).length > GIVE_UP) {
            // meanderings build up as we keep looking but not finding,
            //  engage hopelessness to conserve cpu time
            console.warn(`share seems trackless? giving up`)
            w.sc.then = 'rest'
            await w.r({satisfied:1})
            return
        }

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
                // this function is key, it is satisfied with D%track
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
                    // stay out of .jamsend/
                    .filter(D => !D.oa({fs_scheme:1}))

            }
            // pick one
            dir = dirs[this.prandle(dirs.length)]
            if (!dir) {
                if (!found_anything) {
                    w.sc.seems_to_be_empty = true
                    // < more of a mutter than a warn, for blaming the user
                    console.warn(`empty share: ${this.S.name}`)
                    break
                }
                else {
                    console.log("cul-de-sac: "+supposed_path)
                    // throw out w/%aim, try again from the top
                    await w.r({aim:1},{})
                    continue
                }
            }
            found_anything = true
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
        if (found_anything) {
            delete w.sc.seems_to_be_empty
        }

        // %aim spawns a journey, we follow up our %aim next time
    },

















    
    })
    })
    // < get it able to at least consume Modus.* types:
    //  as Modus
</script>