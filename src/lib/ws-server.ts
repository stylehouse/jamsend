import { Server, Socket } from 'socket.io'
import { readFile, writeFile, access, mkdir, readdir, stat } from 'fs/promises';
import { join, dirname, basename, extname } from 'path';
import { constants } from 'fs';
import { createHash } from 'crypto';
import type { ViteDevServer } from 'vite';
import type { urihash } from './audio/Gather.svelte';
import { spawn } from 'child_process'
import { promisify } from 'util'

export const webSocketServer = {
    name: 'webSocketServer',
    configureServer(server: ViteDevServer) {
        if (!server.httpServer) return

        const io = new Server(server.httpServer)

        io.on('connection', async (socket) => {
            console.log('Client connected:', socket.id);
            // apply these handlers to each client object
            // < bad memory management for a busy server?
            AudioServer(socket, io)
        });

        scan_music()
    }
}


// ms?
type timestamp = Number
type songmeta = {
    artist:string,
    album:string,
    title:string,
    year:string,
    cover:Uint8Array,
}
type TheMusic = {
    id:urihash,
    path:string, // on the filesystem at /music
    meta:songmeta, // gradually emerging, cover art etc
    size:Number, // in bytes
    // < to garbage collect meta, meta.covers may get big
    last_read:timestamp,
}
let Music:Map<urihash,TheMusic> = new Map()

// error-sending wrapper
async function carefully(label: string, callback: Function, socket:Socket, doing: Function) {
    try {
        await doing()
    } catch (error) {
        if (error.message == 'Stream closed by client') return
        console.error("Error in ws-server", error)
        socket.emit('error', {
            error: `${label}: ${error.message}`
        });
    }
    return callback && callback({
        success: true,
    });
}


// stocking Music
// < on server start
// < wander around directory structure
//  < balance randomly presenting the population
//    without having a complete list
// < use a database of music, eg Strawberry's sqlite
async function scan_music(musicDir = '/music') {
    console.log(`Scanning music directory: ${musicDir}`);
    
    // Recursive function to scan directories
    async function scanDir(dir) {
        try {
            const entries = await readdir(dir, { withFileTypes: true });
            
            for (const entry of entries) {
                const fullPath = join(dir, entry.name);
                
                if (entry.isDirectory()) {
                    // Recursively scan subdirectories
                    await scanDir(fullPath);
                } else if (entry.isFile()) {
                    // Check if the file is an audio format we support
                    const ext = extname(fullPath).toLowerCase();
                    if (['.opus', '.ogg', '.mp3', '.flac', '.wav'].includes(ext)) {
                        try {
                            // Get file stats to determine size
                            const stats = await stat(fullPath);
                            
                            // Generate a unique hash for this file
                            const fileHash = createHash('sha1')
                                .update(fullPath + stats.size + stats.mtimeMs)
                                .digest('hex');
                            
                            // Create basic music entry
                            const musicEntry: TheMusic = {
                                id: fileHash,
                                path: fullPath,
                                meta: {
                                    artist: '',
                                    album: '',
                                    title: entry.name.replace(ext, ''),
                                    year: '',
                                    cover: new Uint8Array()
                                },
                                size: stats.size,
                                last_read: Date.now()
                            };
                            
                            Music.set(fileHash, musicEntry);
                            console.log(`Added track: ${musicEntry.meta.title}`);
                        } catch (fileErr) {
                            console.error(`Error processing file ${fullPath}:`, fileErr);
                        }
                    }
                }
            }
        } catch (err) {
            console.error(`Error scanning directory ${dir}:`, err);
        }
    }
    
    // Check if the music directory exists
    try {
        await access(musicDir, constants.R_OK);
    } catch (err) {
        console.error(`Music directory ${musicDir} is not accessible:`, err);
        // Create the directory if it doesn't exist
        try {
            await mkdir(musicDir, { recursive: true });
            console.log(`Created music directory: ${musicDir}`);
        } catch (mkdirErr) {
            console.error(`Failed to create music directory:`, mkdirErr);
        }
    }
    
    // Start scanning from the root music directory
    await scanDir(musicDir);
    console.log(`Scan complete. Found ${Music.size} tracks.`);
}


// picking a piece of TheMusic, for a client
// < check for anything, repick
// < take the next couple, in the same page read, save disk io?
// < prefer what others are streaming, save disk io?
let recentlyServed: Set<urihash> = new Set();
const MAX_RECENT = 100
function random_music(): TheMusic | undefined {
    if (Music.size === 0) {
        console.log("No music tracks available.");
        return undefined;
    }

    // < a Music object with hash and sequence indexes
    // generate an array
    const available = Array.from(Music.values())
        .filter(mu => !recentlyServed.has(mu.id));;
    const randomIndex = Math.floor(Math.random() * available.length);
    const mu = available[randomIndex];

    // Track this as recently served
    recentlyServed.add(mu.id);
    if (recentlyServed.size > MAX_RECENT) {
        // Remove oldest (though Set doesn't guarantee order, this is simple)
        const first = recentlyServed.values().next().value;
        recentlyServed.delete(first);
    }

    return mu
}
function get_music(id): TheMusic | undefined {
    return Music.get(id)
}
// bytes of audio given out at once, audioi.index
const CHUNK_SIZE = 60_000
function random_seek_fraction() {
    let min = 0.2
    let max = 0.7
    return Math.random() * (max-min) + min
}

// -> mu <-> feed
//    pauses and resumes to pipe us just enough 100k ogg to serve /more indexes
//    if spawning a new mu.feed && index is random, we should seek into it
//     so the stream starts with an ogg header
function AudioServer(socket, io) {
    // Track FFmpeg feeds per socket
    socket.feeds = new Map(); // mu.id -> feed
    // per socket|user
    let has_meta = {} // mu.id -> true
    socket.on('more', async (r: audioi, cb) => {
        carefully('more', cb, socket, async () => {
            r ||= {}
            console.log("ws AudioServer more: ",r)
            
            let specific = r.id && true
            let from_start = r.from_start
            let mu = r.id ? get_music(r.id) : random_music()
            if (!mu) {
                throw new Error(`!song: ${r.id}`);
            }
            // create an encoder
            let feed = socket.feeds.get(mu.id);
            if (!feed) {
                if (r.index) throw "following (with index) an unstarted mu"
                let fraction = from_start ? 0 : random_seek_fraction()
                feed = await createFFmpegStream(mu, fraction);
                socket.feeds.set(mu.id, feed);
            }
            // read from the encoder
            //  starting at 0 even when we randomly seek
            r.index ||= 0
            let res = {id: mu.id}
            try {
                res.blob = await feed.get_index(r.index);
            } catch (error) {
                if (error.message === 'End of stream reached') {
                    // < the one that says .done=1 should respond before these?
                    res.notexist = 1
                    res.blob = undefined;
                } else {
                    throw error; // Re-throw other errors
                }
            }
            res.index = r.index
            if (feed.lastIndex != null && r.index == feed.lastIndex) {
                res.done = 1
            }
            if (!has_meta[mu.id]) {
                // the user has now been told
                res.meta = mu.meta
                has_meta[mu.id] = true
            }

            if (from_start) {
                console.log(` - is from start`)
                res.from_start = 1
            }
            
            socket.emit('more', res)
        })
    });
    // drop encoders|cache on disconnect
    // < state of gat must reset if it reconnects?
    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
        // Clean up any FFmpeg streams for this client
        for (const [id, feed] of socket.feeds.entries()) {
            feed.close();
        }
        socket.feeds.clear();
    });
}


async function createFFmpegStream(mu, fraction = 0) {
    // Get metadata including duration
    await ffprobe(mu);
    
    // Calculate seek time based on duration and fraction
    const seektime = mu.meta.duration ? Math.floor(mu.meta.duration * fraction) : 0;
    
    // Create ffmpeg process with stream control
    const ff = ffmpegnate(mu, seektime);
    
    // Store encoded chunks from ffmpeg
    const blobs = [];
    let producedIndex = null;
    let consumedIndex = 0;
    let lastIndex = undefined
    let isEnded = false;
    
    // Map of pending requests by index
    const waitingRequests = new Map();
    console.log(`FFmpeg++ ${mu.id}`);
    
    // Set up data handler
    //#region on_data
    ff.on_data = (data) => {
        if (isEnded) {
            if (ff.termied) return
            throw new Error("data after ended")
        }
        if (producedIndex == null) {
            producedIndex = 0
        }
        else {
            producedIndex++
        }
        // Store the new chunk
        blobs[producedIndex] = data;

        // It becomes safe to resolve index-1
        let safe_index = producedIndex - 1
        const nonlast = safe_index >= 0 && waitingRequests.get(safe_index);
        if (nonlast) {
            let safeblob = blobs[safe_index]
            if (!safeblob) throw "!blobs[safe_index] "+safe_index
            consumedIndex = safe_index
            nonlast.resolve(safeblob)
            waitingRequests.delete(safe_index);
        }
        
        // Pause stream if we've buffered enough chunks ahead
        if (consumedIndex + 5 < producedIndex) {
            ff.pause();
            console.log(`FFmpeg+= ${mu.id} ${consumedIndex}/${producedIndex}, pausing`);
        }
        else {
            console.log(`FFmpeg+= ${mu.id} ${consumedIndex}/${producedIndex}`);
        }
    }
    
    // Handle errors from ffmpeg
    ff.on_error = (error) => {
        console.error(`FFmpeg error for ${mu.id}:`, error);
        isEnded = true;
        
        // Reject all pending requests
        for (const [index, { reject }] of waitingRequests.entries()) {
            reject(new Error(`FFmpeg stream error: ${error.message}`));
            waitingRequests.delete(index);
        }
    }
    
    // < ignore that it ends
    //    we just need to know the end_index
    ff.on_end = () => {
        console.log(`FFmpeg stream for ${mu.id} ended normally`);
        isEnded = true;
        // and has drained the pipe
        lastIndex = producedIndex

        // so we can send the final chunk now
        const nonlast = waitingRequests.get(lastIndex);
        if (nonlast) {
            let safeblob = blobs[lastIndex]
            if (!safeblob) throw "!blobs[lastIndex] "+lastIndex
            consumedIndex = lastIndex
            nonlast.resolve(safeblob)
            waitingRequests.delete(lastIndex);
        }
        // and reject requests further than that
        for (const [index, { reject }] of waitingRequests.entries()) {
            reject(new Error('End of stream reached'));
            waitingRequests.delete(index);
        }
    }

    //#region get_index
    // Return feed interface with improved chunk retrieval
    return {
        async get_index(index) {
            // If requested chunk already exists,
            //  and can't become the last chunk
            //   for which we need to say "done"
            // return it immediately
            let last_chunk = index == producedIndex
            let should_wait = lastIndex == null && last_chunk
            if (!should_wait && blobs[index] !== undefined) {
                const blob = blobs[index];
                // < efficient multi-client vs. not storing lots of memory?
                // delete blobs[index];
                consumedIndex = index
                console.log(`/more served ${mu.id}: ${index}`);
                return blob;
            }
            
            // If stream has ended and we're requesting beyond available chunks
            if (lastIndex != null && index > lastIndex) {
                console.log(`/more request for ${mu.id}: ${index} (stream ended)`);
                throw new Error("End of stream reached");
            }
            
            // If requested future chunk that hasn't been generated yet

            if (index >= producedIndex) {
                let resu = ff.paused ? "(resuming)" : ""
                console.log(`/more waiting for ${mu.id}: ${index} ${resu}`);
                ff.resume();
                // when the requested chunk is available
                return new Promise((resolve, reject) => {
                    // Store the promise resolvers for this index
                    waitingRequests.set(index, { resolve, reject });
                    
                    // Set a timeout to avoid hanging forever
                    setTimeout(() => {
                        if (waitingRequests.has(index)) {
                            waitingRequests.delete(index);
                            reject(new Error(`Timeout waiting for chunk ${index}`));
                        }
                    }, 30000); // 30 second timeout
                });
            }
            
            console.log(`Oh woops ${index} !-> ${consumedIndex}/${producedIndex}`)
            // Should never reach here if logic is correct
            throw new Error(`Unexpected state in get_index(${index}, producedIndex:${producedIndex}) for ${mu.id}`);
        },
        
        get done() {
            return isEnded;
        },
        
        get lastIndex() {
            return lastIndex;
        },
        
        close() {
            isEnded = true;
            ff.terminate();
            // Clear any pending requests
            for (const [index, { reject }] of waitingRequests.entries()) {
                reject(new Error('Stream closed by client'));
                waitingRequests.delete(index);
            }
            console.log(`FFmpeg stream for ${mu.id} closed by client`);
        }
    };
}




// FFmpeg stream implementation with pause/resume functionality
function ffmpegnate(mu:TheMusic, seektime = 0) {
    // Output format selection (ogg is default)
    const format = 'ogg'
    const audioCodec = format === 'ogg' ? 'libvorbis' : 'aac'
    
    // Create FFmpeg process with appropriate arguments for transcoding
    const ffmpeg = spawn('ffmpeg', [
        '-i', mu.path,
        ...(seektime > 0 ? ['-ss', seektime.toString()] : []),
        '-c:a', audioCodec,
        '-f', format,
        '-movflags', 'frag_keyframe+empty_moov',
        '-vn', // No video
        '-ar', '44100', // Sample rate
        '-ac', '2', // Stereo
        '-b:a', '128k', // Bitrate
        '-'  // Output to stdout
    ])
    
    // API
    let ff = {
        paused: false
    }
    let buffer = Buffer.alloc(0)
    // < do we drain the pipe?
    let streamEnded = false
    
    // Process buffer data and send chunks
    function processBuffer(forceDrain = false) {
        // Process full chunks
        while (buffer.length >= CHUNK_SIZE) {
            const dataToSend = buffer.subarray(0, CHUNK_SIZE)
            buffer = buffer.subarray(CHUNK_SIZE)
            
            ff.on_data(dataToSend)
        }
        
        // If force draining (on end) and we have remaining data, send it
        if (forceDrain && buffer.length > 0) {
            const remainingData = buffer
            buffer = Buffer.alloc(0)
            
            ff.on_data(remainingData)
        }
    }
    
    // Handle data from FFmpeg
    ffmpeg.stdout.on('data', (chunk) => {
        if (streamEnded) {
            console.error("dropped more data after streamEnded")
            return
        }
        buffer = Buffer.concat([buffer, chunk])
        processBuffer()
    })
    // Error handling
    ffmpeg.stdout.on('end', (data) => {
        console.log('FFmpeg stdout stream ended, draining buffer...')
        // Drain any remaining data from buffer
        processBuffer(true)
    })
    
    ffmpeg.on('error', (err) => {
        console.error('FFmpeg process error:', err)
        ff.on_error(err)
    })
    
    ffmpeg.on('close', (code) => {
        console.log(`FFmpeg process closed with code ${code}`)
        ff.on_end(code)
    })
    
    // Return control interface
    Object.assign(ff,{
        pause() {
            if (!ff.paused) {
                // Send SIGSTOP to pause the process (similar to Ctrl+Z)
                ffmpeg.kill('SIGSTOP')
                ff.paused = true
                console.log('FFmpeg stream paused')
            }
        },
        
        resume() {
            if (ff.paused) {
                // Send SIGCONT to resume the process (similar to 'fg')
                ffmpeg.kill('SIGCONT')
                ff.paused = false
                console.log('FFmpeg stream resumed')
            }
        },
        
        terminate() {
            ffmpeg.kill('SIGKILL')
            ff.termied = 1
            console.log('FFmpeg stream terminated')
        }
    })
    return ff
}

//#region ffprobe
// Extract metadata using ffprobe
async function ffprobe(mu) {
    return new Promise((resolve, reject) => {
        // Initialize default metadata if not exists
        mu.meta ||= {
            artist: '',
            album: '',
            title: '',
            year: '',
            duration: 0
        }
        
        // Extract duration and stream info
        const ffprobe = spawn('ffprobe', [
            '-v', 'quiet',
            '-print_format', 'json',
            '-show_format',
            '-show_streams',
            mu.path
        ])
        
        let outputData = ''
        
        ffprobe.stdout.on('data', (chunk) => {
            outputData += chunk.toString()
        })
        
        ffprobe.on('close', async (code) => {
            if (code !== 0) {
                console.error(`ffprobe process exited with code ${code}`)
                return resolve(mu) // Return mu even if we couldn't get metadata
            }
            
            try {
                const metadata = JSON.parse(outputData)
                
                // Extract duration
                if (metadata.format && metadata.format.duration) {
                    mu.meta.duration = parseFloat(metadata.format.duration)
                }
                
                // Extract tags from...
                const tags = metadata.format && metadata.format.tags
                    || metadata.streams[0].tags
                if (tags) {
                    mu.meta.artist = tags.artist || tags.ARTIST || tags.Artist || mu.meta.artist
                    mu.meta.album = tags.album || tags.ALBUM || tags.Album || mu.meta.album
                    mu.meta.title = tags.title || tags.TITLE || tags.Title || mu.meta.title
                    mu.meta.year = tags.date || tags.DATE || tags.year || tags.YEAR || mu.meta.year
                }
                
                // Find cover art in attachments or video streams
                if (metadata.streams) {
                    // Try to find a video stream that might be cover art
                    const coverStream = metadata.streams.find(stream => 
                        stream.codec_name === 'mjpeg' || 
                        (stream.codec_type === 'video' && 
                         stream.disposition && 
                         stream.disposition.attached_pic === 1)
                    )
                    
                    if (coverStream) {
                        // We found a cover stream, extract it with a separate call
                        try {
                            await extractCoverArt(mu)
                        } catch (err) {
                            console.warn('Failed to extract cover art:', err)
                        }
                    }
                }
                
                console.log(`ffprobed ${mu.id}: ${mu.meta.artist} - ${mu.meta.title}`)
                resolve(mu)
            } catch (err) {
                console.error('Error parsing ffprobe output:', err)
                resolve(mu) // Return mu even if we couldn't parse metadata
            }
        })
        
        ffprobe.on('error', (err) => {
            console.error('ffprobe process error:', err)
            resolve(mu) // Return mu even if ffprobe failed
        })
    })
}

// Extract cover art to mu.meta.cover
async function extractCoverArt(mu) {
    return new Promise((resolve, reject) => {
        // Use FFmpeg to extract cover art
        const ffmpeg = spawn('ffmpeg', [
            '-i', mu.path,
            '-an', // No audio
            '-vcodec', 'copy',
            '-f', 'image2pipe',
            '-'
        ])
        
        const chunks = []
        
        ffmpeg.stdout.on('data', (chunk) => {
            chunks.push(chunk)
        })
        
        ffmpeg.on('close', (code) => {
            if (code !== 0 && code !== 1) { // FFmpeg sometimes exits with code 1 but still works
                return reject(new Error(`FFmpeg exited with code ${code}`))
            }
            
            if (chunks.length > 0) {
                const coverBuffer = Buffer.concat(chunks)
                if (coverBuffer.byteLength) {
                    mu.meta.cover = new Uint8Array(coverBuffer)
                }
                resolve(mu)
            } else {
                reject(new Error('No cover art data extracted'))
            }
        })
        
        ffmpeg.on('error', reject)
        
        // Set a timeout to avoid hanging
        setTimeout(() => {
            ffmpeg.kill('SIGKILL')
            reject(new Error('Cover art extraction timeout'))
        }, 5000)
    })
}



