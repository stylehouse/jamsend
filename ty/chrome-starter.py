# runs inside the VM
# cold-starts all Chrome profiles from CHROME_PROFILES env
# used by jamsend-chromium.service on cold boot; normal operation resumes from snapshot
#
# < no socket listener, no restart loop, no memory monitoring
# those concerns belong to watchdog.js (Chrome health) and virtreset.py (VM health)

import os
import subprocess


PROFILE_BASE = os.environ["PROFILE_BASE"]
PORT_BASE    = int(os.environ.get("CHROME_DEBUG_PORT_BASE", "9222"))
TARGET_URL   = os.environ["TARGET_URL"]
+print(f"Chrome profile base = {PROFILE_BASE}.", flush=True)

# Parse "public,private,tyrant" or "public,private:/stream,tyrant:/admin"
# same logic as launcher.py and watchdog.js
PROFILES = {}
for i, entry in enumerate(os.environ["CHROME_PROFILES"].split(",")):
    name, _, path = entry.strip().partition(':')
    PROFILES[name] = {"port": PORT_BASE + i, "url": TARGET_URL + path}

for name, config in PROFILES.items():
    profile_dir = f"{PROFILE_BASE}/{name}"
    os.makedirs(profile_dir, exist_ok=True)
    print(f"Starting Chrome: {name}  port={config['port']}  url={config['url']}", flush=True)
    subprocess.Popen([
            "chromium",
            f"--remote-debugging-port={config['port']}",
            f"--user-data-dir={profile_dir}",
            "--no-first-run",
            "--autoplay-policy=no-user-gesture-required",
            "--disable-restore-session-state",
            "--disable-infobars",
            config["url"],
        ],
        start_new_session=True,  # Chrome in its own process group; systemd doesn't track children
        stderr=subprocess.PIPE
    )

print("All Chrome profiles started.", flush=True)
