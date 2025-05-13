
import type { Socket } from "socket.io";
import { io } from "socket.io-client";

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
    done?: Boolean
}
class Gatherer {
    socket:Socket

    audiolets:Map<urihash,Audiolet> = new Map()
    constructor(opt) {
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
                this.audiolets.get(r.id, got)
            }
            got.more(r)
        })
        this.socket.on('error', async ({error,filename}) => {
            console.error("ws-server Error: ",{error,filename})
        })
    }

}

class Audiolet {
    data
    more(r:audiole) {

    }

}