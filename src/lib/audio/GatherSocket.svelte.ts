import type { Socket } from "socket.io";
import { io } from "socket.io-client";
import { AudioletTest, GathererTest } from "./GatherTest.svelte";


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

export class GatherAudios extends GathererTest {
    AC: AudioContext | null = $state(null)
    connected = false;
    begun = false;
    socket: Socket;
    on_error:Function|null
    declare on_begun:Function|null

    constructor(opt) {
        super(opt)
        this.setupSocket();
    }

    setupSocket() {
        this.socket = io();

        // Handle incoming audio data
        this.socket.on('more', async (r: audiole) => {
            try {
                if (!r.id) throw new Error("Missing track ID in response");
                this.have_more(r);
            } catch (err) {
                console.error("Error processing audio data:", err);
                this.on_error?.("Error processing audio: " + err.message);
            }
        });

        // Handle server errors
        this.socket.on('error', async ({ error }) => {
            console.error("Server error:", error);
            this.on_error?.("Server error: " + error);
        });

        // Socket connection handlers
        this.socket.on('connect', () => {
            console.log('Connected to audio server');
            this.connected = true;
            this.beginable();
        });

        this.socket.on('disconnect', () => {
            console.log('Disconnected from audio server');
            this.connected = false;
        });
    }
    close() {
        this.socket?.disconnect();
        this.AC?.close();
    }

    // Initialize audio context (must be triggered by user interaction)
    AC_ready = $state(false)
    init() {
        try {
            this.AC = new AudioContext();

            if (this.AC_OK()) {
                console.log("AudioContext initialized");
                this.beginable();
                return true;
            }
        } catch (er) {
            console.error("Failed to initialize AudioContext:", er);
            return false;
        }
    }
    AC_OK() {
        if (this.AC.state === 'suspended') {
            this.AC.resume();
        }
        if (this.AC.state === 'suspended') {
            console.warn("AudioContext still suspended")
            this.AC_ready = false
        }
        else {
            this.AC_ready = true
            return true
        }
    }

    // Check if we can begin playback
    beginable() {
        if (this.AC.state === 'suspended') {
            this.AC.resume();
        }
        if (this.AC.state === 'suspended') {
            console.warn("AudioContext still suspended")
            return
        }
        if (this.AC && this.socket && this.connected && !this.begun) {
            this.begun = true;
            this.on_begun?.()
            if (!this.on_begun) throw "non on_begun"
            this.surf();
        }
    }


    
    // fetch a random track, creating its AudioletTest
    get_more({from_start,delay}) {
        this.awaiting_mores.push(1)
        let req:audioi = {}
        if (from_start) req.from_start = 1
        this.socket.emit('more',req)
    }
    // via have_more()
    new_audiolet(opt) {
        let aud = new Audiolet(opt)
        if (!aud.gat) {
            debugger
        }
        return aud
    }
    now() {
        return this.AC?.currentTime
    }
}


export class Audiolet extends AudioletTest {
    // we re-type this from the superclass
    //  'declare' that or it'll come back from super() undefined
    declare gat:GatherAudios
    gainNode: GainNode;

    constructor(opt) {
        super(opt)
    }

    setupAudiolet() {
        // Create gain node for fades
        this.gainNode = this.gat.AC.createGain();
        this.gainNode.connect(this.gat.AC.destination);
        this.gainNode.gain.value = 0; // Start silent
    }

    async decode_stretch(encoded) {
        const decoded = await this.gat.AC.decodeAudioData(encoded);
        const stretch = this.gat.AC.createBufferSource();
        stretch.buffer = decoded;
        stretch.connect(this.gainNode);
        return stretch
    }

    get_more({}) {
        this.awaiting_mores.push(1)
        // here we always just want more of the queue, in sequence
        //  see gat.have_more() for creation and an initial aud.have_more()
        let req = {id: this.id, index: this.next_index++}
        this.gat.socket.emit('more',req)
    }


    aud_onended:Function|null
    // called by start_stretch()
    plan_ending(was) {
        console.info("Well, is it playing?", this.playing)
        this.playing.onended = () => {
            if (this.stopped) {
                // is over, no need to keep feeding audio
                throw "onended stop happens"
                return
            }
            let ismore = this.playing_onended ? ', is more' : ''
            console.log(`stretchended${ismore}`)
            if (this.playing_onended) {
                // the next stretch is ready to play
                this.playing_onended()
            }
            else {
                // the next track (aud) is ready to play
                if (!this.aud_onended) return console.error("Off the end")
                this.aud_onended()
                this.stopped = 1
            }
        }
    }

}

