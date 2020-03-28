    ; Interrupt handlers
    bits    32

%include    "idt.hs"
%include    "kb.hs"

section .text
; PIC master null handler
master_null:
    push    eax
    mov al, PIC_EOI     ; Send EOI to PIC
    out PIC_M_CMD, al
    pop eax
    iret

; PIC slave null handler
slave_null:
    push    eax
    mov al, PIC_EOI     ; Send EOI to PIC
    out PIC_S_CMD, al
    out PIC_M_CMD, al
    pop eax
    iret

; Keyboard interrupt handler
kb_int:
    push    eax
    mov al, PIC_EOI
    out PIC_M_CMD, al

    in  al, KB_STAT     ; Read keyboard status
    and al, KB_STAT_OUTPUT  ; If key is queued, read key
    jz  .skip_read
    in  al, KB_DATA
.skip_read:
    pop eax
    iret
