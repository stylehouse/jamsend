// PileTesting.g — the proof of Pile.g (spec/Pile_todo.md rung 1).
//
//  A runner can't pick a folder, so the Book's pile is a FIXTURE: a little tree held in memory (on .c, never snapped), with a
//   lister over it the way Pile_fsa_lister lists a real directory.  "The world" changes it between walks — a rename, a move, a
//    directory renamed with the same insides — and each walk must say what happened by id, never as a vanish plus an arrival.
//  Pile.g must already be loaded (the Book's toc stands on it).

IMPORT()

//#region the fixture pile

// a tree: a directory is an object of its entries, a file is [size, modified].  Sizes and times all differ, so nothing pairs
//  by accident
PileTesting_fixture():
    return {
        'Album X': { '01 Dawn.flac': [1001, 11], '02 Noon.flac': [1002, 12], '03 Dusk.flac': [1003, 13] },
        'Album Y': { 'a.mp3': [2001, 21], 'b.mp3': [2002, 22] },
        'Loose': { 'stray.ogg': [3001, 31] },
        'Empty': {},
        'Singles': { 's1.flac': [5001, 51], 's2.flac': [5002, 52], 's3.flac': [5003, 53], 's4.flac': [5004, 54], 's5.flac': [5005, 55], 's6.flac': [5006, 56] },
        'readme.txt': [4001, 41],
    }

// the directory object at a path, or null
PileTesting_dir(tree, path):
    let here = tree
    if (path === '.') return here
    for (const part of path.split('/')) {
        here = here?.[part]
        if (!here || Array.isArray(here)) return null
    }
    return here

PileTesting_lister(tree):
    return {
        list: async (path) => {
            let dir = this.PileTesting_dir(tree, path)
            if (!dir) return []
            return Object.keys(dir).map(name => (Array.isArray(dir[name]) ? { name, size: dir[name][0], mod: dir[name][1] } : { name, dir: 1 }))
        },
    }

// the world renames something: same directory, new name, insides untouched
PileTesting_rename(tree, dir_path, name, to):
    let dir = this.PileTesting_dir(tree, dir_path)
    dir[to] = dir[name]
    delete dir[name]

// the world drops a new file into a directory
PileTesting_add(tree, dir_path, name, size, mod):
    this.PileTesting_dir(tree, dir_path)[name] = [size, mod]

// the world moves something into another directory, keeping its name
PileTesting_move(tree, dir_path, name, to_dir):
    let dir = this.PileTesting_dir(tree, dir_path)
    this.PileTesting_dir(tree, to_dir)[name] = dir[name]
    delete dir[name]

//#endregion
//#region the test routine — Book PileWalk
// The pile's w is w:PileW, never w:Pile: a runner that has loaded PilePage.g would think a w:Pile as the page (dispatch by name).
// The pile is stood with most=4 (a container over 4 rows partitions), so the fixture's top level and its Singles directory
//  both partition.  Step 2 stands pile A over the fixture and walks it.  Step 3: the world renames a file.  Step 4: the world
//   moves a file into another directory.  Step 5: the world renames a directory, its insides the same, across name ranges
//    (another partition).  Step 6: the page reloads — the pile is stood again from its stored Mags (a memory nav) and walked.
//     Step 7: the world renames a file after the reload.  Step 8: the world drops three files into Singles, whose first
//      partition is full.  Each step ends with one walk and a settle (the changed Mags written); the Trail gets a moment per walk.
PileWalk(A,w):
    w oai %req:wrangle,eternal
        await &PileWalk_drive,w,req
        req%ok = 1

async PileWalk_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 8
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.PileWalk_stand(w)
        if (n === 3) await this.PileWalk_world(w, 'the world renames a file — walk again', (tree) => this.PileTesting_rename(tree, 'Album X', '02 Noon.flac', '02 Midday.flac'))
        if (n === 4) await this.PileWalk_world(w, 'the world moves a file into another directory — walk again', (tree) => this.PileTesting_move(tree, 'Loose', 'stray.ogg', 'Album Y'))
        if (n === 5) await this.PileWalk_world(w, 'the world renames a directory — its insides the same — into another name range — walk again', (tree) => this.PileTesting_rename(tree, '.', 'Album X', 'X Album'))
        if (n === 6) await this.PileWalk_reload(w)
        if (n === 7) await this.PileWalk_world(w, 'the world renames a file after the reload — walk again', (tree) => this.PileTesting_rename(tree, 'X Album', '03 Dusk.flac', '03 Dusk (live).flac'))
        if (n === 8) await this.PileWalk_world(w, 'the world drops three files into a full partition — walk again', (tree) => {
            this.PileTesting_add(tree, 'Singles', 's0.flac', 5000, 50)
            this.PileTesting_add(tree, 'Singles', 's7.flac', 5007, 57)
            this.PileTesting_add(tree, 'Singles', 's8.flac', 5008, 58)
        })
    }
    this.PileWalk_witness(w)

PileWalk_pile():
    return this.o({ A: 'PileW' })[0]?.o({ w: 'PileW' })[0] ?? null

// what each path's id is now (runtime, never snapped): the witness compares against it after the world changes things
PileWalk_ids(mag):
    let ids = {}
    for (const place of Object.values(this.Pile_places(mag))) ids[place.path] = place.row.sc.id
    return ids

async PileWalk_stand(w):
    w.i({ desc: 'stand pile A over a fixture tree — walk it — store its Mags' })
    let old = this.o({ A: 'PileW' })[0]
    if (old) this.drop(old)
    let pile = this.Pile_stand(this, 'PileW')
    this.c.pile_nav = this.Store_memory_nav()
    pile.c.nav = this.c.pile_nav
    let mag = this.Pile_mag(pile, 'A', 'Collection', 4)
    mag.c.tree = this.PileTesting_fixture()
    mag.c.lister = this.PileTesting_lister(mag.c.tree)
    await this.Pile_walk(pile, 'A', 'first look')
    await this.Pile_settle(pile)

async PileWalk_world(w, desc, change):
    w.i({ desc })
    let pile = this.PileWalk_pile()
    let mag = pile && this.Pile_side(pile, 'A')
    if (!mag?.c.tree) return
    mag.c.ids_before = this.PileWalk_ids(mag)
    change(mag.c.tree)
    await this.Pile_walk(pile, 'A', desc.replace(/ — walk again$/, ''))
    await this.Pile_settle(pile)

// the page reloads: everything on .c is gone but the fixture (the folder, still on disk) and the nav (the app tree)
async PileWalk_reload(w):
    w.i({ desc: 'the page reloads — the pile stood again from its stored Mags — walk again' })
    let pile = this.PileWalk_pile()
    let mag = pile && this.Pile_side(pile, 'A')
    if (!mag?.c.tree) return
    let tree = mag.c.tree
    let ids = this.PileWalk_ids(mag)
    pile = await this.Pile_open(this, 'PileW', this.c.pile_nav)
    mag = pile && this.Pile_side(pile, 'A')
    if (!mag) {
        w.i({ log: 'the pile did not come back from its files' })
        return
    }
    mag.c.ids_before = ids
    mag.c.tree = tree
    mag.c.lister = this.PileTesting_lister(tree)
    await this.Pile_walk(pile, 'A', 'the page reloads')
    await this.Pile_settle(pile)

// the witness reads the tree the steps wrote: rows, their ids, the Moved rows, the Trail, the stored files — never the fixture
PileWalk_witness(w):
    let pile = this.PileWalk_pile()
    if (!pile) return
    let n = this.c.run?.c.step_n ?? 0
    let home = pile.o({ Mag: 'Pile' })[0]
    let mag = home?.o({ Mag: 1, side: 'A' })[0]
    let trail = home?.o({ Mag: 'Trail' })[0]
    if (!mag || !trail) return
    let places = this.Pile_places(mag)
    let rows = Object.values(places).map(p => p.row)
    let at = (path) => Object.values(places).find(p => p.path === path)?.row ?? null
    let names_in = (part) => (part?.o() ?? []).filter(row => this.Pile_kind(row)).map(row => row.sc[this.Pile_kind(row)]).join(',')
    let top = (range) => names_in(mag.o({ Mag: range })[0])
    let singles = at('Singles')
    let in_singles = (range) => names_in(singles?.o({ Mag: range })[0])
    let moment = (k) => trail.o({ Moment: String(k) })[0]
    let noticed = (k) => (moment(k)?.o({ Noticed: 1 }) ?? []).map(it => it.sc.Noticed + ':' + it.sc.of)
    let moved = (how) => mag.o({ Moved: 1 }).filter(m => m.sc.how === how)
    let file = (path) => this.c.pile_nav?.files[path + '/toc.snap']
    let writes = (path) => Number(pile.o({ TheAStored: path })[0]?.sc.writes || 0)
    let singles_at = singles ? 'Pile/Collection/' + singles.sc.id + '/' : ''

    let ids = rows.map(row => row.sc.id)
    let album = at('Album X')
    if (n === 2 && rows.length === 18 && ids.every(id => id) && new Set(ids).size === 18 && album
        && this.Pile_kids(album).map(row => row.sc.File).join(',') === '01 Dawn.flac,02 Noon.flac,03 Dusk.flac' && at('Album X/01 Dawn.flac')) {
        this.story_swear(w, 'the pile is the directory tree — a Dir holds its files and Dirs — every entry has its own id')
    }
    if (n === 2) {
        let kinds = home.o().filter(C => C.sc.TheAStore === undefined).map(C => Object.keys(C.sc)[0] + ':' + C.sc[Object.keys(C.sc)[0]]).join(',')
        if (kinds === 'Mag:Collection,Mag:Trail,Ask:fsa' && home.o({ Ask: 'fsa' })[0]?.sc.side === 'B'
            && top('A-G') === 'Album X,Album Y,Empty' && top('H-N') === 'Loose' && top('O-T') === 'Singles,readme.txt'
            && in_singles('O-T') === 's1.flac,s2.flac,s3.flac,s4.flac' && in_singles('O-T (2)') === 's5.flac,s6.flac') {
            this.story_swear(w, 'the pile is three Mags — Mag:Pile holds the side’s Mag and the Trail and asks for another folder — a container with too many rows holds partitions by name range — a full one is followed by a serial one')
        }
        let home_file = file('Pile') || ''
        if (home_file.includes('Mag:Collection') && home_file.includes('TheAStore:Pile/Collection') && !/Moment|Dir:|File:/.test(home_file)
            && ['Pile/Collection', 'Pile/Collection/A-G', 'Pile/Collection/H-N', 'Pile/Collection/O-T', 'Pile/Trail', singles_at + 'O-T', singles_at + 'O-T (2)'].every(path => file(path))
            && !/File:/.test(file('Pile/Collection')) && !/File:s/.test(file('Pile/Collection/O-T')) && file(singles_at + 'O-T (2)').includes('File:s5.flac')) {
            this.story_swear(w, 'each Mag is written to its own file — Mag:Pile’s file holds only the lines of the Mags it holds — each partition holds its own rows')
        }
    }
    if (n === 3) {
        let was = mag.c.ids_before?.['Album X/02 Noon.flac']
        let now = at('Album X/02 Midday.flac')
        let one = moved('rename')
        if (was && now?.sc.id === was && !at('Album X/02 Noon.flac') && one.length === 1 && one[0].sc.of === was && noticed(2).join(' ') === 'rename:' + was) {
            this.story_swear(w, 'a file renamed by the world keeps its id — the walk says rename — not a vanish and an arrival')
        }
    }
    if (n === 4) {
        let was = mag.c.ids_before?.['Loose/stray.ogg']
        let now = at('Album Y/stray.ogg')
        if (was && now?.sc.id === was && moved('move').length === 1 && moved('move')[0].sc.to === 'Album Y/stray.ogg' && noticed(3).join(' ') === 'move:' + was) {
            this.story_swear(w, 'a file moved by the world into another directory keeps its id — the walk says move')
        }
    }
    if (n === 5) {
        let seen = mag.c.ids_before || {}
        let dir = at('X Album')
        let kids = ['01 Dawn.flac', '02 Midday.flac', '03 Dusk.flac']
        let kept = kids.every(name => at('X Album/' + name)?.sc.id === seen['Album X/' + name])
        if (dir && dir.sc.id === seen['Album X'] && kept && noticed(4).join(' ') === 'rename:' + seen['Album X']) {
            this.story_swear(w, 'a directory renamed by the world with the same insides keeps its id — so do its insides — one rename noticed and nothing else')
        }
        if (dir && kept && top('U-Z') === 'X Album' && this.Pile_kids(dir).length === 3 && !top('A-G').includes('Album X')) {
            this.story_swear(w, 'renamed into another name range a directory moves to that partition with its insides — the ids stay — the partition it left holds none of it')
        }
        if (writes('Pile') === 1 && writes('Pile/Collection/O-T') === 1 && writes(singles_at + 'O-T') === 1 && writes('Pile/Collection/A-G') >= 3 && writes('Pile/Trail') === 4) {
            this.story_swear(w, 'a Mag nothing changed in is written once and never again — Mag:Pile and an untouched partition — while the Trail is written every walk')
        }
        let moments = trail.o({ Moment: 1 }).map(m => m.sc.Moment).join(',')
        if (moments === '1,2,3,4' && !trail.o({ Moment: 1 }).some(m => m.o({ Noticed: 'gone' }).length)) {
            this.story_swear(w, 'each walk is one moment on the Trail in order — what it noticed is said there by id — nothing went missing')
        }
    }
    if (n === 6) {
        let seen = mag.c.ids_before || {}
        let same = Object.keys(seen).length === 18 && Object.keys(seen).every(path => at(path)?.sc.id === seen[path])
        let m = moment(5)
        if (same && rows.length === 18 && m && !m.o().length && !m.sc.neu && Number(mag.sc.minted) === 18 && mag.o({ Moved: 1 }).length === 3) {
            this.story_swear(w, 'stood again from its files the pile has every id it had and its moves — the walk after notices nothing new')
        }
        if (!pile.o({ TheAStored: 'Pile' }).length && !pile.o({ TheAStored: 'Pile/Collection/A-G' }).length && !pile.o({ TheAStored: 'Pile/Collection/U-Z' }).length && !pile.o({ TheAStored: singles_at + 'O-T' }).length && writes('Pile/Trail') === 1) {
            this.story_swear(w, 'after the reload a Mag that did not change is not written again — Mag:Pile nor a partition — the Trail is')
        }
    }
    if (n === 7) {
        let was = mag.c.ids_before?.['X Album/03 Dusk.flac']
        let now = at('X Album/03 Dusk (live).flac')
        let moments = trail.o({ Moment: 1 }).map(m => m.sc.Moment).join(',')
        if (was && now?.sc.id === was && noticed(6).join(' ') === 'rename:' + was && moments === '1,2,3,4,5,6') {
            this.story_swear(w, 'after the reload a file the world renames keeps the id it was given before — the Trail carries on counting')
        }
    }
    if (n === 8) {
        if (in_singles('O-T') === 's1.flac,s2.flac,s3.flac,s4.flac' && in_singles('O-T (2)') === 's0.flac,s5.flac,s6.flac,s7.flac' && in_singles('O-T (3)') === 's8.flac'
            && !pile.o({ TheAStored: singles_at + 'O-T' }).length && writes(singles_at + 'O-T (3)') === 1 && Number(moment(7)?.sc.neu) === 3) {
            this.story_swear(w, 'a full partition is never reshuffled — newcomers fill the last one with room and spill into a new serial one — the full one is not written again')
        }
    }
//#endregion
//#region the test routine — Book PilePage
// The page's hands (PilePage.g) without a page: a runner can't pick a folder, so a FAKE directory handle over the fixture stands
//  in for one (what Pile_fsa_lister reads of a real FileSystemDirectoryHandle: getDirectoryHandle, values(), getFile()), and a
//   memory nav for the identity's app tree.  The page's w is stood as w:PileP so the House never thinks it on its own — the Book
//    calls Pile(A,w) itself, once per thing the page would do.  Step 2: a page with nothing stored; a folder is granted; walked.
//     Step 3: the page reloads: what was stored is there before the folder is granted again; granted, the walk notices nothing.
//      Step 4: presses, as the face makes them — ♥ a track, 👎 its album, play it, then next.  Step 5: the page reloads; the taste is there.
PilePage(A,w):
    w oai %req:wrangle,eternal
        await &PilePage_drive,w,req
        req%ok = 1

async PilePage_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 5
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.PilePage_first(w)
        if (n === 3) await this.PilePage_reload(w)
        if (n === 4) await this.PilePage_taste(w)
        if (n === 5) await this.PilePage_retaste(w)
    }
    this.PilePage_witness(w)

// a fake FileSystemDirectoryHandle over a fixture tree: a directory's entries as handles, a file's size and lastModified
PileTesting_handle(tree, name):
    let file = (v, nm) => ({ kind: 'file', name: nm, getFile: async () => ({ size: v[0], lastModified: v[1] }) })
    let dir = (node, nm) => ({
        kind: 'directory',
        name: nm,
        getDirectoryHandle: async (part) => dir(node[part], part),
        values: () => Object.keys(node).map(k => (Array.isArray(node[k]) ? file(node[k], k) : dir(node[k], k))),
    })
    return dir(tree, name)

// stand the page's A and w afresh (a page load): its nav is the app tree, which outlives the page; no face in a runner
PilePage_stand():
    let old = this.o({ A: 'PileP' })[0]
    if (old) this.drop(old)
    let w = this.Pile_stand(this, 'PileP')
    w.c.nav = this.c.pilep_nav
    w.c.face = 1
    return w

async PilePage_first(w):
    w.i({ desc: 'a page with nothing stored — a folder is granted — walked and stored' })
    this.c.pilep_nav = this.Store_memory_nav()
    this.c.pilep_tree = this.PileTesting_fixture()
    // the folder carries the app's own tree, as a listener's music folder does: never part of the pile
    this.c.pilep_tree['.jamsend'] = { 'wormhole': { 'toc.snap': [9001, 91] } }
    let pw = this.PilePage_stand()
    let A = this.o({ A: 'PileP' })[0]
    await this.Pile(A, pw)
    w.oai({ Saw: 'opened' }, this.TheA_nonzero({ mags: pw.o({ Mag: 1 }).length }))
    await this.Pile_grant(pw, 'A', this.PileTesting_handle(this.c.pilep_tree, 'Music'), 'a folder picked')
    await this.Pile(A, pw)

async PilePage_reload(w):
    w.i({ desc: 'the page reloads — the pile is there from its files before the folder is granted again — granted and walked' })
    let pw = this.PilePage_stand()
    let A = this.o({ A: 'PileP' })[0]
    await this.Pile(A, pw)
    let mag = pw.o({ Mag: 'Pile' })[0]?.o({ Mag: 1, side: 'A' })[0]
    w.oai({ Saw: 'reopened' }, this.TheA_nonzero({ rows: this.Pile_rows(mag).length, live: mag?.c.lister ? 1 : 0 }))
    await this.Pile_grant(pw, 'A', this.PileTesting_handle(this.c.pilep_tree, 'Music'), 'the page reloads')
    await this.Pile(A, pw)

async PilePage_taste(w):
    w.i({ desc: 'presses as the face makes them — like a track — dislike its album — play it — then next' })
    let pw = this.o({ A: 'PileP' })[0]?.o({ w: 'PileP' })[0]
    let A = this.o({ A: 'PileP' })[0]
    if (!pw) return
    let dawn = this.Pile_row_at(pw, 'A', 'Album X/01 Dawn.flac')
    let album = this.Pile_row_at(pw, 'A', 'Album X')
    this.Pile_press(pw, 'like', 'A', dawn?.sc.id)
    this.Pile_press(pw, 'dislike', 'A', album?.sc.id)
    this.Pile_press(pw, 'play', 'A', dawn?.sc.id)
    await this.Pile(A, pw)
    let p = pw.o({ Playing: 1 })[0]
    w.oai({ Saw: 'played' }, { of: String(p?.sc.Playing ?? 'nothing') })
    this.Pile_press(pw, 'next', 'A', dawn?.sc.id)
    await this.Pile(A, pw)
    w.oai({ Saw: 'next' }, { of: String(this.Pile_path_of(pw, 'A', this.Pile_row(pw, 'A', pw.o({ Playing: 1 })[0]?.sc.of)) ?? 'nothing') })

async PilePage_retaste(w):
    w.i({ desc: 'the page reloads — what was liked and disliked is there — nothing plays' })
    let pw = this.PilePage_stand()
    let A = this.o({ A: 'PileP' })[0]
    await this.Pile(A, pw)
    await this.Pile_grant(pw, 'A', this.PileTesting_handle(this.c.pilep_tree, 'Music'), 'the page reloads')
    await this.Pile(A, pw)

PilePage_witness(w):
    let pw = this.o({ A: 'PileP' })[0]?.o({ w: 'PileP' })[0]
    if (!pw) return
    let n = this.c.run?.c.step_n ?? 0
    let home = pw.o({ Mag: 'Pile' })[0]
    let mag = home?.o({ Mag: 'Music', side: 'A' })[0]
    let trail = home?.o({ Mag: 'Trail' })[0]
    if (!mag || !trail) return
    let rows = this.Pile_rows(mag)
    let files = this.c.pilep_nav?.files || {}
    if (n === 2 && w.o({ Saw: 'opened' })[0] && w.o({ Saw: 'opened' })[0].sc.mags === undefined && rows.length === 18 && rows.every(row => row.sc.id)
        && this.Pile_row_at(pw, 'A', 'Singles/s6.flac')?.sc.size === 5006 && files['Pile/Music/toc.snap'] && files['Pile/toc.snap']) {
        this.story_swear(w, 'a page with nothing stored opens empty — a folder granted through its handle becomes the side’s Mag named for it — walked and stored')
    }
    if (n === 2 && rows.length === 18 && !rows.some(row => String(row.sc.Dir ?? row.sc.File).startsWith('.jamsend'))) {
        this.story_swear(w, 'a .jamsend directory in the folder is the app’s own — never part of the pile')
    }
    let again = w.o({ Saw: 'reopened' })[0]
    let m2 = trail.o({ Moment: '2' })[0]
    if (n === 3 && again?.sc.rows === 18 && again.sc.live === undefined && rows.length === 18 && m2 && !m2.o().length && !m2.sc.neu && Number(mag.sc.minted) === 18) {
        this.story_swear(w, 'a reloaded page has the pile from its files before the folder is granted again — granted — the walk notices nothing')
    }
    let taste = home.o({ Mag: 'Taste' })[0]
    let dislike = taste?.o({ Dislike: 'Album X' })[0]
    let spares = dislike ? dislike.o({ Spare: 1 }).map(x => x.sc.Spare).join(',') : ''
    if (n === 4 && w.o({ Saw: 'played' })[0]?.sc.of === '01 Dawn.flac' && taste?.o({ Like: '01 Dawn.flac' }).length && spares === '01 Dawn.flac'
        && !pw.o({ Press: 1 }).length && String(files['Pile/Taste/toc.snap'] || '').includes('Spare:01 Dawn.flac')) {
        this.story_swear(w, 'a like and a dislike pressed in one turn — the disliked album spares its liked track — stored in the Taste Mag')
    }
    if (n === 4 && w.o({ Saw: 'next' })[0]?.sc.of === 'Album Y/a.mp3') {
        this.story_swear(w, 'next skips the rest of a disliked album — its spared track still plays')
    }
    if (n === 4 && this.Pile_category({ sc: { Dir: '0 chill' } }) === 'chill' && this.Pile_category({ sc: { Dir: 'Album X' } }) === null) {
        this.story_swear(w, 'a Dir named 0 and a space is a category — Heist’s shelf marker')
    }
    if (n === 5 && !pw.o({ Playing: 1 }).length && spares === '01 Dawn.flac' && taste?.o({ Like: 1 }).length === 1 && rows.length === 18) {
        this.story_swear(w, 'after a reload the likes and dislikes are back from their file with the spares — nothing is playing')
    }
//#endregion
