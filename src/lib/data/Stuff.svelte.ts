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
// storage
type TheX = {
    z?: TheN,

    t?: {},

    s?: [],
    ss?: [],
}
type Thex = {
    up: TheX
} & TheX


export class Stuff {
    X:TheX = {}

    i(n:TheC) {
        // failed ideas here include:
        //   peeling a json-ish string, chaining from s=TheC, environmental awareness

        // do your basic index-everything
        brackX([n],this.X)

        // robustly
        if (this.X.z?.length > 6000) throw "giant stuff"

        // < is a convenient time to return an up-to-date picture of what's at all those locations
        //    a /$k /$v
    }
    o(sc:TheUniversal) {

    }
}



//#region U





//#region X
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


// copy info from these $n to X/$k/$v
function brackX(N:TheN, X?:TheX):TheX {
    X = X || {};
    
    N.forEach(n => {
        // everything we have
        //  the below X_k and X_v also do X_z where they end up
        X_z(X,'z',n)

        Object.entries(n.sc || {}).forEach(([k, v]) => {
            // the keys
            const kx = X_k(X, k, n);

                // have their values via unique id  
                X_v(kx, v, n);
            // so you have to look up all keys if you want all values
        });
    });
    
    return X;
}


// these index data from TheC
// X/$k names it (X.k) and implies a type...
// +$n means accumulate a list of TheC there
//   also refered to as /$n

// X/$k +$n
function X_k(X:TheX, k:string, n:TheC, kf?:string):Thex {
    kf = kf || 'k';
    X[kf] = X[kf] || {};
    const x:Thex = X[kf][k] = X[kf][k] || {};
    x.up = X;
    X_z(X,'z',n)
    return x;
}

// X.z +$n
// dupey accumulator, makes /$n (rows at x)
function X_z(X:TheX, k:string, n:TheC) {
    if (!n) return
    const N = X[k] = X[k] || [];
    if (!Array.isArray(N)) throw "!ar";
    N.push(n);
}

// < GOING? iterating the index...
// check X/$v for $n
function oX_v(X, v, n, kf?, q?):Thex|null {
    q = q || {};
    q.el = 8;
    return X_v(X, v, n, kf, q);
}

// X/$v +$n
function X_v(X:TheX, v:any, n:TheC, kf?, q?):Thex|null {
    kf = kf || 'v';
    return X_refer(X, v, n, kf, q);
}

// indexing objects, or anything
function X_refer(X:TheX, v:any, n:TheC, kf:string, q?:object, kfs?:string):Thex|null {
    // the X.something for the array of values
    // < which should be a WeakMap, preventing the need for two indexes
    kfs = kfs || kf + 's';
    // array mirroring the values with an x for that value
    if (!kf) throw "named";
    
    // by id of the value
    const fs = X[kfs] = X[kfs] || [];
    let vi = fs.indexOf(v);
    
    if (q && q.el == 8 && vi < 0) return;
    if (vi < 0) vi = fs.push(v) - 1;
    
    const f = X[kf] = X[kf] || [];
    const x:Thex = f[vi] = f[vi] || {};
    x.up = X;
    X_z(x,'z',n)
    return x;
}
