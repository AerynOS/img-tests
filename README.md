# Here be dragons 🔥🐉

🚨🚧🚧🚧🚨

As AerynOS is under heavy development, the image generation scripts in this repository are provided as is,
with no explicit or implied warranty or support.

If you break your computer because you used these scripts or AerynOS in its current state, you get to keep both pieces.

## Build an ISO (can be used as an installer)

    just compression=zstd3 build
    # run 'just help' to see available recipes and options

## Build and boot an ISO (you may need to update the UEFI firmware path)

    just firmware="/usr/share/edk2-ovmf/x64/OVMF_CODE.fd" build-and-boot

## Manually create an installable / booting desktop image

    cd desktop/
    sudo ./img.sh
    truncate -s 10G disk.img
    qemu-system-x86_64 -enable-kvm -m 4096m -cdrom aosvalidator.iso -drive if=pflash,format=raw,readonly=on,file=/usr/share/qemu/edk2-x86_64-code.fd -device virtio-vga-gl -display sdl,gl=on -cpu host -serial stdio -device virtio-blk-pci,drive=main -drive id=main,if=none,file=disk.img,format=raw -boot c

Drop the `-boot c` after you've booted the VM, formatted with `fdisk` and installed with `sudo lichen`
