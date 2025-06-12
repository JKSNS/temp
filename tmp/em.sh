Below is a single, self-contained Bash script that interactively asks for everything it needs—firmware path, architecture, QEMU settings, etc.—then:
	1.	Extracts the firmware
	2.	Unpacks the rootfs
	3.	Builds an ext4 disk image
	4.	Boots it under QEMU with HTTP port-forwarding so you can hit the real router UI at http://localhost:<YOUR_PORT>

Save this as e.g. router_emulate.sh, chmod +x router_emulate.sh, and run it on Ubuntu 24.

#!/usr/bin/env bash
set -euo pipefail

### router_emulate.sh
### Prereqs: sudo apt install binwalk squashfs-tools qemu-utils qemu-system-<arch>
### Usage: ./router_emulate.sh

# 1) Ask for firmware blob
read -e -p "Path to firmware (.bin/.img): " FW
[ -f "$FW" ] || { echo "❌ Firmware not found: $FW"; exit 1; }
NAME=$(basename "$FW" | sed 's/\.[^.]*$//')
WORKDIR="work/$NAME"
IMAGEDIR="images/$NAME"

# 2) Ask for architecture
echo "Select architecture:"
PS3="> "
ARCH_OPTS=( mipsel arm x86_64 )
select ARCH in "${ARCH_OPTS[@]}"; do
  [[ " ${ARCH_OPTS[*]} " == *" $ARCH "* ]] && break
  echo "❌ Invalid choice"
done

# 3) Ask for QEMU machine
read -p "QEMU machine type (e.g. malta, versatilepb, pc): " MACHINE
[ -n "$MACHINE" ] || { echo "❌ Machine type required"; exit 1; }

# 4) Optional: vendor kernel & DTB
read -e -p "Path to kernel image (zImage/vmlinux) [leave blank to skip]: " KERNEL
[[ -z "$KERNEL" || -f "$KERNEL" ]] || { echo "❌ Kernel not found"; exit 1; }
read -e -p "Path to DTB file (optional): " DTB
[[ -z "$DTB" || -f "$DTB" ]] || { echo "❌ DTB not found"; exit 1; }

# 5) Disk size & HTTP port
read -p "Rootfs image size in MB [512]: " SIZE; SIZE=${SIZE:-512}
read -p "Host port to forward guest HTTP → [8080]: " HPORT; HPORT=${HPORT:-8080}

# 6) Prepare directories
mkdir -p "$WORKDIR" "$IMAGEDIR"

# 7) Extract firmware
echo "🔍 Extracting firmware..."
binwalk -e --directory "$WORKDIR" "$FW"

# 8) Locate & unpack rootfs
FS_IMG=$(find "$WORKDIR" -type f \( -name '*.squashfs' -o -name '*.jffs2' -o -name '*.cramfs' \) | head -n1)
[ -n "$FS_IMG" ] || { echo "❌ No rootfs image found"; exit 1; }

echo "📦 Unpacking $FS_IMG..."
rm -rf "$WORKDIR/rootfs"
mkdir -p "$WORKDIR/rootfs"
sudo unsquashfs -d "$WORKDIR/rootfs" "$FS_IMG"

# 9) Build ext4 container
ROOTFS_IMG="$IMAGEDIR/$NAME-rootfs.ext4"
echo "🖴 Creating ext4 (${SIZE}MB)..."
dd if=/dev/zero of="$ROOTFS_IMG" bs=1M count="$SIZE" status=none
mkfs.ext4 -F "$ROOTFS_IMG" >/dev/null

echo "📋 Copying rootfs → $ROOTFS_IMG..."
sudo mount -o loop "$ROOTFS_IMG" /mnt
sudo cp -a "$WORKDIR/rootfs/." /mnt
sudo umount /mnt

# 10) Launch QEMU
echo "🚀 Launching QEMU..."
CMD=( qemu-system-$ARCH -M "$MACHINE" -m 256M )

[[ -n "$KERNEL" ]] && CMD+=( -kernel "$KERNEL" )
[[ -n "$DTB"    ]] && CMD+=( -dtb    "$DTB"    )

CMD+=( 
  -drive file="$ROOTFS_IMG",format=raw,if=virtio 
  -append "root=/dev/vda rw console=ttyS0" 
  -nographic 
  -netdev user,id=net0,hostfwd=tcp::${HPORT}-:80 
  -device virtio-net-device,netdev=net0
)

echo "${CMD[*]}"
"${CMD[@]}"

How it works
	1.	Prompts you for:
	•	Path to your .bin/.img
	•	CPU arch (MIPS, ARM, x86_64)
	•	QEMU machine type (e.g. malta, versatilepb, pc)
	•	(Optional) vendor zImage/vmlinux & .dtb
	•	Size for the ext4 disk (default 512 MB)
	•	Host port to forward the guest’s port 80 (default 8080)
	2.	Extracts with binwalk → finds the squashfs/jffs2/cramfs rootfs → unsquashfs into a temp dir.
	3.	Creates a raw ext4 file, mounts it, and copies the unpacked rootfs in.
	4.	Invokes qemu-system-<arch> in system-mode:
	•	Attaches the ext4 as a virtio disk
	•	Boots the provided kernel (or your own)
	•	Forwards guest HTTP 80 → host $HPORT so you can browse the real router UI at

http://localhost:<HPORT>



⸻

Next Steps
	•	If you’d like Docker support, you can wrap this script (and its prerequisites) in a Dockerfile that mounts in your firmware list and exposes port 8080.
	•	For automation of multiple firmwares, call this script in a loop or integrate it into a CI pipeline.
	•	To build networked topologies, point each instance at different host ports or use -netdev tap with a custom bridge.

With this one script in place, you just answer a few questions and immediately get a fully-booted, interactive router VM on Ubuntu 24.