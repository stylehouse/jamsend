
import type { Socket } from "socket.io";
import { io } from "socket.io-client";
import { writable, derived, get } from 'svelte/store';

// a unique song URI hash
export type urihash = String

// sometimes requests for more audio have specifics:
export type audioi = {
    // identifies a track
    id: urihash,
    // position they're streaming towards
    index: Number,
}
// the response of part|whole
type audiole = audioi & {
    blob: Uint8Array,
    // < last bit -> start another from the start
    done?: Boolean
}
export class Gatherer {
    socket:Socket
    on_error:Function

    audiolets:Map<urihash,Audiolet> = new Map()
    constructor(opt?) {
        Object.assign(this, opt)
        this.setupSocket();
    }
    // move down near offer etc
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
            this.on_error?.(error)
        })
        this.socket.on('connect', () => {
            console.log('Connected to audio server');
        })
        this.socket.on('disconnect', () => {
            console.log('Disconnected from audio server');
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
    }

}


// handles time-spurred whims to arrange audio
export class Audiocean {
    AC = new AudioContext()
    close() {
        this.AC.close()
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
        if (!this.random_track) {
            throw "!this.random_track"
        }
        if (this.current) {
            this.current.fadeOut()
        }
        this.current = random_tracks.shift()
        this.gather_random_track()
    }
    // start random track at the start
    next() {
        // < called at the end of the previous track, 
    }

    // queue of incoming random tracks
    random_tracks = []
    gather_random_track() {

    }
}