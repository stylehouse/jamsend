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

type TheC = {
    sc: TheUniversal
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
    z?: TheN = []
    k?: {} = {}
    v?: [] = []
    vs?: [] = []

    // X/$k +$n
    i_k(k: string, n: TheC, kf?: string): TheX {
        kf = kf || 'k';
        this[kf] = this[kf] || {};
        const x: TheX = this[kf][k] = this[kf][k] || new TheX();
        x.up = this;
        this.i_z('z', n);
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
    i_v(v: any, n: TheC, kf?: string, q?: object): TheX | null {
        kf = kf || 'v';
        return this.i_refer(v, n, kf, q);
    }

    // < GONE? others iterate X...
    // check X/$v for $n
    o_v(v: any, n: TheC, kf?: string, q?: object): TheX | null {
        q = q || {};
        q.el = 8;
        return this.i_v(v, n, kf, q);
    }

    // indexing objects, or anything
    i_refer(v: any, n: TheC, kf: string, q?: object, kfs?: string): TheX | null {
        // the X.something for the array of values
        // < which should be a WeakMap, preventing the need for two indexes
        kfs = kfs || kf + 's';
        // array mirroring the values with an x for that value
        if (!kf) throw "named";
        
        // by id of the value
        const fs = this[kfs] = this[kfs] || [];
        let vi = fs.indexOf(v);
        
        if (q && q.el == 8 && vi < 0) return null;
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
    }

    // look for these keys if $key=1, or the value as well.
    // the X.k gives us a /$n, which we then just grep for properties
    //  as opposed to:
    //   > thinking about going into particular X/$k/$v, depending on $key=1
    //   > joining many reads on the X/$k/$v table, which is just uniq(/$n)
    o(sc: TheUniversal) {
        $M = [];
        # AND
        $amongst;
        $X = zs&X;
        each tv c {
            # might have indexing, only for the first one
            if (X && !amongst) {
                $x = ahsk(X,'k',t);
                if (x && v != 1) {
                    $vi = x.refs.indexOf(v);
                    vi < 0 and return
                    x = x.ref[vi];
                }
                !x and return
                each in x.z {
                    nc&drop and continue
                    # check it's still in the data
                    $non = !(n.sc[t] && (v == 1 || v == n.sc[t]))
                    if (non) {
                        if (!hak(n.sc,t)) {
                            # < brack occasionally not readonly
                            #   eg %%toomuch deleted, see &nottoomuch_Eref
                            # dont match
                            continue
                        }
                        elsif (num(n.sc[t]) && v == 1) {
                            # c.led=1 may match %%led:0
                            # eg &PaveelQup_5 / &jaa c='isready' o=1 [0]
                            #  returns the 0 from %%isready:0
                            # eg -Eel / &jaa c='Belti,Bet,Bit'
                            #  wants %%Belti=0, is serial
                            n.sc[t] != 0 and debugger
                        }
                        else {
                            debugger
                            # dont match?
                            continue
                        }
                    }
                    !M.includes(n) and M.push(n)
                }
            }
            else {
                $from = amongst || zs&z;
                each in from {
                    $non = !(n.sc[t] && (v == 1 || v == n.sc[t]));
                    non && amongst and M = M.filter(out=>out!=n)
                    non || amongst and continue
                    nc&drop and continue
                    !M.includes(n) and M.push(n)
                }
            }
            amongst = M;
        }
        # one column mode
        if (o != null) {
            o == 0 and $onerow = o = 1
            o == 1 and o = haks(c)[0]
            $N = M;
            M = [];
            each in N {
                $v = n.sc[o];
                v == null and continue
                M.push(v);
            }
            # not via &jaa, would || []
            onerow and return M[0]
        }
        M.length and return M
    }
}

