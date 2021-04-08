    ; Kernel 0
    ; Multiboot header is defined at the bottom of this file
    bits    32

%include "gdt.hs"
%include "idt.hs"
%include "kb.hs"
%include "multiboot.hs"
%include "tss.hs"
%include "vga.hs"

global kstart               ; Make kstart visible
extern kmain                ; kmain defined in kernel1.asm

; Linker variables
extern _gdt_start           ; Address of GDT struct
extern _idt_start           ; Address of IDT struct

section .text
; Kernel entry point
kstart:
    cli                     ; Disable interrupts
    ; The data segment is not set yet, need to manually give physical address
    lgdt [_gdt_start + gdt_desc - gdt]  ; Load the GDT
    jmp GDT_CODE_INDEX:.reload_seg  ; The jump reloads CS
.reload_seg:
    mov ax, GDT_STACK_INDEX ; Set the stack segment
    mov ss, ax
    mov esp, 0x800000       ; Set up the stack pointer to the top of the stack
    mov ax, GDT_DATA_INDEX  ; Set the data segment
    mov ds, ax
    mov es, ax              ; Set the other segments
    mov fs, ax
    mov ax, GDT_VRAM_INDEX  ; Save the VRAM segment in GS
    mov gs, ax

    ; Load the task-state segment for the main kernel task
    mov ax, GDT_MAIN_TSS
    ltr ax

    ; Reprogram the PIC to use interrupts 0x20 to 0x2F as to not interfere
    ; with hardware interrupts 0 to 31
    mov al, PIC_INIT | PIC_ICW1_4   ; ICW1: init and tell PIC ICW4 is provided
    out PIC_M_CMD, al
    out PIC_S_CMD, al
    mov al, PIC_M_OFF       ; Set the offset for the master (ICW2)
    out PIC_M_DATA, al
    mov al, PIC_S_OFF       ; Set the offset for the slave (ICW2)
    out PIC_S_DATA, al
    mov al, PIC_M_ICW3
    out PIC_M_DATA, al
    mov al, PIC_S_ICW3
    out PIC_S_DATA, al
    mov al, PIC_ICW4_86
    out PIC_M_DATA, al
    out PIC_S_DATA, al
    mov al, 0xFF            ; Disable all IRQs
    out PIC_M_DATA, al
    out PIC_S_DATA, al

    ; Fill in #UD offsets
    mov eax, ud_int
    mov [idt.pm_ud + idt_entry_t.off_bot], ax
    shr eax, 16
    mov [idt.pm_ud + idt_entry_t.off_top], ax

    ; Fill in #NP offsets
    mov eax, np_int
    mov [idt.pm_np + idt_entry_t.off_bot], ax
    shr eax, 16
    mov [idt.pm_np + idt_entry_t.off_top], ax

    ; Fill in #GP offsets
    mov eax, gp_int
    mov [idt.pm_gp + idt_entry_t.off_bot], ax
    shr eax, 16
    mov [idt.pm_gp + idt_entry_t.off_top], ax

    ; Fill in IRQ 0 offsets
    mov eax, master_null
    mov [idt.irq0 + idt_entry_t.off_bot], ax
    shr eax, 16
    mov [idt.irq0 + idt_entry_t.off_top], ax

    ; Fill in IRQ 1 offsets
    mov eax, kb_int
    mov [idt.irq1 + idt_entry_t.off_bot], ax
    shr eax, 16
    mov [idt.irq1 + idt_entry_t.off_top], ax

    ; Fill in rest of PIC master offsets
%assign irq_off 0
%rep 6
    mov eax, master_null
    mov [idt.irq2_7 + irq_off + idt_entry_t.off_bot], ax
    shr eax, 16
    mov [idt.irq2_7 + irq_off + idt_entry_t.off_top], ax
%assign irq_off irq_off + 8
%endrep

    ; Fill in the PIC slave offsets
%assign irq_off 0
%rep 8
    mov eax, slave_null
    mov [idt.irq8_15 + irq_off + idt_entry_t.off_bot], ax
    shr eax, 16
    mov [idt.irq8_15 + irq_off + idt_entry_t.off_top], ax
%assign irq_off irq_off + 8
%endrep

    lidt [idt_desc]         ; Load the IDT
    sti                     ; Re-enable interrupts

    call vga_init           ; Initialize the screen
    call kb_init            ; Initialize the keyboard

    call kmain              ; Kernel main function

    hlt                     ; Halt the CPU after leaving kernel

section .gdt progbits alloc noexec nowrite align=8
gdt:                        ; The start of the GDT
.null:                      ; Null selector (GDT offset = 0x00)
    dq  0                   ; All zeros
.vram:                      ; VRAM selector (GDT offset = 0x08)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_VRAM_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_VRAM_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_VRAM_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_VRAM_ACCESS
        at gdt_entry_t.flags_lim,       db GDT_VRAM_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_VRAM_BASE_TOP
    iend
.stack:                     ; Stack selector (GDT offset = 0x10)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_STACK_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_STACK_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_STACK_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_STACK_ACCESS
        at gdt_entry_t.flags_lim,       db GDT_STACK_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_STACK_BASE_TOP
    iend
.code:                      ; Code selector (GDT offset = 0x18)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_CODE_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_CODE_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_CODE_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_CODE_ACCESS
        at gdt_entry_t.flags_lim,       db GDT_CODE_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_CODE_BASE_TOP
    iend
.data:                      ; Data selector (GDT offset = 0x20)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_DATA_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_DATA_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_DATA_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_DATA_ACCESS
        at gdt_entry_t.flags_lim,       db GDT_DATA_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_DATA_BASE_TOP
    iend
.not_present:               ; Intentionally not present (GDT offset = 0x28)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_DATA_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_DATA_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_DATA_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_DATA_ACCESS & 0x7f
        at gdt_entry_t.flags_lim,       db GDT_DATA_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_DATA_BASE_TOP
    iend
.main_tss:                  ; Main task selector (GDT offset = 0x30)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_MAIN_TSS_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_MAIN_TSS_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_MAIN_TSS_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_MAIN_TSS_ACCESS
        at gdt_entry_t.flags_lim,       db GDT_MAIN_TSS_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_MAIN_TSS_BASE_TOP
    iend
.df_stack:                  ; #DF task stack selector (GDT offset = 0x38)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_DF_STACK_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_DF_STACK_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_DF_STACK_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_DF_STACK_ACCESS
        at gdt_entry_t.flags_lim,       db GDT_DF_STACK_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_DF_STACK_BASE_TOP
    iend
.df_tss:                    ; #DF task selector (GDT offset = 0x40)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_DF_TSS_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_DF_TSS_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_DF_TSS_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_DF_TSS_ACCESS
        at gdt_entry_t.flags_lim,       db GDT_DF_TSS_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_DF_TSS_BASE_TOP
    iend
.end:                       ; End of GDT
gdt_desc:                   ; GDT descriptor
    istruc  gdt_desc_t
        at gdt_desc_t.size,     dw gdt.end - gdt - 1
        at gdt_desc_t.gdt,      dd _gdt_start
    iend

section .idt progbits alloc noexec nowrite align=8
idt:                        ; Start of the IDT
; P-Mode exceptions (0x00 - 0x1f)
%rep 6                      ; Null entries
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0
        at idt_entry_t.selector,    dw 0
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db IDT_NOT_PRESENT
        at idt_entry_t.off_top,     dw 0
    iend
%endrep
.pm_ud:                     ; Invalid Opcode Exception (0x06)
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0xFFFF   ; Filled in code
        at idt_entry_t.selector,    dw GDT_CODE_INDEX
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db INT_GATE
        at idt_entry_t.off_top,     dw 0xFFFF   ; Filled in code
    iend
    istruc  idt_entry_t     ; Null entry
        at idt_entry_t.off_bot,     dw 0
        at idt_entry_t.selector,    dw 0
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db IDT_NOT_PRESENT
        at idt_entry_t.off_top,     dw 0
    iend
.pm_df:                     ; Double Fault Exception (0x08)
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0    ; Not used for task gates
        at idt_entry_t.selector,    dw GDT_DF_TSS
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db TASK_GATE
        at idt_entry_t.off_top,     dw 0    ; Not used for task gates
    iend
%rep 2                      ; Null entries
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0
        at idt_entry_t.selector,    dw 0
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db IDT_NOT_PRESENT
        at idt_entry_t.off_top,     dw 0
    iend
%endrep
.pm_np:                     ; Segment Not Present (0x0b)
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0xFFFF   ; Filled in code
        at idt_entry_t.selector,    dw GDT_CODE_INDEX
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db INT_GATE
        at idt_entry_t.off_top,     dw 0xFFFF   ; Filled in code
    iend
    istruc  idt_entry_t     ; Null entry
        at idt_entry_t.off_bot,     dw 0
        at idt_entry_t.selector,    dw 0
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db IDT_NOT_PRESENT
        at idt_entry_t.off_top,     dw 0
    iend
.pm_gp:
    istruc  idt_entry_t     ; General Protection Exception (0x0d)
        at idt_entry_t.off_bot,     dw 0xFFFF   ; Filled in code
        at idt_entry_t.selector,    dw GDT_CODE_INDEX
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db INT_GATE
        at idt_entry_t.off_top,     dw 0xFFFF   ; Filled in code
    iend
%rep 18                     ; Null entries
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0
        at idt_entry_t.selector,    dw 0
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db IDT_NOT_PRESENT
        at idt_entry_t.off_top,     dw 0
    iend
%endrep
; PIC interrupts (0x20 - 0x2f)
.irq0:                      ; PIC interrupt timer (null handler for now)
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0xFFFF   ; Filled in code
        at idt_entry_t.selector,    dw GDT_CODE_INDEX
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db INT_GATE
        at idt_entry_t.off_top,     dw 0xFFFF   ; Filled in code
    iend
.irq1:                      ; PIC keyboard
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0xFFFF
        at idt_entry_t.selector,    dw GDT_CODE_INDEX
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db INT_GATE
        at idt_entry_t.off_top,     dw 0xFFFF
    iend
.irq2_7:                    ; Rest of PIC master interrupts (null handler for now)
%rep 6
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0xFFFF
        at idt_entry_t.selector,    dw GDT_CODE_INDEX
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db INT_GATE
        at idt_entry_t.off_top,     dw 0xFFFF
    iend
%endrep
.irq8_15:                   ; Rest of PIC slave interrupts (null handler for now)
%rep 8
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0xFFFF
        at idt_entry_t.selector,    dw GDT_CODE_INDEX
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db INT_GATE
        at idt_entry_t.off_top,     dw 0xFFFF
    iend
%endrep
; Rest of user-defined interrupts (0x30 - 0xff)
.not_present:               ; Call to trigger IDT case of #NP (0x30)
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0
        at idt_entry_t.selector,    dw 0
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db IDT_NOT_PRESENT
        at idt_entry_t.off_top,     dw 0
    iend
.double_fault:              ; Call to trigger a double fault (0x31)
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0xFFFF
        at idt_entry_t.selector,    dw GDT_CODE_INDEX
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db INT_GATE
        at idt_entry_t.off_top,     dw 0xFFFF
    iend
.rest:                      ; Rest of the IDT (null entries for now)
%rep 206
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0
        at idt_entry_t.selector,    dw 0
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db IDT_NOT_PRESENT
        at idt_entry_t.off_top,     dw 0
    iend
%endrep
.end:                       ; End of IDT
idt_desc:                   ; IDT descriptor
    istruc  idt_desc_t
        at idt_desc_t.size, dw idt.end - idt - 1
        at idt_desc_t.idt,  dd _idt_start
    iend

; Newer TSS's at the top
section .tss progbits alloc noexec align=16
df_tss:                     ; TSS for double fault task
    istruc tss_t
        at tss_t.backlink,  dw 0
        at tss_t.esp0,      dd 0x100000
        at tss_t.ss0,       dw GDT_DF_STACK
        at tss_t.esp1,      dd 0
        at tss_t.ss1,       dw 0
        at tss_t.esp2,      dd 0
        at tss_t.ss2,       dw 0
        at tss_t.cr3,       dd 0
        at tss_t.eip,       dd df_int
        at tss_t.eflags,    dd 0
        at tss_t.eax,       dd 0
        at tss_t.ecx,       dd 0
        at tss_t.edx,       dd 0
        at tss_t.ebx,       dd 0
        at tss_t.esp,       dd 0x100000
        at tss_t.ebp,       dd 0
        at tss_t.esi,       dd 0
        at tss_t.edi,       dd 0
        at tss_t.es,        dw GDT_DATA_INDEX
        at tss_t.cs,        dw GDT_CODE_INDEX
        at tss_t.ss,        dw GDT_DF_STACK
        at tss_t.ds,        dw GDT_DATA_INDEX
        at tss_t.fs,        dw GDT_DATA_INDEX
        at tss_t.gs,        dw GDT_VRAM_INDEX
        at tss_t.trap,      db 0
        at tss_t.io_map,    dw 0x68 ; Unused - set offset to 1 B after TSS
    iend

main_tss:                   ; TSS for main kernel task
    istruc tss_t
        at tss_t.backlink,  dw 0
        at tss_t.esp0,      dd 0x800000
        at tss_t.ss0,       dw GDT_STACK_INDEX
        at tss_t.esp1,      dd 0
        at tss_t.ss1,       dw 0
        at tss_t.esp2,      dd 0
        at tss_t.ss2,       dw 0
        at tss_t.cr3,       dd 0
        at tss_t.eip,       dd 0
        at tss_t.eflags,    dd 0
        at tss_t.eax,       dd 0
        at tss_t.ecx,       dd 0
        at tss_t.edx,       dd 0
        at tss_t.ebx,       dd 0
        at tss_t.esp,       dd 0
        at tss_t.ebp,       dd 0
        at tss_t.esi,       dd 0
        at tss_t.edi,       dd 0
        at tss_t.es,        dw 0
        at tss_t.cs,        dw 0
        at tss_t.ss,        dw 0
        at tss_t.ds,        dw 0
        at tss_t.fs,        dw 0
        at tss_t.gs,        dw 0
        at tss_t.trap,      db 0
        at tss_t.io_map,    dw 0x68 ; Unused - set offset to 1 B after TSS
    iend

section .multiboot progbits align=4
mb_header:
    istruc  mb_header_t
        at mb_header_t.magic,           dd MB_MAGIC
        at mb_header_t.flags,           dd MB_FLAGS
        at mb_header_t.check,           dd -(MB_MAGIC + MB_FLAGS)
        at mb_header_t.header_addr,     dd _mb_header_addr
        at mb_header_t.load_addr,       dd _mb_load_addr
        at mb_header_t.load_end_addr,   dd _mb_load_end_addr
        at mb_header_t.bss_end_addr,    dd _mb_bss_end_addr
        at mb_header_t.entry_addr,      dd _mb_entry_addr
        at mb_header_t.mode_type,       dd MB_GRAPHICS_MODE
        at mb_header_t.width,           dd MB_SCR_WIDTH
        at mb_header_t.height,          dd MB_SCR_HEIGHT
        at mb_header_t.depth,           dd MB_PIXEL_DEPTH
    iend
