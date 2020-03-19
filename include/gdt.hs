%ifndef GDT_HS_20200318_232100
%define GDT_HS_20200318_232100

struc gdt_entry_t
    .limit_bot: resw 1  ; Bottom word of segment limit
        alignb  2
    .base_bot:  resw 1  ; Bottom word of segment base address
        alignb  2
    .base_top_bot:  resb 1  ; Bottom byte of top word of base
        alignb  1
    .access:    resb 1  ; Access byte
        alignb  1       ; 7:    Present: always 1
                        ; 5-6:  Ring level: 0 (kernel), 3 (user)
                        ; 4:    Type: 0 (system), 1 (code/data)
                        ; 3:    Execute: 0 (no exec), 1 (exec)
                        ; 2:    Direction (data): 0 (grow up), 1 (grow down)
                        ; 2:    Conform (code): 0 (ring), 1 (equal/lower ring)
                        ; 1:    Readable (code): 0 (no), 1 (yes) (never write)
                        ; 1:    Writable (data): 0 (no), 1 (yes) (always read)
                        ; 0:    Accessed: 0 (set to 1 by CPU when accessed)
    .flags_lim: resb 1  ; Flags and top nybble of limit
        alignb  1       ; 7:    Granularity: 0 (bytewise), 1 (4KiB pagewise)
                        ; 6:    Size: 0 (16 bit), 1 (32 bit)
                        ; 4-5:  unset
                        ; 0-3:  Limit
    .base_top:  resb 1  ; Top byte of top word of base
        alignb  1
endstruc

struc   gdt_desc_t
    .size:  resw 1      ; Size of GDT
        alignb  2
    .gdt:   resd 1      ; Address of GDT
        alignb  4
endstruc

%assign GDT_LIM_BOT 0xFFFF
%assign GDT_BASE_BOT    0
%assign GDT_BASE_TOP_BOT    0
%assign GDT_ACCESS_CODE 0b10011010
%assign GDT_ACCESS_DATA 0b10010010
%assign GDT_FLAGS_LIM   0b11001111
%assign GDT_BASE_TOP    0

%endif
