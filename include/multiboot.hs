%ifndef MULTIBOOT_HS_20200318_233525
%define MULTIBOOT_HS_20200318_233525

; helper symbols defined by the linker
extern  _mb_load_addr   ; Multiboot code + data load start address
extern  _mb_load_end_addr   ; Multiboot code + data load ends address
extern  _mb_bss_end_addr    ; Multiboot bss (+stack) end address
extern  _mb_entry_addr  ; .text section's load address

; Multiboot header structure, 4 byte aligned
struc   mb_header_t
    .magic: resd 1      ; Multiboot identifier
        alignb  4
    .flags: resd 1      ; Request features
        alignb  4
    .check: resd 1      ; Checksum, (magic + flags) + checksum = 0
        alignb  4
    .header_addr:   resd 1  ; Address of header start
        alignb  4
    .load_addr: resd 1  ; Address of code + data start
        alignb  4
    .load_end_addr: resd 1  ; Address of code + data end
        alignb  4
    .bss_end_addr:  resd 1  ; Address of end of bss (and stack for us)
        alignb  4
    .entry_addr:    resd 1  ; Address of the entry point
        alignb  4
    .mode_type: resd 1  ; Graphics mode type
        alignb  4
    .width: resd 1      ; Screen width
        alignb  4
    .height:    resd 1  ; Screen height
        alignb  4
    .depth: resd 1      ; Pixel depth
        alignb  4
endstruc

%assign MB_MAGIC 0x1BADB002
%assign MB_FLAGS 0x00010004 ; Bit 2: video mode
                            ; Bit 16: use addresses in header
%assign MB_LOAD_END_ADDR 0  ; Loads the rest of the file
%assign MB_GRAPHICS_MODE 1  ; Text mode
%assign MB_SCR_WIDTH    80  ; Screen width in chars
%assign MB_SCR_HEIGHT   25  ; Screen height in chars
%assign MB_PIXEL_DEPTH  0   ; Pixel depth

%endif

; vim: filetype=asm:syntax=nasm:
