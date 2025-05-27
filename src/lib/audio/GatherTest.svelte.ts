

class Queuey {
    // subtypings
    cursor:Function

    constructor(opt) {
        Object.assign(this,opt)
    }
    // parameterises this superclass
    scheme:{
        history?:number,
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
    // pull from queue
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

    }
}

// the thing that is playing
//  it requests more pieces to play
export class AudioletTest extends Queuey {
    // still encoded chunks of ogg
    queue:Array<Uint8Array> = $state([])

    gat:GathererTest
    
    // < can we assume start_time + duration = end_time?
    start_time:integer
    // test fabrications
    ms_per_item = 900

    cursor() {
        let time = this.along()
        let i = Math.floor(time / ms_per_item)

    }
    along() {
        if (!this.start_time) return 0
        return this.gat.now() - this.start_time
    }
    
    constructor(opt) {
        super(opt)
        // keep entire track once downloaded
        this.scheme.history = -1
    }


    might() {
        // if there's enough queue to start playing
        //  once we are near the end of our currently playing stretch

        let next = this.queue
            // not the old track currently fading out
            .filter(aud => !this.fadeout.includes(aud)) [0]
        next && next.might()
        
        this.provision()
    }
    // get more queue
    provision() {

    }
}
