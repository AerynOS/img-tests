# Here be dragons 🔥🐉

🚨🚧🚧🚧🚨

As AerynOS is under heavy development, the image generation scripts in this repository are provided as is,
with no explicit or implied warranty or support.

If you break your computer because you used these scripts or AerynOS in its current state, you get to keep both pieces.

## Create systemd-nspawn compatible `./aosroot` install

    ./create-aosroot.sh

## Create virt-manager/libvirtd compatible `/var/lib/machines/aosroot/` install

    DESTDIR="/var/lib/machines/aosroot" ./create-aosroot.sh

## Create virtiofs-based virt-manager VM install

    cd virt-manager-vm/
    ./create-virtio-vm.sh

## Create desktop ISO image

    cd desktop/
    sudo ./img.sh
    qemu-system-x86_64 -enable-kvm -cdrom aosvalidator.iso -bios /usr/share/edk2-ovmf/x64/OVMF.fd -m 4096m -serial stdio

## Installable / booting desktop image

    cd desktop/
    sudo ./img.sh
    truncate -s 10G disk.img
    qemu-system-x86_64 -enable-kvm -m 4096m -cdrom aosvalidator.iso -drive if=pflash,format=raw,readonly=on,file=/usr/share/qemu/edk2-x86_64-code.fd -device virtio-vga-gl -display sdl,gl=on -cpu host -serial stdio -device virtio-blk-pci,drive=main -drive id=main,if=none,file=disk.img,format=raw -boot c

Drop the `-boot c` after you've booted the VM, formatted with `fdisk` and installed with `sudo lichen`
