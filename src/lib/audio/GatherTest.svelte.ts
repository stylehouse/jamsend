
// test params
// all queues have this ending
const MOCK_END_OF_INDEX = 9
// various timing code needs to regard the decoded audio aud.playing.duration
const MOCK_MS_PER_ITEM = 621
const PHI = 1.613
export const MS_PER_SIMULATION_TIME = 333
// see also the audio constants in GatherSocket
// turn up log statement level
//  3 = every more response
export const V = 1

class Queuey {
    constructor(opt) {
        Object.assign(this,opt)
        window.gat = this
    }
    // parameterises this superclass
    scheme:{
        history?:number,
        future?:number,
    } = {}

    cull_queue() {
        let history = this.scheme.history || 0
        if (history == -1) return
        let culled = 0
        if (this.now) {
            // assume things will get stopped when they're old
            let stopped = this.queue
                .filter(aud => aud.stopped)
            for (let i = 0; i < history; i++) {
                stopped.pop()
            }
            let sane = 0
            while (stopped.length && sane++<500) {
                let aud = stopped.shift()
                let index = this.queue.indexOf(aud)
                if (index >= 0) {
                    this.queue.splice(index, 1)
                    culled++
                }
            }
        }
        else {
            // < something Queuey-generic about which item is the cursor in
            // let i = Math.floor(this.cursor())
        }
        if (culled) {
            V>1 && console.log(`cull_queue() x${culled}`)
        }
    }

    // get more queue
    awaiting_mores = []
    more_wanted = $state()
    provision() {
        if (this.end_index) {
            // Audiolet is done loading
            return
        }
        // where we have consumed up til
        let i = this.cursor()
        // where we have
        let queued = this.queue.length - 1
        // how far ahead we have
        let ahead = queued - (i||0)
        // compare to how far ahead we like to be
        let deficit = this.scheme.future - ahead
        
        let more_wanted = deficit > 0 ? deficit : 0

        // < we should really be generating unique wills to get more (by index)
        if (this.awaiting_mores) {
            // don't want the same bit of more again
            more_wanted -= this.awaiting_mores.length
        }
        this.more_wanted = more_wanted
        if (more_wanted) {
            V>2 && console.log(`${this.idname} Wanted ${more_wanted} more (cursor:${i})`)
            // < request specific indexes here
            for (let it = 1; it <= more_wanted; it++) {
                this.get_more({delay:it*140})
            }
        }
    }
}



//#region gat
export class GathererTest extends Queuey {
    queue:Array<AudioletTest> = $state([])
    fadingout:Array<AudioletTest> = $state([])
    currently:AudioletTest = $state()
    get idname() {
        return "gat"
    }
    constructor(opt) {
        super(opt)
        // keep the last 3 tracks
        this.scheme.history = 3
        this.scheme.future = 2
    }
    stop() {
        this.queue.map(aud => aud.stop())
        this.close?.()
    }
    idi = 1
    cursor() {
        let i = this.queue.indexOf(this.currently)
        if (i == -1) return null
        return i
    }
    now() {
        return performance.now()
    }

    //#region gat req
    // fetch a random track, creating its AudioletTest
    get_more({from_start,delay}) {
        this.awaiting_mores.push(1)
        setTimeout(() => {
            // response:
            this.have_more({id:this.idi++,blob:'vvv',index:0,from_start})
        }, delay || 100)
    }
    have_more(res) {
        let {id,blob,index,from_start} = res
        if (this.grab_have_more?.(res)) {
            // if !gat.AC_OK, we don't want to spawn any aud just yet...
            return
        }
        V>0 && console.log(`Gat more aud:${id} ${index}`)
        this.awaiting_mores.shift()
        if (index == 0 && this.find_audiolet({id})) {
            // the server randomly sent a previous track
            // < pseudo-random, avoid repeats for as long as possible
            console.error("the server randomly sent a previous track")
            this.get_more({from_start})
            return
        }
        let aud = this.new_audiolet({id,gat:this})
        aud.next_index = index+1
        aud.have_more(res)
        if (from_start) {
            let i = this.queue.indexOf(this.currently)
            if (i < 0) throw "noi"
            this.queue.splice(i+1,0,aud)
            aud.is_nextly = true
            this.nextly = aud
        }
        else {
            this.queue.push(aud)
        }
        this.think()
    }
    find_audiolet({id}) {
        let aud = this.queue
            // not the old track currently fading out
            .filter(aud => aud.id == id) [0]
        return aud
    }
    new_audiolet(opt) {
        return new AudioletTest(opt)
    }
    // the next track to play in sequence, from the start
    nextly


    //#region gat req
    surf() {
        if (!this.queue.length) {
            // beginning, acquire random track at random position
            return this.provision()
        }
        console.log("surf()")
        this.might("surf()")
    }
    // act: pull from queue
    might(really) {
        let next = this.queue
            // not the old track currently fading out
            .filter(aud => !this.fadingout.includes(aud))
            // corner case: not the one we had ready to play in sequence
            .filter(aud => this.nextly != aud)
            .filter(aud => this.currently != aud)
            .filter(aud => !aud.stopped)
            [0]
        if (next) {
            let cur = this.currently
            if (really && cur) {
                // was a track skip, do a mix
                next.aud_onstarted = () => {
                    next.aud_onstarted = null
                    V>1 && console.log("DOING A MIX")
                    cur.fadeout()
                    next.fadein()
                }
            }
            next.might()
        }
        else {
            if (really) {
                // < surf()ing faster than gat queue can load?
                console.warn("surf() > have_more()")
            }
        }

        // a suitable time to think about:
        this.provision()
    }

    // might might(), but only if...
    think_ticks = 0
    think() {
        // we are preoccupied with...
        if (this.currently) {
            // what's on
            this.currently.think('from gat')
        }
        else {
            // getting going
            V>0 && console.log("gat.think() start")
            this.might()
        }
        if (this.think_ticks++ % 250 == 0) {
            // avoid browser mem growing 2GB/hr
            this.cull_queue()
        }
    }

    next_is_gettable_done = $state(null)
    next_is_coming_done = $state(null)
    next_is_gettable(aud) {
        if (this.next_is_gettable_done == aud) return
        this.next_is_gettable_done = aud
        if (!this.nextly) {
            V>1 && console.log(`${aud.idname} next_is_gettable`)
            // the only way to get a whole track is to finish another
            this.get_more({from_start:true})
        }
    }
    async next_is_coming(aud) {
        if (this.next_is_coming_done == aud) return
        this.next_is_coming_done = aud
        let nex = this.nextly
        if (!nex) {
            // would be odd, not enough think() per second? low future?
            console.error("next is not got yet")
            return
        }
        let start = await nex.might("returning start")
        aud.aud_onended = () => {
            V>1 && console.log("Next track!")
            start()
            delete this.nextly
        }
    }
}



// the thing that is playing
//  it requests more pieces to play
export class AudioletTest extends Queuey {
    // still encoded chunks of ogg
    queue:Array<Uint8Array> = $state([])
    //  a decoded, from-the-start subset of the queue
    playing:AudioBufferSourceNode = $state()
    // the index after get_more's we are in to the track (-1)
    next_index:number = $state()
    is_nextly = $state()
    end_index = $state()
    get idname() {
        return `aud:${this.id}`
    }
    meta = $state()

    gat:GathererTest
    
    //#region aud time
    // < can we assume start_time + duration = end_time?
    spawn_time:integer
    start_time:integer = $state()
    stopped = $state()

    cursor() {
        let time = this.along()
        if (time == null) return null
        let i = Math.floor(time / this.approx_chunk_time)
        return i
    }
    along() {
        if (this.start_time == null) return null
        return this.gat.now() - this.start_time
    }
    remaining_stretch():number {
        // < playing.duration - along()
        //    or just the seeked part of playing?
        let along = this.along()
        if (along == null) return 0
        let remains = this.duration() - along
        return Math.round(remains)
    }
    duration():number {
        return this.stretch_size * this.approx_chunk_time
    }

    fadein() {
        // noop
    }
    fadeout() {
        // prevent further aud.start_stretch() etc immediately
        this.stopped = this.gat.now()
        // < redundant given stopped?
        this.gat.fadingout.push(this)
        setTimeout(() => this.stop(), 2)
    }
    stop() {
        this.stopped = this.gat.now()
        this.gat.fadingout = this.gat.fadingout
            .filter(aud => aud != this)
    }
    
    constructor(opt) {
        super(opt)
        let gat = this.gat = opt.gat;
        this.spawn_time = gat.now()
        // keep entire track once downloaded
        this.scheme.history = -1
        this.scheme.future = 2
    }

    // act: start a bit of queue
    //  then are dispatched by gat think()
    // < surf()
    async might(returning_start=false) {
        if (!this.playing && this.queue.length) {
            V>0 && console.log(`${this.idname} -> might`)
            // we're going to hit play on this aud
            // if it's ready
            await this.prep_next_stretch()
            if (this.next_stretch) {
                V>0 && console.log(`${this.idname} -> Currently`)
                
                let start = () => {
                    this.gat.currently = this
                    this.start_stretch(this.next_stretch)
                }
                if (returning_start) return start
                start()
            }
        }
        this.provision()
    }


    

    
    // ambiently
    next_stretch = $state()
    next_stretch_coming = ''
    async think(source?) {
        if (this.stopped) {
            // no more planning
            return
        }
        this.provision()
        // is the playhead moving
        if (!this.playing) {
            // waits for gat to aud.might()
            return
        }
        let notlong = Math.max(500,this.approx_chunk_time)
        let near = this.remaining_stretch() < notlong
        let prepped = this.next_stretch
        // within one item from the end
        // remaining_stretch() depends on along()
        //  which depends on start_time
        //   which is sync with playing
        //   but stays that of first playing (stretch)
        //  in other places it can express 30 when not started
        //   as a way to do something asap
        if (near && !prepped) {
            await this.try_stretching()
        }

        // prepare for the next track when we know this is ending
        if (this.end_index != null) {
            if (this.end_index <= this.cursor()+3) {
                this.gat.next_is_gettable(this)
            }
            // prepare for the next track
            if (this.end_index <= this.cursor()+1) {
                V>1 && console.log(`aud:${this.id} next_is_coming`)
                await this.gat.next_is_coming(this)
            }
        }
    }
    get approx_chunk_time() {
        return MOCK_MS_PER_ITEM
    }

    async prep_next_stretch() {
        if (this.next_stretch_coming) {
            return
        }
        this.next_stretch_coming = "?"

        let stretch = await this.new_stretch()
        if (!stretch) {
            debugger
            this.next_stretch_coming = ""
            return
        }
        // < this way stays blocked until start_stretch()
        this.next_stretch_coming = stretch.length
        this.next_stretch = stretch
    }


    //#region aud stretch
    // from think(), when cursor nears the end of a stretch
    //  think of the next one, schedule it
    async try_stretching() {
        if (this.next_stretch_coming) {
            if (this.next_stretch_coming != "?") {
                // otherwise is sync with this.next_stretch
                debugger
            }
            V>1 && console.log("still waiting for a new_stretch() decode")
            return
        }
        this.next_stretch_coming = "?"
        let stretch = await this.new_stretch()
        if (!stretch) {
            this.next_stretch_coming = ""
            return
        }
        this.next_stretch_coming = stretch.length
        this.next_stretch = stretch

        V>1 && console.log(`aud:${this.id} strext ${this.stretch_size} -> ${stretch.length}`
            +`\t\t${this.remaining_stretch()} of ${this.approx_chunk_time}`)
        
        // schedule it to play when this one finishes
        let was_playing = this.playing
        this.playing_onended = () => {
            if (was_playing != this.playing) {
                debugger
            }
            this.start_stretch(stretch)
            this.playing_onended = null
        }

    }
    // decodes stretches of the queue
    // this fabricates the duration
    //  and is set during decode (too early?) before it reflects this.playing
    stretch_size:number = $state()
    // playing_onended:Function|null
    delayed_stretch_think:number
    async new_stretch() {
        let encoded = this.queue.slice()
        if (this.stretch_size == encoded.length) {
            V>2 && console.log(`${this.idname} Stretchsame ${this.stretch_size}`)
            // we can panic about having a queue of one initially
            if (this.stretch_size == 1) {
                if (this.delayed_stretch_think) return
                let delay = this.remaining_stretch() / PHI*2
                delay = Math.max(555,delay)
                delay = Math.min(122,delay)
                this.delayed_stretch_think = setTimeout(() => {
                    delete this.delayed_stretch_think
                    V>0 && console.log(`   And with ${this.remaining_stretch()} left... `)

                    this.think()
                }, delay)
            }
            else {
            }
            return
        }
        let stretch = await this.decode_stretch(encoded)

        return stretch
    }
    get tc() {
        return '@'+Math.round(this.gat.now())
    }
    async decode_stretch(encoded) {
        return encoded
    }
    // decodes stretches of the queue
    start_stretch(stretch) {
        let was = this.playing
        this.playing = stretch
        this.start_time ||= this.gat.now()
        this.stretch_size = stretch.length
        // allow the next one to build on a think()
        this.next_stretch = null
        this.next_stretch_coming = ''

        if (this.gat.currently != this) {
            debugger
        }

        this.started_stretch?.()
        this.aud_onstarted?.()
        

        // exponentially loady, log times we new_stretch()
        let enthusiasm = Math.floor(this.stretch_size / PHI)
        // we end up loading the last third
        this.scheme.future += enthusiasm

        this.plan_ending(was)

        // let play_from = !was ? 0 : was.duration
        // stretch.start(this.start_time,play_from)
        V>1 && console.log(`aud:${this.id} Stretch++ ${this.stretch_size} ${this.tc}`)
    }
    aud_onended:Function|null
    aud_onstarted:Function|null
    plan_ending(was) {
        this.mock_ending(was)
    }
    mock_ending(was) {
        let endsin = this.stretch_size * this.approx_chunk_time
        if (was) endsin -= was.length * this.approx_chunk_time
        setTimeout(() => {
            this.whatsnext()
        }, endsin)
    }
    whatsnext() {
        let began_whatsnexting = this.gat.now()
        if (this.stopped) {
            // is over, no need to keep feeding audio
            // small chance it will cut out during fadeout()
            return
        }
        let ismore = this.playing_onended ? ', is more' : ''
        V>1 && console.log(`${this.idname} stretchended${ismore} ${this.tc}`)
        if (this.playing_onended) {
            // the next stretch is ready to play
            this.playing_onended()
        }
        else if (this.aud_onended) {
            // the next track (aud) is ready to play
            this.aud_onended()
            this.stopped = 1
        }
        else {
            console.error("Off the end")
        }
    }

    get_more({delay}) {
        this.awaiting_mores.push(1)
        setTimeout(() => {
            // here we always just want more of the queue, in sequence
            //  see gat.have_more() for creation and an initial aud.have_more()
            let req = {id: this.id, index: this.next_index++}
            let res = {...req, blob:'vvv'}
            if (req.index == MOCK_END_OF_INDEX) {
                res.done = 1
            }
            this.have_more(res)
        },delay)
    }
    have_more({id,blob,index,done, meta, try_again,notexist}) {
        if (try_again) {
            V>0 && console.log(`aud:${id} more shall try_again`)
            setTimeout(() => this.request_more(try_again), 1000)
            return
        }
        if (!blob?.byteLength) {
            if (notexist) {
                this.awaiting_mores.shift()
                return
            }
            debugger
        }
        if (meta) {
            this.meta = meta
            if (!this.meta.cover?.byteLength) {
                delete this.meta.cover
            }
        }
        V>2 && console.log(`aud:${id} more ${index} ${done?" DONE":""}`)
        this.awaiting_mores.shift()
        if (this.end_index && index > this.end_index) {
            // test harness generates any index you ask for, ignore extra
            V>1 && console.log(`  end was located, dropped a have_more()`)
            return
        }
        // tempting to assign next_index = index+1 here
        //  but more get_more() may be dispatched already
        this.queue.push(blob)
        if (done) this.end_index = index

        let thinkdelay = 0
        if (index == 1) {
            // debounces us through stretch_size = 1, 3, ...
            thinkdelay = this.remaining_stretch() / PHI
        }
        setTimeout(
            () => this.think(),
            thinkdelay,
        )
    }
}
