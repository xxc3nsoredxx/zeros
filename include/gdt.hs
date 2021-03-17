%ifndef GDT_HS_20200318_232100
%define GDT_HS_20200318_232100

extern _gdt_start

struc   gdt_entry_t
    .limit_bot: resw 1      ; Bottom word of segment limit
        alignb  2
    .base_bot:  resw 1      ; Bottom word of segment base address
        alignb  2
    .base_top_bot:  resb 1  ; Bottom byte of top word of base
        alignb  1
    .access:    resb 1      ; Access byte
        alignb  1           ; 7:    Present: always 1
                            ; 5-6:  Ring level: 0 (kernel), 3 (user)
                            ; 4:    Type: 0 (system), 1 (code/data)
                            ; 3:    Execute: 0 (no exec), 1 (exec)
                            ; 2:    Direction (data): 0 (grow up), 1 (grow down)
                            ; 2:    Conform (code): 0 (ring), 1 (equal/lower ring)
                            ; 1:    Readable (code): 0 (no), 1 (yes) (never write)
                            ; 1:    Writable (data): 0 (no), 1 (yes) (always read)
                            ; 0:    Accessed: 0 (set to 1 by CPU when accessed)
    .flags_lim: resb 1      ; Flags and top nybble of limit
        alignb  1           ; 7:    Granularity: 0 (bytewise), 1 (4KiB pagewise)
                            ; 6:    Size: 0 (16 bit), 1 (32 bit)
                            ; 4:    Reserved for OS: 0 (unused)
                            ; 5:    Reserved: 0
                            ; 0-3:  Limit
    .base_top:  resb 1      ; Top byte of top word of base
        alignb  1
endstruc

struc   gdt_desc_t
    .size:  resw 1          ; Size of GDT - 1
        alignb  2
    .gdt:   resd 1          ; Address of GDT
        alignb  4
endstruc

%assign GDT_VRAM_LIM_BOT    0xFFFF  ; Set limit to 64KiB (relative to base)
                                    ; (0 -> 0x0FFFF)
%assign GDT_VRAM_BASE_BOT   0x8000  ; VRAM at 0x000B8000
%assign GDT_VRAM_BASE_TOP_BOT   0x0B
%assign GDT_VRAM_ACCESS     0b10010010
;                             |\|||||+- Set by CPU
;                             | ||||+-- Writable
;                             | |||+--- Grows up
;                             | ||+---- Not executable
;                             | |+----- Code/Data (data)
;                             | +------ Ring 0
;                             +-------- Present
%assign GDT_VRAM_FLAGS_LIM  0b01000000
;                             ||||+---- Top nybble of limit
;                             |||+----- OS reserved (unused)
;                             ||+------ Reserved
;                             |+------- 32 bit
;                             +-------- Bytewise
%assign GDT_VRAM_BASE_TOP   0
%assign GDT_STACK_LIM_BOT   0x00FF  ; Top of stack (highest invalid addr < base)
                                    ; Base - length - 1
                                    ; = 9MiB - 8MiB - 1
                                    ; = 1MiB - 1
                                    ; = 0x000FFFFF
                                    ; = 0x000FF * 4KiB
%assign GDT_STACK_BASE_BOT  0xFFFF  ; Base address (bottom of stack)
%assign GDT_STACK_BASE_TOP_BOT  0x8F
                                    ; GDT base = start address + length - 4GiB
                                    ; = 1MiB + 8MiB - 4GiB
                                    ; = 0x00100000 + 0x00800000 - 0x1 00000000
                                    ; = 0x0 00900000 - 0x1 00000000
                                    ; = 0x0 00900000 + 0xF 00000000
                                    ; = 0xF 00900000
                                    ; = 0xF 008FFFFF
%assign GDT_STACK_ACCESS    0b10010110
;                             |\|||||+- Set by CPU
;                             | ||||+-- Readable
;                             | |||+--- Grows down
;                             | ||+---- Not executable
;                             | |+----- Code/Data (data)
;                             | +------ Ring 0
;                             +-------- Present
%assign GDT_STACK_FLAGS_LIM 0b11000000
;                             ||||+---- Top nybble of limit
;                             |||+----- OS reserved (unused)
;                             ||+------ Reserved
;                             |+------- 32 bit
;                             +-------- Pagewise
%assign GDT_STACK_BASE_TOP  0
%assign GDT_CODE_LIM_BOT    0xFFFF  ; Set limit to 4GiB (relative to base)
                                    ; (0 -> 0xFFFFF) * 4KiB pages
                                    ; = 0x100000 * 4KiB
                                    ; = 2^20 * 4KiB
                                    ; = 1Mi * 4KiB
                                    ; = 4GiB (really 9MiB + 4GiB)
%assign GDT_CODE_BASE_BOT   0       ; Code base: 0x00900000
%assign GDT_CODE_BASE_TOP_BOT   0x90
%assign GDT_CODE_ACCESS     0b10011010
;                             |\|||||+- Set by CPU
;                             | ||||+-- Readable
;                             | |||+--- Specified ring only
;                             | ||+---- Executable
;                             | |+----- Code/Data (code)
;                             | +------ Ring 0
;                             +-------- Present
%assign GDT_CODE_FLAGS_LIM  0b11001111
;                             ||||+---- Top nybble of limit
;                             |||+----- OS reserved (unused)
;                             ||+------ Reserved
;                             |+------- 32 bit
;                             +-------- Pagewise
%assign GDT_CODE_BASE_TOP   0
%assign GDT_DATA_LIM_BOT    0xFFFF  ; Set limit to 4GiB (relative to base)
                                    ; (0 -> 0xFFFFF) * 4KiB pages
                                    ; = 0x100000 * 4KiB
                                    ; = 2^20 * 4KiB
                                    ; = 1Mi * 4KiB
                                    ; = 4GiB (really 9MiB + 4GiB)
%assign GDT_DATA_BASE_BOT   0       ; Data base: 0x00900000
%assign GDT_DATA_BASE_TOP_BOT   0x90
%assign GDT_DATA_ACCESS     0b10010010
;                             |\|||||+- Set by CPU
;                             | ||||+-- Writable
;                             | |||+--- Grows up
;                             | ||+---- Not executable
;                             | |+----- Code/Data (data)
;                             | +------ Ring 0
;                             +-------- Present
%assign GDT_DATA_FLAGS_LIM  0b11001111
;                             ||||+---- Top nybble of limit
;                             |||+----- OS reserved (unused)
;                             ||+------ Reserved
;                             |+------- 32 bit
;                             +-------- Pagewise
%assign GDT_DATA_BASE_TOP   0

%assign GDT_VRAM_INDEX      0x08
%assign GDT_STACK_INDEX     0x10
%assign GDT_CODE_INDEX      0x18
%assign GDT_DATA_INDEX      0x20

%endif

; vim: filetype=asm:syntax=nasm:
