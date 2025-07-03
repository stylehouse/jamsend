import type { Socket } from "socket.io";
import { io } from "socket.io-client";
import { V } from "./Common.svelte";
import type { urihash,audioi,audiole } from "./Common.svelte";
import { GathererTest } from "./GatherTest.svelte";
import { Audiolet } from "./Audiolet.svelte";



export class GatherSocket extends GathererTest {
    connected = false;
    socket: Socket;

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
    }

    
    //#region gat req
    // fetch a random track, creating its Audiolet
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
}


//#region gat
export class GatherAudios extends GatherSocket {
    AC: AudioContext | null = $state(null)
    declare on_begun: Function | null = null
    on_error: Function | null = null
    // throws this away and starts over
    recreate_gat:Function|null
    begun = false;
    close() {
        super.close()
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
            this.think();
        }
    }
    pending_have_more:Array<audiole> = null
    // decides to and arrests the initial few gat.have_more() until begun
    grab_have_more(res) {
        if (this.begun) return
        // if !gat.AC_OK, we don't want to spawn any aud just yet...
        let N = this.pending_have_more ||= []
        N.push(res)
        console.log("Pending the aud: ",res)
        return true
    }

    // via have_more()
    new_audiolet(opt) {
        let aud = new Audiolet(opt)
        if (!aud.gat) throw "!aud.gat"
        return aud
    }
    now() {
        return this.AC?.currentTime * 1000
    }
}


