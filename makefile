vpath %.asm src
vpath %.ld src
vpath %.hs include
vpath %.o obj
vpath %.bin bin
SRC = src
INC = include
OBJ = obj
BIN = bin
AS = nasm
AFLAGS = -f elf32 -w+all -w+error -w-unknown-warning -i $(INC)/
LD = i386-elf-ld
LFLAGS = -M --fatal-warnings
QEMU = qemu-system-i386
QFLAGS = -drive file=zeros.iso,format=raw
OBJS = interrupts.o kb.o kernel0.o kernel1.o vga.o

.PHONY: all relink install run
all: kernel.bin

relink:
	$(LD) $(LFLAGS) -T $(SRC)/kernel.ld $(OBJS) -o $(BIN)/kernel.bin

install: all
	cp $(BIN)/kernel.bin /mnt/boot/
	sync

run:
	$(QEMU) $(QFLAGS)

$(BIN)/kernel.bin: $(OBJS)
	$(LD) $(LFLAGS) -T $(SRC)/kernel.ld $^ -o $@

$(OBJ)/interrupts.o: interrupts.asm idt.hs kb.hs vga.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/kb.o: kb.asm kb.hs idt.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/kernel0.o: kernel0.asm gdt.hs idt.hs kb.hs multiboot.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/kernel1.o: kernel1.asm vga.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/vga.o: vga.asm vga.hs gdt.hs
	$(AS) $(AFLAGS) $< -o $@
