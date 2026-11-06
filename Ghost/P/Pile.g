// Pile.g — a music pile kept as a Mag** you can walk, move around in, and undo (spec/Pile_todo.md).
//
//  A pile is three kinds of Mag, each stored in its own file (Store.g, the storage reflex; Pile_todo §3 "The Mag** of a Pile"):
//   - %Mag:Pile, the enclosing one, all we're up to: it holds the others, and its file is only their lines (references), plus
//      %Ask:fsa — the add-another-FSA control, answered by a picker on the page;
//   - one fs Mag per side, %Mag:<the folder's name>,side:A — the directory projected into being, rebuilt from disk by walking;
//   - %Mag:Trail, the session: a %Moment per walk, saying what it noticed, by id;
//   - %Mag:Taste, what a person said of the rows, by id: %Like (♥, a track), %Dislike (👎, a Dir or a track) — referring rows,
//      never a verdict stamped onto an fs row (those are what the disk says).  A Dislike of a Dir holding liked tracks SPARES
//       them (%Spare,of under it): a disliked album keeps its one good track, for the radio's sake.
//  The fs Mag IS the directory tree: a %Dir holds its %Dir and %File rows as the disk does.  A container (the fs Mag or a Dir)
//   holding more than `most` rows (900; a Book sets less) holds PARTITIONS instead — %Mag:A-G for the names under A to G, and
//    when that is full a serial %Mag:A-G (2) — each its own file.  A row stays in the partition it was in while its name stays in
//     range, so a full partition is never reshuffled and a split rewrites nothing already stored.  Partitioning is storage, not
//      identity: a row's place is the Dir above it, whatever partition holds it.
//  A Dir is loosely content-versioned: its `v` is a digest of what it holds (names, file sizes, each sub-Dir's v), so a change
//   anywhere shows in every v above it.
//  IDENTITY rides on the rows: an `id`, minted once.  There is no Seem kept beside the data — a walk springs up a pairing per
//   directory (Theory.g TheA_pair: resolve(), the least ambiguous key:value) between what the disk lists and the rows the Dir
//    held, carries each paired row's id onto its new self, and leaves.  A file renamed pairs by `ms` (size + modified), a Dir
//     renamed by `v`; what left one directory and turned up in another is matched across the whole walk by the same keys, and
//      a moved Dir brings its insides' ids with it.
//  What a walk noticed is said twice, kept apart (Pile_todo §3 "Two memories"): the fs Mag remembers the FILESYSTEM (a %Moved
//   row per rename or move, by id), the Trail remembers the SESSION.
//
//      A:Pile / w:Pile
//        Mag:Pile
//          TheAStore:Pile
//          Mag:Collection,side:A,most=900,minted=17,moves=1
//            TheAStore:Pile/Collection
//            Dir:Album X,v:…,id:1                       ← a row: what the disk says, and its id
//              File:01 a.flac,size=1000,mod=5,ms:1000.5,id:6
//            Dir:Singles,v:…,id:4
//              Mag:O-T                                   ← a partition: too many rows for one container
//                TheAStore:Pile/Collection/4/O-T
//                File:s1.flac,…
//              Mag:O-T (2)
//            Moved:1,of:6,how:rename,from:Album X/01 a.flac,to:Album X/01 A.flac
//          Mag:Trail,moments=2
//            TheAStore:Pile/Trail
//            Moment:2,about:look again,side:A,saw=11
//              Noticed:rename,of:6
//          Ask:fsa,side:B
//
//  The lister is runtime, on the fs Mag's .c: { list(path) → [{ name, dir:1 } | { name, size, mod }], file(path) → a File }.  `path` is '.' for the
//   top, else the entry's path joined with '/'.  The nav the Mags are stored through is runtime too, on w's .c.

IMPORT()

// Pile_stand — the pile's A and its world, on this House
Pile_stand(H, name):
    let A = H.oai({ A: name })
    return A.oai({ w: name })

// Pile_home — the enclosing %Mag:Pile, stored at Pile/
Pile_home(w):
    let home = w.o({ Mag: 'Pile' })[0]
    if (home) return home
    return this.Store_keep(w.i({ Mag: 'Pile' }), 'Pile')

// Pile_side — one side's fs Mag (A: the collection, B: an incoming pile), or null
Pile_side(w, side):
    return this.Pile_home(w).o({ Mag: 1, side })[0] ?? null

// Pile_mag — one side's fs Mag, made if it isn't there: named for its folder (but never Pile or Trail, nor another side's
//  name), stored under the home.  Making one asks for the next side
Pile_mag(w, side, name, most):
    let home = this.Pile_home(w)
    let mag = this.Pile_side(w, side)
    if (!mag) {
        name = String(name || side)
        if (name === 'Pile' || name === 'Trail' || name === 'Taste' || home.o({ Mag: name }).length) {
            name = name + '_' + side
        }
        mag = this.Store_keep(home.i({ Mag: name, side, most: most || 900 }), 'Pile/' + name)
        this.Pile_trail(w)
        this.Pile_ask(w)
    }
    return mag

Pile_trail(w):
    let home = this.Pile_home(w)
    let trail = home.o({ Mag: 'Trail' })[0]
    if (trail) return trail
    return this.Store_keep(home.i({ Mag: 'Trail' }), 'Pile/Trail')

// Pile_ask — the add-another-FSA control: a row asking for a handle for the next free side, answered by a picker on the page
Pile_ask(w):
    let home = this.Pile_home(w)
    let side = 'ABCDEFGH'.split('').find(s => !home.o({ Mag: 1, side: s }).length)
    if (side) {
        home.oai({ Ask: 'fsa' }, { side })
    }
    return home.o({ Ask: 'fsa' })[0]

// Pile_range_of — which partitions a name belongs in: its first character's range.  The one place the rule lives
Pile_range_of(name):
    let c = String(name).charAt(0).toUpperCase()
    for (const range of ['A-G', 'H-N', 'O-T', 'U-Z']) {
        if (c >= range[0] && c <= range[2]) return range
    }
    return c >= '0' && c <= '9' ? '0-9' : 'etc'

Pile_kind(row):
    return row.sc.Dir !== undefined ? 'Dir' : row.sc.File !== undefined ? 'File' : null

// the rows a container (the fs Mag, or a Dir) holds, whatever partition holds them
Pile_kids(C):
    let rows = []
    for (const kid of C.o()) {
        if (this.Pile_kind(kid)) {
            rows.push(kid)
        }
        else if (kid.sc.Mag !== undefined) {
            for (const row of kid.o()) {
                if (this.Pile_kind(row)) rows.push(row)
            }
        }
    }
    return rows

// every row under a container, to any depth
Pile_rows(C):
    if (!C) return []
    let out = []
    for (const row of this.Pile_kids(C)) {
        out.push(row)
        if (row.sc.Dir !== undefined) out.push(...this.Pile_rows(row))
    }
    return out

// Pile_places — every id's place in an fs Mag: id → { path, up, name, kind, row }, where up is the id of the Dir it's in ('.'
//  at the top).  Read before a walk and after, the two say what moved
Pile_places(mag):
    let places = {}
    let go = (C, up, at) => {
        for (const row of this.Pile_kids(C)) {
            let kind = this.Pile_kind(row)
            let name = String(row.sc[kind])
            let path = at ? at + '/' + name : name
            if (row.sc.id) places[row.sc.id] = { path, up, name, kind, row }
            if (kind === 'Dir') go(row, row.sc.id, path)
        }
    }
    go(mag, '.', '')
    return places

// Pile_disk — what the disk says now, as a plain tree (not particles yet): each directory's entries sorted by name, each Dir's
//  `v` worked out from what it holds.  An empty Dir has no v.  A .jamsend directory is the app's own (a listener's app tree may
//   live in the very folder being merged) and is never part of the pile
async Pile_disk(lister, path):
    let ents = ((await lister.list(path)) || []).filter(ent => ent.name !== '.jamsend')
    ents = [...ents].sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0))
    let out = []
    for (const ent of ents) {
        let at = path === '.' ? ent.name : path + '/' + ent.name
        if (ent.dir) {
            let kids = await this.Pile_disk(lister, at)
            let sc = { Dir: ent.name }
            let said = kids.map(k => (k.sc.Dir !== undefined ? k.sc.Dir + '/' + (k.sc.v || '') : k.sc.File + ':' + k.sc.size))
            if (said.length) sc.v = this.TheA_digest(said.join('\n'))
            out.push({ sc, kids })
        }
        else {
            out.push({ sc: { File: ent.name, size: ent.size, mod: ent.mod, ms: ent.size + '.' + ent.mod } })
        }
    }
    return out

// what a goner or a newcomer is matched across directories by: a file's size + modified, a Dir's contents
Pile_match_key(sc):
    if (sc.File !== undefined) return 'F' + sc.ms
    return sc.v ? 'D' + sc.v : null

// Pile_pair_dir — one directory's listing paired with the rows it held (a pairing that springs up and leaves): returns the
//  plan of its new rows, each { sc, kids, old, id }, carrying a paired row's id; what nothing paired goes to the walk's goners
//   (with all it held) and newcomers
async Pile_pair_dir(olds, disk, walk):
    let news = disk.map(ent => ({ sc: ent.sc, ent }))
    let stand_ins = olds.map(row => {
        let sc = { ...row.sc }
        delete sc.id
        return { sc, row }
    })
    let plan = []
    for (const [o, n] of await this.TheA_pair(stand_ins, news)) {
        let old = o?.row
        if (old && n && this.Pile_kind(old) !== Object.keys(n.sc)[0]) {
            walk.goners.push(old, ...this.Pile_rows(old))
            old = null
        }
        else if (old && !n) {
            walk.goners.push(old, ...this.Pile_rows(old))
            continue
        }
        let node = { sc: n.sc, old, id: old?.sc.id }
        if (!node.id) walk.neus.push(node)
        if (n.ent.kids) node.kids = await this.Pile_pair_dir(old ? this.Pile_kids(old) : [], n.ent.kids, walk)
        plan.push(node)
    }
    plan.sort((a, b) => {
        let x = String(a.sc[Object.keys(a.sc)[0]])
        let y = String(b.sc[Object.keys(b.sc)[0]])
        return x < y ? -1 : x > y ? 1 : 0
    })
    return plan

// Pile_place — a container's rows made from its plan.  Few enough, and never partitioned: the rows sit in it.  Otherwise in
//  partitions: a row stays in the one it was in while its name is still in that range; the rest fill the first partition of
//   their range with room, and a full range grows a serial partition.  Partitions the container had are kept (and carried
//    from the old Dir to its new self), so a stored one keeps its file
Pile_place(mag, container, plan, old):
    let most = Number(mag.sc.most || 900)
    let parts = old ? old.o({ Mag: 1 }) : []
    let was_in = {}
    for (const part of parts) {
        for (const row of part.o()) {
            if (!this.Pile_kind(row)) continue
            if (row.sc.id) was_in[row.sc.id] = part.sc.Mag
            part.drop(row)
        }
        if (old !== container) container.i(part)
    }
    if (old === container) {
        for (const row of container.o()) {
            if (this.Pile_kind(row)) container.drop(row)
        }
    }
    let rows = plan.map(node => this.Pile_make(mag, node))
    if (!parts.length && plan.length <= most) {
        for (const row of rows) container.i(row)
        return
    }
    let count = {}
    let range_of_part = (name) => String(name).split(' (')[0]
    let into = plan.map((node, i) => {
        let range = this.Pile_range_of(node.sc[Object.keys(node.sc)[0]])
        let was = node.id && was_in[node.id]
        if (was && range_of_part(was) === range && container.o({ Mag: was }).length) {
            count[was] = (count[was] || 0) + 1
            return was
        }
        return null
    })
    for (let i = 0; i < plan.length; i++) {
        if (into[i]) continue
        let range = this.Pile_range_of(plan[i].sc[Object.keys(plan[i].sc)[0]])
        let k = 1
        let name = range
        while (container.o({ Mag: name }).length && (count[name] || 0) >= most) {
            k++
            name = range + ' (' + k + ')'
        }
        if (!container.o({ Mag: name }).length) {
            let base = this.Store_path(mag)
            this.Store_keep(container.i({ Mag: name }), container === mag ? base + '/' + name : base + '/' + container.sc.id + '/' + name)
        }
        count[name] = (count[name] || 0) + 1
        into[i] = name
    }
    for (let i = 0; i < plan.length; i++) container.o({ Mag: into[i] })[0].i(rows[i])

// one planned row made: its sc and id, and for a Dir everything it holds
Pile_make(mag, node):
    let row = new TheC({ c: {}, sc: { ...node.sc, id: node.id } })
    if (node.kids) this.Pile_place(mag, row, node.kids, node.old)
    return row

// Pile_walk — read the pile again and lay it into the fs Mag, every row keeping its id: paired in its directory, or matched
//  across the walk (moved), or minted (new).  Says what changed — a rename (same Dir, new name), a move (another Dir), something
//   new, something gone — as %Moved rows and one %Moment on the Trail.  A path that changed only because a Dir above it was
//    renamed is no change to it: its Dir's id is the same.  Returns the Moment
async Pile_walk(w, side, about):
    let mag = this.Pile_side(w, side)
    if (!mag?.c.lister) return null
    let home = this.Pile_home(w)
    let before = this.Pile_places(mag)
    let disk = await this.Pile_disk(mag.c.lister, '.')
    let walk = { goners: [], neus: [] }
    let plan = await this.Pile_pair_dir(this.Pile_kids(mag), disk, walk)
    // what left one place and turned up in another: the same key, once each
    let pool = {}
    for (const old of walk.goners) {
        let key = this.Pile_match_key(old.sc)
        if (key && old.sc.id) {
            pool[key] = pool[key] || []
            pool[key].push(old.sc.id)
        }
    }
    let minted = Number(mag.sc.minted || 0)
    let neu = 0
    for (const node of walk.neus) {
        let key = this.Pile_match_key(node.sc)
        let id = key && pool[key]?.shift()
        if (!id) {
            minted++
            neu++
            id = String(minted)
        }
        node.id = id
    }
    this.Pile_place(mag, mag, plan, mag)
    home.oai({ Mag: mag.sc.Mag, side }, { minted })
    let after = this.Pile_places(mag)
    let noticed = []
    for (const id of Object.keys(after)) {
        let was = before[id]
        let now = after[id]
        if (!was) continue
        if (was.up !== now.up) {
            noticed.push({ how: 'move', id, from: was.path, to: now.path })
        }
        else if (was.name !== now.name) {
            noticed.push({ how: 'rename', id, from: was.path, to: now.path })
        }
    }
    let gone = Object.keys(before).filter(id => !after[id])
    let moves = Number(mag.sc.moves || 0)
    for (const it of noticed) {
        moves++
        mag.i({ Moved: String(moves), of: it.id, how: it.how, from: it.from, to: it.to })
    }
    if (noticed.length) home.oai({ Mag: mag.sc.Mag, side }, { moves })
    let trail = this.Pile_trail(w)
    let k = Number(trail.sc.moments || 0) + 1
    home.oai({ Mag: 'Trail' }, { moments: k })
    let saw = Object.keys(after).length
    let moment = trail.i({ Moment: String(k), about, side, saw, ...this.TheA_nonzero({ neu: Object.keys(before).length ? neu : 0, gone: gone.length }) })
    for (const it of noticed) moment.i({ Noticed: it.how, of: it.id })
    for (const id of gone) moment.i({ Noticed: 'gone', of: id })
    return moment

// a row's path in its fs Mag, or null
Pile_path_of(w, side, row):
    let places = this.Pile_places(this.Pile_side(w, side))
    return row?.sc.id ? places[row.sc.id]?.path ?? null : null

// Pile_row — the row with this id, on one side
Pile_row(w, side, id):
    return this.Pile_places(this.Pile_side(w, side))[String(id)]?.row ?? null

// Pile_row_at — the row at this path, on one side
Pile_row_at(w, side, path):
    let places = this.Pile_places(this.Pile_side(w, side))
    return Object.values(places).find(p => p.path === path)?.row ?? null

// Pile_category — a Dir named `0 <name>` is a category (a genre, a section): Heist's shelf marker (Heist_genre_norm, the
//  '0 ' a leading dash becomes).  Its name without the marker, or null
Pile_category(row):
    let m = /^0 (.+)$/.exec(String(row?.sc.Dir ?? ''))
    return m ? m[1] : null

// Pile_audio — a File that plays
Pile_audio(row):
    return row?.sc.File !== undefined && /\.(flac|mp3|ogg|opus|m4a|aac|wav|aiff?)$/i.test(String(row.sc.File))

// ── TASTE — %Mag:Taste, stored at Pile/Taste ───────────────────────────────────────────────────────────────────────────
//      Mag:Taste
//        Like:01 Dawn.flac,of:6,side:A
//        Dislike:Album X,of:1,side:A
//          Spare:01 Dawn.flac,of:6          ← a trace: the liked track this dislike keeps
Pile_taste(w):
    let home = this.Pile_home(w)
    return home.o({ Mag: 'Taste' })[0] ?? this.Store_keep(home.i({ Mag: 'Taste' }), 'Pile/Taste')

// what was said of a row (how: Like | Dislike), or null
Pile_said(w, how, side, id):
    return this.Pile_taste(w).o({ [how]: 1, of: String(id), side })[0] ?? null

// Pile_toggle — ♥ or 👎 a row, or take it back (Radio's heart is a toggle too: love, unlove).  Saying one unsays the other
Pile_toggle(w, how, side, id):
    let row = this.Pile_row(w, side, id)
    if (!row) return null
    let taste = this.Pile_taste(w)
    let had = this.Pile_said(w, how, side, id)
    if (had) {
        taste.drop(had)
        return null
    }
    let other = this.Pile_said(w, how === 'Like' ? 'Dislike' : 'Like', side, id)
    if (other) taste.drop(other)
    return taste.i({ [how]: String(row.sc[this.Pile_kind(row)]), of: String(id), side })

// Pile_spare — a Dislike's spares: the liked tracks anywhere under the Dir it names, as %Spare rows under it.  Returns how many
//  changed (a Dislike of a track, or of a Dir with nothing liked, has none)
Pile_spare(w, dislike):
    let side = dislike.sc.side
    let row = this.Pile_row(w, side, dislike.sc.of)
    let want = row?.sc.Dir !== undefined ? this.Pile_rows(row).filter(r => r.sc.File !== undefined && this.Pile_said(w, 'Like', side, r.sc.id)) : []
    let changed = 0
    for (const spare of dislike.o({ Spare: 1 })) {
        if (!want.some(r => r.sc.id === spare.sc.of)) {
            dislike.drop(spare)
            changed++
        }
    }
    for (const r of want) {
        if (!dislike.o({ Spare: 1, of: r.sc.id }).length) {
            dislike.i({ Spare: String(r.sc.File), of: r.sc.id })
            changed++
        }
    }
    return changed

// Pile_heard — does a row get played: not when it, or a Dir it's in, is disliked — unless it's liked (spared)
Pile_heard(w, side, id):
    if (this.Pile_said(w, 'Like', side, id)) return true
    let places = this.Pile_places(this.Pile_side(w, side))
    for (let at = String(id); at && at !== '.'; at = places[at]?.up) {
        if (this.Pile_said(w, 'Dislike', side, at)) return false
    }
    return true

// Pile_next — the track after this one, in shelf order, that gets played; null at the end
Pile_next(w, side, id):
    let files = this.Pile_rows(this.Pile_side(w, side)).filter(r => this.Pile_audio(r))
    let i = files.findIndex(r => r.sc.id === String(id))
    return files.slice(i + 1).find(r => this.Pile_heard(w, side, r.sc.id))?.sc.id ?? null

// Pile_play — %Playing:<name>,of:<id>,side on w, the one track playing (runtime, never stored), or none
Pile_play(w, side, id):
    for (const was of w.o({ Playing: 1 })) w.drop(was)
    let row = id != null ? this.Pile_row(w, side, id) : null
    if (!this.Pile_audio(row)) return null
    return w.i({ Playing: String(row.sc.File), of: row.sc.id, side })

// Pile_settle — write each of the pile's Mags whose text changed (Store.g), through the nav on w's .c.  After a walk, until a
//  walk is a run whose tail does it
async Pile_settle(w):
    return this.Store_settle(w, w.c.nav)

// Pile_open — stand a pile again from what's stored: the home, and through its reference lines every side's fs Mag (each
//  partition from its own file) and the Trail, ids and all.  A lister doesn't come back (a handle is re-granted on a page), so
//   the caller hangs one on before walking.  Returns the w, or null when nothing was stored
async Pile_open(H, name, nav):
    let old = H.o({ A: name })[0]
    if (old) H.drop(old)
    let w = this.Pile_stand(H, name)
    w.c.nav = nav
    let home = await this.Store_open(w, 'Pile', nav)
    return home ? w : null

// Pile_fsa_lister — a lister over a real FileSystemDirectoryHandle: a directory's entries, with each file's size and
//  lastModified.  ⚠ The .g compiler makes it async (awaits in its arrows), so a caller awaits it (Pile_grant).  Book PilePage
//   drives it over a fake handle.
Pile_fsa_lister(root):
    let dir_at = async (path) => {
        let here = root
        if (path === '.') return here
        for (const part of path.split('/')) here = await here.getDirectoryHandle(part)
        return here
    }
    return {
        list: async (path) => {
            let dir = await dir_at(path)
            let out = []
            for await (const handle of dir.values()) {
                if (handle.kind === 'directory') {
                    out.push({ name: handle.name, dir: 1 })
                }
                else {
                    let file = await handle.getFile()
                    out.push({ name: handle.name, size: file.size, mod: file.lastModified })
                }
            }
            return out
        },
        file: async (path) => {
            let parts = path.split('/')
            let name = parts.pop()
            let dir = await dir_at(parts.length ? parts.join('/') : '.')
            return (await dir.getFileHandle(name)).getFile()
        },
    }
