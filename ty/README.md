# caveat

hardcoded /home/s/ in various places

# running server instances

install-jamsend-prod.sh shall install a service, depends on leproxy, see also ../prod.sh

# running chrome appservers

We seem to expose a lot of instability in chrome or something doing this... Chrome runs best on the host desktop environment, but once they go Oh Snap how do you restart them? And they lose their handles, see below.

Ultimately, hopefully we can separate a single user's concerns, becoming an operating system for programs... Hosting the file handles in a separate chrome tab that almost never crashes because it doesn't do anything else, talking to the latest in a series of other tabs we shunt the real work along, like a progress bar of failure... The user bulk-reloads every week or so? Who knows. They could be in a different browser profile if user had another Pier just for the filehandle tab, they could WebRTC to each other.

## badly

install-jamsend-supervisor.sh installs a dockerised bunch of chromes that restart, but they keep losing handles, see below.

## maybe well

Jamsend runs three Chromium instances as application servers. They use the browser's File System Access API to hold Directory Handles — persistent references to directories on disk that the web app uses for storage. The handles are granted interactively by a human clicking "Allow" in the browser, and they live in the browser's memory. If Chrome is killed and restarted, the handles are gone and someone has to grant them again.

The old approach ran Chrome under Xvfb on the bare host, with a Python launcher managing restarts and a Puppeteer watchdog detecting crashes. It worked well except for the fundamental problem: any restart — whether from a crash, memory bloat, or the watchdog — destroyed the Directory Handles.

The new approach runs the entire Xvfb+Chrome stack inside a KVM virtual machine. Instead of restarting Chrome when something goes wrong, the VM is reverted to a saved snapshot that was taken when all three Chromes were healthy and had their handles granted. The handles survive because they're part of the VM's frozen memory state, and the filesystem directories they point to are virtiofs mounts from the host — so they're still there when the VM wakes up.

It downloads a Debian cloud image, creates a copy-on-write overlay disk, lets cloud-init install packages, SSHes in, drops the service files, starts everything, and takes snap1 — broken into two steps, it can take an hour on a 12 year old laptop. Watching the qcow2 filesize will tell you it is still going.

The grant ceremony happens once after snap1: you VNC in, grant Directory Handles in all three Chrome windows, enable the watchdog, and take snap3. That's the snapshot everything reverts to from then on.

The host runs two services. virtreset listens on the same Unix socket the watchdog writes to, and also polls VM balloon memory — if Chrome signals distress or the VM hits 90% memory, it does virsh snapshot-revert back to snap3. virt-viewer.sh does remote viewing.

You may need to:
```
echo 'vm.swappiness = 160' | sudo tee /etc/sysctl.d/60-jamsend-host.conf
echo 'vm.watermark_scale_factor = 200' | sudo tee -a /etc/sysctl.d/60-jamsend-host.conf
sudo sysctl --system
```

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