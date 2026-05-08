# caveat

hardcoded /home/s/ in various places

# for running server instances

install-jamsend-prod.sh shall install a service, depends on leproxy, see also ../prod.sh

# for running chrome appservers

We seem to expose a lot of instability in chrome or something doing this... Chrome runs best on the host desktop environment, but once they go Oh Snap how do you restart them? And they lose their handles, see below.

## badly

install-jamsend-supervisor.sh installs a dockerised bunch of chromes that restart, but they keep losing handles, see below.

## maybe well

Jamsend runs three Chromium instances as application servers. They use the browser's File System Access API to hold Directory Handles — persistent references to directories on disk that the web app uses for storage. The handles are granted interactively by a human clicking "Allow" in the browser, and they live in the browser's memory. If Chrome is killed and restarted, the handles are gone and someone has to grant them again.

The old approach ran Chrome under Xvfb on the bare host, with a Python launcher managing restarts and a Puppeteer watchdog detecting crashes. It worked well except for the fundamental problem: any restart — whether from a crash, memory bloat, or the watchdog — destroyed the Directory Handles.

The new approach runs the entire Xvfb+Chrome stack inside a KVM virtual machine. Instead of restarting Chrome when something goes wrong, the VM is reverted to a saved snapshot that was taken when all three Chromes were healthy and had their handles granted. The handles survive because they're part of the VM's frozen memory state, and the filesystem directories they point to are virtiofs mounts from the host — so they're still there when the VM wakes up.

The install has two stages. The slow part downloads a Debian cloud image, creates a copy-on-write overlay disk, and lets cloud-init install packages — this takes ~30 minutes on the hardware and produces snap0. The fast part SSHes in, drops the service files, starts everything, and takes snap1 — this takes seconds and is re-runnable whenever a service needs fixing.

The grant ceremony happens once after snap1: you VNC in, grant Directory Handles in all three Chrome windows, enable the watchdog, and take snap3. That's the snapshot everything reverts to from then on.

The host runs two services. virtreset listens on the same Unix socket the watchdog writes to, and also polls VM balloon memory — if Chrome signals distress or the VM hits 90% memory, it does virsh snapshot-revert back to snap3. jamsend-virt-vnc-forward socat-forwards port 5910 so the existing xvfb-viewer.sh still works without knowing there's a VM involved.
