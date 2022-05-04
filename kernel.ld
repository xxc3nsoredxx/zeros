LD_FEATURE("SANE_EXPR")
OUTPUT_FORMAT(binary)
OUTPUT_ARCH(i386)

SECTIONS
{
    /* OS stuff starts at virtual address 10 MiB */
    _mem_base = 0x00a00000;
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
    /* Virtual address of start of code */
    /* _code_vma_start = 0x1000; */
    _code_vma_start = 0x1000;

    /**
     * Multiboot header is at the front of the image
     * Requires 4 byte alignment
     */
    .multiboot ALIGN(4) :
    {
        *kernel0.o (.multiboot)
    } =0x00

    /**
     * Load GDT first
     * VMA: 0xa00000
     *   Physical address because the segments aren't set up yet
     * LDA: Right after multiboot header
     */
    _gdt_start = _mem_base;
    .gdt _gdt_start : AT(SIZEOF(.multiboot))
    {
        *kernel0.o (.gdt)
    } =0x00

    /**
     * Load IDT after GDT
     * 256 * 8 B = 2 KiB long
     * VMA: [GDT size]
     *   Segments will have been set up once IDT structures are accessed
     * LDA: Right after GDT
     * Align to 16 B
     */
    . = ALIGN(SIZEOF(.gdt), 16);
    .idt ALIGN(16) : AT(ALIGN(LOADADDR(.gdt) + SIZEOF(.gdt), 16))
    {
        _idt_start = ABSOLUTE(_mem_base + .);
        *kernel0.o (.idt)
    } =0x00

    /**
     * Load task-state segments right before code
     * VMA: 0x1000 - n * [TSS size aligned to 16 B]
     *      0x1000 - n * 0x70
     * LDA: Right before code
     */
    _total_tss_size = 4 * 0x70;
    _tss_start = _code_vma_start - _total_tss_size;
    .tss _tss_start : AT(LOADADDR(.gdt) + 4K - _total_tss_size)
    {
        *kernel0.o (.tss)
    } =0x00

    /**
     * VMA: 0x1000 (4 KiB)
     * LDA: [GDT + 4 KiB]
     */
    .text _code_vma_start : AT(LOADADDR(.gdt) + 4K)
    {
        /* Multiboot loader jumps to address of kernel0/kstart */
        *kernel0.o (.text)
        * (.text)
    } =0x90

    /* Readonly data */
    .rodata ALIGN(16) :
    {
        * (.rodata)
    } =0x00

    /* Initialized data */
    .data ALIGN(16) :
    {
        * (.data)
    } =0x00

    /* Uninitialized data */
    .bss ALIGN(16) :
    {
        * (.bss)
    } =0x00
}
