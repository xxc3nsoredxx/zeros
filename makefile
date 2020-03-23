SRC = src
INC = include
BIN = bin
OBJ = obj
AS = nasm
AFLAGS = -f elf32 -Wall -Werror -I $(INC)/
LD = i386-elf-ld
LFLAGS = -M --fatal-warnings
QEMU = qemu-system-i386
QFLAGS = -drive file=zeros.iso,format=raw
OBJS = $(addprefix $(OBJ)/,kernel0.o kernel1.o vga.o)

.PHONY: all relink install run
all: $(BIN)/kernel.bin

relink:
	$(LD) $(LFLAGS) -T $(SRC)/kernel.ld $(OBJS) -o $(BIN)/kernel.bin

install: all
	cp $(BIN)/kernel.bin /mnt/boot/
	sync

run:
	$(QEMU) $(QFLAGS)

$(BIN)/kernel.bin: $(OBJS)
	$(LD) $(LFLAGS) -T $(SRC)/kernel.ld $^ -o $@

$(OBJ)/kernel0.o: $(SRC)/kernel0.asm $(INC)/gdt.hs $(INC)/multiboot.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/kernel1.o: $(SRC)/kernel1.asm $(INC)/vga.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/vga.o: $(SRC)/vga.asm $(INC)/vga.hs $(INC)/gdt.hs
	$(AS) $(AFLAGS) $< -o $@
