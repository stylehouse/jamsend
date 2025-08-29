import { SvelteMap } from "svelte/reactivity";
import { erring } from "$lib/Y";
import { tick } from "svelte";

import { PeerilyFeature, PierFeature } from "../Peerily.svelte";
// UI
import Shares from "./Shares.svelte";
import Sharee from "./Sharee.svelte";
import { DirectoryShares } from "./Directory.svelte";




// the PF
export class Sharing extends PeerilyFeature {
    shares: DirectoryShares
    constructor(opt) {
        super(opt)
        this.trust_name = 'ftp'
        this.UI_component = Shares
        this.shares = new DirectoryShares(this)

        this.start()
    }
    // be here and in a Pier's UI
    spawn_PF({Pier}) {
        return new PierSharing({P:this.P,Pier,F:this})
    }

    // < who|where|when hits start? the UI?
    async start() {
        try {
            await this.shares.start()

            console.log(`File sharing started with ${this.shares.getShares().length} shares`)
        } catch (err) {
            throw erring("Failed to start file sharing", err);
        }
    }

}

type percentage = number
// the F (per Pier)
export class PierSharing extends PierFeature {
    constructor(opt) {
        super(opt)
        this.UI_component = Sharee
        console.warn("Got PierSharing!")
        this.emit("whatsup",{from:this.Pier.eer.Id+''})
    }

    tm:TransferManager
    
    // < figure out how to do navigation and population
    // listings here + there
    remoteList: DirectoryListing | null = $state()

    // < depend on F.perm
    async consented_acts() {
        await this.refresh_localList()
        await this.refresh_remoteList()
    }
    // then, maybe via ui,
    async start() {
        try {
            // < resume against what we had? another Thing to store?
            this.tm = new TransferManager({sharing:this})

            console.log(`PierSharing:`, this.localList);
        } catch (err) {
            throw erring("Failed to start file sharing", err);
        }
    }
    async stop() {
        try {
            // Cancel any active transfers
            await this.tm.stop()

            // Clear file system state
            this.localList = null
            this.remoteList = null

            // Close any open file handles
            if (this.fsHandler) {
                await this.fsHandler.stop();
            }

            console.log("File sharing stopped");
        } catch (err) {
            throw erring("Error during file sharing cleanup", err);
        }
    }


//#region sendFile
    // Send a file from the filesystem
    async sendFile(
        filename: string,
        shareName: string = 'music', // default share
        onProgress?: (progress: percentage) => void,
        seek = 0,
        fileId?
    ): Promise<void> {
        // for file-pull, they may already have a transfer object
        const share = this.F.shares.getShare(shareName)
        if (!share) {
            throw erring(`Share "${shareName}" not found`)
        }
        
        fileId ||= crypto.randomUUID();
        const reader = await share.getFileReader(filename)
        const transfer = this.tm.initTransfer('upload', fileId, filename, reader.size);
    
        // Send file metadata
        let meta = {
            fileId,
            name: filename,
            size: reader.size,
            share: shareName // include share context
        }
        if (seek) {
            meta.seek = seek
        }
        await this.emit('file_meta', meta);

        // Read and send chunks
        try {
            for await (const chunk of reader.iterate(seek)) {
                await this.emit('file_chunk',{
                    fileId,
                    buffer: chunk
                },{priority: 'low'});

                transfer.updateProgress(chunk.byteLength);
                onProgress?.(transfer.progress);
            }

            // Send completion message
            await this.emit('file_complete',{
                fileId,
            })
            transfer.status = 'completed';
        } catch (err) {
            // < also following a lapse, esp if par.offline
            await transfer.error('sending: ' + err.message);
        }
    }
    async pull(name) {
        await this.emit('file_pull', {name})
    }

    // List available files
    // memoized here:
    localList_string?:string
    async refresh_localList(): Promise<string[]> {
        this.localList = await this.fsHandler.listDirectory();

        let was = this.localList_string
        this.localList_string = JSON.stringify(
            this.localList?.transportable()
        )
        if (was !== this.localList_string) {
            // Notify remote peer of changes
            this.send_file_list()
        }
    }
    async refresh_remoteList() {
        await this.emit('file_list_request')
    }
    async send_file_list() {
        try {
            // < could be moving around
            let listing = this.localList?.transportable()
            listing && await this.emit('file_list_response', {listing})
        } catch (err) {
            throw erring('sending file lists', err)
        }
    }
    // Watch for local file system changes
    async watchLocalChanges() {
        // Periodically check for changes
        this.watchLocal_interval = setInterval(async () => {
            try {
                this.refresh_localList()
            } catch (err) {
                throw erring('watchLocalChanges()', err)
            }
        }, 5000) // Check every 5 seconds
    }
//#region unemits
    unemits = {
        whatsup: (data,{P,Pier}) => {
            console.log("Landed in yondo: ",data)
        },

        // remote peer requesting our file list
        file_list_request: async () => {
            await this.send_file_list()
        },
        // receiving remote peer's file list
        // < data.directory:string[]
        file_list_response: async (data) => {
            this.remoteList = DirectoryListing.fromJSON(data.listing)
        },



        // Starts a new download
        // our PUT is just a file_meta someone receives
        file_meta: async (data) => {
            console.log("file meta: ",data)
            const transfer = this.tm.initTransfer(
                'download',
                data.fileId, 
                data.name, 
                data.size
            );
            transfer.moved = data.seek || 0
            
            try {
                const writable = await this.fsHandler.writeFileChunks(data.name);
                transfer.writable = writable;
                transfer.status = 'active';
            } catch (err) {
                transfer.status = 'error';
                throw erring('starting file transfer', err);
            }
        },
        // ...downloads
        file_chunk: async (data) => {
            console.log("file chunk: ",data)
            const transfer = this.tm.transfers.get(data.fileId);
            if (!transfer || transfer.status !== 'active') {
                console.warn(`Invalid transfer state for chunk: ${data.fileId}`);
                return;
            }

            try {
                await transfer.writable.write(new Uint8Array(data.buffer));
                transfer.updateProgress(data.buffer.byteLength);
            } catch (err) {
                transfer.status = 'error';
                throw erring('Error writing chunk', err);
            }
        },
        // ...complete
        file_complete: async (data) => {
            console.log("file complete: ",data)
            const transfer = this.tm.transfers.get(data.fileId);
            if (!transfer) return;

            try {
                await transfer.writable.close();
                transfer.status = 'completed';
                this.tm.transfers.delete(data.fileId); // Clean up completed transfer
            } catch (err) {
                transfer.status = 'error';
                throw erring('Error completing transfer', err);
            }
        },
        // or do they
        file_error: async (data) => {
            const transfer = this.tm.transfers.get(data.fileId);
            if (!transfer) return;
            await transfer.error(data.error, false); // Don't notify back
        },
        // remote nabs
        file_pull: async (data) => {
            await this.sendFile(data.name, undefined, data.seek, data.fileId);
        },
    }
}



//#region Transfer

// need individuating
type TransferType = 'upload' | 'download';
type TransferStatus = 'pending' | 'active' | 'paused' | 'completed' | 'error'
    | 'restarting'; // briefly before gone, replaced

class Transfer {
    // State
    moved: number = $state(0)    // Actual bytes transferred
    progress: number = $state(0)  // Percentage (0-100)
    status: TransferStatus = $state()
    errorMessage: string = $state('')

    // Metadata
    id: string
    type: TransferType
    filename: string
    size: number
    created_ts: Date = new Date();
    activity_ts: Date = new Date();
    
    // Services
    tm:TransferManager
    sharing:PierSharing
    writable?: FileSystemWritableFileStream  // for downloads
    
    constructor(opt: Partial<Transfer>) {
        Object.assign(this,opt)
    }

    updateProgress(chunkBytes: number) {
        this.on_activity()
        this.moved += chunkBytes;
        this.progress = Math.round((this.moved / this.size) * 100);
    }
    on_activity() {
        this.activity_ts = new Date();
    }
    async error(msg: string, notify = true) {
        this.status = 'error';
        this.errorMessage = msg;
        if (notify) {
            await this.sharing.emit('file_error', {
                fileId: this.id,
                error: msg
            });
        }
    }

    // < ui these, they are not called yet
    // restart somehow
    // < if we still have it?
    // < put in .incoming/
    async resume() {
        this.error = '';
        this.status = 'pending';
        // continuation from last byte
        await this.reinitiate({fileId:this.id,seek:this.moved})
    }
    // send some kind of message to restart somehow
    async reinitiate(opt={}) {
        opt.filename = this.filename
        if (this.type === 'download') {
            await this.sharing.send('file-pull', {
                filename: this.filename,
                fileId: this.id,
                seek: this.moved
            });
        } else {
            // the downloader would resume, usually
            //  but it helps to have communal ui that anyone (ish) can facilitate
            //   asking people for remote procedural clicking is naff
            await this.sharing.sendFile(this.filename, undefined, 0, this.id);
        }
    }
    async restart() {
        this.error = '';
        this.status = 'restarting';
        await this.stop()
        this.tm.remove(this)
        await this.reinitiate()
    }

    async stop() {
        if (this.writable) {
            try {
                await this.writable.close();
            } catch (err) {
                throw erring('Error closing writable', err);
            }
            this.writable = undefined;
        }
    }
}

class TransferManager {
    // parent
    sharing:PierSharing
    
    constructor(opt: { sharing: PierSharing }) {
        Object.assign(this,opt)
    }
    transfers = $state(new SvelteMap<string, Transfer>());
    
    initTransfer(
        type: TransferType,
        id: string, 
        filename: string, 
        size: number
    ): Transfer {
        // they may have supplied an id that we already have, or the one they want
        let transfer = this.transfers.get(id);
        if (transfer) {
            // Transfer.resume() sanity
            if (transfer.type != type) throw "~type"
            if (transfer.filename != filename) throw "~filename"
            if (transfer.size != size) throw "~size"
        }
        else {
            transfer = new Transfer({
                type,
                id,
                filename,
                size,
                progress: 0,
                status: 'pending',
                tm: this,
                sharing: this.sharing
            });
            this.transfers.set(id, transfer);
        }

        transfer.on_activity()
        transfer.status = 'pending';

        return transfer;
    }
    remove(transfer) {
        this.transfers.delete(transfer.id)
    }
    async stop() {
        for (const transfer of this.transfers.values()) {
            await transfer.stop();
        }
        this.transfers.clear();
    }
}

















//#region ->Peering

// eg, whole, not streaming chunks:
//   // Read and write files in the directory
//   async function workWithFiles(dirHandle) {
//     // Create/write a file
//     const newFileHandle = await dirHandle.getFileHandle('recording.wav', { create: true });
//     const writable = await newFileHandle.createWritable();
//     await writable.write(audioData);
//     await writable.close();
  
//     // Read a file
//     const fileHandle = await dirHandle.getFileHandle('recording.wav');
//     const file = await fileHandle.getFile();
//     const contents = await file.arrayBuffer();
//   }












//#region *Listing
export class FileListing {
    name: string;
    size: number;
    modified: Date;
    
    constructor(init: Partial<FileListing>) {
        this.name = init.name;
        this.size = init.size;
        this.modified = init.modified instanceof Date ? init.modified : new Date(init.modified);
    }

    // Format size in human readable format (KB, MB, etc)
    get formattedSize(): string {
        const units = ['B', 'KB', 'MB', 'GB'];
        let size = this.size;
        let unitIndex = 0;
        
        while (size >= 1024 && unitIndex < units.length - 1) {
            size /= 1024;
            unitIndex++;
        }
        
        return `${size.toFixed(1)} ${units[unitIndex]}`;
    }

    // Format date in a readable way
    get formattedDate(): string {
        return this.modified.toLocaleString();
    }

    toJSON() {
        return {
            name: this.name,
            size: this.size,
            modified: this.modified.toISOString()
        };
    }
}
// many of the above
export class DirectoryListing {
    name: string;
    up?: DirectoryListing;
    files: FileListing[] = $state([])
    directories: DirectoryListing[] = $state([])
    
    constructor(init: Partial<DirectoryListing> = {}) {
        Object.assign(this,init)
    }
    // for sending only one directory-full at a time
    //  ie return a Partial<DirectoryListing> without any 2-inners
    //   ie dir/dir/dir or dir/dir/file
    //  reduce dir/dir to their name
    // < paginate?
    transportable() {
        return {
            name: this.name,
            files: this.files,
            directories: this.directories.map(dir => {
                // before toJSON gets called on them, and so on, snip
                return {name: dir.name}
            })
        }
    }
    // might be huge if your have resolved a lot of inners
    toJSON() {
        return {
            name: this.name,
            files: this.files,
            directories: this.directories
        };
    }
    static fromJSON(json: any): DirectoryListing {
        // it'll have no name until stitched into the landscape
        const listing = new DirectoryListing(json);
        listing.files = listing.files.map(f => new FileListing(f))
        listing.directories = listing.directories.map(d => new DirectoryListing(d))
        listing.directories.map(d => d.up = listing)
        return listing;
    }
}
// many of the above
export class CollectionListing {
}













