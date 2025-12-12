import type Modus from "$lib/mostly/Modus.svelte";
import { isar } from "$lib/Y";

export class SoundSystem {
    M: Modus

    AC: AudioContext | null = $state(null)
    constructor(opt) {
        Object.assign(this,opt)
    }
    close() {
        this.AC?.close();
    }
    now() {
        return this.AC?.currentTime || 0
    }

    // Initialize audio context
    // must be triggered by user interaction when this is stuck:
    AC_ready = $state(false)
    async init() {
        try {
            this.AC = new AudioContext();

            if (await this.AC_OK()) {
                console.log("AudioContext initialized");
                this.beginable();
                return true;
            }
        } catch (er) {
            console.error("Failed to initialize AudioContext:", er);
        }
        return false;
    }
    async AC_OK() {
        if (this.AC.state === 'suspended') {
            await this.AC.resume();
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
    beginable() {
        // < this.M.beginable()?
    }

    // the many sound feeds
    new_audiolet(opt={}):Audiolet {
        let aud = new Audiolet({gat:this,...opt})
        if (!aud.gat) throw "!aud.gat"
        return aud
    }
    // if they transcode, what to
    bitrate = 160
}
type ACtime = number
export class Audiolet {
    gat:SoundSystem
    gainNode: GainNode
    gainNode2: GainNode
    outputNode: MediaStreamAudioDestinationNode
    bitrate?
    constructor(opt={}) {
        Object.assign(this,opt)
        this.setupAudiolet();
    }
    getBitrate() {
        return (this.bitrate || this.gat.bitrate) * 1000
    }

    setupAudiolet() {
        this.gainNode2 = this.gat.AC!.createGain();
        this.gainNode2.disconnect()
        this.gainNode2.connect(this.gat.AC!.destination);
        this.gainNode2.gain.value = 1;
        this.gainNode = this.gat.AC!.createGain();
        this.gainNode.disconnect()
        this.gainNode.connect(this.gainNode2);
        this.gainNode.gain.value = 1;
    }

    mediaRecorder?: MediaRecorder
    declare on_recording:Function
    setupRecorder(no_segmenting=false) {
        // don't hear it
        this.gainNode2.disconnect()
        // this thing doesn't allow connections from it
        this.outputNode = this.gat.AC.createMediaStreamDestination()
        this.gainNode.connect(this.outputNode)

        // < make entirely-decodable chunks
        //   perhaps of sets of these chunks when they reach 10s total duration
        //    we shall make them playable from their starts
        //    by quickly doing mediaRecorder.stop() and .start() again
        //    we want to test that for gappiness 
        //     as well as generating tiny chunks
        // https://w3c.github.io/mediacapture-record/
        //   When multiple Blobs are returned (because of timeslice or requestData()),
        //    the individual Blobs need not be playable,
        //    but the combination of all the Blobs from a completed recording MUST be playable.
        let segment_duration = 2
        const options = {
            mimeType: 'audio/webm;codecs=opus',
            audioBitsPerSecond: this.getBitrate(),
        };
        
        let stream = this.outputNode.stream
        console.log("stream",stream)
        this.mediaRecorder = new MediaRecorder(stream, options);
        this.mediaRecorder.ondataavailable = (event) => {
            if (event.data.size > 0) {
                // these are ~35kb chunks of webm usually
                this.on_recording(event.data);
            }
        };

        no_segmenting ? this.mediaRecorder.start()
            : this.mediaRecorder.start(segment_duration*1000)
    }
    encode_segmentation() {
        if (!this.mediaRecorder) return
        this.mediaRecorder.stop()
        this.mediaRecorder.start()
        // < is that like this but with playable chunks?
        // this.mediaRecorder.requestData()
    }


    
    stopped = true
    playing?:AudioBufferSourceNode
    playing_next?:AudioBufferSourceNode
    playing_last?:AudioBufferSourceNode
    start_time?:ACtime
    stop_time?:ACtime
    stop() {
        if (this.stopped) return
        this.stop_time = this.gat.now()
        this.stopped = true
        this.playing?.stop()
        this.playing_last = this.playing
        delete this.playing
        if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
            // https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder/stop_event
            this.mediaRecorder.stop();
            // this.requestData()
        }
    }
    along() {
        if (this.start_time == null) return 0
        if (this.stop_time != null) return this.duration() // assume it stopped at the end
        return this.gat.now() - this.start_time
    }
    most_relevant_playing_instance() {
        return this.playing || this.playing_next || this.playing_last
    }
    duration():number {
        return this.most_relevant_playing_instance()?.buffer?.duration || 0
    }
    left():number {
        if (this.stopped) return 0
        if (!this.pl)
        return this.duration() - this.along()
    }
    async load(encoded:Array<ArrayBuffer>) {
        let stretch = await this.decode_stretch(encoded)
        stretch.onended = () => {
            console.log("stretch ended")
            this.on_ended?.()
            this.stop()
        }
        this.playing_next = stretch
        // < plan_next()
    }
    play(offset=0) {
        this.stop()
        console.log(`aud play`)
        if (!this.playing_next) {
            throw "< clone already decoded this.playing_last ?"
        }
        this.playing = this.playing_next
        delete this.playing_next
        this.playing.start(0,offset)
        this.start_time = this.gat.now() - offset
        this.stop_time = null
        this.stopped = false
    }



    async decode_stretch(encoded) {
        encoded = this.flatten_ArrayBuffers(encoded)
        const decoded = await this.gat.AC!.decodeAudioData(encoded.buffer);
        const stretch = this.stretchify_decode(decoded)
        return stretch
    }
    stretchify_decode(decoded) {
        const stretch = this.gat.AC!.createBufferSource();
        stretch.buffer = decoded;
        stretch.connect(this.gainNode);
        return stretch
    }
    flatten_ArrayBuffers(ArrayBuffers:Array<ArrayBuffer>) {
        if (!isar(ArrayBuffers)) {
            if (!(ArrayBuffers instanceof ArrayBuffer)) throw "!AB"
            ArrayBuffers = [ArrayBuffers]
        }
        const totalLength = ArrayBuffers.reduce((sum, buffer) => sum + buffer.byteLength, 0);
        const concatenated = new Uint8Array(totalLength);
        
        let offset = 0;
        for (const buffer of ArrayBuffers) {
            concatenated.set(new Uint8Array(buffer), offset);
            offset += buffer.byteLength;
        }

        return concatenated
    }



}