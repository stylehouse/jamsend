> **⌛ RETIRED to `ty/history/` on 2026-10-21** (owner: *"if that's for reloading chromes we could put that in a history
> directory, it was pretty bad"*). These are the first two rungs of running Chrome as an unattended appserver — both kept
> Chromes alive by restarting them, which destroyed their FSA Directory Handles every time. The living path is the
> "simply" rung in `../README.md` (`jamsend-vnc.service`, the real desktop, a human re-grants occasionally). The host's
> service watchdog is now `../jamsend-stack-watchdog.service` (prod vite, Caddy, the daemon — not Chromes).
> ⚠ The units here still name their old paths (`/home/s/src/prod-jamsend/ty/…`); if any is still enabled on a host,
> `systemctl disable --now` it before pulling, or it will fail on the moved files.
> Original text follows.

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

