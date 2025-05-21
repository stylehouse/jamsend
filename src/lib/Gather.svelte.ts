
import type { Socket } from "socket.io";
import { io } from "socket.io-client";
import { writable, derived, get } from 'svelte/store';

// a unique song URI hash
export type urihash = string

// sometimes requests for more audio have specifics:
export type audioi = {
    // identifies a track
    id: urihash,
    // position they're streaming towards
    index: number,
}
// the response of part|whole
type audiole = audioi & {
    blob: Uint8Array,
    // < last bit -> start another from the start
    done?: Boolean
}


// handles time-spurred whims to arrange audio
export class Audiocean {
    AC:AudioContext|null = $state(null)
    close() {
        this.AC?.close()
    }
    // can fail before user gesture on the page
    init() {
        try {
            this.AC = new AudioContext()
        }
        catch (er) {
            return
        }
        this.beginable()
    }
    begun = false
    beginable() {
        if (this.AC && this.connected) {
            if (!this.begun) {
                this.begun = true
                this.begin()
            }
        }
    }
    begin() {
        console.log("BEGUN")
        this.socket.emit('more')
    }

    // currently playing
    current:Audiolet
    current_meta = $state()

    // next track is also random, but starts from the start
    next_track:Audiolet

    // < punctuate voluntary track changes with radio-tuning squelches, loop
    tuning_noise:Audiolet

    // start random track at random position
    surf() {
        if (this.current) {
            // this.current.fadeOut()
        }
        this.current = this.random_tracks.shift()
        // this.current.fadeIn()

        console.log("surf?")
        this.socket.emit('more',{})
    }
    // start random track at the start
    next() {
        // < called near the end of the previous track
        //prev.on_ended = () => next.play()
    }

    // queue of incoming random tracks
    random_tracks = []
    gather_tracks() {
        if (this.random_tracks.length > 5) return
        
    }
}


export class Gatherer extends Audiocean {
    socket:Socket
    on_error:Function

    audiolets:Map<urihash,Audiolet> = new Map()
    constructor(opt?) {
        super()
        Object.assign(this, opt)
        this.setupSocket();
    }
    connected = false
    setupSocket() {
        this.socket = io();

        // may return more bits of songs
        this.socket.on('more', async (r:audiole) => {
            if (!r.id) throw "!audiole"
            let got = this.audiolets.get(r.id)
            if (!got) {
                got = new Audiolet()
                this.audiolets.set(r.id, got)
            }
            got.more(r)
        })
        this.socket.on('error', async ({error}) => {
            this.on_error?.("Server error: "+error)
        })
        this.socket.on('connect', () => {
            console.log('Connected to audio server');
            this.connected = true
            this.beginable()
        })
        this.socket.on('disconnect', () => {
            console.log('Disconnected from audio server');
            this.connected = false
        })
    }

    close() {
        console.error("Closing socket")
        this.socket.disconnect()
    }
}


class Audiolet {
    // indexed by mu.index
    chunks = []

    more(r:audiole) {
        if (r.index == undefined) throw "more !index"
        if (r.blob == undefined) throw "more !blob"
        this.chunks[r.index] = r.blob
        if (r.done) {
            
        }
    }

    // each may be playing
    fadeOut() {

    }
    fadeIn() {

    }
}

