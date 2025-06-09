#!/usr/bin/env bash
# 
# SPDX-FileCopyrightText: © 2020-2025 Serpent OS Developers
# SPDX-FileCopyrightText: © 2025- AerynOS Developers
# SPDX-License-Identifier: MPL-2.0
#

# create-aosroot.sh:
# script for conveniently creating a clean /var/lib/machines/aosroot/
# directory suitable for use as the root in AerynOS systemd-nspawn
# container or linux-kvm kernel driven qemu-kvm virtual machine.

source ./basic-setup.sh

showHelp() {
    cat <<EOF

----

You can now start a systemd-nspawn container with:

 sudo systemd-nspawn --bind=${BOULDERCACHE}/ -D ${SOSROOT}/ -b
  OR
 sudo ./boot-systemd-nspawn-container.sh (rewritten on each ./create-aosroot.sh run)

Do a 'systemctl poweroff' inside the container to shut it down.

The container can also be shut down with:

 sudo machinectl stop aosroot

in a shell outside the container.

If you want to be able to use your aosroot/ with virt-manager,
you can set the DESTDIR variable when calling ${0} like so:

    DESTDIR="/var/lib/machines/aosroot" create-aosroot.sh

EOF
}

# Make it more convenient to boot into the created sosroot/ later on
createBootScript () {
    cat <<EOF > boot-systemd-nspawn-container.sh
#!/usr/bin/env bash
#
exec sudo systemd-nspawn --bind=${BOULDERCACHE}/ -D ${AOSROOT}/ -b
EOF
}

checkPrereqs
basicSetup
showHelp
# Make it simple to boot into the created aosroot at a later point
createBootScript && chmod a+x boot-systemd-nspawn-container.sh
cleanEnv
