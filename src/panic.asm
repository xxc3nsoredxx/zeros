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
; Uppercase strings mean flag is set, lowercase string mean flag is clear
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

    ; Print system flags
    bt  ebx, 21             ; Identification flag
    cmovc eax, [id_set]
    cmovnc eax, [id_clear]
    push DWORD id_len
    push eax
    bt  ebx, 20             ; Virtual Interrupt Pending flag
    cmovc eax, [vip_set]
    cmovnc eax, [vip_clear]
    push DWORD vip_len
    push eax
    bt  ebx, 19             ; Virtual Interrupt flag
    cmovc eax, [vif_set]
    cmovnc eax, [vif_clear]
    push DWORD vif_len
    push eax
    bt  ebx, 18             ; Alignment Check flag
    cmovc eax, [ac_set]
    cmovnc eax, [ac_clear]
    push DWORD ac_len
    push eax
    bt  ebx, 17             ; Virtual 8086 Mode flag
    cmovc eax, [vm_set]
    cmovnc eax, [vm_clear]
    push DWORD vm_len
    push eax
    bt  ebx, 16             ; Resume flag
    cmovc eax, [rf_set]
    cmovnc eax, [rf_clear]
    push DWORD rf_len
    push eax
    bt  ebx, 4              ; Nested Task flag
    cmovc eax, [nt_set]
    cmovnc eax, [nt_clear]
    push DWORD nt_len
    push eax
    bt  ebx, 9              ; Interrupt Enable flag
    cmovc eax, [if_set]
    cmovnc eax, [if_clear]
    push DWORD if_len
    push eax
    bt  ebx, 8              ; Trap flag
    cmovc eax, [tf_set]
    cmovnc eax, [tf_clear]
    push DWORD tf_len
    push eax

    push DWORD system_flags_len
    push system_flags
    call printf

    ; Print direction flag
    bt  ebx, 10
    cmovc eax, [df_set]
    cmovnc eax, [df_clear]
    push DWORD df_len
    push eax

    push DWORD dir_flag_len
    push dir_flag
    call printf

    ; Print I/O privilege level
    and ebx, 0x3000         ; I/O PL is bits 12 and 13
    shr ebx, 12
    push ebx
    push DWORD iopl_flag_len
    push iopl_flag
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

    ; Print other registers
    push DWORD fs:[tss_t.gs]
    push DWORD fs:[tss_t.edi]
    push DWORD fs:[tss_t.fs]
    push DWORD fs:[tss_t.esi]
    push DWORD fs:[tss_t.es]
    push DWORD fs:[tss_t.edx]
    push DWORD fs:[tss_t.ds]
    push DWORD fs:[tss_t.ecx]
    push DWORD fs:[tss_t.esp]
    push DWORD fs:[tss_t.ss]
    push DWORD fs:[tss_t.ebx]
    push DWORD fs:[tss_t.ebp]
    push DWORD fs:[tss_t.cs]
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
    call eflags_info

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
    dd  ss_limit_info
    dd  ss_sel_info
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
    db  ' Current TSS selector: %x', 0x0a
    db  'Previous TSS selector: %x', 0x0a
    db  '      EIP: %x', 0x0a
endstring
string task_info2
    db  '      EAX: %x  CS: %x  EBP:    %x', 0x0a
    db  '      EBX: %x  SS: %x  ESP:    %x', 0x0a
    db  '      ECX: %x  DS: %x', 0x0a
    db  '      EDX: %x  ES: %x', 0x0a
    db  '      ESI: %x  FS: %x', 0x0a
    db  '      EDI: %x  GS: %x', 0x0a
endstring
string reg_info
    db  '      EIP: %x', 0x0a
    db  '       CS: %x', 0x0a
endstring

; EFLAGS strings
string eflags
    db  '   EFLAGS: %x', 0x0a
endstring

; Status flags strings
string status_flags
    db  '   Status: %s %s %s %s %s %s', 0x0a
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

; System flags strings
string system_flags
    db  '   System: %s %s %s %s %s %s %s %s %s', 0x0a
endstring
tf_set_str:
    db  'TRAP'
tf_clear_str:
    db  'trap'
tf_len: equ tf_clear_str - tf_set_str
tf_set:
    dd  tf_set_str
tf_clear:
    dd  tf_clear_str
if_set_str:
    db  'INTERRUPT'
if_clear_str:
    db  'interrupt'
if_len: equ if_clear_str - if_set_str
if_set:
    dd  if_set_str
if_clear:
    dd  if_clear_str
nt_set_str:
    db  'NEST'
nt_clear_str:
    db  'nest'
nt_len: equ nt_clear_str - nt_set_str
nt_set:
    dd  nt_set_str
nt_clear:
    dd  nt_clear_str
rf_set_str:
    db  'RESUME'
rf_clear_str:
    db  'resume'
rf_len: equ rf_clear_str - rf_set_str
rf_set:
    dd  rf_set_str
rf_clear:
    dd  rf_clear_str
vm_set_str:
    db  'VIRT_8086'
vm_clear_str:
    db  'virt_8086'
vm_len: equ vm_clear_str - vm_set_str
vm_set:
    dd  vm_set_str
vm_clear:
    dd  vm_clear_str
ac_set_str:
    db  'ALIGN'
ac_clear_str:
    db  'align'
ac_len: equ ac_clear_str - ac_set_str
ac_set:
    dd  ac_set_str
ac_clear:
    dd  ac_clear_str
vif_set_str:
    db  'VIRT_INT'
vif_clear_str:
    db  'virt_int'
vif_len: equ vif_clear_str - vif_set_str
vif_set:
    dd  vif_set_str
vif_clear:
    dd  vif_clear_str
vip_set_str:
    db  'VIRT_PEND'
vip_clear_str:
    db  'virt_pend'
vip_len: equ vip_clear_str - vip_set_str
vip_set:
    dd  vip_set_str
vip_clear:
    dd  vip_clear_str
id_set_str:
    db  'CPUID'
id_clear_str:
    db  'cpuid'
id_len: equ id_clear_str - id_set_str
id_set:
    dd  id_set_str
id_clear:
    dd  id_clear_str

; Direction flag strings
string dir_flag
    db  'Direction: %s', 0x0a
endstring
df_set_str:
    db  'DECREMENT'
df_clear_str:
    db  'increment'
df_len: equ df_clear_str - df_set_str
df_set:
    dd  df_set_str
df_clear:
    dd  df_clear_str

; I/O privilege level string
string iopl_flag
    db  '   I/O PL: %u', 0x0a
endstring

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
    db  'DOUBLE FAULT'
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

ss_limit_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  ss_limit_title
        at panic_info_t.title_len,      dd  ss_limit_title_len
        at panic_info_t.has_error,      db  0
        at panic_info_t.is_task,        db  0
        at panic_info_t.error_msg,      dd  0
        at panic_info_t.error_msg_len,  dd  0
    iend
string ss_limit_title
    db  'STACK FAULT - LIMIT VIOLATION'
endstring

ss_sel_info:
    istruc panic_info_t
        at panic_info_t.title,          dd  ss_sel_title
        at panic_info_t.title_len,      dd  ss_sel_title_len
        at panic_info_t.has_error,      db  1
        at panic_info_t.is_task,        db  0
        at panic_info_t.error_msg,      dd  ss_sel_error
        at panic_info_t.error_msg_len,  dd  ss_sel_error_len
    iend
string ss_sel_title
    db  'STACK FAULT - INVALID SEGMENT'
endstring
string ss_sel_error
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
