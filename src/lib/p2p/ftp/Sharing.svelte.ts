import { SvelteMap } from "svelte/reactivity";
import { erring } from "$lib/Y";
import { tick } from "svelte";

import { PeerilyFeature, PierFeature } from "../Peerily.svelte";
// UI
import Shares from "./Shares.svelte";
import Sharee from "./Sharee.svelte";


// the F
export class Sharing extends PeerilyFeature {
    constructor(opt) {
        super(opt)
        this.trust_name = 'ftp'
        this.UI_component = Shares
    }
    spawn_PF({Pier}) {
        return new PierSharing({P:this.P,Pier,PF:this})
    }

}

type percentage = number
// the PF (per Pier)
export class PierSharing extends PierFeature {
    constructor(opt) {
        super(opt)
        this.UI_component = Sharee
        console.warn("Got PierSharing!")
        this.emit("whatsup",{from:this.Pier.eer.Id+''})
    }

    // be here... and in a UI...
    tm:TransferManager
    private fsHandler:FileSystemHandler
    // compat
    local_directory_compat?:Function
    
    // < figure out how to do navigation and population
    // listings here + there
    localList: DirectoryListing | null = $state()
    remoteList: DirectoryListing | null = $state()

    started = $state(false);

    // < depend on F.perm
    async consented_acts() {
        await this.refresh_localList()
        await this.refresh_remoteList()
    }
    // then, maybe via ui,
    async start() {
        try {
            this.tm = new TransferManager({sharing:this})
            this.fsHandler = new FileSystemHandler({sharing:this});
            // consent by the user
            await this.fsHandler.start()
            
            // < racey. Pier.unemit() should wait up to 3s for new handlers to arrive
            // this.setupSharingHandlers(this.par)
            
            // < in compat mode the picker isn't ready yet.
            await this.refresh_localList()

            this.started = true;
            console.log(`File sharing started with files:`, this.localList);
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
            this.started = false;

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
        onProgress?: (progress: percentage) => void,
        seek = 0,
        fileId?
    ): Promise<void> {
        // for file-pull, they may already have a transfer object
        fileId ||= crypto.randomUUID();
        const reader = await this.fsHandler.getFileReader(filename);
        const transfer = this.tm.initTransfer('upload', fileId, filename, reader.size);
    
        // Send file metadata
        let meta = {
            fileId,
            name: filename,
            size: reader.size
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
        // fyi, our PUT is just a file-meta someone receives
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








//#region fs

interface FileReader {
    size: number;
    iterate: (startFrom?: number) => AsyncGenerator<ArrayBuffer>;
}

const CHUNK_SIZE = 16 * 1024;          // 16KB chunks for file transfer

type FileSystemDirectoryHandle = any
class FileSystemHandler {
    private _fs: FileSystemState = {
        dirHandle: FileSystemDirectoryHandle | null,
        fileHandles: Map<string, FileSystemFileHandle>,
    }
    // < this one probably does belong to Sharing...
    //    might want to trust.etc different shares
    private sharing:PierSharing
    private compat_mode:Boolean
    constructor({sharing}) {
        this.sharing = sharing
        this._fs = {
            dirHandle: null,
            fileHandles: new Map()
        };
    }
    async start() {
        await this.requestDirectoryAccess()
    }
    async stop() {
        // Clear all stored handles
        this._fs.fileHandles.clear();
        this._fs.dirHandle = null;
    }

    
    // Request directory access from user
    // < permanent shares
    private isFileSystemAccessSupported(): boolean {
        return 'showDirectoryPicker' in window;
    }
    async requestDirectoryAccess(): Promise<FileSystemDirectoryHandle> {
        try {
            if (!this.isFileSystemAccessSupported()) {
                this.compat_VirtualDirectoryHandle()
                return
            }
            // Modern browsers that support File System Access API
            this._fs.dirHandle = await window.showDirectoryPicker({
                mode: 'readwrite'
            })
        } catch (err) {
            throw erring('Error accessing directory', err);
        }
    }


    // go somewhere
    async getFileHandle(filename: string): Promise<FileSystemFileHandle> {
        if (!this._fs.dirHandle) throw erring('No directory access')
        const handle = await this._fs.dirHandle.getFileHandle(filename);
        this._fs.fileHandles.set(filename, handle);
        return handle;
    }


    // List all files in the directory
    async listDirectory(): Promise<DirectoryListing> {
        if (!this._fs.dirHandle) {
            if (this.compat_mode) {
                // localList unavailable for longer than usual
                return
            }
            throw erring('No directory access')
        }
        
        const listing = new DirectoryListing()
        // < tabulation?
        for await (const entry of this._fs.dirHandle.values()) {
            try {
                if (entry.kind === 'file') {
                    const file = await entry.getFile();
                    listing.files.push(new FileListing({
                        name: entry.name,
                        size: file.size,
                        modified: new Date(file.lastModified)
                    }));
                } else {
                    listing.directories.push(new DirectoryListing({
                        name: entry.name
                    }));
                }
            } catch (err) {
                console.warn(`Skipping problematic entry ${entry.name}:`, err);
            }
        }

        return listing;
    }

    // First get file info and iterator factory
    async getFileReader(filename: string, chunkSize = CHUNK_SIZE): Promise<FileReader> {
        if (!this._fs.dirHandle) throw erring('No directory access')

        const fileHandle = await this._fs.dirHandle.getFileHandle(filename);
        const file = await fileHandle.getFile();
        
        return {
            size: file.size,
            iterate: async function*(startFrom = 0) {
                let offset = startFrom;
                while (offset < file.size) {
                    // Read file in chunks
                    const chunk = file.slice(offset, offset + chunkSize);
                    yield await chunk.arrayBuffer();
                    offset += chunkSize;
                }
            }
        };
    }

    // Write file in chunks
    async writeFileChunks(filename: string): Promise<FileSystemWritableFileStream> {
        if (!this._fs.dirHandle) throw erring('No directory access')

        const fileHandle = await this._fs.dirHandle.getFileHandle(filename, { create: true });
        const writable = await fileHandle.createWritable();
        this._fs.fileHandles.set(filename, fileHandle);
        return writable;
    }






//#region fs-compat
    // this'll all go
    
    private compat_VirtualDirectoryHandle() {
        this.compat_mode = true
        // Fallback for browsers without File System Access API support
        this.sharing.local_directory_compat = (input) => {
            return new Promise((resolve, reject) => {
                input.onchange = async (event) => {
                    const files = Array.from(input.files || []);
                    if (files.length > 0) {
                        // Create a virtual directory handle
                        this._fs.dirHandle = this.createVirtualDirectoryHandle(files);
                        resolve(this._fs.dirHandle);
                        // and read from it
                        this.sharing.refresh_localList()
                    } else {
                        reject(new Error('No directory selected'));
                    }
                };
                // Trigger the file picker? too late now,
                // < perhaps the UI should precede sharing.start()?
                // input.click();
            })
        }
    }
    // compat - older browsers can throw a whole folder at us
    private createVirtualDirectoryHandle(files: File[]) {
        return {
            kind: 'directory',
            *values() {
                for (const file of files) {
                    yield {
                        kind: 'file',
                        name: file.name,
                        getFile: async () => file
                    };
                }
            },
            async getFileHandle(name: string) {
                const file = files.find(f => f.name === name);
                if (!file) throw new Error('File not found');
                return {
                    kind: 'file',
                    name: file.name,
                    getFile: async () => file,
                    createWritable: async () => {
                        // Implement in-memory write operations
                        let chunks: Uint8Array[] = [];
                        return {
                            write: async (chunk: Uint8Array) => {
                                chunks.push(chunk);
                            },
                            close: async () => {
                                const blob = new Blob(chunks);
                                // Trigger download since we can't write directly
                                const url = URL.createObjectURL(blob);
                                const a = document.createElement('a');
                                a.href = url;
                                a.download = name;
                                a.click();
                                URL.revokeObjectURL(url);
                            }
                        };
                    }
                };
            }
        };
    }




}






