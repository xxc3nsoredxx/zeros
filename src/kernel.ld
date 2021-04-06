LD_FEATURE("SANE_EXPR")
OUTPUT_FORMAT(binary)
OUTPUT_ARCH(i386)

SECTIONS
{
    /* OS stuff starts at virtual address 9 MiB */
    _mem_base = 0x00900000;
    /* Address where the multiboot header is to be loaded to */
    _mb_header_addr = _mem_base - SIZEOF(.multiboot);
    /* Address where the (gdt + idt +) text + data segments start */
    _mb_load_addr = _mb_header_addr;
    /* Address of code + data end */
    _mb_load_end_addr = _mb_load_addr + LOADADDR(.data) + SIZEOF(.data);
    /**
     * End of the .bss section
     * If the .bss section is empty, set the end address to zero, signaling
     * no .bss to multiboot
     */
    _mb_bss_end_addr = MIN(1, SIZEOF(.bss)) * (_mb_load_addr + LOADADDR(.bss)) + SIZEOF(.bss);
    /**
     * kernel0/kstart is the entry point and also the very first bytes
     * of the .text section
     */
    _mb_entry_addr = _mb_load_addr + LOADADDR(.text);

    /**
     * Multiboot header is at the front of the image
     * Requires 4 byte alignment
     */
    .multiboot ALIGN(4) :
    {
        *kernel0.o (.multiboot)
    } =0x00

    /**
     * Load GDT before code
     * VMA: 0x900000
     *   Physical address because the segments aren't set up yet
     * LDA: Right after multiboot header
     */
    _gdt_start = _mem_base;
    .gdt _gdt_start : AT(SIZEOF(.multiboot))
    {
        *kernel0.o (.gdt)
    } =0x00
    _gdt_end = .;

    /**
     * Load IDT after GDT
     * 256 * 8 B = 2 KiB long
     * VMA: [GDT size]
     *   Segments will have been set up once IDT structures are accessed
     * LDA: Right after GDT
     */
    . = SIZEOF(.gdt);
    .idt ALIGN(8) : AT(LOADADDR(.gdt) + SIZEOF(.gdt))
    {
        _idt_start = ABSOLUTE(_gdt_start + SIZEOF(.gdt));
        *kernel0.o (.idt)
    } =0x00

    /**
     * VMA: 0x1000 (4 KiB)
     * LDA: [GDT + 4 KiB]
     */
    .text 0x1000 : AT(LOADADDR(.gdt) + 4K)
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
