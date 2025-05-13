import { Server } from 'socket.io'
import { readFile, writeFile, access, mkdir } from 'fs/promises';
import { join, dirname } from 'path';
import { constants } from 'fs';
import type { urihash } from './Gather.svelte';

export const webSocketServer = {
    name: 'webSocketServer',
    configureServer(server: ViteDevServer) {
        if (!server.httpServer) return

        const io = new Server(server.httpServer)

        io.on('connection', async (socket) => {
            console.log('Client connected:', socket.id);
            AudioServer(socket, io)
        });
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
function scan_music() {
    // < find opus|ogg in the filesystem at /music
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
        carefully('more', cb, () => {
            let mu = r.id ? get_music(r.id)
                          : random_music()
            let index = r.index ?? random_index(mu)
            let seek = index * chunk_size
            // < seek the chunk only for this chunk:
            let chunk = readFile(mu.path, {seek,length:chunk_size})
            

            socket.emit('more', { mu:mu.id, index }
        })
    });
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


