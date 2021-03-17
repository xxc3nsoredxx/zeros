    ; Kernel 0
    ; Multiboot header is defined at the bottom of this file
    bits    32

%include    "gdt.hs"
%include    "idt.hs"
%include    "kb.hs"
%include    "multiboot.hs"

global  kstart              ; Make kstart visible
extern  kmain               ; kmain defined in kernel1.asm

section .text
; Kernel entry point
kstart:
    cli                     ; Disable interrupts
    ; The data segment is not set yet, need to manually correct the address
    lea ecx, [gdt_desc - gdt]
    add ecx, _gdt_start
    lgdt [ecx]         ; Load the GDT
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

    mov eax, master_null    ; Fill in IRQ 0 offsets
    mov [idt.irq0 + idt_entry_t.off_bot], ax
    shr eax, 16
    mov [idt.irq0 + idt_entry_t.off_top], ax

    mov eax, kb_int         ; Fill in IRQ 1 offsets
    mov [idt.irq1 + idt_entry_t.off_bot], ax
    shr eax, 16
    mov [idt.irq1 + idt_entry_t.off_top], ax

%assign irq_off 0           ; Fill in rest of the PIC master offsets
%rep 6
    mov eax, master_null
    mov [idt.irq2_7 + irq_off + idt_entry_t.off_bot], ax
    shr eax, 16
    mov [idt.irq2_7 + irq_off + idt_entry_t.off_top], ax
%assign irq_off irq_off + 8
%endrep

%assign irq_off 0           ; Fill in the PIC slave offsets
%rep 8
    mov eax, slave_null
    mov [idt.irq8_15 + irq_off + idt_entry_t.off_bot], ax
    shr eax, 16
    mov [idt.irq8_15 + irq_off + idt_entry_t.off_top], ax
%assign irq_off irq_off + 8
%endrep

    ; Fix the start address of the IDT, set it to the physical address
    add DWORD [idt_desc + idt_desc_t.idt], _mem_base
    lidt [idt_desc]         ; Load the IDT
    sti                     ; Re-enable interrupts

    call kb_init            ; Initialize the keyboard

    call kmain              ; Kernel main function

    hlt                     ; Halt the CPU after leaving kernel

section .gdt progbits alloc noexec nowrite align=4
gdt:                        ; The start of the GDT
.gdt_null:                  ; Null selector (GDT offset = 0x00)
    dq  0                   ; All zeros
.gdt_vram:                  ; VRAM selector (GDT offset = 0x08)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_VRAM_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_VRAM_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_VRAM_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_VRAM_ACCESS
        at gdt_entry_t.flags_lim,       db GDT_VRAM_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_VRAM_BASE_TOP
    iend
.gdt_stack:                 ; Stack selector (GDT offset = 0x10)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_STACK_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_STACK_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_STACK_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_STACK_ACCESS
        at gdt_entry_t.flags_lim,       db GDT_STACK_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_STACK_BASE_TOP
    iend
.gdt_code:                  ; Code selector (GDT offset = 0x18)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_CODE_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_CODE_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_CODE_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_CODE_ACCESS
        at gdt_entry_t.flags_lim,       db GDT_CODE_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_CODE_BASE_TOP
    iend
.gdt_data:                  ; Data selector (GDT offset = 0x20)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot,       dw GDT_DATA_LIM_BOT
        at gdt_entry_t.base_bot,        dw GDT_DATA_BASE_BOT
        at gdt_entry_t.base_top_bot,    db GDT_DATA_BASE_TOP_BOT
        at gdt_entry_t.access,          db GDT_DATA_ACCESS
        at gdt_entry_t.flags_lim,       db GDT_DATA_FLAGS_LIM
        at gdt_entry_t.base_top,        db GDT_DATA_BASE_TOP
    iend
.end:                       ; End of GDT
gdt_desc:                   ; GDT descriptor
    istruc  gdt_desc_t
        at gdt_desc_t.size,     dw gdt.end - gdt - 1
        at gdt_desc_t.gdt,      dd _gdt_start
    iend

section .idt progbits alloc noexec nowrite align=4
idt:                        ; Start of the IDT
.pm_ex:                     ; Pmode exceptions (null entries for now)
%rep 32
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0
        at idt_entry_t.selector,    dw 0
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db 0
        at idt_entry_t.off_top,     dw 0
    iend
%endrep
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
.rest:                      ; Rest of the IDT (null entries for now)
%rep 208
    istruc  idt_entry_t
        at idt_entry_t.off_bot,     dw 0
        at idt_entry_t.selector,    dw 0
        at idt_entry_t.zero,        db 0
        at idt_entry_t.type_attr,   db 0
        at idt_entry_t.off_top,     dw 0
    iend
%endrep
.end:                       ; End of IDT
idt_desc:                   ; IDT descriptor
    istruc  idt_desc_t
        at idt_desc_t.size, dw idt.end - idt - 1
        at idt_desc_t.idt,  dd idt
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
