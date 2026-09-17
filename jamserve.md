
### UserDaemon — it takes over your identity

Run jamserve as *yourself* and it **is** you on the network: same prepub, same friends, same invites.
 That is the point, and it is also the whole risk.

⚠ **Do not run the same identity in a browser tab and in jamserve at the same time.** Two sockets
 claiming one prepub both receive every frame, and the failure does not look like a conflict — it
  looks like your peers going quiet. Pick one home for an identity, or give the daemon its own.

Four knobs, all set in **`.env`** at the repo root (gitignored). They are compose *substitutions*, so
 they must be in `.env` or your shell — **`.env.local` does not work for these**, and putting them
  there fails silently, leaving you on the defaults:

| in `.env` | is | default if unset |
|---|---|---|
| `MUSIC_PATH` | the collection, mounted read-write at `/music` | the path in *docker-compose.yml* |
| `JAMSERVE_ID` | which prepub to boot as — see below | mints a throwaway |
| `JAMSERVE_ORIGIN` | which server's `/relay` it joins | `http://172.17.0.1:9091`, the dev server |
| `JAMSERVE_TOKEN` | password for the daemon's own control port (`/stop`, `/c`, `/restock` on `:9099`, bound to the docker bridge) | a literal committed to this repo — **set it** |

Then `docker compose up -d --build jamserve`, and check the boot log says it *resumed* your prepub
 rather than minting. Point it at your dev server first; move `JAMSERVE_ORIGIN` once that works.

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
 anything. It will say so, loudly and repeatedly. Note what a throwaway actually is: **not** a
  temporary thing that evaporates — it mirrors itself into `<music>/.jamsend/account/` like any other
   identity and is resumed from there on the next boot, so it is the same peer each time. What makes
    it a throwaway is that *you* did not mint it in a browser, so nobody holds a Pier to it and nobody
     can be served by it — and that it has left an unencrypted private key in your music folder you
      never asked for. Delete that directory to be rid of it.

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

