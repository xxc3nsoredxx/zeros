#!/bin/bash

BINVERSION="2.32-r1"
GCCVERSION="9.2.0-r2"
TARGET="i386-elf"
REPO="cross-$TARGET"
REPODIR="/var/db/repos/$REPO"
REPOSCONF="/etc/portage/repos.conf"
PORT_LOG="/var/log/portage/$REPO-*.log"

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
    crossdev --stage1 --binutils $BINVERSION --gcc $GCCVERSION --target $TARGET --portage -a --portage -v
else
    echo "Repo $REPO exists"
fi
