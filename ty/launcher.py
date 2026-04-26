# runs on the host
# listens on a Unix socket and executes Chromium launch commands when triggered
# accepts messages of the form "RESTART:<profile_name>"
# configuration is read from environment variables (see jamsend-launcher.service)

import socket
import os
import subprocess

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

# --- Socket setup ---

def launch_profile(name, config):
    profile_dir = f"{PROFILE_BASE}/{name}"
    print(f"Killing and restarting Chromium for profile: {name}")
    # Kill only the instance using this profile's debug port
    subprocess.run(["pkill", "-f", f"--remote-debugging-port={config['port']}"])
    subprocess.Popen([
        "chromium",
        f"--remote-debugging-port={config['port']}",
        f"--user-data-dir={profile_dir}",
        "--no-first-run",
        config["url"],
    ])

os.makedirs(SOCKET_DIR, exist_ok=True)
if os.path.exists(SOCKET_PATH):
    os.remove(SOCKET_PATH)

server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
server.bind(SOCKET_PATH)
os.chmod(SOCKET_PATH, 0o666)  # Ensure Docker can write to it
server.listen(1)

print(f"Launcher listening on {SOCKET_PATH}...")

# Launch all profiles immediately on startup
for name, config in PROFILES.items():
    launch_profile(name, config)

while True:
    conn, _ = server.accept()
    data = conn.recv(1024).decode().strip()
    if data.startswith("RESTART:"):
        name = data.split(":", 1)[1]
        if name in PROFILES:
            launch_profile(name, PROFILES[name])
        else:
            print(f"Unknown profile: {name}")
    conn.close()
