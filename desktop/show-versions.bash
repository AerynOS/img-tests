#!/usr/bin/env bash
#
# List "interesting" packages in AerynOS

MOSS=$(command -v moss)
if [[ ! -x "${MOSS}" ]]
then
    echo -e "\nThis script requires a working moss executable to run.\n"
    exit 1
fi

echo -e "\nUsing '${MOSS}' to list versions:\n"


desktops=(
    '\nDesktop_environments:\n'
    cosmic-desktop
    plasma-desktop
    gnome-shell
)
wl_compositors=(
    '\nWayland_compositors:\n'
    mangowc
    niri
    sway
)
wl_components=(
    '\nWayland_components:\n'
    dankmaterialshell
    eiipm
    ewwii
    greetd
    ironbar
    lucien
    riftbar
    waybar
    wl-clipboard-rs
    xwayland-satellite
)
terminal_emulators=(
    '\nTerminal_emulators:\n'
    alacritty
    foot
    ghostty
    kitty
    yakuake
)
editors=(
    '\nTerminal_editors:\n'
    fresh
    gawk
    helix
    kakoune
    micro
    nano
    sed
    vim
    vscode-bin
    vscodium
    zed
)
system_shells=(
    '\nSystem_shells:\n'
    bash
    brush
    dash
    fish
    nushell
    zsh
)
container_stuff=(
    '\nContainer_tools:\n'
    distrobox
    docker
)
toolchains=(
    '\nToolchains_and_interpreters:\n'
    binutils
    clang
    gcc
    golang
    nodejs
    perl
    python
    roswell
    ruby
    rust
)
core_stacks=(
    '\nCore_system:\n'
    coreutils
    dracut
    glibc
    linux-desktop
    linux-tools
    mesa
    pipewire
    uutils-coreutils
)
nvidia=(
    '\nNVIDIA_drivers:\n'
    linux-firmware-nvidia-graphics
    nvidia-graphics-driver
    nvidia-open-gpu-kernel-modules
)
rust_tools=(
    '\nRust_tools:\n'
    atuin
    bat
    bottom
    cpx
    delta
    eza
    fd
    jujutsu
    just
    lsd
    netavark
    ntpd-rs
    powerstation
    samply
    starship
    scx-scheds
    scx-tools
    ripgrep
    thin-provisioning-tools
    tlrc
    zellij
    zola
    zoxide
    yazi
    zram-generator
)


for p in \
${desktops[@]} ${wl_compositors[@]} ${wl_components[@]} \
${terminal_emulators[@]} ${editors[@]} ${system_shells[@]} \
${container_stuff[@]} ${core_stack[@]} ${nvidia[@]} \
${toolchains[@]} ${rust_tools[@]}
do
    # in case of several versions, take the one that matches the lowest repo priority
    version="$(moss info "${p}" |gawk '/Version/ { print $2 }' |head -n1)"
    echo -e "${p} ${version}" || echo -e "!! ${p} not found ??"
done
