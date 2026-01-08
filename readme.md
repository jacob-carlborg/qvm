# QVM - QEMU Virtual Machine Manager

<p align="center">
  <img src="logo.svg" alt="QVM Logo" width="400">
</p>

`qvm` is a lightweight, cross-platform CLI tool implemented in pure POSIX shell
script. It automates the process of downloading pre-built VM images and
launching them with QEMU, making it trivial to spin up ephemeral environments
for testing or development.

It handles the heavy lifting: downloading QEMU binaries, fetching base images,
managing copy-on-write (COW) instances, and configuring the complex QEMU
command-line flags for various operating systems and architectures.

## ✨ Features

*   **Zero Dependency Hell:** Automatically manages its own QEMU and `qemu-img`
    binaries.
*   **Cross-Platform:** Runs seamlessly on macOS and Linux.
*   **Multi-Architecture:** Supports x86-64 and ARM64 (including Apple
    Silicon).
*   **Copy-on-Write:** Uses qcow2 backing files to keep base images clean and
    disk usage low.
*   **Ephemeral by Design:** Easily spin up and destroy VM instances.
*   **Broad OS Support:** Pre-configured drivers for FreeBSD, OpenBSD, NetBSD,
    Haiku, and OmniOS.

## 🚀 Getting Started

### Prerequisites

*   **OS:** macOS or Linux
*   **Shell:** Any Bourne-compatible shell (`sh`, `bash`, `zsh`, `dash`)
*   **Tools:** `curl`, `tar`

### Installation

`qvm` is a standalone script. Simply download it and make it executable:

```bash
# Clone the repository
git clone https://github.com/yourusername/qvm.git

# Enter directory
cd qvm

# Run directly
./qvm --help
```

For convenience, add it to your PATH:

```bash
export PATH=$PATH:$(pwd)
```

## 📖 Usage

### Running a VM

The `run` command downloads the necessary base image (if not cached), creates a
new instance, and boots it.

```bash
# Run FreeBSD 13.2
qvm run freebsd 13.2

# Run with a custom name (allow multiple instances)
qvm run --name my-server freebsd 13.2

# Run and delete automatically after shutdown
qvm run --rm openbsd 7.4
```

### Managing Instances

Each time you run a VM without a name, a unique instance is created. You can
list and manage them easily.

```bash
# List all active instances
qvm list
# Output:
# NAME                   OS         VERSION      ARCH
# ---------------------- ---------- ------------ --------
# qvm-1767882876-20785   freebsd     13.2         x86-64

# Search for available versions
qvm search freebsd
# Output:
# VERSION     x86-64    arm64
# -------     ------    -----
# 13.2        yes       yes
# 14.0        yes       -

# Remove specific instances
qvm rm qvm-1767882876-20785
```

`qvm list` shows `OS`, `VERSION`, and `ARCH` from instance metadata created by `qvm run`.

### Caching Images

Pre-download base images to your cache without running them:

```bash
qvm pull netbsd 9.3
```

### Configuration

Check where `qvm` stores its binaries and images:

```bash
qvm config print-path
# Output: /Users/user/.cache/qvm
```

## 🌍 Supported Operating Systems

`qvm` includes optimized driver configurations for:

| Operating System | x86-64 | ARM64 |
| :--- | :---: | :---: |
| **FreeBSD** | ✅ | ✅ |
| **OpenBSD** | ✅ | ✅ |
| **NetBSD** | ✅ | ✅ |
| **Haiku** | ✅ | ❌ |
| **OmniOS** | ✅ | ❌ |

## 🛠 Architecture

`qvm` uses a driver-based architecture. All QEMU flags and hardware definitions
are isolated in `drivers/<os>-<arch>.sh` files, ensuring that each platform
runs with the optimal configuration (accelerators like HVF on macOS or KVM on
Linux are automatically selected).

Resources are downloaded from the
[cross-platform-actions](https://github.com/cross-platform-actions) GitHub
organization.

## 🧪 Development & Testing

This project targets strict POSIX `sh` compatibility to ensure it runs anywhere.

### Static Analysis

Use `shellcheck` to ensure syntax compliance and avoid bashisms:

```bash
./ci.sh lint
```

### Automated Tests

We recommend using [bats-core](https://github.com/bats-core/bats-core) for
integration testing.

1.  **Install Bats:** Follow instructions at [bats-core](https://github.com/bats-core/bats-core).
2.  **Directory Structure:**
    *   `tests/`: Contains `.bats` test files.
    *   `tests/mocks/`: Contains mock scripts for `curl`, `uname`, and `qemu-system-*`.
3.  **Running Tests:**
    ```bash
    ./ci.sh test
    ```

## 📄 License

This project is licensed under the MIT License - see the [license](license) file for details.
