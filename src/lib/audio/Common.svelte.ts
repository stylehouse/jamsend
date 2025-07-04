
// test params
// all queues have this ending
export const MOCK_END_OF_INDEX = 9
// various timing code needs to regard the decoded audio aud.playing.duration
export const MOCK_MS_PER_ITEM = 621
export const MOCK_BLOB = 'vvv'
export const PHI = 1.613
export const MS_PER_SIMULATION_TIME = 333
// see also the audio constants in Audiolet
// turn up log statement level
//  3 = every more response
export const V = 2


// a unique song URI (on disk filename) hash
export type urihash = string

// sometimes requests for more audio have specifics:
export type audioi = {
    // identifies a track
    id: urihash,
    // position they're streaming towards
    index: number,
}
// the response of part|whole
export type audiole = audioi & {
    blob: Uint8Array,
    // Last bit -> start another from the start
    done?: boolean;
    // Song metadata if available
    meta?: {
        artist: string;
        album: string;
        title: string;
        year: string;
        cover?: Uint8Array;
        duration?: number;
    };
}

export type timestamp = Number
export type songmeta = {
    artist:string,
    album:string,
    title:string,
    year:string,
    cover:Uint8Array,
}
export type TheMusic = {
    id:urihash,
    path:string, // on the filesystem at /music
    meta:songmeta, // gradually emerging, cover art etc
    size:Number, // in bytes
    // < to garbage collect meta, meta.covers may get big
    last_read:timestamp,
}


// time since thing was relevant, when can be culled
// five seconds in miliseconds
const LONG_AGO = 5000
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
        let history = (this.scheme.history || 0)
        if (history == -1) return
        let culled = []
        if (this.now) {
            culled.push(...(this.cull_stopped_audiolets?.()||[]))
            culled.push(...(this.cull_long_paused_audiolets?.()||[]))
            culled.push(...(this.cull_old_star_fields?.()||[]))
        }
        else {
            // < something Queuey-generic about which item is the cursor in
            // let i = Math.floor(this.cursor())
        }
        if (culled.length) {
            V>1 && console.log(`cull_queue() x${culled.length}`)
            culled.map(aud => aud.culled = 1)
            // tell the server to relax
            this.no_more?.(culled)
        }
    }
    remove_item_from_queue(aud) {
        let index = this.queue.indexOf(aud)
        if (index >= 0) {
            this.queue.splice(index, 1)
            return 1
        }
    }
    cull_stopped_audiolets() {
        let culled = []
        // assume things will get stopped when they're old
        let stopped = this.queue
            .filter(aud => aud.stopped)
        for (let i = 0; i < (this.scheme.history || 0); i++) {
            stopped.pop()
        }
        let sane = 0
        while (stopped.length && sane++<500) {
            let aud = stopped.shift()
            this.remove_item_from_queue(aud)
                && culled.push(aud)
        }
        return culled
    }
    cull_long_paused_audiolets() {
        let culled = []
        const now = this.now()
        // sort by most long ago paused
        const paused = this.queue
            .filter(aud => aud.paused && !aud.stopped)
            .map(aud => ({
                aud,
                pausedDuration: now - aud.paused,
            }))
            .filter(a => a.pausedDuration > LONG_AGO)
            .sort((a, b) => b.pausedDuration - a.pausedDuration)
        

        for (let i = 0; i < (this.scheme.history || 0); i++) {
            paused.pop()
        }
        let sane = 0
        while (paused.length && sane++<500) {
            let a = paused.shift()
            let aud = a.aud
            V>1 && console.log(` --cull ${aud.idname} - ${a.pausedDuration}`)
            this.remove_item_from_queue(aud)
                && culled.push(aud)
        }
        return culled
    }
    // cull old star fields and their star.aud references
    //  aud not in gat.queue can be found in here
    cull_old_star_fields() {
        if (!this.star_field) return []
        
        let culled = []
        const now = this.now()
        const FIELD_DISTANCE_THRESHOLD = 4 // fields more than 5 away from current position
        
        const fieldsToRemove = []
        
        // Find old star fields to remove
        V>1 && console.log(`Culling star fields far from ${this.star_field_visiting}`) 
        for (const [indexStr, field] of Object.entries(this.star_field)) {
            const index = parseInt(indexStr)
            const distance = Math.abs(index - this.star_field_visiting)
            
            if (distance > FIELD_DISTANCE_THRESHOLD) {
                // too old and too far away
                fieldsToRemove.push({ index, field })
            }
        }
        
        // Clean up the star fields
        for (const { index, field } of fieldsToRemove) {
            // Clean up star.aud references and collect culled audiolets
            if (field.stars) {
                for (const star of field.stars) {
                    if (star.aud) {
                        V>1 && console.log(`Culling from star field ${index}: ${star.idname}`)
                        if (star.isActive) console.error("culled star was active")
                        // Break the circular reference
                        star.aud.star = null
                        star.aud = null
                        // we could drop all the aud that were there?
                        //  but it's likely user is surfing along
                        //  and we want the diversity of snippets
                        // this.remove_item_from_queue(aud)
                        //     && culled.push(aud)
                    }
                }
            }
            
            // Remove the field from memory
            //  keep_field() will regenerate it if we look() at it
            delete this.star_field[index]
            V>1 && console.log(`Culled old star field ${index}`)
        }
        // don't return already culled audiolets
        return culled.filter(aud => !aud.culled)
    }



    // get more queue
    awaiting_mores = []
    more_wanted = $state()
    provisioning_okay = null
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
            this.provisioning_okay = false
            V>2 && console.log(`${this.idname} Wanted ${more_wanted} more (cursor:${i})`)
            // < request specific indexes here
            for (let it = 1; it <= more_wanted; it++) {
                this.get_more({delay:it*140})
            }
        }
        if (!this.provisioning_okay
            && !more_wanted
            && !this.awaiting_mores?.length) {
            // a sign that this is coming in okay (from where ever)
            // and it's as ready as it can be until started
            this.provisioning_okay = true
            this.on_provisioning_okay?.()
        }
    }
}