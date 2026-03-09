import { TheC, type TheUniversal } from "$lib/data/Stuff.svelte";
import type { Travel } from "$lib/mostly/Selection.svelte";
import { throttle } from "$lib/Y";
import { Dexie, type EntityTable } from 'dexie';




// when any H/A/w/r needs eg a Work object constructed

export function concretion(T:Travel) {
    let {D,path_bit_ark} = T.sc
    // ~~ a column name if we were looking at H/A/w/r
    // < the supply this schema-part or path-bit, path_bit_ark
    let _class = classes[path_bit_ark]
    // the D%* is a possibly slightly different copy of the C%*
    //  so we look for eg C%w:SomeWay and construct a Work().name=SomeWay
    let name = D.sc[path_bit_ark]

    let inst = new _class({name})

    if (D.oa({inst:1,concretion:path_bit_ark})) throw `concretion repeat`
    D.i({inst,concretion:path_bit_ark})
    return inst
}

// Housing is everything through H/A/w/r
//  
abstract class Housing extends TheC {
    // WAS Modus
    //  had .F|PF|S links to the (Pier/)?feature/thing housing it...
    //  < those become lookups? wanting a piece of the rowing|tupling this Housing is embedded in

    // the %w:name or %A:name
    // < do we want to use name_numbered_for_uniqueness_in_Set() and the Selection?
    name:string

    // event stream
    todo: TheC[] = $state([])

    // Housing may involve startup methods and stuff
    started = $state(false)

    // upward link
    up?: Housing

    constructor(opt:TheUniversal) {
        super({sc:{anObj:1}})
        Object.assign(this,opt)

        this.start()
    }
    declare start:Function

    mutex(label:string) {
    }
}




//#endregion
//#region House

export const db = new Dexie('sveltelivequery') as Dexie & {
  House: EntityTable<House, 'name'>;
};

db.version(1).stores({
  House: 'name, json, Lines',
});

db.on('populate', () => {
  db.House.bulkAdd([
    {
      name: 'Initia',
      json: '{}',
    },
  ]);
});


export class StorableHousing extends Housing {
    stashed = $state()
    start() {
        $effect(() => {
            if (this.started) {
                // < all start() dependencies resolved...
                //   just loading from IDB for now?
            }
        })
        // Reactively persist stash whenever it mutates
        const save = throttle(() => {
            if (!this.stashed) return
            _dexie_put(this._db_key, JSON.stringify(this.stashed))
        }, 200)
        $effect(() => {
            if (this.stashed && Object.keys(this.stashed).length) {
                save()
            }
        })

        // < start by reading our House/$name, to determine .stashed
    }
}
export class House extends StorableHousing {
}
export class Street extends StorableHousing {
    
}

//#endregion
//#region Area

// map eg %H -> class House
const classes = {H:House}