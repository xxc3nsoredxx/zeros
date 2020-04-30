#!/bin/bash

BINVERSION="2.32-r1"
GCCVERSION="9.2.0-r2"
TARGET="i386-elf"
REPO="cross-$TARGET"
REPODIR="/var/db/repos/$REPO"
REPOSCONF="/etc/portage/repos.conf"
PORT_LOG="/var/log/portage/$REPO-*.log"
ISO="zeros.iso"
MOUNT="/mnt"
LOOP1=""
LOOP2=""

# Detect root
if [ $(id -u) -ne 0 ]; then
    echo "Need superuser privileges!"
    # Restart script with higher privs
    # sudoer's username is automatically saved in $SUDO_USER
    sudo $0
    exit
fi

# Detect $TARGET toolchain, creating if needed
if [ ! -d $REPODIR ]; then
    echo "Repo $REPO doesn't exist, creating..."
    mkdir -p $REPODIR/{profiles,metadata}
    echo "cross-$TARGET" > $REPODIR/profiles/repo_name
    echo 'masters = gentoo' > $REPODIR/metadata/layout.conf
    echo "[$REPO]" > $REPOSCONF/$REPO.conf
    echo "location = $REPODIR" >> $REPOSCONF/$REPO.conf
    echo 'priority = 10' >> $REPOSCONF/$REPO.conf
    echo 'masters = gentoo' >> $REPOSCONF/$REPO.conf
    echo 'auto-sync = no' >> $REPOSCONF/$REPO.conf
    chown -R portage:portage $REPODIR

    # Create the cross-compiler
    echo "Creating cross-compiler for $TARGET..."
    echo "binutils version: $BINVERSION"
    echo "GCC version: $GCCVERSION"
    crossdev --stage1 --binutils $BINVERSION --gcc $GCCVERSION \
        --target $TARGET --portage -a --portage -v
else
    echo "Repo $REPO exists"
fi

if [ "$(losetup -j $ISO)" ]; then
    echo "ISO already has loopback devices"
    LOOP1="$(losetup -l -n -O NAME -j $ISO | sort | head -1)"
    LOOP2="$(losetup -l -n -O NAME -j $ISO | sort | tail -1)"
else
    echo "Creating loopback devices for ISO"
    LOOP1="$(losetup -f)"
    losetup $LOOP1 $ISO
    LOOP2="$(losetup -f)"
    losetup $LOOP2 $ISO -o 1048576
fi

if [ "$(findmnt -n -o TARGET $LOOP2)" ]; then
    echo "ISO already mounted"
else
    echo "Mounting ISO at $MOUNT"
    mount $LOOP2 $MOUNT
fi
