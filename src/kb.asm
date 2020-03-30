    ; Keyboard utilities
    bits    32

%include    "kb.hs"
%include    "idt.hs"

section .text
; void kb_init ()
; Initializes the keyboard (called only in kernel0)
kb_init:
.loop:                  ; Disable PS/2 port 1
    in  al, PS2_STAT
    and al, PS2_STAT_INPUT
    jnz .loop
    mov al, PS2_DIS_1
    out PS2_CMD, al
.loop2:                 ; Disable PS/2 port 2
    in  al, PS2_STAT
    and al, PS2_STAT_INPUT
    jnz .loop2
    mov al, PS2_DIS_2
    out PS2_CMD, al
    in  al, PS2_DATA    ; Flush output
.loop3:                 ; Read configuration byte
    in  al, PS2_STAT
    and al, PS2_STAT_INPUT
    jnz .loop3
    mov al, PS2_READ_CONF
    out PS2_CMD, al
.loop4:
    in  al, PS2_STAT
    and al, PS2_STAT_OUTPUT
    jz  .loop4
    in  al, PS2_DATA
    and al, PS2_CONF_MASK   ; Set conf byte
    push    ax
.loop5:
    in  al, PS2_STAT
    and al, PS2_STAT_INPUT
    jnz .loop5
    mov al, PS2_WRITE_CONF
    out PS2_CMD, al
.loop6:
    in  al, PS2_STAT
    and al, PS2_STAT_INPUT
    jnz .loop6
    pop ax
    out PS2_DATA, al
.loop7:                 ; Enable port 1
    in  al, PS2_STAT
    and al, PS2_STAT_INPUT
    jnz .loop7
    mov al, PS2_EN_1
    out PS2_CMD, al
.loop8:                 ; Enable port 2
    in  al, PS2_STAT
    and al, PS2_STAT_INPUT
    jnz .loop8
    mov al, PS2_EN_2
    out PS2_CMD, al
.loop9:                 ; Read configuration byte
    in  al, PS2_STAT
    and al, PS2_STAT_INPUT
    jnz .loop9
    mov al, PS2_READ_CONF
    out PS2_CMD, al
.loop10:
    in  al, PS2_STAT
    and al, PS2_STAT_OUTPUT
    jz  .loop10
    in  al, PS2_DATA
    or  al, PS2_CONF_MASK2  ; Set conf byte (enable port interrupts)
    push    ax
.loop11:
    in  al, PS2_STAT
    and al, PS2_STAT_INPUT
    jnz .loop11
    mov al, PS2_WRITE_CONF
    out PS2_CMD, al
.loop12:
    in  al, PS2_STAT
    and al, PS2_STAT_INPUT
    jnz .loop12
    pop ax
    out PS2_DATA, al

    mov al, 0xFD        ; Enable IRQ 1 (keyboard)
    out PIC_M_DATA, al
    ret

section .bss
keycode:
.modifier:              ; Modifiers active
    resb    1           ; Bits:
                        ;   2-7:    Unused
                        ;   1:      Caps:   0 (inactive), 1 (active)
                        ;   0:      Shift:  0 (inactive), 1 (active)
.key:                   ; Pressed key (non-modifier)
    resb    1           ; ASCII code:
                        ;   Letters     (lowercase, 0x61 to 0x7A)
                        ;   Numbers     (0x30 to 0x39, shift for !@#$%^&*())
                        ;   `-=[]\;',./ (0x27, 2C-2F, 3B, 3D, 5B-5D, 60)
                        ;               (shift for ~_+{}|:">?)
                        ;   Newline     (0x0A, return)
                        ;   Space       (0x20, space bar)
                        ;   Backspace   (0x08)
