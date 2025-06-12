Below is a ready-to-build Docker setup that gives you the same interactive “just answer a few questions and spin up a router VM” experience—inside a container on Ubuntu 24.04.

⸻

1) docker/Dockerfile

# Use Ubuntu 24.04 as our base
FROM ubuntu:24.04

# Install all the prereqs for firmware extraction and QEMU-system emulation
RUN apt-get update && apt-get install -y --no-install-recommends \
    binwalk \
    squashfs-tools \
    mtd-utils \
    qemu-utils \
    qemu-system-mips \
    qemu-system-arm \
    qemu-system-x86 \
    sudo \
 && rm -rf /var/lib/apt/lists/*

# Copy in our interactive emulation script
COPY router_emulate.sh /usr/local/bin/router_emulate.sh
RUN chmod +x /usr/local/bin/router_emulate.sh

ENTRYPOINT ["/usr/local/bin/router_emulate.sh"]


⸻

2) docker/router_emulate.sh

#!/usr/bin/env bash
set -euo pipefail

#
# Interactive router emulation inside Docker.
# Expects these bind-mounts from the host:
#   /firmwares → your vendor .bin/.img files
#   /work      → for temporary extraction (persist if you like)
#   /images    → for final ext4 images & kernels
#

# 1) Firmware blob
read -e -p "Path to firmware (e.g. /firmwares/ACME123.bin): " FW
[ -f "$FW" ] || { echo "❌ Firmware not found: $FW"; exit 1; }
NAME=$(basename "$FW" | sed 's/\.[^.]*$//')

# 2) CPU architecture
echo "Select architecture:"
PS3="> "
ARCH_OPTS=( mipsel arm x86_64 )
select ARCH in "${ARCH_OPTS[@]}"; do
  [[ " ${ARCH_OPTS[*]} " == *" $ARCH "* ]] && break
  echo "❌ Invalid choice"
done

# 3) QEMU machine type
read -p "QEMU machine (e.g. malta, versatilepb, pc): " MACHINE
[ -n "$MACHINE" ] || { echo "❌ Machine required"; exit 1; }

# 4) Optional kernel & DTB
read -e -p "Path to kernel (zImage/vmlinux) [leave blank to skip]: " KERNEL
[[ -z "$KERNEL" || -f "$KERNEL" ]] || { echo "❌ Kernel not found"; exit 1; }
read -e -p "Path to DTB (optional): " DTB
[[ -z "$DTB" || -f "$DTB" ]] || { echo "❌ DTB not found"; exit 1; }

# 5) Disk size & HTTP port
read -p "Rootfs size in MB [512]: " SIZE; SIZE=${SIZE:-512}
read -p "Host port for HTTP → guest 80 [8080]: " HPORT; HPORT=${HPORT:-8080}

# 6) Setup dirs
WORKDIR=/work/"$NAME"
IMAGEDIR=/images/"$NAME"
mkdir -p "$WORKDIR" "$IMAGEDIR"

# 7) Extract firmware
echo "🔍 Extracting firmware..."
binwalk -e --directory "$WORKDIR" "$FW"

# 8) Find & unpack rootfs
FS_IMG=$(find "$WORKDIR" -type f \( -name '*.squashfs' -o -name '*.jffs2' -o -name '*.cramfs' \) | head -n1)
[ -n "$FS_IMG" ] || { echo "❌ No rootfs image found"; exit 1; }
echo "📦 Unpacking $FS_IMG..."
rm -rf "$WORKDIR/rootfs"
unsquashfs -d "$WORKDIR/rootfs" "$FS_IMG"

# 9) Build ext4 container
ROOTFS_IMG="$IMAGEDIR/$NAME-rootfs.ext4"
echo "🖴 Creating ext4 (${SIZE}MB)..."
dd if=/dev/zero of="$ROOTFS_IMG" bs=1M count="$SIZE" status=none
mkfs.ext4 -F "$ROOTFS_IMG" >/dev/null

echo "📋 Copying rootfs → $ROOTFS_IMG..."
mount -o loop "$ROOTFS_IMG" /mnt
cp -a "$WORKDIR/rootfs/." /mnt
umount /mnt

# 10) Launch QEMU
echo "🚀 Launching QEMU..."
CMD=( qemu-system-"$ARCH" -M "$MACHINE" -m 256M )
[[ -n "$KERNEL" ]] && CMD+=( -kernel "$KERNEL" )
[[ -n "$DTB"    ]] && CMD+=( -dtb    "$DTB"    )
CMD+=(
  -drive file="$ROOTFS_IMG",format=raw,if=virtio
  -append "root=/dev/vda rw console=ttyS0"
  -nographic
  -netdev user,id=net0,hostfwd=tcp::"$HPORT"-:80
  -device virtio-net-device,netdev=net0
)

echo "${CMD[*]}"
exec "${CMD[@]}"


⸻

3) How to build and run
	1.	Build the image (from the docker/ directory):

docker build -t router-emu .


	2.	Run an interactive container, bind-mount your host dirs:

docker run -it --rm \
  -v ~/router-emu/firmwares:/firmwares \
  -v ~/router-emu/work:/work \
  -v ~/router-emu/images:/images \
  router-emu


	3.	Answer the prompts inside the container:
	•	Path to firmware: e.g. /firmwares/ACME123.bin
	•	Arch, machine, (optional) kernel/DTB, size, port
	4.	Point your browser at http://localhost:<HPORT> to see the router’s real login UI.

⸻

With this setup, all the heavy lifting happens inside Docker—your host stays clean, and you can spin up as many firmware-based router VMs as you like.