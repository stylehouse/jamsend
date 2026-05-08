#!/bin/bash
# install-jamsend-virt-step2.sh
#
# Part 2 of the virt install — runs in seconds, safe to re-run.
# Assumes snap0 exists (base system up, virtiofs mounted).
# Reverts to snap0 before each run so service state is always clean.
#
# What it does:
#   - reverts VM to snap0
#   - SSHes in, copies + wires service files from the virtiofs repo mount
#   - takes snap1: services running, Chrome starting
#   - installs/restarts host-side services (virtreset, vnc-forward)
#   - prints grant ceremony instructions

set -e
export LIBVIRT_DEFAULT_URI=qemu:///system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROD_DIR="$(dirname "$SCRIPT_DIR")"

VM_NAME="jamsend-appservers"
VM_IP="192.168.122.100"
VM_USER="jamsend"
SSH_OPTS="-o ConnectTimeout=3 -o StrictHostKeyChecking=no -o BatchMode=yes"

if ! virsh dominfo "$VM_NAME" &>/dev/null; then
    echo "Error: VM '$VM_NAME' not defined. Run install-jamsend-virt.sh first."
    exit 1
fi

if ! virsh snapshot-info --domain "$VM_NAME" --snapshotname snap0 &>/dev/null; then
    echo "Error: snap0 not found. Run install-jamsend-virt.sh first."
    exit 1
fi

# =============================================================================
# 1. Revert to snap0 — clean slate every run
# =============================================================================

echo "=== Reverting to snap0 ==="
virsh snapshot-revert --domain "$VM_NAME" --snapshotname snap0 --running

# snap0 was taken with the VM running; give it a moment to be reachable
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$VM_IP" 2>/dev/null || true
echo "=== Waiting for SSH ==="
while ! ssh $SSH_OPTS "$VM_USER@$VM_IP" true 2>/dev/null; do
    printf "  waiting...\r"; sleep 3
done
echo "SSH up."

# =============================================================================
# 2. Install service files
#
# shared services (xvfb, wm, x11vnc) have User=1000 and the host's ty/ path
# baked in — sed fixes both on the way to /etc/systemd/system/.
# virt-specific services already reference /opt/jamsend-src/ty/ and User=jamsend.
# =============================================================================

echo "=== Installing service files ==="
ssh $SSH_OPTS "$VM_USER@$VM_IP" "VM_USER=$VM_USER bash" <<'SVCSETUP'
set -e
TY=/opt/jamsend-src/ty

sed -e "s|User=1000|User=$VM_USER|" \
    $TY/jamsend-xvfb.service \
    | sudo tee /etc/systemd/system/jamsend-xvfb.service > /dev/null

sed -e "s|User=1000|User=$VM_USER|" \
    -e "s|--config-file .*|--config-file $TY/openbox-rc.xml|" \
    $TY/jamsend-wm.service \
    | sudo tee /etc/systemd/system/jamsend-wm.service > /dev/null

sed -e "s|User=1000|User=$VM_USER|" \
    $TY/jamsend-x11vnc.service \
    | sudo tee /etc/systemd/system/jamsend-x11vnc.service > /dev/null

sudo cp $TY/jamsend-virt-chromium.service /etc/systemd/system/
sudo cp $TY/jamsend-virt-watchdog.service /etc/systemd/system/

sudo systemctl daemon-reload

sudo systemctl enable jamsend-xvfb.service jamsend-wm.service \
    jamsend-x11vnc.service jamsend-virt-chromium.service
# watchdog intentionally left disabled: enabling it before snap3 risks a reset loop
# during the Directory Handle grant ceremony

sudo systemctl start jamsend-xvfb.service jamsend-wm.service \
    jamsend-x11vnc.service jamsend-virt-chromium.service

echo "Services started."
SVCSETUP

# =============================================================================
# 3. snap1: services running, Chrome starting
# =============================================================================

# delete snap1 if it exists from a previous step2 run
if virsh snapshot-info --domain "$VM_NAME" --snapshotname snap1 &>/dev/null; then
    echo "=== Removing previous snap1 ==="
    virsh snapshot-delete --domain "$VM_NAME" --snapshotname snap1
fi

echo "=== Taking snap1: services-running ==="
virsh snapshot-create-as \
    --domain "$VM_NAME" \
    --name snap1 \
    --description "services enabled; Chrome starting; pre-grant-ceremony" \
    --memspec snapshot=internal \
    --atomic

# =============================================================================
# 4. Host-side services
# =============================================================================

echo "=== Installing host-side services ==="

install_rendered_unit() {
    local NAME="$1"
    # substitute __PROD_DIR__ placeholder with the actual path
    sed "s|__PROD_DIR__|$PROD_DIR|g" "$SCRIPT_DIR/$NAME" \
        | sudo tee "/etc/systemd/system/$NAME" > /dev/null
    sudo chown root:root "/etc/systemd/system/$NAME"
    sudo chmod 644 "/etc/systemd/system/$NAME"
    echo "  Deployed $NAME"
}

install_rendered_unit "jamsend-virtreset.service"

sudo cp "$SCRIPT_DIR/jamsend-virt-vnc-forward.service" /etc/systemd/system/
sudo chown root:root /etc/systemd/system/jamsend-virt-vnc-forward.service
sudo chmod 644 /etc/systemd/system/jamsend-virt-vnc-forward.service

sudo systemctl daemon-reload
sudo systemctl enable jamsend-virtreset.service jamsend-virt-vnc-forward.service
sudo systemctl restart jamsend-virtreset.service jamsend-virt-vnc-forward.service

# =============================================================================
# Done
# =============================================================================

cat <<INSTRUCTIONS

=== snap1 taken. Next: the grant ceremony ===

VNC in to see Chrome:
  ty/xvfb-viewer.sh localhost

Or open virt-manager (ssh -X to this host, then: virt-manager --connect qemu:///system).

Once all three Chrome windows are visible and awaiting permission grants, take snap2:
  virsh snapshot-create-as --domain $VM_NAME --name snap2 \\
    --description "Chromes open, awaiting Directory Handle grants" \\
    --memspec snapshot=internal --atomic

Grant Directory Handles and open shares in all three Chrome windows.

Enable the watchdog (must be running before snap3), then take snap3:
  ssh $VM_USER@$VM_IP 'sudo systemctl enable --now jamsend-virt-watchdog.service'
  virsh snapshot-create-as --domain $VM_NAME --name snap3 \\
    --description "Handles ready — virtreset resumes from here" \\
    --memspec snapshot=internal --atomic

To redo services without rebuilding the VM (e.g. after a service file change):
  ty/install-jamsend-virt-step2.sh

To update snap3 after a key rotation or config change:
  virsh snapshot-delete --domain $VM_NAME --snapshotname snap3
  (repeat grant ceremony above)

INSTRUCTIONS
