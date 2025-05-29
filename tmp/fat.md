# Firmware Analysis Toolkit (FAT) Troubleshooting Guide

This document covers common issues and their resolutions when installing, configuring, and running the Firmware Analysis Toolkit (FAT).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Shebang and Python Version Fixes](#shebang-and-python-version-fixes)
3. [Firmadyne Configuration](#firmadyne-configuration)
4. [QEMU Binary Setup](#qemu-binary-setup)
5. [Kernel Modules & Networking](#kernel-modules--networking)
6. [Filesystem & Partition Tools](#filesystem--partition-tools)
7. [Python Library Dependencies](#python-library-dependencies)
8. [Database Permissions](#database-permissions)
9. [Sudoers & Hostname](#sudoers--hostname)
10. [KVM Acceleration (Optional)](#kvm-acceleration-optional)
11. [Firewall & iptables](#firewall--iptables)
12. [Setup & Execution](#setup--execution)
13. [Cleanup](#cleanup)
14. [Additional Resources](#additional-resources)

---

## Prerequisites

* **Supported OS:** Ubuntu 18.04–20.04 (most battle‑tested)
* **User:** sudo rights
* **git, curl, wget** installed

---

## Shebang and Python Version Fixes

FAT’s scripts default to `#!/usr/bin/env python`. On modern Ubuntu this invokes Python 3 and breaks FAT (which requires Python 2).

```bash
# In your FAT directory:
sed -i '1s|.*|#!/usr/bin/env python2|' setup.sh fat.py reset.py
```

Ensure `python2` is installed and available:

```bash
sudo apt-get install python2
```

---

## Firmadyne Configuration

1. In your **Firmadyne** checkout, edit `firmadyne.config`:

   ```ini
   project_dir = /home/you/firmadyne
   database    = sqlite
   ```
2. In **fat.config**, set your sudo password and path:

   ```ini
   [DEFAULT]
   sudo_password = your_sudo_password
   firmadyne_path = /home/you/firmadyne
   ```

No trailing slashes; ensure exact paths and correct casing.

---

## QEMU Binary Setup

FAT bundles static QEMU 2.5.0 builds by default. If you prefer your system QEMU:

1. Locate the QEMU binary detection in `fat.py` (around line 350).
2. Patch:

   ```python
   # original
   qemu_path = os.path.join(FAT_BIN, "qemu-system-{}-2.5.0".format(arch))
   # patched
   qemu_path = "/usr/bin/qemu-system-{}".format(arch)
   ```
3. Ensure `/usr/bin/qemu-system-<arch>` exists (e.g., `qemu-system-arm`, `qemu-system-mipsel`).

---

## Kernel Modules & Networking

Enable required kernel modules and IP forwarding:

```bash
sudo modprobe loop tun bridge
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-forward.conf
sudo sysctl --system
```

### Network Inference

If FAT times out waiting for a bridge interface, edit `scripts/inferNetwork.sh`:

```bash
BRIDGE=br0
IP4=192.168.0.1
NETMASK=24
# Replace grep logic with explicit bridge creation:
ip link add name $BRIDGE type bridge
```

---

## Filesystem & Partition Tools

Install extract/mount helpers:

```bash
sudo apt-get update
sudo apt-get install squashfs-tools mtd-utils cpio p7zip-full unrar-free
sudo apt-get install kpartx
```

Enable partition mapping:

```bash
sudo systemctl enable --now kmod
```

---

## Python Library Dependencies

```bash
sudo apt-get install python2-pip python3-pip build-essential libglib2.0-dev libpixman-1-dev
sudo pip2 install pycrypto termcolor progress
sudo pip3 install configparser
```

---

## Database Permissions

> *Optional:* Switching to PostgreSQL

```bash
# create user and database\psql -U postgres -c "CREATE USER firmadyne;"
psql -U postgres -c "CREATE DATABASE firmadyne OWNER firmadyne;"
```

Update `firmadyne.config` with credentials.

---

## Sudoers & Hostname

Prevent `sudo: unable to resolve host` and password prompts:

* Add a sudoers file `/etc/sudoers.d/firmadyne` with:

  ```text
  youruser ALL=(ALL) NOPASSWD: /path/to/firmadyne/scripts/*
  ```
* Ensure `$(hostname)` is in `/etc/hosts`.

---

## KVM Acceleration (Optional)

For faster emulation:

```bash
sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
sudo usermod -aG kvm,$(whoami)
```

Patch `fat.py` to call your KVM-enabled `qemu-system-<arch>`.

---

## Firewall & iptables

Allow FAT’s bridge network:

```bash
sudo ufw allow in on br0
sudo iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -j MASQUERADE
```

---

## Setup & Execution

```bash
# Initial install
git clone https://github.com/attify/firmware-analysis-toolkit
cd firmware-analysis-toolkit
./setup.sh   # no errors

# Run FAT
./fat.py /path/to/firmware.bin
```

Expect: extraction, arch detection, disk image, bridge creation, then QEMU prompt.

---

## Cleanup

```bash
./reset.py   # removes images & interfaces
```

---

## Additional Resources

* **FAT GitHub**: [https://github.com/attify/firmware-analysis-toolkit](https://github.com/attify/firmware-analysis-toolkit)
* **Attify Blog**: Getting started with firmware emulation
* **SecNigma Guide**: A beginner’s guide to router hacking & firmware emulation
