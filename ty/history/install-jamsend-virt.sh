#!/bin/bash
# install-jamsend-virt.sh
#
# Sets up a KVM/libvirt VM that runs the jamsend Xvfb+Chrome supervisor stack.
# The VM's state can be snapshotted once Chrome has Directory Handles open,
# then restored to that snapshot on any failure — preserving the handles.
#
# xvfb              provides DISPLAY=:10 to:
#  → wm                       window decorations, Alt+drag
#  → x11vnc                   remote viewing (see virt-viewer.sh)
#  → chromium                 three profiles with open Directory Handles
#    → watchdog               signals virtreset.py on the HOST via shared socket
#
# HOST side services installed here:
#   jamsend-virtreset   — socket listener + VM memory watchdog; reverts to snap3
#
# Snapshot workflow:
#   snap1  freshly-installed    (cloud-init done; Chrome starting)
#   snap2  chromes-open-waiting (Chrome visible, needs Directory Handle grants)
#   snap3  handles-ready        (normal resume point; virtreset reverts here)
#
# Re-running this script tears everything down and rebuilds from scratch.
# The backing cloud image is kept and re-used (no re-download).
#
# All VM-side setup runs inside cloud-init (write_files + runcmd).
# The script just waits for cloud-init to finish, then takes snap1.
# This avoids any race between the SSH poller and package installation.

set -e
# virsh defaults to qemu:///session for non-root users; we always want the system daemon
export LIBVIRT_DEFAULT_URI=qemu:///system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROD_DIR="$(dirname "$SCRIPT_DIR")"   # parent of ty/

VM_NAME="jamsend-appservers"
VM_IP="192.168.122.100"               # static IP on libvirt's default NAT network
VM_USER="jamsend"
VM_MAC="52:54:00:4a:4d:53"           # fixed MAC so cloud-init network-config matches reliably
VM_RAM_MB=8192
VM_CPUS=2
VM_DISK_GB=20

IMAGE_NAME="debian-13-genericcloud-amd64.qcow2"
BACKING_IMAGE="$SCRIPT_DIR/$IMAGE_NAME"
OVERLAY="$SCRIPT_DIR/jamsend-virt-appservers.qcow2"
SEED_ISO="$SCRIPT_DIR/jamsend-virt-appservers-seed.iso"
DEBIAN_CLOUD_URL="https://cloud.debian.org/images/cloud/trixie/latest/$IMAGE_NAME"

# gitignore the large/non-reproducible files in ty/
GITIGNORE="$SCRIPT_DIR/.gitignore"
for entry in "$IMAGE_NAME" "jamsend-virt-appservers.qcow2" "jamsend-virt-appservers-seed.iso"; do
    grep -qxF "$entry" "$GITIGNORE" 2>/dev/null || echo "$entry" >> "$GITIGNORE"
done

# =============================================================================
# Preflight checks
# =============================================================================

PREFLIGHT_OK=1

if [ ! -e /dev/kvm ]; then
    echo "ERROR: /dev/kvm not found."
    echo "       Enable Intel VT-x / AMD-V in BIOS, then: sudo modprobe kvm-intel (or kvm-amd)"
    PREFLIGHT_OK=0
elif [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then
    echo "ERROR: /dev/kvm not accessible to $USER."
    echo "       sudo usermod -aG kvm $USER  then re-login"
    PREFLIGHT_OK=0
fi

if ! command -v virtiofsd &>/dev/null && [ ! -x /usr/lib/qemu/virtiofsd ]; then
    echo "ERROR: virtiofsd not found.  sudo apt install virtiofsd"
    PREFLIGHT_OK=0
fi

for dir in /mnt/jamsend-music /mnt/jamsend-appcache /mnt/jamsend-public /tmp/jamsend-supervisor; do
    if [ ! -d "$dir" ]; then
        echo "ERROR: host directory $dir does not exist."
        echo "       Run install-jamsend-mount-verify.sh first, or:"
        echo "         sudo mkdir -p $dir && sudo chown $USER:$USER $dir"
        PREFLIGHT_OK=0
    fi
done

[ "$PREFLIGHT_OK" -eq 0 ] && exit 1

# =============================================================================
# 0. Teardown any previous install
# =============================================================================

echo "=== Tearing down previous install (if any) ==="

if virsh dominfo "$VM_NAME" &>/dev/null; then
    if virsh dominfo "$VM_NAME" | grep -q "State:.*running"; then
        echo "  Destroying running VM..."
        virsh destroy "$VM_NAME"
    fi
    # undefine removes the domain and all its snapshot metadata in one shot
    echo "  Undefining domain + snapshots..."
    virsh undefine --snapshots-metadata "$VM_NAME"
fi

[ -f "$OVERLAY"  ] && { echo "  Removing overlay...";  rm -f "$OVERLAY";  }
[ -f "$SEED_ISO" ] && { echo "  Removing seed ISO..."; rm -f "$SEED_ISO"; }

echo "  Done."

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
    acl \
    zram-tools

if ! groups | grep -q libvirt; then
    sudo usermod -aG libvirt "$USER"
    echo "Added $USER to libvirt group (re-login for passwordless virsh)"
fi

sudo systemctl enable --now libvirtd zramswap

if ! virsh net-info default &>/dev/null; then
    echo "Creating default NAT network..."
    virsh net-define /dev/stdin <<'NETXML'
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
NETXML
fi
if ! virsh net-info default | grep -q "Active:.*yes"; then
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
# 3. Overlay disk + ACLs
# =============================================================================

echo "=== Creating ${VM_DISK_GB}G overlay backed by $IMAGE_NAME ==="
qemu-img create -f qcow2 \
    -b "$BACKING_IMAGE" -F qcow2 \
    "$OVERLAY" "${VM_DISK_GB}G"

# libvirt-qemu runs QEMU unprivileged and can't traverse home dirs by default;
# grant execute on every directory in the path to ty/, read on the disk images
echo "=== Granting libvirt-qemu access to disk images ==="
_DIR="$SCRIPT_DIR"
while [[ "$_DIR" != "/" ]]; do
    sudo setfacl -m u:libvirt-qemu:x "$_DIR"
    _DIR="$(dirname "$_DIR")"
done
sudo setfacl -m u:libvirt-qemu:r "$OVERLAY"
sudo setfacl -m u:libvirt-qemu:r "$BACKING_IMAGE"

# =============================================================================
# 4. Cloud-init seed ISO
#
# runcmd mounts the virtiofs shares first, then reads service files straight
# from the live repo mount — no files are inlined into user-data.
# By the time cloud-init reports 'done', the VM is fully configured.
# =============================================================================

echo "=== Building cloud-init seed ISO ==="

SEED_DIR=$(mktemp -d)
trap "rm -rf $SEED_DIR" EXIT

if [ -f "$SCRIPT_DIR/authorized_keys" ]; then
    AUTH_KEYS="$SCRIPT_DIR/authorized_keys"
    echo "SSH keys: ty/authorized_keys"
else
    AUTH_KEYS="$HOME/.ssh/authorized_keys"
    echo "SSH keys: ~/.ssh/authorized_keys"
fi
if [ ! -s "$AUTH_KEYS" ]; then
    echo "Error: no SSH keys found at $AUTH_KEYS"; exit 1
fi

SSH_KEY_LIST=$(sed 's/^/      - /' "$AUTH_KEYS")

# Service file content is written directly into user-data.
# Paths are the VM-side paths (/opt/jamsend-src/ty/); the host path ($SCRIPT_DIR)
# is irrelevant inside the VM — virtiofs maps $PROD_DIR to /opt/jamsend-src.
# PROFILE_BASE is overridden inline so Chrome profiles land on the VM disk
# (captured in snapshots) rather than on the host.

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
  - net-tools
  - vim
  - zram-tools

# cloud-init only gets the VM to a usable base: packages installed, virtiofs
# mounted, npm deps ready. Service setup runs in install-jamsend-virt-step2.sh
# so it can be re-run in seconds without rebuilding the whole VM.

runcmd:
  - systemctl enable --now qemu-guest-agent
  - systemctl enable --now ssh
  - mkdir -p /mnt/jamsend-music /mnt/jamsend-appcache /mnt/jamsend-public
  - mkdir -p /tmp/jamsend-supervisor /opt/jamsend-src
  - mkdir -p /home/$VM_USER/.chrome-profiles
  - |
    printf '%s\n' \
      'jamsend-music      /mnt/jamsend-music      virtiofs  defaults,_netdev  0 0' \
      'jamsend-appcache   /mnt/jamsend-appcache   virtiofs  defaults,_netdev  0 0' \
      'jamsend-public     /mnt/jamsend-public     virtiofs  defaults,_netdev  0 0' \
      'jamsend-supervisor /tmp/jamsend-supervisor virtiofs  defaults,_netdev  0 0' \
      'jamsend-src        /opt/jamsend-src        virtiofs  defaults,_netdev  0 0' \
      >> /etc/fstab
  - mount -a
  - npm install --prefix /opt/jamsend-src/ty
  - chown -R $VM_USER:$VM_USER /home/$VM_USER/.chrome-profiles
  - systemctl enable --now zramswap
EOF

cat > "$SEED_DIR/meta-data" <<EOF
instance-id: $VM_NAME
local-hostname: jamsend-appservers
EOF

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

cloud-localds -N "$SEED_DIR/network-config" "$SEED_ISO" \
    "$SEED_DIR/user-data" "$SEED_DIR/meta-data"

# =============================================================================
# 5. Define VM
# =============================================================================

echo "=== Defining VM ==="

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

    <!-- SPICE console: lets virt-manager show the desktop over ssh -X -->
    <!-- bound to localhost only; access via ssh -X then virt-manager on the client -->
    <graphics type='spice' autoport='yes' listen='127.0.0.1'>
      <listen type='address' address='127.0.0.1'/>
    </graphics>
    <video>
      <model type='virtio'/>
    </video>

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

    <!-- serial console: virsh console jamsend-appservers (Ctrl+] to exit) -->
    <serial type='pty'><target type='isa-serial' port='0'/></serial>
    <console type='pty'><target type='serial' port='0'/></console>
  </devices>
</domain>
XMLEOF

# =============================================================================
# 6. Start VM, wait for cloud-init to finish
#
# SSH comes up well before cloud-init finishes installing packages.
# We wait for SSH first (quick), then cloud-init status (however long it takes).
# No hard timeout: this machine may be slow.
# Watch progress with: virsh console jamsend-appservers  (Ctrl+] to exit)
# =============================================================================

echo "=== Starting VM ==="
virsh start "$VM_NAME"

# Clear any stale host key from a previous install — we know this IP is ours
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$VM_IP" 2>/dev/null || true

echo "=== Waiting for SSH at $VM_IP ==="
echo "    (watch boot: virsh console $VM_NAME  —  Ctrl+] to exit)"
SSH_OPTS="-o ConnectTimeout=3 -o StrictHostKeyChecking=no -o BatchMode=yes"
i=0
while ! ssh $SSH_OPTS "$VM_USER@$VM_IP" true 2>/dev/null; do
    i=$(( i + 1 ))
    printf "  %d min elapsed...\r" "$(( i * 5 / 60 ))"
    sleep 5
done
echo "SSH up after $(( i * 5 ))s."

echo "=== Waiting for cloud-init to finish (package install takes ~15 min on slow hardware) ==="
ssh $SSH_OPTS "$VM_USER@$VM_IP" 'sudo cloud-init status --wait --long'

# =============================================================================
# 7. snap0: base system
# =============================================================================

echo "=== Taking snap0: base-system ==="
virsh snapshot-create-as \
    --domain "$VM_NAME" \
    --name snap0 \
    --description "packages installed, virtiofs mounted, npm ready; no services yet" \
    --memspec snapshot=internal \
    --atomic

echo "=== snap0 done. Running step 2... ==="
exec "$SCRIPT_DIR/install-jamsend-virt-step2.sh"
