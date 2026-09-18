# jamsend

modern music piracy in the browser

![at sea](static/screenshot.webp)

An invite gets you the ability to invite other peers. Ideally you and your peer are present somewhere you have wifi, with your phones, to begin with...

# the particle graph

**🔥safety🏠** Could be better but is fantastic. No strangers exist, only your contacts.

**🦊p2p🐉** Music comes from connections you make. Manipulation is impossible.

**🌊experience🎶** You listen to someone’s music collection, always jumping into the middle of a random track, like tuning a radio. Normal, everyday options spring up.

**🚛downloads📦** Preserve directory structure, tend to move whole albums, and restart if interrupted.

# development

Get this to your programmers! I'm wanting to promote myself to management. Do you have 10hr/week? If you aren't allowed to make $3/hr you'll have to volunteer. Make noise as Issues on github, especially grandiose new feature requests that introduce your creative mind.

We are an ongoing project to capture the core of the universe with language, and fix the computer once and for all!

Currently appearing in the guise of modern music piracy, built on a secure and open social medium, soon becoming a hive of diverse developments, attracting low-stakes creativity to the digital frontier. Oh, and all this .g code is quite ugly and I tend not to read it, we're going to fix that at some point.

Interesting areas of development besides the does-a-two-word-thing (music piracy) imperative:

## stho - new programming language

Lies+Lang are compiler|infra and code editor for a new language with more path expressions etc. Promises nice database abstraction. Compiles to javascript. I've neglected it while getting this MVP done, seeking safety. Next steps: meta-programming of having all the IOexpr and Seem known at compile time... It's very creative and unblocked, a brain-teaser.

## Atheory - metaphysics and H|A|w|req

What are these types, really... Probably merge into A, but keep w, and r, which is distinct from n, e... the %Aw pointer somewhere in, and indeed method resolution and precise imports...

It has a nice style+house pattern emerging: Stuff and Housing are very central to everything yet opposite in nature... universal and empirical. the players and the canopy lighting timeclock.

## Vyto - the attractor

An attractor is a mathematical object for engulfing space with stuff, gently... The computer searches for its new visual capacity, and how to keep it connected to ongoing reality, perhaps needing to pin this down as an important common artifact we need to impress people with civilisation and its glorious information: to create a convincing expression of information to look at... See */BigShapeland?B=VytoOrchestra*

Using it to make a presentation of this project... To establish the nice new architecture that I want developers to look at.

## Story - testing

It's quite a futuristic testing system. It captures big deterministic pictures, occasionally leaning on EntropyArrest. It has a huge next-generation wishlist to build, but wants it on top of Atheory.

## Music

What we're doing here... Nice and simple. The system has active (Heist) and passive (SoundPooling) transport whims.

Downloads are weird because you can't get enough filesystem access (FSA) on a mobile device, so Link Device to your computer running Chrome is necessary in that case, Heists land there... So they become a team for music distribution, and SoundPooling (tracks stored in OPFS, in the browser) will keep freshly shuffled music on your phone, as long as both devices are on at the same time...

So there's a "your personal infra" to work out how to stretch music availability across. Lots of this could be slightly different or better! It's the central metaphysical drama that should keep giving to the above four arms of academic development until they're rounded out.

# funding

[You may send tips here!](https://ko-fi.com/ostylehouse) Funds may be for specifics soon, probably starting with educational videos...

# notes

DevTools with 'pause on exception' will need to ignore the line in Decoder.ts with a meaningless RangeError, etc, it sometimes adds random breakpoints, which can be ignored or switched off in the expandy-rack to the right, between Watch and Scope.

Identities (an OurPeering) can be copied out of and into the UI somewhere, if you defeat the FaceSucker

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
- streaming, show gear. voice calls? moderation?
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

If your docker0 interface isn't 172.17.0.1 (so eg _leproxy_ can reverse to it), edit *docker-compose.yml* and related things until it works. You should then look at `docker compose ps` to see where it's listening, it may need to be on localhost. Getting it on the interweb is left a bit hard, just help this project until we make an app scripting language and the community can develop what you need.

### ⚠ hosting at home

**leproxy** also supports tunneling to a public proxy host to reverse a port from, which avoids this flaw.

Behind a port-forward + dynamic-DNS name, your own LAN usually can't reach your own public name —
 most routers won't hairpin a packet back to their own outside address (search **NAT hairpin/loopback**
  if it's news). The fix is to point the name at your LAN IP wherever it's being resolved: a line in
   `/etc/hosts` for a desktop browser, or `extra_hosts:` on the container's compose service (see
    `jamserve` in *docker-compose.yml*, fed from gitignored `.env` vars) for anything running in Docker.
     Don't swap in the LAN IP itself instead — it fails TLS and vite's `ALLOWED_HOSTS` check; keep the
      name, only change where it resolves.

## jamserve — your own always-on peer

*a user's personal internet infrastructure, music piracy only for now*

A browser tab is a bad place to keep a server: it closes, it sleeps, it forgets. **jamserve** is the same
 jamsend app running on nodejs in its own container — it holds your collection, serves heists, and is
  standing there when someone finally redeems an Invite you handed out weeks ago. A third thing
   alongside dev (`docker compose up`) and prod (*prod.sh*) — it shares their compose file but sits
    behind a profile, so it only ever starts when you name it.

see [jamserve/README.md](jamserve/README.md)

# Licensing

Is AGPL 3.0 or later, no holding back releasing your derived work and notes and all. We want working systems here on Earth, remain open. Copyright (c) 2025 github.com/stylehouse