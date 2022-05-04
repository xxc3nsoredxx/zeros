%ifndef IDT_HS_20200327_065700
%define IDT_HS_20200327_065700

; P-Mode exceptions (by vector)
extern ud_int
extern df_int
extern ts_int
extern np_int
extern ss_int
extern gp_int

; PIC handlers
extern master_null
extern slave_null
extern kb_int

struc   idt_entry_t
    .off_bot:   resw 1      ; Bottom word of routine's offset (ie pointer)
        alignb  2
    .selector:  resw 1      ; Selector in GDT/LDT with interrupt routine
        alignb  2           ; Ring level of selector has to be zero for iret
                            ; to not throw a general protection fault
    .zero:      resb 1      ; Unused, set to zero
        alignb  1
    .type_attr: resb 1      ; Type and attributes
        alignb  1           ; 7:    Present: set to 0 for unused interrupts
                            ; 5-6:  Caller minimum ring level
                            ; 4:    Storage: set to 0 for interrupt and trap gate
                            ; 0-3:  Gate type:  5:  32 bit task gate
                            ;                   6:  16 bit interrupt gate
                            ;                   7:  16 bit trap gate
                            ;                   14: 32 bit interrupt gate
                            ;                   15: 32 bit trap gate
    .off_top:   resw 1      ; Top word of offset
        alignb  2
endstruc

struc   idt_desc_t
    .size:  resw 1          ; Size of IDT - 1
        alignb  2
    .idt:   resd 1          ; Address of IDT
        alignb  4
endstruc

%assign TASK_GATE       0b10000101  ; Attribute byte for task gates
%assign INT_GATE        0b10001110  ; Attribute byte for interrupt gates
%assign IDT_NOT_PRESENT 0b00001110  ; Attribute byte for unused interrupts

; 8259 Programmable Interrupt Controller I/O ports
%assign PIC_M_CMD   0x20    ; PIC master command port
%assign PIC_M_DATA  0x21    ; PIC master data port
%assign PIC_S_CMD   0xA0    ; PIC slave command port
%assign PIC_S_DATA  0xA1    ; PIC slave data port

; 8259 PIC commands
%assign PIC_EOI     0x20    ; End of interrupt
%assign PIC_ICW1_4  0x01    ; ICW4 given (more information)
%assign PIC_ICW4_86 0x01    ; 80x86 mode
%assign PIC_INIT    0x10    ; Initialize PIC
%assign PIC_M_ICW3  0x04    ; Slave on IRQ 2
%assign PIC_M_OFF   0x20    ; PIC master interrupt offset
%assign PIC_S_ICW3  0x02    ; Slave is attached to IRQ 2 on master
%assign PIC_S_OFF   0x28    ; PIC slave interrupt offset

%endif

; vim: filetype=asm:syntax=nasm:
