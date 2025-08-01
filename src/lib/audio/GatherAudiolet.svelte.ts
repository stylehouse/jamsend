
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
        return `aud:${this.id}`.slice(0,12)
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

    //#region think
    // ambiently
    next_stretch = $state()
    next_stretch_coming = ''
    async think(source?) {
        if (this.stopped) {
            // no more planning
            return
        }
        this.provision()
    }
    get approx_chunk_time() {
        return MOCK_MS_PER_ITEM
    }

    on_provisioning_okay() {
        if (!this.playing) {
            // as loaded as possible before playing! good time to:
            this.prep_next_stretch()
        }
    }

    // < merge with 
    async prep_next_stretch() {
        if (this.next_stretch_coming) {
            return
        }
        // < this way stays blocked until start_stretch()
        //    unless the decode fails? (!stretch below)
        this.next_stretch_coming = "?"

        let stretch = await this.new_stretch()
        if (!stretch) {
            debugger
            this.next_stretch_coming = ""
            return
        }
        this.next_stretch_coming = stretch.length
        this.next_stretch = stretch

        // when a new star wants to claim this new aud now it exists
        //  it has to introduce the aud to the Star
        this.gat.on_next_stretch?.(this)
        if (this.should_play) {
            console.log(`${this.idname} Autoplaying stretch`)
            this.shall_play('prep')
        }
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
        // whatsnext() will play that

        V>1 && console.log(`aud:${this.id} strext ${this.stretch_size} -> ${stretch.length}`
            +`\t\t${this.remaining_stretch()} of ${this.approx_chunk_time}`)
        
    }
    // decodes stretches of the queue
    // this fabricates the duration
    //  and is set during decode (too early?) before it reflects this.playing
    stretch_size:number = $state()
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
    start_stretch() {
        // old stretch departs, remember its shape
        this.starting_new_stretch?.()

        let was = this.playing
        if (this.stopped) throw "start stopped"
        let stretch = this.next_stretch
        this.playing = stretch
        this.start_time ||= this.gat.now()
        this.stretch_size = stretch.length
        // allow the next one to build on a think()
        this.next_stretch = null
        this.next_stretch_coming = ''

        if (this.gat.currently != this) {
            !this.is_fading && console.warn("this.gat.currently != this")
        }

        this.started_stretch?.()
        

        // exponentially loady, log times we new_stretch()
        let enthusiasm = Math.floor(this.stretch_size / PHI)
        // we end up loading the last third
        this.scheme.future += enthusiasm

        this.plan_ending(was)

        // let play_from = !was ? 0 : was.duration
        // stretch.start(this.start_time,play_from)
        V>1 && console.log(`aud:${this.id} Stretch++ ${this.stretch_size} ${this.tc}`)
    }





    //#region ending, next
    playing_onended:Function|null
    
    plan_ending(was) {
        this.mock_ending(was)
        this.plan_next()
    }
    mock_ending(was) {
        let endsin = this.stretch_size * this.approx_chunk_time
        if (was) endsin -= was.length * this.approx_chunk_time
        setTimeout(() => {
            this.whatsnext()
        }, endsin)
    }
    async whatsnext() {
        if (this.paused) console.error("paused aud reach the end: ${this.idname}")
        if (this.stopped) return
        let ismore = this.next_stretch ? ', is more' : ''
        let cur = this.cursor(1)
        V>1 && console.log(`${this.idname} stretchended${ismore}`
            +` ${this.tc}\tcursor:${cur}`)
        
        if (this.next_stretch) {
            // the next stretch is ready to play
            this.start_stretch()
        }
        else {
            this.stopped = 1
            if (this.end_index == null) {
                console.error(`Off the end of a stretch! ${this.idname}`)
                this.gat.get_unstuck()
                // throw new Error(`${this.idname}: Off the end of a stretch`)
                return
            }
            let good = await this.gat.aud_plays_nextly(this)
            if (!good) {
                console.error("No nextly aud available!")
                this.gat.get_unstuck()
                // throw new Error(`${this.idname}: No nextly aud available`)
            }
        }
    }

    // < and include simply loading more chunks, avoiding provision() !?
    //    and then stretching when the intended loading is done
    // called whenever we start a stretch
    next_plan = null
    async plan_next() {
        // dedup the timers
        let plan = this.next_plan = {}
        let planned_delay = (delay,y) => {
            setTimeout(() => {
                if (plan == this.next_plan) {
                    y()
                }
            }, Math.max(0,delay))
        }
        let remains = this.remaining_stretch()
        if (remains == null) throw "!remains"

        // next track prep might happen either distance from the end
        //  really short auds may only just find out they end in time
        let nextable = true
        let nextilate = () => {
            if (nextable && this.end_index != null) {
                // respond to this once, at either time
                nextable = false
                this.gat.next_is_gettable(this)
            }
        }

        let one_item_from_end = remains - this.approx_chunk_time
        if (one_item_from_end < 55) {
            console.warn(`plan_next() while end-1 is in ${one_item_from_end}ms, remaining=${remains}`)
        }
        planned_delay(one_item_from_end, () => {
            if (!this.next_stretch) {
                this.try_stretching()
            }
            nextilate()
        })
        let three_items_from_end = remains - this.approx_chunk_time*3
        planned_delay(three_items_from_end, () => {
            nextilate()
        })
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
        // see also gat.have_more() which handles from_start

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