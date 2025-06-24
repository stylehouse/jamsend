import type { AudioletTest } from "./GatherAudiolet.svelte";
import { GatherAudios } from "./GatherSocket.svelte";

// behaviour superimposition, generating a starfield
export class GatherStars extends GatherAudios {
    field = $state()
    position = $state()

    whole_new_field() {
        this.field = {}
        this.position = 0
        this.look()
    }

    field_visiting:number
    star_visiting:Star = $state()
    look() {
        if (!this.field) this.whole_new_field()
            
        this.track_field_visiting()
        // maintain pressure for zooming around lots of stations
        // this.scheme.future = 15

        // what station are we closest to, tune it in
        let closest = this.find_closest_star()
        if (!closest) throw "!closest"
        let cur = this.star_visiting
        if (cur && cur != closest) {
            cur.pause()
            closest.play()
        }
        if (!cur) {
            closest.play()
        }
        this.star_visiting = closest

    }

    // to render at the viewport, in the expanse
    local_space:StarField[] = $state()
    track_field_visiting() {
        let index = Math.floor(this.position)
        if (this.field_visiting == null
            || index != this.field_visiting) {
            this.field_visiting = index

            this.crossed_border()
        }
    }
    crossed_border() {
        // maintain scenery for them to scroll intoe
        let index = this.field_visiting
        this.local_space = [
            this.keep_field(index-2),
            this.keep_field(index-1),
            this.keep_field(index),
            this.keep_field(index+1),
            this.keep_field(index+2)
        ]
    }
    keep_field(index) {
        let is = this.field[index]
        if (!is) {
            is = this.field[index] = new StarField({index})
        }
        is.last_seen = this.now()
        return is
    }


    find_closest_star(): Star | null {
        let closest: Star | null = null;
        let closestDistance = Infinity;
        
        // Check stars in nearby fields
        for (let fieldIndex = this.field_visiting - 1; fieldIndex <= this.field_visiting + 1; fieldIndex++) {
            const field = this.field[fieldIndex];
            if (field && field.stars) {
                for (const star of field.stars) {
                    const starWorldX = fieldIndex + star.x
                    const distance = Math.abs(starWorldX - this.position);
                    if (distance < closestDistance) {
                        closestDistance = distance;
                        closest = star;
                    }
                }
            }
        }
        
        return closest;
    }
}

const N_STARS = 7
const STAR_MIN_DISTANCE = 0.1
class StarField {
    index: number // in Stars.field
    stars: Star[] = [];
    last_seen: number = 0;

    constructor(opt) {
        Object.assign(this,opt)
        this.populate()
    }
    
    populate() {
        this.stars = [];
        const attempts = N_STARS * 10; // Try multiple times to place stars
        let placed = 0;
        
        for (let attempt = 0; attempt < attempts && placed < N_STARS; attempt++) {
            let x = Math.random() * 1
            let y = Math.random() * 1;
            // squish from ends since we dont check inter-field star distance
            x = x * (1 - (STAR_MIN_DISTANCE*2))
            x = x + STAR_MIN_DISTANCE
            // squish and put gap
            y = y * 0.6 + 0.1
            if (y > 0.4) y += 0.2

            
            let bail = 0
            // Check if this position is far enough from other stars
            for (const existingStar of this.stars) {
                const distance = Math.abs(existingStar.x - x)
                if (distance < STAR_MIN_DISTANCE) {
                    bail = 1
                    break;
                }
            }
            if (bail) continue
            
            this.stars.push(new Star({ 
                x, 
                y, 
                fieldIndex: this.index,
                size: 3 + Math.random() * 3,
                brightness: 0.3 + Math.random() * 0.7
            }));
            placed++;
        }
    }
}
class Star {
    x: number;
    y: number;
    fieldIndex: number;
    size: number;
    brightness: number;
    isActive: boolean = $state(false);
    // keep track of which aud we are supposed to be playing
    //  in case we return to one
    aud:AudioletTest | null = null;
    constructor(opt) {
        Object.assign(this,opt)
    }
    pause() {
        this.isActive = false;
        console.log(`Star at (${this.x.toFixed(2)}) paused`);
    }
    play() {
        this.isActive = true;
        console.log(`Star at (${this.x.toFixed(2)}) is now playing`);
        
    }
}


