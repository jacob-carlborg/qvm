# QVM - QEMU Virtual Machine Manager Specification

## 1. Overview
`qvm` is a simple, cross-platform CLI tool implemented in Bourne-compatible shell script. It automates the process of downloading pre-built QEMU VM images (qcow2), managing QEMU binaries, and launching virtual machines with specific configurations for various operating systems and CPU architectures.

## 2. System Requirements
- **Host OS:** macOS, Linux.
- **Shell:** Bourne-compatible shell (sh, dash, bash, zsh, ksh).
- **Dependencies:** `curl`, `tar`. (QEMU binaries are managed internally).

## 3. Directory Structure
The tool will maintain a cache directory (e.g., `~/.cache/qvm` or relative to script) to store:
- **Binaries:** Downloaded QEMU system binaries and `qemu-img`.
- **Base Images:** Original downloaded qcow2 images (read-only).
- **VM Instances:** COW (Copy On Write) backing files for running instances.
- **Firmware:** BIOS/EFI files extracted from QEMU resource tarballs.
- **Drivers:** A directory containing hardcoded shell script fragments for each OS/Arch combination.

## 4. CLI Interface

### Usage
```sh
# Run a VM
qvm run [OPTIONS] <OS> <VERSION>

# List created VM instances
qvm list

# Configuration
qvm config print-path

# Help & Version
qvm --help
qvm --version
```

### Arguments
- `<OS>`: The operating system to run (e.g., `freebsd`, `netbsd`, `openbsd`, `haiku`, `omnios`).
- `<VERSION>`: The version of the OS (e.g., `13.2`, `10.1`).

### Commands
- `run`: Downloads necessary resources and launches the VM.
- `pull`: Downloads the base VM image for the specified OS/Version to the cache without running it.
- `rm`: Removes a specific VM instance (backing file) from the cache.
- `list`: Lists all created VM instances (backing files) currently in the cache.
- `config print-path`: Prints the absolute path to the configuration/cache directory.

### Global Options
- `--help`: Print usage information and exit.
- `--version`: Print the current version (0.0.1) and exit.

### Command Options

#### `run`
- `--name <NAME>`: Name of the VM instance. Allows running multiple instances of the same OS/Version. Defaults to a randomly generated name (e.g., `qvm-<RANDOM>`).
- `--platform <ARCH>`: CPU architecture.
- `--rm`: Delete the VM instance after shutdown.
- `--dry-run`: Print the generated QEMU command.

#### `pull`
- `--platform <ARCH>`: CPU architecture (defaults to host).

#### `rm`
- `<NAME>`: The name of the VM instance to remove (as shown in `list`).


### Behavior
- Running `qvm` without arguments (or with unknown arguments) must print the help message.
- Initial version is `0.0.1`.


## 5. VM Management Workflow

1.  **Resolution:** Determine target OS, Version, and Architecture.
2.  **Resource Check:** Check if QEMU binaries and `qemu-img` are present. If not, resolve the latest version via GitHub Releases and download/extract them.
3.  **Image Check:** Check if the base image exists. If not, resolve the latest version via GitHub Releases and download it.
4.  **Instance Creation:** Create a new qcow2 image backed by the base image using `qemu-img create -f qcow2 -b <base> -F qcow2 <instance>`.
5.  **Driver Loading:** Source the specific driver file for the requested OS and Architecture (e.g., `drivers/freebsd-x86-64.sh`).
6.  **Execution:** The driver constructs and executes the specific QEMU command.
7.  **Cleanup:** If `--rm` was specified, remove the instance file after QEMU exits.

## 6. Data Sources

### Base URLs
All resources are hosted under `https://github.com/cross-platform-actions`.

### QEMU Binaries & Resources
Resources will be resolved dynamically from the `resources` repository.
- **Project:** `https://github.com/cross-platform-actions/resources`
- **Latest Resolution:** Fetch `releases/latest` -> Extract tag (e.g., `v0.12.0`).

Files to download (based on resolved version):
- **Linux x86_64:** `qemu-system-x86_64-linux.tar`
- **macOS x86_64:** `qemu-system-x86_64-macos.tar`
- **Linux ARM64:** `qemu-system-aarch64-linux.tar`
- **macOS ARM64:** `qemu-system-aarch64-macos.tar`
- **qemu-img (Linux):** `resources-linux.tar`
- **qemu-img (macOS):** `resources-macos.tar`

**Extraction Strategy:** Use `tar --strip-components=1` to flatten directory structure during extraction.

### VM Images
Pattern: `https://github.com/cross-platform-actions/<OS>-builder/releases`
- **Latest Resolution:** Fetch `releases/latest` -> Extract tag (e.g., `v0.13.1`).
- **Download URL:** `<url>/releases/download/<TAG>/<OS>-<VERSION>-<ARCH>.qcow2`.

## 7. QEMU Configuration Definitions (Drivers)

QEMU command definitions will not be shared. There will be a specific, hardcoded shell script fragment (driver) for each distinct **Operating System + CPU Architecture** combination.

### Driver Strategy
The main `qvm` script will determine the target OS and Architecture, then source the corresponding driver file.

### Driver Files List
The following driver files will be implemented in a `drivers/` directory:

1.  `freebsd-arm64.sh`
2.  `freebsd-x86-64.sh`
3.  `openbsd-arm64.sh`
4.  `openbsd-x86-64.sh`
5.  `netbsd-arm64.sh`
6.  `netbsd-x86-64.sh`
7.  `haiku-x86-64.sh`
8.  `omnios-x86-64.sh`

### Configuration Details per Driver

#### FreeBSD ARM64
```sh
qemu-system-aarch64 \
  -nographic \
  -machine type=virt,accel=hvf:kvm:tcg \
  -cpu cortex-a57 \
  -smp 2 \
  -m 6G \
  -device virtio-net,netdev=user.0,addr=0x03 \
  -netdev user,id=user.0,hostfwd=tcp::2847-:22 \
  -display none \
  -monitor none \
  -boot strict=off \
  -bios "$QVM_CACHE/share/qemu/uefi.fd" \
  -device virtio-blk-pci,drive=drive0,bootindex=0 \
  -drive if=none,file="$VM_IMAGE",id=drive0,cache=unsafe,discard=ignore,format=qcow2
```

#### FreeBSD x86-64
```sh
qemu-system-x86_64 \
  -nographic \
  -machine type=q35,accel=hvf:kvm:tcg \
  -cpu max \
  -smp 2 \
  -m 6G \
  -device virtio-net,netdev=user.0,addr=0x03 \
  -netdev user,id=user.0,hostfwd=tcp::2847-:22 \
  -display none \
  -monitor none \
  -boot strict=off \
  -bios "$QVM_CACHE/share/qemu/bios-256k.bin" \
  -device virtio-blk-pci,drive=drive0,bootindex=0 \
  -drive if=none,file="$VM_IMAGE",id=drive0,cache=unsafe,discard=ignore,format=qcow2
```

#### Haiku x86-64
```sh
qemu-system-x86_64 \
  -nographic \
  -machine type=q35,accel=hvf:kvm:tcg \
  -cpu max \
  -smp 2 \
  -m 6G \
  -device e1000,netdev=user.0,addr=0x03 \
  -netdev user,id=user.0,hostfwd=tcp::2847-:22,ipv6=off \
  -display none \
  -monitor none \
  -boot strict=off \
  -bios "$QVM_CACHE/share/qemu/bios-256k.bin" \
  -device virtio-scsi-pci \
  -device scsi-hd,drive=drive0,bootindex=0 \
  -drive if=none,file="$VM_IMAGE",id=drive0,cache=unsafe,discard=ignore,format=qcow2
```

#### OpenBSD ARM64
```sh
qemu-system-aarch64 \
  -nographic \
  -machine type=virt,accel=hvf:kvm:tcg \
  -cpu cortex-a57 \
  -smp 2 \
  -m 6G \
  -device virtio-net,netdev=user.0,addr=0x03 \
  -netdev user,id=user.0,hostfwd=tcp::2847-:22 \
  -display none \
  -monitor none \
  -boot strict=off \
  -bios "$QVM_CACHE/share/qemu/linaro_uefi.fd" \
  -device virtio-scsi-pci \
  -device scsi-hd,drive=drive0,bootindex=0 \
  -drive if=none,file="$VM_IMAGE",id=drive0,cache=unsafe,discard=ignore,format=qcow2
```

#### OpenBSD x86-64
```sh
qemu-system-x86_64 \
  -nographic \
  -machine type=q35,accel=hvf:kvm:tcg \
  -cpu max,-pdpe1gb \
  -smp 2 \
  -m 6G \
  -device e1000,netdev=user.0,addr=0x03 \
  -netdev user,id=user.0,hostfwd=tcp::2847-:22 \
  -display none \
  -monitor none \
  -boot strict=off \
  -drive if=pflash,format=raw,unit=0,file="$QVM_CACHE/share/qemu/uefi.fd",readonly=on \
  -device virtio-scsi-pci \
  -device scsi-hd,drive=drive0,bootindex=0 \
  -drive if=none,file="$VM_IMAGE",id=drive0,cache=unsafe,discard=ignore,format=qcow2
```

#### NetBSD x86-64
```sh
qemu-system-x86_64 \
  -nographic \
  -machine type=q35,accel=hvf:kvm:tcg \
  -cpu max \
  -smp 2 \
  -m 6G \
  -device virtio-net,netdev=user.0,addr=0x03 \
  -netdev user,id=user.0,hostfwd=tcp::2847-:22,ipv6=off \
  -display none \
  -monitor none \
  -boot strict=off \
  -bios "$QVM_CACHE/share/qemu/bios-256k.bin" \
  -device virtio-scsi-pci \
  -device scsi-hd,drive=drive0,bootindex=0 \
  -drive if=none,file="$VM_IMAGE",id=drive0,cache=unsafe,discard=ignore,format=qcow2
```

#### NetBSD ARM64
```sh
qemu-system-aarch64 \
  -nographic \
  -machine type=virt,accel=hvf:kvm:tcg \
  -cpu cortex-a57 \
  -smp 2 \
  -m 6G \
  -device virtio-net,netdev=user.0,addr=0x03 \
  -netdev user,id=user.0,hostfwd=tcp::2847-:22,ipv6=off \
  -display none \
  -monitor none \
  -boot strict=off \
  -bios "$QVM_CACHE/share/qemu/uefi.fd" \
  -device virtio-scsi-pci \
  -device scsi-hd,drive=drive0,bootindex=0 \
  -drive if=none,file="$VM_IMAGE",id=drive0,cache=unsafe,discard=ignore,format=qcow2
```

#### OmniOS x86-64
```sh
qemu-system-x86_64 \
  -nographic \
  -machine type=q35,accel=hvf:kvm:tcg \
  -cpu max \
  -smp 2 \
  -m 6G \
  -device virtio-net,netdev=user.0,addr=0x03 \
  -netdev user,id=user.0,hostfwd=tcp::2847-:22 \
  -display none \
  -monitor none \
  -boot strict=off \
  -bios "$QVM_CACHE/share/qemu/bios-256k.bin" \
  -device virtio-blk,drive=drive0,bootindex=0,addr=0x02 \
  -drive if=none,file="$VM_IMAGE",id=drive0,cache=unsafe,discard=ignore,format=qcow2
```

## 8. Implementation Details

- **Shell:** Strict POSIX/Bourne compatibility. No bashisms (arrays, `[[ ]]`, etc.).
- **HTTP Client:** `curl` only. Flags: `-L` (follow redirects), `-f` (fail fast), `-s` (silent/no progress), retry flags.
- **Paths:** Always use absolute paths for QEMU arguments (BIOS, Drives).
- **Indentation:** 2 spaces.
