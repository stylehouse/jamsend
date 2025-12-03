import { now_in_seconds, PeeringFeature } from "$lib/p2p/Peerily.svelte";
import { SvelteMap, SvelteSet } from "svelte/reactivity";
import type { KVStore } from "./IDB.svelte";
import type { ThingIsms } from "./Things.svelte";
import type { Travel } from "$lib/mostly/Selection.svelte";
import { isar, map, throttle } from "$lib/Y";
import { untrack } from "svelte";
import type { Matchy, Strata } from "$lib/mostly/Structure.svelte";

let spec = `

what Stuff is (~~ brackio)
   is the ability to C.i(inC)
    using C..X... = x, x.z = [inC+]
    the X... indexes group like stuff (from C.sc.*)
     as well as simply listing all C/*
    they can make trees by many of those steps (C/C/C/C)
    or flatly being a pool of information to query
     also known as baskets
    < or being a hybrid, using o() illusions to union subsets
   it seems to go to form:
    < Modus of advancing states with methods (~~ Super)
    < Selection (~~ C**, nodes)
     types of hierarchy (edges)
      ie whether theyre basically all up or down
      the clone|mirror plane...
      origin
      continuity of identity (~~ resolve $n)
       this is going too far!

just want a nice light medium to CRUD with
    for the thinky process supporting music piracy
    that can be persisted, somewhat...






use cases:
  build a scheme to
   inflate and annotate a directory tree
    slow the directory listing iterator

`;



//#region TheX
`
      =write or read (autovivificatorialy)
        X/$someindex ||= x += /$n
       leading to x, another|inside X via $someindex
       x doesnt know what indexes it is in
        &Xsomp etc make ax = {someindex=value,x,n...}
        joins|varies by x.z/r aka x/$n or just /$n,
         the members being added to x locatable space
       < X_n, X_z for duplicating|not X.z?
      =cut 
`;

// storage class with methods
class TheX {
    // we may be inside another X
    //  aka an x, as in X...x
    up?: TheX;

    // by the usual names:
    k?: {}
    v?: []
    vs?: []
    z?: TheN

    // tried to make .z state but... it loses the first row? but is reactive
    serial_i = $state(1)
    bump_version() {
        this.serial_i = this.serial_i*1 + 1
    }

    // X/$k +$n
    i_k(k: string, n?: TheC|null, kf?: string): TheX {
        this.bump_version()
        kf = kf || 'k';
        this[kf] = this[kf] || {};
        const x: TheX = this[kf][k] = this[kf][k] || new TheX();
        x.up = this;
        x.i_z(n);
        return x;
    }

    // X.z +$n - dupey accumulator, makes /$n (rows at x)
    i_z(n?: TheC|any|null, kf?: string) {
        if (!n) return;
        kf = kf || 'z';
        this.bump_version()
        const N = this[kf] = this[kf] || [];
        if (!Array.isArray(N)) throw "!ar";
        N.push(n);
        // robustly
        if (N.length > 6000) throw "giant stuff";
    }

    // X/$v +$n
    i_v(v: any, n: TheC, kf?: string): TheX | null {
        kf = kf || 'v';
        return this.i_refer(v, n, kf);
    }
    // indexing objects, or anything
    // < decide based on the v type (in o or i) whether to use
    //    a third index for key-ish values...
    // < value array should be a WeakMap, preventing the need for two indexes
    i_refer(v: any, n?: TheC|null, kf: string, kfs?: string): TheX | null {
        this.bump_version()
        // the X.something for the array of values
        kfs = kfs || kf + 's';
        // array mirroring the values with an x for that value
        if (!kf) throw "named";
        
        // by id of the value
        const fs = this[kfs] = this[kfs] || [];
        let vi = fs.indexOf(v);
        
        // if $n=null you will inflate an empty /$n space
        if (vi < 0) vi = fs.push(v) - 1;
        
        const f = this[kf] = this[kf] || [];
        const x: TheX = f[vi] = f[vi] || new TheX();
        x.up = this;
        x.i_z(n);
        return x;
    }

    // X reading, returning x to Stuff
    o_kv(k:string,v:1|any,q:any):TheX|undefined {
        // Look up the key in X.k
        let x = this.k && this.k[k] ? this.k[k] : null;
        
        // wildcard where {$k:1}
        if (x && (v != 1 || q?.notwild)) {
            // Find the value index
            let vi = x.vs ? x.vs.indexOf(v) : -1;
            if (vi < 0) return; // continues to next iteration
            x = x.v && x.v[vi] ? x.v[vi] : null;
        }

        return x
    }
}



//#region Stuff
// a class of activities you can make in a C
class StuffIO {
    c: TheEmpirical
    // this would be in c but it needs $state():
    X:TheX = $state()
    // while doing replace(), hops everything over to:
    X_before?:TheX
    Xify() {
        this.X ||= new TheX()
        // via Stuff.replace(), X is a page that turns, keep version
        if (this.X_before) {
            this.X.serial_i = this.X_before.serial_i
            this.X.bump_version()
        }
    }
    get version() {
        return this.X?.serial_i || 0
    }
    // might have a channel to log (.i()) algorithm mumble to
    coms?: TheC
    // delete a C (filter it out of results)
    drop(n:TheC) {
        if (!n) return
        if (!n.sc) throw "!drop(C)"
        n.c.drop = 1
        this.X.bump_version()
    }

    // attachment, materialisation. indexes build up, forming X/.../$n to be with
    i(n: TheC|TheUniversal) {
        n = _C(n)
        this.Xify()
        // failed ideas here include:
        //   peeling a json-ish string n, chaining from s=TheC, environmental awareness
        // new, able to fail ideas:
        //  everything can C.i(D), see TheC extends Stuff
        //   < but what if D.sc.in!=C?
        //      a third party, ancestor, knowing about the relation?
        //   lets not have a D.sc.in, uplinks are harder to garbage collect?
        

        // do your basic index-everything - copy info from these $n to X/$k/$v
        // everything we have
        //  the below i_k and i_v also do i_z where they end up
        this.X.i_z(n);

        let keys = Object.entries(n.sc || {})
        if (!keys.length) throw "i nothing"
        keys.forEach(([k, v]) => {
            // the keys
            const kx = this.X.i_k(k, n);
            
                // this is under X/$k
                // have their values via unique id  
                kx.i_v(v, n);
            // so you have to look up all keys if you want all values
        });

        // < is a convenient time to return an up-to-date picture of what's at all those locations
        //    a /$k /$v
        return n
    }

    // look for these keys if $key=1, or the value as well.
    // the X/$k(/$v) /$n give us a list of $n
    //   which we then just grep for the rest of properties
    //  as opposed to:
    //   > thinking about going into particular X/$k/$v, depending on $key=1
    //   > joining many reads on the X/$k/$v table, which is just uniq(/$n)
    // o(...)[0] for the first row
    // q||.one_column_mode =
    //  $k returns [v+] in that column, from the resultant /$n/.sc.$k
    //  1 returns the first column mentioned in sc (javascript hashes are ordered)
    //  0 returns the first value of the first column (in the query)
    o(sc?:TheUniversal,q?:number|any):TheN|TheC|any|undefined {
        sc ||= {}
        // < q might be a Travel...?
        if (typeof q == "number") q = {one_column_mode:q}
        q ||= {}
        this.Xify()

        let M = this.o_query(sc,q)
        return this.o_results(M,sc,q)
    }
    // return arrays, empty if no rows, good for iterating .forEach()
    bo(c?:TheUniversal,q?):TheN|TheC|any {
        if (typeof q == "number") q = {one_column_mode:q}
        q ||= {}
        q.X ||= this.X_before
        if (!q.X) return []
        return this.o(c,q)
    }
    // returning null rather than empty arrays if no rows
    //  less good for iterating .forEach(), more good for boolean logic
    oa(c?:TheUniversal,q?):TheN|TheC|any|undefined|null {
        return nonemptyArray_or_null(this.o(c,q))
    }
    boa(c?:TheUniversal,q?):TheN|TheC|any|undefined|null {
        return nonemptyArray_or_null(this.bo(c,q))
    }

    o_query(sc:TheUniversal,q:any) {
        q ||= {}
        q.X ||= this.X
        // results
        let M:TheN = []
        // Process each key-value pair in sc
        let query_params = Object.entries(sc || {})
        if (!query_params.length) {
            // wants everything
            M = q.X.z?.filter(n => this.n_matches_star(n)) || []
        }

        let amongst:TheN;
        query_params.forEach(([k, v]) => {
            // might have indexing, only for the first one
            if (!amongst) {
                let x = q.X.o_kv(k,v);
                // start resulting with items here in x.z
                //  x.z = the /$n at the end of whatever expression
                (x && x.z || []).forEach(n => {
                    if (this.n_matches_kv(n,k,v)) {
                        // includes result
                        if (!M.includes(n)) M.push(n)
                    }
                });
            }
            else {
                // filter results we are already joined to
                amongst.forEach(n => {
                    if (!this.n_matches_kv(n,k,v)) {
                        // disincludes results
                        M = M.filter(out => out != n)
                    }
                });
            }
            
            amongst = M;
        });
        return M
    }
    // make subsets of the results easier to get
    o_results(M:TheN,sc:TheUniversal,q:any) {
        if (q.one_column_mode != null) {
            q.one_value_mode = false;
            if (q.one_column_mode == 0) {
                q.one_value_mode = true;
                q.one_column_mode = 1;
            }
            if (q.one_column_mode == 1) {
                // Get first key from sc (equivalent to haks(c)[0])
                q.one_column_mode = Object.keys(sc)[0];
            }
            
            let N = M;
            M = [];
            
            N.forEach(n => {
                let v = n.sc && n.sc[q.one_column_mode];
                // also makes sure that value isn't null, even if you wildcard it
                if (v == null) return;
                M.push(v);
            });
            
            if (q.one_value_mode) return M[0];
        }
        
        return M
    }
    matches(sc:TheUniversal) {
        let n:TheC = this
        let query_params = Object.entries(sc || {})
        for (let [k, v] of query_params) {
            if (!this.n_matches_kv(n,k,v)) {
                return false
            }
        }
        return true
    }
    private n_matches_star(n:TheC) {
        if (n.c.drop) return false
        return true
    }
    private n_matches_kv(n: TheC, key: string, value: any): boolean {
        if (!this.n_matches_star(n)) return false;
        
        if (!n.sc || !n.sc.hasOwnProperty(key)) {
            return false;
        }
        
        // wildcard where {$k:1}
        if (value == 1) return true
        
        return n.sc[key] === value;
    }
    // whole seconds of oldness getter
    ago(gk) {
        let time = this.sc[gk]
        if (time == null) return Infinity
        return now_in_seconds() - time
    }
}

class StuffGames extends StuffIO {
    // keep a value next to a key
    //  need some other id in the tuple
    //   just eg %openity=$v won't resolve to itself when it changes
    //  eg deliver one final-most bit of %openity advice to your Se.each_fn
    async i_kv(k:string,v:any) {
        let D = this as TheC
        let c = {}
        c[k] = 1
        let n
        await D.replace(c,async () => {
            // v=0 shall not exist
            n = v && D.i({...c,v})
        })
        return n
    }
    o_kv(k:string) {
        let c = {}
        c[k] = 1
        return  this.o(c)[0]
    }
}

//#endregion
//#region Stuff.replace
export class Stuff extends StuffGames {
    // this C has Isness, C/* are there already and don't recycle them.
    // marks this C as going to have inners already when resolve() commits
    //  so don't resume its C/* from before
    is() {
        this.c.Isness = 1
        return this
    }
    // replace one thing
    // < GONER? silly?
    async r(pattern_sc:TheUniversal,sc?:TheUniversal):Promise<TheC> {
        if (!sc) {
            // make an %all:1,wildcards:1 pattern
            sc = pattern_sc
            if (isar(sc)) {
                pattern_sc = sc[0]
            }
            pattern_sc = map(() => 1, pattern_sc)
        }
        let C
        await this.replace(pattern_sc, async () => {
            let N = isar(sc) ? sc : [sc]
            for (let s of N) {
                C = this.i(s)
            }
        })
        return C
    }

    // resolved C usually resume C/*
    resume_X(a,b) {
        if (!b.c.Isness) {
            b.X = a.X
        }
    }

    // redo everything or a subset that we replace things around
    //  inside fn(),
    //   bo() can be used to look at the before time
    //   o() will only have what we've added so far
    //  
    async replace(pattern_sc:TheUniversal,fn:Function,q?:any) {
        if (this.X_before) throw `already X_before, still doing another replace()`
        q ||= {}
        // move it aside and regerate another X
        //  ensuring we have an X_before the first time
        //   so we can use it for locking, see have_time()
        this.Xify()
        this.X_before = this.X
        this.X = null
        this.Xify()

        // may select a subset to replace
        let partial:TheN|null = null
        if (Object.keys(pattern_sc).length) {
            partial = this.bo(pattern_sc)
        }

        try {
            // do the work, materialising atoms
            const result = await fn()
            
            // now all that's in X should be what's new in partial
            if (!q.fresh) {
                // let's resolve what's the same (each C having an itself in before)
                //  and then give each C.X from itself before
                // so by default, replacing a C keeps its C/**

                // make a series of pairs of $n across time
                let pairs = await this.resolve(this.X,this.X_before,partial)
                let resolved_pairs = ([a,b]) => {
                    if (a && b) {
                        let innered = b.X?.z?.length
                        if (innered && !b.c.Isness) {
                            // < if they have b.i() already? post-hoc resolve()?
                            console.error("Ohno! something already in: "+keyser(this)
                                +"\n eg: "+keyser(b.X.z[0]))
                        }
                        this.resume_X(a,b)
                    }
                    q.pairs_fn?.(a,b)
                }
                pairs.forEach(resolved_pairs)
            }

            if (partial) {
                // put everything else back in
                this.bo().forEach(n => {
                    if (partial?.includes(n)) return
                    this.i(n)
                })
            }
            
            return result

        } catch (error) {
            // rollback data changes
            this.X = this.X_before

            console.error('Transaction failed:', error)
            throw error

        } finally {
            this.X_before = undefined
            // something probably changed
            //  chase up observers, eg Stuffing, who aren't waiting
            this.X?.bump_version()
        }
    }

    // regard new|gone in here
    // assumes we're going to uniquely identify everything easily
    //  by comparing n.sc.*,
    //   n/* or n.sc.*.*
    // < we could resolve gradually, even one-at-a-time
    // make a series of pairs of $n across time
    async resolve(X:TheX,oldX:TheX,partial:TheN|null) {
        if (!oldX?.z?.length) {
            // everything is new
            return (X.z||[]).map(n => [null,n])
        }
        // partial may be a set of old things we're replacing
        //  if partial, there's other stuff in oldX we're not replacing
        // but X is always the new stuff only
        let partsof = (N:TheN) => {
            return N.filter(n => !partial || partial.includes(n))
        }
        // debuggery
        let coms = this.coms

        // collect islands of same k+v
        let Over = _C({})
        Over.Xify()

        let kv_iter = (X,fn) => {
            Object.entries(X.k||{}).forEach(([k,kx]) => {
                kx = kx as TheX
                // eg k=nib, we're dividing nib=dir|blob
                Object.entries(kx.v).forEach(([i,vx]) => {
                    let v = kx.vs[i]
                    fn(k,kx,v,vx)
                })
            })
        }

        // iterate the new k/v structure

        kv_iter(X,(k,kx,v,vx) => {
            // eg k=nib,v=dir

            // expect some string property will be more disambiguating
            // < ref matching. would be slower. do on the remainder?
            let vtype = typeof v == 'object' ? 'ref' : 'string'
            if (vtype == 'ref') return

            // look for the same k/v
            let oldvx = oldX.o_kv(k,v,{notwild:1})
            if (!oldvx) return // none

            if (!oldvx.z.length) throw `should always be some /$n`
            let old_z = partsof(oldvx.z)
            if (!old_z.length) {
                // may share kv with the out-group
                // < an odd occasion to study in testing
                // console.warn("Perhaps your replace() pattern_sc doesn't match the new atoms?",{X,partial})
                return
            }
            vx.z.forEach((n:TheC,i:number) => {
                // any neu%nib:dir could match any old%nib:dir
                // via /$v:neu /$k/$v:stringval /$n=old
                let nkvx = Over.X.i_v(n,null,'neu')
                    .i_k(k).i_v(v,null)
                old_z.forEach(oldn => nkvx.i_z(oldn))
            })
        })



        let matchi = 1
        // /$v:neu /$k/$v:stringval /$n=old
        Object.entries(Over.X.neu||{}).forEach(([i,_neux]) => {
            let n = Over.X.neus[i]
            let neux = _neux as TheX
            kv_iter(neux,(k,kx,v,vx) => {
                let possible = vx.z
                let unambiguity = 1 / possible.length
                // for %nib:dir x20 matching less than %name:veryunique x1
                // /$neu /$ambiguity=0.234 /$n=old
                let rated = neux.i_k(unambiguity,null,'unambiguity')
                rated.z = [...vx.z]
                // /$ambiguity=0.234 /$n=neu for ordering matches amognst all $neu
                Over.X.i_k(unambiguity,n,'unambiguity')

            })
        })
        let sort_unambiguity = (X) => {
            return Object.keys(X.unambiguity||{}).sort().reverse()
        }

        // pairs of [oldn,n], eventual result
        let pairs = []
        // $neu dwindling to actual new items
        let unfound:Array<TheC> = [...(X.z||[])]
        // $oldn that become paired with a $neu
        let claimed:Array<TheC> = []
        let claim = (oldn,n) => {
            pairs.push([oldn,n])
            unfound = unfound.filter(m => m != n)
            claimed.push(oldn)
        }

        // sort by unambiguity
        // /$ambiguity=0.234 /$n=neu/$ambiguity=0.234 /$n=old
        let ratings = sort_unambiguity(Over.X)
        ratings.forEach((unambiguity) => {
            let x = Over.X.unambiguity[unambiguity]
            x.z.forEach((n:TheC) => {
                if (!unfound.includes(n)) return

                // /$v:neu
                let neux = Over.X.i_v(n,null,'neu')
                if (!neux?.k) throw `algo!?k`
                let rated = neux.i_k(unambiguity,null,'unambiguity')
                if (!rated.z.length) throw `algo!?z`
                rated.z.forEach((oldn) => {
                    if (claimed.includes(oldn)) return
                    // < I fade out here. maybe with a better io notation...
                    //   sorting through arrangements any more is...
                    //    one of those has-been-done academic things
                    // let oldnx = Over.X.i_v(oldn,n,'old')
                    // if (oldnx.z.length > 1) coms&&coms.i({ambiguo:n,neu:keyser(n),oldn,old:keyser(oldn)})
                    // < pile up neux/$maybe=oldn from many vx
                    //    to union many takes on $oldn with decreasing pickiness
                    //     depending on everyone else's contest...
                    //    lots of permuting?
                    // or just accept the first one?
                    //  they are sorted for uniqueness, won't re-claim...
                    claim(oldn,n)
                })
            })
        })

        // what's left in X_before (that we are partial to replacing)
        let gone = partsof(oldX.z||[])
            .filter(oldn => !claimed.includes(oldn))
        
        // log it all
        if (0 && coms) {
            pairs.forEach(([oldn,n]) => coms.i({old:keyser(oldn),neu:keyser(n)}))
            unfound.forEach((n) => coms.i({spawn:keyser(n)}))
            gone.forEach((n) => coms.i({gone:keyser(n)}))
        }

        // new stuff
        unfound.forEach((n) => pairs.push([null,n]))
        // gone stuff
        gone.forEach((oldn) => pairs.push([oldn,null]))

        return pairs
    }
}

export function keyser(n:TheC) {
    let la:Array<string> = []
    Object.entries(n.sc).forEach(([k,v]) => {
        la.push(k+":"+objectify(v))
    })
    return la.join(", ")
}








//#region Stuffing
// a look at some Stuff
//  to come springing out of Modus.
// < the universal, an experiential perspective
// Stuffing - whole island of Stuff
//  / Stuffusion - the compressed identity of some rows
//  / Stuffziad - the k:v presentation, may be a compressed identity
//  / Stuffziado - one value

// whole island of Stuff
export class Stuffing {
    Stuff:Stuff
    groups = new SvelteMap()
    started = $state(false)

    matchy?:Matchy
    constructor(Stuff:Stuff,matchy:Matchy) {
        this.Stuff = Stuff
        this.matchy = matchy
        //  svelte docs: You can use $effect anywhere,
        //   not just at the top level of a component, 
        //   as long as it is called while a parent effect is running.
        this.slowly_brackology = throttle(() => this.brackology(),200)

        $effect(() => {
            if (this.Stuff.version) {
                // may drop out here, UI:Stuffing reacts to .started
                if (this.Stuff.X_before) return //console.warn("Stuffing waits for X_before")
                // console.log("reacting to Stuff++")
                setTimeout(() => this.slowly_brackology(), 1)

            }
        })
    }
    get_matching_rows() {
        let matches = this.matchy?.see || []
        if (!matches.length) matches = [{}]
        let N = []
        for (let sc of matches) {
            for (let n of this.Stuff.o(sc)) {
                if (N.includes(n)) continue
                N.push(n)
            }
        }
            
        let unmatches = this.matchy?.hide || []
        let from = N.length
        for (let sc of unmatches) {
            N = N.filter((n:TheC) => !n.matches(sc))
        }
        let to = N.length
        // if (unmatches.length) console.log(`Stuffing unmatches ${from}->${to}: `,unmatches)

        return N
    }
    // group like stuff
    brackology() {
        let groups = _C()
        this.get_matching_rows().forEach((n:TheC) => {
            let ks = Object.keys(n.sc);
            let matchness = 0;
            let match = null;
            groups.o().forEach((c:TheC) => {
                // leave apart if:
                // more than one key is different
                let different_keys = ks.filter(k => !Object.hasOwn(c.sc,k)).length
                if (different_keys > 1) return
                // certain keys' values are different
                if (n.sc.dome != c.sc.dome) return
                
                // prefer 0 different keys to 1
                // < fuzzier matching, lots complicated. graph partitioning with cytoscape?
                let same_keys = ks.filter(k => Object.hasOwn(c.sc,k)).length
                let matched = same_keys - different_keys
                if (matched <= matchness) return
                match = c
                matchness = matched
            })
            if (match && matchness >= ks.length-1) {
                // groups members with <= 1 odd key
                // < this could use Stuff.i_z() for speed, only needs X.z
                match.i(n)
            }
            else {
                // group labeled, copies k:v
                // < more clean and proper to look at match/$n[0]
                //    instead of copying the first datum to match itself?
                match = _C({name:ks.join(','),sc:{...n.sc}})
                // match|group knows the source $n
                match.i(n)
                groups.i(match)
            }
        })
        this.regroup(groups)
        this.started = true
    }
    // grouped stuff -> tree of objects with quantity descriptions
    regroup(groups:TheC) {
        this.groups.clear()
        groups.o().forEach((n:TheC) => {
            // uniquely identify them
            let name = n.name || 'unnamed'
            name = name_numbered_for_uniqueness_in_Set(name, this.groups)
            let rows = n.o()
            const stuffusion = new Stuffusion(this, name, rows)
            // do any rows have n.X, nest Stuffing
            stuffusion.detect_nX(rows)

            // add columns
            // there may be odd ones out (many of them) from c.sc
            let column_names = Object.keys(n.X.k || {})
            column_names.forEach((key) => {
                const kx = n.X?.o_kv(key, 1)
                if (!kx) throw "!kx"
                let rows = kx.z
                const stuffziad = new Stuffziad(stuffusion, key, rows)

                // vs contains the unique values, v contains the TheX for each
                const values = kx.vs || []
                const valueXs = kx.v || []
                values.forEach((val, idx) => {
                    const vx = valueXs[idx]
                    // Count how many $n have this value (from vx.z)
                    let rows = vx?.z || []
                    
                    // Create a Stuffziado for each distinct value
                    let display_name = objectify(val)
                    let val_name = name_numbered_for_uniqueness_in_Set(display_name, stuffziad.values)
                    const stuffziado = new Stuffziado(stuffziad, val_name, rows)
                    stuffziado.value = val
                    stuffziado.display_name = display_name
                    // note some interesting features
                    let innerables = [...rows]
                    if (typeof val == 'object') {
                        if (val instanceof TheC) {
                            stuffziado.is_C = true
                            // check for C.X, nest Stuffing
                            innerables.push(val)
                        }
                        // < pull out v(.constructor)+.name
                    }
                    else {
                        stuffziado.is_string = true
                    }
                    stuffziado.detect_nX(innerables)
                    
                    
                    stuffziad.values.set(stuffziado.name, stuffziado)
                })

                stuffusion.columns.set(stuffziad.name,stuffziad)
            })
            this.groups.set(stuffusion.name,stuffusion)
        })
    }
}
// C*/* measurer
function inner_sizing(innered) {
    let sizo = { here: 0, therein: 0 };
    for (const inn of innered) {
        sizo.here += 1;
        sizo.therein += inn?.X?.z?.length || 0;
    }
    return (sizo.here == 1 ? '' : ("x" + sizo.here))
            + "/*" + sizo.therein
}
// data dumper
// < recursion
export function objectify(v:any):string {
    return String(
        typeof v == 'number' || typeof v == 'string' ? v
        : v == null ? 'null'
        : v.constructor == Array ? `[${v.map(n => objectify(n)).join(',')}]`
        : `${v.constructor.name}()`
    )
}

function name_numbered_for_uniqueness_in_Set(name,set) {
    if (typeof name !== 'string' || !(set instanceof Set) && !(set instanceof Map)) {
        throw new Error('Invalid arguments');
    }
    let number = 0;
    let name_numbered = name;
    while (set.has(name_numbered)) {
        number++;
        name_numbered = `${name} ${number}`;
    }
    return name_numbered;
}

// base class, a section of the slope into Stuff-ness, ((k:v+)+)+
type manyable_Stuffusia = Stuffing|Stuffusion|Stuffziad
export class Stuffuzia {
    up:manyable_Stuffusia
    name:string
    rows: TheN
    row_count:number = $state()
    constructor(up, name: string, rows: TheN) {
        this.up = up
        this.name = name
        this.rows = rows
        this.row_count = rows.length
    }

    // subset of .rows or C-like .value that have n.X.z
    innered?: TheN
    inner_sizing?:string
    // type cXhavable_Stuffusia = Stuffusion | Stuffziado
    detect_nX(N) {
        // supposing the X.z always has everything
        let innered = N.filter(n => n.X?.z?.length)
        if (!innered.length) return
        this.innered = innered
        this.inner_sizing = inner_sizing(innered)
    }
}

// a group of rows, name is keys and maybe serial number
export class Stuffusion extends Stuffuzia {
    columns = new SvelteMap()
}
// a group of k:v, name is the key
export class Stuffziad extends Stuffuzia {
    values = new SvelteMap()
}
// single value, name is serial number?
export class Stuffziado extends Stuffuzia {
    value: any
    is_string?: boolean
    is_C?: boolean
}




//#endregion
//#region TheC
export type TheUniversal = {
    waits: string,
    D: TheC,
    bD: TheC,
    n: TheC,
    name: string,
    needs_doing: boolean,
} & any
export type TheEmpirical = {
    // whether it has been deleted, the index remains
    drop: any,
    top: Travel,

    T:Travel,
    n: TheC,
    path: Array<Travel>
    d: number, // depth of .path
// < these & any mean we don't get types in eg D.c.T
//   but without them lots of red underline happens
//   with: & Record<string, unknown>
//    everything in o(s)'s s is red underlined...
} & any

// extends Stuff, with .X so you can C.i(inC) for C/inC
export class TheC extends Stuff {
    c: TheEmpirical
    sc: TheUniversal
    constructor(opt:Partial<TheC>) {
        super()
        Object.assign(this,opt)
        this.c ||= {}
        if (!this.sc) throw "!C.sc"
    }
}
// ensures v={data:3} becomes C.sc={data:3}
//  as long as you never use the key=sc
export function _C(v={}):TheC {
    if (!v.sc) return new TheC({c:{},sc:{...v}})
    if (!(v instanceof TheC)) return  new TheC(v)
    return v
}

export type TheN = TheC[]



//#endregion
//#region Modus
// > when q.one_value_mode, we may want a [] value
function nonemptyArray_or_null(N:any) {
    if (N?.length) return N
    return null
}
type StashedModus = Object & {

}
// memory hole climbing accessors
//  for any M.stashed haver, for now Modus
export class Modusmem {
    M:Modus
    keys:Array<string>
    constructor(M:Modus,keys:Array<string>) {
        this.M = M
        this.keys = keys
    }
    further(key) {
        return new Modusmem(this.M,[...this.keys,key])
    }
    // they then have a bunch of possible k:v, all should react UI:Thingstashed
    get(key) {
        let here = this.M.stashed
        for (let key of this.keys) {
            if (!Object.hasOwn(here,key)) {
                return null
            }
            here = here[key]
        }
        return here?.[key]
    }
    set(key,value) {
        let here = this.M.stashed
        for (let k of this.keys) {
            let there = here
            here = here[k] || {}
            there[k] = here
        }
        here[key] = value

        this.M.stashed.version ||= 0
        this.M.stashed.version ++
    }
}
// a culture of io
// trivial n/%stuctures and their games
abstract class TimeOffice {
    // < these could be next to TheC.ago() ?
    async i_wasLast(n:TheC,label:string,now=false) {
        if (now) {
            // set it
            await n.replace({wasLast:label,at:1},async () => {
                n.i({wasLast:label,at:now_in_seconds()})
            })
            return 0
        }
        else {
            // measure ago
            return n?.o({wasLast:label})[0]?.ago('at') || 0
        }

    }
    // < arg a label as well?
    async i_chaFrom(n:TheC,v:any,q:TheEmpirical) {
        let ch = n.o({chaFrom:1})[0]

        let was = ch?.sc.v
        await q?.pairs_fn?.(was,v,previous_time)
        if (!ch || v != was) {
            // it changed! or established
            let previous_time = ch?.ago('at')
            await n.replace({chaFrom:1},async () => {
                ch = n.i({chaFrom:1,was,v,at:now_in_seconds()})
            })
            await q?.changing_pairs_fn?.(was,v,previous_time)
        }
    }

}
abstract class TimeGallopia extends TimeOffice{
    // M.stashed is persistent
    stashed:StashedModus = $state()
    stashed_mem:KVStore
    init_stashed_mem() {
        this.S.stashed_mem(this,`Modus:${objectify(this)}`)
    }
    // io into the .stashed.**
    imem(key) {
        return new Modusmem(this,[key])
    }


    // the "I'm redoing the thing" process wrapper
    // a layer on top of Stuff.replace():
    //  graceful fail when already locked
    //  doesn't recycle C/** (replace() q.fresh)
    abstract current:TheC
    time_having?:Error|null
    async have_time(fn:Function) {
        let at = new Error().stack
        if (this.time_having) {
            console.error("re-transacting Modus",
                {awaiting_stack:this.time_having,
                 current_stack:at})
            return
        }
        this.time_having = at
        
        try {
            // doing the business
            await fn()
        } finally {
            this.time_having = null
        }
    }

    // when starting a new time, set the next
    async reset_interval() {
        // the universal %interval persists through time, may be adjusted
        // our current %mo,interval row, a singleton
        let n
        let int = this.o({mo:'main',interval:1})[0]
        let interval = int?.sc.interval || 3.6
        let id; id = setTimeout(() => {
            // if we are still the current callback
            if (n != this.o({mo:'main',interval:1})[0]) return
            // if the UI:Modus still exists
            if (this.stopped) return
            // UI:Sharability thing above can stop
            if (!this.S.started) return

            this.main()
            
        },1000*interval)

        await this.current.replace({mo:'main',interval:1}, async () => {
            n = this.i({mo:'main',interval,id})
        })
    }


    // < GOING, but is a primitive sketch of replace()
    // replacies() does a really simple resolve $n
    //  or creates $n afresh
    // when it calls your middle_cb(n)
    //  n already have|resolved n/*
    //   and n.replace() can work
    //  yet n.sc.* is still mutable
    //   because it hasn't done this.i(n)
    //      in contrast to replace() itself
    //       where n/* isn't available until we commit (resolve)
    // 
    // ie find the history (previous entry) of a particle by its look
    // 
    //
    // we usually want to consider a whole table of tuples we're replacing
    //  but it's easier to code for single lumps of action
    //  where a thing is defined and something is done with it over time
    //   that MIGHT change its n.sc.*
    //    seems it's better to put all changables into n/*!
    // 
    // much simpler and more limited than Stuff.replace()
    // < to work within the Modus.current.replace()
    //    to resolve some of the X.z at once...
    //   basically by holding off goners indefinitely
    // establish a single bunch of stuff
    //  simply cloning the before set makes it trivial to resolve $n
    async replacies({base_sc,new_sc,middle_cb}:{
        base_sc:TheUniversal,
        new_sc:Function|TheUniversal,
        middle_cb:Function
    }) {
        // Modus.main() used to be in a Modus.current.replace({}, ...)
        //    ie of everything, so we boa to see the prior complete state
        let N = this.boa(base_sc)
        if (!N) {
            // first time!
            if (typeof new_sc == 'function') {
                new_sc = new_sc()
            }
            new_sc = {...base_sc,...new_sc}
            N = [_C(new_sc)]
        }


        // console.log("replacies!",N.map(n => keyser(n)))
        // don't bother with multiple things
        if (N.length > 1) N = [N[0]]


        for (const oldn of N) {
            let n = _C(oldn.sc)
            // keep n/* from last time, since we basically resolve $n
            n.X = oldn.X
            // you may still mutate n.sc
            await middle_cb(n)
            //  because we index it now
            this.i(n)
        }
    }
}

export abstract class Modus extends TimeGallopia {
    // belongs to a thing of a feature
    S:ThingIsms
    // < FeatureIsms. PF.F = F
    F:PeeringFeature
    
    // < GOING?
    coms?:TheC|null = $state()
    // suppose you will develop your *Modus while looking at a Strata
    a_Strata?:Strata = $state()

    constructor(opt:Partial<Modus>) {
        super()
        Object.assign(this,opt)
        this.init_stashed_mem?.()
    }


    // Modus having .current, rather than being C
    current:TheC = $state(_C())
    // add to the Stuff
    i(C:TheC|TheUniversal) {
        return this.current.i(C)
    }
    drop(C:TheC) {
        return this.current.drop(C)
    }

    // retrieval (opening)
    // for now or before
    // return undefined if no rows, good for boolean logic
    // look at this time's Stuff
    o(c?:TheUniversal,q?) {
        return this.current.o(c, q)
    }
    // < zo() would look at the previous time until the current one was commit to
    // look at previous time
    bo(c?:TheUniversal,q?) {
        return this.current.bo(c, q)
    }

    oa(c?:TheUniversal,q?) {
        return this.current.oa(c, q)
    }
    boa(c?:TheUniversal,q?) {
        return this.current.boa(c, q)
    }

    // you subclass this
    main() {
        console.log("Disfrance")
        this.i({diffrance:23})
    }
    // see TimeGallopia for 
    //  probably use replacies() to enliven some Stuff




    stopped = false
    stop() {
        this.stopped = true
    }

    static test_Modus() {
        let M = new Modus()

        M.i({unfinished:1})
        if (M.oa({unfinished:1})) {
            console.log("We had it!")
        }
        if (M.oa().length) {
            console.log("We had all!")
        }
        if (M.oa({fefe:1})) {
            console.log("We didn't have it!")
        }
        return M
    }

    static test_Stuff() {
        let M = new Modus()
        M.i({waffle:2,table:4})
        M.i({waffle:5,six:4})
        let two_one_one = [
            M.o({waffle:1}),
            M.o({table:4}),
            M.o({waffle:5}),
        ]
        let empty_undef = [
            M.o({lovely:3}),
            M.oa({six:3}),
        ]
        console.log("Stuff",{empty_undef,two_one_one})
        return M
    }
    



}
