import { Server, Socket } from 'socket.io'
import { readFile, writeFile, access, mkdir, readdir, stat } from 'fs/promises';
import { join, dirname, basename, extname } from 'path';
import { constants } from 'fs';
import { createHash } from 'crypto';
import type { ViteDevServer } from 'vite';
import { V,urihash,timestamp,songmeta,TheMusic } from '../audio/Common.svelte';
import { promisify } from 'util'
import { createFFmpegStream } from './FFmpeg';

export const webSocketServer = {
    name: 'webSocketServer',
    configureServer(server: ViteDevServer) {
        if (!server.httpServer) return
        const io = new Server(server.httpServer)
        init_an_io(io)
    }
}

export function init_an_io(io) {
    io.on('connection', async (socket) => {
        console.log('Client connected:', socket.id);
        // apply these handlers to each client object
        // < bad memory management for a busy server?
        AudioServer(socket, io)
    });

    scan_music()
}

// error-sending wrapper
export async function carefully(label: string, callback: Function, socket:Socket, doing: Function) {
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


let Music:Map<urihash,TheMusic> = new Map()
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
                            V>0 && console.log(`Added track: ${musicEntry.meta.title}`);
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
const MAX_RECENT = 100
function random_music(user): TheMusic | undefined {
    user.recentlyServed ||= new Set()
    if (Music.size === 0) {
        console.log("No music tracks available.");
        return undefined;
    }

    // < a Music object with hash and sequence indexes
    // generate an array
    const available = Array.from(Music.values())
        .filter(mu => !user.recentlyServed.has(mu.id));
    
    const randomIndex = Math.floor(Math.random() * available.length);
    const mu = available[randomIndex];

    if (!mu) {
        // what if it runs out
        user.recentlyServed = new Set()
        return random_music(user)
    }

    // Track this as recently served
    user.recentlyServed.add(mu.id);
    if (user.recentlyServed.size > MAX_RECENT) {
        // Remove oldest (though Set doesn't guarantee order, this is simple)
        const first = user.recentlyServed.values().next().value;
        user.recentlyServed.delete(first);
    }

    return mu
}
function get_music(id): TheMusic | undefined {
    return Music.get(id)
}
function random_seek_fraction() {
    let min = 0.2
    let max = 0.7
    return Math.random() * (max-min) + min
}

let users = {}
// -> mu <-> feed
//    pauses and resumes to pipe us just enough 100k ogg to serve /more indexes
//    if spawning a new mu.feed && index is random, we should seek into it
//     so the stream starts with an ogg header
function AudioServer(socket, io) {
    // track users by socket.id
    let user = users[socket.id] ||= {}
    // which they can reclaim after socket reconnects, with the same Gat state
    socket.on('try_recycle_gatid', async ({id}, cb) => {
        carefully('try_recycle_gatid', cb, socket, async () => {
            let was = users[id]
            if (was) {
                for (const [id, feed] of Object.entries(was.feeds)) {
                    user.feeds[id] = feed
                }
                socket.emit('try_recycle_gatid_success')
            }
            else {
                socket.emit('try_recycle_gatid_failed')
            }
        })
    })
    
    // Track FFmpeg feeds per socket
    user.feeds = {} // mu.id -> feed
    // per socket|user
    let has_meta = {} // mu.id -> true
    socket.on('more', async (r: audioi, cb) => {
        carefully('more', cb, socket, async () => {
            r ||= {}
            V>0 && console.log("/more: ",r)
            
            let specific = r.id && true
            let from_start = r.from_start
            let mu = r.id ? get_music(r.id) : random_music(user)
            if (!mu) {
                throw new Error(`!song: ${r.id}`);
            }
            // create an encoder
            let feed = user.feeds[mu.id];
            if (!feed) {
                if (r.index) {
                    // can occur before recycling hands over the feeds
                    console.warn("more of old feed before recycle?")
                    socket.emit('more', {id:r.id,try_again:r})
                    return
                }
                let fraction = from_start ? 0 : random_seek_fraction()
                feed = await createFFmpegStream(mu, fraction);
                user.feeds[mu.id] = feed;
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
                V>0 && console.log(` - is from start`)
                res.from_start = 1
            }
            
            socket.emit('more', res)
        })
    });

    // Handle no_more requests from client
    socket.on('no_more', async (data, cb) => {
        carefully('no_more', cb, socket, async () => {
            console.log(`/no_more ${socket.id}'s`)
            V>0 && console.log(`/no_more ${socket.id}'s`, data)
            const { track_ids: ids } = data
            if (!ids?.length) return
            
            V>0 && console.log(`culling ${socket.id}'s`, ids)
            
            let cleaned_count = 0
            for (const id of ids) {
                const feed = user.feeds[id]
                if (feed) {
                    try {
                        // Close the FFmpeg stream
                        await feed.close()
                        delete user.feeds[id]
                        cleaned_count++
                        V>1 && console.log(`Cleaned up feed for track ${id}`)
                    } catch (error) {
                        console.error(`Error closing feed for track ${id}:`, error)
                    }
                }
                delete has_meta[id]
            }
            
            V>0 && console.log(`Cleaned up ${cleaned_count} feeds for client ${socket.id}`)
        })
    })

    // drop user a while after disconnect
    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
        // after 2m
        setTimeout(() => {
            // Clean up any FFmpeg streams for this client
            for (const [id, feed] of Object.entries(user.feeds)) {
                feed.close();
            }
            delete users[socket.id]
            has_meta = {}
        }, 2*60*1000)

    });
}



