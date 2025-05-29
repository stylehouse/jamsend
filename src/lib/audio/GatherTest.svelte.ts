
// test params
// all queues have this ending
const MOCK_END_OF_INDEX = 9
// various timing code needs to regard the decoded audio aud.playing.duration
const MOCK_MS_PER_ITEM = 450
const PHI = 1.613
export const MS_PER_SIMULATION_TIME = 111


class Queuey {
    constructor(opt) {
        Object.assign(this,opt)
    }
    // parameterises this superclass
    scheme:{
        history?:number,
        future?:number,
    } = {}

    // < this
    cull_queue() {
        let history = this.scheme.history || 0
        if (history == -1) return
        // which item is the cursor in
        let i = Math.floor(this.cursor())
        this.queue
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
            console.log(`${this.idname} Wanted ${more_wanted} more (cursor:${i})`)
            for (let it = 1; it <= more_wanted; it++) {
                this.get_more({delay:it*140})
            }
        }
    }
}

export class GathererTest extends Queuey {
    queue:Array<AudioletTest> = $state([])
    fadeout:Array<AudioletTest> = $state([])
    currently:AudioletTest
    get idname() {
        return "gat"
    }
    constructor() {
        super()
        // keep the last 3 tracks
        this.scheme.history = 3
        this.scheme.future = 2
    }
    idi = 1
    cursor() {
        let i = this.queue.indexOf(this.currently)
        if (i == -1) return null
        return i
    }

    // fetch a random track, creating its AudioletTest
    get_more({from_start,delay}) {
        this.awaiting_mores.push(1)
        setTimeout(() => {
            // response:
            this.have_more({id:this.idi++,blob:'vvv',index:0,from_start})
        }, delay || 100)
    }
    have_more({id,blob,index,from_start}) {
        console.log(`Gat more aud:${id} ${index}`)
        this.awaiting_mores.shift()
        let aud = new AudioletTest({id,gat:this})
        aud.next_index = index+1
        aud.have_more({id,blob,index})
        if (from_start) {
            this.queue.unshift(aud)
            aud.a_nextly = true
            this.nextly = aud
        }
        else {
            this.queue.push(aud)
        }
        this.think()
    }



    surf() {
        if (!this.queue.length) {
            // beginning, acquire random track at random position
            return this.provision()
        }
        console.log("surf()")
        this.might()
    }
    now() {
        return performance.now()
    }
    // act: pull from queue
    might() {
        let next = this.queue
            // not the old track currently fading out
            .filter(aud => !this.fadeout.includes(aud))
            // corner case: not the one we had ready to play in sequence
            .filter(aud => this.nextly != aud)
            [0]
        if (next) {
            next.might()
        }

        // a suitable time to think about:
        this.provision()
    }

    // might might(), but only if...
    think() {
        // if near the end of the track
        let cur = this.currently
        if (cur) {
            cur.think()
        }
        else {
            console.log("gat.think() start")
            this.might()
        }
    }

    next_is_gettable(aud) {
        if (!this.nextly) {
            this.get_more({from_start:true})
        }
    }
    next_is_coming(aud) {
        let nex = this.nextly
        if (!nex) throw "!nex"
        let start = nex.might("returning start")
        aud.aud_onended = () => {
            console.log("Next track!")
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
    playing:BufferSource = $state()
    // the index after get_more's we are in to the track (-1)
    next_index:number = $state()
    end_index = $state()
    get idname() {
        return `aud:${this.id}`
    }

    gat:GathererTest
    
    // < can we assume start_time + duration = end_time?
    spawn_time:integer
    start_time:integer = $state()

    cursor() {
        let time = this.along()
        if (time == null) return null
        let i = Math.floor(time / MOCK_MS_PER_ITEM)
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
        return this.stretch_size * MOCK_MS_PER_ITEM
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
    //  then are dispatched by think()
    might(returning_start=false) {
        if (!this.playing && this.queue.length) {
            let stretch = this.new_stretch()
            let start = () => {
                this.gat.currently = this
                this.start_stretch(stretch)
            }
            // when preparing (decoding) gat.nextly
            if (returning_start) return start
            start()
        }
        this.provision()
    }
    // ambiently
    next_stretch
    think() {
        // is the playhead moving
        if (!this.playing) {
            // waits for gat to aud.might()
        }
        // within one item from the end
        // remaining depends on along depends on start_time which is sync with playing
        //  other places is can express 0 when not started as a way to do something asap
        else if (this.remaining_stretch() < MOCK_MS_PER_ITEM) {
            if (this.next_stretch) {
                // is organised
                return
            }
            let stretch = this.new_stretch()
            if (!stretch) {

                return
            }
            this.next_stretch = stretch

            console.log(`aud:${this.id} strext ${this.stretch_size} -> ${stretch.length}`
                +`\t\t${this.remaining_stretch()} of ${MOCK_MS_PER_ITEM}`)
            
            let was_playing = this.playing
            // schedule it to play when this one finishes
            this.playing_onended = () => {
                if (was_playing != this.playing) {
                    debugger
                }
                this.start_stretch(stretch)
                delete this.next_stretch
                delete this.playing_onended
            }
        }
        else {
            // nothing to actuate right now
        }

        // prepare for the next track
        if (this.end_index != null && this.end_index <= this.cursor()+3) {
            this.gat.next_is_gettable(this)
        }

        // prepare for the next track
        if (this.end_index != null && this.end_index <= this.cursor()+1) {
            this.gat.next_is_coming(this)
        }
        

        this.provision()
    }

    


    // decodes stretches of the queue
    // this fabricates the duration
    //  and is set during decode (too early?) before it reflects this.playing
    stretch_size = $state()
    playing_onended:Function|null
    delayed_stretch_think
    new_stretch() {
        let encoded = this.queue.slice()
        if (this.stretch_size == encoded.length) {
            console.log(`${this.idname} Stretchsame ${this.stretch_size}`)
            // we can panic about having a queue of one initially
            if (this.stretch_size == 1) {
                if (this.delayed_stretch_think) return
                this.delayed_stretch_think = setTimeout(() => {
                    delete this.delayed_stretch_think
                    console.log(`   And with ${this.remaining_stretch()} left... `)

                    this.think()
                }, this.remaining_stretch() / PHI*2)
            }
            else {
            }
            return
        }
        // this.stretch_size == encoded.length
        

        // const encoded = await this.context.decodeAudioData(encoded);
        let decoded = (encoded)

        // const stretch = this.gat.context.createBufferSource();
        // stretch.buffer = decoded;
        // stretch.connect(this.gainNode);
        let stretch = decoded

        return stretch
    }
    // decodes stretches of the queue
    start_stretch(stretch) {
        let was = this.playing
        this.playing = stretch
        this.start_time ||= this.gat.now()
        this.stretch_size = stretch.length

        // exponentially loady, log times we new_stretch()
        let addiction = Math.floor(this.stretch_size / PHI)
        // we end up loading the last third
        this.scheme.future += addiction

        this.mock_ending(was)

        // let play_from = !was ? 0 : was.duration
        // stretch.start(this.start_time,play_from)
        console.log(`aud:${this.id} Stretch++ ${this.stretch_size}`)
    }
    aud_onended:Function|null
    mock_ending(was) {
        let endsin = this.stretch_size * MOCK_MS_PER_ITEM
        if (was) endsin -= was.length * MOCK_MS_PER_ITEM
        setTimeout(() => {
            let ismore = this.playing_onended ? ', is more' : ''
            console.log(`stretchended ${ismore}`)
            if (this.playing_onended) {
                // the next stretch is ready to play
                this.playing_onended()
            }
            else {
                // the next track (aud) is ready to play
                if (!this.aud_onended) return console.error("Off the end")
                this.aud_onended()

            }
        }, endsin)
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
    have_more({id,blob,index,done}) {
        console.log(`aud:${id} more ${index} ${done?" DONE":""}`)
        this.awaiting_mores.shift()
        if (this.end_index && index > this.end_index) {
            console.log(`  end was located, dropped a have_more()`)
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
