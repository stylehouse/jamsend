

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
        if (this.end_reached) return
        this.scheme.future ||= 2
        let i = this.cursor()
        let more_wanted = i == null ? this.scheme.future
            : this.scheme.future - (i+1)
        if (this.awaiting_mores) {
            // don't want the same bit of more again
            more_wanted -= this.awaiting_mores.length
        }
        this.more_wanted = more_wanted
        if (more_wanted) {
            let name = this.constructor.name
            console.log(`${name} Wanted ${more_wanted} more`)
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
    constructor() {
        super()
        // keep the last 3 tracks
        this.scheme.history = 3
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
        aud.next_index = index
        aud.have_more({id,blob,index})
        // < skips the queue?
        this.queue.push(aud)
        if (from_start) {
            this.queue.unshift(aud)
            aud.a_nextly = true
            this.nextly = aud
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
            if (cur.near_end && !this.nextly) {
                this.get_more({from_start:true})
            }
            cur.think()
        }
        else {
            console.log("gat.think() start")
            this.might()
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
    end_reached = $state(false)

    gat:GathererTest
    
    // < can we assume start_time + duration = end_time?
    spawn_time:integer
    start_time:integer = $state()
    // test fabrications
    ms_per_item = 300

    cursor() {
        let time = this.along()
        if (time == null) return null
        let i = Math.floor(time / this.ms_per_item)
        return i
    }
    along() {
        if (this.start_time == null) return null
        return this.gat.now() - this.start_time
    }
    remaining_stretch():number {
        // < playing.duration - along()
        //    or just the seeked part of playing?
        let duration = this.stretch_size * this.ms_per_item
        let remains = duration - this.along()
        return remains
    }
    
    constructor(opt) {
        super(opt)
        let gat = this.gat = opt.gat;
        this.spawn_time = gat.now()
        // keep entire track once downloaded
        this.scheme.history = -1
        this.scheme.future = 3
    }

    // act: start a bit of queue
    //  then are dispatched by think()
    might() {
        if (!this.playing && this.queue.length) {
            let stretch = this.new_stretch()
            this.gat.currently = this
            this.start_stretch(stretch)
        }
        this.provision()
    }
    // ambiently
    think() {
        // is the playhead moving
        if (!this.playing) {
            // waits for gat to aud.might()
        }
        // within one item from the end
        else if (this.remaining_stretch() < this.ms_per_item) {
            let stretch = this.new_stretch()
            // schedule it to play when this one finishes
            this.playing_onended = () => {
                this.start_stretch(stretch)
                delete this.playing_onended
            }
        }
        else {
            console.log("~")
        }
        // is the playing reaching
    }


    // decodes stretches of the queue
    stretch_size = $state()
    playing_onended:Function|null
    new_stretch() {
        let encoded = this.queue.slice()
        if (this.stretch_size == encoded.length) {
            console.log("Hit the end!!!!")
            return
        }
        this.stretch_size = encoded.length

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
        this.start_time = this.gat.now()
        setTimeout(() => {
            console.log(`stretchended`)
            this.playing_onended?.()
        }, this.stretch_size * this.ms_per_item)
        // let play_from = !was ? 0 : was.duration
        // stretch.start(this.start_time,play_from)
        console.log(`aud:${this.id} Stretch++ ${this.stretch_size}`)
    }

    get_more({delay}) {
        this.awaiting_mores.push(1)
        setTimeout(() => {
            // here we always just want more of the queue, in sequence
            //  see gat.have_more() for creation and an initial aud.have_more()
            let req = {id: this.id, index: this.next_index++}
            let res = {...req, blob:'vvv'}
            if (req.index == 7) res.done = 1
            this.have_more(res)
        },delay)
    }
    have_more({id,blob,index,done}) {
        console.log(`aud:${id} more ${index}`)
        this.awaiting_mores.shift()
        // tempting to assign next_index = index+1 here
        //  but more get_more() may be dispatched already
        this.queue.push(blob)
        if (done) this.end_reached = true
        this.think()
    }
}
