# caveat

hardcoded /home/s/ in various places

# running server instances

install-jamsend-prod.sh shall install a service, depends on leproxy, see also ../prod.sh

install-jamsend-stack-watchdog.sh installs jamsend-stack-watchdog.service: a probe round a minute over prod vite
 (page + relay upgrade), Caddy (leproxy-caddy-1) and the jamserve daemon, restarting whichever stops answering
  (journalctl -u jamsend-stack-watchdog -f). Policy and overrides are in jamsend-stack-watchdog.sh's header.

# running chrome appservers

We seem to expose a lot of instability in chrome or something doing this... Chrome runs best on the host desktop environment, but once they go Oh Snap how do you restart them? And they lose their handles, see below.

Ultimately, hopefully we can separate a single user's concerns, becoming an operating system for programs... Hosting the file handles in a separate chrome tab that almost never crashes because it doesn't do anything else, talking to the latest in a series of other tabs we shunt the real work along, like a progress bar of failure... The user bulk-reloads every week or so? Who knows. They could be in a different browser profile if user had another Pier just for the filehandle tab, they could WebRTC to each other.

The first two rungs (a dockerised supervisor of Xvfb Chromes with a Puppeteer watchdog, then a KVM VM reverted to a
 snapshot) kept Chromes alive by RESTARTING them, and it went badly. Both are retired to `history/` (see its README).

## simply — just the real desktop (the dev-instance path)

All the rungs above fight one windmill: keeping FSA Directory Handles alive across Chrome restarts on
 a box with nobody at the keyboard. A **dev instance** (see `../Dev_instance.md`) doesn't need that — a
  human IS reachable, VNCs in, and re-grants occasionally. So the whole handle-preservation apparatus
   (Xvfb, the Puppeteer watchdog, the KVM snapshot-revert) is overkill. This rung goes the other way:
    *less* complexity.

- **`jamsend-vnc.service`** (installed by `install-jamsend-vnc.sh`) runs one `x11vnc` against the
   **real logged-in desktop `:0`** (`-noshm -localhost -rfbport 5900`). No Xvfb, no separate WM, no VM —
    the machine's own desktop session already has a working dbus + xdg-desktop-portal + window focus, so
     it just *is* the appserver display. The installer also retires the old headless three
      (`jamsend-xvfb`/`-wm`/`-x11vnc` on `:10`) off this host.
- **Chrome runs on `:0`:** `DISPLAY=:0 chromium --user-data-dir=<profile> '…/Otro?E=…'`. Because it's a
   real DE, the native "📂 open share" **file picker actually works**. On the headless Xvfb `:10` it only
    flickered and threw `AbortError` — no portal backend, no dbus session, and a WM that couldn't hold the
     transient dialog. Grant once with the runner's `--user-data-dir`; the handle persists in that
      profile's IndexedDB and the runner tab restores it (`Directory.svelte.ts` restoreDirectoryHandle).
- **`ty/desktop-viewer.sh <host>`** tunnels 5900 and opens a local vncviewer — the `:0` sibling of
   `xvfb-viewer.sh` (which pointed at the now-retired `:10` on 5910).
- Handle loss is *tolerated, not prevented*: a "reload every ~30 min" Chrome extension shakes wedged
   tab-state, and the human re-grants on the next VNC-in.

Gotchas learned the hard way (all real, all cost an hour):
- **Your SSH `$DISPLAY` is a lie.** Under `ssh -X`, `echo $DISPLAY` shows `localhost:11.0` — the
   forwarded tunnel, not `:0`. Launch anything GUI without an explicit `DISPLAY=:0` (or `:10`) prefix and
    it renders back on your laptop ("chrome popped up outside the vncviewer"). Always prefix.
- **`-auth guess` fails from an SSH shell** (it can't find `:0`'s cookie): run x11vnc as root — the
   service does — or pass the explicit `-auth /var/run/<dm>/…` path. And **`-noshm` is mandatory**:
    attaching MIT-SHM to `:0` across the root/owner boundary is denied (`BadAccess` on `X_ShmAttach`).
- **`http://localhost:9091` showing "Not secure" is fine** — that's just the plain-http badge. localhost
   is still a secure *context* (`window.isSecureContext === true`), so FSA is fully available there.