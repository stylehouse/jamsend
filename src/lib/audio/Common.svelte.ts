
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