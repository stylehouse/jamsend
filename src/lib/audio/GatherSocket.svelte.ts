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
        this.scheme.future = 1
        this.setupSocket();
    }

    setupSocket() {
        this.socket = io();

        // Handle incoming audio data
        this.socket.on('more', async (r: audiole) => {
            try {
                if (!r.id) throw new Error("Missing track ID in response");
                this.handle_more(r);
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
    handle_more(r) {
        if (r.index == 0) {
            // requested by gat
            this.have_more(r)
        }
        else {
            // requested by an aud
            let aud = this.queue.filter(aud => aud.id == r.id)[0]
            if (!aud) throw "id !aud"
            aud.have_more(r)
        }
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
        return this.AC?.currentTime * 1000
    }
}

let MOCK_MS_PER_ITEM = 3000
export class Audiolet extends AudioletTest {
    // we re-type this from the superclass
    //  'declare' that or it'll come back from super() undefined
    declare gat:GatherAudios
    gainNode: GainNode;

    constructor(opt) {
        super(opt)
        this.setupAudiolet();
    }
    setupAudiolet() {
        // Create gain node for fades
        this.gainNode = this.gat.AC.createGain();
        this.gainNode.connect(this.gat.AC.destination);
        this.gainNode.gain.value = 1;
    }

    // < become based on a rolling start_time?
    //    any extra duration divided by extra stretch_size
    //   or something.
    average_new_chunk_duration?:number
    get approx_chunk_time() {
        return this.average_new_chunk_duration || MOCK_MS_PER_ITEM
    }
    // where in the queue are we up to
    cursor() {
        if (this.stretch_start_time == null) return null
        // time into the new part of this stretch
        let time = this.gat.now() - this.stretch_start_time
        let i = Math.floor(time / this.approx_chunk_time)
        // time = Math.round(time)
        // let newdur = Math.round(this.stretch_new_duration)
        // console.log(`cursor(): ${i}: ${time} @ ${newdur} (+${this.stretch_start_index})`)
        // into the wider context of the queue
        i = i + this.stretch_start_index
        return i
    }
    along() {
        if (this.start_time == null) return null
        return this.gat.now() - this.start_time
    }
    remaining_stretch():number {
        // < playing.duration - along()
        //    or just the seeked part of playing?
        let along = this.along()
        if (along == null) return 0
        let remains = this.duration() - along
        return Math.round(remains)
    }
    // includes the skipped portion (playFrom)
    duration():number {
        return this.playing.buffer.duration * 1000
    }

    // in seconds, not ms
    previous_duration?:number
    previous_stretch_size?:number
    stretch_start_index?:number
    stretch_start_time?:number
    stretch_new_chunks?:number
    stretch_new_duration?:number
    // called by start_stretch() before it calls plan_ending()
    started_stretch() {
        let playFrom = 0
        if (this.previous_duration) {
            // skip to where we ended
            playFrom = this.previous_duration
        }
        this.playing.start(0,playFrom)
        // allows cursor() to be more accurate
        this.stretch_start_index = (this.previous_stretch_size||1) - 1
        this.stretch_start_time = this.gat.now()
        this.stretch_new_chunks = this.stretch_size - (this.previous_stretch_size||0)
        this.stretch_new_duration = this.duration() - (this.previous_duration||0)
        this.average_new_chunk_duration = this.stretch_new_duration / this.stretch_new_chunks
        // for next time
        this.previous_duration = this.duration()
        this.previous_stretch_size = this.stretch_size
    }


    async decode_stretch(encoded) {
        let n_chunks = encoded.length
        encoded = this.flatten_ArrayBuffers(encoded)
        const decoded = await this.gat.AC.decodeAudioData(encoded.buffer);
        const stretch = this.gat.AC.createBufferSource();
        stretch.buffer = decoded;
        stretch.connect(this.gainNode);
        // stash this here, becomes stretch_size
        stretch.length = n_chunks
        return stretch
    }
    flatten_ArrayBuffers(ArrayBuffers:Array<ArrayBuffer>) {
        const totalLength = ArrayBuffers.reduce((sum, buffer) => sum + buffer.byteLength, 0);
        const concatenated = new Uint8Array(totalLength);
        
        let offset = 0;
        for (const buffer of ArrayBuffers) {
            concatenated.set(new Uint8Array(buffer), offset);
            offset += buffer.byteLength;
        }

        return concatenated
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

