import { SvelteMap } from "svelte/reactivity";

// UI
import Shares from "./Shares.svelte";
import Sharee from "./Sharee.svelte";
import { DirectoryListing, DirectoryShare, DirectoryShares } from "./Directory.svelte";
type percentage = number
import { _C, keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
import { PeeringFeature, PierFeature,
         now_in_seconds_with_ms, now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
import { erring, ex, grep, grop, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
import { RadioModus } from "./Audio.svelte";
import type { Travel } from "$lib/mostly/Selection.svelte";

//#endregion
//#region DirectoryModus
// ftp as a view to work with
//  makes guesswork to provide defaults, remote plots may inject
export class DirectoryModus extends RadioModus {
    // js quirk: our constructor() / super() / assign() doesn't set .F|S
    //  unless 'declare', because they are in the parent class also
    declare F:PeeringSharing
    declare S:DirectoryShare//|AnyShare // the Thing we're hotwiring

    // into this Selection.process()
    Se:Selection
    Tr:Travel
    thetime = 0

    constructor(opt:Partial<DirectoryModus>) {
        super(opt)

        this.S.i_actions({
            'j++': () => this.further_journey(),
            'j--': () => this.further_journey({go:'backwards'}),
            'Mo++': () => this.main(),
            'hard': () => this.toggle_gohard(),
            'A++': () => this.do_A(),
        })
    }




    // click button events
    // < manual directory browsing, w:meander takes care of it for us
    // the events, nudges
    async further_journey(opt?) {
        let D = this.Tr.sc.D
        if (!D.oa({journey:1})) {
            this.Se.autovivify_journey(D)
            return
        }
        await this.Se.journey_further(opt)
        this.main()
    }
    async nameclick(D:TheD) {
        let Se = this.Se
        let topD = Se.c.T.sc.D
        let journey = 'funsies'
        topD.replace({journey}, async () => {
            let j = topD.i({journey,clicked:1})
            Se.i_path(j,D)
        })
        this.main()
    }
    // sleep when possible
    hard = false
    toggle_gohard() {
        this.hard = !this.hard
        console.log("going hard: "+this.hard)
    }
    // Agency parameterising and processing
    // < it could want these A.is() or not, depending on how resetty we're trying to be
    //    we might just be changing parameters on things from .perm
    //    but trust changes can be totally Modus-resetting for now
    async do_A() {
        await this.r({A:1},{})
        this.i({A:'Directory'})
        
        this.i({A:'rastream'})

        this.i({A:'Alice Records'}).i({w:'rahunting'})
        this.i({A:'Bob Records'}).i({w:'rahunting'})

        this.i({A:'radiostock'})
        this.i({A:'rapiracy'})

        console.log(`do_A() for ${this.constructor.name}`)
        this.main()
    }

}


//#endregion
//#region M:Shares
//  makes guesswork to provide defaults, remote plots may inject
export class SharesModus extends RadioModus {
    declare S:PeeringSharing
    declare F:PeeringSharing

    constructor(opt:Partial<SharesModus>) {
        super(opt)
        this.F = this.S
        // the above super() / assign() doesn't set .F|S (javascript quirk?)
        // Object.assign(this,opt)
        if (!this.S) throw "Oh no F"

        this.S.i_actions({
            'R++': () => this.further_journey(),
            'R--': () => this.further_journey({go:'backwards'}),
            'Mo++': () => this.main(),
        })
    }
    async do_A() {
        await this.r({A:1},{})
        this.i({A:'ragate'})
        this.i({A:'raglance'})
        console.log(`do_A() for ${this.constructor.name}`)
    }

    async do_main() {
        await this.r({Seee:2})
    }


}
//#endregion
//#region M:Sharee
export class ShareeModus extends RadioModus {
    declare S:PierSharing
    declare F:PeeringSharing
    declare PF:PierSharing
    constructor(opt:Partial<SharesModus>) {
        super(opt)
        this.PF = this.S

        this.S.i_actions({
            'Radio': () => this.turn_knob(),
            'recyto': () => this.recyto(),
            'Mo++': () => this.main(),
            'C++': () => this.hard_reset(),
            'A++': () => this.do_A(),
        })
    }
    async hard_reset() {
        this.empty();
        await this.do_A();
        this.main()
    }
    // describe the minds regarding trust
    // < rename perm... it's both pieces of trust, theirs and ours...
    async do_A() {
        await this.r({A:1},{})
        let V = this.i({A:'visual'})
        V.i({w:'cytotermicaster'})
        
        let A = this.i({A:'audio'})

        // < so perm can change over time, do this every time, replacing %w?
        let perm = this.PF.perm
        if (perm.local) {
            // we grant them read access, they receive
            A.i({w:'racaster'})
        }
        if (perm.remote) {
            // they grant us read access, we receive
            A.i({w:'raterminal'})
        }
        if (perm.local && perm.remote) {
            // < may both be on, share DJing, syncing many Pier's?
            A.i({is_both_listener_and_source:1})
        }
        console.log(`do_A() for ${this.constructor.name}`)
        this.main()
    }

    

    

}



//#endregion PeeringSharing
//#region PeeringSharing
// the F
export class PeeringSharing extends PeeringFeature {
    // a Things of super complicated directory handling, locating music, encoding it
    //  produces S.modus/%io:radiostock
    shares: DirectoryShares
    modus_init() {
        return new SharesModus({S:this})
    }
    every_Modus():Modus[] {
        return [this.modus, ...this.shares.asArray()
            .map(share => share.modus).filter(M=>M)]
    }

    constructor(opt) {
        super(opt)
        this.trust_name = 'ftp'
        // our UI gives this and our shares/...S a .modus (via UI:Modus)
        this.UI_component = Shares
        this.IDB_Schema(7, [
            // these two are /$share/$handle
            'shares',        // for Things:DirectoryShares
            'share handle',  // for DirectoryShare.persisted_handle
            'gizmo',        // for named Things:** with .stashed via UI:Thingstashed
        ])
        this.shares = new DirectoryShares({F:this})
    }
    // be here and in a Pier's UI
    spawn_PF({Pier}) {
        return new PierSharing({P:this.P,Pier,F:this})
    }

    // < who|where|when hits start? the UI?
    started = $state(false)
    async start() {
        // this is started by UI:Things
        // await this.shares.start()
        this.started = true
    }

}

//#endregion
//#region PierSharing
// the PF (per Pier)
export class PierSharing extends PierFeature {
    // < keep?
    tm:TransferManager
    modus_init() {
        return new ShareeModus({S:this})
    }

    constructor(opt) {
        super(opt)
        this.UI_component = Sharee
        this.emit("whatsup",{from:this.Pier.eer.Id+''})
    }
    

    // < DUBIOUS from here down

    // < figure out how to do navigation and population
    // listings here + there
    remoteList: DirectoryListing | null = $state()

    // then, maybe via ui,
    started = $state(false)
    async start() {
        try {
            // < resume against what we had? another Thing to store?
            this.tm = new TransferManager({sharing:this})

            this.started = true
            console.log(`PierSharing:`, this.list);
        } catch (err) {
            throw erring("Failed to start file sharing", err);
        }
    }
    async stop() {
        try {
            // Cancel any active transfers
            await this.tm.stop()

            // Clear file system state
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
    // < needs a redo for %nib** reality...
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

    // < comes via Modus now
    // List available files
    // memoized here:
    localList_string?:string
    async refresh_localList(): Promise<string[]> {
        this.localList = await this.fsHandler.list.expand();

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
        whatsup: async (data,{P,Pier}) => {
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
























