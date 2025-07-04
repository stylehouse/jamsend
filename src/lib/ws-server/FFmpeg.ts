import type { TheMusic } from "$lib/audio/Common.svelte";
import { V } from '../audio/Common.svelte';
import { spawn } from 'child_process'

// bytes of audio given out per audioi.index
const CHUNK_SIZE = 60_000

export async function createFFmpegStream(mu:TheMusic, fraction = 0) {
    // Get metadata including duration
    await ffprobe(mu);
    
    // Calculate seek time based on duration and fraction
    const seektime = mu.meta.duration ? Math.floor(mu.meta.duration * fraction) : 0;

    await ffloudness(mu,seektime);
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
    V>0 && console.log(`FFmpeg++ ${mu.id}`);
    
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
            V>0 && console.log(`FFmpeg+= ${mu.id} ${consumedIndex}/${producedIndex}, pausing`);
        }
        else {
            V>0 && console.log(`FFmpeg+= ${mu.id} ${consumedIndex}/${producedIndex}`);
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
                V>0 && console.log(`/more served ${mu.id}: ${index}`);
                return blob;
            }
            
            // If stream has ended and we're requesting beyond available chunks
            if (lastIndex != null && index > lastIndex) {
                V>0 && console.log(`/more request for ${mu.id}: ${index} (stream ended)`);
                throw new Error("End of stream reached");
            }
            
            // If requested future chunk that hasn't been generated yet

            if (index >= producedIndex) {
                let resu = ff.paused ? "(resuming)" : ""
                V>0 && console.log(`/more waiting for ${mu.id}: ${index} ${resu}`);
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
            
            console.log(`Oh no, ${index} !-> ${consumedIndex}/${producedIndex}`)
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
        ...(seektime > 0 ? ['-ss', seektime.toString()] : []),
        '-i', mu.path,
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

//#region ffloudness
// Extract loudness information using FFmpeg's loudnorm filter
async function ffloudness(mu: TheMusic, seektime = 0) {
    return new Promise((resolve, reject) => {
        // Use FFmpeg with loudnorm filter in analysis mode
        const ffmpeg = spawn('ffmpeg', [
            ...(seektime > 0 ? ['-ss', seektime.toString()] : []),
            '-i', mu.path,
            '-t', 20, // only ten seconds
            '-af', 'loudnorm=print_format=json',
            '-f', 'null',
            '-'
        ])
        
        let outputData = ''
        let errorData = ''
        
        // FFmpeg outputs loudnorm results to stderr
        ffmpeg.stderr.on('data', (chunk) => {
            errorData += chunk.toString()
        })
        
        ffmpeg.stdout.on('data', (chunk) => {
            outputData += chunk.toString()
        })
        
        ffmpeg.on('close', (code) => {
            if (code !== 0) {
                console.error(`ffloudness process exited with code ${code}`)
                console.error('Error output:', errorData)
                return resolve(mu) // Return mu even if we couldn't get loudness data
            }
            
            try {
                // Extract JSON from stderr output
                const jsonMatch = errorData.match(/\{[\s\S]*?\}/);
                if (!jsonMatch) {
                    console.warn('No loudness JSON found in FFmpeg output')
                    return resolve(mu)
                }
                
                const loudnessData = JSON.parse(jsonMatch[0])
                
                // Map FFmpeg loudnorm output to our metadata structure
                mu.meta.loudness = {
                    integrated: parseFloat(loudnessData.input_i) || 0,
                    truePeak: parseFloat(loudnessData.input_tp) || 0,
                    lra: parseFloat(loudnessData.input_lra) || 0,
                    threshold: parseFloat(loudnessData.input_thresh) || 0,
                    targetOffset: parseFloat(loudnessData.target_offset) || 0
                }
                console.log(`ffloudness ${mu.id}: ${mu.meta.loudness.integrated} LUFS, ${mu.meta.loudness.truePeak} dBTP`)
                // only want
                mu.meta.loudness = mu.meta.loudness.integrated
                
                resolve(mu)
            } catch (err) {
                console.error('Error parsing loudness output:', err)
                console.error('Raw stderr:', errorData)
                resolve(mu) // Return mu even if we couldn't parse loudness data
            }
        })
        
        ffmpeg.on('error', (err) => {
            console.error('ffloudness process error:', err)
            resolve(mu) // Return mu even if FFmpeg failed
        })
        
        // Set a timeout to avoid hanging (loudness analysis can take time)
        setTimeout(() => {
            ffmpeg.kill('SIGKILL')
            console.warn(`ffloudness timeout for ${mu.id}`)
            resolve(mu)
        }, 30000) // 30 second timeout
    })
}