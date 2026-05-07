#!/bin/bash
# install-jamsend-virt.sh
#
# Sets up a KVM/libvirt VM that runs the jamsend Xvfb+Chrome supervisor stack.
# The VM's state can be snapshotted once Chrome has Directory Handles open,
# then restored to that snapshot on any failure — preserving the handles.
#
# xvfb              provides DISPLAY=:10 to:
#  → wm                       window decorations, Alt+drag
#  → x11vnc                   remote viewing (forwarded to host:5910 by socat)
#  → chromium                 three profiles with open Directory Handles
#    → watchdog               signals virtreset.py on the HOST via shared socket
#
# HOST side services installed here:
#   jamsend-virtreset   — socket listener + VM memory watchdog; reverts to snap3
#   jamsend-vnc-forward — socat 127.0.0.1:5910 → VM:5910 (xvfb-viewer.sh unchanged)
#
# Snapshot workflow:
#   snap1  freshly-installed    (services on disk; Chrome starting on first boot)
#   snap2  chromes-open-waiting (Chrome visible, needs Directory Handle grants)
#   snap3  handles-ready        (normal resume point; virtreset reverts here)
#
# Re-running this script after snap3 exists:
#   skips download + overlay creation; redeploys host services only.
#   To rebuild from scratch: delete virtualised-appservers.qcow2 and re-run.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROD_DIR="$(dirname "$SCRIPT_DIR")"   # parent of ty/

VM_NAME="jamsend-appservers"
VM_IP="192.168.122.100"               # static IP on libvirt's default NAT network
VM_USER="jamsend"
VM_MAC="52:54:00:4a:4d:53"           # fixed MAC so cloud-init network-config matches reliably
VM_RAM_MB=4096
VM_CPUS=2
VM_DISK_GB=20

IMAGE_NAME="debian-13-genericcloud-amd64.qcow2"
BACKING_IMAGE="$SCRIPT_DIR/$IMAGE_NAME"
OVERLAY="$SCRIPT_DIR/virtualised-appservers.qcow2"
SEED_ISO="$SCRIPT_DIR/jamsend-seed.iso"
DEBIAN_CLOUD_URL="https://cloud.debian.org/images/cloud/trixie/latest/$IMAGE_NAME"

# gitignore the VM disk images — they're large and non-reproducible
GITIGNORE="$SCRIPT_DIR/.gitignore"
for entry in "$IMAGE_NAME" "virtualised-appservers.qcow2" "jamsend-seed.iso"; do
    grep -qxF "$entry" "$GITIGNORE" 2>/dev/null || echo "$entry" >> "$GITIGNORE"
done

# --- SSH keys ---
# ty/authorized_keys takes precedence over ~/.ssh/authorized_keys
if [ -f "$SCRIPT_DIR/authorized_keys" ]; then
    AUTH_KEYS="$SCRIPT_DIR/authorized_keys"
    echo "SSH keys: ty/authorized_keys"
else
    AUTH_KEYS="$HOME/.ssh/authorized_keys"
    echo "SSH keys: ~/.ssh/authorized_keys"
fi
if [ ! -s "$AUTH_KEYS" ]; then
    echo "Error: no SSH keys found at $AUTH_KEYS"
    exit 1
fi

# =============================================================================
# 1. Host dependencies
# =============================================================================

echo "=== Installing host dependencies ==="
sudo apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    virtiofsd \
    cloud-image-utils \
    socat

if ! groups | grep -q libvirt; then
    sudo usermod -aG libvirt "$USER"
    echo "Added $USER to libvirt group (re-login for passwordless virsh)"
fi

sudo systemctl enable --now libvirtd

# Bring up the default NAT network (virbr0) if it isn't already running
if ! virsh net-info default 2>/dev/null | grep -q "Active:.*yes"; then
    virsh net-autostart default
    virsh net-start default
fi

# =============================================================================
# 2. Backing image
# =============================================================================

if [ -f "$BACKING_IMAGE" ]; then
    echo "=== Backing image already present: $IMAGE_NAME ==="
else
    echo "=== Downloading Debian 13 cloud image ==="
    wget --show-progress -O "$BACKING_IMAGE" "$DEBIAN_CLOUD_URL"
fi

# =============================================================================
# 3. Overlay disk
# =============================================================================

if [ -f "$OVERLAY" ]; then
    echo "=== Overlay already exists — skipping creation ==="
    echo "    Delete it and re-run to start from scratch."
else
    echo "=== Creating ${VM_DISK_GB}G overlay backed by $IMAGE_NAME ==="
    qemu-img create -f qcow2 \
        -b "$BACKING_IMAGE" -F qcow2 \
        "$OVERLAY" "${VM_DISK_GB}G"
fi

# =============================================================================
# 4. Cloud-init seed ISO
# =============================================================================

echo "=== Building cloud-init seed ISO ==="

SEED_DIR=$(mktemp -d)
trap "rm -rf $SEED_DIR" EXIT

# Indent each key for the YAML ssh_authorized_keys list
SSH_KEY_LIST=$(sed 's/^/      - /' "$AUTH_KEYS")

cat > "$SEED_DIR/user-data" <<EOF
#cloud-config
hostname: jamsend-appservers

users:
  - name: $VM_USER
    groups: [sudo, audio, video]
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
$SSH_KEY_LIST

packages:
  - qemu-guest-agent
  - python3-psutil
  - xvfb
  - x11vnc
  - openbox
  - xterm
  - chromium
  - nodejs
  - npm

runcmd:
  - systemctl enable --now qemu-guest-agent
  - systemctl enable --now ssh
  # Chrome profiles live on the VM disk so they're captured in snapshots
  - mkdir -p /home/$VM_USER/.chrome-profiles
  - chown $VM_USER:$VM_USER /home/$VM_USER/.chrome-profiles
  # virtiofs mount points
  - mkdir -p /mnt/jamsend-music /mnt/jamsend-appcache /mnt/jamsend-public
  - mkdir -p /tmp/jamsend-supervisor /opt/jamsend-src
EOF

cat > "$SEED_DIR/meta-data" <<EOF
instance-id: $VM_NAME
local-hostname: jamsend-appservers
EOF

# Static IP matched by MAC address — the VM is always at VM_IP on virbr0
cat > "$SEED_DIR/network-config" <<EOF
version: 2
ethernets:
  mainif:
    match:
      macaddress: "$VM_MAC"
    set-name: eth0
    dhcp4: false
    addresses: [$VM_IP/24]
    routes:
      - to: default
        via: 192.168.122.1
    nameservers:
      addresses: [8.8.8.8, 8.8.4.4]
EOF

# cloud-localds from cloud-image-utils bundles these into a NoCloud seed ISO
cloud-localds -N "$SEED_DIR/network-config" "$SEED_ISO" \
    "$SEED_DIR/user-data" "$SEED_DIR/meta-data"

# =============================================================================
# 5. Define VM
# =============================================================================

if virsh dominfo "$VM_NAME" &>/dev/null; then
    echo "=== VM '$VM_NAME' already defined — skipping define ==="
    echo "    (virsh undefine --nvram $VM_NAME to redefine)"
else
    echo "=== Defining VM ==="

    # virtiofs requires memfd-backed shared memory between host and guest
    virsh define /dev/stdin <<XMLEOF
<domain type='kvm'>
  <name>$VM_NAME</name>
  <memory unit='MiB'>$VM_RAM_MB</memory>
  <vcpu>$VM_CPUS</vcpu>

  <memoryBacking>
    <source type='memfd'/>
    <access mode='shared'/>
  </memoryBacking>

  <os>
    <type arch='x86_64' machine='q35'>hvm</type>
    <boot dev='hd'/>
  </os>

  <features><acpi/><apic/></features>
  <cpu mode='host-passthrough'/>

  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>

    <!-- overlay qcow2 backed by the debian cloud image; snapshots stored here -->
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' discard='unmap'/>
      <source file='$OVERLAY'/>
      <target dev='vda' bus='virtio'/>
    </disk>

    <!-- cloud-init seed; cloud-init won't re-run after first boot (same instance-id) -->
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='$SEED_ISO'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
    </disk>

    <interface type='network'>
      <mac address='$VM_MAC'/>
      <source network='default'/>
      <model type='virtio'/>
    </interface>

    <!-- guest agent: used by virsh domifaddr and clean shutdown -->
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
    </channel>

    <!-- virtiofs: host directories passed through to the VM kernel -->
    <filesystem type='mount' accessmode='passthrough'>
      <driver type='virtiofs'/>
      <source dir='/mnt/jamsend-music'/>
      <target dir='jamsend-music'/>
    </filesystem>
    <filesystem type='mount' accessmode='passthrough'>
      <driver type='virtiofs'/>
      <source dir='/mnt/jamsend-appcache'/>
      <target dir='jamsend-appcache'/>
    </filesystem>
    <filesystem type='mount' accessmode='passthrough'>
      <driver type='virtiofs'/>
      <source dir='/mnt/jamsend-public'/>
      <target dir='jamsend-public'/>
    </filesystem>
    <!-- the socket directory is shared: VM writes RESTART, host virtreset.py reads it -->
    <filesystem type='mount' accessmode='passthrough'>
      <driver type='virtiofs'/>
      <source dir='/tmp/jamsend-supervisor'/>
      <target dir='jamsend-supervisor'/>
    </filesystem>
    <!-- the whole prod-jamsend repo; services, watchdog.js, conf all read from here -->
    <filesystem type='mount' accessmode='passthrough'>
      <driver type='virtiofs'/>
      <source dir='$PROD_DIR'/>
      <target dir='jamsend-src'/>
    </filesystem>

    <!-- no graphical console; VNC is served by x11vnc inside the VM on port 5910 -->
    <graphics type='none'/>
    <video><model type='none'/></video>
    <serial type='pty'><target type='isa-serial' port='0'/></serial>
    <console type='pty'><target type='serial' port='0'/></console>
  </devices>
</domain>
XMLEOF
fi

# =============================================================================
# 6. Start VM, wait for SSH
# =============================================================================

if ! virsh dominfo "$VM_NAME" | grep -q "State:.*running"; then
    echo "=== Starting VM ==="
    virsh start "$VM_NAME"
fi

echo "=== Waiting for SSH at $VM_IP (cloud-init takes ~60–90s on first boot) ==="
SSH_OPTS="-o ConnectTimeout=3 -o StrictHostKeyChecking=no -o BatchMode=yes"
for i in $(seq 1 90); do
    if ssh $SSH_OPTS "$VM_USER@$VM_IP" true 2>/dev/null; then
        echo "SSH up."
        break
    fi
    [ "$i" -eq 90 ] && { echo "Timed out waiting for SSH"; exit 1; }
    printf "  %d/90...\r" "$i"
    sleep 5
done

# =============================================================================
# 7. VM-side setup (runs inside the VM via SSH)
# =============================================================================

echo "=== Setting up VM internals ==="

# HOST_TY_PATH is passed as an env var so the VM-side bash can substitute
# it out of the existing service files (which hardcode the host's ty/ path)
ssh $SSH_OPTS "$VM_USER@$VM_IP" env HOST_TY_PATH="$SCRIPT_DIR" bash <<'VMSETUP'
set -e

echo "Waiting for cloud-init to finish..."
sudo cloud-init status --wait

# --- virtiofs fstab entries ---
# _netdev: wait for virtio devices before mounting (they're not real block devices)
sudo tee -a /etc/fstab <<'FSTAB'
jamsend-music       /mnt/jamsend-music       virtiofs  defaults,_netdev  0 0
jamsend-appcache    /mnt/jamsend-appcache    virtiofs  defaults,_netdev  0 0
jamsend-public      /mnt/jamsend-public      virtiofs  defaults,_netdev  0 0
jamsend-supervisor  /tmp/jamsend-supervisor  virtiofs  defaults,_netdev  0 0
jamsend-src         /opt/jamsend-src         virtiofs  defaults,_netdev  0 0
FSTAB

sudo mount -a
echo "virtiofs mounts active."

# --- npm deps for watchdog ---
cd /opt/jamsend-src/ty && npm install

# --- existing services: substitute the host's ty/ path out; keep everything else ---
for unit in jamsend-xvfb.service jamsend-wm.service jamsend-x11vnc.service; do
    sed \
        -e "s|$HOST_TY_PATH/|/opt/jamsend-src/ty/|g" \
        -e 's|User=1000|User=jamsend|g' \
        "/opt/jamsend-src/ty/$unit" \
        | sudo tee "/etc/systemd/system/$unit" > /dev/null
done

# --- new VM-specific services already reference /opt/jamsend-src/ty/ ---
sudo cp /opt/jamsend-src/ty/jamsend-chromium.service /etc/systemd/system/
sudo cp /opt/jamsend-src/ty/jamsend-watchdog-vm.service \
        /etc/systemd/system/jamsend-watchdog.service
sudo chmod 644 /etc/systemd/system/jamsend-{xvfb,wm,x11vnc,chromium,watchdog}.service

sudo systemctl daemon-reload

sudo systemctl enable jamsend-xvfb.service
sudo systemctl enable jamsend-wm.service
sudo systemctl enable jamsend-x11vnc.service
sudo systemctl enable jamsend-chromium.service
# watchdog is intentionally left disabled here:
# enabling it before snap3 is taken risks a reset loop during the grant ceremony

sudo systemctl start jamsend-xvfb.service
sudo systemctl start jamsend-wm.service
sudo systemctl start jamsend-x11vnc.service
sudo systemctl start jamsend-chromium.service

echo "VM services started. Chrome should be opening now."
VMSETUP

# =============================================================================
# 8. snap1
# =============================================================================

echo "=== Taking snap1: freshly-installed ==="
virsh snapshot-create-as \
    --domain "$VM_NAME" \
    --name snap1 \
    --description "Services installed; Chrome starting on first boot" \
    --memspec snapshot=internal \
    --atomic

# =============================================================================
# 9. Host-side services
# =============================================================================

echo "=== Installing virtreset and VNC forwarder on host ==="

install_rendered_unit() {
    local NAME="$1"
    # substitute __PROD_DIR__ placeholder with the actual path
    sed "s|__PROD_DIR__|$PROD_DIR|g" "$SCRIPT_DIR/$NAME" \
        | sudo tee "/etc/systemd/system/$NAME" > /dev/null
    sudo chown root:root "/etc/systemd/system/$NAME"
    sudo chmod 644 "/etc/systemd/system/$NAME"
    echo "Deployed $NAME"
}

install_rendered_unit "jamsend-virtreset.service"
sudo cp "$SCRIPT_DIR/jamsend-vnc-forward.service" /etc/systemd/system/
sudo chown root:root /etc/systemd/system/jamsend-vnc-forward.service
sudo chmod 644 /etc/systemd/system/jamsend-vnc-forward.service

sudo systemctl daemon-reload
sudo systemctl enable jamsend-virtreset.service
sudo systemctl enable jamsend-vnc-forward.service
sudo systemctl restart jamsend-virtreset.service
sudo systemctl restart jamsend-vnc-forward.service

# =============================================================================
# Done — print the grant ceremony instructions
# =============================================================================

cat <<INSTRUCTIONS

=== snap1 taken. Next: the grant ceremony ===

VNC in to see Chrome opening:
  ty/xvfb-viewer.sh localhost    (or your remote host alias)

Once Chrome windows are visible and asking for permissions, take snap2:
  virsh snapshot-create-as --domain $VM_NAME --name snap2 \\
    --description "Chromes open, awaiting Directory Handle grants" \\
    --memspec snapshot=internal --atomic

Grant Directory Handles and open shares in all three Chrome windows.

Enable the watchdog (it must be running to be in the snapshot), then take snap3:
  ssh $VM_USER@$VM_IP 'sudo systemctl enable --now jamsend-watchdog.service'
  virsh snapshot-create-as --domain $VM_NAME --name snap3 \\
    --description "Handles ready — virtreset resumes from here" \\
    --memspec snapshot=internal --atomic

Verify virtreset is watching:
  systemctl status jamsend-virtreset.service
  journalctl -u jamsend-virtreset.service -f

To update snap3 after a key rotation or config change:
  virsh snapshot-delete --domain $VM_NAME --snapshotname snap3
  (repeat from the grant ceremony above)

INSTRUCTIONS
