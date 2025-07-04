import { V } from "./Common.svelte";
import type { Gather } from "./Gather.svelte";
import { AudioletTest } from "./GatherAudiolet.svelte";
import type { Star } from "./GatherStars.svelte";

// alongside AudioletTest

// in ms
const FADE_OUT_DURATION = 1533
const FADE_IN_DURATION = 255
const MIN_GAIN = 0.0001
// Target loudness in LUFS
const TARGET_LUFS = -8.0
const MAX_GAIN = 6.0
const MIN_GAIN_DB = -20

//#region aud
let MOCK_MS_PER_ITEM = 3000
export class Audiolet extends AudioletTest {
    // we re-type this from the superclass
    //  'declare' that or it'll come back from super() undefined
    declare gat:Gather
    gainNode: GainNode;
    star?:Star

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

    stop() {
        this.stopped = 1
        this.playing?.stop()
        this.gat.fadingout = this.gat.fadingout
            .filter(aud => aud != this)
    }

    // make all the same loudness
    // < use libebur128-wasm
    full_gain(): number {
        // Default to 1.0 if no loudness data available
        const loudness = this.meta?.loudness;
        if (!loudness) {
            V > 0 && console.warn(`${this.idname}: No loudness data, using gain 1.0`);
            return 1.0;
        }
        
        // Calculate gain needed to reach target LUFS
        const gainDb = TARGET_LUFS - loudness;
        
        // Apply safety limits
        const limitedGainDb = Math.max(MIN_GAIN_DB, Math.min(gainDb, this.dbToLinear(MAX_GAIN)));
        
        // Convert to linear gain
        const linearGain = this.dbToLinear(limitedGainDb);
        
        // Log the calculation for debugging
        V > 2 && console.log(
            `${this.idname}: Loudness ${loudness.toFixed(1)} LUFS → ` +
            `${gainDb.toFixed(1)}dB gain (${linearGain.toFixed(3)} linear) `
        );
        
        return linearGain;
    }
    private dbToLinear(db: number): number {
        return Math.pow(10, db / 20);
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
        let time = this.gat.now() - this.stretch_start_time - this.stretch_paused_time()

        // where that is in a queue of typical these-chunks
        let cursor = time / this.approx_chunk_time
        // point of reference = most recent start time data
        cursor += this.stretch_start_index
        if (cursor < -0.05) {
            // < some rounding error?
            throw new Error(`${this.idname}: Cursor < 0`)
        }
        // into the wider context of the queue
        if (hires) return cursor
        return Math.floor(cursor)
    }
    along() {
        if (this.start_time == null) return null
        return this.gat.now() - this.start_time - this.all_paused_time()
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
        this.stretch_start_time = this.gat.now()
        // because new_duration may include some paused_time
        this.stretch_start_paused_time = this.all_paused_time()
        
        // see start_stretch() / previous_duration
        this.stretch_new_chunks = this.stretch_size - (this.previous_stretch_size||0)
        this.stretch_new_duration = this.duration() - (this.previous_duration||0)
        this.average_new_chunk_duration = this.stretch_new_duration / this.stretch_new_chunks
        
        this.star?.started_stretch?.()
        // re-assess when to do what for the future, now now is now
        this.plan_next()
    }
    //  roll these over once per new stretch, not every started_stretch()
    starting_new_stretch() {
        if (this.playing) {
            this.previous_duration = this.duration()
            if (this.previous_stretch_size == this.stretch_size) debugger
            this.previous_stretch_size = this.stretch_size || 0
        }
    }

    //#region aud pauses
    is_fading = false
    fadein() {
        if (this.is_fading) {
            // where-ever it is
            this.gainNode.gain.cancelScheduledValues(this.gat.now()/1000)
            this.is_fading = false
            console.log(`${this.idname} fade back in from where-ever`)
        }
        else {
            // up from silence
            this.gainNode.gain.setValueAtTime(MIN_GAIN, this.gat.now()/1000)
        }
        let at = this.gat.now() + FADE_IN_DURATION
        this.gainNode.gain.exponentialRampToValueAtTime(
            this.full_gain(),
            at/1000
        )
    }
    async fadeout() {
        let the_fading = this.is_fading = {}
        let at = (this.gat.now() + FADE_OUT_DURATION) / 1000
        this.gainNode.gain.exponentialRampToValueAtTime(
            MIN_GAIN,
            at
        )
        return new Promise((resolve) => {
            setTimeout(() => {
                 resolve(the_fading != this.is_fading)
            }, FADE_OUT_DURATION)

        })
    }

    paused = $state(null)
    paused_time = 0
    async pause() {
        // this will take some time
        let invalidated = await this.fadeout()
        // if we fadein() (etc?) again while we were fading out, don't pause
        if (invalidated) {
            V>1 && console.log(`${this.idname} stopped fading!`)
            this.star && this.gat.done_travel?.(this.star)
            return
        }
        this.is_fading = false

        
        this.should_play = null
        if (!this.playing) {
            // < how does this happen?
            console.warn(`pause() on non-playing ${this.idname}`)
            return
        }
        this.paused = this.gat.now()
        // where to resume above
        this.previous_duration = this.along()
        // < not always enough?
        this.playing.stop()
    }
    // stop along()ing
    all_paused_time() {
        let paused_time = this.paused_time
        if (this.paused) {
            paused_time += this.gat.now() - this.paused
        }
        return paused_time
    }
    // and for only the latest stretch
    stretch_start_paused_time = 0
    stretch_paused_time() {
        return this.all_paused_time() - this.stretch_start_paused_time
    }

    //#region play
    async play(why="?") {
        if (this.stopped) debugger
        if (this.paused) {
            if (this.stopped) debugger
            this.paused_time += this.gat.now() - this.paused
            this.paused = null
            this.gat.currentlify(this,"aud.play")
            this.restart_stretch()
            this.fadein()
        }
        else if (this.is_fading) {
            this.fadein()
            this.gat.currentlify(this,"was only fading towards a pause")
        }
        else if (this.playing) {
            console.error("double play()?")
            this.gat.currentlify(this,"double play()?")
            this.fadein()
        }
        else {
            // want to wait for it, or we pause() / fadeout() the last aud too soon
            await this.shall_play(why+' play()')
            this.fadein()
        }
    }
    should_play = null
    async shall_play(caller) {
        if (this.next_stretch) {
            this.gat.currentlify(this,caller+" shall_play()")
            this.start_stretch()
            this.should_play?.()
            this.should_play = null
        }
        else {
            return new Promise((r) => this.should_play = r)
        }
    }
    restart_stretch() {
        // these objects only play once
        let old = this.playing
        let stretch = this.stretchify_decode(old.buffer)
        // the params of the supposed 
        stretch.length = old.length
        stretch.onended = old.onended
        if (!old.onended) debugger
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