
// test params
// all queues have this ending
export const MOCK_END_OF_INDEX = 9
// various timing code needs to regard the decoded audio aud.playing.duration
export const MOCK_MS_PER_ITEM = 621
export const PHI = 1.613
export const MS_PER_SIMULATION_TIME = 333
// see also the audio constants in GatherSocket
// turn up log statement level
//  3 = every more response
export const V = 2

export class Queuey {
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
            aud.from_start = true
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


    //#region surf might
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



