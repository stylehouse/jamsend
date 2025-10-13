import { SvelteMap, SvelteSet } from "svelte/reactivity";

let spec = `

what Stuff is (~~ brackio)
   is the ability to C.i(inC)
    using C.c.X... = x, x.z = [inC+]
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
        this.serial_i = Number(this.serial_i) + 1
    }

    // X/$k +$n
    i_k(k: string, n: TheC, kf?: string): TheX {
        this.bump_version()
        kf = kf || 'k';
        this[kf] = this[kf] || {};
        const x: TheX = this[kf][k] = this[kf][k] || new TheX();
        x.up = this;
        x.i_z('z', n);
        return x;
    }

    // X.z +$n - dupey accumulator, makes /$n (rows at x)
    i_z(k: string, n: TheC) {
        if (!n) return;
        this.bump_version()
        const N = this[k] = this[k] || [];
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
    i_refer(v: any, n: TheC, kf: string, kfs?: string): TheX | null {
        this.bump_version()
        // the X.something for the array of values
        kfs = kfs || kf + 's';
        // array mirroring the values with an x for that value
        if (!kf) throw "named";
        
        // by id of the value
        const fs = this[kfs] = this[kfs] || [];
        let vi = fs.indexOf(v);
        
        if (vi < 0) vi = fs.push(v) - 1;
        
        const f = this[kf] = this[kf] || [];
        const x: TheX = f[vi] = f[vi] || new TheX();
        x.up = this;
        x.i_z('z', n);
        return x;
    }

    // X reading, returning x to Stuff
    o_kv(k:string,v:1|any):TheX|undefined {
        // Look up the key in X.k
        let x = this.k && this.k[k] ? this.k[k] : null;
        
        // wildcard where {$k:1}
        if (x && v != 1) {
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
export class Stuff {
    c: TheEmpirical
    Xify() {
        this.c.X ||= new TheX()
    }
    get version() {
        return this.c.X.serial_i
    }
    // delete a C (filter it out of results)
    drop(n:TheC) {
        if (!n) return
        if (!n.sc) throw "!drop(C)"
        n.c.drop = 1
        this.c.X.bump_version()
    }


    // regroup! indexes build up, forming X/.../$n to be with
    i(n: TheC) {
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
        this.c.X.i_z('z', n);

        Object.entries(n.sc || {}).forEach(([k, v]) => {
            // the keys
            const kx = this.c.X.i_k(k, n);
            
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
    // oa(...)[0] for the first row
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

        let M = this.o_query(sc)
        return this.o_results(M,sc,q)
    }
    o_query(sc:TheUniversal) {
        // results
        let M:TheN = []
        // Process each key-value pair in sc
        let query_params = Object.entries(sc || {})
        if (!query_params.length) {
            // wants everything
            M = this.c.X.z?.filter(n => this.n_matches_star(n)) || []
        }

        let amongst:TheN;
        query_params.forEach(([t, v]) => {
            // might have indexing, only for the first one
            if (!amongst) {
                let x = this.c.X.o_kv(t,v);
                // start resulting with items here in x.z
                //  x.z = the /$n at the end of whatever expression
                (x && x.z || []).forEach(n => {
                    if (this.n_matches_kv(n,t,v)) {
                        // includes result
                        if (!M.includes(n)) M.push(n)
                    }
                });
            }
            else {
                // filter results we are already joined to
                amongst.forEach(n => {
                    if (!this.n_matches_kv(n,t,v)) {
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

    // visitor of many ** to o()
    d(s:TheUniversal,d?:Partial<Travel>) {
        // start arriving
        if (typeof d == 'function') d = {y:d}
        let T = Travel.onwards(d||{})

        // check if we're supposed to be here ($n=this) again
        let refx = T.i_visit(this)
        if (refx.z.length > 1) {
            return d.sc.not = "visited"
        }

        // visit here
        T.sc.n = this
        T.c.y(this,T)

        // find more!
        // run the query here
        let M = this.o(s)
        M.forEach((n:TheC) => {
            n.d(s,T)
        })
    }




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
    constructor(Stuff:Stuff) {
        this.Stuff = Stuff
        $effect(() => {
            if (this.Stuff.version) {
                console.log("reacting to Stuff++")
                setTimeout(() => this.brackology(), 110)
            }
        })
    }
    // group like stuff
    brackology() {
        let groups = _C()
        this.Stuff.o().forEach((n:TheC) => {
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
    }
    // grouped stuff -> tree of objects with quantity descriptions
    regroup(groups) {
        this.groups.clear()
        groups.o().forEach((c:TheC) => {
            // uniquely identify them
            let name = c.name || 'unnamed'
            name = name_numbered_for_uniqueness_in_Set(name, this.groups)
            let rows = c.o()
            const stuffusion = new Stuffusion(this, name, rows)
            // do any rows have n.c.X, nest Stuffing
            stuffusion.detect_cX(rows)

            // add columns
            // there may be odd ones out (many of them) from c.sc
            let column_names = Object.keys(c.c.X.k)
            column_names.forEach((key) => {
                const kx = c.c.X?.o_kv(key, 1)
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
                    let val_name = objectify(val)
                    val_name = name_numbered_for_uniqueness_in_Set(val_name, stuffziad.values)
                    const stuffziado = new Stuffziado(stuffziad, val_name, rows)
                    stuffziado.value = val
                    // note some interesting features
                    if (typeof val == 'object') {
                        if (val instanceof TheC) {
                            stuffziado.is_C = true
                            // does it contain C.c.X, nest Stuffing
                            stuffziado.detect_cX([val])
                        }
                        // < pull out v(.constructor)+.name
                    }
                    else {
                        stuffziado.is_string = true
                    }
                    
                    
                    stuffziad.values.set(stuffziado.name, stuffziado)
                })

                stuffusion.columns.set(stuffziad.name,stuffziad)
            })
            this.groups.set(stuffusion.name,stuffusion)
        })
    }
}
// data dumper
// < recursion
function objectify(v:any):string {
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
    constructor(up, name: string, rows: TheN) {
        this.up = up
        this.name = name
        this.rows = rows
    }

    // subset of .rows or C-like .value that have n.c.X.z
    innered?: TheN
    // type cXhavable_Stuffusia = Stuffusion | Stuffziado
    detect_cX(N) {
        // supposing the X.z always has everything
        let innered = N.filter(n => n.c.X?.z)
        if (innered.length) {
            this.innered = innered
        }
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
class Stuffziado extends Stuffuzia {
    value: any
    is_string?: boolean
    is_C?: boolean
}




//#endregion
//#region C
type TheUniversal = {
    waits?: string,
} & any
type TheEmpirical = {
    // whether it has been deleted, the index remains
    drop?: any,
    // contains indexes leading to in-C (C/C)
    X?: TheX,
    top?: Travel,
} & any

// extends Stuff, so you can C.i(inC) for C/inC
class TheC extends Stuff {
    // may be null, doesn't count as a key!
    name?: string
    // similar, but between 0-1
    fraction?: number

    // < $state() unnecessary?
    c: TheEmpirical = $state()
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
    if (!v.sc) return new TheC({c:{},sc:v})
    if (!(v instanceof TheC)) return  new TheC(v)
    return v
}

export type TheN = TheC[]

//#endregion



//#region Travel
// the visitor of $n** for the Stuff.d() function
class Travel extends TheC {
    // callback for each $n
    y:Fuction
    constructor(opt) {
        super(opt)
        Object.assign(this,opt)
    }
    // factory, extender
    //  d usu cloning a Travel we're going beyond
    //  also from Stuff.d(s,y,d), so Travel.sc=d
    // arrive at a new place, inc the first one
    static onwards(d:Travel["c"]|Travel):Travel {
        if (d.instanceof(Travel)) {
            // copy d.c.*, new d.sc.*
            d = new Travel({c:{...d.c},sc:{up:d}})
            // clone d.c.* that mutate
            d.c.path = (d.c.path||[]).slice()
        }
        else {
            d = new Travel({c:d,sc:{}})
        }
        d.c.top ||= d
        d.c.d ||= 0
        d.c.d++

        return d
    }
    // tracking visited refs at the top to avoid going in loops
    i_visit(v:any|TheC):TheX {
        let d = this
        let top:Travel = this.c.top
        top.Xify()
        let X:TheX = top.c.X
        return X.i_refer(v,d,'visit_v')
    }
}


//#region Modus
// > when q.one_value_mode, we may want a [] value
function nonemptyArray_or_null(N:any) {
    if (N?.length) return N
    return null
}
export class Modus {
    current:TheC = $state(_C())
    before?:TheC

    constructor(opt:Partial<Modus>) {
        Object.assign(this,opt)
    }

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
        return nonemptyArray_or_null(this.current.o(c, q))
    }
    // < zo() would look at the previous time until the current one was commit to
    // look at previous time
    bo(c?:TheUniversal,q?) {
        return nonemptyArray_or_null(this.before?.o(c, q))
    }


    // return arrays, empty if no rows, good for iterating .forEach()
    oa(c?:TheUniversal,q?):TheN|TheC|any {
        return this.o(c,q) || []
    }
    boa(c?:TheUniversal,q?):TheN|TheC|any {
        return this.bo(c,q) || []
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
            M.oa({lovely:3}),
            M.o({six:3}),
        ]
        console.log("Stuff",{empty_undef,two_one_one})
        return M
    }
    main() {
        console.log("Disfrance")
        this.i({diffrance:23})
    }
    static test_Modus() {
        let M = new Modus()

        M.i({unfinished:1})
        if (M.o({unfinished:1})) {
            console.log("We had it!")
        }
        if (M.o()) {
            console.log("We had all!")
        }
        if (M.o({fefe:1})) {
            console.log("We didn't have it!")
        }
        return M
    }
    

    advance() {
        // < to rearrange a composite Stuff...
        //    dropping only what we'll do again in the Modus.main()
        //   or recreate any %domes until they are 
    }
    



}
