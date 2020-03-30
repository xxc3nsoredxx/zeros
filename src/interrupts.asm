    ; Interrupt handlers
    bits    32

%include    "idt.hs"
%include    "kb.hs"
%include    "vga.hs"

section .text
; PIC master null handler
master_null:
    pusha
    mov al, PIC_EOI     ; Send EOI to PIC
    out PIC_M_CMD, al
    popa
    iret

; PIC slave null handler
slave_null:
    pusha
    mov al, PIC_EOI
    out PIC_S_CMD, al
    out PIC_M_CMD, al
    popa
    iret

; Keyboard interrupt handler
kb_int:
    pusha

    mov al, PIC_EOI
    out PIC_M_CMD, al

    in  al, PS2_DATA    ; Get the scancode
    cmp al, 0x5D        ; Test for basic keys
    jle .basic
    jmp .clear
.basic:
    add al, 0x20
    push    eax
    call    putch
.clear:
    in  al, PS2_STAT    ; Clear the buffer
    and al, PS2_STAT_OUTPUT
    jz  .done
    in  al, PS2_DATA
    jmp .clear
.done:
    popa
    iret
