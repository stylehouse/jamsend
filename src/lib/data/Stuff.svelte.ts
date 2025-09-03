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

`


type TheUniversal = {
    waits?: string
} & any
type TheEmpirical = {
    drop?: any
} & any

class TheC {
    c: TheEmpirical
    sc: TheUniversal
    constructor(v) {
        Object.assign(this,v)
    }
}
// ensures v={data:3} becomes C.sc={data:3}
let _C = (v) => {
    if (!v.sc) v = new TheC({c:{},sc:v})
    return v
}

type TheN = TheC[]



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
`

// storage class with methods
class TheX {
    // we may be inside another X
    up?: TheX;

    // by the usual names:
    z?: TheN
    k?: {}
    v?: []
    vs?: []

    // X/$k +$n
    i_k(k: string, n: TheC, kf?: string): TheX {
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
    i_refer(v: any, n: TheC, kf: string, kfs?: string): TheX | null {
        // the X.something for the array of values
        // < which should be a WeakMap, preventing the need for two indexes
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
        if (this.X.z?.length > 6000) throw "giant stuff";

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
    //  0 returns the first value of the first column
    o(sc: TheUniversal,one_column_mode) {
        let M:TheN = [];
        let amongst:TheN;
        // Process each key-value pair in sc
        Object.entries(sc || {}).forEach(([t, v]) => {
            // might have indexing, only for the first one
            if (!amongst) {
                // Look up the key in X.k
                let x = this.X.k && this.X.k[t] ? this.X.k[t] : null;
                
                if (x && v != 1) {
                    // Find the value index
                    let vi = x.vs ? x.vs.indexOf(v) : -1;
                    if (vi < 0) return; // continue to next iteration
                    x = x.v && x.v[vi] ? x.v[vi] : null;
                }
                
                if (!x) return; // continue to next iteration
                
                // Process each item in x.z
                (x.z || []).forEach(n => {
                    if (n.c.drop) return; // continue if marked as dropped
                    
                    // check it's still in the data
                    let non = !(n.sc && n.sc[t] && (v == 1 || v == n.sc[t]));
                    
                    if (non) {
                        if (!n.sc || !n.sc.hasOwnProperty(t)) {
                            // < brack occasionally not readonly
                            //   eg %%toomuch deleted, see &nottoomuch_Eref
                            // dont match
                            return;
                        }
                        else if (typeof n.sc[t] === 'number' && v == 1) {
                            // c.led=1 may match %%led:0
                            // eg &PaveelQup_5 / &jaa c='isready' o=1 [0]
                            //  returns the 0 from %%isready:0
                            // eg -Eel / &jaa c='Belti,Bet,Bit'
                            //  wants %%Belti=0, is serial
                            if (n.sc[t] != 0) console.log('debugger'); // debugger equivalent
                        }
                        else {
                            console.log('debugger'); // debugger equivalent
                            // dont match?
                            return;
                        }
                    }
                    
                    if (!M.includes(n)) M.push(n);
                });
            }
            else {
                let from = amongst
                
                from.forEach(n => {
                    let non = !(n.sc && n.sc[t] && (v == 1 || v == n.sc[t]));
                    
                    if (non && amongst) {
                        M = M.filter(out => out != n);
                    }
                    if (non || amongst) return;
                    if (n.c.drop) return; // continue if marked as dropped
                    
                    if (!M.includes(n)) M.push(n);
                });
            }
            
            amongst = M;
        });
        
        if (one_column_mode) {
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
            
            // not via &jaa, would || []
            if (one_value_mode) return M[0];
        }
        
        return M.length ? M : undefined;
    }




    static test_Stuff() {
        let M = new Modus()
        M.ji({waffle:2,table:4})
        M.ji({waffle:5,six:4})
        let two_one_one = [
            M.jo({waffle:1}),
            M.jo({table:4}),
            M.jo({waffle:5}),
        ]
        let empty = [
            M.jo({lovely:3}),
            M.jo({six:3}),
        ]
        console.log("Stuff",{empty,two_one_one})
    }
}

//#region Modus
export class Modus {
    current = new Stuff()
    before?:Stuff


    // add to the Stuff
    ji(C) {
        return this.current.i(_C(C))
    }
    // look at this time's Stuff
    jo(c,q?) {
        return this.current.o(c, q)
    }

    // < zo() would look at the previous time until the current one was commit to
    // look at previous time
    bo(c,q?) {
        return this.before?.o(c, q)
    }


    static test_Modus() {
        let M = new Modus()
        M.advance()
    }

    advance() {
        this.ji({unfinished:1})
        if (this.jo({unfinished:1})) {
            console.log("We had it!")
        }
        if (this.jo({fefe:1})) {
            console.log("We didn't have it!")
        }
    }
    



}
