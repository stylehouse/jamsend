let spec = `

what Stuff is (~~ brackio)
   it seems to go to form:
    Modus of advancing states with methods (~~ Super)
    Selection (~~ C**, nodes)
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
export class Stuff {
    X: TheX = new TheX()

    // regroup! indexes build up, forming X/.../$n to be with
    i(n: TheC) {
        // failed ideas here include:
        //   peeling a json-ish string, chaining from s=TheC, environmental awareness

        // do your basic index-everything - copy info from these $n to X/$k/$v
        // everything we have
        //  the below i_k and i_v also do i_z where they end up
        this.X.i_z('z', n);

        Object.entries(n.sc || {}).forEach(([k, v]) => {
            // the keys
            const kx = this.X.i_k(k, n);
            
                // this is under X/$k
                // have their values via unique id  
                kx.i_v(v, n);
            // so you have to look up all keys if you want all values
        });

        // robustly
        if (this.X.z && this.X.z.length > 6000) throw "giant stuff";

        // < is a convenient time to return an up-to-date picture of what's at all those locations
        //    a /$k /$v
        return n
    }

    // look for these keys if $key=1, or the value as well.
    // the X/$k(/$v) /$n give us a list
    //   which we then just grep for the rest of properties
    //  as opposed to:
    //   > thinking about going into particular X/$k/$v, depending on $key=1
    //   > joining many reads on the X/$k/$v table, which is just uniq(/$n)
    // one_column_mode =
    //  $k returns [v+] in that column, from the resultant /$n/.sc.$k
    //  1 returns the first column (javascript hashes are ordered)
    //  0 returns the first value of the first column (in the query)
    o(sc: TheUniversal,one_column_mode):TheN|TheC|any|undefined {
        // results
        let M:TheN = []
        // Process each key-value pair in sc
        let query_params = Object.entries(sc || {})
        if (!query_params.length) {
            // wants everything
            M = this.X.z?.filter(n => this.n_matches_star(n)) || []
        }

        let amongst:TheN;
        query_params.forEach(([t, v]) => {
            // might have indexing, only for the first one
            if (!amongst) {
                let x = this.X.o_kv(t,v);
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
        
        if (one_column_mode != null) {
            let one_value_mode = false;
            if (one_column_mode == 0) {
                one_value_mode = true;
                one_column_mode = 1;
            }
            if (one_column_mode == 1) {
                // Get first key from sc (equivalent to haks(c)[0])
                one_column_mode = Object.keys(sc)[0];
            }
            
            let N = M;
            M = [];
            
            N.forEach(n => {
                let v = n.sc && n.sc[one_column_mode];
                if (v == null) return;
                M.push(v);
            });
            
            if (one_value_mode) return M[0];
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
    d(s:TheUniversal,y:Function,d?:TheEmpirical) {
        d = Travel.onwards(d||{})
        
    }
}

//#region C, Travel

type TheUniversal = {
    waits?: string
} & any
type TheEmpirical = {
    drop?: any
} & any

// extends Stuff means all C can .i(), .o() what's inside them!
class TheC {
    c: TheEmpirical
    sc: TheUniversal
    constructor(opt:Partial<TheC>) {
        Object.assign(this,opt)
    }
}
// ensures v={data:3} becomes C.sc={data:3}
let _C = (v) => {
    if (!v.sc) v = new TheC({c:{},sc:v})
    return v
}

type TheN = TheC[]

// the visitor of $n** for the Stuff.d() function
class Travel extends TheX {
    constructor(opt) {
        Object.assign(this,opt)
    }
    // arrive at a new place, inc the first one
    static onwards(d) {
        d = new Travel(d)
        // track all items ($n) visited to avoid loops
        //  similar to X.i_refer()
        if (!d.refs) {
            d.refs = [];
            d.refid = {}; // those indices to d
        }
    }
    ref_visited(n) {

    }
}

//#region Modus
export class Modus {
    current = $state(new Stuff())
    before?:Stuff

    constructor(opt:Partial<Modus>) {
        Object.assign(this,opt)
    }

    // add to the Stuff
    i(C:TheC|TheUniversal) {
        return this.current.i(_C(C))
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
