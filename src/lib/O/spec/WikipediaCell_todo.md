# WikipediaCell_todo.md — a Cell:Wikipedia, click for a random page

**The owner, 2026-09-18/20:** wants a `Cell:Wikipedia` — click it, get a random Wikipedia page — as a
 "top-level app personality quirk... an important 'thing on the internet'" (paired with "nazi-fighting
  powers" in the original ask — read as: the app takes a stance for open knowledge, not neutrality
   about it). Small in scope for now; the owner is handing this to a fresh agent, not building it in
    the session that scoped it.

## 0. What to get on with next

**Recommended shape** (not yet built, not yet reviewed by the owner beyond this framing):

- **Don't** download a Wikipedia dump (50G+) for this. That's Kiwix/ZIM territory — a real offline
   mirror, the right tool if the actual goal is ever "resilient when Wikipedia/the internet itself is
    blocked or down," which the "nazi-fighting" framing might genuinely mean eventually. That's a
     separate, much bigger infra project — worth its own todo if the owner confirms that's the intent,
      not folded into this one.
- **Don't** just iframe `https://en.wikipedia.org/wiki/Special:Random` either. Three problems: it's a
   redirect (can behave inconsistently inside an iframe), the live page carries Wikipedia's own full
    chrome (sidebar/nav/edit tabs) that won't fit a small Cell, and it's a live third-party network call
     on every click — sitting oddly next to CLAUDE.md's stated production stance ("no participation in
      any Cluster beyond sending to their peers via relay"). Harmless in practice (Wikimedia is a
       reputable host) but worth knowing it's a deliberate carve-out, not free.
- **Do** use the REST summary API: `GET https://en.wikipedia.org/api/rest_v1/page/random/summary` — a
   few KB of JSON (title, extract, thumbnail URL, canonical article link). Style the card in the app's
    own look rather than fighting Wikipedia's page chrome in a cramped Cell. A click-through to the FULL
     article (new tab, or an iframe/link at the now-known resolved URL) is a separate, later action —
      not the first click.

**Left to whoever picks this up:** where `Cell:Wikipedia` actually lives in the Cell/Cyto vocabulary
 (is it a `%Cell` mainkey like the existing Radio/Door/Pooling cells seen in a real Cello INTENT line —
  `Cello INTENT: main=Radio offedge=false cells=3 [Radio,Door,Pooling]` — or something else entirely);
   whether it needs a Story/Book gate at all (a static external-API card may not need one); rate-limiting
    /caching repeat clicks; and matching this to the "top-level personality" framing (does it belong on
     every screen, or one specific place).
