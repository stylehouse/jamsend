<script lang="ts">
    // Editron — the IDE, run as a Story Book.  Booted via ?B=Editron: Otro stamps H.c.book, Auto
    //  activates the Editron Book (Auto.svelte), and Story_subHouse stands up its Run by calling
    //   Run_A_Editron below (the Run_A_<Book> recipe, mirroring Run_A_PereStaple).
    //
    //  Why a Book and not a bare top-level world: running the editor AS a Story makes its own
    //   startup one observable, re-runnable step.  If the editor breaks, re-run the Book and read
    //    the step snap to see how far boot got (Lies up? Waft open? docks compiled?) — diagnostics
    //     are Story-based, so the editor's boot is the first of the "runtime stories".  After the
    //      boot step the Run stays live and the editor is used interactively.
    //
    //  Run_A_Editron lays A:Editron/w:Editron + editor-flavoured Lies/Lang (+ Pantheate) INTO the
    //   Book's Run, so the Run's own think/reqdo_sweep pumps them.  The per-beat handler H.Editron
    //    opens the Waft (from ?W=) — that one action is the Book's single "watch itself start up".
    //
    //  Lies%editor is the explicit counterpart to the runner's Lies%runner: the two ends share the
    //   same Waft — runner running it UIless (read→compile→include), editor editing it (full
    //    chrome).  editor:1 / runner:1 are the symmetric flags; today the code branches on !w%runner.
    import { type House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import { boot_param } from "$lib/boot"

    let { M } = $props()

    // The Waft this editor opens on boot, from ?W=<Waft> (env W= in node), default Ghost/Net/Easy.
    //  A Waft path implies the wormhole/ prefix — Lies_open_Waft → Lies_waft_snap_path resolves
    //   Ghost/Net/Easy → wormhole/Ghost/Net/Easy/toc.snap.  Ghost/Net/Easy is the overlay carrying
    //    the Peeroleum/Peregrination .g docks — the same Waft the runner shares.
    const EDITOR_WAFT = boot_param('W') || 'Ghost/Net/Easy'

    onMount(async () => {
    await M.eatfunc({

        // Run_A_Editron — the Editron Book's Run recipe.  Story_subHouse calls this once (the
        //  Run has no A: yet) to wire the editor's actors into the Run, exactly as
        //   Run_A_PereStaple wires the test runner's.  The actors must live in the Run so its
        //    own think/reqdo_sweep pumps the Lies/Lang compile chain.
        Run_A_Editron(this: House) {
            const H = this
            // The Run's authoritative role — one source of truth every actor in it
            //  reads via Lies_role (incl. Pantheate, whose w carries no flag).  This
            //   is what makes the editor compile-and-write but NOT mount/run.
            H.c.role ??= 'editor'   // boot param (?E=) wins; this is the Library-boot fallback
            // Editron's boot-step snap captures the whole Lang state — but Editron is NOT a compiler
            //  test, so the full generated .go module text on each %Compile/%Output (hundreds of lines
            //   per dock) is pure snap noise.  Flag the run so Lang_compile_dock munges the SNAPPED
            //    source to a marker; the real source still rides the Lies_compiled elvis for the write,
            //     and %Output.dige stays the compile fingerprint, so nothing the run asserts on is lost.
            H.c.mungOutputstring = 1
            H.i({ A: 'Editron' }).i({ w: 'Editron' })
            // editor-flavoured Lies/Lang: full chrome (NOT runner:1), edits the Waft.
            H.i({ A: 'Lies' }).i({ w: 'Lies', editor: 1 })
            H.i({ A: 'Lang' }).i({ w: 'Lang', editor: 1 })
            H.i({ A: 'Pantheate' }).i({ w: 'Pantheate' })
            console.log(`🛠 ${H.name} Editron wired`)
        },

        // Editron(A,w) — the Book's per-beat handler (w:Editron resolves here).  Opens the editor's
        //  Waft once; the boot step's snap then captures the editor standing up on it.  Idempotent
        //   via w.c.Editron_opened so later beats (and re-runs) don't re-open.
        async Editron(A: TheC, w: TheC) {
            const H = this as House
            if (w.c.Editron_opened) return
            w.c.Editron_opened = true
            H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path: EDITOR_WAFT })
            console.log(`🛠 ${H.name} Editron — opening Waft:${EDITOR_WAFT}`)
        },

    })
    })
</script>
