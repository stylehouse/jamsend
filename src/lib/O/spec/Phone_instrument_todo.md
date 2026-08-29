# Phone_instrument_todo — the phone as instrument

**The loop:** a person out in the world receives pushed music streams; they tag what they hear with
 quick gestures (lockscreen transport key, bluetooth slide-clicker, or a knob|buttonscape device);
  those tags flow back into the shared matter and reshape future pushes. The phone is not a passive
   receiver — it is an instrument the listener plays against the community's computer.

The owner's words (the original statement of intent): *"I'll want a bunch of 'vio' tagged stuff
 shipped to my phone regularly, along with another population of sheer randomness... and I'll tag
  stuff as 'naff' or 'fast' or 'slow' on my phone while playing out there in the world, hopefully
   via the lockscreen PWA but perhaps a bluetooth slide-clicker or knob|buttonscape device before
    long too."*

**Relationship to SoundPooling_todo.** The `vio` stream + the randomness population are pool
 curation — how the community decides what to push and what composition the phone's local pool should
  have. That selection economy belongs to SoundPooling_todo (especially §2.4 Siphon tags, §4.4 Flow
   2 Cave → phone fill, and the proposed `radio.sc.source` rung). This doc focuses on the PHONE side:
    how gestures arrive, what particles a tag creates, how they sync back. Read SoundPooling_todo §0
     and Siphon_todo alongside this doc; they name the other half of the closed loop.

---

## 0. What to get on with next

A fresh session reads here. The overall arc is:

1. **The minimum provable slice** — wire one tag verb (e.g. `Radio_tag_now`) behind the Media
   Session `previoustrack` handler (or a `keydown` on a mapped key). A gesture fires → a
   `%Tagged,of:<origId>` row lands under the right `%Tag` → it snaps → visible in the glass.
   No sync needed yet; prove the in-session model first.

2. **The gesture layer** — a single abstraction (`Radio_gesture(radio, verb)`) that accepts a named
   action (`'tag:naff'`, `'tag:vio'`, `'skip'`, `'play-pause'`) and fires from any surface: Media
   Session handler, `keydown`, and future MIDI/HID/Gamepad surfaces. The layer itself is the
   deliverable — each new surface is a two-liner on top of it.

3. **Tag sync** — replicate the `%Tags` shelf back to the community's computer over Swarm gossip
   (the same frame discipline existing Swarm frames use). A pushed tag becomes a decision-fact in
   the shared matter. This is the loop closing.

4. **The pushed stream** — a standing `vio`-tagged playlist wired as a Radio source rung, so the
   phone's dial walks the community's tagged pool rather than (or as well as) the randomness
   population. The composition dial (what fraction `vio` vs random) is the final curation surface.

5. **The knobscape** — Web MIDI and Web Bluetooth GATT paths, Android/Chrome only, as a ceiling on
   the same gesture abstraction the lockscreen floor already uses.

**Candidates for next move:** §0.1 is the right first move — a single keydown binding that fires
 `Radio_tag_now(radio, 'naff')` and verifies it snaps. That proves the particle model and the
  gesture layer in one gesture without any sync machinery.

---

## 1. The tag particle model

### 1.1 The existing foundation

`Siphon.g` already defines the tag model (built 2026-08-28, SoundPooling_todo §2.4). The exact
 shape:

```
%Tags (on the radio world — w.oai({Tags:1}))
  %Tag,name:<word>                  ← one particle per tag word, find-or-create
    %Tagged,of:<origId>             ← a REFERRING particle, many:1 onto a %Record
```

`Siphon_tag_def(w, name)`, `Siphon_tag_apply(w, tag, origId)`, `Siphon_tag_unapply(w, tag, origId)`,
 and `Siphon_playlist(w, tag)` are the complete CRUD surface. **Do not build parallel machinery.**
  The phone gesture model is a NEW CALLER on top of these exact verbs.

### 1.2 Why `%Tagged,of:` is right for a many:1 tag

CLAUDE.md identity law: a tag is MANY `origId`s associated with ONE tag word. The holding of the
 track is the `%Record`; the tag application is a FACT that lives beside it — a `%Tagged,of:<origId>`
  wearing its OWN mainkey and carrying the id, never a second `%Record` impersonating the holding.

Per the CLAUDE.md snap-boolean rule: removal is `Siphon_tag_unapply` (a `drop`), never setting
 `sc.active = false`. A mis-tag is cheap to undo — drop the `%Tagged` row.

### 1.3 The phone's tags are a superset of the pool's tags

`vio` is both a CURATION LANE (what the Cave pushes to the phone's pool) and a TAG the phone
 listener applies at play-time. The same `%Tags/%Tag,name:vio/%Tagged,of:` model serves both;
  the phone's `%Tags` shelf IS the curation signal once it syncs. No second particle kind needed.

`naff`, `fast`, `slow` are exactly the same model. The tag word is a free string on `%Tag,name:`.

### 1.4 Tag undo discipline

`Radio_tag_toggle(radio, tagWord)` — if `%Tagged,of:<playing-origId>` exists under `%Tag,name:tagWord`,
 remove it (unapply); otherwise apply it. This is the full undo model: one gesture cycles the fact
  on and off. The face (RadioFace or a TagFace chip) reads `tag.oa({Tagged:1, of:origId})` to know
   whether to highlight the tag key.

A `radio.sc.note` line ("tagged naff", "untagged naff") gives immediate lockscreen-readable feedback
 via the existing note chip.

### 1.5 Where tags live in the snap

The `%Tags` shelf sits under the radio world (`w`). It snaps as part of the world's C tree (it is a
 `c.up`-linked particle on `w`). Tags therefore persist across sessions (unlike `radio.c.heard`
  which is session-volatile). This is the right durability — a tag is a decision-fact, not a
   runtime hint.

### 1.6 `Radio_tag_now(radio, tagWord)` — the verb

```
Radio_tag_now(radio, tagWord):
    let rec = radio.c.rec
    if (!rec || !rec.sc.id) {
        radio.sc.note = 'nothing playing to tag'
        radio.bump()
        return
    }
    let origId = String(rec.sc.id)
    let tag = this.Siphon_tag_def(radio.c.w, tagWord)
    let had = tag.oa({ Tagged: 1, of: origId })
    if (had) {
        this.Siphon_tag_unapply(radio.c.w, tag, origId)
        radio.sc.note = 'untagged ' + tagWord
    } else {
        this.Siphon_tag_apply(radio.c.w, tag, origId)
        radio.sc.note = 'tagged ' + tagWord
    }
    radio.bump()
```

This is a pure sync call — no req, no ttlilt. Analogous to `Radio_heist_now`. Should live in
 `Ghost/M/Radio.g` in a new `#region tags` block alongside the heist region.

---

## 2. The gesture layer

### 2.1 One abstraction over all surfaces

The phone may receive a gesture from:
- the lockscreen Media Session transport keys (hardware media keys, PWA lockscreen buttons)
- a `keydown` event from a Bluetooth HID slide-clicker (which enumerates as a keyboard)
- a Web MIDI message from a BLE-MIDI device (Android/Chrome only)
- a Web Bluetooth GATT notify from a custom knob|buttonscape
- the Gamepad API (broad device support, works on iOS Safari in some configurations)
- a touch gesture on the RadioFace itself

None of these should wire directly to `Radio_skip` / `Radio_tag_now`. They all call:

```
Radio_gesture(radio, verb):
    — verb is a string: 'skip', 'play-pause', 'tag:naff', 'tag:vio', 'tag:fast', 'tag:slow', ...
    — dispatches to the right Radio_ verb
    — returns immediately (all Radio_ verbs are sync-safe at their entry points)
```

This is the ONLY call any surface makes. A new input surface is a two-liner:

```js
// example: Gamepad button 3 → 'tag:naff'
if (gp.buttons[3].pressed) Radio_gesture(radio, 'tag:naff')
```

### 2.2 Media Session (the lockscreen floor, iOS + Android)

**What it is.** `navigator.mediaSession` — already wired in `Radio.g` for `nexttrack`, `pause`,
 `play`. The lockscreen card shows track metadata and transport buttons on both iOS Safari and
  Android Chrome when the PWA plays audio. Hardware media keys (headphone inline controls, BT
   headset buttons) fire the same action handlers.

**What is already wired.** `Radio_media_now` (Radio.g ~352) wires `nexttrack → Radio_skip`,
 `pause → Radio_pause`, `play → Radio_go`. Wired lazily once per session (`media_wired` latch).

**What to add.** Two action handlers not yet claimed: `previoustrack` and `seekbackward`.
 `previoustrack` on a BT slide-clicker (PageUp/PageDown enumerate as `previoustrack`/`nexttrack`
  on many devices via the Media Session bridge) is the natural "tag this" key — the one the
   listener reaches for without looking. Map it to `Radio_gesture(radio, 'tag:naff')` or to a
    configurable verb (`radio.sc.tag_prev_key`, defaulting to `'tag:naff'`).

**iOS caveat.** iOS Safari (and WKWebView on iOS) does NOT support Web MIDI, Web Bluetooth, or
 WebHID. The Media Session API + `keydown` (for BT HID keyboards) ARE the iOS ceiling. Design
  the gesture layer so the iOS path is complete and useful without those APIs.

**Android/Chrome extras.** Android Chrome supports Web MIDI (with sysex flag for some devices),
 Web Bluetooth GATT, WebHID, and the Gamepad API. These are the ceiling, not the floor.

### 2.3 `keydown` — Bluetooth slide-clickers and keyboard navigation

BT slide-clickers enumerate as HID keyboards. Common key sequences:
- PageUp / PageDown — "previous / next"
- Arrow keys — depends on device
- Volume keys — routed to OS on most phones, not reachable by a PWA
- Custom keys — device-specific; some map to media keys

Wire a `window.addEventListener('keydown', ...)` in `Sounditron.svelte` or a new `PhoneFace.svelte`
 that catches `PageUp → 'tag:naff'`, `PageDown → 'skip'` (or any mapping from `radio.sc.key_map`,
  a future soft config). The handler must be:
- active only when `radio.sc.Radio !== 'off'` (don't steal keys when the radio is stopped)
- checked for the user-gesture requirement: `Radio_gesture` calls verbs that are already
  user-gesture-safe (they do not open the AudioContext — `Radio_go` handles that)

The `Sounditron.svelte` (or Cytui) already registers a global `keydown` for other uses; the phone
 gesture handler should be a SEPARATE registration, not grafted into existing handlers.

### 2.4 Web MIDI (Android/Chrome only)

`navigator.requestMIDIAccess({ sysex: false })` — works on Android Chrome for class-compliant BLE-MIDI
 devices (BLE-MIDI adapters, MIDI controllers with BT MIDI mode). iOS Safari: not available.

Shape of the wiring:

```js
// one-time at Radio_go or on demand:
if (navigator.requestMIDIAccess) {
    navigator.requestMIDIAccess({ sysex: false }).then(access => {
        for (const input of access.inputs.values()) {
            input.onmidimessage = (msg) => {
                Radio_midi_message(radio, msg.data)
            }
        }
        access.onstatechange = (e) => { /* re-wire on device connect/disconnect */ }
    })
}
```

`Radio_midi_message(radio, data)` maps MIDI CC or Note-On to `Radio_gesture` verbs. The mapping
 is soft (`radio.sc.midi_map` — a future config sc key whose value is a comma-delimited string of
  `cc:verb` pairs, e.g. `'cc74:tag:naff,cc75:tag:vio'`). Default: no mapping until the user
   defines one (a MIDI knob|buttonscape without a config is a no-op, not a surprise).

`sysex: false` is enough for most CC/note-on devices. A device that needs sysex for identity gets a
 one-time permission prompt (Android Chrome shows this); design the fallback as: no sysex → use
  generic CC mapping.

### 2.5 Web Bluetooth GATT (Android/Chrome only)

For a truly custom knob|buttonscape: pair via Web Bluetooth, subscribe to a custom GATT characteristic
 notify, and decode the device's own byte protocol into `Radio_gesture` verbs.

This is the CEILING — the most capable path. Shape:

```js
// user presses "pair device" button (MUST be a user gesture):
const device = await navigator.bluetooth.requestDevice({ filters: [...], optionalServices: [...] })
const server = await device.gatt.connect()
const service = await server.getPrimaryService(SERVICE_UUID)
const char = await service.getCharacteristic(CHAR_UUID)
await char.startNotifications()
char.addEventListener('characteristicvaluechanged', (e) => {
    Radio_ble_message(radio, new Uint8Array(e.target.value.buffer))
})
```

`Radio_ble_message` is the BLE equivalent of `Radio_midi_message` — maps device bytes to
 `Radio_gesture` verbs. The specific protocol is device-defined; the structure (a verb decoder
  calling the gesture layer) is the same.

**iOS: not available.** `navigator.bluetooth` is absent on iOS Safari and WKWebView as of 2026.
 Do not gate any feature on its presence for the iOS path.

### 2.6 Gamepad API (broad, incl. some iOS configurations)

`navigator.getGamepads()` + `gamepadconnected` event. Works on:
- Android Chrome (broad device support including many BT controllers)
- Desktop Chrome/Firefox
- iOS Safari in some configurations (limited; `gamepadconnected` fires but button support varies)

Shape: poll on `requestAnimationFrame` or on a `setInterval` while a radio is playing. Map
 gamepad buttons to `Radio_gesture` verbs via a soft map (same `radio.sc.gamepad_map` config
  pattern as MIDI). This is optional polish, not the first slice.

### 2.7 Gesture map configuration

The soft map (`radio.sc.key_map`, `radio.sc.midi_map`, etc.) lets a listener define their own
 binding without code. Format: a comma-delimited string of `<source-id>:<verb>` pairs, stored as
  a plain sc scalar. For example:

```
radio.sc.key_map = 'PageUp:tag:naff,PageDown:skip,KeyQ:tag:vio'
radio.sc.midi_map = 'cc74:tag:naff,cc75:tag:vio,cc76:tag:fast,cc77:tag:slow'
```

The parser lives in `Radio_gesture_map_parse(mapStr)` → a plain JS object keyed by source-id.
 No C-particles needed for the map itself — it is a single sc value, edited by the listener or by
  a future TagFace config panel.

---

## 3. The pushed stream — how the loop closes

### 3.1 The two populations

The owner describes two populations on the phone:

1. **`vio`-tagged stuff** — tracks the community (or the owner themselves) have tagged `vio`,
   pushed to the phone regularly. This is a CURATED stream: the pool's `vio` playlist.

2. **Sheer randomness** — a second population drawn from the full friend pool without curation
   bias. This is what the radio already does (the shuffle pool, friend-first, heard-this-sitting
    exclusion).

These are not two different radio modes; they are two source-mixing strategies on the dial.
 SoundPooling_todo §3.2 sketches `radio.sc.source` as a three-state cycle; the vio lane is a
  FOURTH rung: `sc.source === 'playlist:vio'` (or generalised: `'playlist:<tagWord>'`).

### 3.2 The playlist rung in Radio_dial

`Radio_dial` already has a ladder. The new rung:

```
if sc.source starts with 'playlist:':
    tagWord = sc.source.slice('playlist:'.length)
    tag = Siphon_tag_def(w, tagWord)  — find-or-create (safe: oai)
    ids = Siphon_playlist(w, tag)     — ordered list of origIds
    rec = first unheard Record from ids that Radio_playable passes
    if rec: return rec
    — fallthrough: pool exhausted, dial falls to next rung
```

`Siphon_playlist` returns origIds. The dial maps an origId to a standing `%Record` via
 `w.o({Record:1, id:origId})[0]` (the pool shelf) — same lookup `Radio_dial_pool_local` would
  use. If the record is not on the pool shelf (the phone doesn't have it yet), the dial falls
   through — this is safe and honest. The tag is a WANT, not a guarantee.

### 3.3 The composition dial

A future `radio.sc.vio_fraction` (0.0–1.0, default 0.5) decides what fraction of plays the
 `playlist:vio` rung serves before handing off to the random rung. The dial reads this as a
  probability weight. This is a single sc scalar on the %Radio particle; no new particles.

For the FIRST SLICE, ignore the fraction and simply alternate: `playlist:vio` for one track, then
 the random rung for one track (a simple `radio.sc.vio_turn` toggle, 1-or-absent).

### 3.4 How tags sync back

Tags created on the phone (via gestures) must reach the community's computer. The mechanism:

**Swarm gossip frame.** The `%Tags/%Tag/%Tagged` tree at `w` already snaps with the world. The sync
 question is: how do two Houses exchange a `%Tags` subtree?

The existing Swarm gossip/Repli machinery moves particles as Waft-encoded frames. The tag tree is
 small (each `%Tagged` is a single sc-line: `Tagged,of:<16-hex-id>`). The right mechanism is a
  **dedicated gossip frame kind** (e.g. `Tags` frame type alongside existing music-specific frames),
   or piggybacking on the existing `Keep`/`Heist` frame discipline where a peer sends a delta of
    new applications.

**Concrete shape (design proposal, not yet specified by Swarm_spec):**
- On a `radio.c.tags_dirty` flag (set by `Radio_tag_now`), the phone queues a `%TagsFrame`
  Waft-encoded as the full `%Tags` subtree.
- The receiving peer merges it: for each `%Tagged,of:id` in the frame, it calls
  `Siphon_tag_apply(w, tag, id)` — which is oai-idempotent. Removals need a tombstone shape
   (a `%Untagged,of:id,at:<timestamp>` under the `%Tag`, analogous to `%NotGrant` in Swarm_spec §2).
   Without tombstones, a removal on one peer does not propagate.

**The tombstone question.** Tags are low-stakes (wrong tags are correctable by the owner); a
 tombstone-less first version (additions only sync, removals are local) is acceptable for the
  initial slice. Add tombstones in a second pass when the sync is proven working.

**Sync occasion.** Do not sync on every tag. Sync at session-end (when `Radio_state(radio, 'off')`)
 or when the phone connects to a peer. One round-trip, not a live stream of gestures.

### 3.5 How the Cave fills the phone's pool from the `vio` playlist

The Cave (the home server) watches the `%Tags` shelf it receives from the phone. When
 `%Tag,name:vio` gains new `%Tagged,of:id` rows, the Cave queues a pool fill for those records:
  a `Ra_quarter_serve`-style steward push (Flow 2, SoundPooling_todo §4.4) with the vio playlist
   as the want-list. This is daemon-side work (the daemon's tour → rest → tour pattern, Daemon_todo).
    The phone receives the pushed pool tracks as Heist chunks landing on the OPFS pool mount.

This closes the loop: phone tags a track `vio` → tag syncs to Cave → Cave fills phone's pool with
 `vio` tracks → phone's radio plays them next session, offline if needed.

---

## 4. The smallest provable slice

### 4.1 What to build first

**One gesture, one tag, one snap.** In `Ghost/M/Radio.g`, add:

1. `Radio_tag_now(radio, tagWord)` — the toggle verb (§1.6 above). Composing `Siphon_tag_def` +
   `Siphon_tag_apply` / `Siphon_tag_unapply`. ~15 lines.

2. In `Radio_media_now`, extend the Media Session wiring to include `previoustrack`:
   ```js
   navigator.mediaSession.setActionHandler('previoustrack',
       () => { this.Radio_gesture(radio, radio.sc.tag_prev_key || 'tag:naff') })
   ```

3. `Radio_gesture(radio, verb)` — the dispatch stub (~20 lines):
   ```
   Radio_gesture(radio, verb):
       if (verb === 'skip') { this.Radio_skip(radio); return }
       if (verb === 'play-pause') { this.Radio_toggle(radio); return }
       if (verb.startsWith('tag:')) {
           let word = verb.slice(4)
           if (word) this.Radio_tag_now(radio, word)
           return
       }
   ```

4. A `window.addEventListener('keydown', ...)` in `Sounditron.svelte` (or a tiny new
   `PhoneInput.svelte` component mounted by the Sounditron) that calls `Radio_gesture` for
   PageUp/PageDown/configurable keys.

**Verify it snaps.** With the radio playing, press PageUp (or the `previoustrack` BT key). Then:

```sh
node scripts/runner_ask.mjs snap 1 | grep Tagged
```

Expect: a `Tagged,of:<origId>` line under the `Tag,name:naff` row in the world snap. That is the
 proof the particle landed and snapped.

**Book (MusuPhoneGesture or a step in MusuRadio).** A Story step that:
1. starts the radio (`Radio_go` in a Book's muted mode)
2. calls `Radio_gesture(radio, 'tag:naff')` directly (no hardware needed in a Book)
3. `%see:'the playing track is tagged naff'` — asserted once it holds

The `%see` sentence is the sworn record. The snap fixture carries the `%Tagged` row.

### 4.2 The arc to the knobscape

| step | surface | what it adds |
|---|---|---|
| 1 (first slice) | Media Session `previoustrack` + `keydown` | lockscreen tag button + BT slide-clicker |
| 2 | `radio.sc.tag_prev_key` config | listener picks which tag `previoustrack` fires |
| 3 | Soft key map (`radio.sc.key_map`) | multiple keys → multiple tag words |
| 4 | Gamepad API (optional) | controller buttons on Android |
| 5 | Web MIDI (`radio.sc.midi_map`) | BLE-MIDI knob/button, Android/Chrome only |
| 6 | Web Bluetooth GATT | fully custom knob|buttonscape, bespoke protocol |

Each step is a new input surface on the SAME `Radio_gesture` abstraction. Steps 5 and 6 require a
 user gesture to request permission; design the pairing flow as a button in RadioFace or a new
  `LinkDevice.svelte` variant (a sibling of the existing `LinkDevice.svelte` for other pairing flows,
   `src/lib/O/ui/LinkDevice.svelte`).

### 4.3 The arc to the closed loop

| step | what closes |
|---|---|
| Phone gesture → `%Tagged` lands in snap | DONE at first slice |
| Tag sync to Cave (Swarm frame, additions only) | loop closes for curation signal |
| `playlist:vio` rung in Radio_dial | phone plays curated stream |
| Tombstone-propagated removals | correct tagging is reversible across devices |
| Cave-side steward pushes vio pool to phone | offline curation is complete |

---

## 5. The lockscreen PWA as a real instrument

### 5.1 What the lockscreen surface IS

A PWA installed on Android (Add to Home Screen) or iOS (Add to Home Screen via Safari) shows a
 lockscreen Now Playing card when:
- a Service Worker is registered (or the PWA is in the foreground enough to have started audio)
- `navigator.mediaSession.metadata` is set (already done in `Radio_media_now`)
- `navigator.mediaSession.playbackState` is `'playing'` (already done)

The lockscreen card shows: track title, artist, artwork (currently `/icon.svg` — a real thumbnail
 would be better long-term), and transport buttons: ⏮ previous, ⏸/▶ play/pause, ⏭ next.

**The `previoustrack` button is the tag button.** Without this doc, ⏮ was unbound (the `previoustrack`
 handler was not registered). Binding it to `Radio_gesture(radio, 'tag:naff')` (or a configurable
  verb) makes ⏮ the phone-out-in-the-world tagging gesture: hear something annoying, press ⏮, move on.

### 5.2 iOS platform reality check

- Media Session API: YES (iOS 15+, works in PWA added to Home Screen)
- `keydown` / HID keyboard events: YES (BT slide-clickers that enumerate as keyboards work)
- Web MIDI: NO — not available on any iOS browser as of 2026
- Web Bluetooth: NO — not available on any iOS browser as of 2026
- WebHID: NO — not available on iOS
- Gamepad API: PARTIAL — `gamepadconnected` fires but support varies by iOS version
- OPFS: YES (iOS 16.4+, the SoundPool's offline store works on iOS)
- PWA install: YES — "Add to Home Screen" from Safari

**The iOS floor is: lockscreen transport (Media Session) + BT HID keyboards (`keydown`).** That
 is enough for the slide-clicker workflow. All other surfaces are Android/Chrome bonuses.

### 5.3 Android platform reality check

- Media Session API: YES (Android Chrome, Chromium-based browsers)
- `keydown` / HID: YES
- Web MIDI: YES (Chrome 78+, requires user gesture + `requestMIDIAccess`)
- Web Bluetooth: YES (Chrome 56+, requires user gesture + HTTPS)
- WebHID: YES (Chrome 89+, desktop only in 2026 — NOT mobile Android yet; verify before building)
- Gamepad API: YES (broad support)
- OPFS: YES (Chrome 102+)
- PWA install: YES — "Add to Home Screen" or install prompt

**Concrete gap on Android:** WebHID is not available on Android Chrome as of 2026 (desktop only).
 A custom button|box connected via BLE goes through Web Bluetooth GATT, not WebHID.

---

## 6. How tags surface in the glass

### 6.1 RadioFace tag chips (minimum)

Under the transport row in RadioFace, a row of small tag chips shows the known tag words:

```svelte
{#each knownTags as tag}
    <button class="rf-tag" class:active={taggedThis(tag)}
            onclick={() => H?.Radio_gesture?.(n, 'tag:' + tag)}>
        {tag}
    </button>
{/each}
```

`knownTags` is derived from `w.o({Tags:1})[0]?.o({Tag:1}) ?? []` — the tags the listener has
 already defined. `taggedThis(tag)` checks `tag.oa({Tagged:1, of:playingId})`. Adding a new tag
  word: a small `+` button opens a text input; on confirm, `Siphon_tag_def(w, word)` and
   `Radio_tag_now(radio, word)` in sequence.

This is the DESKTOP/TABLET face. On the lockscreen, the lockscreen's own transport buttons serve
 the same gestures — the face chips are a secondary redundancy for when the phone is in hand.

### 6.2 The tag as a curation signal visible in Cyto

`%Tags` and `%Tag,name:vio` are C-particles and snap normally. They appear in the Cytoscape glass
 (Cyto_scan walks the world). Matstyle autovivifies a `matstyle:Tag` swatch. A viewer watching
  the glass can see the tag shelf grow in real time as the listener tags from the field — the
   community's computer SEEING its own curation happen.

### 6.3 No new face particle needed for the minimum

The minimum slice needs no new `sc.face` particle — the tag chips live inside RadioFace. A future
 `%TagFace` is warranted only if the tag management UI outgrows a chip row. Keep it in RadioFace
  until that moment.

---

## 7. Bombs (what detonates if the next fork doesn't know)

- **`Siphon_tag_def` is an `oai` — safe to call from `Radio_tag_now`, but never from a derived
   computation (a render-time call to an oai mints a particle, which is a write during a read
    pass).** Always call it from a verb, never from `$derived.by`.

- **The `previoustrack` Media Session handler is a user gesture.** The `navigator.mediaSession`
   handler runs synchronously as a user gesture in iOS 15+ — `Radio_gesture` must never `await`
    inside the handler if it needs to open the AudioContext (it doesn't — tag verbs are sync).
     A mis-fire that puts an `await` in the handler path would silently break the AudioContext
      gesture chain.

- **`keydown` is global — be defensive.** The phone gesture handler must check that the radio is
   playing (`radio.sc.Radio !== 'off'`) and that no text input is focused (`document.activeElement`
    is not an `<input>` or `<textarea>`). Otherwise a user typing a tag name in the config panel
     would fire tags on every keystroke.

- **Web MIDI and Web Bluetooth require HTTPS.** The dev container on localhost:9091 qualifies
   (localhost is a secure context). A remote phone connecting to the app needs a real TLS cert
    or a tunnel; there is no polyfill path.

- **iOS has NO Web MIDI / Web Bluetooth.** Do not `if (!navigator.requestMIDIAccess) return`
   where return means "no gesture possible" — the Media Session + keydown path is the iOS gesture
    path and must not be gated behind MIDI availability.

- **A cold-tab book can call `Radio_gesture` directly.** `Radio_tag_now` is sync and works in a
   Book without a live AudioContext (it only touches sc/C, not the audio pipeline). A Book that
    exercises the gesture model can call `Radio_gesture` without `Sound_gat`, without the device
     standing, without `humdinger`. This is what makes it bookable.

- **Tag sync needs tombstones for removals to propagate.** Additions-only sync is correct for the
   first slice; a removal on the phone without a tombstone will silently NOT propagate to the Cave,
    and the Cave will keep re-pushing the "removed" track. Document this clearly when wiring sync —
     don't paper over it.

- **`Siphon_playlist` returns origIds in child-insertion order.** The Radio_dial playlist rung
   must check `Radio_playable(rec)` before yielding a pick — some origIds in the playlist may not
    have bytes on the pool shelf yet (the push hasn't arrived). Fall through gracefully; don't skip
     or error.

---

## 8. Reference — existing file locations

| thing | file | lines |
|---|---|---|
| `Siphon_tag_def/apply/unapply/playlist` | `Ghost/M/Siphon.g` | 29–62 |
| `Radio_media_now` (Media Session wiring) | `Ghost/M/Radio.g` | ~352 |
| `Radio_heist_now` (gesture pattern to follow) | `Ghost/M/Radio.g` | ~266 |
| `Radio_gesture` (to be added) | `Ghost/M/Radio.g` | new |
| `Radio_tag_now` (to be added) | `Ghost/M/Radio.g` | new |
| `RadioFace` transport + note chip | `src/lib/O/ui/RadioFace.svelte` | 124–208 |
| `ShuffleFace` (pool visual) | `src/lib/O/ui/ShuffleFace.svelte` | 1 |
| `SoundPooling_todo` (pool economy, dial rungs) | `src/lib/O/spec/SoundPooling_todo.md` | whole |
| `Swarm_spec` (gossip frame discipline) | `src/lib/O/spec/Swarm_spec.md` | whole |
| `Siphon_todo` (tag + siphon arc) | `src/lib/O/spec/Siphon_todo.md` | whole |
| `Radio_todo` / `Radio_multicast_todo` | `src/lib/O/spec/Radio_todo.md` | whole |
| `Cluster_spec §3.2b` (relay channel) | `src/lib/O/spec/Cluster_spec.md` | §3.2b |
