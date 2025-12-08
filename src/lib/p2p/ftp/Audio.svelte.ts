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

    //
}