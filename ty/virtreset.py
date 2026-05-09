# runs on the host
# listens on the supervisor Unix socket; reverts the VM to snap3 when signalled
# also polls VM balloon memory; reverts before the guest OOMs rather than after
#
# accepts the same "RESTART:<profile>" messages as launcher.py —
# profile name is logged but unused; any Chrome failure = full VM revert
#
# on startup: if the VM isn't running, reverts to snap3 automatically
# handles the host-reboot case without manual intervention

import socket
import os
import subprocess
import select
import time


SOCKET_DIR  = "/tmp/jamsend-supervisor"
SOCKET_PATH = f"{SOCKET_DIR}/chrome_launcher.sock"

VM_NAME      = os.environ.get("VM_NAME",      "jamsend-appservers")
SNAP_READY   = os.environ.get("SNAP_READY",   "snap3")
# fraction of VM RAM at which we revert rather than waiting for an OOM kill
MEMORY_LIMIT = float(os.environ.get("VM_MEMORY_LIMIT", "0.90"))
# seconds between revert attempts — avoids a loop if snap3 itself is degraded
REVERT_COOLDOWN = int(os.environ.get("REVERT_COOLDOWN", "120"))


def virsh(*args):
    return subprocess.run(["virsh", *args], capture_output=True, text=True)


def vm_is_running():
    r = virsh("dominfo", VM_NAME)
    return "running" in r.stdout

def vm_state():
    r = virsh("dominfo", VM_NAME)
    for line in r.stdout.splitlines():
        if line.startswith("State:"):
            return line.split(":", 1)[1].strip()
    return "unknown"

def revert_to_ready(reason):
    state = vm_state()
    if state == "paused":
        print(f"  VM is paused (revert already in progress?) — skipping", flush=True)
        return
    print(f"Reverting {VM_NAME} to {SNAP_READY} ({reason})", flush=True)
    r = virsh("snapshot-revert", "--domain", VM_NAME,
              "--snapshotname", SNAP_READY, "--running")
    if r.returncode != 0:
        print(f"  snapshot-revert failed: {r.stderr.strip()}", flush=True)
    else:
        print(f"  VM resumed from {SNAP_READY}", flush=True)

def check_memory():
    if not vm_is_running():
        return False  # shut-off VM reports maximum/maximum; not a meaningful reading
    r = virsh("domstats", "--balloon", VM_NAME)
    unused = available = maximum = None
    for line in r.stdout.splitlines():
        if "balloon.unused"     in line: unused     = int(line.split("=")[1])
        elif "balloon.available" in line: available  = int(line.split("=")[1])
        elif "balloon.maximum"   in line: maximum    = int(line.split("=")[1])
    if None in (unused, available, maximum) or maximum == 0:
        return False  # < balloon stats not reporting; no memory monitoring
    usage = (available - unused) / maximum
    if usage > MEMORY_LIMIT:
        print(f"VM memory {usage:.0%} > {MEMORY_LIMIT:.0%} — reverting", flush=True)
        return True
    return False


# --- startup: ensure VM is running from the ready snapshot ---

os.makedirs(SOCKET_DIR, exist_ok=True)

if not vm_is_running():
    print(f"{VM_NAME} not running — reverting to {SNAP_READY}", flush=True)
    revert_to_ready("startup / host reboot")
    time.sleep(5)  # brief pause for the VM to begin resuming

if os.path.exists(SOCKET_PATH):
    os.remove(SOCKET_PATH)

server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
server.bind(SOCKET_PATH)
os.chmod(SOCKET_PATH, 0o666)  # VM (virtiofs) writes to this socket
server.listen(1)

print(f"Virtreset listening on {SOCKET_PATH}  vm={VM_NAME}  snap={SNAP_READY}", flush=True)

last_revert = 0.0

while True:
    print("Waiting...", flush=True)
    readable, _, _ = select.select([server], [], [], 30)

    if readable:
        conn, _ = server.accept()
        data = conn.recv(1024).decode().strip()
        conn.close()
        print(f"Received: {data!r}", flush=True)

        if data.startswith("RESTART:"):
            now = time.time()
            remaining = REVERT_COOLDOWN - (now - last_revert)
            if remaining > 0:
                print(f"  cooldown: {remaining:.0f}s remaining — skipping", flush=True)
            else:
                profile = data.split(":", 1)[1]
                last_revert = now
                revert_to_ready(f"watchdog: '{profile}' uncontactable")

    else:
        # Timeout branch — no socket message; check VM memory instead
        if check_memory():
            now = time.time()
            if now - last_revert >= REVERT_COOLDOWN:
                last_revert = now
                revert_to_ready("memory pressure")
