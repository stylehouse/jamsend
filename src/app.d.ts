// See https://svelte.dev/docs/kit/types#app.d.ts
// for information about these interfaces
declare global {
	namespace App {
		// interface Error {}
		// interface Locals {}
		// interface PageData {}
		// interface PageState {}
		// interface Platform {}
	}

	// Cluster-trust public anchors baked into the client by vite.config's `define`
	//  (from process.env, PUBLIC values only). Declared so the literal access
	//   import.meta.env.VITE_CLUSTER_* type-checks AND stays verbatim for the define swap.
	interface ImportMetaEnv {
		readonly VITE_CLUSTER_TRUSTED_PUBS?: string
		readonly VITE_CLUSTER_ROLE?: string
	}
}

export {};
