#! /bin/bash

TARGET='i386-elf'
GDB="$(which $TARGET-gdb)" || exit 1
PEDA='/usr/lib/peda/peda.py'

if [ -f $PEDA ]; then
    $GDB --nx -ix ./.gdbinit -iex 'target remote :1234'
else
    $GDB -iex 'target remote :1234'
fi
