<script lang="ts">
    import { onMount } from "svelte";

    import { _C, keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
    import { erring, ex, grep, grop, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import Records from "./Records.svelte";
    import Cytoscaping from "./Cytoscaping.svelte";
    import Directory from "./Directory.svelte";
   
    let {M} = $props()
    // making moves to provision and consume radio

    // $share/.jamsend/radiostock/*.webms
    const IGNORE_RADIOSTOCK_CACHE = false 
    const RADIOSTOCK_CACHE_LIMIT = 20 // items, they are timestamped

    // < get these numbers down, which involves lots of testing?
    //   adapt to slow cpu, which might be measured by punctuality of a callback?
    //    want in-the-wild performance reports
    //   PREVIEW_DURATION is the hardest to increase if not reaching...
    const PREVIEW_DURATION = 33 // seconds of preview
    const MIN_LEFT_TO_WANT_STREAMING = 22
    const STAY_AHEAD_OF_ACK_SEQ = 7 // many re/pr to load ahead

    const V = {}
    V.plau = 0
    V.irec = 0
    V.tx = 0
    V.rastream = 0

    onMount(async () => {
    await M.eatfunc({
        
        async on_code_change() {
            // < bounces!?
            this.on_code_change = async () => {}
            return
            // prove you can reset Bob
            //  he drops stuff if he's busy, ouch!
            this.o({A:1}).filter(A => A.sc.A.startsWith('Bob'))
                .map(async A => await this.Areset(A))
            console.warn("meta~!gets4rrrrrrrrr4t !!!",this.o({A:1}).map(C => keyser(C)))
        },

//#endregion
//#region raterminal
    turn_knob() {
        if (!this.do_skip_track_fn) return console.error(`you don't skip track`)
        this.do_skip_track_fn()
    },
    // do_skip_track_fn:Function
    async raterminal(A,w) {
        w.sc.unemits ||= {
            irecord: async ({re:resc,pr:prsc,buffer}:{re:TheUniversal,pr:TheUniversal}) => {
                A = this.refresh_C([A])
                w = this.refresh_C([A,w])
                this.check_all_records_sanity(A)
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

                if (keyword == 'stream') {
                    // if we terminal hungered, may get high-seq streams we didn't want yet
                    //  until our low orecord ack_seq indicate lack of interest in that later stream
                    let he = w.o({hearing:resc.enid})[0]
                    if (!he?.oa({we_want_streaming:1})) {
                        console.warn(`terminal hungered high-seq %stream? @${prsc.seq} dropped`)
                        return
                    }
                }
                
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
                this.check_all_records_sanity(A)
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

                this.check_all_records_sanity(A)
                
                // now...
                if (!w.oa({nowPlaying:1})) this.i_elvis(w,'noop',{A:w})
                
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
            this.check_all_records_sanity(A)
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
            this.check_all_records_sanity(A)
            return A.o({record:1})
            //grep(re => !w.oa({recently_heard:1,uri:re.sc.uri}),
            //)
        }


        let co = await w.r({consumers:1,of:'radiostock'})
        let client = 1
        let la = null
        let next = async (loop=0) => {
            if (loop > 3) throw "loop"

            let ohno_start_over = async () => {
                console.warn(`out of current, starting over?`)
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
            this.i_elvis(w,'noop',{A:w})
            
            let now = w.o({nowPlaying:1})[0]
            console.log(`skipped track ${before.sc.enid} -> ${now.sc.enid}`)
        }

        let them = o_playable()
        let left = await this.co_cursor_N_least_left(co,them)
        let KEEP_AHEAD = 5
        if (left < KEEP_AHEAD) {
            w.i({see:'acquiring more...'})
            V.tx && console.log(`orecord pls`)
            await this.PF.emit('orecord',{client:w.c.cursor})
        }
        if (!them.length) {
            return w.i({waits:"no records"})
        }

        if (!this.gat.AC_ready) return w.i({error:"!AC",waits:1})

        // kick things off the first time
        //  or if the current aud seems wasted
        // < do a subsequent call lossy throttle on this more elegantly
        if (w.o({nowPlayingShunted:1})[0]?.ago('at') > 10) {
            await w.r({nowPlayingShunted:1},{})
        }
        if (!this.nowPlaying_is_ok(w)) {
            if (w.oa({nowPlayingShunted:1})) {
                let ago = w.o({nowPlayingShunted:1})[0]?.ago('at')
                console.log(`>>>>>>>>>>> too often, just ${ago} ago`)
            }
            else {
                w.i({nowPlayingShunted:1,at:now_in_seconds()})
                console.log(">>>>>>>>>>>>>>>>>>")
                let rec = await next()
            }
        }

        


        // < at half way through *%preview, order %stream
        // < have a way to modulate around a mix of them
        //    radio_hear() just wanders off...
    },
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
    },
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
//#region radio_hear listening
    // engage one re
    // < GOING? I mean it looks so bad. see radio_hive
    async radio_hear(A,w,re) {
        // and something to exist for all the auds in a sequence...
        let dohe = w.oa({hearing:re.sc.enid})
        if (dohe) throw "double hearing "+re.sc.enid
        let he = w.i({hearing:re.sc.enid})
        he.i(re)
        this.whittle_N(w.o({hearing:1}),5)
        
        let what = () => `${re.sc.enid}`

        let last_live_edge_delay = 0
        let check_live_edge_delta = (pr,aud:Audiolet) => {
            // when playing, check how far behind the live edge we are
            //  defined by our unemit:irecord, tells us how far behind the source material
            //   playing into the MediaRecord at the other end we are
            // we also try to stay 3s behind seq=0 at progress()
            let behind = now_in_seconds_with_ms() - pr.sc.irecord_ts
            if (last_live_edge_delay) {
                let delta = behind - last_live_edge_delay
                if (behind < 15) {
                    let say = `live edge: ${behind.toFixed(3)}, delta: ${delta.toFixed(3)}`
                    behind < 3.141 ? console.warn(say)
                        : V.tx && console.log(say)
                    if (behind < 3.141) {
                        // getting close enough to break soon! better freak them out
                        // < make it seem like this weakness comes from physics
                        // aud.playing_next.
                        console.warn(`having a melty one because we are drifting towards the end of time`)
                        aud.playing_next.playbackRate.value = 0.8
                    }
                }
            }
            last_live_edge_delay = behind
        }

        // thinking %hearing/*%aud, advancing reactions like play() etc
        let listening = async () => {
            await this.c_mutex(w,'radio_hear:listening', async () => {
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
                check_live_edge_delta(pr,aud)
                // which is...
                aud.on_ended = async () => {
                    let samehe = this.refresh_C([A,w,he],true)
                    if (he != samehe) {
                        // Modus can't have .stopped or .gat will destroy audiosources
                        console.error(`zombified radio_hear() he on_ended, dropping`)
                        return
                    }
                    if (!w.oa({nowPlaying:he})) {
                        console.error(`zombified nowPlaying=${he.sc.hearing} on_ended, dropping`)
                        return
                    }

                    au.sc.stopping = 1
                    V.plau>1 && console.log(`aud @${au.sc.seq} ended after ${au.sc.aud.along()}`)
                    // < get listening() to ambiently progress()
                    //   instead of having a pause while we decode...
                    listening()
                }
                this.aud_applies_loudness(A,w,re,aud)
                aud.play()
                au.sc.playing = 1
                
                V.plau && console.log(`plau now ${au.sc.pr.sc.seq}`)
                for (let no of w.o({nowPlaying:1})) {
                    no.r({record_bit:1},{...pr.sc})
                }
            }

            if (!plau) {
                // first one
                let au = aus[0]
                if (!au) throw "!au"
                plau = au
                // < or hook up to... something
                V.plau>1 && console.log(`plau ENGAGES`)
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
                        await he.r({plau:1},{ended_ts:now_in_seconds_with_ms()})
                        await progress()
                        return
                    }
                    
                    plau = neau
                }
                else {
                    V.plau>1 && console.log(`plau continues`)
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

            // time to decode the next aud
            if (!plau.sc.next) {
                setTimeout(() => progress(), 345)
            }
            })
        }



//#endregion
//#region radio_hear enqueue
        let found_stream = false
        let enqueue_i = 0
        // %preview -> aud, aud<->aud,
        //  but not necessarily playing it yet
        let enqueue = async (pr) => {
            // for a linked list of aud
            let what = () => `${re.sc.uri}\npr%${keyser(pr.sc)}`
            V.plau && console.log(`radio enqueue ${enqueue_i}: \t${pr.sc.seq}`)
            if (enqueue_i != pr.sc.seq) return console.warn(`seq!=enqueue_i`)
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

            // yet they are in order, we can cull earlier ones:
            let gone_auN = this.whittle_N(he.o({aud:1,pr:1}),10)
            for (let au of gone_auN) {
                if (!au.sc.aud.playing_last) {
                    console.warn(`whittle never played he/au: ${re.sc.enid}@${seq}`)
                }
                if (!au.sc.aud.stopped) {
                    console.warn(`whittle playing he/au: ${re.sc.enid}@${seq}`)
                }
            }
        }

        // find next %preview and enqueue it
        let currently_ending = null
        let progress = async (soft=false) => {
            await this.c_mutex(w,'radio_hear:progressing', async () => {
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
                    await this.co_cursor_save(he,he,current)
                    // contains decoding, if undecodable the he is doomed
                    await enqueue(current)
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
                if (he.oa({plau:1,ended_ts:1})) {
                    // having just i %ended_ts and needs_nexties=true
                    w.c.next_is_go()
                }
                else {
                    V.plau && console.log(`progress() ${what()} out-of-bits !%ended_ts`)
                }
            }
            })
        }

//#endregion
//#region radio_hear top
        // periodically emit:orecord {ack_seq,want_streaming?}
        let last_ack_seq = 0
        let streamability = async () => {
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
            console.log(`streamability(): left: ${left.toFixed(2)}`) 
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

        let no = await this.i_nowPlaying(A,w,he,re)

        no.c.hear_wake_fn = async () => {
            // will be attended while we are the %nowPlaying ?
            await progress()
        }

        this.whittle_N(he.o({aud:1,pr:1}),10)
    },
    async i_nowPlaying(A,w,he,re) {
        let no = await w.r({nowPlaying:he,uri:re.sc.uri,enid:re.sc.enid,
            ...re.sc.meta
        })
        return no
    },

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
    },














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
            V.tx && console.log(`${blah(pr)} send`)
            await this.PF.emit('irecord',{
                re: sex(tex({},re.sc),re.sc,'meta'),
                pr: tex({},pr.sc),
                buffer,
            })
        }
        // < put this on w/listeners/$who or so
        //  < and separate the transmitter (PF) from the broadcaster (F)
        let co = _C({name:"through record chunks"})
        let spooling = 0
        let spoolia = async () => {
            let some = false
            await this.c_mutex(w,'spoolia', async () => {

                let them = this.get_record_audiobits(re)
                let pr = await this.co_cursor_N_next(co,co,them)
                spooling ++
                if (pr) {
                    // don't get too far ahead
                    // by what they ack_seq
                    let last_ack_seq = re.c.client_ack_seq?.[client] || 0
                    let not_too_far_ahead = last_ack_seq + STAY_AHEAD_OF_ACK_SEQ
                    if (pr.sc.seq > not_too_far_ahead) {
                        V.tx && console.log(`cooling the spooling @${pr.sc.seq}`)
                        return
                    }
                    if (!pr.sc.buffer) {
                        // < tidy re/*%stream after a while?
                        //    and spawn a new streamer if the listening party is so far ahead
                        //    that the chunks just after the %preview is already de-buffered
                        throw "ohno, hit dropped %record memory"
                    }
                    V.tx && console.log(`soundpooling ${spooling} goes ${re.sc.enid}@${pr.sc.seq}`)
                    await sending(pr)
                    await this.co_cursor_save(co,co,pr)
                    some = true
                }
            })
            return some
        }
        // all %preview that are there
        while (await spoolia()) { 1 }

        this.Cpromised(re,async () => await spoolia())
    },


//#endregion
//#region racaster
    // < test the efficacy of this... born in chaos
    async racaster(A,w) {
        if (this.sent_re_client_quota_default == null) {
            this.sent_re_client_quota_default = 0
            this.sent_re_client_quota = {}
            this.sent_re_client_enids = {}
        }
        //  just one other to track for
        let co = await w.r({consumers:1,of:'%record'})
        // speaking, on Pier, to the other Pier
        let Pier = this.PF.Pier
        let io
        
        let rr = await w.r({was_sent:1})
        // let rr = await wh.r({these_records:1})
        let sendeth = async (A,w,co,rr,client:number,re) => {
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
            V.tx && console.log(`broad: orecord: sendeth: ${re.sc.enid} to ${client}`)
            
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
        let dealeth = async (A,w,co,rr,client,loopy=0) => {
            let them = A.o({record:1})

            // they might be saying a few things...
            let re = await this.co_cursor_N_next(co,client,them)
            if (re) {
                // hang on, is it all banged up?
                // < and WHY. eg, I've recently seen them double-seq++ing, all %preview
                if (this.is_record_disordered(re)) {
                    console.log(`ignoring disordered re=${re.sc.enid}`)
                    A.drop(re)
                    re = null
                    if (loopy <3) {
                        dealeth(A,w,co,rr,loopy++)
                        return
                    }
                }
            }
            if (re) {
                w.i({see:"unemit:orecord"})
                await sendeth(A,w,co,rr,client,re)
            }
            else {
                // can send when one arrives
                V.tx && console.log("broad: orecord: excitable")
                await rr.r({excitable:1})

                io?.sc.ohhi()
            }
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
                        if (!re) return console.warn(`orecord: don't know re=${enid}`)
                        re.c.client_ack_seq ||= {}
                        let was = re.c.client_ack_seq[client]
                        re.c.client_ack_seq[client] = ack_seq
                        if (was && was > ack_seq) {
                            console.warn(`broad: orecord: ack_seq dropped from ${was}`)
                            // we may just be looping the %preview section if sluggish...
                            if (was - 20 > ack_seq) {
                                // long ago, cancelling the %stream
                                io.sc.ostream(re,{unstream:1})
                            }
                        }
                        V.tx && console.log("broad: orecord: ack_seq="+ack_seq)
                        let promising = await this.Cpromise(re)
                        if (!promising) {
                            console.warn(`lost track of what we're feeding them`)
                        }
                        return
                    }
                    if (want_streaming) {
                        // ordering re/pr%stream after the bunch of pr%preview
                        if (!enid) throw "enid?"
                        // tell F...w:radiostock to engage a stream
                        let re = A.o({record:1,enid})[0]
                        if (!re) return console.warn(`orecord: don't know re=${enid}`)
                        V.tx && console.log("broad: orecord: want_streaming: "+enid)
                        io.sc.ostream(re)
                    }
                    // for more re
                    // rr.i({gota:"orecord"})

                    dealeth(A,w,co,rr,client)
                })
            },
        }

        // we provide %record and %stream
        //  %stream should let people join for the first 10s

        // copy %io:radiostock interfaces here
        await this.Miome(A,{io:'radiostock'})
        if (!A.oa({io:'radiostock'})) return w.i({waits:"no stock"})
        io = A.o({io:'radiostock'})[0]

        // what we have to play
        let them = A.o({record:1})

        

        // managerially,
        // find how far from the end the furthest cursor is
        let left = await this.co_cursor_N_least_left(co,them)
        let total = them.length
        await w.r({stocklevels:1,left,total})
        V.tx && console.log(`broad: has ${left} left of ${total}`)

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

    },
    // shelf to DJ desk
    async pull_stock(A,w,io) {
        // our stream of %records shall be
        let rec = await io.sc.o(w)
        if (rec) {
            A.i(rec)
            let very = rec.oa({in_progress:1}) ? "very " : ""
            w.i({see:very+"new radiostock!!!"})
            return rec
        }
        else {
            w.i({see:"no new radiostock"})
        }
    },



//#endregion
//#region radiostock

    // side note,
    //  about the falling-ness of this** C
    //  we KEEP_WHOLE_w so the object w might be kinda robust (longer lived) now
    //   but other C that get w.r({bits}) will be renewed
    //    taking the C.sc.* to a new C essentially
    //   so you can't capture C and then expect C.i() to operate on the current time of it
    //   unless you use refresh_C()
    //  so functions created only the first time
    //    eg w:racaster / unemits / orecord
    //   capture values of C that get buried in the past
    //  %record though (aka rec, re)
    //    just sit there!
    //  in w:racaster you can put this:
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
                    .map(ow => this.i_elvis(w,'noop',{A:ow}))
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
            // starts streams
            //  zapped a subtype of broadcaster's unemit:orecord
            ostream: async (re:TheC,q) => {
                this.o({A:'rastream'}).map(A => {
                    A.o({w:'rastream'}).map(w => {
                        w.c.ostream(re,q)
                    })
                })
            },
            // shoves the DirectoryShare.modus in case it loses its interval
            // < why does it do that
            ohhi: async () => {
                // mostly going for A:hunting, but everything likes staying alive
                setTimeout(() => this.main(), 250)
            },
        })

        if (IGNORE_RADIOSTOCK_CACHE) return

        // and may cache on the filesystem for spanglier startups
        await this.radiostock_caching(A,w)
    },
    async radiostock_caching(A,w) {
        // the .jamsend/radiostock/ directory D
        let stockD
        let keep_things = RADIOSTOCK_CACHE_LIMIT
        stockD = await this.aim_to_open(w,['.jamsend','radiostock'])
        if (!stockD) return // also when ope<3

        // our records...
        let had = A.o({record:1})
        for (let re of had) {
            if (!re.oa({in_radiostock:1})) {
                // wants saving to disk once whole
                if (!re.oa({in_progress:1})) {
                    // little delay, sometimes %EOpreview is not determined during last aud.on_recording
                    setTimeout(async () => {
                        await this.record_to_disk(re,stockD)
                    },500)
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
    },

    //#endregion
    //#region rastream
    async rastream(A,w) {
        // await need
        w.c.ostream = async (re,q) => {
            let {enid} = re.sc
            let st = w.o({streamable:1,re,enid})[0]
            if (st) {
                if (q?.unstream) {
                    st.c.stop()
                    console.log(`unstream, stops: ${enid}`)
                }
                else {
                    console.log(`Already streaming ${enid}`)
                }
                return
            }
            for (let st of w.o({streamable:1})) {
                st.c.stop?.()
            }
            // < we could deputise st as a kind of w, and Travel the %aim hoisting etc
            //    w is an instance of the soul of A
            // we do the work in w/* rather than under w/st/*, so:
            w.empty()
            w.i({streamable:1,re,enid})
            this.i_elvis(w,'noop',{A:w,because:'got ostream'})
        }

        let st = w.o({streamable:1})[0]
        if (!st) return w.i({see:"At rest"})

        // process a %streamable,re
        let re = st.sc.re
        let uri = re.sc.uri
        let enid = re.sc.enid
        let path = uri.split('/')
        // resolve ourselves to this Se
        // < pick between many DirectoryShare depending on uri at io.orecord?
        let topname = path.shift()
        if (topname != this.Se.c.T.sc.D.sc.name) throw `< many shares? ${topname} unknown`
        // depend on that need to keep feeding %records
        let not_relevant = false
        let is_still_relevant = () => {
            w = this.refresh_C([A,w])
            let wenid = w.o1({streamable:1},'enid')[0]
            return !not_relevant && enid == wenid
        }
        // stop
        st.c.stop = () => {
            console.error("stream stop called")
            // < figure out how to keep the %record without muddling it with non-continuing %stream
            re.r({stream:1},{})
            not_relevant = true
            w.o1({aud:1}).map(aud => aud.stop())
        }
        let check_for_abandonment = (pr) => {
            if (!re.c.client_ack_seq) return
            // find closest one of these behind us and give up if we are > 10 seq away
            let audienced = Object.values(re.c.client_ack_seq || {})
                .some(seq => (seq+20) > pr.sc.seq * 0.34 && seq < pr.sc.seq+2)
            if (!audienced) {
                V.rastream && console.log(`rastream:${enid} stream @${pr.sc.seq} abandoned`, re.c.client_ack_seq)
                st.c.stop()
            }
        }


        // recursive directory something-if-not-exist thinger
        let D = await this.Se.aim_to_open(w,path,async (uD,pathbit) => {
            throw `rastream:${enid}: not found: ${uri}\n  had ${uD.sc.name} but not ${pathbit}`
        })
        if (!D) return

        

        if (!w.oa({buffers:1})) {
            V.rastream && console.log(`rastream:${enid} loads`)
            re.i({they_want_streaming:1})
            await this.radiostreaming_i_buffers(A,w,D)
        }

        // we have to figure out what the last %preview,seq= is
        //  so arrange to get told before we do any i re/%stream
        //   but then have a bunch of them at once, getting live edge ahead!
        // wait for %preview++ done so we can re-seq all the %stream accordingly
        let ip = re.o({in_progress:'preview'})[0]
        let saved_up_chunksc:TheUniversal[] = []
        if (ip) {
            V.rastream && console.log(`rastream:${enid}: waiting until %previews++ done`)
            // we save up our chunks of recording
            w.c.on_i_chunksc = (ore:TheC,prsc:TheUniversal) => {
                if (ore != re) throw "~re"
                saved_up_chunksc.push(prsc)
            }
            // then when they're done they send their last %preview
            ip.c.on_finish = async (pr:TheC) => {
                // release
                w.c.on_i_chunksc = undefined
                // which we re-number our %stream,seq to
                let seq = pr.sc.seq
                for (let prsc of saved_up_chunksc) {
                    seq++
                    let pr = re.i({...prsc, seq})
                    w.c.on_recording(re,pr)
                }
                w.sc.seq = seq
            }
        }
        
        if (!w.oa({aud:1})) {
            let offset = re.sc.offset + re.sc.preview_duration
            if (offset < 0.43) throw "low offset..."
            let from_seq = re.o1({preview:1},'seq').pop() + 1
            let aud = await this.record_preview(A,w,D,{
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
                V.rastream &&  console.log(`rastream:${enid} %stream,seq=${pr.sc.seq}${also} is in!`)
                await this.Cpromise(re);
                check_for_abandonment(pr)
            }
        }

        await this.watch_auds_progressing(A,w,D)


    },



    //#endregion
    //#region hunt, radiopreview
    async rahunting(A,w,D) {
        // in response to eg decode errors, just try again from the top
        A.c.reset_Aw = async () => await this.Areset(A)
        // we are done immediately, and move on to...
        w.i({satisfied:1})
        w.sc.then = 'meander'
        A.c.meander_then = 'radiopreview'
    },
    
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
            let aud = await this.record_preview(A,w,D,{
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
                await this.Cpromise(re);
                if (pr.sc.seq == 0) {
                    // we can start streaming this very very soon...
                    //  supposing latency is stable, they should be able to start playing it now?
                    await radiostock.sc.i(re)
                    w.i({see:'record taken!'})
                }
            }
        }

        await this.watch_auds_progressing(A,w,D)
    },




    })
    })
</script>

<Records {M} ></Records>
<Cytoscaping {M} ></Cytoscaping>
<Directory {M}></Directory>