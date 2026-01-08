# jamsend

Hifi streaming with radio-tuner UI

# features

## p2p

Music comes from connections you make, ideally you're sitting next to each other.

## radio-tuner

Peer-to-peer music sharing where you turn the knob and jump into the middle of a random track, like tuning a radio.

# setup

```bash
# get such a container
docker compose build
# populate your ./node_modules, mounted in the container under /app
docker run --rm -v .:/app jamsend-app:latest npm install
# thence
docker compose up
# maybe eventually
cd ..; git clone jamsend prod-jamsend; cd prod-jamsend; ./prod.sh
```

If your docker0 interface isnt 172.17.0.1 (so eg _leproxy_ can reverse to it), edit *docker-compose.yml* and related things until it works. You should then look at `docker compose ps` to see where it's listening, it may need to be on localhost. Getting it on the interweb is left a bit hard, just help this project until we make an app scripting language and the community can develop what you need.

# development

Is go. This should grow into the best place for code to live, etc. You may be paid $3/hr if under 16 and in NZ, you may volunteer. All development, commissioning and correspondence is on github under the eyes of the law. There are about 20 40hr developments I expect we can manage 70% success with in the first two weeks.

There are many non-frontend things to do. See Issues, or anything commented as < in the code, which means TODO.

## notes

DevTools with 'pause on exception' will need to ignore the line in Decoder.ts with a meaningless RangeError, etc, it sometimes adds random breakpoints, which can be ignored or switched off in the expandy-rack to the right, between Watch and Scope.

To use *prod.sh*, see *Peer_OPTIONS*, but we no longer use socket.io which it may be unadapted for.

## objects, data layer

AI says: Besides p2p and audio, we need a sophisticated, reactive data structure and UI framework, with a focus on managing dynamic, hierarchical data (like directory listings) and visualizing it in a way that responds to frequent updates.

Here is a tour of the p2p layer, then some primitive almost-data-layer objects like *Thing* that are quite pragmatic and irrelevant, then what is more meaningful: what we do with *TheC*.

If you want to write new code, the src/lib/ghost/\*.svelte is the best place to build things because it'll update the Modus live without restarting anything, but they need to be included by a Modus, which are included by some kind of *\*Feature*, so do a whole lot of searches and readings, you probably want to add another %w=yourmethod to some M.do_A().

### Peerily...

Is the main|single object doing p2p. It persists to localStorage info mentioned in this section. It has one or more *Peering* listen addresses (which are public keys) which collect *Pier* remote counterparts when people scan QR codes or so.

*Pier* can give each other trust (see *TrustName*), which might also come from QR codes or so. Trust enables a *PierFeature* (*PierSharing*) at both ends, which shows UI parts of the feature relevant to the individual *Pier*, and also a *PeeringFeature* on *Peering*, for the main, for-itself UI of the feature as a whole, eg *PeeringSharing*.

### Things

Are persisted to IndexedDB. They CRUD, start|stop, and integrate with the *Things*/*Thing* UI generics which have specifics imposed by their client, eg *Shares*.

Eg *PeeringSharing* has a *DirectoryShares* object that can be given to the *Things* UI, which takes care of getting each *Thing* happening, including autovivifying the first one. It's important that this list of things uses IndexedDB because that's how to persist the *FileSystemDirectoryHandle* permission we acquire across page reloads.

### Stuff

*TheC* is a piece (C) of the computer's mind, and is posited as the standard linguistic item you should believe in. It is the set of properties on the thing (philosophically, not the *Thing* mentioned above). There's an upper (C.sc) and lower (C.c) hemisphere, supposing the user is up and the machine is down. C.c is for esoteric hacks for very nearby machinery, C.sc is for everything you'd ever want to see easily.

*TheC* extends *Stuff*, which allows them to contain each other (eg C/C, C/C/C, etc), and thus insert (C.i({props:1})) and select (.o({props:1})) them. Sets of them get replaced ongoingly, which usually resolves which is which and resumes|re-attaches their /*, eg C/C/C that C/C had before it was re-inserted empty.

We can note (in comments and spec (so far)) the name of a C variable, and some relevant structure and properties like so:

``neu%nib=dir`` is new (you can't use the reserved word new), its .sc.nib='dir'

``%record/*%preview`` is the many %preview inside a %record

*Stuffing* puts them on the screen efficiently, grouping like stuff, compressing communication.

*Travel* tracks recursion into trees of C (aka C**, eg C/C, C/C/C, etc).

*Selection* is and locates C**, by the higher level Artist/Album/Track hierarchy or via directory path...

*Modus* is an agenda to attend to, has a heartbeat, provides persistent memory via *Modusmem*... Eg *DirectoryModus* wanders around your *DirectoryShare* looking for music to make available, and traces of our mind we may have stored in there.

And now all further introduced *Objects* here are not javascript classes of their own, but are *TheC* that define themselves with their C.sc.*, eg A:such is C%A=such .

*Modus* (aka *M*), or some subclass of it, contains many *A*/*w* that organise to do the work. They can handle events via %elvis=sometype,Aw=suchAplace/workertype .

About here is the frontier, but probably:

And now these are the important user-mind things to persist in *Modusmem* and beyond:

*View* shall look into *M/A/w\*\** and process it via *Stuffing* and *Selection* into *Cytoscape* and other UI-things... Probably solving the difficulty connecting the *Stuffing* etc UI interaction <-> the process flowing into it.

*Heist* does the sequential work of replicating a *Selection* somewhere. It should work on either end.

*Info* know about *Heist*s, and whatever the user jots down about anything. Inform layout. Remain.

### Ultimately

- machine should be more feminine and competent
- C and everything in Stuff.svelte.ts
- Stuff.replace() and Stuff.resolve() are important to adapt to and study academically, makes a pattern more suited to [merge](https://en.wikipedia.org/wiki/Merge_(linguistics))
- Selection.process() as a care factory

## goals

- get funding
- shared directories
- climbing directories, properly randomly selecting, transcoding in ffmpeg-wasm
- guess the `Artist/1979 Album/01 Track.etc` hierarchy, or pulling in ffmpeg-wasm to read tags?
- read a managed music library via some API, eg readonly open your Strawberry music player's sqlite database.
- streaming, show gear. voice calls?
- collectivise music collection connections
- build a trust network
- cytoscape ui, presence|rate|pitch-bendable aud
- culture (ethnology, typology, ?) graph
- auto-heal corrupt data
- utopian stuff, conservation schemes for local disk space alleviation

## Licensing

This project is licensed under the terms of the **GNU Affero General Public License v3.0 or later**. The full text of the license can be found in the [LICENSE](LICENSE) file.

Also you must release everything you build with it that is useful, eg makes money, entirely enough to be as useful as it is for you. Don't hold back! You're about to die!

Copyright (c) 2025 github.com/stylehouse