Below is end-to-end documentation—targeted at Ubuntu 24—for taking any modern vendor firmware (ARM, MIPS, x86, etc.) and spinning it up as a full, interactive router VM (with its real web UI), either directly under QEMU or packaged in Docker.

⸻

Overview

This guide covers:
	1.	Host setup on Ubuntu 24
	2.	Bulk extraction of vendor firmware blobs
	3.	Architecture detection & rootfs unpacking
	4.	Building a bootable ext4 disk image
	5.	Obtaining or building a matching kernel & device tree
	6.	Launching system-mode QEMU with HTTP port-forwarding
	7.	(Optional) Automating with Firmadyne
	8.	(Optional) Containerizing in Docker
	9.	Orchestration & lab topologies
	10.	Debugging, instrumentation, and common pitfalls

⸻

1. Host Prerequisites

sudo apt update
sudo apt install -y \
  binwalk squashfs-tools mtd-utils git build-essential \
  qemu-system-mips qemu-system-arm qemu-system-x86 \
  qemu-utils libguestfs-tools python3-pip docker.io
# Add yourself to docker group (re-login required)
sudo usermod -aG docker $USER


⸻

2. Workspace & Directory Layout

mkdir -p ~/router-emu/{firmwares,work,images,scripts,docker}
cd ~/router-emu

	•	firmwares/: drop all vendor .bin/.img files here
	•	work/: temporary extraction & build scratch space
	•	images/: final disk images, kernels, DTBs, configs
	•	scripts/: automation helpers
	•	docker/: Dockerfile & compose manifests

⸻

3. Bulk Extraction of Firmware

Create scripts/extract_all.sh:

#!/usr/bin/env bash
set -euo pipefail
SRC=../firmwares
DST=../work
mkdir -p "$DST"

for fw in "$SRC"/*.{bin,img,zip}; do
  name=$(basename "$fw" | sed 's/\.[^.]*$//')
  out="$DST/$name"
  [ -d "$out" ] && continue
  echo "Extracting $fw → $out"
  binwalk -e --directory "$out" "$fw"
done

chmod +x scripts/extract_all.sh
scripts/extract_all.sh


⸻

4. Identify Architecture & RootFS

For each extracted folder (work/<name>/):
	1.	Locate filesystem image

find work/$name -type f \
  \( -name '*.squashfs' -o -name '*.jffs2' -o -name '*.cramfs' \)


	2.	Probe BusyBox for CPU arch

file work/$name/*/squashfs-root/bin/busybox
# → “ELF 32-bit LSB executable, MIPS, …” or “ARM, EABI” or “x86-64”


	3.	Note: if you find zImage, uImage, or a .dtb, stash those under images/$name/ for later.

⸻

5. Build a Bootable ext4 Disk Image

Save as scripts/build_rootfs.sh:

#!/usr/bin/env bash
set -euo pipefail
NAME=$1
WORK=../work/$NAME
OUT=../images/$NAME
FS_IMG=$(find "$WORK" -type f -name '*.squashfs' | head -n1)

mkdir -p "$OUT"
# 1. Extract squashfs → temp
rm -rf "/tmp/$NAME-rootfs"
mkdir -p "/tmp/$NAME-rootfs"
sudo unsquashfs -d "/tmp/$NAME-rootfs" "$FS_IMG"

# 2. Create ext4 container (size adjust as needed)
IMG="$OUT/$NAME-rootfs.ext4"
dd if=/dev/zero of="$IMG" bs=1M count=512
mkfs.ext4 -F "$IMG"

# 3. Copy rootfs
sudo mount -o loop "$IMG" /mnt
sudo cp -a "/tmp/$NAME-rootfs/." /mnt
sudo umount /mnt
rm -rf "/tmp/$NAME-rootfs"

echo "→ Built $IMG"

chmod +x scripts/build_rootfs.sh
# Loop over all names
for name in $(ls work); do
  scripts/build_rootfs.sh $name
done


⸻

6. Obtain or Compile Matching Kernel & DTB
	•	Vendor-provided: copy any extracted zImage/uImage and .dtb into images/<name>/.
	•	Generic kernels: use Firmadyne’s prebuilt repo:

git clone https://github.com/firmadyne/firmadyne-kernel.git images/kernels

Pick kernels/<arch>/vmlinux and its .dtb for the matching SoC.

⸻

7. Launch with QEMU (System-Mode)

Create scripts/run_qemu.sh:

#!/usr/bin/env bash
set -euo pipefail
NAME=$1
IMGDIR=../images/$NAME
ROOTFS=$IMGDIR/$NAME-rootfs.ext4
KERNEL=$(ls $IMGDIR/*vmlinux* $IMGDIR/zImage 2>/dev/null | head -n1)
DTB=$(ls $IMGDIR/*.dtb 2>/dev/null | head -n1 || echo '')

# You may need to override ARCH & MACHINE per firmware:
ARCH=${ARCH:-mipsel}
MACHINE=${MACHINE:-malta}

qemu-system-$ARCH \
  -M $MACHINE -m 256M \
  -kernel "$KERNEL" \
  ${DTB:+-dtb "$DTB"} \
  -drive file="$ROOTFS",format=raw,if=virtio \
  -append "root=/dev/vda rw console=ttyS0" \
  -nographic \
  -netdev user,id=net0,hostfwd=tcp::8080-:80 \
  -device virtio-net-device,netdev=net0

chmod +x scripts/run_qemu.sh
# Example for a MIPS firmware “ACME123”:
ARCH=mipsel MACHINE=malta scripts/run_qemu.sh ACME123

	•	-nographic: serial console on your terminal
	•	hostfwd: guest port 80 → host port 8080 → browser to http://localhost:8080

If you prefer a windowed console, replace -nographic with -display gtk.

⸻

8. Automating with Firmadyne (Optional)

Firmadyne automates extraction, DB tracking, and QEMU wrapper generation:

cd firmadyne
# configure config.ini → set IMAGE_DIR=~/router-emu/images, DB path
./scripts/extract.py ~/router-emu/firmwares/ACME123.bin
./scripts/patches.py <image-id>
./scripts/run.sh <image-id>

The VM will appear on a virtual bridge (e.g. 192.168.0.2); point your host to that IP.

⸻

9. Containerizing in Docker (Optional)

docker/Dockerfile:

FROM ubuntu:24.04
RUN apt update && apt install -y \
    qemu-system-mips binwalk squashfs-tools sudo
WORKDIR /opt
COPY entrypoint.sh /opt/
COPY ../firmwares /opt/firmwares
ENTRYPOINT ["bash","/opt/entrypoint.sh"]

docker/entrypoint.sh:

#!/usr/bin/env bash
set -euo pipefail
NAME=$1
FW=/opt/firmwares/$NAME.bin
EX=/opt/work/$NAME

# (Re)use your extract/build scripts here...
binwalk -e --directory "$EX" "$FW"
# ...unsquashfs, build ext4, locate kernel/dtb...

# Launch QEMU exactly as in run_qemu.sh
qemu-system-mipsel ... \
  -netdev user,id=net0,hostfwd=tcp::80-:80 ...

Build & run:

cd docker
docker build -t router-emu .
docker run --rm -p 8080:80 router-emu ACME123

Browse http://localhost:8080 to interact.

⸻

10. Orchestration & Topologies
	•	docker-compose: define multiple router services on a custom bridge, assign static IPs, and link client containers.
	•	GNS3 / EVE-NG: import your QEMU (or Docker) appliances, interconnect with virtual switches, VLANs, firewalls, and hosts for full lab scenarios.

⸻

11. Debugging & Instrumentation
	•	GDB stub: add -s -S to QEMU flags → listen on TCP :1234 before boot
	•	gdb-multiarch or vendor-toolchains to attach to kernel/userland
	•	PANDA or Avatar2 plugins for record/replay, taint tracking, multi-target instrumentation
	•	tcpdump in host with -i any port 80 to verify HTTP traffic

⸻

12. Common Pitfalls & Tips
	•	Kernel/DTB mismatch: if vendor kernel is missing, try OpenWRT or Firmadyne’s prebuilt kernels.
	•	Filesystem too small: bump the dd … count= to fit large rootfs.
	•	Missing drivers: proprietary Wi-Fi or switching ASICs may not initialize—stick to basic Ethernet.
	•	Docker permissions: you may need --cap-add=NET_ADMIN for TAP interfaces if you switch away from user-mode networking.

⸻

With this workflow in place on Ubuntu 24, you can drop any vendor firmware into firmwares/ and, in minutes, spin up a real, interactive router VM—complete with its genuine login UI—either natively under QEMU or neatly containerized in Docker.