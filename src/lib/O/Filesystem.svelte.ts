// Filesystem — the File System Access API, wrapped: a directory handle (FileSystemHandler), the
//  listing under it (DirectoryListing), a file in it (FileListing).  The one seam between Housing's
//   Wormhole and the browser's disk; node gets its own in scripts/NodeWormholeNav.ts.
//  A .svelte.ts because DirectoryListing's files|directories|expanded are $state runes (the tree UI watches
//   them) — as a plain .ts, $state is an undefined name and the first picker click threw (2026-09-16).
//  Lifted from p2p/ftp/Directory.svelte.ts (the prototype's share machinery) 2026-09-16 — only these
//   three classes were live; the shares around them went with the prototype.
import { CHUNK_SIZE, erring } from '$lib/Y.svelte'

// what a listing knows about its share: a name for messages.  (Was the prototype's share object.)
type ShareName = { name: string }

export class FileListing {
    up: DirectoryListing
    name: string;
    share: ShareName

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
type name_haver = {name:string}
function sort_by_name(a:name_haver,b:name_haver,k?:string) {
    k ||= 'name'
    return a[k] > b[k] ? 1 : a[k] < b[k] ? -1 : 0
}
// How long to wait after seeing a .crswap (a write in flight) before re-expanding.
//  A close()/rename settles in well under this; 3s is the human's "read again once it's
//   settled" instinct with slack for a slow disk.  One debounced timer per listing.
const CRSWAP_SETTLE_MS = 3000
// many files|dirs
export class DirectoryListing {
    up?: DirectoryListing
    handle:FileSystemDirectoryHandle
    name: string


    files: FileListing[] = $state([])
    directories: DirectoryListing[] = $state([])

    expanded = $state(false);
    // debounced re-expand handle, armed when an expand() catches the dir mid-write (a .crswap
    //  present, or an entry that vanished under us).  Internal plumbing — not reactive.
    _resettle_timer:any = null

    constructor(init: Partial<DirectoryListing> = {}) {
        Object.assign(this,init)
    }

    async getReader(pathbit) {
        // console.log(`getReader() ${this.up?.name}/${this.name}/${pathbit}`)
        const fileHandle = await this.handle.getFileHandle(pathbit);
        const file = await fileHandle.getFile();
        // < never needs closing? isn't file.stream
        //   a bunch of separate sequential reads...
        //    assuming it hasn't been changed meanwhile etc
        return {
            size: file.size,
            iterate: async function*(startFrom = 0, chunkSize = CHUNK_SIZE) {
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
    async getWriter(pathbit,keepExistingData=false):Promise<FileSystemWritableFileStream> {
        if (!this.handle) throw erring('No directory access')
        const fileHandle = await this.handle.getFileHandle(pathbit, { create: true });
        const writable = await fileHandle.createWritable({keepExistingData});
        return writable;
    }
    async makeDirectory(pathbit) {
        try {
            await this.handle.getDirectoryHandle(pathbit, { create: true })
        } catch (err) {
            throw erring(`Failed to create file "${pathbit}"`, err)
        }
    }
    async deleteEntry(pathbit) {
        try {
            await this.handle.removeEntry(pathbit, { recursive: false })
        } catch (err) {
            if (err.name == "NotFoundError") {
                // D** lags behind reality?  The entry was already gone when we asked to remove it.
                //  Benign idempotent churn (see below), so name what vanished and stay a debug note,
                //   not a naked warn: several call paths (tidy_crswap's crswap-sweep-then-name,
                //    whittle_stock, radiostock_caching's source-gone drop) can each ask to delete the
                //     same disk entry, and a .crswap rename can settle the target away between listing
                //      and removeEntry.  The C-tree (D**) that drove this delete lags the real FS.
                console.debug(`double-deleted "${pathbit}" under ${this.up?.name ? this.up.name + '/' : ''}${this.name}`)
                return
            }
            throw erring(`Failed to delete "${pathbit}"`, err)
        }
    }
    
    
    async expand() {
        if (!this.handle) throw erring('No directory access')
        // Build ASIDE, assign once at the end — swap, don't clear.  This loop crosses an
        //  await per entry, and .files|.directories are read concurrently (WormholeNav
        //   walks, the editor serving several runners' wh ops at once): a reader landing
        //    mid-expand must see a complete listing — old or new — never the cleared
        //     intermediate.  [] here read as not_found for a file that EXISTS, which
        //      upstream turned a recorded Story Book into 'new' mode and clobbered its
        //       toc.snap fixture with a Step-less re-record.
        const files: FileListing[] = []
        const directories: DirectoryListing[] = []
        // A .crswap is Chrome's atomic-write journal: createWritable() writes foo.crswap, then
        //  close() renames it onto foo.  Seeing one means a write is in flight RIGHT NOW — so it
        //   is never a real listing entry (skip by name; don't getFile() something about to
        //    vanish — that WAS the "Skipping problematic entry ….crswap: NotFoundError" noise),
        //     and this whole listing is provisional: the settled foo may not be visible yet.
        //      Flag the flux and re-expand once it settles, converging to post-rename truth rather
        //       than caching a mid-rename listing — the exact race the comment below warns about.
        let saw_flux = false
        // < tabulates|reduces into a Selection later
        // TWO PASSES, THE STATS IN PARALLEL (2026-09-11 — "wormhole list src/lib/O/spec overran
        //  5000ms" on every 8s GhostList walk).  This used to `await entry.getFile()` INSIDE the
        //   `for await`, i.e. one browser-process round trip per file, strictly serial: 139 files
        //    in spec/ at ~40ms each is the whole 5s Wormhole budget, so the op was abandoned and
        //     retried four times a cycle, forever, while the abandoned expands kept running
        //      underneath.  Enumerate first (one stream), then stat every file at once — the
        //       browser pipelines the handles and the listing costs about one round trip.
        //        The listing is sorted after, so the settle order never mattered.
        const seen: FileSystemHandle[] = []
        for await (const entry of this.handle.values()) {
            if (entry.name.endsWith('.crswap')) { saw_flux = true; continue }
            seen.push(entry)
        }
        const stats = await Promise.all(seen.map(async (entry) => {
            if (entry.kind !== 'file') return null
            try { return await (entry as FileSystemFileHandle).getFile() }
            catch (err: any) {
                // An entry can vanish between values() yielding it and our getFile() — a concurrent
                //  delete/rename completing.  Benign churn, not a corrupt entry: note the flux (the
                //   re-expand picks up the settled truth) and stay quiet.  Warn only on a real surprise.
                if (err?.name === 'NotFoundError') { saw_flux = true; return null }
                console.warn(`Skipping problematic entry ${entry.name}:`, err)
                return null
            }
        }))
        seen.forEach((entry, i) => {
            let generally = {
                up: this,
                name: entry.name,
            }
            if (entry.kind === 'file') {
                const file = stats[i]
                if (!file) return
                files.push(new FileListing({
                    ...generally,
                    size: file.size,
                    modified: new Date(file.lastModified),
                }));
            } else {
                // < dirs don't have mtime. put a cache of Stuff in each one?
                // reuse the existing child listing: cached walkers (WormholeNav._cache)
                //  and open UIs keep their object, its expanded state, its own children
                const prior = this.directories.find(d => d.name === entry.name)
                if (prior) { prior.handle = entry as FileSystemDirectoryHandle; directories.push(prior) }
                else directories.push(new DirectoryListing({
                    handle: entry as FileSystemDirectoryHandle,
                    ...generally,
                }));
            }
        })
        this.files = files.sort(sort_by_name)
        this.directories = directories.sort(sort_by_name)
        this.expanded = true
        if (saw_flux) this._resettle()
        return this
    }
    collapse() {
        if (!this.expanded) return;
        this.files = []
        this.directories = []
        this.expanded = false;
    }
    // Arm a single debounced re-expand after a mid-write expand (a .crswap seen / an entry
    //  vanished under us).  Debounced so a burst of writes coalesces to one re-read; converges
    //   because a settled dir shows no .crswap → saw_flux false → nothing re-arms.  Detached
    //    (fire-and-forget onto the reactive $state), so guard a since-dropped handle and swallow.
    _resettle() {
        if (this._resettle_timer) clearTimeout(this._resettle_timer)
        this._resettle_timer = setTimeout(() => {
            this._resettle_timer = null
            if (!this.handle) return   // listing torn down before it settled
            this.expand().catch(() => {})
        }, CRSWAP_SETTLE_MS)
    }


    // < GOING from here down? encode|communicate stuff somehow.
    // for sending only one directory-full at a time
    //  ie return a Partial<DirectoryListing> without any 2-inners
    //   ie dir/dir only, not their dir/dir/(dir|file)
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
// see unemit:file_list_response
export class FileSystemHandler {
    // handle for the root directory of the share
    handle:FileSystemDirectoryHandle|null
    // handles for any file being read
    // < or written to?
    // < io limits per share? so leech swarms share what is going around
    file_handles = new Map()
    // up to share owning this
    share: ShareName
    // the owner can store this
    restoreDirectoryHandle:Function
    storeDirectoryHandle:Function

    started:boolean = false
    list?:DirectoryListing|null

    constructor(opt={}) {
        Object.assign(this, opt)
    }
    async start() {
        const restored = await this.restoreDirectoryHandle?.()
        if (restored) {
            this.handle = restored
            this.post_start()
            console.log(`Restored directory for share "${this.share.name}"`)
            return
        }
    }
    // Request directory access from user
    async requestDirectoryAccess(): Promise<void> {
        try {
            // browser's File System Access API
            this.handle = await window.showDirectoryPicker({
                mode: 'readwrite'
            })
            this.post_start()
            // Store using the storage layer above this
            await this.storeDirectoryHandle?.(this.handle)
        } catch (err) {
            throw erring(`Error accessing directory for share "${this.share.name}"`, err);
        }
    }
    post_start() {
        this.started = true
        // create a root DirectoryListing
        this.list = new DirectoryListing({
            handle:this.handle,
            name:this.handle.name,
        })

    }
    async stop() {
        // Clear all stored handles
        this.file_handles.clear();
        this.handle = null;
        this.list = null;
        this.started = false
    }

}


