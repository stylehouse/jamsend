# jamsend

modern music piracy in the browser

![at sea](static/screenshot.webp)

Someone sends you a link. You open it and you're listening to their music collection — dropped into the middle of a random track, like tuning a radio. Nothing to install, no account, no strangers.

**🔥safety🏠** Only your contacts exist here. Could be better, but it's fantastic.

**🦊p2p🐉** Music comes from the connections you make. Manipulation is impossible.

**🌊experience🎶** of listening, jumping tracks, and plotting Heists...

**🚛Heists📦** Preserve directory structure, move whole albums, and may end up on another computer via Link Device.

# your devices

The catch: A phone browser can't keep a music folder. A computer running Chrome can. So you **Link Device**: the device you started on shows a QR code, you open it on the other, and from then on they are both *you* — your friends see one person, not two.

**Heists land on the computer.** A Heist you start on the phone is written into the computer's folder, album by album.

**🏊 SoundPooling** keeps a fresh, shuffled handful of tracks inside the phone's browser, so there's always something to play with no signal. Whenever both devices are on at once, the pool is topped up and turned over. It's off until you switch it on, in its 🏊 cell: choose how many MB it may use, and whether it pools from your friends, your own devices, or both.

**Something always on.** "Whenever both are on at once" is the weak spot, so there's **jamserve**: the same app, running in docker, on a small always-on box at home. It holds your collection, serves Heists, and is still standing there when someone finally opens the invite you sent them weeks ago (see *jamserve* below).

That's the idea under all of it: your own little infrastructure, stretched across whatever devices you have, so music stays near you.

# try it

You need a link from someone already here... Or run your own instance: set up the app and a *jamserve* (see setup below), and invite your friends.

# funding

[You may send tips here!](https://ko-fi.com/ostylehouse) Funds may be for specifics soon, probably starting with education... Open issues about funding opportunities we could chase...

---

*Everything below is for programmers.*

# development

Get this to your programmers! I'm wanting to promote myself to management. Do you have 10hr/week? If you aren't allowed to make $3/hr you'll have to volunteer. Make noise as Issues on github, especially grandiose new feature requests that introduce your creative mind.

We are an ongoing project to capture the core of the universe with language, fix the computer and save the humans!

Currently appearing in the guise of modern music piracy, built on a secure and open social medium, soon becoming a hive of diverse developments, attracting low-stakes creativity to the digital frontier. Oh, and all this .g code is quite ugly and I tend not to read it, we're going to fix that at some point.

Interesting areas of development besides the does-a-two-word-thing (music piracy) imperative:

## stho - new programming language

Lies+Lang are compiler|infra and code editor for a new language with more path expressions etc. Promises nice database abstraction. Compiles to javascript. I've neglected it while getting this MVP done, seeking safety. Next steps: meta-programming of having all the IOexpr and Seem known at compile time... It's very creative and unblocked, a brain-teaser.

## Atheory - metaphysics and H|A|w|req

Atheory is the model of reality underneath everything: the containers (H), the actors living in them (A), their works (w) and the machine of requirements (req) that drives them — done again so the program is made of the same legible stuff as the data it holds.

A generalised sloped wall leading into the dialectic nestling of computation, so the program can see itself. Every part will declare where it stands, every event will leave a footprint, and nothing will happen that cannot be walked back to and looked at again. The code will become a landscape, and we will cross it on foot.

## Vyto - the attractor

Is the art department. Visual code. Building this seems to be very hard for LLMs in 2026, haven't done enough art!

An attractor is the place a system falls toward, whatever it starts from. Vyto treats information that way: every
  particle becomes a cell, the cells crowd and settle into a picture, and a hand can pin one and watch the rest flow
  round it. The aim is a picture of state convincing enough to look at, and stable enough to keep looking at while
  it changes.

**in other words**

An attractor is where a moving system comes to rest. Vyto is the glass: any C** drawn as settled cells, sized by
  weight, nested by containment, so the same picture serves a running test, a music library or the code itself. The
  computer is looking for its visual capacity here, a common artefact we can point at and say "that's what it's
  doing".

See */BigShapeland?B=VytoOrchestra* 

Using it to make a presentation of this project... To establish the nice new architecture that I want developers to look at.

## Story - testing

It's quite a futuristic testing system. It captures big deterministic pictures, occasionally leaning on EntropyArrest. It has a huge next-generation wishlist to build, but wants it on top of Atheory.

## Music

What we're doing here... Nice and simple. The system has active (Heist) and passive (SoundPooling) transport whims.

*your devices* above is the listener's view. Underneath: a phone has no filesystem access (FSA), so Heists ride the Link Device crew to a computer, and SoundPooling lives in the browser's own storage (OPFS).

So there's a "your personal infra" to work out how to stretch music availability across. Lots of this could be slightly different or better! It's the central metaphysical drama that should keep giving to the above four arms of academic development until they're rounded out.

# notes

## objects, data layer

### Stuff

Everything, the data model, is C (*TheC*), a homoiconic particle, where properties are bunched together, which might give it meaning in multiple systems.

C makes pieces of the computer's mind, the standard item you should believe in. They have properties and can contain each other (eg C/C, C/C/C, etc), and thus insert (C.i({props:1})) and select (C.o({props:1})) them. There's a way `replace` subsets of them ongoingly, which then will `resolve` which was which so they can know their history by simply containing what they did before, so they magically aren't re-inserted empty though it looks like it until the replace finishes. This is an important design, leads to a more reductive system.

The first property (aka mainkey) tends to be its class or object type, each property adds a bit more type. Also reductive, not fully invented as an object model.
We can note the name of a C variable, and some relevant structure and properties like so:

``Waft`` is well known, but ``%somethingelse`` (with a % sigil) may be clearer on its own...

``Text%dige`` equivalent to ``%Text,dige``, but with %dige emphasised.

``Waft/What**/Doc`` is about a %Doc inside perhaps many layers of %What, in a %Waft - `**` meaning recursing.

``What/Point,method`` is about the same, less plurality implied, and refers to the method property, as well as the mainkey ``Point``, which most of a Doc's data falls under, like an object type.

*Stuffing* puts them on the screen efficiently, grouping like stuff, compressing communication.

*Seem* does recursion into trees of C (aka C**, eg C/C, C/C/C, etc) with change tracking and enough thinking to be useful for eg mirroring nodes into cytoscape. It should be a fairly universal type of stuff-going-on. We usually want to put something somewhere and realise it's the same thing we put there last time, and this is an attempt to formalise that part of reality... Wants lifecycles, beings, situations...

*House* is an agenda to attend to, has a heartbeat, provides persistent memory.

*House* (aka *H*), or some subclass of it, contains many *A*/*w* that organise to do the work. They can handle events via %elvis=sometype,Aw=suchAplace/workertype .

Then many further *Objects* are not javascript classes of their own, but are *TheC* that define themselves with their C.sc.*, eg A:such is C%A:such, and somehow those properties are meaningful.

### Ultimately

- machine should be much more visually pleasing and competent
- moving beyond C-like language
- Seem as a care factory for intersecting realities
- Stuff.replace() and Stuff.resolve() (aka re-identity) are important to adapt to and study academically, for a reductionist design pattern more suited to [merge](https://en.wikipedia.org/wiki/Merge_(linguistics)) 

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
  standing there when someone finally redeems an Invite you handed out weeks ago.

see [jamserve/README.md](jamserve/README.md)

# Licensing

Is AGPL 3.0 or later, no holding back releasing your derived work and notes and all. We want working systems here on Earth, remain open. Copyright (c) 2025 github.com/stylehouse