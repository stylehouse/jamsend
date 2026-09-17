# jamsend

modern music piracy in the browser

![at sea](static/screenshot.webp)

An invite gets you the ability to invite other peers. Ideally you and your peer are present somewhere you have wifi, with your phones, to begin with...

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

### ⚠ hosting on your own router

Behind a port-forward + dynamic-DNS name, your own LAN usually can't reach your own public name —
 most routers won't hairpin a packet back to their own outside address (search **NAT hairpin/loopback**
  if it's news). The fix is to point the name at your LAN IP wherever it's being resolved: a line in
   `/etc/hosts` for a desktop browser, or `extra_hosts:` on the container's compose service (see
    `jamserve` in *docker-compose.yml*, fed from gitignored `.env` vars) for anything running in Docker.
     Don't swap in the LAN IP itself instead — it fails TLS and vite's `ALLOWED_HOSTS` check; keep the
      name, only change where it resolves.

## objects, data layer

### Stuff

*TheC* is the convoluted name for the type C, the main type, the piece of the computer's mind, the standard item you should believe in. It is a set of properties on a thing, so a bunch of pieces of text -> other pieces of text. There's an upper (C.sc) and lower (C.c) hemisphere, supposing the user is up and the machine is down. C.c is for esoteric hacks for very nearby machinery, C.sc is for everything you'd ever want to see, one way or another.

*TheC* extends *Stuff*, which allows them to contain each other (eg C/C, C/C/C, etc), and thus insert (C.i({props:1})) and select (C.o({props:1})) them. There's a way replace subsets of them ongoingly, which usually resolves which is which so they can know their history by simply containing what they did before, so they magically aren't re-inserted empty though it looks like it until the replace finishes. This is an important trick to making code easy.

We can note the name of a C variable, and some relevant structure and properties like so:

``%Waft/*%Doc`` is the many %Doc inside a %Waft

``Doc/Point,method`` is about the same, less plurality implied, and refers to the method property, as well as the mainkey ``Point``, which most of a Doc's data falls under, like an object type.

``Text%dige`` is a property of a thing: a Text's dige.

*Stuffing* puts them on the screen efficiently, grouping like stuff, compressing communication.

*Travel* does recursion into trees of C (aka C**, eg C/C, C/C/C, etc).

*Selection* is *Travel* with change tracking and enough thinking to be useful for eg mirroring nodes into cytoscape. It should be a fairly universal type of stuff-going-on. We usually simply put something somewhere and realise it's the same thing we put there last time, and this is an attempt to formalise that part of reality... Wants lifecycles, beings, situations...

*House* is an agenda to attend to, has a heartbeat, provides persistent memory.

*House* (aka *H*), or some subclass of it, contains many *A*/*w* that organise to do the work. They can handle events via %elvis=sometype,Aw=suchAplace/workertype .

Then many further *Objects* are not javascript classes of their own, but are *TheC* that define themselves with their C.sc.*, eg A:such is C%A=such, and somehow those properties are meaningful.

### Ultimately

- machine should be more visually pleasing and competent
- C and everything in Stuff.svelte.ts
- Stuff.replace() and Stuff.resolve() (aka re-identity) are important to adapt to and study academically, for a design pattern more suited to [merge](https://en.wikipedia.org/wiki/Merge_(linguistics))
- Selection.process() as a care factory for intersecting realities

## goals

- hiring $3/hr programmers
- get funding
- shared structures
- guess the `Artist/1979 Album/01 Track.etc` hierarchy, general noise sorter and goo tuner
- read a big music library via some API, eg readonly open your Strawberry music player's sqlite database, to be able to search up tracks
- streaming, show gear. voice calls?
- safer content filter. check media-contained album art is legit.
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

A browser tab is a bad place to keep a server: it closes, it sleeps, it forgets. **jamserve** is the same
 jamsend app running on nodejs in its own container — it holds your collection, serves heists, and is
  standing there when someone finally redeems an Invite you handed out weeks ago. A third thing
   alongside dev (`docker compose up`) and prod (*prod.sh*) — it shares their compose file but sits
    behind a profile, so it only ever starts when you name it.

see [jamserve.md]

## Licensing

Is AGPL 3.0 or later, no holding back releasing your derived work and notes and all. We want working systems here on Earth, remain open. Copyright (c) 2025 github.com/stylehouse