SRC = src
INC = include
BIN = bin
OBJ = obj
AS = nasm
AFLAGS = -f elf32 -Wall -Werror -I $(INC)/
LD = i386-elf-ld
OBJS = $(addprefix $(OBJ)/,kernel0.o kernel1.o vga.o)

.PHONY: all
all: $(BIN)/kernel.bin

$(BIN)/kernel.bin: $(OBJS)
	$(LD) -T $(SRC)/kernel.ld $^ -o $@ -M

$(OBJ)/kernel0.o: $(SRC)/kernel0.asm
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/kernel1.o: $(SRC)/kernel1.asm $(INC)/vga.hs
	$(AS) $(AFLAGS) $< -o $@

$(OBJ)/vga.o: $(SRC)/vga.asm $(INC)/vga.hs
	$(AS) $(AFLAGS) $< -o $@
