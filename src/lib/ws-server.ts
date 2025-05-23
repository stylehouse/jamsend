import { Server } from 'socket.io'
import { readFile, writeFile, access, mkdir, readdir, stat } from 'fs/promises';
import { join, dirname, basename, extname } from 'path';
import { constants } from 'fs';
import { createHash } from 'crypto';
import type { ViteDevServer } from 'vite';
import type { urihash } from './Gather.svelte';
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

// Promise helper for async/await usage
class DeferredPromise {
    promise
    resolve
    reject
    constructor() {
        this.promise = new Promise((resolve, reject) => {
            this.resolve = resolve
            this.reject = reject
        })
    }
    then(fn) {
        return this.promise.then(fn)
    }
    catch(fn) {
        return this.promise.catch(fn)
    }
}
// error-sending wrapper
function carefully(label: string, callback: Function, doing: Function) {
    try {
        doing()
    } catch (error) {
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
function random_music(): TheMusic | undefined {
    if (Music.size === 0) {
        console.log("No music tracks available.");
        return undefined;
    }
    // < a Music object with hash and sequence indexes
    // generate an array
    const musicArray = Array.from(Music.values());
    const randomIndex = Math.floor(Math.random() * musicArray.length);
    const mu = musicArray[randomIndex];
    return mu
}
function get_music(id): TheMusic | undefined {
    return Music.get(id)
}
// bytes of audio given out at once, audioi.index
const CHUNK_SIZE = 60_000
function random_index(mu) {
    let seek = random_seek_fraction() * mu.size
    let index = Math.floor(seek / CHUNK_SIZE)
    return index
}
function random_seek_fraction() {
    let min = 0.2
    let max = 0.7
    return Math.random() * (max-min) + min
}

// < ffmpeg jobs spawn on mu.feed
//    pauses and resumes to pipe us just enough 100k ogg to serve /more indexes
//    if spawning a new mu.feed && index is random, we should seek into it
//     so the stream starts with an ogg header
function AudioServer(socket, io) {
    socket.on('more', async (r: audioi, cb) => {
        carefully('more', cb, async () => {
            r ||= {}
            console.log("ws AudioServer more: ",r)
            
            let specific = r.id && true
            let mu = r.id ? get_music(r.id) : random_music()
            if (!mu) {
                throw new Error(`!song: ${r.id}`);
            }
            // create an encoder
            if (!mu.feed) {
                if (r.index) throw "following (with index) an unstarted mu"
                let fraction = r.index == 0 ? 0 : random_seek_fraction()
                mu.feed = await createFFmpegStream(mu,fraction);
            }
            // read from the encoder
            //  starting at 0 even when we randomly seek
            r.index ||= 0
            let res = {id: mu.id}
            res.blob = await mu.feed.get_index(r.index)
            res.index = r.index

            if (mu.feed.done) res.done = 1
            if (socket.last_meta_id != mu.id) {
                // the user has now been told
                res.meta = mu.meta
                socket.last_meta_id = mu.id
            }
            
            socket.emit('more', res)
        })
    });
}
async function createFFmpegStream(mu,fraction=0) {
    // get mu.meta.duration, etc
    ffprobe(mu)
    // use it to jump in somewhere
    let seektime = Math.floor(mu.meta.duration * fraction)
    let ff = ffmpegnate(mu)
    
    // per index, the encoded stream read from ffmpeg
    const blobs = []
    let blobs_cursor = 0
    let isEnded = false
    let waiting = null
    
    // Set up data handler
    ff.on_data((data) => {
        blobs.push(data)
        
        // Resolve waiting promise if any
        if (waiting) {
            waiting()
            waiting = null
        }
        
        // Pause stream if we've buffered enough chunks
        if (blobs.length > blobs_cursor + 3) {
            ff.pause()
        }
    })
    
    // Handle end of stream
    ff.on_end(() => {
        isEnded = true
        if (waiting) {
            waiting()
            waiting = null
        }
    })

    // Return feed interface
    return {
        async get_index(index) {
            // If requested chunk doesn't exist yet
            if (!blobs[index]) {
                // Already at end of stream
                if (isEnded) {
                    throw new Error("End of stream reached")
                }
                
                // Resume stream and wait for data
                ff.resume()
                
                // Create a promise that will resolve when data arrives
                const stall = new DeferredPromise()
                waiting = () => stall.resolve()
                
                // Wait for data or end of stream
                await stall
            }
            
            // Return requested chunk if available
            const blob = blobs[index]
            if (!blob) {
                if (isEnded) {
                    throw new Error("End of stream reached")
                }
                throw new Error("Still no data available")
            }
            
            // Remove chunk from storage to free memory
            delete blobs[index]
            blobs_cursor = index
            
            return blob
        },
        
        get done() {
            return isEnded
        },
        
        close() {
            ff.terminate()
        }
    }
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
    
    // Stream control state
    let paused = false
    let dataHandler = null
    let errorHandler = null
    let endHandler = null
    let buffer = Buffer.alloc(0)
    
    // Handle data from FFmpeg
    ffmpeg.stdout.on('data', (chunk) => {
        buffer = Buffer.concat([buffer, chunk])
        
        // If we have collected enough data, process it
        if (buffer.length >= CHUNK_SIZE) {
            const dataToSend = buffer.slice(0, CHUNK_SIZE)
            buffer = buffer.slice(CHUNK_SIZE)
            
            // Send to registered handler
            if (dataHandler) {
                dataHandler(dataToSend)
            }
        }
    })
    
    // Error handling
    ffmpeg.stderr.on('data', (data) => {
        console.log(`FFmpeg log: ${data.toString()}`)
    })
    
    ffmpeg.on('error', (err) => {
        console.error('FFmpeg process error:', err)
        if (errorHandler) {
            errorHandler(err)
        }
    })
    
    ffmpeg.on('close', (code) => {
        console.log(`FFmpeg process closed with code ${code}`)
        if (endHandler) {
            endHandler(code)
        }
    })
    
    // Return control interface
    return {
        pause() {
            if (!paused) {
                // Send SIGSTOP to pause the process (similar to Ctrl+Z)
                ffmpeg.kill('SIGSTOP')
                paused = true
                console.log('FFmpeg stream paused')
            }
        },
        
        resume() {
            if (paused) {
                // Send SIGCONT to resume the process (similar to 'fg')
                ffmpeg.kill('SIGCONT')
                paused = false
                console.log('FFmpeg stream resumed')
            }
        },
        
        on_data(handler) {
            dataHandler = handler
            
            // If we already have data in buffer, process it
            if (buffer.length >= CHUNK_SIZE) {
                const dataToSend = buffer.slice(0, CHUNK_SIZE)
                buffer = buffer.slice(CHUNK_SIZE)
                handler(dataToSend)
            }
        },
        
        on_error(handler) {
            errorHandler = handler
        },
        
        on_end(handler) {
            endHandler = handler
        },
        
        terminate() {
            ffmpeg.kill('SIGKILL')
            console.log('FFmpeg stream terminated')
        }
    }
}

// Extract metadata using ffprobe
async function ffprobe(mu) {
    return new Promise((resolve, reject) => {
        // Initialize default metadata if not exists
        mu.meta ||= {
            artist: '',
            album: '',
            title: '',
            year: '',
            cover: new Uint8Array(),
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
        
        ffprobe.on('close', (code) => {
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
                
                // Extract tags from format section
                if (metadata.format && metadata.format.tags) {
                    const tags = metadata.format.tags
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
                        extractCoverArt(mu).catch(err => {
                            console.warn('Failed to extract cover art:', err)
                        })
                    }
                }
                
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
                mu.meta.cover = new Uint8Array(coverBuffer)
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



