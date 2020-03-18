    ; Kernel 0
    ; Multiboot header is defined at the bottom of this file
    bits    32

section .text
    global  kstart  ; Make kstart visible
    extern  kmain   ; kmain defined in kernel1.asm

kstart:
    cli             ; Disable interrupts
                    ; Will be reenabled by kernel later
    mov esp, stack  ; Set up the stack pointer
    call    kmain   ; Kernel main function
    hlt             ; Halt the CPU after leaving kernel

section .stack nobits alloc noexec write align=16
stack_bot:
    resb    8 * 1024 * 1024 ; 8MiB stack
stack:              ; Stack pointer at highest address

section .multiboot progbits align=4
    ; helper symbols defined by the linker
    extern _mb_load_addr        ; Multiboot code + data load start address
    extern _mb_load_end_addr    ; Multiboot code + data load ends address
    extern _mb_bss_end_addr     ; Multiboot bss (+stack) end address

    ; Multiboot header structure, 4 byte aligned
    struc   mb_header_t
        .magic: resd 1  ; Multiboot identifier
            alignb 4
        .flags: resd 1  ; Request features
            alignb 4
        .check: resd 1  ; Checksum, (magic + flags) + checksum = 0
            alignb 4
        .header_addr: resd 1    ; Address of header start
            alignb 4
        .load_addr: resd 1      ; Address of code + data start
            alignb 4
        .load_end_addr: resd 1  ; Address of code + dara end
            alignb 4
        .bss_end_addr: resd 1   ; Address of end of bss (and stack for us)
            alignb 4
        .entry_addr: resd 1     ; Address of the entry point
            alignb 4
    endstruc

%assign MB_MAGIC 0x1BADB002
%assign MB_FLAGS 0x00010000 ; Bit 16: use addresses in header
%assign MB_LOAD_END_ADDR 0  ; Loads the rest of the file

mb_header:
    istruc  mb_header_t
        at mb_header_t.magic, dd MB_MAGIC
        at mb_header_t.flags, dd MB_FLAGS
        at mb_header_t.check, dd - (MB_MAGIC + MB_FLAGS)
        at mb_header_t.header_addr, dd mb_header
        at mb_header_t.load_addr, dd _mb_load_addr
        at mb_header_t.load_end_addr, dd _mb_load_end_addr
        at mb_header_t.bss_end_addr, dd _mb_bss_end_addr
        at mb_header_t.entry_addr, dd kstart
    iend
