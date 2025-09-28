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

    // X/$k +$n
    i_k(k: string, n: TheC, kf?: string): TheX {
        this.serial_i++
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


    // regroup! indexes build up, forming X/.../$n to be with
    i(n: TheC) {
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
        
        return M.length ? M : undefined;
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

    // delete a C (filter it out of results)
    drop(n:TheC) {
        if (!n) return
        n.c.drop = 1
        this.c.X.serial_i++
    }




}




//#region Stuffing
// a look at some Stuff
//  to come springing out of Modus.
// < the universal, an experiential perspective
// Stuffing - whole island of Stuff
//  / Stuffusion - the compressed identity of some rows
//  / Stuffziad - the k:v presentation, may be a compressed identity

// whole island of Stuff
class Stuffing {
    Stuff:Stuff
    constructor(Stuff:Stuff) {
        this.Stuff = Stuff
        $effect(() => {
            if (this.Stuff.version) {
                console.log("reacting to Stuff++")
                this.brackology()
            }
        })
    }
    brackology() {

    }
}
// the compressed identity of some rows
class Stuffusion {
    id:string

    
}
// the k:v presentation, may be a compressed identity
class Stuffziad {
    
}



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
let _C = (v={}) => {
    if (!v.sc) v = new TheC({c:{},sc:v})
    return v
}

type TheN = TheC[]

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
export class Modus {
    current:TheC = $state(_C())
    before?:TheC

    constructor(opt:Partial<Modus>) {
        Object.assign(this,opt)
    }

    // add to the Stuff
    i(C:TheC|TheUniversal) {
        C = _C(C)
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
        return this.before?.o(c, q)
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
