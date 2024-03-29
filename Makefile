vpath %.asm src
vpath %.ld src
vpath %.hs include
vpath %.o obj
vpath %.bin bin
SRC = src
INC = include
OBJ = obj
BIN = bin
MOUNT = /mnt
AS = nasm
AFLAGS = -f elf32 -w+all -w+error -w-unknown-warning -i $(INC)/
LD = i386-elf-ld
LFLAGS = -Map=./ --fatal-warnings
QEMU = qemu-system-i386
QFLAGS = -curses -drive file=zeros.iso,format=raw -s -enable-kvm
OBJS  = ext2.o ide.o interrupts.o kb.o kernel0.o kernel1.o mbr.o panic.o sys.o
OBJS += tests.o vga.o

.PHONY: all relink install run
all: kernel.bin

relink: $(OBJS)
	$(LD) $(LFLAGS) -T kernel.ld $^ -o $(BIN)/kernel.bin

install: all
	cp $(BIN)/kernel.bin $(MOUNT)/boot/
	sync $(MOUNT)

run:
	$(QEMU) $(QFLAGS)

runx:
	command startx ./qemu_zeros.xinitrc -- vt$(shell tty | sed -e 's|/dev/tty||')

$(BIN)/kernel.bin: $(OBJS)
	$(LD) $(LFLAGS) -T kernel.ld $^ -o $@

$(OBJ)/ext2.o: ext2.asm ext2.hs ide.hs mbr.hs misc.hs sys.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/ide.o: ide.asm ide.hs misc.hs sys.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/interrupts.o: interrupts.asm idt.hs kb.hs panic.hs vga.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/kb.o: kb.asm kb.hs idt.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/kernel0.o: kernel0.asm gdt.hs ide.hs idt.hs kb.hs multiboot.hs tss.hs vga.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/kernel1.o: kernel1.asm ext2.hs ide.hs misc.hs panic.hs sys.hs tests.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/mbr.o: mbr.asm mbr.hs ide.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/panic.o: panic.asm panic.hs misc.hs sys.hs vga.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/sys.o: sys.asm sys.hs kb.hs vga.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/tests.o: tests.asm tests.hs gdt.hs misc.hs panic.hs sys.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/vga.o: vga.asm vga.hs
	$(AS) $(AFLAGS) $< -o $@
