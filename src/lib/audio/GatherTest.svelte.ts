

class Queuey {
    constructor(opt) {
        Object.assign(this,opt)
    }
    // parameterises this superclass
    scheme:{
        history?:number,
        future?:number,
    } = {}
    cull_queue() {
        let history = this.scheme.history || 0
        if (history == -1) return
        // which item is the cursor in
        let i = Math.floor(this.cursor())
        this.queue
    }
}

export class GathererTest extends Queuey {
    queue:Array<AudioletTest> = $state([])
    fadeout:Array<AudioletTest> = $state([])
    constructor() {
        super()
        // keep the last 3 tracks
        this.scheme.history = 3
    }
    idi = 1
    surf() {
        let aud = new AudioletTest({id:this.idi++,gat:this})
        this.queue.push(aud)
        console.log("The aud: ",aud)
        this.might()
    }
    now() {
        return performance.now()
    }
    // act: pull from queue
    might() {
        let next = this.queue
            // not the old track currently fading out
            .filter(aud => !this.fadeout.includes(aud)) [0]
        next && next.might()

        // a suitable time to think about:
        this.provision()
    }
    // get more queue
    provision() {

    }


    // might might(), but only if...
    think() {

        // if not satisfied, come back
    }
}

// the thing that is playing
//  it requests more pieces to play
export class AudioletTest extends Queuey {
    // still encoded chunks of ogg
    queue:Array<Uint8Array> = $state([])
    playing:BufferSource

    gat:GathererTest
    
    // < can we assume start_time + duration = end_time?
    start_time:integer
    // test fabrications
    ms_per_item = 900

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
    remaining_stretch() {
        // < playing.duration - along()
        //    or just the seeked part of playing?
    }
    
    constructor(opt) {
        super(opt)
        this.gat = opt.gat;
        // keep entire track once downloaded
        this.scheme.history = -1
    }

    // act: start a bit of queue
    //  then are dispatched by think()
    might() {
        if (!this.playing && this.queue.length) {
            let stretch = this.new_stretch()
            this.start_stretch(stretch)
        }
        this.provision()
    }
    // ambiently
    think() {
        // is the playhead moving
        if (!this.playing) {
            this.might()
        }
        // within one item from the end
        else if (this.remaining_stretch() < this.ms_per_item) {
            let stretch = this.new_stretch()
            // schedule it to play when this one finishes
            this.playing.onended = () => {
                this.start_stretch(stretch)
            }
        }
        else {
            console.log("~")
        }
        // is the playing reaching
    }


    // decodes stretches of the queue
    new_stretch() {
        console.log("Wanted a new stretch ")
        let encoded = this.queue.slice()

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
        // let play_from = !was ? 0 : was.duration
        // stretch.start(this.start_time,play_from)
        console.log("Stretch++")
    }


    // get more queue
    provision() {
        this.scheme.future ||= 4
        let i = this.cursor()
        let more_wanted = i == null ? this.scheme.future
            : this.scheme.future - (i+1)
        if (more_wanted) {
            console.log(`Wanted ${more_wanted} more`)
            for (let it = 1; it <= more_wanted; it++) {
                this.get_more({delay:it*140})
            }
        }
    }
    get_more({delay}) {
        setTimeout(() => {
            this.have_more({blob:'vvv'})
        },delay)
    }
    have_more({blob}) {
        this.queue.push(blob)
        this.think()
    }
}
