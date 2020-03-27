OUTPUT_FORMAT(binary)

SECTIONS
{
    /* Address where the text + data segments start */
    _mb_load_addr = .;
    /**
     * kernel0/kstart is the entry point and also the very first bytes
     * of the .text section
     */
    _mb_entry_addr = LOADADDR(.text);
    /* Address of code + data end */
    _mb_load_end_addr = LOADADDR(.data) + SIZEOF(.data);
    /**
     * End of the .bss section
     * If the .bss section is empty, set the end address to zero, signaling
     * no .bss to multiboot
     */
    _mb_bss_end_addr = MIN(1, SIZEOF(.bss)) * LOADADDR(.bss) + SIZEOF(.bss);

    /**
     * Multiboot header is at the front of the image
     * Requires 4 byte alignment
     */
    .multiboot ALIGN(4) :
    {
        *kernel0.o (.multiboot)
    } =0x00

    /* Align it to 4KiB boundaries, start at 9MiB */
    . = 0x00900000;
    /* Load GDT before code */
    .gdt ALIGN(4) :
    {
        *kernel0.o (.gdt)
    } =0x00

    /**
     * Load IDT after GDT
     * 256 * 8B = 2KiB long
     */
    .idt SIZEOF(.gdt) : AT(LOADADDR(.gdt) + SIZEOF(.gdt))
    {
        *kernel0.o (.idt)
    } =0x00

    /**
     * .text segment begins at virtual address 0x00001000 (4KiB)
     * The physical address is 4KiB after start of GDT in RAM
     */
    .text 0x00001000 : AT(LOADADDR(.gdt) + 4K)
    {
        /* Multiboot loader jumps to address of kernel0/kstart */
        *kernel0.o (.text)
        * (.text)
    } =0x90

    /* Readonly data */
    .rodata :
    {
        * (.rodata)
    } =0x00

    /* Initialized data */
    .data :
    {
        * (.data)
    } =0x00

    /* Uninitialized data */
    .bss :
    {
        * (.bss)
    } =0x00
}
