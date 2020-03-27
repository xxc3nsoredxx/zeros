    ; Kernel 0
    ; Multiboot header is defined at the bottom of this file
    bits    32

%include    "gdt.hs"
%include    "idt.hs"
%include    "multiboot.hs"

global  kstart          ; Make kstart visible
extern  kmain           ; kmain defined in kernel1.asm

section .text
; Kernel entry poin
kstart:
    cli                 ; Disable interrupts
                        ; Will be reenabled by kernel later
    lgdt    [gdt_desc]  ; Load the GDT
    jmp GDT_CODE_INDEX:.reload_seg  ; The jump reloads CS
.reload_seg:
    mov ax, GDT_STACK_INDEX ; Set the stack segment
    mov ss, ax          ; 
    mov esp, 0x800000   ; Set up the stack pointer to the top of the stack
    mov ax, GDT_DATA_INDEX  ; Set the data segment
    mov ds, ax
    mov es, ax          ; Set the other segments
    mov fs, ax
    mov ax, GDT_VRAM_INDEX  ; Save the VRAM segment in gs
    mov gs, ax
    
    ; TODO: Re-enable interrupts
    xor eax, eax        ; Reprogram the PIC to use interrupts 0x20 to 0x2F
                        ; That way they don't interfere with the first 32
    in  al, PIC_M_DATA  ; Save the masks
    push    eax
    in  al, PIC_S_DATA
    push    eax
    mov al, PIC_INIT | PIC_ICW1_4   ; ICW1: init and tell PIC ICW4 is provided
    out PIC_M_CMD, al
    out PIC_S_CMD, al
    mov al, PIC_M_OFF   ; Set the offset for the master (ICW2)
    out PIC_M_DATA, al
    mov al, PIC_S_OFF   ; Set the offset for the slave (ICW2)
    out PIC_S_DATA, al
    mov al, PIC_M_ICW3
    out PIC_M_DATA, al
    mov al, PIC_S_ICW3
    out PIC_S_DATA, al
    mov al, PIC_ICW4_86
    out PIC_M_DATA, al
    out PIC_S_DATA, al
    pop eax             ; Restore masks
    out PIC_S_DATA, al
    pop eax
    out PIC_M_DATA, al

    call    kmain       ; Kernel main function
    hlt                 ; Halt the CPU after leaving kernel

section .gdt progbits alloc noexec nowrite align=4
gdt:                    ; The start of the GDT
.gdt_null:              ; Null selector (GDT offset = 0x00)
    dq  0               ; All zeros
.gdt_vram:              ; VRAM selector (GDT offset = 0x08)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot, dw GDT_VRAM_LIM_BOT
        at gdt_entry_t.base_bot, dw GDT_VRAM_BASE_BOT
        at gdt_entry_t.base_top_bot, db GDT_VRAM_BASE_TOP_BOT
        at gdt_entry_t.access, db GDT_VRAM_ACCESS
        at gdt_entry_t.flags_lim, db GDT_VRAM_FLAGS_LIM
        at gdt_entry_t.base_top, db GDT_VRAM_BASE_TOP
    iend
.gdt_stack:             ; Stack selector (GDT offset = 0x10)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot, dw GDT_STACK_LIM_BOT
        at gdt_entry_t.base_bot, dw GDT_STACK_BASE_BOT
        at gdt_entry_t.base_top_bot, db GDT_STACK_BASE_TOP_BOT
        at gdt_entry_t.access, db GDT_STACK_ACCESS
        at gdt_entry_t.flags_lim, db GDT_STACK_FLAGS_LIM
        at gdt_entry_t.base_top, db GDT_STACK_BASE_TOP
    iend
.gdt_code:              ; Code selector (GDT offset = 0x18)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot, dw GDT_CODE_LIM_BOT
        at gdt_entry_t.base_bot, dw GDT_CODE_BASE_BOT
        at gdt_entry_t.base_top_bot, db GDT_CODE_BASE_TOP_BOT
        at gdt_entry_t.access, db GDT_CODE_ACCESS
        at gdt_entry_t.flags_lim, db GDT_CODE_FLAGS_LIM
        at gdt_entry_t.base_top, db GDT_CODE_BASE_TOP
    iend
.gdt_data:              ; Data selector (GDT offset = 0x20)
    istruc  gdt_entry_t
        at gdt_entry_t.limit_bot, dw GDT_DATA_LIM_BOT
        at gdt_entry_t.base_bot, dw GDT_DATA_BASE_BOT
        at gdt_entry_t.base_top_bot, db GDT_DATA_BASE_TOP_BOT
        at gdt_entry_t.access, db GDT_DATA_ACCESS
        at gdt_entry_t.flags_lim, db GDT_DATA_FLAGS_LIM
        at gdt_entry_t.base_top, db GDT_DATA_BASE_TOP
    iend
.end:                   ; End of GDT
gdt_desc:               ; GDT descriptor
    istruc  gdt_desc_t
        at gdt_desc_t.size, dw gdt.end - gdt - 1
        at gdt_desc_t.gdt, dd gdt
    iend

section .idt progbits alloc noexec nowrite align=4
idt:                    ; Start of the IDT
%rep    32              ; Pmode exceptions (null entries for now)
    istruc  idt_entry_t
        at idt_entry_t.off_bot, dw 0
        at idt_entry_t.selector, dw 0
        at idt_entry_t.zero, db 0
        at idt_entry_t.type_attr, db 0
        at idt_entry_t.off_top, dw 0
    iend
%endrep
.end:                   ; End of IDT
idt_desc:               ; IDT descriptor
    istruc  idt_desc_t
        at idt_desc_t.size, dw idt.end - idt - 1
        at idt_desc_t.idt, dd idt
    iend

section .multiboot progbits align=4
mb_header:
    istruc  mb_header_t
        at mb_header_t.magic, dd MB_MAGIC
        at mb_header_t.flags, dd MB_FLAGS
        at mb_header_t.check, dd - (MB_MAGIC + MB_FLAGS)
        at mb_header_t.header_addr, dd mb_header
        at mb_header_t.load_addr, dd _mb_load_addr
        at mb_header_t.load_end_addr, dd _mb_load_end_addr
        at mb_header_t.bss_end_addr, dd _mb_bss_end_addr
        at mb_header_t.entry_addr, dd _mb_entry_addr
        at mb_header_t.mode_type, dd MB_GRAPHICS_MODE
        at mb_header_t.width, dd MB_SCR_WIDTH
        at mb_header_t.height, dd MB_SCR_HEIGHT
        at mb_header_t.depth, dd MB_PIXEL_DEPTH
    iend
