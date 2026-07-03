import { now_in_seconds, PeeringFeature } from "$lib/p2p/Peerily.svelte";
import { SvelteMap, SvelteSet } from "svelte/reactivity";
import type { Travel } from "$lib/mostly/Selection.svelte";
import { armap, ex, exactly, hakd, isar, map, tex, throttle } from "$lib/Y.svelte";
import type { Matchy } from "$lib/mostly/Structure.svelte";

const OPTIMISE_FOR_DX = true

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
export class TheX {
    // we may be inside another X
    //  aka an x, as in X...x
    up?: TheX;

    // by the usual names:
    k?: {}
    v?: []
    vs?: []
    z?: TheN

    // < tried to make .z state but... it loses the first row? but is reactive
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
    i_v(v: any, n?: TheC, kf?: string): TheX | null {
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
        
        // wildcard where {$k:1}, leaving us where there are more /$n
        if (x && (v != 1 || typeof v == 'string' || q?.notwild)) {
            // Find the value index
            let vi = x.vs ? x.vs.indexOf(v) : -1;
            if (vi < 0 && typeof v == 'string') {
                // o(exactly(sc)) for when you really mean %step:1 only
                //  may be trying to locate a string when it needs to use a number
                v = v * 1
                if (!Number.isNaN(v)) {
                    vi = x.vs ? x.vs.indexOf(v) : -1;
                }
            }
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
    replace_having?:Error["stack"]
    Xify() {
        if (this.X) return
        this.X ||= new TheX()
        // X is being created fresh — if replace() is mid-flight,
        // inherit the version so observers don't miss a beat
        if (this.X_before) {
            this.X.serial_i = this.X_before.serial_i
            this.X.bump_version()
        }
    }
    bump_version() {
        this.Xify()
        this.X.bump_version()
    }
    // bump() — the civilised short name; bump_version is migrating onto it.  The
    //  `recv&bump` stho call form lowers to recv.bump(), so reach for bump() in
    //  the app layer and let bump_version age out.
    bump() {
        this.bump_version()
    }
    get version() {
        return this.X?.serial_i || 0
    }
    // terser and always true access to version(), for reactivity
    //  is_exa = $derived(exa.vers && exa.sc.active_path == doc.sc.path)
    get vers() {
        return this.version + 1
    }

    // might have a channel to log (.i()) algorithm mumble to
    coms?: TheC
    // delete a C (filter it out of results)
    drop(n:TheC) {
        // < drop() is weird... meant for the host.
        //   but it can just filter o() by !nc&drop from now on...
        n ||= this
        if (!n.sc) throw "!drop(C)"
        n.c.drop = 1
        this.X?.bump_version()
    }

    // attachment, materialisation. indexes build up, forming X/.../$n to be with
    // n joins X.z (ordered), X/$k (key bucket), and X/$k/$v (value bucket)
    // you can many-place C object by C.i(C), aka same ref
    // C.i(LE) twice will cause two /LE with same ref, C.i(LE.sc) without same ref
    //  you might want: C.r({LE:1},{}); C.i(LE), to be the only %LE
    i(n: TheC|TheUniversal):TheC {
        n = _C(n)
        this.Xify()

        // list of everything in order
        //  the below i_k and i_v also do i_z where they end up
        this.X.i_z(n);

        let keys = Object.entries(n.sc || {})
        if (!keys.length) throw "i nothing"
        // copy info from these n.$k.$v to X/$k/$v
        keys.forEach(([k, v]) => {
            // the keys
            const kx = this.X.i_k(k, n);
            
                // this is under X/$k
                // have their values via unique id  
                kx.i_v(v, n);
            // so you have to look up all keys if you want all values
        });
        return n
    }


    // look for these keys if $key=1, or the value as well.
    //  good for iterating
    // the X/$k(/$v) /$n give us a list of $n
    //   which we then just grep for the rest of properties
    //  as opposed to:
    //   > thinking about going into particular X/$k/$v, depending on $key=1
    //   > joining many reads on the X/$k/$v table
    // o(...)[0] for the first row
    //  given that there is q.one_value_mode etc this could return type |TheC|any
    //   but it really confuses LLMs, only oai() and r() return TheC...
    o(sc?:TheUniversal,q?):TheN {
        q ||= {}
        sc ||= {}
        // bold call, avoids "Svelte error: state_unsafe_mutation" from a component doing C.o()
        if (!this.X) return []
        // < q might be a Travel...?
        this.Xify()

        let M = this.o_query(sc,q)
        return this.o_results(M,sc,q)
    }
    // rarely used.
    // if in replace(),
    //  o() from before the replace began
    //  which would have the complete set of stuff
    //   while the new one is filling itself out
    // else
    //  < give the w|req's last post-do_fn state on X_stable ?
    //   < implies we might have X_testing
    //      virtualise C particularity entirely into X?
    bo(c?:TheUniversal,q?):TheN {
        q ||= {}
        q.X ||= this.X_before
        if (!q.X) return []
        return this.o(c,q)
    }

    // ob: o() with version tracking for UItime $effect / $derived.
    // Use when reading a watched-destination TheC from a UI component:
    //   H.ave.ob({ examining: 1 })
    // Reads this.version (Svelte tracks it), then queries this/*.
    // H.ave.version is only bumped by Housing's flush() after all_clear(),
    // so $effects re-run exactly once per settled beliefs cycle.
    ob(c?:TheUniversal,q?):TheN {
        void this.vers // may be UI-buffered in the future...
        return this.o(c,q)
    }

    // returning null rather than empty arrays if no rows
    //  good for boolean logic, is a presence check
    oa(c?:TheUniversal,q?):TheN|undefined|null {
        return nonemptyArray_or_null(this.o(c,q))
    }
    boa(c?:TheUniversal,q?):TheN|undefined|null {
        return nonemptyArray_or_null(this.bo(c,q))
    }

    // q||q.one_column_mode =
    //  $k returns [v+] in that column, from the resultant /$n/.sc.$k
    //  1 returns the first column mentioned in sc (javascript hashes are ordered)
    //  0 returns the first value of the first column (in the query)
    one_column_mode_q(q) {
        if (typeof q == "number" || typeof q == "string") q = {one_column_mode:q}
        q ||= {}
        q.one_column_mode ??= 1
        return q
    }
    o1(sc?:TheUniversal,q?:number):Array<any>|any|undefined {
        q = this.one_column_mode_q(q)
        sc ||= {}
        // < q might be a Travel...?
        this.Xify()

        let M = this.o_query(sc,q)
        return this.o_results(M,sc,q)
    }
    bo1(c?:TheUniversal,q?):TheN|undefined|null {
        q = this.one_column_mode_q(q)
        return this.bo(c,q)
    }
    oa1(c?:TheUniversal,q?):TheN|undefined|null {
        return nonemptyArray_or_null(this.o1(c,q))
    }
    boa1(c?:TheUniversal,q?):TheN|undefined|null {
        return nonemptyArray_or_null(this.bo1(c,q))
    }

    // oai | roai | _foc | place — the find-or-create keyworkings — live on
    //  StuffAware (the layer that also knows the %req protocol), so oai's req
    //   branch and roai's async replace sit together one wall above Stuff.


//#endregion
//#region Stuff askies
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
            if (typeof q.exactly === 'object' ? q.exactly[k] : q.exactly) {
                if (v === 1) v = "1" // < less of a hack
            }
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
    //  could also do sorting or joining...
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
        
        // wildcard {$k:1} but not {$k:"1"}
        if (value == 1 && typeof value == 'number') return true
        
        return n.sc[key] == value;
    }

//#endregion
//#region Stuff util
    // lematch — generalised rule matcher
    //   { matching_any: [{sc_has:{...}} | {sc_only:{...}}],
    //     means: { skip?, munging?, thence_matching? } }
    //  sc_has: like .o(), C contains (at least) these keys/values.
    //  sc_only: C contains exactly these keys/values and no more.
    lematch(rules: any[] = []): {
        skip: boolean
        munging: any[]
        thence: any[]
    } {
        const munging: any[] = []
        const thence: any[] = []
        let skip = false
        const seen = new Set<string>()

        for (const rule of rules) {
            const matched = (rule.matching_any as any[]).some((entry: any) => {
                if ('sc' in entry) throw `lematch rule uses deprecated key 'sc' — rename to 'sc_has'`
                if (entry.sc_only) {
                    const want = Object.keys(entry.sc_only)
                    if (Object.keys(this.sc).length !== want.length) return false
                    return this.matches(entry.sc_only)
                }
                return this.matches(entry.sc_has)
            })
            if (!matched) continue
            for (const m of rule.means?.munging ?? []) munging.push(m)
            if (rule.means?.skip) skip = true
            for (const tw of rule.means?.thence_matching ?? []) {
                const key = JSON.stringify(tw)
                if (!seen.has(key)) { seen.add(key); thence.push(tw) }
            }
        }

        return { skip, munging, thence }
    }
}

// the async keyworking wall, and the one protocol Stuff knows: %req.
//  StuffAware holds the find-or-create verbs (oai merges in place, sync, %req-aware;
//   roai replaces → new ref, async, no %req) plus place, and the req machinery
//    (do | finish | all_finished | doai | maybe_mutate_sc).  %req is the
//     ONLY property Stuff.svelte.ts treats as meaningful — a %req child is a unit
//      of work this layer can pump, settle and re-key; everything else is opaque sc
//       (bar the splash in TheUniversal).  These verbs call this.r() | this.replace()
//        which land in Stuff (a subclass): the wall order is io → aware → … → Stuff,
//         so the reaction verbs sit just above the replace they invoke — fine at
//          runtime, where `this` is always a TheC carrying the lot.
abstract class StuffAware extends StuffIO {
    // these ride the concrete TheC (c | sc) and Stuff (r | replace) below; declared
    //  here so the %req verbs + place that lean on them typecheck on this wall.
    //  `this` is always a TheC at runtime — the abstract bases are never minted.
    declare c: TheEmpirical
    declare sc: TheUniversal
    declare r: (pattern_sc: TheUniversal, sc?: TheUniversal) => Promise<TheC>
    declare replace: (pattern_sc: TheUniversal, fn: Function, q?: any) => Promise<any>

    // _foc — sync find-or-create + merge, shared by oai and roai.  Returns {made}
    // on a fresh insert, else {existing, changed, full}; the on-change reaction
    // (oai bumps, roai replaces) is the caller's, not ours.
    //  ex() is merge-only — it writes full's keys and never deletes — so `changed`
    //  counts only a written key whose value actually differs, never a goner (a key
    //  on the C but absent from the supplied sc).  Counting goners (the old
    //  symmetric hakd) bumps|replaces every call against a C that just carries extra
    //  keys — fatal inside a $derived.  Functions copy through (freshest closure
    //  wins) but never count.
    _foc(s: TheUniversal, c: TheUniversal = {}): {
        made?: TheC, existing?: TheC, changed?: boolean, full?: TheUniversal,
    } {
        const full = { ...s, ...c }
        const existing = this.o(s)[0] as TheC | undefined
        if (!existing) return { made: this.i(full) as TheC }
        const changed = Object.keys(full).some(k =>
            typeof full[k] !== 'function' && typeof existing.sc[k] !== 'function'
            && existing.sc[k] !== full[k])
        ex(existing.sc, full)
        return { existing, changed, full }
    }

    // oai — THE everyday data verb: find-or-create with merge-in-place.  Same ref;
    // when the found C's sc drifts the change merges in place and %version bumps
    // (watchers keyed on %version re-render).  Sync — nothing here awaits.  (Was
    // `moai`; the birth-only oai is gone — to seed a value once without refreshing
    // it, do it by hand: `x.sc.k ??= …`.)
    //  %req is special: a req child is found-or-created with the req preset — a
    //  serial when anonymous (%req:1 → %req:$i), c.up wiring, and on re-key its sc
    //  merges with %mutated:{key:old} (差/hakd); a drifted %permanent+%finished
    //  stage un-finishes so do() re-runs it.  A req is never replaced, only mutated
    //  — its identity rides the ref.
    oai(s, c = {}): TheC {
        // %req triggers the req machine when it is the MAINKEY (classic %req:kind), OR when a
        //  TYPED particle carries the serialise sentinel req:1 behind a real mainkey
        //   (%Pier,pub:…,req → {Pier:1, pub:…, req:1}): the flock shape — the type leads and
        //    req:1 plugs it into the req pump (serial value, c.up wiring, initialdo, do()).
        //     The footgun stays shut: an incidental string value-key ({lematch:1, req:'wants'})
        //      has req !== 1, so it is NOT minted as a req.  do_fn_for then dispatches a typed
        //       serial-req by its MAINKEY (req_Pier), a classic one by its kind (req_handshake).
        if (Object.keys(s)[0] === 'req' || s.req === 1) {
            // maz:1 is implied, never identifying — strip it from the identity match
            //  (a created req drops it below) so a later oai({…,maz:1}) re-finds the
            //   same req instead of minting a duplicate that carries no maz.
            if (s.maz === 1) delete s.maz
            // %req:1 is the serialise-me sentinel — presence-only, never identity.
            //  exactly() would stringify it to "1" and so miss the assigned serial
            //   (%req:2…), minting a fresh duplicate each pass. Re-find on the req's
            //    own identity keys with req left a numeric wildcard; a named req still
            //     matches its name exactly, and a bare anonymous req (no other keys)
            //      has no identity to re-find on, so it always mints fresh.
            const ident = exactly(s)
            let req: TheC | undefined
            if (s.req === 1) {
                delete ident.req
                if (Object.keys(ident).length) req = this.o({ req: 1, ...ident })[0] as TheC | undefined
            } else {
                req = this.o(ident)[0] as TheC | undefined
            }
            if (req) { this.maybe_mutate_sc(req, c); return req }
            // preserve the caller's key order so the MAINKEY is kept: a classic req is
            //  {req:…} (req leads anyway); a typed serial-req is {Pier:…, …, req:1} (the type
            //   leads, req rides behind).  s always carries req here (the gate guarantees it),
            //    so spreading s alone both keeps req present and keeps the type in front.
            const mix: TheUniversal = { ...s }
            // a serialise-sentinel req:1 (anonymous %req:1 OR a typed %…,req:1) wants serial
            //  numbering off the host counter — the serial becomes the %req value.  A named
            //   req keeps its name.  Serials start at 2 ((??1)+1) so they never collide with
            //    the req:1 "please-serialise" sentinel; next is 3, 4, …
            if (mix.req === 1) mix.req = this.c.req_serial = ((this.c.req_serial as number) ?? 1) + 1
            req = this.i(mix) as TheC
            req.c.up = this
            // initial-do pending, stamped at birth — in .c so it never snaps; do()
            //  exposes it as %initialdo for the handler then clears it.
            req.c.initialdo = 1
            Object.assign(req.sc, c)
            if (req.sc.maz === 1) delete req.sc.maz   // maz:1 is implied
            return req
        }
        const r = this._foc(s, c)
        if (r.made) return r.made
        if (r.changed) r.existing!.bump_version()
        return r.existing!
    }

    // roai — replacey oai: find-or-create, but on a drift replace the C via this.r()
    // — a new ref, re-resolved, for where a keyed render watches ref identity.
    // Async (r is async).  NO %req awareness — a new ref would orphan a req's
    // c.up | do_fn | oncelers | child reqs, so use oai for reqs.
    async roai(s, c = {}) {
        const r = this._foc(s, c)
        if (r.made) return r.made
        if (r.changed) return await this.r(s, r.full)
        return r.existing
    }

    // doai — seed a req and return a one-shot do_fn setter (?.(body)), or null once
    // wired (re-entry never re-wires; only do() re-runs the body).  This is what the
    // compiler lowers `oai …` + a BLOCK into.  A do_fn only belongs on a req, so an
    // anonymous c (no %req key) gets the serial preset {req:1,…}.  Sync — oai is sync.
    doai(c: TheUniversal, sc: TheUniversal = {}): ((fn: Function) => void) | null {
        if (!('req' in c)) c = { req: 1, ...c }
        const req = this.oai(c, sc)
        if (req.c.do_fn) return null
        return (fn: Function) => { req.c.do_fn = fn }
    }

    // oai's %req re-merge: merge sc in place, flagging %mutated = {key: old} for the
    //  changed keys (差, hakd) so a do_fn (or mutated_fn) can react.  A %permanent
    //   stage gone quiescent un-finishes on a real change so do() re-runs it with a
    //    fresh initial-do lease.  The first do() clears %mutated, so it stays a
    //     within-beat signal — never snaps.
    maybe_mutate_sc(req: TheC, sc: TheUniversal): void {
        if (!sc || !Object.keys(sc).length) return
        const merged = { ...req.sc, ...sc }
        const diffs = hakd(req.sc, merged)
        if (!diffs.length) return
        const mutated: TheUniversal = {}
        for (const k of diffs) mutated[k] = req.sc[k]
        Object.assign(req.sc, sc)
        req.sc.mutated = mutated
        if (req.sc.permanent && req.sc.finished) {
            delete req.sc.finished
            req.c.initialdo = 1
        }
        req.bump_version()
    }

    //  pump this host's reqs, highest maz first.  %ok is a pass-local satisfied
    //   signal for eternal reqs — re-armed each pass, cleared on entry.  A req that
    //    arms a ttlilt and bows out (stays needs_work) halts the descent.
    async do(fn?: Function): Promise<void> {
        for (const req of this.o({ req: 1 }) as TheC[]) if (req.sc.ok) delete req.sc.ok
        while (true) {
            const needs_work = (r: TheC) => !r.sc.finished && !r.sc.ok
            const N = (this.o({ req: 1 }) as TheC[]).filter(needs_work)
            if (!N.length) return
            const maz_high = Math.max(...N.map(r => (r.sc.maz as number) || 1))
            const level = N.filter(r => ((r.sc.maz as number) || 1) === maz_high)
            for (const req of level) await this._req_do_one(req, fn)
            if (level.some(needs_work)) return
        }
    }

    async _req_do_one(req: TheC, fn?: Function): Promise<void> {
        if (req.sc.finished) throw "do req%finished"
        delete req.sc.ok
        // forget last pass's transient problems before re-running
        await req.r({ waits: 1 }, {}); await req.r({ error: 1 }, {}); await req.r({ see: 1 }, {})
        // resolve the handler the way the walk does — climb c.up to the House for
        //  do_fn_for (req.c.do_fn, the req_$name convention, and mutated_fn).  At
        //  do-time the tree is wired, so the House is always up the chain.
        let H: any = this
        while (H && typeof H.do_fn_for !== 'function') H = H.c?.up
        const handler = fn || H?.do_fn_for(req, { ark: 'req' })?.handler
        if (handler) {
            // first do(): expose the birth-stamped initial-do as %initialdo
            if (req.c.initialdo) { delete req.c.initialdo; req.sc.initialdo = 1 }
            await handler(req)
            delete req.sc.initialdo   // comes off again after the do() — never snaps
        }
        delete req.sc.mutated   // after the handler — a mutated_fn reads it
    }

    //  host settles a child req: yoink its oncelers + their sc keys, drop its
    //   ttlilts, mark %finished (reactive via the bump).
    finish(child: TheC): void {
        if (child.sc.finished) return
        for (const k of Object.keys(child.c.oncelers ?? {})) delete child.sc[k]
        delete child.c.oncelers
        ;(child.o({ ttlilt: 1 }) as TheC[]).map(t => child.drop(t))
        child.sc.finished = 1
        child.bump_version()
    }

    all_finished(): boolean {
        const all = this.o({ req: 1 }) as TheC[]
        return all.length > 0 && all.every(r => r.sc.finished)
    }


    // ensure given things are the only ones in a match
    //  does nothing if the things are already there, reactivity etc
    // good for inserting whole objects, taking over the space
    // Each incoming C gets .is() so replace() skips resume_X — the C owns /* elsewhere.
    async place(pattern_sc: TheUniversal, n: TheC | TheC[]): Promise<void> {
        const N: TheC[] = n instanceof TheC ? [n] : n as TheC[]
        const existing = this.o(pattern_sc) as TheC[]
        if (N.length === existing.length && N.every((c, i) => existing[i] === c)) return
        await this.replace(pattern_sc, () => { for (const c of N) { c.is(); this.i(c) } })
    }
}

// a culture of io
// trivial n/%stuctures and their games
abstract class TimeOffice extends StuffAware {
    // keep a value next to a key
    //  need some other id in the tuple
    //   just eg %openity=$v won't resolve to itself when it changes
    //  eg deliver one final-most bit of %openity advice to your Se.each_fn
    async i_kv(k:string,v:any) {
        let D = this as TheC
        let c = {}
        c[k] = 1
        await D.replace(c,async () => {
            // v=0 shall not exist
            v && D.i({...c,v})
        })
    }

    // for some %timestamp, delta to now, seconds of oldness getter
    ago(gk):number {
        let time = this.sc[gk]
        if (time == null) return Infinity
        return now_in_seconds() - time
    }
    async i_wasLast(label:string,now) {
        if (now) {
            // set it
            await this.replace({wasLast:label,at:1},async () => {
                this.i({wasLast:label,at:now_in_seconds()})
            })
            return 0
        }
        else {
            // measure ago
            let was = this?.o({wasLast:label})[0]
            if (was?.sc.at) return was.ago('at') || 0
            // no was, was last infinitely long ago
            return Infinity
        }

    }
    // < arg a label as well?
    async i_chaFrom(t:string,v:any,q:TheEmpirical) {
        let c = {chaFrom:t}
        let ch = this.o(c)[0]
        let previous_time = ch?.ago('at')
        let was = ch?.sc.v

        await q?.pairs_fn?.(was,v,previous_time)

        if (!ch || v != was) {
            // it changed! or established
            await this.replace(c,async () => {
                ch = this.i({...c,was,v,at:now_in_seconds()})
            })
            await q?.changing_pairs_fn?.(was,v,previous_time)
        }
    }

}

//#endregion
//#region Stuff.replace
export class Stuff extends TimeOffice {
    // replace one thing
    async r(pattern_sc:TheUniversal,sc?:TheUniversal):Promise<TheC> {
        if (!sc) {
            // make an %all:1,wildcards:1 pattern
            sc = pattern_sc
            if (isar(sc)) {
                pattern_sc = sc[0]
            }
            pattern_sc = map(() => 1, pattern_sc)
        }
        else {
            if (sc.sc && sc instanceof TheC) {
                sc = [sc] // entirely, same object
            }
            else if (Object.keys(sc).length) {
                // the pattern|sc divided bunch of language
                sc = {...pattern_sc,...sc}
            }
            else {
                // r({such:1},{}) replaces it with nothing!
                // see also drop(), to hide it from o
                // < figure out the subtleties of either approach to removal
                sc = []
            }
        }
        let C
        await this.replace(pattern_sc, async () => {
            let N = isar(sc) ? sc : [sc]
            for (let s of N) {
                C = this.i(s)
            }
        })
        return C!
    }

    // rm(pattern_sc) — remove: replace the matching %pattern children with
    //  nothing.  Sugar for r(pattern_sc, {}) — the empty sc makes replace()
    //  insert nothing, so the matches are cleared.  Reads less cryptically than
    //  the r(c,{}) idiom it wraps.  See also drop(), which hides a C from o()
    //  without removing it.
    async rm(pattern_sc:TheUniversal) {
        return this.r(pattern_sc, {})
    }

    // resolved C usually resume C/*
    resume_X(a,b) {
        if (!b.c.Isness) {
            b.X = a.X
        }
    }
    // forget C/* - everything in this C
    empty() {
        // this makes Xify() resume and then bump the version
        // < but it also breaks Otro or so, only H:Mundo appears...
        // this.X_before = this.X
        this.X = null
        this.Xify()
        // this.X_before = null
        return this
    }
    // assert this C has Isness, C/* are there already and don't recycle them.
    // marks this C as going to have inners already when resolve() commits
    //  so don't resume its C/* from before
    is() {
        this.c.Isness = 1
        return this
    }

    // redo everything or a subset that we replace things around
    //  inside fn(),
    //   bo() can be used to look at the before time
    //   o() will only have what we've added so far
    //  
    async replace(pattern_sc:TheUniversal,fn:Function,q?:any) {
        // < is perhaps workable if the patterns don't overlap?
        let problemo = 'nested replace() transactions'
        let stacken = () => {
            // < more sanity checks
            const stack = `pattern_sc = ${keyser(pattern_sc)}\n`
                + new Error().stack.split("\n").slice(2).join("\n")
            return stack.split("\n")
        }
        if (OPTIMISE_FOR_DX) {
            // < possibly expensive?
            // note where we're coming from
            const stack = stacken()
            if (this.replace_having) {
                if (!this.X_before) throw "insanity"
                console.error(problemo, {
                    awaiting_stack: this.replace_having,
                    current_stack: stack,
                })
                throw problemo
            }
            this.replace_having = stack
        }
        if (this.X_before) {
            throw problemo
        }
        
        q ||= {}
        q.pattern_sc = pattern_sc
        // move it aside and regenerate another X
        this.Xify() // always have an X_before, including the first time
        this.X_before = this.X
        this.empty()

        // may select a subset to resume everything else around
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
                let pairs = await this.resolve(this.X,this.X_before,partial,q)
                for (let [a,b] of pairs) {
                    if (a && b) {
                        let innered = b.X?.z?.length
                        if (innered && !b.c.Isness) {
                            // < if they have b.i() already? post-hoc resolve()?
                            console.error(`C.replace() resolved n have /*, should you be using C.place()?:\n`
                                +`  C: ${keyser(this)}\n`
                                +`    n: ${keyser(b)}\n`
                                +(b.X.z.map(s => `      s: ${keyser(s)}\n`).join(''))
                                +`via:\n`
                                +(stacken().join("\n"))
                            )
                        }
                        this.resume_X(a,b)
                    }
                    await q.pairs_fn?.(a,b)
                }

                if (q.gone_fn) {
                    for (let [a,b] of pairs) {
                        if (a && !b) {
                            q.gone_fn(a)
                        }
                        
                    }
                }
            }

            if (partial) {
                // as if we .i(), so new rows are at the end
                const IN_ORDER = true
                let X_new = this.X
                if (IN_ORDER) this.empty()
                // put everything else back in
                this.bo().forEach(n => {
                    if (partial?.includes(n)) return
                    // keeping n.c.etc as it is, but already ignoring n.c.drop
                    this.i(n)
                })
                if (IN_ORDER) X_new.z?.map(n => this.i(n))
            }
            
            return result

        } catch (error) {
            // rollback data changes
            this.X = this.X_before

            console.error('Transaction failed:', error)
            throw error

        } finally {
            this.X_before = undefined
            this.replace_having = undefined
            // something probably changed
            //  chase up observers, eg Stuffing, who aren't waiting
            this.X?.bump_version()
        }
    }

//#endregion
//#region Stuff.resolve
    // regard new|gone in here
    // assumes we're going to uniquely identify everything easily
    //  by comparing n.sc.*,
    //   n/* or n.sc.*.*
    // < we could resolve gradually, even one-at-a-time
    // make a series of pairs of $n across time
    async resolve(X:TheX,oldX:TheX,partial:TheN|null,q={}) {
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



        // /$v:neu /$k/$v:stringval /$n=old
        Object.entries(Over.X.neu||{}).forEach(([i,_neux]) => {
            let n = Over.X.neus[i]
            let neux = _neux as TheX
            kv_iter(neux,(k,kx,v,vx) => {
                let possible = vx.z
                // for %nib:dir x20 matching less than %name:veryunique x1
                let unambiguity = 1 / possible.length
                let newly_possible = X.i_k(k)?.i_v(v)?.z?.length
                if (newly_possible) {
                    // it wants to be unique in the past and future.
                    unambiguity = (unambiguity + (1/newly_possible)) / 2
                }
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

        // obvious a == b, can be out of ordered
        for (let n of oldX.z) {
            if (!unfound.includes(n)) continue
            claim(n,n)
        }


        // sort by unambiguity
        // give up on weak reductive logicality
        //  you can break LangTiles playing with this. had to reduce from 0.33 for it.
        let UNAMBIGUITY_THRESHOLD = 0.23
        
        // /$ambiguity=0.234 /$n=neu/$ambiguity=0.234 /$n=old
        let ratings = sort_unambiguity(Over.X)
        ratings.forEach((unambiguity) => {
            if (Number(unambiguity) < UNAMBIGUITY_THRESHOLD) return
            let x = Over.X.unambiguity[unambiguity]
            x.z.forEach((n:TheC) => {
                if (!unfound.includes(n)) return

                // /$v:neu
                let neux = Over.X.i_v(n,null,'neu')
                if (!neux?.k) throw `algo!?k`
                let rated = neux.i_k(unambiguity,null,'unambiguity')
                if (!rated.z.length) throw `algo!?z`
                for (let oldn of rated.z) {
                    if (claimed.includes(oldn)) continue
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
                    if (q.resolve_strict) {
                        // be more likely to drop and recreate things
                        //  if any stringified value has changed
                        let valuesOf = (n) => armap(v=>v+'',n.sc).join(',')
                        if (valuesOf(n) != valuesOf(oldn)) {
                            return
                        }
                    }
                    coms&&coms.i({claiming: keyser(n), oldn: keyser(oldn), score: unambiguity})
                    claim(oldn,n)
                    // once n is claimed, stop claiming oldn for it
                    break
                }
            })
        })

        // what's left in X_before (that we are partial to replacing)
        let gone = partsof(oldX.z||[])
            .filter(oldn => !claimed.includes(oldn))
        
        // log it all
        if (coms) {
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


//#region see Selection
// which naturally comes about here
//  but is too large






//#region Stuffing
// a look at some Stuff
//  to come springing out of Modus.
// < the universal, an experiential perspective
// Stuffing - whole island of Stuff
//  / Stuffusion - the compressed identity of some rows
//  / Stuffziad - the k:v presentation, may be a compressed identity
//  / Stuffziado - one value

// whole island of Stuff — a look at some Stuff, springing out of Modus.
//  one $state write per update (this.groups = next), nothing else reactive.
//  H drives commits inside H.clear() so siblings batch into one Svelte flush.
export class Stuffing {
    Stuff: Stuff
    // the one and only reactive surface. one write per commit, never mutated piecemeal.
    groups: Map<string, Stuffusion> = $state(new Map())
    started = $state(false)
    matchy?: Matchy
    // self_row: the single row is the %Stuff particle ITSELF (its own k:v), not its children —
    //  how a leaf or structural particle renders as a stuffing (Cyto chunk self-mode)
    self_row?: boolean

    constructor(Stuff: Stuff, matchy?: Matchy) {
        this.Stuff = Stuff
        this.matchy = matchy
        // < no $effect, no internal subscription. H is the only driver.
    }

    // matchy-aware row selection from %Stuff
    get_matching_rows(): TheN {
        if (this.self_row) return [this.Stuff as unknown as TheC]
        let matches = this.matchy?.see || []
        if (!matches.length) matches = [{}]
        let N: TheN = []
        for (let sc of matches) {
            for (let n of this.Stuff.o(sc)) {
                if (N.includes(n)) continue
                N.push(n)
            }
        }
        let unmatches = this.matchy?.hide || []
        for (let sc of unmatches) {
            N = N.filter((n: TheC) => !n.matches(sc))
        }
        return N
    }

    // pure: reads %Stuff and %matchy, builds a complete tree of Stuffusion/Stuffziad/Stuffziado,
    //  returns the new groups Map. Writes nothing reactive.
    //  Safe to call from anywhere; the caller commits when sibling Stuffings have also computed.
    compute_groups(): Map<string, Stuffusion> {
        // phase 1: group like /things into a tmp /Stuff so columns line up nicely
        const grouped = _C()
        this.get_matching_rows().forEach((n: TheC) => {
            const ks = Object.keys(n.sc)
            let matchness = 0
            let match: TheC | null = null
            grouped.o().forEach((c: TheC) => {
                // leave apart if more than one key is different
                const different_keys = ks.filter(k => !Object.hasOwn(c.sc, k)).length
                if (different_keys > 1) return
                // or if certain keys' values are different
                if (n.sc.dome != c.sc.dome) return
                // prefer 0 different keys to 1
                // < fuzzier matching, lots complicated. graph partitioning with cytoscape?
                const same_keys = ks.filter(k => Object.hasOwn(c.sc, k)).length
                const matched = same_keys - different_keys
                if (matched <= matchness) return
                match = c
                matchness = matched
            })
            if (match && matchness >= ks.length - 1) {
                // groups members with <= 1 odd key
                // < this could use Stuff.i_z() for speed, only needs X.z
                match.i(n)
            }
            else {
                // group labeled, copies k:v
                // < more clean and proper to look at match/$n[0]
                //    instead of copying the first datum to match itself?
                match = _C({ name: ks.join(','), sc: { ...n.sc } })
                match.i(n)
                grouped.i(match)
            }
        })

        // phase 2: turn each group into a Stuffusion/Stuffziad/Stuffziado tree
        const next = new Map<string, Stuffusion>()
        grouped.o().forEach((n: TheC) => {
            // uniquely identify them
            let name = n.name || 'unnamed'
            name = name_numbered_for_uniqueness_in_Set(name, next)
            const rows = n.o()
            const stuffusion = new Stuffusion(this, name, rows)
            // do any rows have n.X, nest Stuffing
            stuffusion.detect_nX(rows)

            // add columns — there may be odd ones out (many of them) from c.sc
            const column_names = Object.keys(n.X.k || {})
            column_names.forEach((key) => {
                const kx = n.X?.o_kv(key, 1)
                if (!kx) throw "!kx"
                const stuffziad = new Stuffziad(stuffusion, key, kx.z)

                // vs contains the unique values, v contains the TheX for each
                const values = kx.vs || []
                const valueXs = kx.v || []
                values.forEach((val, idx) => {
                    const vx = valueXs[idx]
                    // count how many $n have this value (from vx.z)
                    const vx_rows = vx?.z || []
                    const display_name = objectify(val, -1)
                    const val_name = name_numbered_for_uniqueness_in_Set(display_name, stuffziad.values)
                    const stuffziado = new Stuffziado(stuffziad, val_name, vx_rows)
                    stuffziado.value = val
                    stuffziado.display_name = display_name
                    if (display_name == '1') stuffziado.is_one = true

                    // note some interesting features
                    const innerables = [...vx_rows]
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
                if (Array.from(stuffziad.values.values()).every(s => s.is_one)) {
                    stuffziad.is_one = true
                }
                stuffusion.columns.set(stuffziad.name, stuffziad)
            })
            next.set(stuffusion.name, stuffusion)
        })

        return next
    }

    // one $state write — Svelte sees the whole new tree at once.
    //  call inside H.clear() so all sibling Stuffings commit in the same flush.
    commit(next: Map<string, Stuffusion>) {
        this.groups = next
        this.started = true
    }

    // backward-compat wrapper for callers outside H.clear() (eg tests, debugging)
    brackology() {
        this.commit(this.compute_groups())
    }
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
    columns = new SvelteMap<string, Stuffziad>()
}
// a group of k:v, name is the key
export class Stuffziad extends Stuffuzia {
    values = new SvelteMap<string, Stuffziado>()
    is_one?: boolean // meaning all our stuffziado.is_one
}
// single value, name is serial number?
export class Stuffziado extends Stuffuzia {
    value: any
    is_string?: boolean
    is_C?: boolean
    display_name?: string
    is_one?: boolean
}




//#endregion
//#region TheC
// only some properties.
//  the universal is particularly fond of you making them up.
export type TheUniversal = {
    waits: string,
    D: TheC,
    bD: TheC,
    n: TheC,
    name: string,
    needs_doing: boolean,
    buffer: ArrayBuffer
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

    // The %req machinery (oai's req preset, doai, do, finish, all_finished,
    //  maybe_mutate_sc, _req_do_one) lives one wall up, on StuffAware — %req is the
    //  one protocol Stuff.svelte.ts knows.  TheC just adds the .c/.sc typing.
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
//#region f

export function keyser(n:TheC|Object,loop=0) {
    let la:Array<string> = []
    Object.entries(n.sc || n).forEach(([k,v]) => {
        if (loop>0) {
            // we've got to stop zooming down into v
            la.push(k)
        }
        else {

            la.push(k+":"+objectify(v,loop+1))
        }
    })
    let Cprefix = n instanceof TheC ? "%" : ""
    return Cprefix+la.join(", ")
}
// > when q.one_value_mode, we may want a [] value
function nonemptyArray_or_null(N:any) {
    if (N?.length) return N
    return null
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
export function objectify(v:any,loop=-1,gutsy=false):string {
    let s = String(
        typeof v == 'number' || typeof v == 'string' ? v
        : v == null ? 'null'
        : v.constructor == Array ? `[${
            loop>0 ? "x"+v.length
                : v.map(n => objectify(n,loop+1)).join(',')
        }]`
        : v.constructor == TheC ? `${keyser(v,loop+1)}`
        : v.constructor == Boolean ? `${v}`
        : `${v.constructor.name}(${gutsy ? keyser(v,loop+1) : ''})`
    )
    let where = 77
    if (s.length > 100) s = s.slice(0,where)+"..."+(s.length-where)
    return s
}

export function name_numbered_for_uniqueness_in_Set(name,set) {
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

//#endregion