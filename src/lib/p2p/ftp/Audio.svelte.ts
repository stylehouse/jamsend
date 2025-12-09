import type Modus from "$lib/mostly/Modus.svelte";

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
        return this.AC?.currentTime * 1000
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
            return false;
        }
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
    new_audiolet(opt) {
        let aud = new Audiolet({gat:this,...opt})
        if (!aud.gat) throw "!aud.gat"
        return aud
    }
}
type ACtime = number
export class Audiolet {
    gat:SoundSystem
    gainNode: GainNode;
    constructor(opt) {
        Object.assign(this,opt)
        this.setupAudiolet();
    }
    setupAudiolet() {
        // Create gain node for fades
        this.gainNode = this.gat.AC.createGain();
        this.gainNode.connect(this.gat.AC.destination);
        this.gainNode.gain.value = 1;
    }
    stopped = false
    playing?:AudioBufferSourceNode
    start_time?:ACtime
    stop() {
        this.stopped = true
        this.playing?.stop()
    }
    along() {
        if (this.start_time == null) return 0
        return this.gat.now() - this.start_time
    }
    duration():number {
        return this.playing.buffer.duration * 1000
    }
    async play_this_data(encoded) {
        let stretch = await this.decode_stretch(encoded)

        stretch.onended = () => {
            console.log("stretch ended")
        }

        this.playing = stretch
        let playFrom = 0
        this.playing.start(0,playFrom)
        this.start_time = this.gat.now()
        // < plan_next()
        
    }



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



}