    ; Kernel panic screen
    bits    32

%include "panic.hs"
%include "sys.hs"
%include "vga.hs"

section .text
; NO_RET panic (u32 panic_selector, u32? error)
; Display a kernel panic screen
panic:
    pop eax                 ; Remove panic call-saved eip from the stack

    push CURSOR_DISABLE
    call cursor_state

    ; Set the color scheme and clear
    mov al, [PANIC_COLOR]
    mov [color], al
    call clear

    ; Get the address of the correct struct
    pop ebx
    mov ebx, [.panics + ebx*4]

    ; Print panic title
    push DWORD [ebx + panic_info_t.title_len]
    push DWORD [ebx + panic_info_t.title]
    push DWORD title_len
    push title
    call printf

    ; Test for error code
    cmp BYTE [ebx + panic_info_t.has_error], 0
    jz  .skip_error
    ; Print error message (code already on stack)
    push DWORD [ebx + panic_info_t.error_msg_len]
    push DWORD [ebx + panic_info_t.error_msg]
    push DWORD error_len
    push error
    call printf

.skip_error:
    ; Print the register info (already on the stack thanks to the exception)
    push DWORD reg_info_len
    push reg_info
    call printf

    ; Freeze the machine
.hang:
    hlt
    pause
    jmp .hang

; Lookup table for panic info structs
.panics:
    dd  ud_info
    dd  df_info
    dd  np_idt_info
    dd  np_gdt_info
    dd  gp_idt_info
    dd  gp_gdt_info
    dd  gp_gen_info

section .rodata
PANIC_COLOR:
    db  VGA_BG_WHITE | VGA_FG_L_RED

; Common strings
title:
    db  'PANIC: %s', 0x0a
title_len:  equ $ - title
reg_info:
    db  '   EIP:    %x', 0x0a
    db  '    CS:    %x', 0x0a
    db  'EFLAGS:    %x'
reg_info_len:   equ $ - reg_info
error:
    db  '%s: %u', 0x0a
error_len:  equ $ - error

ud_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  ud_title
        at panic_info_t.title_len,      dd  ud_title_len
        at panic_info_t.has_error,      db  0
        at panic_info_t.error_msg,      dd  0
        at panic_info_t.error_msg_len,  dd  0
    iend
ud_title:
    db  'INVALID OR UNDEFINED OPCODE'
ud_title_len: equ $ - ud_title

df_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  df_title
        at panic_info_t.title_len,      dd  df_title_len
        at panic_info_t.has_error,      db  0
        at panic_info_t.error_msg,      dd  0
        at panic_info_t.error_msg_len,  dd  0
    iend
df_title:
    db  '!!! DOUBLE FAULT !!!'
df_title_len:   equ $ - df_title

np_idt_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  np_idt_title
        at panic_info_t.title_len,      dd  np_idt_title_len
        at panic_info_t.has_error,      db  1
        at panic_info_t.error_msg,      dd  np_idt_error
        at panic_info_t.error_msg_len,  dd  np_idt_error_len
    iend
np_idt_title:
    db  'UNHANDLEABLE INTERRUPT'
np_idt_title_len:   equ $ - np_idt_title
np_idt_error:
    db  'Missing gate'
np_idt_error_len:   equ $ - np_idt_error

np_gdt_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  np_gdt_title
        at panic_info_t.title_len,      dd  np_gdt_title_len
        at panic_info_t.has_error,      db  1
        at panic_info_t.error_msg,      dd  np_gdt_error
        at panic_info_t.error_msg_len,  dd  np_gdt_error_len
    iend
np_gdt_title:
    db  'ATTEMPTTED LOAD OF INVALID SEGMENT'
np_gdt_title_len:   equ $ - np_gdt_title
np_gdt_error:
    db  'Bad selector'
np_gdt_error_len:   equ $ - np_gdt_error

gp_idt_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  gp_idt_title
        at panic_info_t.title_len,      dd  gp_idt_title_len
        at panic_info_t.has_error,      db  1
        at panic_info_t.error_msg,      dd  gp_idt_error
        at panic_info_t.error_msg_len,  dd  gp_idt_error_len
    iend
gp_idt_title:
    db  'PROTECTION VIOLATION - IDT'
gp_idt_title_len:   equ $ - gp_idt_title
gp_idt_error:
    db  'Bad gate'
gp_idt_error_len:   equ $ - gp_idt_error

gp_gdt_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  gp_gdt_title
        at panic_info_t.title_len,      dd  gp_gdt_title_len
        at panic_info_t.has_error,      db  1
        at panic_info_t.error_msg,      dd  gp_gdt_error
        at panic_info_t.error_msg_len,  dd  gp_gdt_error_len
    iend
gp_gdt_title:
    db  'PROTECTION VIOLATION - GDT'
gp_gdt_title_len:   equ $ - gp_gdt_title
gp_gdt_error:
    db  'Bad selector'
gp_gdt_error_len:   equ $ - gp_gdt_error

gp_gen_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  gp_gen_title
        at panic_info_t.title_len,      dd  gp_gen_title_len
        at panic_info_t.has_error,      db  0
        at panic_info_t.error_msg,      dd  0
        at panic_info_t.error_msg_len,  dd  0
    iend
gp_gen_title:
    db  'PROTECTION VIOLATION'
gp_gen_title_len: equ $ - gp_gen_title
