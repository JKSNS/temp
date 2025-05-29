````markdown
# Firmware Analysis Toolkit (FAT) Troubleshooting Guide

This document walks through common issues and configuration tweaks to get FAT (and its Firmadyne backend) installed and running smoothly on Ubuntu/Debian systems.

---

## Table of Contents

1. [Prerequisites & Environment](#prerequisites--environment)  
2. [Initial Setup](#initial-setup)  
3. [Common Issues & Fixes](#common-issues--fixes)  
   - [1. Python Version Errors](#1-python-version-errors)  
   - [2. Firmadyne Path / `firmadyne.config`](#2-firmadyne-path--firmadyneconfig)  
   - [3. QEMU Binary Mismatch](#3-qemu-binary-mismatch)  
   - [4. Network/Bridge Timeouts](#4-networkbridge-timeouts)  
   - [5. Missing Loop / Bridge Modules](#5-missing-loop--bridge-modules)  
   - [6. Filesystem Extraction Tools](#6-filesystem-extraction-tools)  
   - [7. Partition Mapping (`kpartx`)](#7-partition-mapping-kpartx)  
   - [8. Python Module Errors](#8-python-module-errors)  
   - [9. Sudoers / Hostname Issues](#9-sudoers--hostname-issues)  
   - [10. Firewall / `ufw` Rules](#10-firewall--ufw-rules)  
   - [11. KVM Acceleration Problems](#11-kvm-acceleration-problems)  
4. [“One-Command” Re-test](#one-command-re-test)  
5. [Additional Resources](#additional-resources)  

---

## Prerequisites & Environment

- **Recommended Host OS**: Ubuntu 18.04–20.04 LTS  
- **Kernel modules**: `loop`, `tun`, `bridge`  
- **IP forwarding** enabled  
- **Disk tools**: `squashfs-tools`, `mtd-utils`, `cpio`, `p7zip-full`, `unrar-free`  
- **Partition mapper**: `kpartx`  
- **Python**: Both v2.7 and v3.x installed  
- **Database**: SQLite (default) or PostgreSQL if configured  

---

## Initial Setup

1. **Clone FAT repo**  
   ```bash
   git clone https://github.com/attify/firmware-analysis-toolkit.git
   cd firmware-analysis-toolkit
````

2. **Ensure Python-2 shebang**

   ```bash
   sed -i '1s|.*|#!/usr/bin/env python2|' setup.sh fat.py reset.py
   chmod +x setup.sh fat.py reset.py
   ```

3. **Install system packages**

   ```bash
   sudo apt-get update
   sudo apt-get install \
     python2 python2-pip python3-pip \
     build-essential libglib2.0-dev libpixman-1-dev \
     squashfs-tools mtd-utils cpio p7zip-full unrar-free \
     kpartx qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
   ```

4. **Enable kernel modules & IP forwarding**

   ```bash
   sudo modprobe loop tun bridge
   sudo sysctl -w net.ipv4.ip_forward=1
   echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-forward.conf
   sudo sysctl --system
   ```

5. **Install Python modules**

   ```bash
   sudo pip2 install termcolor pycrypto progress
   sudo pip3 install configparser
   ```

6. **Run FAT setup**

   ```bash
   ./setup.sh
   ```

---

## Common Issues & Fixes

### 1. Python Version Errors

**Symptom:** `TypeError`, `ModuleNotFoundError`, or invalid syntax in FAT scripts.
**Fix:** Ensure FAT scripts run under Python 2:

```bash
head -n1 setup.sh fat.py reset.py
# should be: #!/usr/bin/env python2
```

---

### 2. Firmadyne Path / `firmadyne.config`

**Symptom:** “Cannot find Firmadyne directory” or database errors.
**Fix:**

* In FAT’s `fat.config`:

  ```ini
  [DEFAULT]
  sudo_password = your_sudo_pass
  firmadyne_path  = /home/you/firmadyne
  ```
* In Firmadyne’s `firmadyne.config`:

  ```ini
  project_dir = /home/you/firmadyne
  database    = sqlite
  ```

---

### 3. QEMU Binary Mismatch

**Symptom:** “No such file: qemu-system-\*-2.5.0” or unsupported QEMU version.
**Fix Options:**

* Use FAT’s static QEMU builds under `bin/`
* OR patch `fat.py` to point at host QEMU:

  ```python
  # in fat.py, around qemu_path assignment:
  qemu_path = "/usr/bin/qemu-system-{}".format(arch)
  ```

---

### 4. Network/Bridge Timeouts

**Symptom:**

```
[ERROR] No network interface found after 60s
```

**Fix:**

* Edit `scripts/inferNetwork.sh`:

  ```bash
  BRIDGE=br0
  IP4=192.168.0.1
  NETMASK=24
  ```
* Replace complex `grep` logic with a static `ip link add name $BRIDGE type bridge …`

---

### 5. Missing Loop / Bridge Modules

**Symptom:**

```
mount: unknown filesystem type ‘squashfs’
```

or

```
Bridge device br0 does not exist
```

**Fix:**

```bash
sudo modprobe loop
sudo modprobe bridge
```

---

### 6. Filesystem Extraction Tools

**Symptom:** Binwalk fails to extract JFFS2/CRAMFS images.
**Fix:**

```bash
sudo apt-get install squashfs-tools mtd-utils cpio p7zip-full unrar-free
```

---

### 7. Partition Mapping (`kpartx`)

**Symptom:**

```
losetup: cannot find partition table
```

**Fix:**

```bash
sudo apt-get install kpartx
sudo systemctl enable --now kmod
```

---

### 8. Python Module Errors

**Symptom:**

```
ImportError: No module named termcolor
```

**Fix:**

```bash
sudo pip2 install termcolor pycrypto progress
```

---

### 9. Sudoers / Hostname Issues

**Symptom:**

```
sudo: unable to resolve host myhost
```

**Fix:**

* Add entry in `/etc/hosts`:

  ```
  127.0.0.1   your-hostname
  ```
* Or give passwordless sudo for Firmadyne scripts:

  ```bash
  # /etc/sudoers.d/firmadyne
  youruser ALL=(ALL) NOPASSWD: /path/to/firmadyne/scripts/*
  ```

---

### 10. Firewall / `ufw` Rules

**Symptom:**
QEMU VM cannot ping host or access network.
**Fix:**

```bash
sudo ufw allow in on br0
sudo iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -j MASQUERADE
```

---

### 11. KVM Acceleration Problems

**Symptom:**
QEMU is extremely slow or fails to start with KVM.
**Fix:**

```bash
sudo usermod -aG kvm $(whoami)
# Verify with:
ls -al /dev/kvm
```

If needed, patch FAT to use `/usr/bin/qemu-system-<arch>` that has KVM support.

---

## “One-Command” Re-test

Once all fixes are applied, try:

```bash
./setup.sh          # no errors
./fat.py firmware.bin
```

Expect output:

1. Extraction logs
2. “Detected architecture: …”
3. Disk image creation
4. Bridge `br0` up and IP assignment
5. QEMU prompt “Press ENTER to run firmware”

---

## Additional Resources

* **FAT GitHub** – Issues & Wiki:
  [https://github.com/attify/firmware-analysis-toolkit](https://github.com/attify/firmware-analysis-toolkit)
* **Attify Blog: Firmware Emulation 101**
  [https://blog.attify.com/getting-started-with-firmware-emulation/](https://blog.attify.com/getting-started-with-firmware-emulation/)
* **SecNigma Tutorial**
  [https://secnigma.wordpress.com/2022/01/18/a-beginners-guide-into-router-hacking-and-firmware-emulation/](https://secnigma.wordpress.com/2022/01/18/a-beginners-guide-into-router-hacking-and-firmware-emulation/)

---


