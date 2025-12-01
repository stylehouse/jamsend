import type { TheC, TheUniversal } from "$lib/data/Stuff.svelte";
import type { Selection, Travel } from "./Selection.svelte";
import { hak, Parserify, reverse } from '$lib/Y'

export class Structure {
    // guessing, implying structure
    // upwards, propagate D**%readin=$aspect about the tracks
    // Artist get %readin:type,val:artist
    async intelligible_name(T:Travel) {
        let {D,n} = T.sc
        let i_readin = (t:string,s:TheUniversal) => {
            D.i({readin: t, thetime: this.thetime, ...s})
        }
        await D.replace({readin: 1}, async () => {
            const name = n.sc.name as string;
            const p = new Parserify(name);
            
            if (n.sc.nib === 'blob') {
                let format, type, seq

                // Extract and index file extension
                if (p.p(/\.([a-z0-9]{3,4})$/i)) {
                    format = p[1]!.toLowerCase();
                    i_readin('name', {format});
                    
                    // Determine if it's a track
                    if (format.match(/^(mp3|wav|ogg|m4a|aac|flac|opus|webm|oga|mkv|mka|mp4)$/)) {
                        type = 'track'
                        i_readin('name',{type});
                    }
                }
                
                // Extract and index track number from start
                if (p.p(/^(\d+)[\s\.\-_]+/, '')) {
                    seq = Number(p[1])
                    i_readin('name', {seq});
                }
                
                // Clean up punctuation noise at the edges
                p.p(/^[\s\-_\.]+/)
                p.p(/[\s\-_\.]+$/);
                // Collapse multiple spaces
                while (p.p(/  +/,' ')) 1
                
                // Final cleaned name
                const cleaned_name = p.s.trim();
                i_readin('name', {name: cleaned_name});

                if (type == 'track') {
                    // coherent enough!
                    //  make %%art out of all this
                    //   unlikely to be wrong at this level,
                    //    we may regard more context when hoisting it as %%ads
                    i_readin('art',{track:cleaned_name,seq,format})
                }
            }
            
            if (n.sc.nib === 'dir') {
                // Directory handling depends on finding D**%readin:type,val:track somewhere
                //  extrapolate outwards to become D^^%readin:type,val:artist
                // note D.replace() is happening, so we .bo() the previous time
                //  during replace(), only the newly placed items are findable with .o()
                
                let said_album = 0
                let said_artist = 0
                let said_collection = 0
                for (let oD of D.bo({Tree:3})) {
                    // D:Album/Tree:Track*
                    if (oD.oa({readin:1,type:'track'})) {
                        // tracks imply we are an album
                        if (!said_album++) {
                            i_readin('inners',{type:'album'})
                        }
                    }
                    if (oD.oa({readin:1,type:'album'})) {
                        // albums imply we are an artist
                        if (!said_artist++) {
                            i_readin('inners',{type:'artist'})
                        }
                    }
                    if (oD.oa({readin:1,type:'artist'})) {
                        // artists imply we are a collection
                        if (!said_collection++) {
                            i_readin('inners',{type:'collection'})
                        }
                    }
                }

                // < be more tentative, guess, configure what character
                // notice '0 chill' etc genre|classification|purpose directories
                if (p.p(/^(0|-) /i)) {
                    if (!said_collection++) {
                        i_readin('inners',{type:'collection'})
                    }
                }

                // 
                if (said_album && said_artist
                    || (said_album || said_artist) && said_collection) {
                    // an artist dir with a few loose tracks?
                    D.o({readin:1,type:'album'}).map(n => D.drop(n))
                    said_collection
                        && D.o({readin:1,type:'artist'}).map(n => D.drop(n))
                }


                i_readin('name', {name: p.s.trim(), thetime: this.thetime});
            }
        });
    }

    // upwards propagate more stuff
    async percolating_ads(T:Travel) {
        let {D} = T.sc
        // random flood of %ads hoisted about tracks
        // < do in a second traversal of D** and incorporate how the hierarchies have flopped out
        //    including from top-down
        //    
        // < which pseudo-randomly shuffles what to talk about at the top level
        // 
        // < can make ads about:
        //    D/oD/%readin=type,val=track|album|artist

        //    D/oD/%readin=track
        //    D/oD/%readin=album
        //    D/oD/%readin=artist
        // the fact we also D%readin=

        // < prefers to advertise albums

        // < guess if we're "Artist - Album (1979)" based on the surroundings
        // haphazardly extend up, or spawn whole, %artist,album,track tuples
        await D.replace({ads: 1}, async () => {
            // look at here
            let meta = {}
            let gather_meta = (type:string) => {
                let name = D.boa({type:type,readin:1})
                        && D.boa({name:1,   readin:'name'},1)[0]
                if (name != null) {
                    meta[type] = name
                }
            }
            gather_meta('collection')
            gather_meta('artist')
            gather_meta('album')
            gather_meta('track')

            // meta accumulates when hoisted, on ads
            let i_ads = (t:string,sc={}) => {
                // set ads twice for object property ordering...
                //   because sc may contain it from below
                //  ie every %thing,with,values is a thing primarily
                return D.i({ads:0,...meta,...sc,ads:t,
                     thetime:this.thetime})
            }

            let some_inners = false
            for (let oD of D.bo({Tree:3})) {
                // ads build up locality as they hoist
                let few = 3
                oD.oa({ads:1})?.map((n:TheC) => {
                    if (few-- < 1) return
                    i_ads('beyond',n.sc)
                    some_inners = true
                })
            }

            if (hak(meta)) {
                // we could start advertising this thing!
                if ('prand' || 'track') {
                    // starts with|as any %%art found here
                    //  so individual track info as such
                    // < folder.jpg?
                    let arts = D.boa({readin:'art'})?.map((n:TheC) => ({...n.sc}))
                        || [{noart:1}]
                    for (let art of arts) {
                        delete art.readin
                        i_ads('here',art)
                    }
                }
            }
        });
    }
}