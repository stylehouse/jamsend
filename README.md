# jamsend

modern music piracy in the browser

![at sea](static/screenshot.webp)

[Demo serves an album of mine](https://jamsend.duckdns.org:9999/#############7950f300faa8a4f9-ope.n~0-729547c09f15f29f) in ogg or flac. That invite gets you the ability to invite other peers. Ideally you and your peer are present somewhere you have wifi, with your phones, to begin with...

# the particle graph

**🔥safety🏠** Could be better but is fantastic. No strangers exist, only your contacts.

**🦊p2p🐉** Music comes from connections you make. Manipulation is impossible.

**🌊experience🎶** You listen to someone’s music collection, always jumping into the middle of a random track, like tuning a radio. Normal, everyday options spring up.

**🚛downloads📦** Preserve directory structure, tend to move whole albums, and restart if interrupted.

**🛰️jamserve🎛️** Your own always-on peer. The same app, headless in a container, holding your collection and answering heists and invites when your browser is closed. See *jamserve* under [setup](#jamserve--your-own-always-on-peer).

# development

Get this to your programmers! Make noise as Issues on github, especially grandiose new feature requests that introduce your creative mind.

We are an ongoing project to capture the core of the universe with language, and fix the computer once and for all!

Currently appearing in the guise of modern music piracy, built on a secure and open social medium, soon becoming a hive of diverse developments, attracting low-stakes creativity to the digital frontier.

## news 

A new top-level at lib/O/Otro.svelte is in development, with a bunch of fancy simplicities... It's a much more elegant integration with svelte, etc.

Work is currently progressing towards using it to make a presentation of this project in the next week or two. We're also trying to establish the nice new architecture that I want developers to look at.

Involving a compiler of a nice new language and CodeMirror integration, figuring out how to start using Selection and io expressions together, then we can much more recreationally build testable app code, particularly Radios and Pirating. Architectural problems (causing ugly code) should be fixed. It should all look good in Cyto.

It has a nice style+house pattern emerging: Stuff and Housing are very central to everything yet opposite in nature... universal and empirical. the players and the canopy lighting timeclock.


# hiring

Proudly supporting the $3/hr programmer, which means under 16 in NZ. You may volunteer! Go for it. All development, commissioning and correspondence is on github under the eyes of the law.

Open an issue if anything isn't easy.

There are many non-frontend things to do. See Issues on github, or comments starting with < in the code, which means less-than-existing, ie TODO.

# funding

[Send tips!](https://ko-fi.com/ostylehouse) Ready to technically manage lots of quality work on a new computer culture and direction for the humans, which is somewhat here in this project.

# notes

DevTools with 'pause on exception' will need to ignore the line in Decoder.ts with a meaningless RangeError, etc, it sometimes adds random breakpoints, which can be ignored or switched off in the expandy-rack to the right, between Watch and Scope.

Identities (an OurPeering) can be copied out of and into the UI somewhere, if you defeat the FaceSucker

## prod

To use *prod.sh*, see *Peer_OPTIONS*. I would ./install.sh then scp (clone) the entire leproxy repo to the server at ~/src/leproxy, then run ~/src/prod-jamsend/prod.sh (that repo is git cloned from my machine, this pulls), then that produces a there/ to scp to your proxy host. See also *ty/* to run a flock of chrome instances with your identities.

## objects, data layer

Here is a tour of the p2p layer, then some primitive almost-data-layer objects like *Thing* that are quite pragmatic and irrelevant, then, really,  *TheC*. To start reading the code, try [data/Stuff](src/lib/data/Stuff.svelte.ts) and [Housing etc in O](src/lib/O), which has obsoleted (reinvented) *Modus*, *Things* etc... So from here til the Stuff section is likely obsolete as well..

To write code, the src/lib/ghost/\*.svelte is the best place to build things because it'll update the Modus live without restarting anything, but they need to be included by a Modus, which are included by some kind of *\*Feature*, so do a whole lot of searches and readings, you probably want to add another %w=yourmethod to some M.do_A().

### Peerily...

Is the main|single object doing p2p. It persists to localStorage info mentioned in this section. It has one or more *Peering* listen addresses (which are public keys) which collect *Pier* remote counterparts when people scan QR codes or so.

*Pier* can give each other trust (see *TrustName*), which might also come from QR codes or so. Trust enables a *PierFeature* (*PierSharing*) at both ends, which shows UI parts of the feature relevant to the individual *Pier*, and also a *PeeringFeature* on *Peering*, for the main, for-itself UI of the feature as a whole, eg *PeeringSharing*.

### Things

Are persisted to IndexedDB. They CRUD, start|stop, and integrate with the *Things*/*Thing* UI generics which have specifics imposed by their client, eg *Shares*.

Eg *PeeringSharing* has a *DirectoryShares* object that can be given to the *Things* UI, which takes care of getting each *Thing* happening, including autovivifying the first one. It's important that this list of things uses IndexedDB because that's how to persist the *FileSystemDirectoryHandle* permission we acquire across page reloads.

### Stuff

*TheC* is a piece (C) of the computer's mind, and is posited as the standard linguistic item you should believe in. It is the set of properties on the thing (philosophically, not the *Thing* mentioned above). There's an upper (C.sc) and lower (C.c) hemisphere, supposing the user is up and the machine is down. C.c is for esoteric hacks for very nearby machinery, C.sc is for everything you'd ever want to see, one way or another.

*TheC* extends *Stuff*, which allows them to contain each other (eg C/C, C/C/C, etc), and thus insert (C.i({props:1})) and select (C.o({props:1})) them. There's a way replace subsets of them ongoingly, which usually resolves which is which so they can know their history by simply containing what they did before, so they magically aren't re-inserted empty though it looks like it until the replace finishes. This is an important trick to making code easy.

We can note the name of a C variable, and some relevant structure and properties like so:

``%record/*%preview`` is the many %preview inside a %record

``record/preview,duration`` is about the same, less plurality implied, and refers to the duration property, as well as the mainkey ``preview``, which most of their data falls under, like an object type.

``D%nib:dir`` is probably in a tree of D**, and its nib is dir.

*Stuffing* puts them on the screen efficiently, grouping like stuff, compressing communication.

*Travel* does recursion into trees of C (aka C**, eg C/C, C/C/C, etc).

*Selection* is *Travel* with change tracking and enough thinking to be useful for eg *Directory* and *Cytoscaping*, it should be a fairly universal type of stuff-going-on. We usually simply put something somewhere and realise it's the same thing we put there last time, this is an attempt to formalise that part of reality with lifecycles of beings in situations.

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
- Stuff.replace() and Stuff.resolve() (aka re-identity) are important to adapt to and study academically, for a design pattern more suited to [merge](https://en.wikipedia.org/wiki/Merge_(linguistics))
- Selection.process() as a care factory for intersecting realities

## goals

- hiring $3/hr programmers
- get funding
- shared directories
- climbing directories, properly randomly selecting, transcoding in ffmpeg-wasm
- guess the `Artist/1979 Album/01 Track.etc` hierarchy, general noise sorter and goo tuner
- read a big music library via some API, eg readonly open your Strawberry music player's sqlite database, to be able to search up tracks
- streaming, show gear. voice calls?
- safer content filter. assure media-contained album art is legit.
- collectivise music collection connections, ie multi-hop
- build a trust network, advanced social network features aka SafetyNet
- cytoscape ui, presence|rate|pitch-bendable aud
- culture (ethnology, typology, ?) graph
- auto-heal corrupt data
- utopian stuff, conservation schemes for local disk space alleviation

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
# having already configured leproxy to tunnel or not, etc.
```

If your docker0 interface isnt 172.17.0.1 (so eg _leproxy_ can reverse to it), edit *docker-compose.yml* and related things until it works. You should then look at `docker compose ps` to see where it's listening, it may need to be on localhost. Getting it on the interweb is left a bit hard, just help this project until we make an app scripting language and the community can develop what you need.

## jamserve — your own always-on peer

*a user's personal internet infrastructure, music piracy only for now*

A browser tab is a bad place to keep a peer: it closes, it sleeps, it forgets. **jamserve** is the same
 jamsend app booted headless in its own container — it holds your collection, serves heists, and is
  standing there when someone finally redeems an Invite you handed out weeks ago. A third thing
   alongside dev (`docker compose up`) and prod (*prod.sh*) — it shares their compose file but sits
    behind a profile, so it only ever starts when you name it.

### your identity lives in your music folder

This is the part to understand before anything else, because it explains both how to set jamserve up
 and the one way you can get hurt.

**Your music directory is also where you live.** Point the app at a collection and it makes a
 `.jamsend/` beside your music, holding an `account/<prepub>/` per identity (plus `radiostock/`, a
  bounded cache of pre-encoded audio, and `identities/`, a friendly-name roster). Mounting the folder
   into jamserve therefore hands it both jobs at once: the music to serve, and the identity to serve
    it *as*. That is deliberate — everyone uses the same folder-grant, so the `<prepub>` path segment
     is what keeps two owners apart, and no per-device root is needed.

**jamserve never invents an identity — you provision one in a browser.** Open the app, grant your
 music folder with the File System Access picker, and let it write the account. Then:

```bash
ls <music>/.jamsend/account/         # the directory names ARE the prepubs
JAMSERVE_ID=<that prepub> docker compose up -d jamserve
```

That prepub is your address on the wire — the same string the app shows beside your name in the
 invite panel. `JAMSERVE_ID` becomes the app's own `?I=<prepub>` resume, so jamserve boots *as* you:
  same peer, same friends, same invites, across restarts and rebuilds. Set it to a prepub with no
   account on disk and it **exits 2** rather than pretending to be a stranger.

Leave it unset and jamserve mints a throwaway instead, so you can try the box out before provisioning
 anything. It will say so, loudly and repeatedly — a throwaway is nobody's friend, no one can invite
  it, and its identity dies with the container.

**A throwaway hands out its own way in**, which makes the whole thing testable in about a minute. Not
 knowing anybody is exactly the problem an invite solves, so a throwaway box mints one unasked and
  prints it:

```
🎟 INVITE — this box is a throwaway, so here is a single-use way in.
   Open in an incognito tab (single use — one Pier, then it is spent):
   http://localhost:9091/BigSoundland?Iz=<token>
```

Open that in a private window and you are a second peer, sealed to the daemon, listening to music it
 serves. A **provisioned** box never does this — that identity is *you*, and quietly minting invites
  to your real self into a logfile would be handing out your friendship without being asked.

> ### ⚠ security — the account file holds your private key, in the clear
>
> `.jamsend/account/<prepub>/toc.snap` contains your **ed25519 private key, unencrypted**. Whoever
>  holds that file *is you*: they can sign as you, answer your friends, and redeem your invites.
>
> Inside jamsend that is safe, and safe for reasons that are enforced rather than hoped for: `.jamsend`
>  is never peer-readable, a share walk returns **audio files only** so a peer can never see this file,
>   and replication moves data objects rather than raw files. There is no path by which jamsend itself
>    ships it.
>
> **But those guarantees are jamsend's alone, and they do not extend to anything else you point at the
>  same folder.** A second sync or sharing tool over your collection — Syncthing, Resilio, Dropbox,
>   another p2p music app — will cheerfully replicate `.jamsend/` along with the music, and at that
>    point your key is wherever that tool sends it. So either exclude dot-directories there (most such
>     tools take ignore patterns — Syncthing's `.stignore` and friends), or don't share a collection
>      jamsend is living in. If a key does get out, mint a new identity; there is no revoking one.
>
> Anything that changes what a share walk returns, or makes `.jamsend` peer-readable, has to revisit
>  key-at-rest here. The landmine is documented in the code too, at `Swarm_account_save`.

It is a service in *docker-compose.yml* like the others, but behind a **profile**, so a plain
 `docker compose up` never starts it. Naming it turns its profile on for you, so the commands stay
  short:

```bash
# build and start it (add MUSIC_PATH=... if your collection isn't the default in docker-compose.yml)
JAMSERVE_ID=<your prepub> docker compose up -d --build jamserve

# watch it
docker logs -f jamserve         # or: docker compose logs -f jamserve
tail -f jamserve/run.log        # the same thing, on the bind mount

# stop it
docker compose stop jamserve
```

It runs as **uid 1000**, so everything it writes into your music folder stays yours and the browser
 can still read the account it shares. (It didn't, at first — as root it laid down `.jamsend` mode 700
  owned by `root`, locking out the browser that provisioned it. If you have such a directory from an
   early run, `sudo rm -rf <music>/.jamsend` before starting again; it holds nothing but a throwaway.)

⚠ **If you are upgrading from a version that ran as root, a rebuild alone will not fix the volumes.**
 Docker keeps both of jamserve's volumes across a rebuild — `up` reuses the previous container's
  *anonymous* volume (`/app/node_modules`) instead of repopulating it from the new image, and the
   *named* `jamserve-state` survives by design. So the new image's ownership never lands, and jamserve
    fails as uid 1000 a few minutes after a green boot, when vite writes `node_modules/.vite/deps`.
 Drop them explicitly:

```bash
docker compose rm -sf jamserve
docker volume ls | grep jamserve-state && docker volume rm <project>_jamserve-state
docker compose up -d --renew-anon-volumes jamserve
```

 `jamserve-state` is safe to drop — it is Dexie working state that re-seeds from `<music>/.jamsend`.
  **Do not reach for `docker compose down -v`** as a shortcut: `-v` removes the *project's* named
   volumes, which includes `claude-auth` (the `claude` service's credentials and session history).

Start it **once**. You don't need an `up --build` loop to pick up code changes: the source is
 bind-mounted, and `JAMSERVE_SECS` makes the process exit on a timer so `restart: always` brings it
  straight back on freshly-edited source. Rebuild only when the Dockerfile or *package.json* moves.

Knobs, all optional, all read from your environment or a *.env*:

| | |
|---|---|
| `MUSIC_PATH` | your collection on the host. Mounted read-**write** here (unlike dev's `:ro`) because the account lives in `<music>/.jamsend`; the `LIBRARY=` knob keeps the write surface honest inside the app — `music` read-only, only `.jamsend` writable. |
| `JAMSERVE_ID` | the prepub to resume. Unset ⇒ mints a throwaway. |
| `JAMSERVE_ROLE` | relay address it binds (default `jamserve`). Not `runner` — two claimants of `runner` both receive every frame. |
| `JAMSERVE_SECS` | seconds before a voluntary exit-and-restart (default 900). `0` for a box that never exits on its own. |
| `JAMSERVE_ORIGIN` | where the relay is (default `http://172.17.0.1:9091`, ie the dev `app`). |
| `JAMSERVE_TOKEN` | bearer for the status endpoint, published bridge-only on `172.17.0.1:9099`. |

The container is Alpine with `ffmpeg` from `apk` — never npm; `/app/node_modules` is shared between a
 musl and a glibc container already and a third installer strands the others (there's a whole warning
  about this in *CLAUDE.md*). An anonymous volume shadows `node_modules` so jamserve keeps the musl
   tree its own image built.

Rough edges, honestly. **Loudness levelling already works in the browser** — every track is measured
 for integrated LUFS and gained to −14 LUFS (with a −1 dBFS peak ceiling) *before* the opus encode, so
  classical arrives as loud as everything else and a kept `.ogg` sounds like the stream it came from.
   jamserve can't do it *yet*: that path measures through a Web Worker and encodes through WebCodecs,
    neither of which exists in node, which is what the ffmpeg in this image is for — one
     `-af loudnorm` pass that both measures and corrects. Until that lands, jamserve serves the
      preview window and not the continuation. It also still boots vite in middleware mode rather than
       a built bundle, so it spends ~12s transforming on every start. See
        *src/lib/O/spec/Daemon_todo.md*.

## Licensing

Is AGPL 3.0 or later, no holding back releasing your derived work and notes and all. We want working systems here on Earth, remain open. Copyright (c) 2025 github.com/stylehouse