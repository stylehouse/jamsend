
import { KVStore } from '$lib/data/IDB.svelte'
import { _C, keyser, Modus, Stuff, TheC, type TheN, type TheUniversal } from '$lib/data/Stuff.svelte';
import { ThingIsms, ThingsIsms } from '$lib/data/Things.svelte.ts'
import { Selection, Travel } from '$lib/mostly/Selection.svelte';
import { erring, hak, Parserify, reverse } from '$lib/Y'
import { now_in_seconds, PeeringFeature, type PierFeature } from '../Peerily.svelte';
import type { PeeringSharing, PierSharing } from './Sharing.svelte';


// these One/Many things are given to a Things/Thing UI
// Shares/Share is the filesystem terminal
//  Selections/Selection are your collations

// ftp as a view to work with
//  makes guesswork to provide defaults, remote plots may inject
export class DirectoryModus extends Modus {
    F:PeeringSharing
    S:DirectoryShare//|AnyShare // the Thing we're hotwiring

    constructor(opt:Partial<DirectoryModus>) {
        super(opt)
        // the above super() / assign() doesn't set .F|S (javascript quirk?)
        Object.assign(this,opt)
    }


    // refresh the top level, etc
    // UI:Sharability(DirectoryShare) reacts here once DirectoryShare.started
    //  < GOING is DirectoryShare.refresh() and so forth
    // < and slowly dispatch everything else...
    async main() {
        // switch on (and clear) the debug channel
        this.coms = _C()
        // this sty
        await this.have_time(async () => {
            this.reset_interval()

            // < rewrite everything we're thinking about how to:
            await this.surf_nibs(this.S.list)

            // Modus_testcase(this)

            // < look within $scope of the Tree (start with localList) for...
        })
    }
    // sleep when possible
    hard = false
    toggle_gohard() {
        this.hard = !this.hard
        console.log("going hard: "+this.hard)
    }

    // < partition a travel into %nib**
    //  < and deduplicate|DRY from having an extra toplevel %nib replace.
    // look to (or initialise) and climb down into the top %DL
    async surf_nibs(DL) {
        if (!DL) throw "!DL"
        let was = null
        await this.replacies({
            base_sc: {nib:'dir',name:'/',DL:1},
            new_sc: () => ({DL,  est:now_in_seconds()}),
            middle_cb: async (n:TheC) => {
                if (was && was == n) {
                    debugger
                }
                if (was) {
                    debugger
                }
                was = n
                // sub coms
                n.coms = this.coms?.i({into:"surf_DLs"})
                // start recursing this %nib,DL**
                await this.Travel_DLs(n)
            }
        })
        // these always change!?
        // if (DL != n.sc.DL) throw "~DL"
    }

    // a big development.
    //  is farming off to process() of domesticating information
    // random challenges:
    //  are there any unawaited promises in my code?
    thetime = 0
    async Travel_DLs(n:TheC) {
        console.log(`Travel_DLs:`)
        let thetime = this.thetime += 1
        n.coms.i({twas_thetime:this.thetime})
        // advertise %Tree for UI:Strata
        await n.replace({Strata:1,match:1}, async () => {
            n.i({Strata:1,match:1}).is().i({Tree:1})
        })
        await n.replace({Strata:1,see:1}, async () => {
            n.i({Strata:1,see:1}).is().i({openity:1})
            n.i({Strata:1,see:1}).is().i({frontierity:1})
            n.i({Strata:1,see:1}).is().i({journey:1}) // j, the toplevel list of places to go
            n.i({Strata:1,see:1}).is().i({plodding:1}) // =j, stuff dribbling down
            n.i({Strata:1,see:1}).is().i({toured:1}) // =j, for D** within the journey
        })


        let Se = new Selection()
        let DS = new DirectorySelectivityUtils(this)
        // for aiming...
        let btw = `
            set interlinkage is going on here
            needs a scheme to wander around D** a reasonable amount per second
            
            > that comes from Se:Activation
                so to target where we're randomly wandering,
                another Selection:Activation building a D of paths to want to find
                //    which does a weird resolve onto the D** of Selection:Valley
                Act** we trace into
                but treat goners as failed-to-find
                and resurrect them as such after the resolve() of what's there
                //   ie we'd climb down Se:Valley D** in another Se:Activation
                //   another Selection.process() for targeting?
                //    
            
            or, simply do that resurrect|make as half-there step to D**
             from event handling
              which could start out as waiting for thetime++ every 6 blobs we look at
               and closing earlier branches of D** when more than 20 blobs are awake
             and ensure D** wanted wake up and find instructionsnext time around
            yes...
             since we can afford to wake everything
              lets not target Travels efficiently yet...
              it wants a lovely but tricky asyncing
               once more ballistic visuals are go


            possibly_expand_nib(T)
             adjusts according to %openity
              which we replace when event handling

        `

        
        // look for new things in it
        await Se.process({
            n,
            process_sc: {Se:'Valley',Tree:3,name:n.sc.name}, // initial $n/%Se,Tree, singular
                // should be matched by trace_sc


            match_sc: {nib:1,name:1},    // climbing $n%nib,name**
            each_fn: async (D:TheC,n:TheC,T:Travel) => {
                let bD = T.sc.bD
                if (n.sc.nib == 'dir') {
                    // valves for more $n/%nib,name**
                    await DS.possibly_expand_nib(T)
                }
            },


            // re-describe each n/* into D/*%Tree
            //  $D/* fills with each Dyn/$n*
            //   the D is one step above this n
            // D** is thence always fillable with other stuff, not of pattern_sc
            // < resolve() maybe could n.sc <-> D.sc.nid, a copy of n.sc
            //    nid being D's index of the foreign n.sc, the identity it is tracking
            //   and hopefully these new sort-of joins will +1 nicely
            //    like you'd work things out on paper
            trace_sc: {Tree:3},          // fabricating D%Tree**
            trace_fn: async (uD:TheC,n:TheC) => {
                let D = uD.i({Tree:3,name:n.sc.name})
                return D
            },
            // now for each of those, what can we see...
            traced_fn: async (D:TheC,bD:TheC,n:TheC,T:Travel) => {
                if (!bD || bD.sc.name != D.sc.name) {
                    if (bD) {
                        console.warn(`process Renamed ${bD.sc.name} -> ${D.sc.name}`)
                    }
                    T.sc.needs_doing = true
                }
                else {
                    // sleepable?
                    // return T.sc.not = 'sleepable'
                }
            },
            resolved_fn: async (T:Travel,N:Array<Travel>,goners:TheN) => {
                await DS.resolved_nibs(T,N,goners)
            },


            // everything that's going to be|wake inside (D|n)** is there|awake now
            //  so you can write other stuff in places
            done_fn: async (D:TheC,n:TheC,T:Travel) => {
                if (n.sc.nib == null) throw "not o %nib"
                if (n.sc.name == null) throw "not o %name"
                D.X_before && console.warn("Still transacting "+keyser(D))

                if (this.hard) T.sc.needs_doing = true

                if (T.sc.needs_doing) {
                    // no go?
                    await DS.intelligible_name(T)
                }
            },
        })

        
        // then more richocheting around of percolating waves of stuff
        Se.reverse(async (T:Travel) => await DS.percolating_ads(T))
    }

    
}

class Frontier extends Travel {
    constructor(opt={}) {
        // .c += opt
        super(opt)
    }
    async i_openity(D,openity:number) {
        await D.replace({openity:1},async () => {
            openity && D.i({openity})
        })
    }
}
class WanderingFrontier extends Frontier {
    journey = 0
    // flatlist endurance before everything doesn't want to open
    energy = 5

    give_up_fn?:Function
    async visit(D,T) {
        // D is not closed, count it as a journey
        this.journey += 1

        await D.replace({frontierity:1}, async () => {
            D.i({frontierity:this.journey})
        })
        if (!this.energy) return
        if (this.energy == this.journey) {
            await this.c.give_up_fn?.(D,T)
        }
        if (this.energy <= this.journey) {
            // from here on
            await this.i_openity(D,2)
        }
        else {
            await this.i_openity(D,3)
        }
    }
}

function Tdebug(T,title,say,etc) {
    let indent = T.c.path.map(T=>'  ').join('')
    let D = T.sc.D
    console.log(`${title} ${indent} ${D.sc.name}\t${say||''}`,...[etc].filter(n=>n != null))
}

class Dierarchy {
    // < keeping things around
    // < findable orphaned D** via path (fragments) and filesizes
    D_to_name(D) {
        return D.sc.name
    }
    D_to_path(D) {
        let path = D.c.T.c.path
        return path.map(T => this.D_to_name(T.sc.D))
    }
    i_path(D,j) {
        let i = 0
        for (let bit of this.D_to_path(D)) {
            j.i({path:bit,seq: i++})
        }
    }
    // does the journey flow into here
    async journeys_choose_D(T:Travel,oT:Travel) {
        let D = T.sc.D
        let seq = oT.c.path.length-1
        let oD = oT.sc.D
        let bit = this.D_to_name(oD)
        
        await oD.replace({journey:1},async () => {
            for (let j of (T.sc.journeys||[])) {
                // if we're currently within the parameters of the tour
                //  so it should flood into yonders
                let goes = D.o({plodding:j,tour:1})[0]
                if (goes && goes.sc.ends) goes = null

                // < seq=1 matches everything! what do we do about that...
                //    use an exotic unicode character in the code
                //     obscured by LieSurgery
                let pathbit = j.o({path:1,seq}).filter(n=>n.sc.seq == seq)[0]

                if (goes || pathbit) {
                    // Tdebug(T,'journey goesto',`journey: ${keyser(j)} seq:${seq}`,pathbit)
                    // wants to go here
                    oT.sc.journeys ||= []
                    oT.sc.journeys.push(j)
                }
            }
        })
    }
    // T%journeys/$j and D**%plodding go inward
    async journeys_affect_D(T:Travel) {
        let uD = T.up?.sc.D
        let D = T.sc.D
        // all %plodding copy down, noting if they're opening, ending etc
        let openness_suggestions:Array<number> = []
        let journey_gives_up:Array<TheC> = []
        for (let j of (T.sc.journeys||[])) {
            // have moved, using a D** ephemeral
            // gather plodding information
            await D.replace({plodding:1},async () => {
                // Tdebug(T,'journey affect',`journey: ${keyser(j)}`)
                let pls:TheN = uD?.oa({plodding:j})

                if (!pls) {
                    if (T != T.c.top) throw "plodding T!top"
                    // when there is nothing,
                    //  establish a shared energy budget for all D**
                    D.i({plodding:j,enthusiasmus:{journey:0,energy:5}})
                    // D** starts being inside the journey
                    D.i({plodding:j,tour:{DN:[D]}})
                }
                else {
                    for (let pl of pls) {
                        // whole lot of protocols carrying themselves into D**
                        let to = pl.sc.tour
                        if (to) {
                            if (to.ends) {
                                // don't do any more %%plodding here
                                openness_suggestions.push(2)
                                return
                            }
                            // tour += D
                            to.DN.push(D)
                            // < is this where to check where the journey ends?
                        }
                    }
                    for (let pl of pls) {
                        let en = pl.sc.enthusiasmus
                        if (en) {
                            // simulates going further
                            en.journey += 1
                            
                            if (en.energy == en.journey) {
                                // will be first next.
                                journey_gives_up.push(j)
                            }
                            if (en.energy <= en.journey) {
                                // from here on
                                openness_suggestions.push(2)
                            }
                            else {
                                openness_suggestions.push(3)
                            }
                        }
                        // copy into D**
                        D.i(pl.sc)
                    }
                }
            })

            for (let j of journey_gives_up) {
                // in addition to suggesting low-openness
                await this.journey_gives_up(j,T)
            }

            let most_awake = openness_suggestions.sort().pop()
            if (T != T.c.top && !most_awake) throw "there should be at least 1 %journey"
            await this.i_openity(D,most_awake)
        }
    }
    async stop_the_tour(j,T) {
        let D = T.sc.D
        let to = D.o({plodding:j,tour:1})[0]
        if (!to) throw "cancel!to"
        to.ends = D
        // < later siblings of D
    }
    async journey_gives_up(j,T) {
        let topD = T.c.top.sc.D
        let D = T.sc.D
        // note in %journey/%gaveup where it ends,
        //  ~~ %journey/%ends at a non-meaningful point
        //  which could become the next %journey,begins
        this.stop_the_tour(j,T)
        await j.replace({gaveup:1}, async () => {
            // ~~ %journey/%path
            let j = topD.i({gaveup:1})
            this.i_path(D,j)
        })
    }


    async i_openity(D,openity:number) {
        await D.replace({openity:1},async () => {
            openity && D.i({openity})
        })
    }

}
type TheD = TheC
class DirectorySelectivityUtils extends Dierarchy {
    M:Modus
    constructor (M) {
        super()
        this.M = M
    }
    get thetime() {
        return this.M.thetime
    }
    async resolved_nibs(T:Travel,N:Array<Travel>,goners:Array<TheD>) {
        for (let oT of N) {
            await this.journeys_choose_D(T,oT)
            await this.journeys_affect_D(oT)
        }

        for (let go of goners) {
            // < keep their D** hanging around, subsiding...
        }
    }
    // for n%nib:dir only
    async possibly_expand_nib(T:Travel) {
        let {D,bD,n} = T.sc
        let time = this.thetime
        let topD = T.c.top.sc.D

        if (!T.sc.frontier) {
            if (T == T.c.top) {
                // where we aim to start doing it
                if (!topD.oa({journey:1})) {
                    // start at the top
                    let j = topD.i({journey:'auto',begins:1})
                    this.i_path(D,j)
                }
                T.sc.journeys = topD.o({journey:1})
                // you might address the top of the %Tree
                await this.journeys_affect_D(T)

                // first time in, just wander
                // < GOING in favour of the journey
                let F = T.sc.frontier = new WanderingFrontier({
                    give_up_fn: async (D,T) => {
                        return
                        await topD.replace({journey:'auto',ends:1}, async () => {
                            let j = topD.i({journey:'auto',ends:1})
                            this.i_path(D,j)
                        })
                    }
                })
            }
            else {
                let journeys = T.sc.journeys
                // < %journeys already be aimed by T.up at resolved_fn

                T.sc.frontier = T.up.sc.frontier
            }
        }
        let F = T.sc.frontier as WanderingFrontier
        await F.visit(D,T)

        D.i({frontierity:"IS",time})





        let openity = D.o({openity:1},1)[0] || 3
        if (openity <3) {
            return T.sc.not = 'chilling'
        }

        // < sensible timings of:
        await this.expand_nib(n)
        // this.collapse_nib(n)
    }

    
    async expand_nib(n:TheC) {
        const DL:DirectoryListing = n.sc.DL
        await DL.expand()

        // i /*%nib:dir,...
        let uDL = DL
        await n.replace({nib:1,name:1},async () => {
            for (const DL of uDL.directories) {
                let di = n.i({nib:'dir',name:DL.name,DL,thetime:this.thetime})
            }
            for (const FL of uDL.files) {
                n.i({nib:'blob',name:FL.name,FL,thetime:this.thetime})
            }
        })
    }
    async collapse_nib(n:TheC) {
        const DL:DirectoryListing = n.sc.DL
        DL.collapse()
        // forget $n/**
        await n.replace({nib:1,name:1},async () => {
        })
    }


    // guessing, implying structure
    // upwards, propagate D**%readin=$aspect about the tracks
    // Artist get %readin:type,val:artist
    async intelligible_name(T:Travel) {
        let {D,n} = T.sc
        let i_readin = (t:string,s:TheUniversal) => {
            D.i({readin: t, thetime: this.thetime, ...s})
        }
        await D.replace({readin: 1}, async () => {
            const name = n.sc.name as string;
            const p = new Parserify(name);
            
            if (n.sc.nib === 'blob') {
                let format, type, seq

                // Extract and index file extension
                if (p.p(/\.([a-z0-9]{3,4})$/i)) {
                    format = p[1]!.toLowerCase();
                    i_readin('name', {format});
                    
                    // Determine if it's a track
                    if (format.match(/^(mp3|wav|ogg|m4a|aac|flac|opus|webm|oga|mkv|mka|mp4)$/)) {
                        type = 'track'
                        i_readin('name',{type});
                    }
                }
                
                // Extract and index track number from start
                if (p.p(/^(\d+)[\s.\-_]+/, '')) {
                    seq = parseInt(p[1]!, 10);
                    i_readin('name', {seq});
                }
                
                // Clean up punctuation noise at the edges
                p.p(/^[\s\-_\.]+/)
                p.p(/[\s\-_\.]+$/);
                // Collapse multiple spaces
                while (p.p(/  +/,' ')) 1
                
                // Final cleaned name
                const cleaned_name = p.s.trim();
                i_readin('name', {name: cleaned_name});

                if (type == 'track') {
                    // coherent enough!
                    //  make %%art out of all this
                    //   unlikely to be wrong at this level,
                    //    we may regard more context when hoisting it as %%ads
                    i_readin('art',{track:cleaned_name,seq,format})
                }
            }
            
            if (n.sc.nib === 'dir') {
                // Directory handling depends on finding D**%readin:type,val:track somewhere
                //  extrapolate outwards to become D^^%readin:type,val:artist
                // note D.replace() is happening, so we .bo() the previous time
                //  during replace(), only the newly placed items are findable with .o()
                
                let said_album = 0
                let said_artist = 0
                let said_collection = 0
                for (let oD of D.bo({Tree:3})) {
                    // D:Album/Tree:Track*
                    if (oD.oa({readin:1,type:'track'})) {
                        // tracks imply we are an album
                        if (!said_album++) {
                            i_readin('inners',{type:'album'})
                        }
                    }
                    if (oD.oa({readin:1,type:'album'})) {
                        // albums imply we are an artist
                        if (!said_artist++) {
                            i_readin('inners',{type:'artist'})
                        }
                    }
                    if (oD.oa({readin:1,type:'artist'})) {
                        // artists imply we are a collection
                        if (!said_collection++) {
                            i_readin('inners',{type:'collection'})
                        }
                    }
                }

                // < be more tentative, guess, configure what character
                // notice '0 chill' etc genre|classification|purpose directories
                if (p.p(/^(0|-) /i)) {
                    if (!said_collection++) {
                        i_readin('inners',{type:'collection'})
                    }
                }

                // 
                if (said_album && said_artist
                    || (said_album || said_artist) && said_collection) {
                    // an artist dir with a few loose tracks?
                    D.o({readin:1,type:'album'}).map(n => D.drop(n))
                    said_collection
                        && D.o({readin:1,type:'artist'}).map(n => D.drop(n))
                }


                i_readin('name', {name: p.s.trim(), thetime: this.thetime});
            }
        });
    }

    // upwards propagate more stuff
    async percolating_ads(T:Travel) {
        let {D} = T.sc
        // random flood of %ads hoisted about tracks
        // < do in a second traversal of D** and incorporate how the hierarchies have flopped out
        //    including from top-down
        //    
        // < which pseudo-randomly shuffles what to talk about at the top level
        // 
        // < can make ads about:
        //    D/oD/%readin=type,val=track|album|artist

        //    D/oD/%readin=track
        //    D/oD/%readin=album
        //    D/oD/%readin=artist
        // the fact we also D%readin=

        // < prefers to advertise albums

        // < guess if we're "Artist - Album (1979)" based on the surroundings
        // haphazardly extend up, or spawn whole, %artist,album,track tuples
        await D.replace({ads: 1}, async () => {
            // look at here
            let meta = {}
            let gather_meta = (type:string) => {
                let name = D.boa({type:type,readin:1})
                        && D.boa({name:1,   readin:'name'},1)[0]
                if (name != null) {
                    meta[type] = name
                }
            }
            gather_meta('collection')
            gather_meta('artist')
            gather_meta('album')
            gather_meta('track')

            // meta accumulates when hoisted, on ads
            let i_ads = (t:string,sc={}) => {
                // set ads twice for object property ordering...
                //   because sc may contain it from below
                //  ie every %thing,with,values is a thing primarily
                return D.i({ads:0,...meta,...sc,ads:t,
                     thetime:this.thetime})
            }

            let some_inners = false
            for (let oD of D.bo({Tree:3})) {
                // ads build up locality as they hoist
                let few = 3
                oD.oa({ads:1})?.map((n:TheC) => {
                    if (few-- < 1) return
                    i_ads('beyond',n.sc)
                    some_inners = true
                })
            }

            if (hak(meta)) {
                // we could start advertising this thing!
                if ('prand' || 'track') {
                    // starts with|as any %%art found here
                    //  so individual track info as such
                    // < folder.jpg?
                    let arts = D.boa({readin:'art'})?.map((n:TheC) => ({...n.sc}))
                        || [{noart:1}]
                    for (let art of arts) {
                        delete art.readin
                        i_ads('here',art)
                    }
                }
            }
        });
    }

}



//#region *Listing
// one file
export class FileListing {
    up: DirectoryListing
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
type name_haver = {name:string}
function sort_by_name(a:name_haver,b:name_haver,k?:string) {
    k ||= 'name'
    return a[k] > b[k] ? 1 : a[k] < b[k] ? -1 : 0
}
// many files|dirs
export class DirectoryListing {
    handle:any
    name: string
    up?: DirectoryListing
    files: FileListing[] = $state([])
    directories: DirectoryListing[] = $state([])
    
    expanded = $state(false);
    
    constructor(init: Partial<DirectoryListing> = {}) {
        Object.assign(this,init)
    }
    async expand() {
        if (!this.handle) throw erring('No directory access')
        // if already expanded, it means return
        this.files = []
        this.directories = []
        // < tabulates|reduces into a Selection later
        for await (const entry of this.handle.values()) {
            try {
                let generally = {
                    up: this,
                    name: entry.name,
                }
                if (entry.kind === 'file') {
                    const file = await entry.getFile();
                    this.files.push(new FileListing({
                        ...generally,
                        size: file.size,
                        modified: new Date(file.lastModified),
                    }));
                } else {
                    // < dirs don't have mtime. put a cache of Stuff in each one?
                    this.directories.push(new DirectoryListing({
                        handle: entry,
                        ...generally,
                    }));
                }
            } catch (err) {
                console.warn(`Skipping problematic entry ${entry.name}:`, err);
            }
        }
        this.files = this.files.sort(sort_by_name)
        this.directories = this.directories.sort(sort_by_name)
        this.expanded = true
        return this
    }
    collapse() {
        if (!this.expanded) return;
        this.files = []
        this.directories = []
        this.expanded = false;
    }

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
export class RemoteListing extends DirectoryListing {
    PF:PierSharing
    name: string
    up?: RemoteListing
    files: FileListing[] = $state([])
    directories: RemoteListing[] = $state([])
    expanded = $state(false);
    
    constructor(init: Partial<RemoteListing> = {}) {
        Object.assign(this,init)
    }
    async expand() {
        // < ask PF.send
    }
}
// < pass a bunch of Directory|Remote specifics in to Sharability.svelte
export type AnyShare = RemoteShare | DirectoryShare
export class RemoteShare extends ThingIsms {
    async start() {}
}

//#region DirectoryShare
// Individual share - like a PierFeature but for directories
export class DirectoryShare extends ThingIsms {
    fsHandler: FileSystemHandler
    
    // State
    started = $state(false)

    // private state
    modus?:Modus = $state()

    // a single toplevel DL:'/',  DirectoryListing thing
    get list():DirectoryListing {
        return this.started && this.fsHandler.list
    }
    
    // was localList
    
    persisted_handle:KVStore
    constructor(opt) {
        super(opt)
        let {name,F}:{name:string,F:PeeringFeature} = opt

        this.persisted_handle = F.spawn_KVStore(`share handle`,name)
        
        this.fsHandler = new FileSystemHandler({
            share: this,
            storeDirectoryHandle: async (handle) => {
                await this.persisted_handle.put(handle)
            },
            restoreDirectoryHandle: async () => {
                const handle = await this.persisted_handle.get()
                if (!handle) return null

                try {
                    // Verify the handle is still valid
                    const permission = await handle.queryPermission({ mode: 'readwrite' })
                    
                    if (permission === 'granted') {
                        return handle
                    } else if (permission === 'prompt') {
                        // Try to request permission again
                        const newPermission = await handle.requestPermission({ mode: 'readwrite' })
                        if (newPermission === 'granted') {
                            return handle
                        }
                    }
                    
                } catch (err) {
                    console.warn('Directory handle validation failed:', err)
                    // < huh?
                }
                // maybe drop this stored object?
                await this.persisted_handle.delete()
                return null
            },
        })
    }
    async start() {
        try {
            await this.fsHandler.start()
            this.start_post(true)
        } catch (err) {
            throw erring(`Failed to start share "${this.name}"`, err)
        }
    }
    // user interaction required
    async click_start() {
        await this.fsHandler.requestDirectoryAccess()
        this.start_post()

    }
    async start_post(retriable=false) {
        if (this.fsHandler.started) {
            this.started = true
            console.log(`DirectoryShare "${this.name}" started`)
        }
        else {
            if (retriable) {
                // the handle failed to resume, perhaps it is new
                this.i_action({label:'open share', class:'big', handler: async () => {
                        await this.click_start()
                        this.i_action({label:'open share'},true)
                    }})
            }
            else {
                throw erring(`Share not starting! "${this.name}"`)
            }
        }


    }
    async stop() {
        try {
            await this.fsHandler.stop()
            this.started = false
            console.log(`DirectoryShare "${this.name}" stopped`)
        } catch (err) {
            throw erring(`Failed to stop share "${this.name}"`, err)
        }
    }

    // < used by FileList, which is perhaps not the future...
    async refresh() {
        if (!this.started) return
        // only does the top level
        await this.fsHandler.list.expand()
    }

    // Get file reader from this share's directory
    async getFileReader(filename: string) {
        return await this.fsHandler.getFileReader(filename)
    }

    // Write file to this share's directory
    async writeFileChunks(filename: string) {
        return await this.fsHandler.writeFileChunks(filename)
    }
}

//#region DirectoryShares
// Collection of DirectoryShares with persistence
export class DirectoryShares extends ThingsIsms {
    started = $state(false)
    constructor(opt) {
        super(opt)
        this.set_table(`shares`)
    }


    async thingsify(opt) {
        return new DirectoryShare(opt)
    }
    // < what becomes of this object? should it be a saved stash situation?
    async autovivify(opt) {
        opt.name = 'music'
    }
}



//#region fs

interface FileReader {
    size: number;
    iterate: (startFrom?: number) => AsyncGenerator<ArrayBuffer>;
}

const CHUNK_SIZE = 16 * 1024;          // 16KB chunks for file transfer
type FileSystemDirectoryHandle = any
class FileSystemHandler {
    // handle for the root directory of the share
    handle:FileSystemDirectoryHandle|null
    // handles for any file being read
    // < or written to?
    // < io limits per share? so leech swarms share what is going around
    file_handles = new Map()
    // up to share owning this
    share: DirectoryShare
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
        this.list = new DirectoryListing({handle:this.handle,name:'/'})

    }
    async stop() {
        // Clear all stored handles
        this.file_handles.clear();
        this.handle = null;
        this.list = null;
        this.started = false
    }


    // go somewhere
    async getFileHandle(filename: string): Promise<FileSystemFileHandle> {
        if (!this.handle) throw erring('No directory access')
        const handle = await this.handle.getFileHandle(filename);
        this.file_handles.set(filename, handle);
        return handle;
    }

    // First get file info and iterator factory
    async getFileReader(filename: string, chunkSize = CHUNK_SIZE): Promise<FileReader> {
        if (!this.handle) throw erring('No directory access')

        const fileHandle = await this.handle.getFileHandle(filename);
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
        if (!this.handle) throw erring('No directory access')

        const fileHandle = await this.handle.getFileHandle(filename, { create: true });
        const writable = await fileHandle.createWritable();
        this.file_handles.set(filename, fileHandle);
        return writable;
    }









}

