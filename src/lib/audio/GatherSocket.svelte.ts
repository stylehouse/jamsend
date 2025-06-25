import type { Socket } from "socket.io";
import { io } from "socket.io-client";
import { V } from "./Common.svelte";
import type { urihash,audioi,audiole } from "./Common.svelte";
import { GathererTest } from "./GatherTest.svelte";
import { AudioletTest } from "./GatherAudiolet.svelte";

// in ms
const FADE_OUT_DURATION = 333
const FADE_IN_DURATION = 155
const MIN_GAIN = 0.001


//#region gat
export class GatherAudios extends GathererTest {
    AC: AudioContext | null = $state(null)
    connected = false;
    begun = false;
    socket: Socket;
    // throws this away and starts over
    recreate_gat:Function|null
    on_error:Function|null
    declare on_begun:Function|null

    constructor(opt) {
        super(opt)
        this.scheme.future = 0
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
        // < ffmpeg recycling token via gat
        this.socket.on('connect', () => {
            this.connected = true;
            
            let recycled = ''
            if (this.socketid) {
                this.socket.emit('try_recycle_gatid', {id:this.socketid})
                recycled = ', recycling '+this.socketid
            }
            this.socketid = this.socket.id

            V>0 && console.log('Connected to audio server'+recycled);
            this.beginable();
        });
        // while waiting for this process,
        //  more unstarted mu can occur, so we get them to retry with backoff
        this.socket.on('try_recycle_gatid_failed', () => {
            // a new Gat!
            V>0 && console.log("gatid recycling failed, have to reload")
            this.recreate_gat()
        })
        this.socket.on('try_recycle_gatid_success', () => {
            // it works. to test, devtools you can throttle Network to nothing
            // debugger
        })

        this.socket.on('disconnect', () => {
            V>0 && console.log('Disconnected from audio server');
            this.connected = false;
        });
    }
    close() {
        this.socket?.disconnect();
        this.AC?.close();
    }

    //#region gat AC
    // Initialize audio context (must be triggered by user interaction)
    AC_ready = $state(false)
    init() {
        try {
            this.AC = new AudioContext();

            if (this.AC_OK()) {
                V>0 && console.log("AudioContext initialized");
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
    socket_begun = false
    beginable() {
        if (this.socket && this.connected && !this.socket_begun) {
            // first wave of provisioning
            this.socket_begun = true
            this.think()
        }
        if (this.AC.state === 'suspended') {
            this.AC.resume();
        }
        if (this.AC.state === 'suspended') {
            console.warn("AudioContext still suspended")
            return
        }
        if (this.AC && this.socket && this.connected && !this.begun) {
            this.begun = true;
            // two more for getting this far
            this.scheme.future = 2;

            (this.pending_have_more||[]).map(res => {
                this.have_more(res)
            })

            this.on_begun?.()
            if (!this.on_begun) throw "non on_begun"
            this.surf();
        }
    }

    pending_have_more:Array<audiole>
    // arrests the initial few gat.have_more()
    grab_have_more(res) {
        if (this.begun) return
        if (this.AC_OK()) {
            debugger
        }
        // if !gat.AC_OK, we don't want to spawn any aud just yet...
        let N = this.pending_have_more ||= []
        N.push(res)
        console.log("Pending the aud: ",res)
        return true
    }


    
    //#region gat req
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

//#region aud
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
    fadein() {
        this.gainNode.gain.setValueAtTime(MIN_GAIN, this.gat.now()/1000)
        let at = this.gat.now() + FADE_IN_DURATION
        this.gainNode.gain.exponentialRampToValueAtTime(
            1.0,
            at/1000
        )
    }
    fadeout() {
        // prevent further aud.start_stretch() etc immediately
        this.stopped = 1
        // < redundant given stopped?
        this.gat.fadingout.push(this)
        setTimeout(() => {
            V>2 && console.log(`Fadeout done, ${this.gainNode.gain.value}`)
            this.stop()
        }, FADE_OUT_DURATION)


        let at = (this.gat.now() + FADE_OUT_DURATION) / 1000
        V>1 && console.log(`Fadeout? ${this.gat.now()/1000}\t${at}`)
        this.gainNode.gain.linearRampToValueAtTime(
            MIN_GAIN,
            at
        )
    }
    stop() {
        this.stopped = 1
        this.playing?.stop()
        this.gat.fadingout = this.gat.fadingout
            .filter(aud => aud != this)
    }


    //#region aud time
    // < become based on a rolling start_time?
    //    any extra duration divided by extra stretch_size
    //   or something.
    average_new_chunk_duration?:number
    get approx_chunk_time() {
        return this.average_new_chunk_duration || MOCK_MS_PER_ITEM
    }
    // where in the queue are we up to
    //  we don't seem to be able to know exactly where the audio
    cursor(hires=false) {
        if (this.stretch_start_time == null) return null
        // time into the new part of this stretch
        let time = this.gat.now() - this.stretch_start_time
        if (this.paused) {
            // pretend it's then
            time = this.paused
        }
        // where is that in a queue of typical chunks
        let cursor = time / this.approx_chunk_time
        // point of reference = most recent start time data
        cursor += this.stretch_start_index
        // into the wider context of the queue
        if (hires) return cursor
        return Math.floor(cursor)
    }
    along() {
        if (this.start_time == null) return null
        return this.gat.now() - this.start_time - this.paused_time
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
    // in miliseconds!
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
            // skip to where we ended, in seconds
            playFrom = this.previous_duration / 1000
        }
        this.playing.start(0,playFrom)
        // allows cursor() to be more accurate
        this.stretch_start_index = (this.previous_stretch_size||1) - 1
        this.stretch_start_time = this.gat.now() + this.paused_time
        this.stretch_new_chunks = this.stretch_size - (this.previous_stretch_size||0)
        // < this may or may not include some paused_time - hard
        this.stretch_new_duration = this.duration() - (this.previous_duration||0)
        this.average_new_chunk_duration = this.stretch_new_duration / this.stretch_new_chunks
        // for next time
        this.previous_duration = this.duration()
        this.previous_stretch_size = this.stretch_size
    }
    paused_time = 0
    pause() {
        this.paused = this.gat.now()
        // where to resume above
        this.previous_duration = this.along()
        this.playing.stop()
    }
    play() {
        if (this.paused) {
            this.paused_time += this.gat.now() - this.paused
            this.paused = null
            this.restart_stretch()
        }
        else {
            throw "do you mean might()?"
        }
    }
    restart_stretch() {
        // these objects only play once
        let old = this.playing
        let stretch = this.stretchify_decode(old.buffer)
        stretch.length = old.length
        this.playing = stretch
        this.started_stretch()
        // ending remains planned, ie the station plays another track
        
    }


    //#region aud stretch
    async decode_stretch(encoded) {
        let n_chunks = encoded.length
        encoded = this.flatten_ArrayBuffers(encoded)
        const decoded = await this.gat.AC.decodeAudioData(encoded.buffer);
        const stretch = this.stretchify_decode(decoded)
        // stash this here, becomes stretch_size
        stretch.length = n_chunks
        return stretch
    }
    stretchify_decode(decoded) {
        const stretch = this.gat.AC.createBufferSource();
        stretch.buffer = decoded;
        stretch.connect(this.gainNode);
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
        this.request_more(req)
    }
    request_more(req) {
        this.gat.socket.emit('more',req)
    }


    aud_onended:Function|null
    // called by start_stretch()
    plan_ending(was) {
        this.playing.onended = () => {
            if (this.paused) return

            // < sanity checks for the wild
            let early = this.gat.now() < 1500
            let playlittle = this.along() / this.duration() < 0.1
            if (early && playlittle) {
                console.error(`Wert only: ${this.along()} / ${this.duration()}`)
                this.was_playlittle = 1
                return
            }
            if (this.was_playlittle) {
                console.warn("this.was_playlittle")
            }

            this.whatsnext()
        }
    }

}

