
import { MOCK_BLOB, MOCK_END_OF_INDEX, MOCK_MS_PER_ITEM, PHI, Queuey, V } from "./Common.svelte";
import { GathererTest } from "./GatherTest.svelte";

// the thing that is playing
//  it requests more pieces to play
export class AudioletTest extends Queuey {
    // still encoded chunks of ogg
    queue:Array<Uint8Array> = $state([])
    //  a decoded, from-the-start subset of the queue
    playing:AudioBufferSourceNode = $state()
    // the index after get_more's we are in to the track (-1)
    next_index:number = $state()
    from_start = $state()
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

    //#region might
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
    aud_onstarted:Function|null
    playing_onended:Function|null
    aud_onended:Function|null
    
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
        if (this.stopped) {
            // is over, no need to keep feeding audio
            // small chance it will cut out during fadeout()
            return
        }
        let ismore = this.playing_onended ? ', is more' : ''
        let cur = this.cursor(1)
        V>1 && console.log(`${this.idname} stretchended${ismore}`
            +` ${this.tc}\tcursor:${cur}`)
        
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

    //#region get, have
    get_more({delay}) {
        this.awaiting_mores.push(1)
        setTimeout(() => {
            // here we always just want more of the queue, in sequence
            //  see gat.have_more() for aud creation, initial aud.have_more()
            let req = {id: this.id, index: this.next_index++}
            let res = {...req, blob:MOCK_BLOB}
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
        if (!blob?.byteLength && blob != MOCK_BLOB) {
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