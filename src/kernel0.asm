    ; Kernel 0
    ; Multiboot header is defined at the bottom of this file
    bits    32

%include    "gdt.hs"

global  kstart          ; Make kstart visible
extern  kmain           ; kmain defined in kernel1.asm

section .text
; Kernel entry point
kstart:
    cli                 ; Disable interrupts
                        ; Will be reenabled by kernel later
    lgdt    [gdt_desc]  ; Load the GDT
    jmp 0x08:.reload_seg    ; The jump reloads CS
.reload_seg:
    mov ax, 0x10        ; Set the proper values for other segments
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, stack      ; Set up the stack pointer
    call    kmain       ; Kernel main function
    hlt                 ; Halt the CPU after leaving kernel

section .gdt progbits alloc noexec nowrite align=4
gdt:                    ; The start of the GDT
.gdt_null:              ; Null selector
    dq  0               ; All zeros
.gdt_code:              ; Code selector
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot, dw GDT_LIM_BOT
        at gdt_entry_t.base_bot, dw GDT_BASE_BOT
        at gdt_entry_t.base_top_bot, db GDT_BASE_TOP_BOT
        at gdt_entry_t.access, db GDT_ACCESS_CODE
        at gdt_entry_t.flags_lim, db GDT_FLAGS_LIM
        at gdt_entry_t.base_top, db GDT_BASE_TOP
    iend
.gdt_data:              ; Data selector
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot, dw GDT_LIM_BOT
        at gdt_entry_t.base_bot, dw GDT_BASE_BOT
        at gdt_entry_t.base_top_bot, db GDT_BASE_TOP_BOT
        at gdt_entry_t.access, db GDT_ACCESS_DATA
        at gdt_entry_t.flags_lim, db GDT_FLAGS_LIM
        at gdt_entry_t.base_top, db GDT_BASE_TOP
    iend
.end:                   ; End of GDT
gdt_desc:               ; GDT descriptor
    istruc  gdt_desc_t
        at gdt_desc_t.size, dw gdt.end - gdt
        at gdt_desc_t.gdt, dd gdt
    iend

section .stack nobits alloc noexec write align=16
stack_bot:
    resb    8 * 1024 * 1024 ; 8MiB stack
stack:                  ; Stack pointer at highest address

section .multiboot progbits align=4
    ; helper symbols defined by the linker
    extern _mb_load_addr        ; Multiboot code + data load start address
    extern _mb_load_end_addr    ; Multiboot code + data load ends address
    extern _mb_bss_end_addr     ; Multiboot bss (+stack) end address

    ; Multiboot header structure, 4 byte aligned
    struc   mb_header_t
        .magic: resd 1  ; Multiboot identifier
            alignb  4
        .flags: resd 1  ; Request features
            alignb  4
        .check: resd 1  ; Checksum, (magic + flags) + checksum = 0
            alignb  4
        .header_addr:   resd 1  ; Address of header start
            alignb  4
        .load_addr: resd 1  ; Address of code + data start
            alignb  4
        .load_end_addr: resd 1  ; Address of code + dara end
            alignb  4
        .bss_end_addr:  resd 1  ; Address of end of bss (and stack for us)
            alignb  4
        .entry_addr:    resd 1  ; Address of the entry point
            alignb  4
        .mode_type: resd 1  ; Graphics mode type
            alignb  4
        .width: resd 1  ; Screen width
            alignb  4
        .height:    resd 1  ; Screen height
            alignb  4
        .depth: resd 1  ; Pixel depth
            alignb  4
    endstruc

%assign MB_MAGIC 0x1BADB002
%assign MB_FLAGS 0x00010003 ; Bit 2: video mode
                            ; Bit 16: use addresses in header
%assign MB_LOAD_END_ADDR 0  ; Loads the rest of the file
%assign MB_GRAPHICS_MODE 1  ; Text mode
%assign MB_SCR_WIDTH    80  ; Screen width in chars
%assign MB_SCR_HEIGHT   25  ; Screen height in chars
%assign MB_PIXEL_DEPTH  0   ; Pixel depth

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
        at mb_header_t.mode_type, dd MB_GRAPHICS_MODE
        at mb_header_t.width, dd MB_SCR_WIDTH
        at mb_header_t.height, dd MB_SCR_HEIGHT
        at mb_header_t.depth, dd MB_PIXEL_DEPTH
    iend
