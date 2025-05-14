import { Server } from 'socket.io'
import { readFile, writeFile, access, mkdir, readdir, stat } from 'fs/promises';
import { join, dirname, basename, extname } from 'path';
import { constants } from 'fs';
import { createHash } from 'crypto';
import { constants } from 'fs';
import type { urihash } from './Gather.svelte';

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
        console.log("Alrighteo")
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
// stocking Music
// < on server start
// < wander around directory structure
//  < balance randomly presenting the population
//    without having a complete list
// < use a database of music, eg Strawberry's sqlite
async function scan_music(musicDir = '/music') {
    console.log(`Scanning music directory: ${musicDir}`);
    const scanned = new Map();
    
    // Recursive function to scan directories
    async function scanDir(dir+) {
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
                            
                            // Try to extract metadata (can be implemented later)
                            try {
                                // This would be where you'd extract ID3 tags or other metadata
                                // We'll implement a placeholder for now
                                await extractMetadata(musicEntry);
                            } catch (metaErr) {
                                console.warn(`Could not extract metadata for ${fullPath}:`, metaErr);
                            }
                            
                            scanned.set(fileHash, musicEntry);
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
            return scanned;
        }
    }
    
    // Start scanning from the root music directory
    await scanDir(musicDir);
    console.log(`Scan complete. Found ${scanned.size} tracks.`);
    
    return scanned;
}

// Placeholder function for metadata extraction
async function extractMetadata(musicEntry: TheMusic) {
    // This would be where you'd implement music metadata extraction
    // You could use libraries like 'music-metadata' or similar
    // For now, just use filename as title if nothing else is set
    if (!musicEntry.meta.title) {
        const baseName = basename(musicEntry.path);
        musicEntry.meta.title = baseName.substring(0, baseName.lastIndexOf('.'));
    }
}

// picking Music, for a client
function random_music() {
    let i = Math.floor(Math.random() * music.size)
    let mu = music[i]
    // < check for anything, repick
    // < take the next couple, in the same page read, save disk io?
    // < prefer what others are streaming, save disk io?
    return mu
}
// bytes of audio given out at once, audioi.index
const chunk_size = 60_000
function random_index(mu) {
    let min = mu.size * 0.2
    let max = mu.size * 0.7
    let seek = Math.random() * (max-min) + min
    let index = Math.floor(seek / chunk_size)
    return index
}

function AudioServer(socket, io) {
    socket.on('more', async (r: audioi, cb) => {
        carefully('more', cb, async () => {
            let specific = r.id && true
            let mu = r.id ? get_music(r.id) : random_music()
            if (!mu) {
                throw new Error(`!song: ${r.id}`);
            }
            let index = r.index ?? random_index(mu)
            let seek = index * chunk_size

            try {
                // Read the chunk of audio data
                const blob = await readFile(mu.path, { start: seek, end: seek + chunk_size - 1 });
                
                if (specific && socket.last_meta_id != mu.id) {
                    // they are continuing a stream
                    //  asyncily find and give out meta
                    send_meta(socket,mu)
                }
                mu.last_read = Date.now();
                
                socket.emit('more', {
                    id:mu.id,
                    index,
                    blob
                })
            } catch (error) {
                console.error(`Error reading audio file ${mu.id} at index ${index}:`, error);
                throw error; // Will be caught by carefully wrapper
            }
        })
    });
}

async function send_meta(socket,mu) {
    carefully('send_meta',()=>{},() => {
        if (!mu.meta) {
            // < ffprobe it
            mu.meta = {artist:"Mus"}
        }

        // let them know when the last chunk is
        let last_index = Math.floor(mu.size / chunk_size)

        socket.emit('more',{
            id: mu.id,
            meta: mu.meta,
            last_index
        })
        // the user has now been told
        socket.last_meta_id = mu.id
    })
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
    return callback({
        success: true,
    });
}


