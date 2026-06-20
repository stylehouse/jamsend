<script lang="ts">
    // Waft.svelte — one Waft item in the recursive Waft tree.
    //
    // Extracted from Liesui to be a stable component boundary:
    // Svelte reconciles {#each} items by component key (waft.sc.Waft) so
    // this component survives Liesui re-renders, keeping form state and
    // focused inputs stable across think() ticks.
    //
    // Single <PeelInput> callsite via pi(). Single item wrapper via waftitem(C, upC).
    //   waftitem detects type from C.sc mainkey, reads C.o({}) for children,
    //   renders .ls-item / .ls-item-hdr / .ls-items — all personality from ITEM_TYPES.
    //   The Waft header row itself is rendered as waftitem(waft, waft) via the Waft
    //   entry in ITEM_TYPES — no separate header block.

    import type { TheC }    from "$lib/data/Stuff.svelte"
    import type { House }   from "$lib/O/Housing.svelte"
    import { peel, depeel } from "$lib/Y.svelte"
    import { SvelteSet }    from "svelte/reactivity"
    import { tick }         from "svelte"
    import EncodingSplatter from "$lib/O/ui/EncodingSplatter.svelte"
    import PeelInput        from "$lib/O/ui/PeelInput.svelte"
    import DocTing          from "$lib/O/ui/DocTing.svelte"   // taker-Waft switcheroo: histogram, not raw globules
    import DocGhostList      from "$lib/O/ui/DocGhostList.svelte"   // lister-Waft switcheroo: the stem-clustered ghost index

    let { H, w, waft, depth = 0, on_active, on_delete, examining }: {
        H:         House
        w:         TheC          // Lies's w particle — for live state downstream
        waft:      TheC
        depth?:    number
        on_active: (waft: TheC) => void
        on_delete: (waft: TheC) => void
        examining?: TheC         // from Liesui; derives Spotlight glow targets
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
    type ItemType = keyof typeof ITEM_TYPES

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
    const DISPLAY_SKIP = new Set(['active', 'new', 'not_found'])
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
    let waft_children = $derived((() => { void waft.version; return waft.o().filter((c: TheC) => !c.sc.Waft) as TheC[] })())
    let sub_wafts     = $derived((() => { void waft.version; return waft.o({ Waft: 1 }) as TheC[] })())
    let waft_mungs    = $derived((() => { void waft.version; return waft.o({ mung_error: 1 }) as TheC[] })())
    // taker Waft (the attention Ting) renders as a histogram by default; toggle to peek
    //  at the raw %Point globule tree.
    let is_taker      = $derived(!!waft.sc.takes)
    // lister Waft (the GhostList) renders as the stem-clustered ghost index, not its
    //  raw group/Doc tree — the same switcheroo idea as the taker Ting.
    let is_lister     = $derived(!!waft.sc.lists)
    let raw           = $state(false)

    // ── havoc pads (Ballistics — the testing havoc drum-machine) ───────
    //   A %havoc particle authored anywhere in the tree renders inline as a
    //   strikeable pad (waftitem).  Striking runs the limb keyed by the havoc kind
    //   (Lies/HAVOC_LIMBS) — popping that limb out of the Lies/Store plumbing.  In a
    //   switcheroo Waft's raw mode the bare particle shows instead of the pad.
    let struck = $state<TheC | null>(null)
    function strike_havoc(c: TheC) {
        H.i_elvisto('Lies/Lies', 'Lies_strike', { kind: c.sc.havoc as string })
        struck = c
        setTimeout(() => { if (struck === c) struck = null }, 180)
    }
    function havoc_raw(c: TheC): string {
        return Object.entries(c.sc).map(([k, v]) => v === 1 ? k : `${k}:${v}`).join(', ')
    }
    // a dock-bound %Funkcion is a Credence test-light: its run (Lies_verdict_read) stamps
    //  funk.c.verdict = {phase,pass,total,dige} off-snap; we read it reactively (void
    //   version) and colour the cell good|bad|working.  leaf = the dock's leaf name.
    function funk_verdict(c: TheC): { phase: string, pass?: number, total?: number, dige?: string } {
        void c.version
        return (c.c.verdict as any) ?? { phase: 'working' }
    }
    const leaf = (p: any) => String(p ?? '').split('/').pop()
    // a cell binds to a Book (%of_book) or a dock (%of_dock); label by whichever.
    const funk_bound = (c: TheC) => (c.sc.of_book ?? c.sc.of_dock) as string | undefined
    // click a cell to run it.  A dock cell fires the same "run it now" intent Esc does
    //  (Lies_run_arm → the runner runs it off the Rungo the compile-write emits).  A Book
    //   cell wants the editor→runner "become Book" remote control (§5e build-order b, not
    //    yet wired) — for now it just acks optimistically; the verdict still lands live
    //     whenever that Book is run on the runner by any means.
    function strike_funk(c: TheC) {
        if (c.sc.of_dock) H.i_elvisto('Lies/Lies', 'Lies_run_arm', { path: c.sc.of_dock as string })
        else console.log(`🧪 Credence: become-Book "${c.sc.of_book}" not yet wired (§5e b)`)
        c.c.verdict = { ...(c.c.verdict as any ?? {}), phase: 'working' }   // optimistic ack
        c.bump_version()
    }
    // a %havoc,arm pad self-arms: it strikes itself whenever its containing What is
    //  engaged (Lies_arm_engaged).  Glow it when that What holds the spotlight, so the
    //  auto-fire is legible — the pad lights the same moment the limb runs.
    function havoc_armed_engaged(c: TheC): boolean {
        if (!c.sc.arm) return false
        let what: any = c
        while (what && what.sc?.What === undefined) what = what.c?.up
        return what ? is_spotlight(what) : false
    }

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
    //  whatever you type (a %havoc, or anything), not a forced ItemType.
    const add_raw_C    = new WeakSet<TheC>()
    const orb_trigger  = new WeakMap<TheC, TheC>()    // container → item whose orb opened this add

    // ── add-item form ─────────────────────────────────────────────────
    //
    //   pick_and_open: add a child inside container (appends to container.X.z).
    //   pick_and_open_after: add a sibling after item (splices into container.X.z).
    //     after_item is stored in a WeakMap so submit_add_after knows where to splice.
    const after_item_C = new WeakMap<TheC, TheC>()   // container → insert-after target

    //   raw=true is the plain "C" box: no ItemType, the typed text is peel()'d into
    //   the sc (mainkey is whatever you type — a %havoc, anything).  t is ignored then.
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
        editing.delete(item)
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
                // C box: first typed char opens a RAW add form (peel — any mainkey,
                //  including a %havoc).  Gated by where an add is structurally allowed.
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
            mk_ph:        raw ? 'havoc:kind' : td!.mk_ph,
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
</script>

<div class="ls-waft" style="margin-left: {depth * 14}px"
     class:ls-waft-active={is_active} class:ls-waft-ting={is_taker} class:ls-waft-ghl={is_lister}>

    {#if is_taker}
        <!-- Switcheroo: a taker Waft (the attention Ting) is all machine-y %Point
             globule data raw, so instead of dumping the tree it engages DocTing and
             "looks such" — the gold-bar histogram.  The header toggles to the raw
             data when you want to inspect the gross C**. -->
        <button class="ls-ting-switch" onclick={() => raw = !raw}
                title="{raw ? 'show the histogram' : 'show the raw Ting data'}">
            <span class="ls-ting-glyph">{raw ? '⤺' : '▦'}</span>
            <span class="ls-ting-key">{wkey}</span>
            <span class="ls-ting-mode">{raw ? 'data' : 'bars'}</span>
        </button>
        {#if raw}
            {#if waft_mungs.length || waft.oa({ encode_error: 1 })}
                <EncodingSplatter {waft} />
            {/if}
            {@render waftitem(waft, waft)}
            {#each sub_wafts as sw (sw.sc.Waft)}
                <svelte:self {H} {w} waft={sw} depth={depth + 1} {examining}
                    {on_active} {on_delete} />
            {/each}
        {:else}
            <DocTing {H} />
        {/if}
    {:else if is_lister}
        <!-- a lister Waft (GhostList) shows DocGhostList — the stem-clustered ghost
             index — not its raw group/Doc tree.  Toggle to inspect the raw data. -->
        <button class="ls-ting-switch" onclick={() => raw = !raw}
                title="{raw ? 'show the ghost index' : 'show the raw GhostList data'}">
            <span class="ls-ting-glyph">{raw ? '⤺' : '👻'}</span>
            <span class="ls-ting-key">{wkey}</span>
            <span class="ls-ting-mode">{raw ? 'data' : 'ghosts'}</span>
        </button>
        {#if raw}
            {#if waft_mungs.length || waft.oa({ encode_error: 1 })}
                <EncodingSplatter {waft} />
            {/if}
            {@render waftitem(waft, waft)}
            {#each sub_wafts as sw (sw.sc.Waft)}
                <svelte:self {H} {w} waft={sw} depth={depth + 1} {examining}
                    {on_active} {on_delete} />
            {/each}
        {:else}
            <DocGhostList {H} {waft} />
        {/if}
    {:else}

    <!-- Waft header row — waft C rendered as a waftitem like any other -->
    {#if waft_mungs.length || waft.oa({ encode_error: 1 })}
        <EncodingSplatter {waft} />
    {/if}
    {@render waftitem(waft, waft)}

    <!-- sub-Wafts (recursive) -->
    {#each sub_wafts as sw (sw.sc.Waft)}
        <svelte:self {H} {w} waft={sw} depth={depth + 1} {examining}
            {on_active} {on_delete} />
    {/each}

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


<!-- waftitem — the one wrapper for every Point/Doc/What in the tree.
     Detects type from C.sc mainkey, reads C.o({}) for children,
     renders .ls-item / .ls-item-hdr / .ls-items.
     All per-type personality (CSS, child_types, spotlight) comes from ITEM_TYPES.
     upC is the containing C — used for edit/delete keying and Doc dpath.
     Type selection now lives in the PeelInput irow via on_crud.on_pick_type. -->
{#snippet waftitem(C: TheC, upC: TheC)}
    {@const hav = C.sc?.havoc}
    {#if hav !== undefined}
        <!-- %havoc — a Ballistics pad rendered inline; bare particle in raw mode. -->
        {#if raw}
            <div class="ls-havoc-raw">{havoc_raw(C)}</div>
        {:else}
            <div class="ls-havoc">
                <button class="ls-havoc-pad" class:ls-havoc-hit={struck === C}
                        class:ls-havoc-armed={!!C.sc.arm}
                        class:ls-havoc-engaged={havoc_armed_engaged(C)}
                        title={(C.sc.hint as string) ?? (C.sc.arm ? `self-arming havoc: ${hav} (also strikeable)` : `strike havoc: ${hav}`)}
                        onclick={() => strike_havoc(C)}>
                    <span class="ls-havoc-glyph">{(C.sc.emoji as string) ?? '💥'}</span>
                    <span class="ls-havoc-label">{hav}</span>
                    {#if C.sc.arm}<span class="ls-havoc-arm" title="self-arms when its What is looked at">⟳</span>{/if}
                </button>
            </div>
        {/if}
    {:else if C.sc?.Funkcion !== undefined}
        <!-- %Funkcion — an embedded applet.  A dock-bound one (carrying %of_dock) renders
             as a Credence test-light: ✓ green / ✗ red / ◴ working, with the step pass-count
             and the dock leaf.  Raw mode shows the bare particle. -->
        {#if raw}
            <div class="ls-havoc-raw">Funkcion:{C.sc.Funkcion}{funk_bound(C) ? ` → ${funk_bound(C)}` : ''}</div>
        {:else}
            {@const v = funk_verdict(C)}
            <button class="ls-funk ls-funk-{v.phase}" onclick={() => strike_funk(C)}
                 title="Credence cell · click to run · {funk_bound(C) ?? 'unbound'} — {v.phase === 'good' ? `green, ${v.pass}/${v.total} steps` : v.phase === 'bad' ? `red, ${v.pass}/${v.total} steps` : 'awaiting a run'}{v.dige ? ` @ ${String(v.dige).slice(0,8)}` : ''}">
                <span class="ls-funk-ico">{v.phase === 'good' ? '✓' : v.phase === 'bad' ? '✗' : '◴'}</span>
                <span class="ls-funk-name">{C.sc.Funkcion}</span>
                {#if v.total}<span class="ls-funk-steps">{v.pass}/{v.total}</span>{/if}
                {#if C.sc.of_dock}<span class="ls-funk-dock">{leaf(C.sc.of_dock)}</span>{/if}
            </button>
        {/if}
    {:else}
    {@const t = item_type_of(C)}
    {#if t}
        {@const td       = ITEM_TYPES[t]}
        {@const items    = (() => { void C.version; return C.o() as TheC[] })()} 
        {@const dpath    = t === 'Doc' ? C.sc.Doc as string : undefined}
        {@const dyn_cls  = td.item_cls_fns.filter(f => f.when(C)).map(f => f.cls).join(' ')}
        <div class="{td.item_cls} {dyn_cls}">
            <div class="ls-item-hdr">
                {@render pi(item_props(C, upC, t, dpath))}
            </div>
            {#if td.child_types}
                {#if editing.has(C) && (add_type_C.has(C) || add_raw_C.has(C))}
                    <div class="ls-add-row">{@render pi(add_item_props(C, orb_trigger.get(C) ?? C))}</div>
                {/if}
                {#if items.length}
                    <div class="ls-items">
                        {#each items as child (child)}
                            {@render waftitem(child, C)}
                        {/each}
                    </div>
                {/if}
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
    }
    .ls-waft-active { border-color: #446 }

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

    /* Point — pink left border, warm label */
    .ls-item-point {
        border-left: 2px solid #4a2a3a; padding-left: 0.3rem;
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

    /* %havoc — a Ballistics pad, struck to pop a limb out of the Lies/Store plumbing.
       Renders inline among the tree rows; presses down + flashes warm on a hit. */
    .ls-havoc { margin: 0.15rem 0; }
    .ls-havoc-pad {
        display: inline-flex; align-items: center; gap: 0.35rem;
        padding: 0.2rem 0.5rem;
        background: #1a1408; border: 1px solid #3a2c10; border-radius: 5px;
        color: #c9b48a; cursor: pointer;
        box-shadow: 0 2px 0 #0c0a04;
        transition: transform 0.06s, box-shadow 0.06s, background 0.12s, border-color 0.12s;
    }
    .ls-havoc-pad:hover  { background: #221a0c; border-color: #5a4418; color: #e8d4a4; }
    .ls-havoc-pad:active { transform: translateY(2px); box-shadow: 0 0 0 #0c0a04; }
    .ls-havoc-hit {
        background: #4a3410; border-color: #c89a3a;
        box-shadow: 0 0 10px rgba(200, 154, 58, 0.6); color: #ffe6a8;
    }
    .ls-havoc-glyph { font-size: 0.95rem; line-height: 1; }
    .ls-havoc-label { font-family: monospace; font-size: 0.74rem; }
    /* self-arming pad (%havoc,arm): a cooler cast + a ⟳ mark; it lights warm
       (.ls-havoc-engaged) the moment its What holds the spotlight and the limb
       self-fires, the same glow a manual hit gives. */
    .ls-havoc-armed { border-color: #2c3a4a; }
    .ls-havoc-armed:hover { border-color: #44627e; }
    .ls-havoc-arm { font-size: 0.7rem; color: #6a86a8; line-height: 1; }
    .ls-havoc-engaged {
        background: #14283a; border-color: #4a86c8;
        box-shadow: 0 0 9px rgba(74, 134, 200, 0.55); color: #cfe4ff;
    }
    .ls-havoc-engaged .ls-havoc-arm { color: #9cc4ee; }
    /* raw mode (switcheroo Waft): show the bare particle, not the pad */
    .ls-havoc-raw {
        font-family: monospace; font-size: 0.74rem; color: #8a7a5a;
        padding: 0.1rem 0.2rem;
    }
    /* ── Funkcion test-light (the Credence cell) — good|bad|working, reusing the
         Langui verdict idiom (✓ green / ✗ red / ◴ working). ── */
    .ls-funk {
        display: inline-flex; align-items: center; gap: 0.35rem; margin: 0.15rem 0;
        padding: 0.15rem 0.5rem; border-radius: 5px; cursor: pointer;
        border: 1px solid #2a2a3a; background: #14141e;
        font-family: monospace; font-size: 0.74rem; color: #99a;
        transition: filter 0.1s, transform 0.06s;
    }
    .ls-funk:hover  { filter: brightness(1.3); }
    .ls-funk:active { transform: translateY(1px); }
    .ls-funk-ico  { font-size: 0.9rem; line-height: 1; }
    .ls-funk-name { color: #c4c4d4; }
    .ls-funk-steps{ font-variant-numeric: tabular-nums; }
    .ls-funk-dock { color: #667; font-size: 0.7rem; }
    .ls-funk-good    { border-color: rgba(106, 208, 160, 0.4); background: rgba(106, 208, 160, 0.08); color: #6ad0a0; }
    .ls-funk-good    .ls-funk-name { color: #8fe4c0; }
    .ls-funk-bad     { border-color: rgba(255, 136, 136, 0.4); background: rgba(255, 136, 136, 0.08); color: #f88; }
    .ls-funk-bad     .ls-funk-name { color: #f9a; }
    .ls-funk-working { border-color: #3a3420; color: #c4a86a; }
</style>
