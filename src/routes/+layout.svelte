<script lang="ts">
	import '../app.css';
	// THE CONSOLE RING INSTALLS HERE, ON EVERY ROUTE (2026-09-06).  It used to install in Otro.svelte —
	//  which is the cluster page (?E=/?B=), so a music page (`/?I=<pub>`, this layout's root route) never
	//   ran it and `runner_ask console --player=` read an empty ring from a tab that had logged hundreds of
	//    lines.  The layout is the one script every tab executes, and it runs before the page's own boot,
	//     so the ring also catches the boot lines.  Idempotent (concap's conInstalled) and browser-guarded
	//      inside, so SSR and a second mount are both no-ops.  Pure in-memory, never persisted, never snapped.
	import { concap_install } from '$lib/O/sockcap';
	concap_install();

	let { children } = $props();
</script>

{@render children()}
