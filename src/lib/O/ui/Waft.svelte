<script lang="ts">
    // Waft.svelte — one Waft item in the recursive Waft tree.
    //
    // A Waft is generic-C number one: a named, persistable container — an INDIFFERENT
    // MEDIUM in which you expect Whats, Docs and Points. Strip away everything that once
    // looked like Waft-schema and the floor is just an identity that is also its home
    // (`Waft:<path>`, where it snaps) plus a bag of C children. That is irreducible —
    // nothing about how we do a Waft gets simpler than a named container that holds.
    //   Its FACE is not a kind on the Waft — it is just the Waft's main Funkcion, a
    //   `%Funkcion,main` child resolved through FUNK_KINDS and mounted by FunkHost (see
    //   main_funk below); DocTing rides Funkcion:Ting, DocGhostList rides Funkcion:dirlist.
    //   takes|aside|minimised|equip are STANCES — plain %-properties a lens reads —
    //   never render branches in here.
    //   So this file knows only Waft/What/Doc/Point and "mount the main Funkcion"; it
    //   knows nothing of Ting, GhostList or any applet. The attention that rides a Waft
    //   (Interest), its persistence (the Keep) and the editor surface (Lang) all live
    //   elsewhere — a Waft is the indifferent medium they share. See spec/Interest.md.
    //
    // Mechanics — a stable component boundary extracted from Liesui: Svelte reconciles
    // {#each} items by key (waft.sc.Waft) so this survives Liesui re-renders, keeping form
    // state and focused inputs stable across think() ticks. One <PeelInput> via pi(); one
    // item wrapper via waftitem(C, upC) — type from C.sc mainkey, children from C.o({}),
    // all personality from ITEM_TYPES (the header row is itself waftitem(waft, waft), no
    // separate header block).

    import type { TheC }    from "$lib/data/Stuff.svelte"
    import type { House }   from "$lib/O/Housing.svelte"
    import { peel, depeel } from "$lib/Y.svelte"
    import { SvelteSet }    from "svelte/reactivity"
    import { tick }         from "svelte"
    import EncodingSplatter from "$lib/O/ui/EncodingSplatter.svelte"
    import PeelInput        from "$lib/O/ui/PeelInput.svelte"
    import Waft             from "./Waft.svelte"                      // self-import for the recursive sub-Waft render (replaces deprecated <svelte:self>)
    import FunkHost          from "$lib/O/Funk/FunkHost.svelte"     // generic host for %Funkcion embeds (kind-dispatched) — incl. a Waft's BIG main face
    import { FUNK_KINDS }     from "$lib/O/Funk/kinds"               // registry: which kinds have a live component
    import Orb                from "$lib/O/ui/micro/Orb.svelte"      // shared edit/crud toggle (ui/micro/)

    let { H, w, waft, depth = 0, on_active, on_delete, examining, on_hover }: {
        H:         House
        w:         TheC          // Lies's w particle — for live state downstream
        waft:      TheC
        depth?:    number
        on_active: (waft: TheC) => void
        on_delete: (waft: TheC) => void
        examining?: TheC         // from Liesui; derives Spotlight glow targets
        on_hover?: (waft_key?: string) => void   // reports mouse-over up to Liesui (the
                                                 //  searchbar's StemHive glows member rows);
                                                 //  top-level only — Liesui doesn't thread it
                                                 //  into the recursive sub-Waft render
    } = $props()

    // ── item-type descriptor table ────────────────────────────────────
    //
    //   Every behavioural difference between Point/Doc/What lives here.
    //
    //   mk_key:       sc key that identifies this type (first key in sc)
    //   mk_ph:        mainkey input placeholder
    //   sc_ph:        sc extras placeholder
    //   make_sc:      builds the oai() sc from (val, sc_str)
    //   on_open:      navigation action when the display value is clicked
    //   item_cls:     CSS class(es) on the .ls-item wrapper
    //   item_cls_fns: dynamic class predicates — {cls: string, when: (C)=>bool}[]
    //   child_types:  ItemTypes allowed as add-child options; undefined = leaf (no children)
    //   can_add:      whether this type shows + (add-child picker) in its header
    //   spotlight:    whether this type participates in the Spotlight glow
    //
    //   display is handled by the shared item_to_display() below
    //   < Doc: directory-list autocomplete for Ghost/* paths
    //   < Doc: bare name auto-prefixes Ghost/ and appends .g
    const ITEM_TYPES = {
        Waft: {
            mk_key:     'Waft' as const,
            mk_ph:      'path/to/waft',
            sc_ph:      'tag:foo',
            make_sc:    (val: string, sc_str: string) => ({
                Waft: val,
                ...(sc_str ? peel(sc_str) : {})
            }),
            // < rename is a no-op here — backend rewrites %Waft on load/save to new path
            on_open:    (_item: TheC) => on_active(waft),
            item_cls:   'ls-item ls-item-waft',
            item_cls_fns: [
                { cls: 'ls-item-waft-active', when: (_c) => is_active },
            ] as { cls: string; when: (c: TheC) => boolean }[],
            child_types: ['What', 'Doc', 'Point'] as ItemType[],
            can_add:    true,
            spotlight:  false,
        },
        Point: {
            mk_key:     'Point' as const,
            mk_ph:      'fuzzyName',
            sc_ph:      'method:Name,call',
            make_sc:    (val: string, sc_str: string) => ({
                Point: val === '' ? 1 : val,
                ...(sc_str ? peel(sc_str) : {})
            }),
            on_open:    (item: TheC, dpath?: string) =>
                H.i_elvisto('Lang/Lang', 'Dock_open', {
                    path:  dpath,
                    point: (item.sc as any).method ?? item.sc.Point,
                }),
            item_cls:   'ls-item ls-item-point',
            item_cls_fns: [] as { cls: string; when: (c: TheC) => boolean }[],
            child_types: undefined,   // leaf — no children
            can_add:    false,
            spotlight:  false,
        },
        Doc: {
            mk_key:     'Doc' as const,
            mk_ph:      'Ghost/…',
            sc_ph:      'tag:foo',
            make_sc:    (val: string, sc_str: string) => ({
                Doc: resolve_doc_path(val),
                ...(sc_str ? peel(sc_str) : {})
            }),
            on_open:    (item: TheC) => focus_doc(item),
            item_cls:   'ls-item ls-item-doc',
            item_cls_fns: [
                { cls: 'ls-item-doc-new',     when: (c) => !!c.sc.new },
                { cls: 'ls-item-doc-missing', when: (c) => !!c.sc.not_found && !c.sc.new },
            ],
            child_types: ['Point', 'What'] as ItemType[],
            can_add:    false,
            spotlight:  false,
        },
        What: {
            mk_key:     'What' as const,
            mk_ph:      'label',
            sc_ph:      'tag:foo',
            make_sc:    (val: string, sc_str: string) => ({
                What: val,
                ...(sc_str ? peel(sc_str) : {})
            }),
            on_open:    (item: TheC) =>
                H.i_elvisto('Lies/Lies', 'Lies_cursor_what', { what: item, dive: true }),
            item_cls:   'ls-item ls-item-what',
            item_cls_fns: [
                { cls: 'ls-item-what-active', when: (c) => is_spotlight(c) },
            ],
            child_types: ['Point', 'Doc', 'What'] as ItemType[],
            can_add:    true,
            spotlight:  true,
        },
    } as const
    // spelled out, not keyof typeof ITEM_TYPES — the table's own child_types use
    //  `as ItemType[]`, so deriving the type from the table would close a cycle
    //   that collapses ITEM_TYPES to `any`.  Keep in step with the keys above.
    type ItemType = 'Waft' | 'Point' | 'Doc' | 'What'

    // ── item_to_display — split display for any item C ───────────────
    //
    //   Returns { val, sc } separately so PeelInput can style them at different sizes.
    //   val:  mainkey value string — empty when :1 (label alone covers it)
    //   sc:   extras as depeel string — keys beyond the mainkey
    //
    //   eg {Point:1, method:'transport'} → { val:'',           sc:'method:transport' }
    //      {Point:'MyThing'}             → { val:'MyThing',     sc:'' }
    //      {What:'label', tag:'foo'}     → { val:'label',       sc:'tag:foo' }
    //      {Doc:'Ghost/foo.g'}           → { val:'Ghost/foo.g', sc:'' }
    //   What val falls back to '·' when both empty so the row has a visible click target.
    //   Internal state keys (active, new, not_found) are excluded from sc extras.
    const DISPLAY_SKIP = new Set(['active', 'new', 'not_found', 'desc'])
    function item_to_display(c: TheC, t: ItemType): { val: string; sc: string } {
        const sc_obj = c.sc as Record<string, any>
        const mk_key = ITEM_TYPES[t].mk_key
        const mk_val = sc_obj[mk_key]
        const sc = Object.entries(sc_obj)
            .filter(([k]) => k !== mk_key && !DISPLAY_SKIP.has(k))
            .map(([k, v]) => v === 1 ? k : `${k}:${v}`)
            .join(',')
        const val = (mk_val === 1 || mk_val === true) ? '' : String(mk_val ?? '')
        return { val: (!val && !sc && t === 'What') ? '·' : val, sc }
    }

    // ── PiProps — the full set of props pi() accepts ──────────────────
    type CrudProps = {
        orb_open:            boolean
        on_orb:              () => void   // opens irow AND immediately starts edit
        on_cancel_orb:       () => void   // cancel edit and close irow together
        on_del:              () => void
        // C inputs: first typed char seeds draft_mk and opens the add form
        on_start_after?:     (char: string) => void
        on_start_in?:        (char: string) => void
        // type buttons: open the add form without pre-seeding mainkey
        on_pick_after_type?: (t: string) => void
        on_pick_in_type?:    (t: string) => void
        add_types?:          string[]
    }
    type PiProps = {
        label:         string
        open:          boolean
        display_val?:  string          // idle: mainkey value (big)
        display_sc?:   string          // idle: extras sc string (small)
        mk_ph?:        string
        sc_ph?:        string
        mk_is_one?:    boolean         // mainkey value is :1 — label shows as comma-key
        mainkey?:      string
        on_mk?:        (v: string) => void
        sc_str?:       string
        on_sc?:        (v: string) => void
        focus_sc?:     boolean
        submit_label?: string
        on_open?:      () => void      // navigate — whole label/val row
        on_submit:     () => void
        on_cancel:     () => void
        on_crud?:      CrudProps       // orb + irow; absent on add-child forms
    }

    function resolve_doc_path(raw: string): string {
        const v = raw.trim()
        if (!v) return ''
        // bare name with no slash → Ghost/Name.g
        if (!v.includes('/')) return `Ghost/${v.includes('.') ? v : v + '.g'}`
        return v
    }

    // ── item_type_of — detect type from mainkey ───────────────────────
    //   Returns the ItemType whose mk_key is the first key in C.sc, or undefined.
    function item_type_of(c: TheC): ItemType | undefined {
        const first_key = Object.keys(c.sc ?? {})[0] as ItemType | undefined
        if (first_key && first_key in ITEM_TYPES) return first_key
        return undefined
    }

    // ── reactive reads ────────────────────────────────────────────────
    let wkey          = $derived(waft.sc.Waft as string)
    let is_active     = $derived(!!waft.sc.active)
    let sub_wafts     = $derived((() => { void waft.version; return waft.o({ Waft: 1 }) as TheC[] })())
    let waft_mungs    = $derived((() => { void waft.version; return waft.o({ mung_error: 1 }) as TheC[] })())
    // a taker Waft (the attention Ting) keeps a flavour border; its FACE now rides a main
    //  Funkcion like any other (see main_funk), not a hardwired branch.
    let is_taker      = $derived(!!waft.sc.takes)
    // raw — the face⇄data toggle for a main-Funkcion Waft: show the big face, or peek at
    //  the raw child tree behind it.  (Was the per-Ting|GhostList switcheroo, now generic.)
    let raw           = $state(false)

    // ── per-Waft view controls ────────────────────────────────────────────────
    //   minimised:  collapse the body to just the control bar (the wkey stays as a tab).
    //                PROJECTED from the Keep (Lies_keep_cfg) — per-Waft "how it's pitched"
    //                 memory lives in the Keep's ledger, NOT on the Waft, so it survives reload
    //                  (even the dontSnap Cluster) and the Keep owns it.  absent = open; an
    //                   %equip fixture is seeded collapsed in the Keep (Lies_aim).
    //   capstate:   the body height stance.  'tall' (default) caps at ~half the screen and
    //               scrolls inside — one huge Waft can't eat the page, and the cursor-follow
    //                effect below keeps the working row in view.  'tight' is the old Vexpany
    //                 10em park; 'free' is infinite growth (the old default, now the opt-out).
    //   sidebyside: halve this Waft's width.  The parent list (.ls-waft-section) is a
    //               flex-wrap row, so two adjacent half-Wafts pair onto one line by
    //               themselves — no parent bookkeeping, the wrap does the pairing.
    //   capstate|sidebyside stay ephemeral — render-only, never reach the C/snap.
    // On the runner there is no Keep to persist to, so minimise is session-local: a plain $state,
    //  toggleable but NOT saved, seeded from the infra default below.
    let local_min = $state<boolean | undefined>(undefined)
    let minimised  = $derived((() => {
        const keep = w.o({ Waft: 'Keep' })[0] as TheC | undefined
        void (keep?.version ?? w.version)                       // re-derive when the Keep changes|loads
        const stored = H.Lies_keep_cfg_get(w, wkey, 'minimised')
        if (stored !== undefined) return !!stored              // an explicit persisted choice always wins
        if (keep) return false                                 // editor, no flag → open (Lies_aim seeds %equip closed)
        // no Keep at all (the runner): session-local, seeded from the BACKSTAGE INFRA default —
        //  Trope/entropy profiles + dontSnap scaffolding start closed (not working surfaces), a
        //   giver Waft starts open.  Toggleable in-session (toggle_minimised), just not persisted.
        return local_min ?? !!(waft?.sc.equip || waft?.sc.boring || waft?.sc.dontSnap)
    })())
    // toggle: persist through the Keep on the editor; fall back to session-local state on the runner.
    const toggle_minimised = () => {
        if (w.o({ Waft: 'Keep' })[0]) H.Lies_keep_cfg_set(w, wkey, 'minimised', minimised ? undefined : 1)
        else local_min = !minimised
    }
    let capstate   = $state<'tall' | 'tight' | 'free'>('tall')
    const cycle_cap = () => capstate = capstate === 'tall' ? 'tight' : capstate === 'tight' ? 'free' : 'tall'
    let sidebyside = $state(false)
    let body_el    = $state<HTMLElement | undefined>(undefined)

    // ── cursor-follow ─────────────────────────────────────────────────
    //   When the Spotlight MOVES to a new src under THIS Waft (nearest Waft owns the scroll),
    //    nudge the glowing What row into the body's scroll window.  Reactivity discipline
    //     (reactivity_docs): subscribe on vers only, re-read the settled tree inside H.clear —
    //      a bare read here can catch a transacting (momentarily empty) state.  And the scroll
    //       is scrollTop math on the BODY ALONE — never scrollIntoView, which also scrolls the
    //        window, so every trickle think() yanked the page (the "impossible to run tests"
    //         regression).  The page must never move except by the user's own hand.
    let last_spot: any = undefined
    $effect(() => {
        void examining?.vers
        H.clear(async () => {
            const spot = examining?.o?.({ Spotlight: 1 })?.[0] as any
            const src  = spot?.sc.src
            if (!src || src === last_spot) return           // only a real cursor MOVE scrolls
            last_spot = src
            let node: any = src
            while (node && node.sc?.Waft === undefined) node = node.c?.up
            if (node !== waft) return
            const row = body_el?.querySelector('.ls-item-what-active') as HTMLElement | null
            if (!row || !body_el) return
            const bt = body_el.getBoundingClientRect(), rt = row.getBoundingClientRect()
            if      (rt.top    < bt.top)    body_el.scrollTop += rt.top - bt.top - 8
            else if (rt.bottom > bt.bottom) body_el.scrollTop += rt.bottom - bt.bottom + 8
        })
    })

    // Embedded applets (%Funkcion) render through FunkHost — the kind module owns the
    //  pad/light, the strike, and the armed glow.  See O/Funk/.

    // ── inline Funkcions ↔ editable C (the per-What negotiation) ──────────────────────
    //   A What full of Funkcions reads best as its illusions flowed inline, not a bullet list of
    //    structural rows.  Waft_dip stamps `c.inlined` on such a What at load (a suggestion); an
    //     author can force it with `%What:Label,inline`.  An inlined What lays its children out in
    //      a compact flow and shows them live (the Storying lights, the StoryTimes station).
    //   That illusion carries its own affordance: a ✎ on the What toggles it to the conventional
    //    bullet C**, where each Funkcion node becomes an editable plain-C PeelInput row — so you
    //     edit the Funkcion node itself, then ◉ back to the live inline view.  struct_what holds
    //      the Whats currently flipped to that editing presentation (session-local).
    let struct_what = new SvelteSet<TheC>()
    function toggle_struct(C: TheC) {
        if (struct_what.has(C)) struct_what.delete(C); else struct_what.add(C)
        waft.bump_version()
    }
    const what_inlined  = (C: TheC) => C.sc.inline !== undefined || !!C.c.inlined
    const has_funk_child = (C: TheC) => (C.o() as TheC[]).some(k => k.sc.Funkcion !== undefined)

    // ── editing a Funkcion node as plain C (no ItemType — peel/depeel its whole sc) ──
    //   A %Funkcion's mainkey isn't an ITEM_TYPE, so it has no PeelInput of its own.  In a What's
    //    editing presentation we render it as a generic C row: idle shows the depeeled line ("the
    //     usual plain Waft C"), the orb opens a PeelInput that peels the typed text straight back
    //      into the funk's sc — the mainkey is whatever you type.  raw_edit_C marks a funk whose
    //       open form submits this way (vs an ItemType edit).
    const raw_edit_C = new WeakSet<TheC>()
    const DISPLAY_SKIP_C = new Set(['active', 'new', 'not_found', 'created_at'])
    function raw_display(c: TheC): { mk: string; sc: string } {
        const ents = Object.entries(c.sc as Record<string, any>).filter(([k]) => !DISPLAY_SKIP_C.has(k))
        const tok  = ([k, v]: [string, any]) => v === 1 ? k : `${k}:${v}`
        return { mk: ents[0] ? tok(ents[0]) : '', sc: ents.slice(1).map(tok).join(',') }
    }
    function start_edit_raw(funk: TheC) {
        editing.clear(); editing.add(funk); raw_edit_C.add(funk)
        const d = raw_display(funk); draft_mk = d.mk; draft_sc = d.sc; draft_focus_sc = false
    }
    async function submit_edit_raw(container: TheC, funk: TheC) {
        const text = [draft_mk.trim(), draft_sc.trim()].filter(Boolean).join(',')
        const sc   = peel(text)
        if (!Object.keys(sc).length) return
        Object.keys(funk.sc).forEach(k => delete funk.sc[k])
        Object.assign(funk.sc, sc)
        container.bump_version(); waft.bump_version()
        await tick()
        editing.delete(funk); raw_edit_C.delete(funk)
    }
    // open_raw_edit — flip a Funkcion (live or bare) into its plain-C edit row.  Shared by
    //  the live-view orb and raw_props' orb so both land in the same edit+irow state.
    function open_raw_edit(funk: TheC) {
        orb_open_C.clear(); editing.clear()
        orb_open_C.add(funk); start_edit_raw(funk)
    }
    // funk_kind / funk_live — a Funkcion's kind, and whether that kind has a registered
    //  live component.  An unregistered or face-less kind (comp_<Lens>-only, e.g. Runner) has
    //   no illusion to host, so it renders as a plain editable C row instead of an orb beside
    //    an empty applet.
    const funk_kind = (c: TheC) => c.sc.Funkcion as string | undefined
    const funk_live = (c: TheC) => { const k = funk_kind(c); return k != null && FUNK_KINDS[k]?.component != null }

    // main_funk — the Waft's MAIN Funkcion: a direct %Funkcion,main child whose kind has a
    //  live face (FUNK_KINDS[kind].component).  When present the Waft body renders THAT face
    //   (the close-up Lens — DocTing, DocGhostList, …) instead of its raw child tree; the ⤺
    //    toggle peeks at the data behind it.  Generic + property-driven: any registered
    //     big-face Funkcion marked %main, never a hardwired DocTing|DocGhostList branch.
    const main_funk = $derived.by(() => {
        void waft.version
        return (waft.o({ Funkcion: 1 }) as TheC[]).find(f => f.sc.main && funk_live(f))
    })

    // ── unified item-edit form state ──────────────────────────────────
    //
    //   editing: the one C currently open for editing/adding.
    //   Since only one form is ever open, a single $state pair holds the draft.
    //   draft_type lives in a WeakMap (non-reactive; read only on submit).
    //
    //   add_type_C:    the chosen ItemType for the pending add-form.
    let editing      = new SvelteSet<TheC>()
    let orb_open_C   = new SvelteSet<TheC>()   // items whose irow is currently visible
    let draft_mk     = $state('')
    let draft_sc     = $state('')
    let draft_focus_sc = $state(false)   // focus sc field instead of mainkey on open
    const draft_type = new WeakMap<TheC, ItemType>()
    const add_type_C   = new WeakMap<TheC, ItemType>()
    // containers whose pending add is a *raw* C — the plain "C" box, no imposed
    //  mainkey: the typed text is peel()'d straight into the sc, so the mainkey is
    //  whatever you type, not a forced ItemType.
    const add_raw_C    = new WeakSet<TheC>()
    const orb_trigger  = new WeakMap<TheC, TheC>()    // container → item whose orb opened this add

    // ── add-item form ─────────────────────────────────────────────────
    //
    //   pick_and_open: add a child inside container (appends to container.X.z).
    //   pick_and_open_after: add a sibling after item (splices into container.X.z).
    //     after_item is stored in a WeakMap so submit_add_after knows where to splice.
    const after_item_C = new WeakMap<TheC, TheC>()   // container → insert-after target

    //   raw=true is the plain "C" box: no ItemType, the typed text is peel()'d into
    //   the sc (mainkey is whatever you type — anything).  t is ignored then.
    function pick_and_open(container: TheC, t: ItemType | undefined, seed = '', raw = false) {
        editing.clear()
        editing.add(container)
        if (raw) add_raw_C.add(container); else add_type_C.set(container, t!)
        draft_mk = seed
        draft_sc = ''
        // add forms always focus mainkey — user sets the name first, refines sc after
        // < Point :1 shortcut: user can just submit blank mainkey, sc will auto-focus next
        draft_focus_sc = false
    }
    function pick_and_open_after(container: TheC, after: TheC, t: ItemType | undefined, seed = '', raw = false) {
        editing.clear()
        editing.add(container)
        if (raw) add_raw_C.add(container); else add_type_C.set(container, t!)
        after_item_C.set(container, after)
        draft_mk = seed
        draft_sc = ''
        draft_focus_sc = false
    }
    function cancel_add(container: TheC) {
        editing.delete(container)
        add_type_C.delete(container)
        add_raw_C.delete(container)
        after_item_C.delete(container)
        orb_trigger.delete(container)
    }
    function submit_add(container: TheC) {
        const raw = add_raw_C.has(container)
        let sc: Record<string, any>
        if (raw) {
            // plain "C" box: peel the whole typed text — mainkey is whatever you typed.
            //  Both fields fold into one peel input, comma-joined.
            const text = [draft_mk.trim(), draft_sc.trim()].filter(Boolean).join(',')
            sc = peel(text)
            if (!Object.keys(sc).length) return
        } else {
            const t    = add_type_C.get(container)!
            const val  = draft_mk.trim()
            const sc_s = draft_sc.trim()
            if (!val && t !== 'Point') return
            sc = ITEM_TYPES[t].make_sc(val, sc_s)
            if (t === 'Doc' && !(sc as any).Doc) return
        }
        const child = container.oai(sc)
        if (!raw && add_type_C.get(container) === 'Doc') child.sc.new = 1

        // if after_item_C is set, splice child just after the target in X.z
        const after = after_item_C.get(container)
        if (after && container.X?.z) {
            const z   = container.X.z as TheC[]
            const idx = z.indexOf(child)    // oai() already pushed it
            const aft = z.indexOf(after)
            if (idx >= 0 && aft >= 0 && idx !== aft + 1) {
                z.splice(idx, 1)
                // aft may have shifted if child was before after
                const aft2 = z.indexOf(after)
                z.splice(aft2 + 1, 0, child)
            }
        }

        container.bump_version()
        waft.bump_version()
        cancel_add(container)
    }

    // ── edit existing item ────────────────────────────────────────────
    //
    //   The item C itself is the key — same C can't be edited twice simultaneously.
    //   For What "rename", the item IS the container (what === what), same pattern.
    function start_edit(item: TheC, t: ItemType) {
        const sc     = item.sc as Record<string, any>
        const mk_key = ITEM_TYPES[t].mk_key
        const pval   = sc[mk_key]
        editing.clear()
        editing.add(item)
        draft_type.set(item, t)
        draft_mk = (pval === 1 || pval === true) ? '' : String(pval ?? '')
        draft_sc = Object.entries(sc)
            .filter(([ky]) => ky !== mk_key)
            .map(([ky, v]) => v === 1 ? ky : `${ky}:${v}`)
            .join(',')
        // focus sc when mainkey is bare :1 or when there are already extras to edit
        draft_focus_sc = (pval === 1 || pval === true) || draft_sc !== ''
    }
    function cancel_edit(item: TheC) {
        editing.delete(item)
    }
    async function submit_edit(container: TheC, item: TheC) {
        const t      = draft_type.get(item)!
        const td     = ITEM_TYPES[t]
        const val    = draft_mk.trim()
        const sc_str = draft_sc.trim()
        if (!val && t === 'What') return
        if (t === 'Doc' && !resolve_doc_path(val)) return
        const new_sc = td.make_sc(val, sc_str)
        // fire rename event before mutating sc, so Lies can drop the old open_req
        if (t === 'Doc') {
            const old_path = item.sc.Doc as string
            const new_path = (new_sc as any).Doc as string
            if (new_path && new_path !== old_path) {
                delete item.sc.not_found
                delete item.sc.new
                H.i_elvisto('Lies/Lies', 'Lies_rename_doc', { old_path, new_path, waft_path: wkey })
            }
        }
        Object.keys(item.sc).forEach(k => delete item.sc[k])
        Object.assign(item.sc, new_sc)
        container.bump_version()
        waft.bump_version()
        // await tick so derived display values re-read updated sc before edit mode clears
        await tick()
        // close both the edit form and the irow overlay — orb openness is coupled,
        //  same as on_orb's second-click and the cancel paths.  Submitting is "done".
        editing.delete(item)
        orb_open_C.delete(item)
    }
    function delete_item(item: TheC, container: TheC) {
        container.drop(item)
        container.bump_version()
        waft.bump_version()
    }

    // ── What spotlight helper ─────────────────────────────────────────
    function is_spotlight(what: TheC): boolean {
        void examining?.vers
        const spot = examining?.o?.({ Spotlight: 1 })?.[0] as any
        if (!spot?.sc.src) return false
        let node: any = spot.sc.src
        while (node) { if (node === what) return true; node = node.c?.up }
        return false
    }

    // ── Doc focus ─────────────────────────────────────────────────────
    function focus_doc(doc: TheC) {
        H.i_elvisto('Lies/Lies', 'Lies_set_cursor', { doc_C: doc, waft_key: wkey })
    }

    // ── props builders — feed into pi() ──────────────────────────────
    //
    //   item_props: edit/idle row for an existing item C.
    //     dpath threads through to Point's on_open for Dock_open navigation.
    //
    //   add_item_props: open add-form for a new child of container.
    //     Always open=true, submit_label='+', no edit/del buttons.

    function item_props(item: TheC, container: TheC, t: ItemType, dpath?: string): PiProps {
        const td      = ITEM_TYPES[t]
        // open only when editing this specific item — not when item is acting as add-container
        const open    = editing.has(item) && !add_type_C.has(item)
        const mk_val  = (item.sc as any)[td.mk_key]
        const is_waft = t === 'Waft'
        const disp    = item_to_display(item, t)
        // after_types: sibling types allowed by the container
        const container_t  = item_type_of(container)
        const after_types  = (!is_waft && container_t)
            ? (ITEM_TYPES[container_t].child_types as string[] | undefined)
            : undefined
        // close_orb: shut irow without touching any add form that may be open on container
        function close_orb() { orb_open_C.delete(item) }
        // open_after: close this item's edit, open a sibling-add form on the parent container
        function open_after(typ: ItemType, seed = '') {
            close_orb()
            cancel_edit(item)
            orb_trigger.set(container, item)
            pick_and_open_after(container, item, typ, seed)
        }
        // open_in: close this item's edit, open a child-add form on this item
        function open_in(typ: ItemType, seed = '') {
            close_orb()
            cancel_edit(item)
            orb_trigger.set(item, item)
            pick_and_open(item, typ, seed)
        }
        // raw variants — the plain "C" box: no imposed mainkey, peel()'d on submit
        function open_after_raw(seed = '') {
            close_orb()
            cancel_edit(item)
            orb_trigger.set(container, item)
            pick_and_open_after(container, item, undefined, seed, true)
        }
        function open_in_raw(seed = '') {
            close_orb()
            cancel_edit(item)
            orb_trigger.set(item, item)
            pick_and_open(item, undefined, seed, true)
        }
        // add_types: union of after_types and child_types, deduplicated
        const add_types_set = new Set<string>([
            ...(after_types ?? []),
            ...(td.child_types ?? []),
        ])
        const add_types = add_types_set.size ? [...add_types_set] : undefined
        return {
            label:        t,
            open,
            display_val:  disp.val,
            display_sc:   disp.sc,
            mk_ph:        td.mk_ph,
            sc_ph:        td.sc_ph,
            mk_is_one:    mk_val === 1 || mk_val === true,
            mainkey:      open ? draft_mk : '',
            on_mk:        (v: string) => { draft_mk = v },
            sc_str:       open ? draft_sc : '',
            on_sc:        (v: string) => { draft_sc = v },
            focus_sc:     open ? draft_focus_sc : false,
            submit_label: '✓',
            on_open:      () => td.on_open(item as any, dpath),
            // < Waft rename is a no-op — backend rewrites %Waft on load/save
            on_submit:    is_waft ? () => cancel_edit(item) : () => submit_edit(container, item),
            on_cancel:    () => { cancel_edit(item); close_orb() },
            on_crud: {
                orb_open: orb_open_C.has(item),
                on_orb: () => {
                    if (orb_open_C.has(item)) {
                        // second click on orb: close everything
                        close_orb()
                        cancel_edit(item)
                    } else {
                        // first click: open irow and immediately enter edit mode
                        orb_open_C.clear()
                        editing.clear()
                        orb_open_C.add(item)
                        start_edit(item, t)
                    }
                },
                on_cancel_orb: () => { close_orb(); cancel_edit(item) },
                on_del: is_waft ? () => on_delete(waft) : () => delete_item(item, container),
                // C box: first typed char opens a RAW add form (peel — any mainkey).
                //  Gated by where an add is structurally allowed.
                on_start_after: after_types?.length
                    ? (char: string) => open_after_raw(char)
                    : undefined,
                on_start_in: td.can_add
                    ? (char: string) => open_in_raw(char)
                    : undefined,
                // type buttons: open without seeding mainkey
                on_pick_after_type: after_types?.length
                    ? (typ: string) => open_after(typ as ItemType)
                    : undefined,
                on_pick_in_type: td.can_add
                    ? (typ: string) => open_in(typ as ItemType)
                    : undefined,
                add_types,
            },
        }
    }

    // add_item_props: open add-form for a new child/sibling of container.
    //   orb_item: the item whose orb triggered this add (to close it on cancel).
    //   Always open=true, submit_label='+', no on_crud.
    //   focus_sc only for Point (mainkey is :1 in that case).
    //   raw ("C" box): no ItemType — label 'C', placeholders hint a free particle.
    function add_item_props(container: TheC, orb_item: TheC): PiProps {
        const raw = add_raw_C.has(container)
        const td  = raw ? undefined : ITEM_TYPES[add_type_C.get(container)!]
        return {
            label:        raw ? 'C' : add_type_C.get(container)!,
            open:         true,
            mk_ph:        raw ? 'Funkcion:Ballistics' : td!.mk_ph,
            sc_ph:        raw ? 'emoji:💥,arm:1' : td!.sc_ph,
            mainkey:      draft_mk,
            on_mk:        (v: string) => { draft_mk = v },
            sc_str:       draft_sc,
            on_sc:        (v: string) => { draft_sc = v },
            focus_sc:     raw ? false : draft_focus_sc,
            submit_label: '+',
            on_submit:    () => submit_add(container),
            on_cancel:    () => { cancel_add(container); orb_open_C.delete(orb_item) },
        }
    }

    // raw_props: the generic plain-C row — used for any C with no ITEM_TYPE: a %Funkcion node
    //   in a What's editing presentation, AND an un-schema'd Waft child (Keep's WaftTimes|Cursor,
    //    Cluster's %HostedIdentity, …).  idle = the depeeled line; orb opens a PeelInput that
    //     peels the typed text straight back into the sc — the mainkey is whatever you type.
    function raw_props(funk: TheC, container: TheC): PiProps {
        const open = editing.has(funk) && raw_edit_C.has(funk)
        const d    = raw_display(funk)
        return {
            label:        Object.keys(funk.sc)[0] ?? 'C',
            open,
            display_val:  d.mk,
            display_sc:   d.sc,
            mk_ph:        'Key:value',
            sc_ph:        'more:keys',
            mainkey:      open ? draft_mk : '',
            on_mk:        (v: string) => { draft_mk = v },
            sc_str:       open ? draft_sc : '',
            on_sc:        (v: string) => { draft_sc = v },
            focus_sc:     false,
            submit_label: '✓',
            on_submit:    () => submit_edit_raw(container, funk),
            on_cancel:    () => { editing.delete(funk); raw_edit_C.delete(funk); orb_open_C.delete(funk) },
            on_crud: {
                orb_open: orb_open_C.has(funk),
                on_orb: () => {
                    if (orb_open_C.has(funk)) { orb_open_C.delete(funk); editing.delete(funk); raw_edit_C.delete(funk) }
                    else open_raw_edit(funk)
                },
                on_cancel_orb: () => { orb_open_C.delete(funk); editing.delete(funk); raw_edit_C.delete(funk) },
                on_del: () => delete_item(funk, container),
            },
        }
    }
</script>

<div class="ls-waft" style="margin-left: {depth * 14}px"
     data-waft-col={wkey} role="group"
     class:ls-waft-active={is_active} class:ls-waft-ting={is_taker}
     class:ls-waft-half={sidebyside}
     onmouseenter={() => on_hover?.(wkey)}
     onmouseleave={() => on_hover?.(undefined)}>

    <!-- control bar — view toggles that ride beside the ghost|data disillusioner.
         All three are render-only and never reach the C/snap. -->
    <div class="ls-waft-ctl">
        <button class="ls-waft-btn" class:ls-waft-btn-on={minimised}
                onclick={toggle_minimised}
                title="{minimised ? 'expand this Waft' : 'minimise this Waft'}">{minimised ? '▸' : '▾'}</button>
        {#if minimised}
            <span class="ls-waft-tab" title={wkey}>{wkey}</span>
        {/if}
        <span class="ls-waft-ctl-spacer"></span>
        <button class="ls-waft-btn" class:ls-waft-btn-on={sidebyside}
                onclick={() => sidebyside = !sidebyside}
                title="{sidebyside ? 'full width' : 'side-by-side (half width; pairs with a neighbour)'}">▥</button>
        <button class="ls-waft-btn" class:ls-waft-btn-on={capstate !== 'tall'}
                onclick={cycle_cap}
                title="{capstate === 'tall' ? 'height: capped at ~half the screen — click for tight (10em)'
                      : capstate === 'tight' ? 'height: tight (10em) — click for free (infinite)'
                      : 'height: free (infinite) — click to re-cap'}">{capstate === 'tall' ? '⤡' : capstate === 'tight' ? '▁' : '⤢'}</button>
    </div>

    {#if !minimised}
    <div class="ls-waft-body scrollbig" bind:this={body_el}
         class:ls-waft-capped={capstate === 'tight'} class:ls-waft-free={capstate === 'free'}>

    {#if main_funk && !raw}
        <!-- a main-Funkcion Waft renders that Funkcion's BIG face (the close-up Lens —
             DocTing histogram, DocGhostList index, …) as its whole body.  No per-kind
             branch: the kind's component (kinds.ts) owns the face; here we just host it.
             The ⤺ toggle peeks at the raw child tree behind it. -->
        <button class="ls-ting-switch" onclick={() => raw = true}
                title="peek at the raw data tree">
            <span class="ls-ting-glyph">▦</span>
            <span class="ls-ting-key">{wkey}</span>
            <span class="ls-ting-mode">face</span>
        </button>
        <FunkHost {H} {w} funk={main_funk} {examining} />
    {:else}

        {#if main_funk}
            <!-- raw view of a main-Funkcion Waft — the data tree, toggle back to its face -->
            <button class="ls-ting-switch" onclick={() => raw = false}
                    title="show the face">
                <span class="ls-ting-glyph">⤺</span>
                <span class="ls-ting-key">{wkey}</span>
                <span class="ls-ting-mode">data</span>
            </button>
        {/if}

    <!-- Waft header row — waft C rendered as a waftitem like any other -->
    {#if waft_mungs.length || waft.oa({ encode_error: 1 })}
        <EncodingSplatter {waft} />
    {/if}
    {@render waftitem(waft, waft, false, false)}

    <!-- sub-Wafts (recursive) -->
    {#each sub_wafts as sw (sw.sc.Waft)}
        <Waft {H} {w} waft={sw} depth={depth + 1} {examining}
            {on_active} {on_delete} />
    {/each}

    {/if}

    </div>
    {/if}

</div>

<!-- pi — the one and only <PeelInput> callsite in this file. -->
{#snippet pi(p: PiProps)}
    <PeelInput
        label={p.label}
        open={p.open}
        display_val={p.display_val}
        display_sc={p.display_sc}
        mk_ph={p.mk_ph}
        sc_ph={p.sc_ph}
        mk_is_one={p.mk_is_one}
        mainkey={p.mainkey}
        on_mk={p.on_mk}
        sc_str={p.sc_str}
        on_sc={p.on_sc}
        focus_sc={p.focus_sc}
        submit_label={p.submit_label}
        on_open={p.on_open}
        on_submit={p.on_submit}
        on_cancel={p.on_cancel}
        on_crud={p.on_crud} />
{/snippet}


<!-- waftitem — the one wrapper for ANY C in the tree.  A Waft is an indifferent medium,
     so this dispatches three ways on the C and never hides a child:
       %Funkcion        → its live face (FunkHost) or, mid-edit, the plain-C row;
       a known ITEM_TYPE → Waft/What/Doc/Point personality from the table (CSS, children,
                            spotlight, navigate, add-picker);
       anything else     → the generic plain-C row + its recursed subtree (the {:else} below).
     Detects type from C.sc mainkey, reads C.o({}) for children, renders
     .ls-item / .ls-item-hdr / .ls-items.  upC is the containing C — used for edit/delete
     keying and Doc dpath.  Type selection lives in the PeelInput irow via on_crud.on_pick_type. -->
{#snippet waftitem(C: TheC, upC: TheC, funk_as_C: boolean, inline: boolean)}
    {#if C.sc?.Funkcion !== undefined}
        {@const fediting = editing.has(C) && raw_edit_C.has(C)}
        <!-- Every Funkcion is editable through an orb.  A live kind shows its illusion with a
             small orb beside it (compact in an inline flow, a row otherwise); the orb flips it
             to the plain-C edit form.  A kind with no live component (a comp_<Lens>-only kind), a
             What flipped to edit-as-C, or a Funkcion mid-edit instead renders the full plain-C
             row — the generic PeelInput — so it looks like, and edits as, any other C. -->
        {#if fediting || funk_as_C || !funk_live(C)}
            <div class="ls-item ls-item-funkc">
                <div class="ls-item-hdr">{@render pi(raw_props(C, upC))}</div>
            </div>
        {:else}
            <div class="ls-funk-live" class:ls-funk-live-inline={inline}>
                <Orb onclick={() => open_raw_edit(C)} title="edit this Funkcion" />
                <FunkHost {H} {w} funk={C} {raw} {examining} />
            </div>
        {/if}
    {:else}
    {@const t = item_type_of(C)}
    {#if t}
        {@const td       = ITEM_TYPES[t]}
        {@const items    = (() => { void C.version; return C.o() as TheC[] })()}
        {@const dpath    = t === 'Doc' ? C.sc.Doc as string : undefined}
        {@const dyn_cls  = td.item_cls_fns.filter(f => f.when(C)).map(f => f.cls).join(' ')}
        {@const is_what  = t === 'What'}
        {@const editing_struct = is_what && struct_what.has(C)}
        {@const inline_flow    = is_what && what_inlined(C) && !editing_struct}
        {@const show_tog       = is_what && (has_funk_child(C) || what_inlined(C))}
        {@const child_as_C     = is_what ? editing_struct : funk_as_C}
        <div class="{td.item_cls} {dyn_cls}">
            <div class="ls-item-hdr" class:ls-hdr-desc={!!C.sc?.desc && !editing.has(C)}>
                <!-- a Funkcion-bearing What carries the inline⇄edit toggle as part of its
                     illusion: ✎ flips to the editable bullet C**, ◉ restores the live inline flow. -->
                {#if show_tog}
                    <button class="ls-inline-tog" onclick={() => toggle_struct(C)}
                        title={editing_struct ? 'show the live Funkcions inline' : 'edit as plain C'}>{editing_struct ? '◉' : '✎'}</button>
                {/if}
                {@render pi(item_props(C, upC, t, dpath))}
                <!-- a one-line desc (e.g. a Credence What:desc naming what the group tests) sits to the
                     RIGHT of the label with a margin; kept out of the inline peel via DISPLAY_SKIP.
                     DISPLAY-ONLY: hidden while editing (matching the .ls-hdr-desc class's own !editing
                     gate) — a shown desc claims its content width + the 5em margin FIRST, starving the
                     flex-basis-0 PeelInput to ~0 wide (the "pi-row is 0 wide" collapse). Editing needs
                     the row for the inputs; the desc returns once the orb closes. -->
                {#if C.sc?.desc && !editing.has(C)}<span class="ls-desc" title={C.sc.desc as string}>{C.sc.desc}</span>{/if}
            </div>
            {#if td.child_types}
                {#if editing.has(C) && (add_type_C.has(C) || add_raw_C.has(C))}
                    <div class="ls-add-row">{@render pi(add_item_props(C, orb_trigger.get(C) ?? C))}</div>
                {/if}
                {#if items.length}
                    <div class={inline_flow ? 'ls-inline' : 'ls-items'}>
                        {#each items as child (child)}
                            {@render waftitem(child, C, child_as_C, inline_flow)}
                        {/each}
                    </div>
                {/if}
            {/if}
        </div>
    {:else}
        <!-- generic C — mainkey is none of the ITEM_TYPES and it isn't a %Funkcion.
             A Waft is an indifferent medium that holds any C, so an un-schema'd particle
             (the Keep's WaftTimes|Cursor, the Cluster's %HostedIdentity, …) renders as a
             plain editable C row — the same generic PeelInput a Funkcion edits through — and
             recurses its child tree, so the whole /* shows instead of nothing.  No ITEM_TYPE
             means no add-picker|spotlight|navigate; the orb edits the line, ✕ deletes. -->
        {@const gitems = (() => { void C.version; return C.o() as TheC[] })()}
        <div class="ls-item ls-item-c">
            <div class="ls-item-hdr">{@render pi(raw_props(C, upC))}</div>
            {#if gitems.length}
                <div class="ls-items">
                    {#each gitems as child (child)}
                        {@render waftitem(child, C, false, false)}
                    {/each}
                </div>
            {/if}
        </div>
    {/if}
    {/if}
{/snippet}

<script module lang="ts">
    // place_cursor_at_stem — positions cursor before the stem's first dot,
    // selecting just the stem portion so it can be edited or suffixed.
    export function place_cursor_at_stem(node: HTMLInputElement) {
        node.focus()
        const val     = node.value
        const slash_i = val.lastIndexOf('/')
        const base    = slash_i >= 0 ? val.slice(slash_i + 1) : val
        const dot_i   = base.indexOf('.')
        const stem_end   = slash_i >= 0
            ? slash_i + 1 + (dot_i >= 0 ? dot_i : base.length)
            : (dot_i >= 0 ? dot_i : base.length)
        const stem_start = slash_i >= 0 ? slash_i + 1 : 0
        node.setSelectionRange(stem_start, stem_end)
        return {}
    }

    export function focus_on_mount(node: HTMLElement) {
        node.focus()
        if (node instanceof HTMLInputElement) node.select()
        return {}
    }
</script>

<style>
    .ls-waft {
        background: #13131d; border: 1px solid #252535;
        border-radius: 3px; padding: 0.3rem 0.4rem; margin-bottom: 0.25rem;
        font-size: 0.83rem; color: #ccc;
        /* full row by default in the flex-wrap parent list; .ls-waft-half halves it
           so two adjacent Wafts pair. Inert (block) for nested/non-flex parents. */
        flex: 1 1 100%; min-width: 0;
    }
    .ls-waft-active { border-color: #446 }

    /* control bar — thin row of view toggles at the top of every Waft */
    .ls-waft-ctl {
        display: flex; align-items: center; gap: 0.15rem;
        margin: -0.1rem 0 0.15rem 0;
    }
    .ls-waft-ctl-spacer { flex: 1; }
    .ls-waft-btn {
        background: none; border: 1px solid #2a2a3a; border-radius: 3px;
        color: #667; cursor: pointer; font-size: 0.7rem; line-height: 1;
        padding: 0.05rem 0.28rem; flex-shrink: 0;
        transition: color 0.1s, border-color 0.1s;
    }
    .ls-waft-btn:hover  { color: #aab; border-color: #446; }
    .ls-waft-btn-on     { color: #9ab; border-color: #446; background: #1a1a2a; }
    /* when minimised, the wkey rides the bar as a tab so you can still tell which Waft */
    .ls-waft-tab {
        font-family: monospace; font-size: 0.74rem; color: #7a8fa8; font-weight: bold;
        min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
        padding-left: 0.2rem;
    }
    /* every body is height-capped by default — a huge Waft scrolls inside itself
       (cursor-follow keeps the glowing row in view) instead of eating the page */
    .ls-waft-body   { max-height: 55vh; overflow: auto; }
    .ls-waft-capped { max-height: 10em; }   /* Vexpany — the tight park */
    .ls-waft-free   { max-height: none; }   /* infinite growth — the old default, now opt-in */
    /* side-by-side — half width; the flex-wrap parent pairs two halves onto one row */
    .ls-waft-half { flex: 1 1 calc(50% - 0.3rem); min-width: 0; }

    /* a group's one-line desc (Credence What:desc) — muted italic, a fixed 5em to the right of the
       label.  the two-class selector out-specifies the .ls-item-hdr :global(.pi-wrap) flex:1 rule so the
       label sizes to its CONTENT — and flex-shrink 0 so the title is shown in FULL, never crush-truncated
       before it reaches the desc (the title is the identity; the desc is the lower-priority extra).  The
       desc gives instead: it keeps shrink:1 and ellipsises when the row runs out of room. */
    .ls-item-hdr.ls-hdr-desc :global(.pi-wrap) { flex: 0 0 auto; }
    .ls-item-hdr.ls-hdr-desc :global(.pi-row)  { flex: 0 0 auto; }
    .ls-desc {
        flex: 0 1 auto; min-width: 0; margin-left: 5em;
        font-size: 0.86rem; color: #7a7a8c; font-style: italic; line-height: 1.3;
        white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    }

    /* taker Waft (the Ting) — the histogram switcheroo + its toggle */
    .ls-waft-ting { border-color: #4a3a2a; }
    .ls-ting-switch {
        display: flex; align-items: center; gap: 0.35rem; width: 100%;
        background: none; border: none; cursor: pointer; padding: 0 0 0.2rem 0;
        color: #b89a6a; font-family: monospace; font-size: 0.8rem; text-align: left;
    }
    .ls-ting-switch:hover { color: #e0c088; }
    .ls-ting-glyph { width: 0.9rem; }
    .ls-ting-key   { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis;
                     white-space: nowrap; font-weight: bold; }
    .ls-ting-mode  { color: rgba(180, 150, 100, 0.5); font-size: 0.7rem; }

    /* Waft header row — styled like a What but with active-glow on the key */
    .ls-item-waft {
        margin: 0 0 0.2rem 0;
        border-left: 2px solid #334;
        padding-left: 0.35rem;
    }
    .ls-item-waft :global(.pi-label) { color: #6a7fa8; font-weight: bold; }
    .ls-item-waft :global(.pi-display-val) { color: #8ab; font-weight: bold; }
    /* active waft: glow on the left border */
    .ls-item-waft-active { position: relative; }
    .ls-item-waft-active::before {
        content: '';
        position: absolute; left: -2px; top: 0; bottom: 0; width: 2px;
        background: #88c; box-shadow: 0 0 6px 2px #446a;
    }

    /* an inlined What flows its Funkcion illusions instead of bulleting them */
    .ls-inline {
        display: flex; flex-wrap: wrap; align-items: center; gap: 0.3rem;
        padding-left: 0.5rem;
    }
    /* the inline⇄edit toggle on a Funkcion-bearing What — subtle, brightens on hover */
    .ls-inline-tog {
        background: none; border: none; cursor: pointer; padding: 0 0.1rem;
        color: #45506a; font-size: 0.72rem; line-height: 1; flex: none;
        transition: color 0.1s;
    }
    .ls-inline-tog:hover { color: #8fa6d0; }
    /* a Funkcion edited as plain C — same muted register as a Point row */
    .ls-item-funkc :global(.pi-label) { color: #6a6a8a; }
    /* a generic un-schema'd C (Keep/Cluster registry rows, …) — muted, raw-data register */
    .ls-item-c :global(.pi-label)       { color: #5a6a7a; }
    .ls-item-c :global(.pi-display-val) { color: #8a98a6; }

    /* a live Funkcion illusion with its edit orb beside it — a row by default,
       compact inline-flex inside an inlined What's flow */
    .ls-funk-live        { display: flex; align-items: center; gap: 0.25rem; }
    .ls-funk-live-inline { display: inline-flex; }

    /* shared item wrapper */
    .ls-item { margin: 0.1rem 0; }
    .ls-item-hdr {
        display: flex; align-items: center; gap: 0.2rem; min-height: 1.4rem;
    }
    /* PeelInput fills the header row so cancel reaches the right edge */
    .ls-item-hdr :global(.pi-wrap) { flex: 1; min-width: 0; }
    .ls-item-hdr :global(.pi-row)  { flex: 1; min-width: 0; }
    /* children indented under any item type */
    .ls-items { padding-left: 0.5rem; }

    /* Point — warm label, hairline separator; no left border or indent (reads flat) */
    .ls-item-point {
        border-bottom: 1px solid #1c1c28;
    }
    .ls-item-point:last-child { border-bottom: none }
    .ls-item-point :global(.pi-label) { color: #7a4a5a; }

    /* Doc — no left border by default; new/missing tint via modifier classes */
    .ls-item-doc { margin: 0.1rem 0 0.15rem 0; }
    .ls-item-doc-new     { border-left: 2px solid #3a5a3a; padding-left: 0.35rem; }
    .ls-item-doc-missing { border-left: 2px solid #5a3a2a; padding-left: 0.35rem; opacity: 0.8; }

    /* What — bordered left margin brackets header + all children; spotlight glow */
    .ls-item-what {
        margin: 0.15rem 0;
        border-left: 2px solid #2a3a4a;
        padding-left: 0.35rem;
    }
    /* nested Whats step the border colour cooler so depth reads visually */
    .ls-item-what .ls-item-what { border-left-color: #223040; }
    .ls-item-what .ls-item-what .ls-item-what { border-left-color: #1a2530; }
    /* What label brighter than the muted Doc/Point default; display larger */
    .ls-item-what > .ls-item-hdr :global(.pi-label)       { color: #7a8fa8; }
    .ls-item-what > .ls-item-hdr :global(.pi-display-val) { font-size: 0.9rem; color: #aac8dd; }
    /* Spotlight glow — overwrites left border with a glowing beam */
    .ls-item-what-active { position: relative; }
    .ls-item-what-active::before {
        content: '';
        position: absolute; left: -2px; top: 0; bottom: 0;
        width: 2px;
        background: #446a; box-shadow: 0 0 6px 2px #446a;
    }

    /* add-item row — PeelInput open for a new child */
    .ls-add-row { margin-top: 0.05rem; }

    .ls-input {
        background: #0d0d14; border: 1px solid #333; border-radius: 3px;
        color: #aaa; font-family: monospace; font-size: 0.76rem;
        padding: 0.2rem 0.35rem; outline: none;
    }
    .ls-input:focus  { border-color: #446 }

    .ls-cancel-btn {
        background: none; border: none; color: #555;
        cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.3rem;
    }
    .ls-cancel-btn:hover  { color: #999 }
    .ls-cancel-right { margin-left: auto }

    .ls-type-picker {
        display: none;  /* < type picker now lives in the PeelInput irow */
    }

</style>
