
import { Queuey, V,  } from "./Common.svelte";
import type { audioi } from "./Common.svelte";
import { AudioletTest } from "./GatherAudiolet.svelte"



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
    get_more_from_start() {
        this.get_more({from_start:true})
    }
    get_more({from_start,delay}) {
        this.awaiting_mores.push(1)
        setTimeout(() => {
            // response:
            this.have_more({id:this.idi++,blob:'vvv',index:0,from_start})
        }, delay || 100)
    }
    have_more(res:audioi) {
        let {id,blob,index,from_start} = res
        if (this.grab_have_more?.(res)) {
            // if !gat.AC_OK, we don't want to spawn any aud just yet...
            return
        }
        V>0 && console.log(`Gat more aud:${id} ${index}`)
        this.awaiting_mores.shift()
        // the server randomly sent a previous track
        // < pseudo-random, avoid repeats for as long as possible
        if (this.shouldnt_repeat_aud(res)) return

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
    shouldnt_repeat_aud(res) {
        if (res.index == 0 && this.find_audiolet({id:res.id})) {
                console.error("the server randomly sent a previous track")
                this.get_more_from_start()
                return true
        }
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
        let next = this.suitable_new_aud()
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
    suitable_new_aud() {
        return this.queue
            // not the old track currently fading out
            .filter(aud => !this.fadingout.includes(aud))
            // corner case: not the one we had ready to play in sequence
            .filter(aud => this.nextly != aud)
            .filter(aud => this.currently != aud)
            .filter(aud => !aud.stopped)
            [0]
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

    //#region next
    next_is_gettable_done = $state(null)
    next_is_coming_done = $state(null)
    // from an aud noticing it ends soon
    next_is_gettable(aud) {
        if (this.next_is_gettable_done == aud) return
        this.next_is_gettable_done = aud
        if (!this.nextly) {
            V>1 && console.log(`${aud.idname} next_is_gettable`)
            this.get_more_from_start()
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



