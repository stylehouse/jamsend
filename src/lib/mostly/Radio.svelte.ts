import { _C, keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
import type { FileListing } from "$lib/p2p/ftp/Directory.svelte.ts"
import type { PeeringSharing, PierSharing } from "$lib/p2p/ftp/Sharing.svelte.ts"
import { now_in_seconds_with_ms, now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
import { erring, ex, grep, grop, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
import {Modus} from "./Modus.svelte.ts"
import { RecordModus } from "./Record.svelte.ts"
import type { TheD } from "./Selection.svelte.ts"

const PREVIEW_DURATION = 21.58 // seconds of preview
const STAY_AHEAD_OF_ACK_SEQ = 4 // many re/pr to load head
const V = {
    plau: 1,
    irec: 1
}

//#endregion
//#region radiostock

export class RadioModus extends RecordModus {
    // Audio things haver
    //  Modus.stop() happens reliably, avoiding zombie sounds
    gat:SoundSystem
    constructor(opt:Partial<Modus>) {
        super(opt)
        this.gat = new SoundSystem({M:this})
    }
    do_stop() {
        // on UI:Modus destroy
        this.gat?.close()
    }

    // side note,
    //  about the falling-ness of this** C
    //  we KEEP_WHOLE_w so the object w might be kinda robust (longer lived) now
    //   but other C that get w.r({bits}) will be renewed
    //    taking the C.sc.* to a new C essentially
    //   so you can't capture C and then expect C.i() to operate on the current time of it
    //   unless you use refresh_C()
    //  so functions created only the first time
    //    eg w:radiobroadcaster / unemits / orecord
    //   capture values of C that get buried in the past
    //  %record though (aka rec, re)
    //    just sit there!
    //  in w:radiobroadcaster you can put this:
        // // an experiment into using refresh_C() at loose times
        // if (w.oa({self:1,round:2})) {
        //     let i = 1
        //     setInterval(() => {
        //         let tick = "b"+i
        //         rr = this.refresh_C([A,w,wh,rr])
        //         rr.i({tock:tick})
        //         io.sc.ticking(tick)
        //         i++
        //     },400)
        // }
    //  and in its w.sc.unemits.orecord, put this:
        //  io.sc.ticking("out of timeity")
    //  and in w:radiostock io.o(client), put this:
        // ticking: async (say) => {
        //     w = this.refresh_C([A,w])
        //     w.i({tick:say})
        // }

    // the next two methods occur in parallel in the same Modus
    //  M/%spare_worker=A:hunting indicates capacity to make more records

    // radio pools into the unsatisfiable task of keeping stock
    async radiostock(A,w) {
        // races to keep stock ahead of pointers
        // < needs timeout? await Pier.promise_destroy?
        let co = await w.r({consumers:1,of:'radiostock'})

        // advertise an API of this Modus
        this.r({io:'radiostock'},{
            i: async (re:TheC) => {
                w = this.refresh_C([A,w])
                // first it comes into the cache here, available to Piers
                if (A.oa({record:1,enid:re.sc.enid})) {
                    console.log(`radiostock.i() DUP ${re.sc.enid} (dropped)`)
                    return
                }
                
                A.i(re)
                // it's the same C, so we "have" new /*%preview as they come in
                //                              (see Cpromise() for knowing when)
                //  and lose /%in_progress

                // have a downstream Modus waiting for this
                w.o({excitable:'radiostock i'})
                    .map(ex => ex.sc.client)
                    .map(M => M.main())
                    .length && w.r({excitable:'radiostock i'},{})
            },
            o: async (client:TheC) => {
                w = this.refresh_C([A,w])
                let them = A.o({record:1})
                
                let current = await this.co_cursor_N_next(co,client,them)
                if (!current) {
                    // no new %record is available so don't return one (via wrap around)
                    //  the broadcaster shall stay ahead of terminals usually

                    await w.r({excitable:'radiostock i',client})
                    // this chases the other A back into making more %record
                    await this.unrest()
                    return
                }
                await this.co_cursor_save(co,client,current)
                return current
            },
            // this interface starts streams
            //  zapped a subtype of broadcaster's unemit:orecord
            ostream: async (re:TheC) => {
                this.o({A:'streaming'}).map(A => {
                    A.o({w:'radiostreaming'}).map(w => {
                        w.c.ostream(re)
                    })
                })
            },
        })

        if ('only what we made') return

        // and may cache on the filesystem for spanglier startups
        await this.radiostock_caching(A,w)
    }
    async radiostock_caching(A,w) {
        // the .jamsend/radiostock/ directory D
        let stockD
        let keep_things = 20
        stockD = await this.aim_to_open(w,['.jamsend','radiostock'])
        if (!stockD) return // also when ope<3

        // our records...
        let had = A.o({record:1})
        for (let re of had) {
            if (!re.oa({in_radiostock:1})) {
                // wants saving to disk once whole
                if (!re.oa({in_progress:1})) {
                    await this.record_to_disk(re,stockD)
                }
            }
        }

        let radiostock = this.o({io:'radiostock'})[0]
        if (!radiostock) return w.i({waits:"%io:radiostock"})
        // load some
        if (had.length < keep_things * 0.8) {
            let to_load = 5 // not to much work per A
            for await (const re of this.load_random_records(stockD, to_load,had)) {
                await radiostock.sc.i(re)
            }
        }
        
        // whittle to 20 things
        this.whittle_N(A.o({record:1}),keep_things)
        await this.whittle_stock(w,stockD,keep_things)
    }

    //#endregion
    //#region radiostreaming
    async radiostreaming(A,w) {
        // await need
        w.c.ostream = async (re) => {
            let {enid} = re.sc
            if (w.oa({streamable:1,re,enid})) {
                // don't reset when we don't need to
                console.log(`Already streaming ${enid}`)
                return
            }
            for (let st of w.o({streamable:1})) {
                st.c.stop?.()
            }
            // we do the work in w/* rather than under w/st/*, so:
            w.empty()
            w.i({streamable:1,re,enid})
            this.main()
        }

        let st = w.o({streamable:1})[0]
        if (!st) return w.i({see:"At rest"})

        // process a %streamable,re
        let re = st.sc.re
        let uri = re.sc.uri
        let enid = re.sc.enid
        let path = uri.split('/')
        // resolve ourselves to this Se
        // < pick between many DirectoryShare depending on uri at io.ostream?
        let topname = path.shift()
        if (topname != this.Se.c.T.sc.D.sc.name) throw `< many shares? ${topname} unknown`
        // depend on that need to keep feeding %records
        let is_still_relevant = () => {
            w = this.refresh_C([A,w])
            let wenid = w.o1({streamable:1},'enid')[0]
            return enid == wenid
        }


        // recursive directory something-if-not-exist thinger
        let D = await this.Se.aim_to_open(w,path,async (uD,pathbit) => {
            throw `radiostreaming:${enid}: not found: ${uri}\n  had ${uD.sc.name} but not ${pathbit}`
        })
        if (!D) return

        // we have to figure out what the last %preview,seq= is
        //  so just wait.
        // < could start, but avoid Cpromise until %preview++ done
        //    and we can re-seq all the %stream accordingly
        let ip = re.o({in_progress:1})[0]
        if (ip) {
            console.log(`radiostreaming:${enid}: waiting until %previews++ done`)
            ip.c.on_finish = () => {
                // < aim at w better
                this.main()
            }
            return
        }
        

        if (!w.oa({buffers:1})) {
            console.log(`radiostreaming:${enid} loads`)
            re.i({they_want_streaming:1})
            await this.radiostreaming_i_buffers(A,w,D)
        }

        if (!w.oa({aud:1})) {
            let offset = re.sc.offset + re.sc.preview_duration
            if (offset < 0.43) throw "low offset..."
            let from_seq = re.o1({preview:1},'seq').pop() + 1
            let aud = await this.record_preview_individuated(A,w,D,{
                get_offset: () => offset,
                keyword: 'stream', // it's %record/%stream
                record: re, // continuing in
                from_seq,
                is_still_relevant,
            })
            // hold on to this while it's happening
            w.i({aud})
            // forget the encoded source buffers now
            await w.r({buffers:1},{ok:1})

            // makes wave of re.c.promise
            // < stash such concerns at a lower level...
            w.c.on_recording = async (re,pr) => {
                let also = pr.sc.EOstream ? ",EOstream" : ""
                console.log(`radiostreaming:${enid} %stream,seq=${pr.sc.seq}${also} is in!`)
                this.Cpromise(re);
            }
        }

        this.watch_auds_progressing(A,w,D)

        if (w.oa({record:1}) && !w.oa({see:'aud',playing:1})) {
            // all done!
            await w.r({satisfied:1})
        }

        // stop
        st.c.stop = () => {

            w.o1({aud:1}).map(aud => aud.stop())
        }
    }



    //#endregion
    //#region radiopreview
    async radiopreview(A,w,D) {
        if (!this.gat.AC_ready) return w.i({error:"!AC",waits:1})
        // w can mutate
        w.sc.then = "rest"
        w.c.error_fn = async (er) => {
            if (!String(er).includes("Error: original encoded buffers fail\n  Unable to decode audio data")) return
            // re-wander due to corrupt-seeming data
            // < make note. a lot of music out there has decode problems, perhaps not always fatal?
            await A.c.reset_Aw?.()
            return true
        }

        if (!w.oa({buffers:1})) {
            await this.radiopreview_i_buffers(A,w,D)
        }

        let radiostock = this.o({io:'radiostock'})[0]
        if (!radiostock) return w.i({waits:"%io:radiostock"})

        if (!w.oa({aud:1})) {
            let aud = await this.record_preview_individuated(A,w,D,{
                get_offset: (aud) => aud.duration() - PREVIEW_DURATION,
            })
            // hold on to this while it's happening
            w.i({aud})
            // forget the encoded source buffers now
            await w.r({buffers:1},{ok:1})
            w.c.on_recording = async (re,pr) => {
                w = this.refresh_C([A,w])
                radiostock = this.refresh_C([radiostock])
                // makes wave of re.c.promise
                // < temporarily re.c.promised()
                this.Cpromise(re);
                if (pr.sc.seq == 0) {
                    // we can start streaming this very very soon...
                    //  supposing latency is stable, they should be able to start playing it now?
                    await radiostock.sc.i(re)
                    w.i({see:'record taken!'})
                }
            }
        }

        this.watch_auds_progressing(A,w,D)

        if (w.oa({record:1}) && !w.oa({see:'aud',playing:1})) {
            // all done!
            await w.r({satisfied:1})
        }
    }


    
}


//#endregion
//#region M:Shares
//  makes guesswork to provide defaults, remote plots may inject
export class SharesModus extends RadioModus {
    declare S:PeeringSharing
    declare F:PeeringSharing

    constructor(opt:Partial<SharesModus>) {
        super(opt)
        this.F = this.S
        // the above super() / assign() doesn't set .F|S (javascript quirk?)
        // Object.assign(this,opt)
        if (!this.S) throw "Oh no F"

        this.S.i_actions({
            'R++': () => this.further_journey(),
            'R--': () => this.further_journey({go:'backwards'}),
            'Mo++': () => this.main(),
        })
    }
    async do_A() {
        await this.replace({A:1},async () => {
            this.i({A:'gate'}).is().i({w:'radiostockade'})
        })
        
    }

    async do_main() {
        await this.r({Seee:2})
    }


    async radiostockade(A,w) {
        // < what to do as|with the bunch of music shares? redundancy?
    }
}
//#endregion
//#region M:Sharee
export class ShareeModus extends RadioModus {
    declare S:PierSharing
    declare F:PeeringSharing
    declare PF:PierSharing
    constructor(opt:Partial<SharesModus>) {
        super(opt)
        this.PF = this.S
        this.S.i_actions({
            'Radio': () => this.turn_knob(),
            'Mo++': () => this.main(),
            'C++': () => this.hard_reset(),
        })
    }
    async hard_reset() {
        this.empty();
        await this.do_A();
        this.main()
    }
    // describe the minds regarding trust
    // < rename perm... it's both pieces of trust, theirs and ours...
    async do_A(hard=false) {
        // console.log("do_A")
        let A
        await this.replace({A:1},async () => {
            A = this.i({A:'punt'})
            if (hard) A.is() // prevents replacing the contents
        })
        await A.replace({w:1},async () => {
            // < so perm can change over time, do this every time, replacing %w?
            let perm = this.PF.perm
            if (perm.local) {
                // we grant them read access
                A.i({w:'radiobroadcaster'})
            }
            if (perm.remote) {
                // they grant us read access
                A.i({w:'radioterminal'})
            }
            if (perm.local && perm.remote) {
                // < may both be on, share DJing, syncing many Pier's?
                A.i({is_both_listener_and_source:1})
            }
        })
    }
    

//#endregion
//#region radioterminal
    turn_knob() {
        this.do_skip_track_fn()
    }
    do_skip_track_fn:Function
    async radioterminal(A,w) {
        w.sc.unemits ||= {
            irecord: async ({re:resc,pr:prsc,buffer}:{re:TheUniversal,pr:TheUniversal}) => {
                A = this.refresh_C([A])
                w = this.refresh_C([A,w])
                this.check_record_sanity(A)
                if (!resc.record) throw "!%record"
                if (prsc.seq == 0 && A.oa({record:1,enid:resc.enid})) {
                    console.warn(`irecord DUP ${resc.enid} at ${prsc.seq}`)
                    // < if they reload and resend cached stuff to us.
                }
                let keyword = prsc.preview ? 'preview'
                    : prsc.stream ? 'stream'
                    : null
                if (!keyword) throw "no pr%keyword we know"
                let keywordc = {}
                keywordc[keyword] = 1
                
                // < test|tour places we did eg A.r(resc)
                //    because without the sc arg it makes pattern_sc.* = 1
                //   see replace() / IN_ORDER
                // in case of
                let exactly = (sc) => map(v => String(v),sc)
                let re = A.o({record:1,enid:resc.enid})[0]
                    || await A.r(exactly(resc),resc)
                // < dealing with repeat transmissions. this should be re.i()
                //   some cursors need to wait at the end?
                // string '1' is not a wildcard
                this.check_record_sanity(A)
                if (re.oa({...keywordc,seq:String(prsc.seq)})) {
                    console.log(`irecord DUP ${re.sc.enid} at ${prsc.seq}`)
                    w.i({warning:'irecord DUP'})
                    return
                }
                let pr = re.o({...keywordc,...exactly(prsc)})[0]
                    || await re.r(
                    exactly({...keywordc,seq:prsc.seq}),
                    {...prsc,buffer,irecord_ts:now_in_seconds_with_ms()}
                )
                V.irec && console.log(`irecord   re=${re.sc.enid}%${keyword},seq=${pr.sc.seq}`)

                this.check_record_sanity(A)
                
                // now...
                if (!w.oa({nowPlaying:1})) this.main()
                
                // this may be for %nowPlaying
                //  which may be following the live edge too closely
                //   to get around to enqueue() (decode) this piece in time.
                let no = w.o({nowPlaying:1,enid:re.sc.enid}).pop()
                if (no) {
                    await no.c.hear_wake_fn()
                }
                // re.i({dooooooooooings:'it'})
                // re.i({dooooooewooings:'it'})
                // re.i({doooaooowooings:'it'})
                // re.i({doooeooooooings:'it'})
                // re.i({doooootooooings:'it'})
                // re.i({dowooooooooings:'it'})
                // re.i({dooooooooyyings:'it'})
            }
        }
        w.c.spinner ||= setInterval(() => {
            if (this.stopped) return clearInterval(w.c.spinner)
            this.check_record_sanity(A)
        }, 100)
        // < should we have hidden state like this?
        //   depends on KEEP_WHOLE_w to not lose w.c at the end of every time
        //    which perhaps we should...
        // our cursor id on the broadcaster, so we can restart
        w.c.cursor ||= this.prandle(9000000000)
        // < times...
        w.c.rec_end_nearing = () => {
            // < any %record/*%seq=$here,end_seq=$later can indicate the end?
            //    so radiostock can warn you to emit:ostream well before the end
            // < if it was %preview, then commission %stream
            //   if it was %stream, go 
            
            // < in other cases we may be on much
            // < would be the %stream to completion coming
            //   want to play another %record from the start!
        }
        w.c.next_nearing = () => {
            // < just the first bit of radio_hear
        }
        // record is finished
        w.c.next_is_go = () => {
            // < there's a %mixage operating this procedure?
            //    callback clustering
            console.log("term: next_is_go")
            next()
        }

        // we're hungry for %record
        let o_playable = () => {
            // < a join to the recently table on uri ?
            //    cursor should work fine for keeping us along...
            //   a desperate fugue of reruns may have to be another layer...
            let recs = A.o({record:1})
            this.check_record_ordering(recs)
            return recs
            //grep(re => !w.oa({recently_heard:1,uri:re.sc.uri}),
            //)
        }


        let co = await w.r({consumers:1,of:'radiostock'})
        let client = 1
        let la = null
        let next = async (loop=0) => {
            if (loop > 3) throw "loop"

            let ohno_start_over = async () => {
                for (let re of A.o({record:1})) {
                    // don't trust leftover A/re/*%stream
                    // < refactor to be able to request more streaming
                    //    for a re we know aren't streaming
                    //      or being actively given to us
                    //       as we orecord about where we're at
                    //     which is a quality we don't track anywhere atm
                    await re.r({stream:1},{})
                }
                await w.r({hearing:1},{})
                await co.r({client},{})
                await next(loop + 1)
            }
            // < unique artist+track
            let them = o_playable()
            console.log(`radio_hear(), re${this.say_cursor(them,client,co)}`)
            let current = await this.co_cursor_N_next(co,client,them)

            if (current) {
                let dohe = w.oa({hearing:current.sc.enid})
                if (dohe) {
                    // isn't supposed to reoccur until them run out
                    console.warn(`double hearingradio_hear(${current.sc.enid})`)
                    return ohno_start_over()
                }

                await this.radio_hear(A,w,current)
                await this.co_cursor_save(co,client,current)
                return current
            }
            else {
                // route hunger to the cursor-nearing-end code
                console.warn("terminal hunger")
                // let everything play again! this is odd though.
                // < make these cases studyable in the wild
                //    it here we suggest uploading some screeds
                return ohno_start_over()
            }
        }

        this.do_skip_track_fn = async () => {
            let before = w.o({nowPlaying:1})[0]

            await next()
            this.main()
            
            let now = w.o({nowPlaying:1})[0]
            console.log(`skipped track ${before.sc.enid} -> ${now.sc.enid}`)
        }

        let them = o_playable()
        let left = await this.co_cursor_N_least_left(co,them)
        let KEEP_AHEAD = 5
        if (left < KEEP_AHEAD) {
            w.i({see:'acquiring more...'})
            console.log(`term: orecord? we are`)
            await this.PF.emit('orecord',{client:w.c.cursor})
        }
        if (!them.length) {
            return w.i({waits:"no records"})
        }

        if (!this.gat.AC_ready) return w.i({error:"!AC",waits:1})

        // kick things off the first time
        //  or if the current aud seems wasted
        if (!this.nowPlaying_is_ok(w)) {
            console.log(">>>>>>>>>>>>>>>>>>")
            let rec = await next()
        }

        


        // < at half way through *%preview, order %stream
        // < have a way to modulate around a mix of them
        //    radio_hear() just wanders off...
    }
    nowPlaying_is_ok(w) {
        let ok = false
        for (let he of w.o1({nowPlaying:1})) {
            // Check if there's a currently playing aud
            let plau = he.o({playing:1, aud:1})[0]
            if (plau) {
                let aud:Audiolet = plau.sc.aud
                // Check if the audiolet is not stopped
                if (!aud.stopped) {
                    ok = true
                    break
                }
            }
        }
        return ok
    }
//#endregion
//#region < radio_hive

// < better calmer radio_hear(), cytoscape friendly
//   doing c_mutex() on an A or w... seems good huh
//    maybe a stack of mutexes
//   clients (perhaps out of M.main() time) describe their claim to reality...
//    the reaction to ending an aud of playing the next re/* aud would continue
//     but if the last one it wouldn't call w.c.next_is_go()
//   both ends of the deal
//    could be sharing some embryo of experience
//     which would help tidy when moved past
//    


//#endregion
//#region radio_hear
    // engage one re
    // < GOING? I mean it looks so bad. see radio_hive
    async radio_hear(A,w,re) {
        // and something to exist for all the auds in a sequence...
        let dohe = w.oa({hearing:re.sc.enid})
        if (dohe) throw "double hearing "+re.sc.enid
        let he = w.i({hearing:re.sc.enid})
        he.i(re)
        let what = () => `${re.sc.enid}`

        let last_live_edge_delay = 0
        let check_live_edge_delta = (pr) => {
            // when playing, check how far behind the live edge we are
            //  defined by our unemit:irecord, tells us how far behind the source material
            //   playing into the MediaRecord at the other end we are
            // we also try to stay 3s behind seq=0 at progress()
            let behind = now_in_seconds_with_ms() - pr.sc.irecord_ts
            if (last_live_edge_delay) {
                let delta = behind - last_live_edge_delay
                if (behind < 5 || 1) {
                    console.log(`live edge: ${behind}, delta: ${delta}`)

                }
            }
            last_live_edge_delay = behind
        }

        // thinking %hearing/*%aud, advancing reactions like play() etc
        let listening = async () => {
            let samehe = this.refresh_C([A,w,he],true)
            if (!samehe || he != samehe) {
                // Modus can't have .stopped or .gat will destroy audiosources
                console.error(`zombified radio_hear(${what()}), dropping`)
                return
            }

            let aus = he.o({aud:1})
            // where is playhead
            let plau = he.o({playing:1,aud:1})[0]
            let au_play = (au) => {
                let aud:Audiolet = au.sc.aud
                let pr = au.sc.pr
                check_live_edge_delta(pr)
                // which is...
                aud.on_ended = async () => {
                    let samehe = this.refresh_C([A,w,he])
                    if (he != samehe) {
                        // Modus can't have .stopped or .gat will destroy audiosources
                        console.error(`zombified radio_hear() he on_ended, dropping`)
                        return
                    }
                    if (!w.oa({nowPlaying:he})) {
                        debugger
                        console.error(`zombified nowPlaying on_ended, dropping`)
                        return
                    }

                    au.sc.stopping = 1
                    V.plau>1 && console.log(`aud @${au.sc.seq} ended after ${au.sc.aud.along()}`)
                    // < get listening() to ambiently progress()
                    //   instead of having a pause while we decode...
                    listening()
                }
                if (0 && 'temporarily') {
                    setTimeout(() => aud.on_ended(), 2000)
                }
                else {
                    aud.play()
                }
                // setTimeout(() => progress(), 333)
                
                V.plau && console.log(`plau now ${au.sc.pr.sc.seq}`)
                au.sc.playing = 1
            }

            if (!plau) {
                // first one
                let au = aus[0]
                if (!au) throw "!au"
                plau = au
                // < or hook up to... something
                V.plau && console.log(`plau ENGAGES`)
                au_play(au)
            }
            else {
                // garbage collect auds from the front (oldest)
                // let goners = this.whittle_N(aus,10)
                // if (goners.some(au => au.sc.playing)) throw `aud whittle_N still %playing`
                // if (aus[0]) {
                //     delete aus[0].sc.prev
                // }
                let pr = plau.sc.pr

                if (plau.sc.stopping) {
                    delete plau.sc.playing
                    
                    let neau = plau.sc.next
                    if (neau) {
                        V.plau>1 && console.log(`plau hops -> ${neau.sc.seq}`)
                        au_play(neau)
                        delete plau.sc.stopping
                        await he.r({plau:1},{seq:plau.sc.seq})

                    }
                    else {
                        // < if we are on the last decoded (in enqueue()) au
                        //    go decode more and return to this
                        //    irecord could excite the decode|enqueue
                        if (pr.sc.EOpreview) console.error(`run out of %preview @${pr.sc.seq}`)
                        if (!pr.sc.EOpreview && !pr.sc.EOstream) {
                            console.error(`run out of re/*, not marked as end: @${pr.sc.seq}`)
                        }
                        V.plau && console.log(`plau ENDS`)
                        await he.r({plau:1},{ENDED:1})
                        await progress()
                        return
                    }
                    
                    plau = neau
                }
                else {
                    V.plau && console.log(`plau continues`)
                }
            }

            // sense at certain times from the end
            await streamability()

            // update the index in he (he.X) so we can find %playing via .o()
            //  using the rarer key playing before the populous aud
            await he.replace({aud:1}, async () => {
                // au values are referred to for a linked list
                //  so keep the whole C, not just C.sc
                aus.map(au => he.i(au))

            })

            if (!plau) return

                // progress()
            // < get listening() to ambiently progress()
            // return
            // time to decode the next aud
            let needs_nexties = !plau.sc.next
            if (needs_nexties) {
                V.plau && console.log(`plau=${plau.sc.seq} wants nexties ${what()}`)
                await progress()
            }
        }

        let found_stream = false
        let enqueue_i = 0
        // %preview -> aud, aud<->aud,
        //  but not necessarily playing it yet
        let enqueue = async (pr) => {
            // for a linked list of aud
            let what = () => `${re.sc.uri}\npr%${keyser(pr.sc)}`
            V.plau && console.log(`radio enqueue ${enqueue_i}: \t${pr.sc.seq}`)
            if (enqueue_i != pr.sc.seq) throw `seq!=enqueue_i`
            enqueue_i++
            if (pr.sc.stream) {
                if (!found_stream) {
                    console.log(`radio enqueue: %preview turns to %stream`)
                    if (!he.oa({we_want_streaming:1})) {
                        console.warn("didnt ask for stream")
                    }
                    found_stream = true
                }
            }
            
            let aud = this.gat.new_audiolet()
            try {
                await aud.load(pr.sc.buffer)
            }
            catch (er) {
                // < recovery? mark %record as trouble?
                throw erring(`radio chunk decode error: ${what()}`,er)
            }

            // now pop it into hearing, the decoded stuff...
            //   these are all Selection.process() computations really
            //    being able to iterate a list, and how that list can change
            let seq = pr.sc.seq
            let au = he.i({aud,pr,seq})

            // au%next=->, au%prev=<- linkage
            this.linkedlist_frontiering(he,'decode_frontier',au)
        }

        // find next %preview and enqueue it
        let currently_ending = null
        let progress = async (soft=false) => {
            // pull the next %record/*%preview
            let them = this.get_record_audiobits(re)
            let current = await this.co_cursor_N_next(he,he,them)

            if (current) {
                let pr = current
                if (pr.sc.seq == 0) {
                    let behind = now_in_seconds_with_ms() - pr.sc.irecord_ts
                    if (behind < 3) {
                        // wait for the next main() if it's very recently arrived
                        // to stay back from "live edge" or end of time or buffer underrun
                        console.warn("backing away from end of time")
                        return
                    }
                }

                let bit = 'enqueue'
                try {
                    if (currently_ending) {
                        debugger
                    }
                    if (current.sc.EOstream) {
                        currently_ending = true
                    }


                    V.plau && console.log(`progress() ${what()} ${current.sc.seq}!`)
                    // contains decoding
                    await enqueue(current)
                    await this.co_cursor_save(he,he,current)
                    bit = 'listening'
                    // figure out what to do now looking at he/*%aud
                    //  plays initially, then operates from callbacks.
                    //  we should only observe nothing needing doing from here once %playing
                    //   
                    await listening()
                }
                catch (er) {
                    // < recovery? mark %record as trouble?
                    throw erring(`radio chunk ${bit} error: ${what()}`,er)
                }
            }
            else {
                if (soft) {
                    V.plau && console.log(`progress() ${what()} casual noop`)
                    return
                }
                V.plau && console.log(`progress() ${what()} done!?`)
                if (he.oa({plau:1,ENDED:1})) {
                    // having just i %ENDED and needs_nexties=true
                    w.c.next_is_go()
                }
                else {
                    V.plau && console.log(`progress() ${what()} out-of-bits !%ENDED`)
                }
            }
        }
        // < get this number down
        //    via 
        const MIN_LEFT_TO_WANT_STREAMING = 16
        // periodically emit:orecord {ack_seq,want_streaming?}
        let last_ack_seq = 0
        let streamability = async () => {
            console.log(`streamability`)
            // where is playhead
            let plau = he.o({aud:1,playing:1})[0]
            let pr = plau?.sc.pr
            if (!pr) return

            // send a remote cursor report every other seq, allowing more re/* to send
            if (last_ack_seq+1 < pr.sc.seq) {
                await this.PF.emit('orecord',
                    {client:w.c.cursor, enid:re.sc.enid, ack_seq:pr.sc.seq})
                last_ack_seq = pr.sc.seq
            }

            if (he.oa({we_want_streaming:1})) return

            // how far will we be next time we have time to think about streamability()
            //  playing time remaining, via seq durations so far
            let played_re_time = re.o1({preview:1},'duration')
                .slice(0,pr.sc.seq+2)
                .reduce((sum,s) => sum + s,0)
            if (!re.sc.preview_duration) throw "!re.sc.preview_duration"
            let left = re.sc.preview_duration - played_re_time
            console.log(`streamability(): left: ${left}`) 
            if (left < MIN_LEFT_TO_WANT_STREAMING) {
                console.log("term: nearing end of %preview, ordering *%stream...")
                await this.PF.emit('orecord',
                    {client:w.c.cursor, enid:re.sc.enid, want_streaming:1})
                he.i({we_want_streaming:1})
            }

            // < GONE using EOpreview, see 
            // is the last %preview audiobit now final?
            // < earlier warning? we know total duration when w:radiopreview decodes it
            let lapr = re.o({preview:1}).pop()
            if (!lapr?.sc.EOpreview) return
        }


        // start decoding
        //  which spurs playing
        //   which sets up continuity
        await progress()

        // < ideally with mixage
        // switch off any currently heard auds
        for (let he of w.o1({nowPlaying:1})) {
            // < where is playhead seems too complicated
            for (let aud of he.o1({aud:1}) as Audiolet[]) {
                aud.on_ended = undefined
                aud.stop()
            }
        }

        let no = await w.r({nowPlaying:he,uri:re.sc.uri,enid:re.sc.enid})
        no.c.hear_wake_fn = async () => {
            // will be attended while we are the %nowPlaying ?
            await progress()
        }
    }

    // < just use another co_cursor?
    // au%next=->, au%prev=<- linkage via the host he
    linkedlist_frontiering(he:TheC,name:string,au:TheC) {
        let laau = he.sc[name]
        if (laau) {
            if (laau.sc.next) throw `already au%next`
            laau.sc.next = au
            au.sc.prev = laau;
        }
        he.sc[name] = au
    }


//#endregion
//#region emit:irecord
    // desk to machine (terminal)
    // < and if also a terminal, hotwire the arrival handlers
    
    // transmit once, keeps transmitting while re.c.promise more /* 
    async transmit_record(A,w,re,client:number) {
        let blah = (pr) => {
            let keyword = Object.keys(pr.sc)[0]
            return `transmit_record re=${re.sc.enid}%${keyword},seq=${pr.sc.seq}`
        }
        let sending = async (pr) => {
            let buffer = pr.sc.buffer
            if (!buffer) throw "!buffer"
            if (!buffer instanceof ArrayBuffer) throw "~buffer"
            console.log(`${blah(pr)} send`)
            await this.PF.emit('irecord',{
                re: tex({},re.sc),
                pr: tex({},pr.sc),
                buffer,
            })
        }
        // < put this on w/listeners/$who or so
        //  < and separate the transmitter (PF) from the broadcaster (F)
        let co = _C({name:"through record chunks"})
        let spooling = 0
        let spoolia = async () => {
            let them = this.get_record_audiobits(re)
            let pr = await this.co_cursor_N_next(co,co,them)
            spooling ++
            if (pr) {
                let last_ack_seq = re.c.client_ack_seq?.[client] || 0
                let not_too_far_ahead = last_ack_seq + STAY_AHEAD_OF_ACK_SEQ
                if (pr.sc.seq > not_too_far_ahead) {
                    console.log(`cooling the spooling @${pr.sc.seq}`)
                    return
                }
                if (!pr.sc.buffer) {
                    // < tidy re/*%stream after a while?
                    //    and spawn a new streamer if the listening party is so far ahead
                    //    that the chunks just after the %preview is already de-buffered
                    throw "ohno, hit dropped %record memory"
                }
                // console.log(`soundpooling ${spooling}`)
                await sending(pr)
                await this.co_cursor_save(co,co,pr)
                return true
            }
        }
        // all %preview that are there
        while (await spoolia()) { 1 }

        this.Cpromised(re,() => spoolia())
    }


//#endregion
//#region radiobroadcaster
    sent_re_client_quota_default = 0
    sent_re_client_quota = {}
    // < test the efficacy of this... born in chaos
    sent_re_client_enids = {}
    async radiobroadcaster(A,w) {
        //  just one other to track for
        let co = await w.r({consumers:1,of:'%record'})
        // speaking, on Pier, to the other Pier
        let Pier = this.PF.Pier
        
        let rr = await w.r({was_sent:1})
        // let rr = await wh.r({these_records:1})
        let sendeth = async (A,w,co,rr,re,client:number) => {
            A = this.refresh_C([A])
            w = this.refresh_C([A,w])
            co = this.refresh_C([A,w,co])
            rr = this.refresh_C([A,w,rr])
            if (this.sent_re_client_quota_default) {
                if (this.sent_re_client_quota[client] == null) {
                    this.sent_re_client_quota[client] =
                        this.sent_re_client_quota_default
                }
                if (this.sent_re_client_quota[client]-- <= 0) {
                    console.warn("sendeth: quota exhausted, ends "+re.sc.enid)
                    return
                }
            }
            if (this.sent_re_client_enids[`${client} ${re.sc.enid}`]) {
                console.warn("sendeth: DUP "+re.sc.enid)
                return
            }
            this.sent_re_client_enids[`${client} ${re.sc.enid}`] = true
            console.log(`broad: orecord: sendeth: ${re.sc.enid} to ${client}`)
            
            // < see: don't trust leftover A/re/*%stream
            await re.r({stream:1},{})

            // < this should be after we transmit_record(), for rollbackity
            //    need to throttle many unemit:orecord rushing here before we complete sendeth()
            //   
            // save new cursor, in case we came through %excitable without moving the cursor
            await this.co_cursor_save(co,client,re)


            // send it, which can be drawn out
            await this.transmit_record(A,w,re,client)
            await rr.r({excitable:1},{})
            rr.i({enid:re.sc.enid})
        }
        w.sc.unemits ||= {
            orecord: async ({client,ack_seq,enid,want_streaming},{P,Pier:samePier}) => {
                if (samePier != Pier) throw "Pier?"
                // serve an entire orecord before releasing...
                await this.c_mutex(w,'orecord', async () => {
                    w = this.refresh_C([A,w])
                    co = this.refresh_C([A,w,co])
                    rr = this.refresh_C([A,w,rr])
                    if (ack_seq) {
                        // for more re/pr, whatever pr type
                        if (!enid) throw "enid?"
                        // it's a remote cursor report, allowing more re/* to send
                        let re = A.o({record:1,enid})[0]
                        re.c.client_ack_seq ||= {}
                        re.c.client_ack_seq[client] = ack_seq
                        console.log("broad: orecord: ack_seq="+ack_seq)
                        this.Cpromise(re)
                        return
                    }
                    if (want_streaming) {
                        // ordering re/pr%stream after the bunch of pr%preview
                        if (!enid) throw "enid?"
                        // tell F...w:radiostock to engage a stream
                        let re = A.o({record:1,enid})[0]
                        if (!re) throw `don't know re=${enid}`
                        console.log("broad: orecord: want_streaming: "+enid)
                        io.sc.ostream(re)
                    }
                    // for more re



                    let them = A.o({record:1})
                    rr.i({gota:"orecord"})

                    // they might be saying a few things...


                    let current = await this.co_cursor_N_next(co,client,them)
                    if (current) {
                        w.i({see:"unemit:orecord"})
                        await sendeth(A,w,co,rr,current,client)
                    }
                    else {
                        // can send when one arrives
                        console.log("broad: orecord: excitable")
                        await rr.r({excitable:1})
                    }
                })
            },
        }

        // we provide %record and %stream
        //  %stream should let people join for the first 10s

        // copy %io:radiostock interfaces here
        await this.Miome(A,{io:'radiostock'})
        if (!A.oa({io:'radiostock'})) return w.i({waits:"no stock"})
        let io = A.o({io:'radiostock'})[0]

        // what we have to play
        let them = A.o({record:1})

        

        // managerially,
        // find how far from the end the furthest cursor is
        let left = await this.co_cursor_N_least_left(co,them)
        let total = them.length
        await w.r({stocklevels:1,left,total})
        console.log(`broad: has ${left} left of ${total}`)

        let KEEP_AHEAD = 5
        if (left < KEEP_AHEAD) {
            let dif = KEEP_AHEAD - left
            // receive a new one time
            let it = await this.pull_stock(A,w,io)
            if (it && dif > 1) await this.pull_stock(A,w,io)
            if (it) {
                if (rr.oa({excitable:1})) {
                    // < dunno.. they ask often?
                    //    leaving off to debug other stuff
                    // < we would also need to hold their latest client number
                    //   which would be fine with a bit more Selection.process() around...
                    console.log(`broad: excitable, zen`)
                    w.i({see:"excitable, zen"})
                    // await sendeth(it)
                }
            }
            else {
                w.i({see:"want more"})
            }
        }

        // %

    }

    // shelf to DJ desk
    async pull_stock(A,w,io) {
        // our stream of %records shall be
        let rec = await io.sc.o(this)
        if (rec) {
            A.i(rec)
            let very = rec.oa({in_progress:1}) ? "very " : ""
            w.i({see:very+"new radiostock!!!"})
            return rec
        }
        else {
            w.i({see:"no new radiostock"})
        }
    }

    

}

