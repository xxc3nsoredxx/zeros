/* ENTRY(kstart) */
/* OUTPUT_FORMAT(elf32-i386) */
OUTPUT_FORMAT(binary)

SECTIONS
{
    /* Address where the text + data segments start */
    _mb_load_addr = .;
    /**
     * Multiboot header is at the front of the image
     * Requires 4 byte alignment
     */
    .multiboot ALIGN(4) :
    {
        *kernel0.o (.multiboot)
    }
    /**
     * Multiboot loader jumps to address of kernel0/kstart
     * Align it to 4KiB boundaries, start at 9MiB
     */
    . = 0x00900000;
    /* Load GDT before code */
    .gdt ALIGN(4) :
    {
        *kernel0.o (.gdt)
    }
    .text 0x00001000 :
    AT(ADDR(.gdt) + 4K)
    {
        /* Have the kernel initialization code first */
        _mb_entry_addr = LOADADDR(.text);
        *kernel0.o (.text)
        * (.text)
    }
    /* Readonly data */
    .rodata :
    {
        * (.rodata)
    }
    /* Initialized data */
    .data :
    {
        * (.data)
    }
    /* Address of code + data end */
    _mb_load_end_addr = LOADADDR(.data) + SIZEOF(.data);
    /* Uninitialized data */
    .bss :
    {
        * (.bss)
    }
    /* End of .bss */
    _mb_bss_end_addr = MIN(1, SIZEOF(.bss)) * LOADADDR(.bss) + SIZEOF(.bss);
}
