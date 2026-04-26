# runs on the host
# listens on a Unix socket and executes the Chromium launch command when triggered

import socket
import os
import subprocess

SOCKET_PATH = "/tmp/chrome_launcher.sock"

if os.path.exists(SOCKET_PATH):
    os.remove(SOCKET_PATH)

server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
server.bind(SOCKET_PATH)
os.chmod(SOCKET_PATH, 0o666) # Ensure Docker can write to it
server.listen(1)

print("Launcher listening on /tmp/chrome_launcher.sock...")

while True:
    conn, _ = server.accept()
    data = conn.recv(1024)
    if data == b"RESTART":
        print("Restart signal received. Killing and starting Chromium...")
        subprocess.run(["pkill", "-f", "chromium"])
        # Launch Chromium (adjust flags as needed for your Linux setup)
        subprocess.Popen([
            "chromium", 
            "--remote-debugging-port=9222", 
            "--user-data-dir=/tmp/chrome-profile",
            "--no-first-run",
            "https://your-webapp.com"
        ])
    conn.close()