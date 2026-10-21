# runs on the host
# listens on a Unix socket and executes Chromium launch commands when triggered
# accepts messages of the form "RESTART:<profile_name>"
# configuration is read from environment variables (see jamsend-launcher.service)

import socket
import os
import subprocess
import select
import psutil
import signal


SOCKET_DIR  = "/tmp/jamsend-supervisor"
SOCKET_PATH = f"{SOCKET_DIR}/chrome_launcher.sock"

# --- Config from environment (injected via Environment= in systemd unit) ---
TARGET_URL   = os.environ["TARGET_URL"]
PROFILE_BASE = os.environ["PROFILE_BASE"]
PORT_BASE    = int(os.environ.get("CHROME_DEBUG_PORT_BASE", "9222"))

# Parse "public,private,tyrant" or "public,private:/stream,tyrant:/admin"
# → dict of {name: {port, url}}; colon+path suffix is optional
PROFILES = {}
for i, entry in enumerate(os.environ["CHROME_PROFILES"].split(",")):
    name, _, path = entry.strip().partition(':')  # colon+path optional, e.g. 'private:/stream'
    PROFILES[name] = {"port": PORT_BASE + i, "url": TARGET_URL + path}

print("Configured profiles:")
for name, cfg in PROFILES.items():
    print(f"  {name}: port={cfg['port']}  url={cfg['url']}")


# per chrome
MEMORY_LIMIT_GB = 3.14159
def check_memory():
    for name, proc in list(processes.items()):
        if proc.poll() is not None:
            continue  # already dead
        try:
            p = psutil.Process(proc.pid)
            # Sum parent + all renderer/GPU/extension subprocesses
            children = p.children(recursive=True)
            total_rss = p.memory_info().rss
            for child in children:
                try:
                    total_rss += child.memory_info().rss
                except psutil.NoSuchProcess:
                    pass  # child exited between listing and measuring — skip it
            mem_gb = total_rss / 1e9
            if mem_gb > MEMORY_LIMIT_GB:
                print(f"Chrome '{name}' using {mem_gb:.1f}GB — restarting", flush=True)
                launch_profile(name, PROFILES[name])
        except psutil.NoSuchProcess:
            pass


# --- Socket setup ---

processes = {}  # track live Popen objects by profile name

def launch_profile(name, config):
    profile_dir = f"{PROFILE_BASE}/{name}"
    print(f"Killing and restarting Chromium for profile: {name}")

    # Kill the entire process group — SIGTERM to the coordinator alone leaves
    # renderer subprocesses (including Oh Snap tabs) alive and hanging
    if name in processes:
        proc = processes[name]
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            proc.wait(timeout=5)  # ensure it's actually gone before relaunching
        except ProcessLookupError:
            pass  # already dead
        except subprocess.TimeoutExpired:
            print(f"Profile '{name}' didn't exit cleanly, sending SIGKILL...")
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            proc.wait()  # reap the zombie after SIGKILL (no timeout — SIGKILL is not ignorable)

    processes[name] = subprocess.Popen([
            "chromium",
            f"--remote-debugging-port={config['port']}",
            f"--user-data-dir={profile_dir}",
            "--no-first-run",
            "--autoplay-policy=no-user-gesture-required",  # suppress "tap to unmute"
            "--disable-restore-session-state",              # suppress "Restore pages?" after our SIGTERM/SIGKILL
            "--disable-infobars",                           # suppress other notification bars
            config["url"],
        ],
        start_new_session=True,  # puts Chrome in its own process group so killpg works
        stderr=subprocess.PIPE   # capture crash reason
    )
    # give it a moment then check if it already died
    import time; time.sleep(1)
    if processes[name].poll() is not None:
        print(f"Chrome for '{name}' died immediately: {processes[name].stderr.read().decode()}", flush=True)

os.makedirs(SOCKET_DIR, exist_ok=True)
if os.path.exists(SOCKET_PATH):
    os.remove(SOCKET_PATH)

server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
server.bind(SOCKET_PATH)
os.chmod(SOCKET_PATH, 0o666)  # Ensure Docker can write to it
server.listen(1)

print(f"Launcher listening on {SOCKET_PATH}...")

while True:
    print("Waiting...", flush=True)  # confirm the loop is alive
    readable, _, _ = select.select([server], [], [], 30)  # 30s timeout
    if readable:
        conn, _ = server.accept()
        data = conn.recv(1024).decode().strip()
        print(f"Received: {data!r}", flush=True)
        if data.startswith("RESTART:"):
            name = data.split(":", 1)[1]
            if name in PROFILES:
                launch_profile(name, PROFILES[name])
            else:
                print(f"Unknown profile: {name}", flush=True)
        conn.close()
    else:
        # Timeout branch — no socket message, do housekeeping
        check_memory()






