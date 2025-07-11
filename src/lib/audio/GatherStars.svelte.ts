import { throttle } from "$lib/Y";
import type { Audiolet } from "./Audiolet.svelte";
import { V } from "./Common.svelte";
import type { Gather } from "./Gather.svelte";
import { GatherAudios } from "./GatherSocket.svelte";

// behaviour superimposition, generating a starfield
export class GatherStars extends GatherAudios {
    think() {
        super.think()
        // sometimes happens
        if (!this.star_field) this.whole_new_field()
    }
    // a general rescue-from-silence maneuvre
    get_unstuck() {
        console.warn(`had to get_unstuck()`)
        let going = this.active_auds()
        if (going.length) {
            going.map(aud => {
                console.warn(`get_unstuck() had to pause ${aud.idname}`)
                aud.pause()
            })
        }
        this.star_visiting = null
        this.look()
    }
    
    

    star_field = $state()
    star_position = $state()

    whole_new_field() {
        this.star_field = {}
        this.star_position = 0
        this.look()
    }

    star_field_visiting:number
    star_visiting:Star|null = $state()
    // lock|concentrate on each target while:
    star_travel_in_progress:Star|null = false
    star_travel_wanted:Star|null = null
    star_finding_frequency = 7
    star_finding_freq_throttle:Function
    async look() {
        if (!this.star_field) this.whole_new_field()
        
        this.track_field_visiting()

        this.might_travel()
    }
    might_travel() {
        this.star_finding_freq_throttle ||= throttle(() => {
            // what station are we closest to
            let closest = this.find_closest_star()
            if (!closest) throw "!closest"
            let cur = this.star_visiting
            if (!cur || cur && cur != closest) {
                if (!this.may_travel(closest)) return
                this.change_star(closest,cur)
            }
        }, 1000 / this.star_finding_frequency)
        this.star_finding_freq_throttle()
    }
    may_travel(to:Star) {
        if (this.star_travel_in_progress) {
            this.star_travel_wanted = to
        }
        else {
            this.star_travel_in_progress = to
            return true
        }
    }
    done_travel(to:Star) {
        if (to != this.star_travel_in_progress) {
            // < fadeout-in jitterbug: understand why this is with Story doing visuals, steps
            // we sometimes come here from an aborted after-fadeout() pause()
            //   which was about to stop this aud
            //  this avoids a bug where you can't travel between
            //   stars 1,2,1 faster than fadeout time
            //   or star 1 doesn't play again until 2 started_stretch ??? unsure
            //  suspect stickiness of which star we are visiting
            // < also the 
            // debugger
            console.warn("fadeout-in jitterbug")
        }
        this.star_travel_in_progress = null
        if (this.star_travel_wanted) {
            console.log("Belated star travel")
            let to = this.star_travel_wanted
            let from = this.star_visiting
            this.star_travel_wanted = null
            this.change_star(to,from)
        }
    }
    async change_star(to:Star,from?:Star) {
        if (to == from) return console.log("null change_star()")
        await to.play()
        from?.pause()
        this.star_visiting = to
    }
    // come from any start of a stretch (inc unpauses)
    star_started_stretch(star) {
        if (star == this.star_travel_in_progress) {
            // we meant to get here!
            this.done_travel(star)
        }
        // after making some progress, wind up our ambition
        if (this.scheme.future < 10) {
            this.scheme.future += 1
        }

    }
    // until ^, we catch the first aud after decode via a one-timer in:
    on_next_stretch:Function|null

//#region star fields

    // to render at the viewport, in the expanse
    star_fields_nearby:StarField[] = $state()
    track_field_visiting() {
        let index = Math.floor(this.star_position)
        if (this.star_field_visiting == null
            || index != this.star_field_visiting) {
            this.star_field_visiting = index

            this.crossed_border()
        }
    }
    crossed_border() {
        // maintain scenery for them to scroll intoe
        let index = this.star_field_visiting
        this.star_fields_nearby = [
            this.keep_field(index-2),
            this.keep_field(index-1),
            this.keep_field(index),
            this.keep_field(index+1),
            this.keep_field(index+2)
        ]
    }
    keep_field(index) {
        let is = this.star_field[index]
        if (!is) {
            is = this.star_field[index] = new StarField({
                gat:this,
                index
            })
        }
        is.last_seen = this.now()
        return is
    }


//#endregion
//#region star fields
    find_closest_star(): Star | null {
        let closest: Star | null = null;
        let closestDistance = Infinity;
        
        // Check stars in nearby fields
        for (let fieldIndex = this.star_field_visiting - 1; fieldIndex <= this.star_field_visiting + 1; fieldIndex++) {
            const field = this.star_field[fieldIndex];
            if (field && field.stars) {
                for (const star of field.stars) {
                    const starWorldX = fieldIndex + star.x
                    const distance = Math.abs(starWorldX - this.star_position);
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
    gat:Gather
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
                gat:this.gat,
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

//#region star
// each star claims an aud when it needs one
// < claim the next aud that plays in sequence
// 
export class Star {
    gat:Gather
    x: number;
    y: number;
    fieldIndex: number;
    size: number;
    brightness: number;
    isActive: boolean = $state(false);
    get idname() {
        return "Star"+this.x.toFixed(2)
            +(this.aud ? ':'+this.aud.idname : '')
    }
    // keep track of which aud we are supposed to be playing
    //  in case we return to one
    aud:Audiolet | null = null;
    constructor(opt) {
        Object.assign(this,opt)
    }
    pause() {
        if (!this.isActive) console.warn("Star double-pause")
        this.isActive = false;
        V>1 && console.log(`Star at (${this.idname}) paused`);
        this.aud?.pause()
    }
    
    async play() {
        // find a new aud?
        let aud = this.aud || this.find_an_aud()
        if (!aud) {
            return this.no_aud_available()
        }
        if (aud.stopped) {
            console.warn(`${this.idname} aud had stopped. Off the end of a stretch?`)
            this.isActive = false;
            this.aud = null
            return await this.play()
        }

        if (this.isActive) console.warn("Star double-play")
        this.isActive = true;
        V>1 && console.log(`${this.idname} is now playing`);

        if (!this.gat.queue.includes(aud)) {
            return this.aud_is_lost()
        }
        if (aud.star && aud.star != this) {
            console.error(`overassigning stars`)
            aud.star.aud = null
            aud.star.isActive = false
        }

        this.aud = aud
        aud.star = this

        if (aud.paused) {
            aud.play('*unpause')
            // console.log(`Was paused: ${aud.paused_time}`)
        }
        else {
            // become gat.currently via provisioning,
            //  being ready but not playing,
            // or noop if we're already playing - the first star's aud is.
            aud.play('*play')
        }
        
        aud.think()
    }
    // follows that of Audiolet
    started_stretch() {
        // deduce the one that means play() worked, and let Stars.look() happen again
        this.gat.star_started_stretch(this)
    }

    // next track, same star
    next_aud(next) {
        let was = this.aud
        this.aud = next
        next.star = this
        if (was && was != next) {
            if (!was.stopped) console.error(`next_aud(): was !stopped: ${was.idname}`)
            was.pause()
        }
    }

    // < cull aud that have been paused for a long time
    //   as in traveling far across space, switching on lots of aud...
    aud_is_lost() {
        console.warn("aud is lost")
        if (this.aud) {
            this.aud.star = null
            this.aud = null
        }
        this.isActive = false
        setTimeout(() => {
            this.play()
        },200)
    }
    find_an_aud():Audiolet|null {
        // this gets us all !aud.playing
        let all = this.gat.suitable_new_auds()
        // it's probably better to recycle an aud than wait for a decode
        // < not too clear what's happening, of course. when scrolling hard.
        let playable = all.filter(aud => aud.next_stretch)
        let nostar = playable.filter(aud => !aud.star)
        if (nostar[0]) {
            return nostar[0]
        }
        return this.recyclingly_find_an_aud()
    }
    // try harder, by recycling a hardly-played aud
    recyclingly_find_an_aud():Audiolet|null {
        let all = this.gat.playable_auds()
            .filter(aud => aud.paused)
        let sorted = all.map(aud => {
            return {along:(aud.along()||0),aud}
        }).sort((a,b) => (a.along - b.along))

        // console.log("Could be sorted: ",sorted)
        let some_along = sorted.filter(a => a.along != 0)

        let not_far = some_along.filter(a => a.along < 500)
        let aud;
        if (not_far.length) {
            // < test this, doesn't seem to occur
            let long_ago = not_far.map(a => {
                return {...a, paused:a.aud.paused}
            }).sort((a,b) => (a.paused - b.paused))
            V>1 && console.log("In order: longest-paused first", long_ago.map(a => a.paused))
            aud = long_ago[0]?.aud
        }
        // < there's a new Object.groupBy() method I kind of wanted to use here

        aud ||= some_along[0]?.aud
        if (!aud) console.warn("still no recyclingly_find_an_aud()")
        if (!aud) return
        // revoke from the other star
        // < this doesn't seem to get it done!?
        if (aud.star) {
            V>2 && console.log(`${this.idname} Recycling aud from ${aud.star.idname}`)
            aud.star.aud = null
            aud.star.isActive = false
            aud.star = null
        }
        return aud
    }

    no_aud_available() {
        // before the first aud appears
        //  or when we run out of fresh auds
        // await for the next decode
        console.warn(`${this.idname} no_aud_available(), waits for on_next_stretch...`)
        this.gat.on_next_stretch = (aud) => {
            this.gat.on_next_stretch = null
            console.log(`${this.idname} on_next_stretch !!!`)
            // not introduced to the star, just hope
            // there could be others that are suitable_new_auds() by now
            // we wait for the next decoded one, which may not be the one we actually pick
            if (this.aud) {
                return
            }

            this.play()

            if (this.aud != aud) {
                console.warn("on_next_stretch: didn't find the one")
            }
        }
    }
}


