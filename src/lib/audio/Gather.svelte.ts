
import type { Socket } from "socket.io";
import { io } from "socket.io-client";
import { writable, derived, get } from 'svelte/store';

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

const BUFFER_AHEAD = 3; // Number of chunks to keep buffered ahead
const FADE_DURATION = 0.5; // Fade duration in seconds


// handles time-spurred whims to arrange audio
export class Audiocean {
    AC: AudioContext | null = $state(null)
    connected = false;
    begun = false;
    socket: Socket;

    // Currently playing and next up tracks
    current: Audiolet | null = $state(null);
    next_track: Audiolet | null = $state(null);

    // UI state
    current_meta = $state(null);
    loading = $state(false);

    // Queue of incoming random tracks
    random_tracks: Audiolet[] = [];

    // Scheduled timeout for next chunk
    nextChunkTimeout: number | null = null;

    close() {
        this.AC?.close();
        if (this.nextChunkTimeout) {
            clearTimeout(this.nextChunkTimeout);
        }
    }

    // Initialize audio context (must be triggered by user interaction)
    init() {
        try {
            this.AC = new AudioContext();

            console.log("AudioContext initialized");
            this.beginable();
            return true;
        } catch (er) {
            console.error("Failed to initialize AudioContext:", er);
            return false;
        }
    }

    // Check if we can begin playback
    beginable() {
        if (this.AC && this.connected && !this.begun) {
            this.begun = true;
            this.surf();
        }
    }

    // Start a random track at random position
    surf() {
        console.log("Surfing to new random track");
        this.loading = true;

        // Fade out current if playing
        if (this.current) {
            this.current.fadeOut().then(() => {
                this.current.stop();
                this.current = null;
            });
        }

        // Request new random track
        this.socket.emit('more', {});
    }

    // Play next planned track (called near end of current track)
    playNextTrack() {
        if (!this.next_track) {
            this.surf(); // No next track ready, just surf
            return;
        }

        const nextTrack = this.next_track;
        this.next_track = null;

        if (this.current) {
            // crossfade, then update the UI
            let was = this.current
            nextTrack.play();
            nextTrack.fadeIn();
            was.fadeOut().then(() => {
                was.stop();
                this.encurrent(nextTrack)
            });
        } else {
            // No current track, just play next
            this.encurrent(nextTrack)
            if (nextTrack.meta) {
                this.current_meta = nextTrack.meta;
            }
        }

        // Prepare another next track
        this.prepareNextTrack();
    }

    // Request a track from beginning (index 0)
    prepareNextTrack() {
        this.socket.emit('more', { index: 0 });
    }

    // Process incoming audio data
    async handle_more(data: audiole) {
        if (!this.AC) return;
        let audiolet = this.findOrCreateAudiolet(data.id);

        // Add the chunk to the audiolet
        await audiolet.addChunk(data.index, data.blob, data.done);
        if (data.index == 0) {
            // might need it playable for the below encurrent()
            await audiolet.decodeChunk(0);
        }

        // If we don't have a current track playing, start this one
        if (!this.current && audiolet.canPlay()) {
            this.encurrent(audiolet);
            this.loading = false;
            this.prepareNextTrack();
        }
        // If we don't have a next track ready and this isn't the current track
        else if (!this.next_track && (!this.current || this.current.id !== data.id) && audiolet.canPlay()) {
            this.next_track = audiolet;
        }

        // Request more chunks if needed for current track
        this.requestMoreIfNeeded();
    }

    encurrent(au: Audiolet) {
        this.current = au;
        this.current_meta = au.meta;
        au.play()
    }

    // Find or create an Audiolet for a track ID
    findOrCreateAudiolet(id: urihash): Audiolet {
        let audiolet = this.audiolets.get(id);
        if (!audiolet) {
            audiolet = new Audiolet(this.AC, id, () => {
                // When this track finishes
                if (this.current && this.current.id === id) {
                    this.playNextTrack();
                }
            });
            this.audiolets.set(id, audiolet);
        }
        return audiolet;
    }

    // Check if we need to request more audio chunks
    requestMoreIfNeeded() {
        if (!this.current) return;

        // If we're close to the end of buffered data for current track,
        // request more chunks
        if (this.current.needsMoreChunks()) {
            // Schedule the request slightly ahead of when we'll need it
            if (this.nextChunkTimeout) {
                clearTimeout(this.nextChunkTimeout);
            }

            this.nextChunkTimeout = setTimeout(() => {
                this.socket.emit('more', {
                    id: this.current.id,
                    index: this.current.getNextChunkIndex()
                });
                this.nextChunkTimeout = null;
            }, 50); // Small delay to avoid too frequent requests
        }
    }

    // Collection of all audiolets by ID
    audiolets: Map<urihash, Audiolet> = new Map();
}


export class Gatherer extends Audiocean {
    on_error: Function;

    constructor(opt?) {
        super();
        Object.assign(this, opt);
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
        super.close(); // Close AudioContext
        console.log("Closing socket");
        this.socket.disconnect();
    }
}

















class Audiolet {
    id: urihash;
    context: AudioContext;
    destination: AudioNode;
    onFinished: Function;

    // Indexed by chunk index
    chunks: Map<number, Uint8Array> = new Map();
    decodedChunks: Map<number, AudioBuffer> = new Map();

    // Playback state
    isPlaying = false;
    isStopping = false;
    currentTime = 0;
    lastChunkIndex = -1;
    sourceNode: AudioBufferSourceNode | null = null;
    gainNode: GainNode;

    // Track status
    isDone = false;
    meta: any = null;

    // Playback position tracking
    scheduledEndTime = 0;
    currentChunkStartTime = 0;
    currentChunkIndex = 0;

    constructor(
        context: AudioContext,
        id: urihash,
        onFinished?: Function
    ) {
        this.context = context;
        this.destination = context.destination;
        this.id = id;
        this.onFinished = onFinished || (() => { });

        // Create gain node for fades
        this.gainNode = context.createGain();
        this.gainNode.connect(this.destination);
        this.gainNode.gain.value = 0; // Start silent
    }

    // Add a new chunk of audio data
    async addChunk(index: number, data: Uint8Array, isDone = false) {
        // Store chunk
        this.chunks.set(index, data);

        // Update last chunk index if needed
        if (index > this.lastChunkIndex) {
            this.lastChunkIndex = index;
        }

        // Mark if this is the last chunk
        if (isDone) {
            this.isDone = true;
        }
    }

    // Decode a chunk of audio data
    async decodeChunk(index: number) {
        try {
            const data = this.chunks.get(index);
            if (!data) return;
            const audioBuffer = await this.context.decodeAudioData(data);
            this.decodedChunks.set(index, audioBuffer);
            // If we're playing and this is the next chunk we need, schedule it
            if (this.isPlaying && index === this.currentChunkIndex + 1) {
                this.scheduleNextChunk();
            }
        } catch (err) {
            console.error(`Error decoding chunk ${index}:`, err);
        }
    }

    // Check if we have enough decoded chunks to start playing
    canPlay(): boolean {
        return this.decodedChunks.has(0);
    }

    // Start playback
    play() {
        if (this.isPlaying) return;

        this.isPlaying = true;
        this.currentChunkIndex = 0;
        this.scheduleNextChunk();
    }



    // Schedule the next chunk for playback
    scheduleNextChunk() {
        if (!this.isPlaying || this.isStopping) return;

        const index = this.currentChunkIndex;
        const audioBuffer = this.decodedChunks.get(index);

        if (!audioBuffer) {
            // We don't have this chunk decoded yet, wait for it
            console.log(`Waiting for chunk ${index} to be decoded`);
            return;
        }

        // Create a new source node
        const source = this.context.createBufferSource();
        source.buffer = audioBuffer;
        source.connect(this.gainNode);

        // Calculate start time
        let startTime;
        if (this.scheduledEndTime <= this.context.currentTime) {
            // Start immediately if we're not currently playing
            startTime = this.context.currentTime;
        } else {
            // Schedule to play right after current chunk
            startTime = this.scheduledEndTime;
        }

        // Schedule the chunk to play
        source.start(startTime);
        this.sourceNode = source;
        this.currentChunkStartTime = startTime;

        // Calculate when this chunk will end
        this.scheduledEndTime = startTime + audioBuffer.duration;

        // Set up callback for when this chunk finishes
        source.onended = () => {
            // Move to next chunk
            this.currentChunkIndex++;

            // If we have more chunks, schedule the next one
            if (this.decodedChunks.has(this.currentChunkIndex)) {
                this.scheduleNextChunk();
            }
            // If we're done and there are no more chunks
            else if (this.isDone && this.currentChunkIndex > this.lastChunkIndex) {
                this.isPlaying = false;
                this.onFinished();
            }
            // Otherwise, we need to wait for more chunks
        };
    }

    // Check if we need more chunks
    needsMoreChunks(): boolean {
        // If we're playing and getting close to running out of buffered chunks
        return this.isPlaying &&
            !this.isDone &&
            this.currentChunkIndex + BUFFER_AHEAD > this.lastChunkIndex;
    }

    // Get the next chunk index to request
    getNextChunkIndex(): number {
        return this.lastChunkIndex + 1;
    }

    // Stop playback
    stop() {
        if (!this.isPlaying) return;

        // Stop the current source
        if (this.sourceNode) {
            try {
                this.sourceNode.stop();
            } catch (e) {
                // Ignore errors if already stopped
            }
            this.sourceNode = null;
        }

        this.isPlaying = false;
        this.isStopping = false;
    }

    // Fade in (from silent)
    async fadeIn() {
        if (!this.context) return Promise.resolve();

        const now = this.context.currentTime;
        this.gainNode.gain.setValueAtTime(0, now);
        this.gainNode.gain.linearRampToValueAtTime(1, now + FADE_DURATION);

        return new Promise<void>(resolve => {
            setTimeout(resolve, FADE_DURATION * 1000);
        });
    }

    // Fade out (to silent)
    async fadeOut() {
        if (!this.context) return Promise.resolve();

        const now = this.context.currentTime;
        this.gainNode.gain.setValueAtTime(this.gainNode.gain.value, now);
        this.gainNode.gain.linearRampToValueAtTime(0, now + FADE_DURATION);
        this.isStopping = true;

        return new Promise<void>(resolve => {
            setTimeout(resolve, FADE_DURATION * 1000);
        });
    }
}

