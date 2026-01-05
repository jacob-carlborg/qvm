I want to build a simple CLI tool that run QEMU virtual machines. It's intended
to download pre-built VM images and launch those. It should be cross platform
(support for macOS and Linux is fine for now). It should be implemented in
shell script that works for all borune compatible shells, not just bash. The
downloaded images are in the qcow2 format. They should be stored and be reused
and only downloaded if not already present. Use qcow2 backing files to avoid
modifying the original VM images when launching a VM, these original images act
like base images. If the --rm flag is passed it should destroy the VM image
(not the base image) after the VM has shutdown. It should support multiple
operating systems, multiple cpu architectures and multiple versions of the
operating system. I'm thinking there can be, more or less, hardcoded shell
script files, one for each combination of operating system and cpu
architecture. The VM images are available to download GitHub releases, from:


https://github.com/cross-platform-actions/freebsd-builder/releases/latest
https://github.com/cross-platform-actions/openbsd-builder/releases/latest
https://github.com/cross-platform-actions/netbsd-builder/releases/latest
https://github.com/cross-platform-actions/haiku-builder/releases/latest
https://github.com/cross-platform-actions/omnios-builder/releases/latest

The format is: <operatingsystem>-<version>-<cpuarchitecture>.qcow, for example:
freebsd-13.2-x86-64.qcow2
netbsd-10.1-arm64.qcow2


* The CPU architecture should be optional and defaults to the same CPU
    architecture as the host platform. To explicitly specify the CPU architecture,
    pass the --platform flag.

* Regarding the definitions files. It doesn't need to separate files for each
    version, the only thing that will be different between different versions will
    be the name of the base VM image file.

* Regarding the accelerator flags, for simplicity, always specify all -accel
    flags and QEMU will automatically pick the best match. -accel tcg need to go
    last.

* Only use Curl, don't use wget. Make sure the appropriate flags for handling
    redirects and retries are passed. Also not progress should be show from Curl.

* The QVM_DOWNLOAD_URL URL is not correct. Example of correct URL is "https://github.com/cross-platform-actions/freebsd-builder/releases/download/v0.13.1/freebsd-13.2-x86-64.qcow2". After "download" in the URL comes the version of the builder, not the version of the operating system. The command needs to figure out which is the latest version of the builder. The latest version can be retrieved at "https://github.com/cross-platform-actions/freebsd-builder/releases/latest". This URL points to the latest version and, in this case, redirects to "https://github.com/cross-platform-actions/freebsd-builder/releases/tag/v0.13.1". So perhaps the command needs to extract the build version out of the URL.
* For the QEMU command, don't use the system provided command, but instead
    download the command from here:
    https://github.com/cross-platform-actions/resources/releases/download/v0.12.0/qemu-system-aarch64-linux.tar
    https://github.com/cross-platform-actions/resources/releases/download/v0.12.0/qemu-system-aarch64-macos.tar
    https://github.com/cross-platform-actions/resources/releases/download/v0.12.0/qemu-system-x86_64-linux.tar
    https://github.com/cross-platform-actions/resources/releases/download/v0.12.0/qemu-system-x86_64-macos.tar

    The content of the above tar files are:
    $ tree qemu-system-x86_64-linux
    qemu-system-x86_64-linux
    ├── bin
    │   └── qemu
    └── share
        └── qemu
            ├── bios-256k.bin
            ├── efi-e1000.rom
            ├── efi-virtio.rom
            ├── kvmvapic.bin
            ├── uefi.fd
            └── vgabios-stdvga.bin
    $ tree qemu-system-aarch64-macos
    qemu-system-aarch64-macos
    ├── bin
    │   └── qemu
    └── share
        └── qemu
            ├── efi-e1000.rom
            ├── efi-virtio.rom
            ├── linaro_uefi.fd
            └── uefi.fd

qemu-img can be found here:
https://github.com/cross-platform-actions/resources/releases/download/v0.12.0/resources-linux.tar
https://github.com/cross-platform-actions/resources/releases/download/v0.12.0/resources-macos.tar

Again, the version in the above URLs are the version of the "resources"
project. The command needs to be able to figure out latest version.

* The exact QEMU commands that should be run are:
FreeBSD ARM64:
qemu-system-aarch64 -daemonize -machine type=virt,accel=hvf:kvm:tcg -cpu cortex-a57 -smp 2 -m 6G -device virtio-net,netdev=user.0,addr=0x03 -netdev user,id=user.0,hostfwd=tcp::2847-:22 -display none -monitor none -serial file:/tmp/cross-platform-actions.log -boot strict=off -bios /home/runner/work/_temp/97ba73e2-97f1-4f3b-8131-508d13bb6f87/share/qemu/uefi.fd -device virtio-blk-pci,drive=drive0,bootindex=0 -drive if=none,file=/home/runner/work/_temp/e5d8a428-2d47-4472-9c68-ef83326056a4/disk.raw,id=drive0,cache=unsafe,discard=ignore,format=raw -device virtio-blk-pci,drive=drive1,bootindex=1 -drive if=none,file=/tmp/resourcesoSCR4c/res.raw,id=drive1,cache=unsafe,discard=ignore,format=raw
FreeBSD x86-64:
qemu-system-x86_64 -daemonize -machine type=q35,accel=hvf:kvm:tcg -cpu max -smp 2 -m 6G -device virtio-net,netdev=user.0,addr=0x03 -netdev user,id=user.0,hostfwd=tcp::2847-:22 -display none -monitor none -serial file:/tmp/cross-platform-actions.log -boot strict=off -bios /home/runner/work/_temp/81f72aae-ad62-42f4-9009-d17b4be5dd42/share/qemu/bios-256k.bin -device virtio-blk-pci,drive=drive0,bootindex=0 -drive if=none,file=/home/runner/work/_temp/eaa8531e-1afa-4dd8-add4-f8dd8ccdc679/disk.raw,id=drive0,cache=unsafe,discard=ignore,format=raw -device virtio-blk-pci,drive=drive1,bootindex=1 -drive if=none,file=/tmp/resourceshbwHHe/res.raw,id=drive1,cache=unsafe,discard=ignore,format=raw
Haiku x86-64:
qemu-system-x86_64 -daemonize -machine type=q35,accel=hvf:kvm:tcg -cpu max -smp 2 -m 6G -device e1000,netdev=user.0,addr=0x03 -netdev user,id=user.0,hostfwd=tcp::2847-:22,ipv6=off -display none -monitor none -serial file:/tmp/cross-platform-actions.log -boot strict=off -bios /home/runner/work/_temp/1c81c3f7-5f6e-406b-a018-cc9ba2904e45/share/qemu/bios-256k.bin -device virtio-scsi-pci -device scsi-hd,drive=drive0,bootindex=0 -drive if=none,file=/home/runner/work/_temp/1dd95890-8a61-48d8-9452-b7c9ea7f1f02/disk.raw,id=drive0,cache=unsafe,discard=ignore,format=raw -device scsi-hd,drive=drive1,bootindex=1 -drive if=none,file=/tmp/resourcesaKQ6oX/res.raw,id=drive1,cache=unsafe,discard=ignore,format=raw
OpenBSD ARM64:
qemu-system-aarch64 -daemonize -machine type=virt,accel=hvf:kvm:tcg -cpu cortex-a57 -smp 2 -m 6G -device virtio-net,netdev=user.0,addr=0x03 -netdev user,id=user.0,hostfwd=tcp::2847-:22 -display none -monitor none -serial file:/tmp/cross-platform-actions.log -boot strict=off -bios /home/runner/work/_temp/459a45b5-512f-42dd-a65d-7dc7edf8f4f5/share/qemu/linaro_uefi.fd -device virtio-scsi-pci -device scsi-hd,drive=drive0,bootindex=0 -drive if=none,file=/home/runner/work/_temp/36700db3-de5b-4d7e-8f4d-ece7ad9fb672/disk.raw,id=drive0,cache=unsafe,discard=ignore,format=raw -device scsi-hd,drive=drive1,bootindex=1 -drive if=none,file=/tmp/resourcesmbqhxp/res.raw,id=drive1,cache=unsafe,discard=ignore,format=raw
OpenBSD x86-64:
qemu-system-x86_64 -daemonize -machine type=q35,accel=hvf:kvm:tcg -cpu max,-pdpe1gb -smp 2 -m 6G -device e1000,netdev=user.0,addr=0x03 -netdev user,id=user.0,hostfwd=tcp::2847-:22 -display none -monitor none -serial file:/tmp/cross-platform-actions.log -boot strict=off -drive if=pflash,format=raw,unit=0,file=/home/runner/work/_temp/5a0720e2-7ebb-4424-bee2-3b017cbd785f/share/qemu/uefi.fd,readonly=on -device virtio-scsi-pci -device scsi-hd,drive=drive0,bootindex=0 -drive if=none,file=/home/runner/work/_temp/0a8dbf3d-0b16-4d72-aac2-a5ff29f24432/disk.raw,id=drive0,cache=unsafe,discard=ignore,format=raw -device scsi-hd,drive=drive1,bootindex=1 -drive if=none,file=/tmp/resources3ST4rU/res.raw,id=drive1,cache=unsafe,discard=ignore,format=raw
NetBSD x86-64:
qemu-system-x86_64 -daemonize -machine type=q35,accel=hvf:kvm:tcg -cpu max -smp 2 -m 6G -device virtio-net,netdev=user.0,addr=0x03 -netdev user,id=user.0,hostfwd=tcp::2847-:22,ipv6=off -display none -monitor none -serial file:/tmp/cross-platform-actions.log -boot strict=off -bios /home/runner/work/_temp/079f8aa3-3344-4aa9-9be1-cf392e8e5d67/share/qemu/bios-256k.bin -device virtio-scsi-pci -device scsi-hd,drive=drive0,bootindex=0 -drive if=none,file=/home/runner/work/_temp/d7b1bd3b-925a-46d5-bc06-83f807df0e43/disk.raw,id=drive0,cache=unsafe,discard=ignore,format=raw -device scsi-hd,drive=drive1,bootindex=1 -drive if=none,file=/tmp/resourcesQAKIKY/res.raw,id=drive1,cache=unsafe,discard=ignore,format=raw
NetBSD ARM64:
qemu-system-aarch64 -daemonize -machine type=virt,accel=hvf:kvm:tcg -cpu cortex-a57 -smp 2 -m 6G -device virtio-net,netdev=user.0,addr=0x03 -netdev user,id=user.0,hostfwd=tcp::2847-:22,ipv6=off -display none -monitor none -serial file:/tmp/cross-platform-actions.log -boot strict=off -bios /home/runner/work/_temp/7b80d37d-f26e-4929-a5f6-54439088bbf0/share/qemu/uefi.fd -device virtio-scsi-pci -device scsi-hd,drive=drive0,bootindex=0 -drive if=none,file=/home/runner/work/_temp/130821ce-df15-4d49-bd87-3afb5ad3d871/disk.raw,id=drive0,cache=unsafe,discard=ignore,format=raw -device scsi-hd,drive=drive1,bootindex=1 -drive if=none,file=/tmp/resourcest4EHJ5/res.raw,id=drive1,cache=unsafe,discard=ignore,format=raw
OmniOS x86-64:
qemu-system-x86_64 -daemonize -machine type=q35,accel=hvf:kvm:tcg -cpu max -smp 2 -m 6G -device virtio-net,netdev=user.0,addr=0x03 -netdev user,id=user.0,hostfwd=tcp::2847-:22 -display none -monitor none -serial file:/tmp/cross-platform-actions.log -boot strict=off -bios /home/runner/work/_temp/f78ca417-c6a2-47c9-9599-3ae3a4e27de8/share/qemu/bios-256k.bin -device virtio-blk,drive=drive0,bootindex=0,addr=0x02 -drive if=none,file=/home/runner/work/_temp/121ec9a3-7e21-45b9-b92a-e6327bde49a5/disk.raw,id=drive0,cache=unsafe,discard=ignore,format=raw

Note, the above commands uses the RAW format for the disk, but this command
should use the qcow2 format, as previously specified. Don't use the -daemonize
flag, instead use the -nographic flag to make the command interactive. Don't
use the `-serial` flag. Use two spaces for indentation.

* All URLs provided (freebsd-builder, resources, etc.) are under
https://github.com/cross-platform-actions. We will use this base URL.


* Tarball Structure:
    Nested. The tree output you provided earlier shows the tarballs contain a top-level directory (e.g., qemu-system-x86_64-linux/).
    *   Strategy: We will use tar --strip-components=1 -C <destination> to extract the contents directly into our bin and share cache directories, avoiding the extra nesting layer

* Firmware Path:
    Explicit Paths. The specific QEMU commands you listed use explicit paths for the BIOS/EFI files (e.g., -bios .../share/qemu/uefi.fd).
    *   Strategy: The script will resolve the absolute path to the extracted share/qemu directory and pass specific file paths (e.g., $QVM_CACHE/share/qemu/uefi.fd) to the -bios or -drive if=pflash arguments, exactly as shown in your examples.

*  Dry Run: Add a debug mode to print the QEMU command instead of running it, to verify it matches your requirements exactly.

Write a full software specification. Write it out to a file: spec.md
