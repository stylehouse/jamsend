import { SvelteMap } from "svelte/reactivity"

function arre(a:Array,gone,neu) {
    const i = a.indexOf(gone)
    if (i < 0) throw "!found"
    a[i] = neu
}
export class NotPeerily {
    stash = $state({})
    save_stash:Function|null
    constructor(opt={}) {
        Object.assign(this, opt)
    }

    // for test convenience, has the first|only one of:
    eer:NotPeering
    pier:NotPier
    startup() {
        this.eer = this.a_NotPeering('one')
        this.pier = this.eer.a_NotPier('two')
    }

    // own pubkey addresses
    //  are one per Peer, so we create them here
    addresses:SvelteMap<Prekey,Peering> = $state(new SvelteMap())
    a_NotPeering(id) {
        let eer = this.addresses.get(id)
        if (!eer) {
            eer = new NotPeering({P:this})
            this.addresses.set(id,eer)
        }
        // stash it with our known selves (keypairs, listen addresses)
        // also, have a list of these...? to keep real objects out of P.stash
        let stashed = this.stash.Peerings?.find(a => a.id.startsWith(id))
        if (!stashed) {
            eer.stashed = {id}
            stashed = eer.stashed
            this.stash.Peerings ||= []
            this.stash.Peerings.push(stashed)
        }
        // < can we update it from eer/Pier?
        eer.stashed = stashed
        arre(this.stash.Peerings,stashed,eer.stashed)
        return eer
    }
}
class NotPeering {
    P:NotPeerily
    stashed = $state()
    constructor(opt={}) {
        Object.assign(this, opt)
    }
    Piers:SvelteMap<Prekey,Pier> = $state(new SvelteMap())
    a_NotPier(id) {
        let pier = this.Piers.get(id)
        if (!pier) {
            pier = new NotPier({P:this.P})
            this.Piers.set(id,pier)
        }
        
        // stashable
        // .pubkey as primary key, ignore malformed
        if (this.stashed.Piers?.find(a => !a.id)) {
            this.stashed.Piers = this.stashed.Piers.filter(a => a.id)
        }
        let stashed = this.stashed.Piers?.find(a => a.id?.startsWith(id))
        if (!stashed) {
            // svelte reactivity: must be given to the object first
            //  or it won't be the same object as ends up in .Piers
            pier.stashed = {id,uninitiated:true,policies:[]}
            stashed = pier.stashed
            this.stashed.Piers ||= []
            this.stashed.Piers.push(stashed)
            // svelte reactivity: must wake up the array, or something?
            //  or Pier.svelte will not react to its changes
            //   this gotcha seems much stranger than the above
            this.stashed.Piers = this.stashed.Piers
        }
        pier.stashed = stashed
        arre(this.stashed.Piers,stashed,pier.stashed)
        return pier
    }
}
export class NotPier {
    P:NotPeerily
    stashed = $state()
    tweakstash?:Function
    constructor(opt={}) {
        Object.assign(this, opt)
    }
}