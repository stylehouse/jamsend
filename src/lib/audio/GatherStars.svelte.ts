import { Audiolet, GatherAudios } from "./GatherSocket.svelte";

// behaviour superimposition, generating a starfield
export class GatherStars extends GatherAudios {
    think() {
        super.think()

        if (!this.star_field) throw "think() before look()"
            // this.whole_new_field()
        
        
    }
    
    

    star_field = $state()
    star_position = $state()

    whole_new_field() {
        this.star_field = {}
        this.star_position = 0
        this.look()
    }

    star_field_visiting:number
    star_visiting:Star = $state()
    async look() {
        if (!this.star_field) this.whole_new_field()
            
        this.track_field_visiting()

        // what station are we closest to, tune it in
        let closest = this.find_closest_star()
        if (!closest) throw "!closest"
        let cur = this.star_visiting
        if (cur && cur != closest) {
            // change star
            await closest.play()
            cur.pause()
        }
        if (!cur) {
            closest.play()
        }
        this.star_visiting = closest

    }
    // when we don't have an aud yet,
    // callback to start the first star when the first aud starts
    on_next_aud_started:Function|null
    // when that has happened
    star_started = null
    // from first (and all) successful aud-star bindings
    stars_are_playing() {
        if (!this.star_started) {
            this.star_begins_doing_stuff()
        }
        this.star_started = this.now()
    }
    star_begins_doing_stuff() {
        // < doesn't seem to be working?
        console.log(`star_begins_doing_stuff()`)
        setTimeout(() => {
           this.scheme.future = 10
        },150)
    }

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
    gat:GatherStars
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
class Star {
    gat:GatherStars
    x: number;
    y: number;
    fieldIndex: number;
    size: number;
    brightness: number;
    isActive: boolean = $state(false);
    // keep track of which aud we are supposed to be playing
    //  in case we return to one
    aud:Audiolet | null = null;
    constructor(opt) {
        Object.assign(this,opt)
    }
    pause() {
        this.isActive = false;
        console.log(`Star at (${this.x.toFixed(2)}) paused`);
        this.aud?.pause()
    }
    
    loopy =0
    async play() {
        this.isActive = true;
        console.log(`Star at (${this.x.toFixed(2)}) is now playing`);
        this.aud ||= this.find_an_aud()
        let aud = this.aud
        if (!aud) {
            return this.no_aud_available()
        }
        if (!this.gat.queue.includes(aud)) {
            return this.aud_is_lost()
        }
        this.gat.stars_are_playing()
        if (aud.star && aud.star != this) {
            throw "overassigning stars"
        }
        aud.star = this


        if (aud.paused) {
            aud.play()
            console.log(`Was paused: ${aud.paused_time}`)
        }
        else {
            // become gat.currently via provisioning,
            //  being ready but not playing,
            // or noop if we're already playing - the first star's aud is.
            await aud.might()
        }
    }
    // < cull aud that have been paused for a long time
    //   as in traveling far across space, switching on lots of aud...
    aud_is_lost() {
        console.warn("aud is lost")
        setTimeout(() => {
            this.aud = null
            this.play()
        },200)
    }
    find_an_aud():Audiolet|null {
        return this.gat.suitable_new_auds()
            // avoid race to over-assign these before aud.playing
            .filter(aud => !aud.star)
            [0]
    }
    get idname() {
        return "Star"+this.x.toFixed(2)
    }
    no_aud_available():Audiolet|null {
        let got = (aud) => {
            if (this.aud) {
                debugger
            }
            this.aud = aud
            // < going through this for consistency?
            //    to set gat.star_started?
            this.play()
        }
        console.log(`Star no_aud_available()`)
        if (!this.gat.star_started) {
            // await for ~ gat.currently
            this.gat.on_next_aud_started = (aud) => {
                this.gat.on_next_aud_started = null
                console.log(`${aud.idname} on_next_aud_started ${this.idname}`)
                got(aud)
            }
        }
        else {
            // < await whatever aud arrives next
            this.gat.on_next_aud_creation = (aud) => {
                this.gat.on_next_aud_creation = null
                console.log(`${aud.idname} On creation ${this.idname}`)
                got(aud)
            }
        }
    }
}


