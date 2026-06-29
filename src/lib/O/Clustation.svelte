<script lang="ts">
    // Clustation.svelte — the cluster IDENTITY layer (the network self, kept OFF Lies).
    //
    //  A %Identity is the per-?I self: it OWNS a %Peering (our real pub address — 1:1 in the
    //   common case) and, later, the trust it has earned. It is the CONCRETION of a persisted
    //    identity-thang (the Thangs `identities` table, Peeroleum_spec §10) — the live particle a
    //     Dexie row hydrates into. The cluster signing key rides on the %Identity (.c.keys — a
    //      secret, never sc, never encoded), and Lies_cluster_idento reads the ACTIVE one, so the
    //       relay `hello` (LiesLies) binds prepubOf(pub)→our socket: to:<pub> then routes to a
    //        VERIFIED Id — the address Waft:Cluster lists and the punter dials.
    //
    //  ?I=<tag>   resume that identity (mint it the first time)
    //  ?I=new     always mint a FRESH identity — a fork (the hop-over primitive)
    //  (absent)   no identity layer: Lies_cluster_idento falls back to the .stashed/.env key, so
    //              this is inert until a peer is booted with ?I= — non-breaking.
    //
    //  Persistence is Thangs (Dexie, shared across all tabs in the profile) — but only the
    //   IDENTITY lifts into its own `identities` rows; the rest of the stashed pile stays shared.
    //    A fresh ?I=new starts COLD (no trust): trust rides the %Identity, per the settled design.
    //
    //  First slice: ensure runs ONCE at boot (Auto), minting|loading + concreting the active
    //   %Identity. The per-pass p2pman worker (react to liveQuery; ensure a %Peering per
    //    online_want) and the ui/Net/ health view are the follow-ups.
    import { onMount } from 'svelte'
    import { Idento } from "$lib/Y.svelte"
    import { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { boot_param } from "$lib/boot"

    let { M } = $props()

    onMount(async () => {
        await M.eatfunc({

            // Clustation_mint — a fresh ed25519 keypair, the codebase way (Idento), as a storable
            //  {pub, key, prepub, friendly}. pub/key are full hex; prepub is the 16-hex routing
            //   address (= header.from / the %Peering name / the to:<pub> target).
            async Clustation_mint(this: House, friendly?: string) {
                const ido = new Idento()
                await ido.generateKeys()
                const f = ido.freeze()                       // { pub, key } hex
                const prepub = ido.pretty_pubkey()           // 16-hex
                return { pub: f.pub as string, key: f.key as string, prepub, friendly: friendly ?? `id-${prepub.slice(0, 6)}` }
            },

            // Clustation_ensure_identity — resolve ?I= and stand up the active %Identity (+ its
            //  %Peering) under A:Clustation, persisted as an `identities` Thang. Idempotent per
            //   session (the Auto caller guards on H.c.identity_up). No ?I= ⇒ no-op (legacy key
            //    path). Async, but no liveQuery race: thang_add/thang_peek hit Dexie directly, and
            //     the %Identity is concreted here-and-now rather than awaited off a subscription.
            async Clustation_ensure_identity(this: House, H?: House): Promise<boolean> {
                H = (H ?? this) as House
                const param = boot_param('I')
                if (!param) return true                       // no identity layer requested — done
                // The Thangs persistence helpers are deposited by a sibling ghost; if the boot tick
                //  beat that mount, report not-done so the caller retries next pass (don't latch).
                if (typeof (H as any).thang_add !== 'function' || typeof (H as any).thang_peek !== 'function') return false
                const A  = H.o({ A: 'Clustation' })[0] || H.i({ A: 'Clustation' })
                const wT = A.o({ w: 'Thangs', thangs: 'identities' })[0]
                        || A.i({ w: 'Thangs', thangs: 'identities' })
                wT.c.up = A

                let tag: string
                let stored: { pub: string; key: string; prepub: string; friendly?: string } | undefined
                if (param === 'new') {
                    stored = await (H as any).Clustation_mint()
                    tag = stored!.prepub                       // a fresh identity is named by its own prepub
                    await (H as any).thang_add(wT, tag, stored)
                } else {
                    tag = param
                    const peeked = await (H as any).thang_peek('identities', tag)
                    if (peeked?.pub && peeked?.key) stored = peeked
                    else { stored = await (H as any).Clustation_mint(tag); await (H as any).thang_add(wT, tag, stored) }
                }

                // Concrete the live %Identity — keys on .c (a secret: never sc, never encoded) —
                //  owning its %Peering (the pub address, 1:1). The active flag rides as 1/absent so
                //   it stays snap-clean; only ONE %Identity is active at a time.
                for (const old of A.o({ Identity: 1 }) as TheC[]) delete old.sc.active
                const ident = A.oai({ Identity: tag }) as TheC
                ident.c.up = A
                ident.c.keys = { pub: stored!.pub, key: stored!.key }
                ident.sc.prepub = stored!.prepub
                if (stored!.friendly) ident.sc.friendly = stored!.friendly
                ident.sc.active = 1
                const peering = ident.oai({ Peering: 1, name: stored!.prepub }) as TheC
                peering.c.up = ident
                H.c.active_identity = ident
                console.log(`🪪 Identity ${param === 'new' ? 'minted' : 'active'} ${tag} (${stored!.prepub})`)
                return true
            },

            // Clustation_active_identity — the ACTIVE %Identity's signing key {pub, key}, or
            //  undefined. Read by Lies_cluster_idento. Prefers the stamped ref; falls back to the
            //   %Identity,active flag so a re-mixed method (HMR) still resolves.
            Clustation_active_identity(this: House, H?: House): { pub: string; key: string } | undefined {
                H = (H ?? this) as House
                const top = (H.top_House?.() ?? H) as House
                let ident = (top.c as any)?.active_identity as TheC | undefined
                if (!ident) {
                    const A = (top.o({ A: 'Clustation' }) as TheC[])[0]
                    ident = A && (A.o({ Identity: 1 }) as TheC[]).find(i => i.sc.active)
                }
                const keys = (ident?.c as any)?.keys as { pub?: string; key?: string } | undefined
                return keys?.pub && keys?.key ? { pub: keys.pub, key: keys.key } : undefined
            },

        })
    })
</script>
