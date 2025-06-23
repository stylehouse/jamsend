import type { AudioletTest } from "./GatherAudiolet.svelte";
import {GathererTest} from "./GatherTest.svelte";

const N_STARS = 7
// behaviour superimposition, generating a starfield
class GatherStars extends GathererTest {
    think() {
        super.think()

        this.field || this.whole_new_field()
    }
    field = $state()
    position = $state()
    whole_new_field() {
        this.field = []
        this.position = 9000
        this.look()
    }
    field_visiting:number
    star_visiting:Star
    look() {
        let index = Math.floor(this.position)
        if (index != this.field_visiting) {
            this.field_visiting = index
            // maintain scenery for them to scroll into
            this.keep_field(index-2)
            this.keep_field(index-1)
            this.keep_field(index)
            this.keep_field(index+1)
            this.keep_field(index+2)
        }
        // maintain pressure for zooming around lots of stations
        this.scheme.future = 15
        // what station are we closest to, tune it in
        let closest = this.find_closest_star()
        let cur = this.star_visiting
        if (cur && cur != closest) {
            cur.pause()
            closest.play()
        }

    }
    find_closest_star() {
        return star
    }
    keep_field(index) {
        let is = this.field[index]
        if (!is) {
            is = this.field[index] = new StarField()
        }
        is.last_seen = this.now()
    }
}
class StarField {
    stars = []
    constructor(opt) {
        Object.assign(this,opt)
    }
    populate() {
        for i (1..N_STARS) {
            // shouldn't be withing 20 x of each other
            this.stars.push(new Star({x,y}))
        }
    }
}
class Star {
    // keep track of which aud we are supposed to be playing what if we go back to one
    aud:AudioletTest
    constructor(opt) {
        Object.assign(this,opt)
    }
    pause() {

    }
    play() {
        
    }
}


