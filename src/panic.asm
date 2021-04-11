    ; Kernel panic screen
    bits    32

%include "panic.hs"
%include "misc.hs"
%include "sys.hs"
%include "tss.hs"
%include "vga.hs"

section .text
; void eflags_info (u32 eflags)
; Dump information about the given EFLAGS state
eflags_info:
    push ebp
    mov ebp, esp
    push ebx

    ; Save the EFLAGS
    mov ebx, DWORD [ebp + 8]

    ; Print EFLAGS in hex
    push ebx
    push DWORD eflags_len
    push eflags
    call printf

    ; Uppercase strings mean flag is set, lowercase string mean flag is clear

    ; Print status flags
    ; CMOVcc doesn't allow directly moving an address into a register, need to
    ; instead move the contents of a pointer to the strings...
    bt  ebx, 11             ; Overflow flag
    cmovc eax, [of_set]
    cmovnc eax, [of_clear]
    push DWORD of_len
    push eax
    bt  ebx, 7              ; Sign flag
    cmovc eax, [sf_set]
    cmovnc eax, [sf_clear]
    push DWORD sf_len
    push eax
    bt  ebx, 6              ; Zero flag
    cmovc eax, [zf_set]
    cmovnc eax, [zf_clear]
    push DWORD zf_len
    push eax
    bt  ebx, 4              ; Auxiliary Carry flag
    cmovc eax, [af_set]
    cmovnc eax, [af_clear]
    push DWORD af_len
    push eax
    bt  ebx, 2              ; Parity flag
    cmovc eax, [pf_set]
    cmovnc eax, [pf_clear]
    push DWORD pf_len
    push eax
    bt  ebx, 0              ; Carry flag
    cmovc eax, [cf_set]
    cmovnc eax, [cf_clear]
    push DWORD cf_len
    push eax

    push DWORD status_flags_len
    push status_flags
    call printf

    pop ebx
    mov esp, ebp
    pop ebp
    ret 4

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
    jz  .dump_task
    ; Print error message (code already on stack)
    push DWORD [ebx + panic_info_t.error_msg_len]
    push DWORD [ebx + panic_info_t.error_msg]
    push DWORD error_len
    push error
    call printf
    jmp .dump_regs

.dump_task:
    ; Test for task gate
    cmp BYTE [ebx + panic_info_t.is_task], 0
    jz  .dump_regs
    ; Print info about the previous task
    str ecx                 ; Get the curent TSS selector
    mov eax, ecx
    add ecx, 8              ; Get the read mapping
    mov fs, cx
    ; Read the backlink to get the previous TSS selector
    mov cx, WORD fs:[tss_t.backlink]
    mov ebx, ecx
    add ecx, 8              ; Get the read mapping
    mov fs, cx
    push fs

    ; Print basic info
    push DWORD fs:[tss_t.eip]
    push ebx                ; Push previous TSS
    push eax                ; Push current TSS
    push DWORD task_info1_len
    push task_info1
    call printf

    ; Print EFLAGS
    push DWORD fs:[tss_t.eflags]
    call eflags_info

    ; Print general purpose registers
    push DWORD fs:[tss_t.edi]
    push DWORD fs:[tss_t.esi]
    push DWORD fs:[tss_t.edx]
    push DWORD fs:[tss_t.ecx]
    push DWORD fs:[tss_t.esp]
    push DWORD fs:[tss_t.ebx]
    push DWORD fs:[tss_t.ebp]
    push DWORD fs:[tss_t.eax]
    push DWORD task_info2_len
    push task_info2
    call printf
    jmp .hang

.dump_regs:
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
string title
    db  'PANIC: %s', 0x0a
endstring
string error
    db  '%s: %u', 0x0a
endstring
string task_info1
    db  'Current TSS selector: %x', 0x0a
    db  'Previous TSS selector: %x', 0x0a
    db  '   EIP:    %x', 0x0a
endstring
string task_info2
    db  '   EAX:    %x  EBP:    %x', 0x0a
    db  '   EBX:    %x  ESP:    %x', 0x0a
    db  '   ECX:    %x', 0x0a
    db  '   EDX:    %x', 0x0a
    db  '   ESI:    %x', 0x0a
    db  '   EDI:    %x', 0x0a
endstring
string reg_info
    db  '   EIP:    %x', 0x0a
    db  '    CS:    %x', 0x0a
    db  'EFLAGS:    %x'
endstring

; EFLAGS strings
string eflags
    db  'EFLAGS:    %x', 0x0a
endstring
string status_flags
    db  'Status:    %s %s %s %s %s %s', 0x0a
endstring
; Strings, length, pointers to strings
cf_set_str:
    db  'CARRY'
cf_clear_str:
    db  'carry'
cf_len: equ cf_clear_str - cf_set_str
cf_set:
    dd  cf_set_str
cf_clear:
    dd  cf_clear_str
pf_set_str:
    db  'PARITY'
pf_clear_str:
    db  'parity'
pf_len: equ pf_clear_str - pf_set_str
pf_set:
    dd  pf_set_str
pf_clear:
    dd  pf_clear_str
af_set_str:
    db  'AUX_CARRY'
af_clear_str:
    db  'aux_carry'
af_len: equ af_clear_str - af_set_str
af_set:
    dd  af_set_str
af_clear:
    dd  af_clear_str
zf_set_str:
    db  'ZERO'
zf_clear_str:
    db  'zero'
zf_len: equ zf_clear_str - zf_set_str
zf_set:
    dd  zf_set_str
zf_clear:
    dd  zf_clear_str
sf_set_str:
    db  'SIGN'
sf_clear_str:
    db  'sign'
sf_len: equ sf_clear_str - sf_set_str
sf_set:
    dd  sf_set_str
sf_clear:
    dd  sf_clear_str
of_set_str:
    db  'OVERFLOW'
of_clear_str:
    db  'overflow'
of_len: equ of_clear_str - of_set_str
of_set:
    dd  of_set_str
of_clear:
    dd  of_clear_str

; Individual panic info
ud_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  ud_title
        at panic_info_t.title_len,      dd  ud_title_len
        at panic_info_t.has_error,      db  0
        at panic_info_t.is_task,        db  0
        at panic_info_t.error_msg,      dd  0
        at panic_info_t.error_msg_len,  dd  0
    iend
string ud_title
    db  'INVALID OR UNDEFINED OPCODE'
endstring

df_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  df_title
        at panic_info_t.title_len,      dd  df_title_len
        at panic_info_t.has_error,      db  0
        at panic_info_t.is_task,        db  1
        at panic_info_t.error_msg,      dd  0
        at panic_info_t.error_msg_len,  dd  0
    iend
string df_title
    db  '!!! DOUBLE FAULT !!!'
endstring

np_idt_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  np_idt_title
        at panic_info_t.title_len,      dd  np_idt_title_len
        at panic_info_t.has_error,      db  1
        at panic_info_t.is_task,        db  0
        at panic_info_t.error_msg,      dd  np_idt_error
        at panic_info_t.error_msg_len,  dd  np_idt_error_len
    iend
string np_idt_title
    db  'UNHANDLEABLE INTERRUPT'
endstring
string np_idt_error
    db  'Missing gate'
endstring

np_gdt_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  np_gdt_title
        at panic_info_t.title_len,      dd  np_gdt_title_len
        at panic_info_t.has_error,      db  1
        at panic_info_t.is_task,        db  0
        at panic_info_t.error_msg,      dd  np_gdt_error
        at panic_info_t.error_msg_len,  dd  np_gdt_error_len
    iend
string np_gdt_title
    db  'ATTEMPTTED LOAD OF INVALID SEGMENT'
endstring
string np_gdt_error
    db  'Bad selector'
endstring

gp_idt_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  gp_idt_title
        at panic_info_t.title_len,      dd  gp_idt_title_len
        at panic_info_t.has_error,      db  1
        at panic_info_t.is_task,        db  0
        at panic_info_t.error_msg,      dd  gp_idt_error
        at panic_info_t.error_msg_len,  dd  gp_idt_error_len
    iend
string gp_idt_title
    db  'PROTECTION VIOLATION - IDT'
endstring
string gp_idt_error
    db  'Bad gate'
endstring

gp_gdt_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  gp_gdt_title
        at panic_info_t.title_len,      dd  gp_gdt_title_len
        at panic_info_t.has_error,      db  1
        at panic_info_t.is_task,        db  0
        at panic_info_t.error_msg,      dd  gp_gdt_error
        at panic_info_t.error_msg_len,  dd  gp_gdt_error_len
    iend
string gp_gdt_title
    db  'PROTECTION VIOLATION - GDT'
endstring
string gp_gdt_error
    db  'Bad selector'
endstring

gp_gen_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  gp_gen_title
        at panic_info_t.title_len,      dd  gp_gen_title_len
        at panic_info_t.has_error,      db  0
        at panic_info_t.is_task,        db  0
        at panic_info_t.error_msg,      dd  0
        at panic_info_t.error_msg_len,  dd  0
    iend
string gp_gen_title
    db  'PROTECTION VIOLATION'
endstring
