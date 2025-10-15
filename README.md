# jamsend

Hifi streaming with radio-tuner UI

# features

## radio-tuner

Peer-to-peer music sharing where you turn the knob and jump into the middle of any track, like tuning a radio.

## p2p

Is nearly...

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

If your docker0 interface isnt 172.17.0.1 (so eg _leproxy_ can reverse to it), edit *docker-compose.yml* and related things until it works.

# development

The radio-tuner system is currently centralised, nearly ready to rebuild on top of the p2p system for peer-sourcing music.

## notes

DevTools with 'pause on exception' will need to ignore the line in Decoder.ts with a meaningless RangeError, etc

To use *prod.sh*, see *Peer_OPTIONS*.

## objects, data model

Besides p2p and audio, we need a sophisticated, reactive data structure and UI framework, with a focus on managing dynamic, hierarchical data (like directory listings) and visualizing it in a way that responds to frequent updates.

### Peerily...

Is the main|single object doing p2p. It persists to localStorage info mentioned in this section. It has one or more *Peering* listen addresses which collect *Pier* remote counterparts when people scan QR codes or so.

*Pier* can give each other trust (see *TrustName*), which might also come from QR codes or so. Trust enables a *PierFeature* at both ends, which shows UI parts of the feature relevant to the individual *Pier*, and also a *PeeringFeature* on *Peering*, for the main, for-itself UI of the feature as a whole, eg *PeeringSharing*.

### Things

Are persisted to IndexedDB. They CRUD, start|stop, and integrate with the *Things*/*Thing* UI generics.

Eg *PeeringSharing* has a *DirectoryShares* object that can be given to the *Things* UI, which takes care of getting each *Thing* happening, including autovivifying the first one. It's important that this list of things uses IndexedDB to persist the *FileSystemDirectoryHandle* permission we acquire across page reloads.

### Stuff

*TheC* is a piece (C) of the computer's mind. It is the set of properties on the thing (philosophically, not the *Thing* mentioned above). There's an upper (sc) and lower (c) hemisphere, supposing the user is up and the machine is down.

*TheC* extends *Stuff*, which allows them to contain each other (eg C/C, C/C/C, etc), and thus insert and select them.

*Stuffing* puts them on the screen in a space efficient way, similar to how your mind compresses information.

About here is the frontier, but probably:

*Travel* tracks recursion into trees of C (aka C**, eg C/C, C/C/C, etc).

*Modus* is an agenda to recompute, has a heartbeat... Eg *DirectoryModus* wanders around your *DirectoryShare* looking for music to make available, and traces of our mind we may have stored in there...

And now these are the important user-mind things to persist:

*Selection* is and locates C**, by the higher level Artist/Album/Track hierarchy or via directory path...

*Heist* does the sequential work of replicating a *Selection* somewhere. It should work on either end.

## goals

- get funding
- p2p
- peer-sourcing music, shared directories
- climbing directories, randomly selecting, transcoding in ffmpeg-wasm
- guess the `Artist/1979 Album/01 Track.etc` hierarchy, or pulling in ffmpeg-wasm to read tags?
- read a managed music library via some API, eg readonly open your Strawberry music player's sqlite database.
- streaming, show gear. voice calls?
- collectivise music collection connections
- build a trust network
- cytoscape ui, presence|rate|pitch-bendable aud
- culture (ethnology, typology, ?) graph
- auto-heal corrupt data
- utopian stuff, conservation schemes for local disk space alleviation
