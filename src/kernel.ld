ENTRY(kstart)
/* OUTPUT_FORMAT(elf32-i386) */
OUTPUT_FORMAT(binary)

SECTIONS
{
    /* Address where the code + data starts */
    _mb_load_addr = .;
    /**
     * Multiboot header is the very first thing
     * Requires 4 byte alignment
     */
    .multiboot ALIGN(4) :
    {
        *kernel0.o (.multiboot)
    }
    /**
     * Multiboot loader jumps to address 0x00100000
     * Align it to 4KiB boundaries
     */
    . = 0x00100000;
    .text ALIGN(4K) :
    {
        /* Have the kernel initialization code first */
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
        /* Address of code + data end */
        _mb_load_end_addr = ABSOLUTE(.);
    }
    /* Uninitialized data */
    .bss :
    {
        * (.bss)
    }
    /* Stack at the very end */
    .stack ALIGN(16) :
    {
        *kernel0.o (.stack)
        /* End of .bss and stack */
        _mb_bss_end_addr = ABSOLUTE(.);
    }
}
