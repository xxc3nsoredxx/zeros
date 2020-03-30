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

section .rodata
SC2_BASIC:              ; Basic keys
    db  0, 0x89, 0, 0x85        ; n/a       F9      n/a     F5
    db  0x83, 0x81, 0x82, 0x8C  ; F3        F1      F2      F12
    db  0, 0x8A, 0x88, 0x6      ; n/a       F10     F8      F6
    db  0x84, 0x09, '`', 0      ; F4        Tab     `       n/a
    db  0, 0x96, 0x92, 0        ; n/a       L-Alt   L-Shift n/a
    db  0x93, 'q1', 0           ; L-Ctrl    Q       1 one   n/a
    db  0, 0, 'zs'              ; n/a       n/a     Z       S
    db  'aw2', 0                ; A         W       2       n/a
    db  0, 'cxd'                ; n/a       C       X       D
    db  'e43', 0                ; E         4       3       n/a
    db  0, ' vf'                ; n/a       Space   V       F
    db  'tr5', 0                ; T         R       5       n/a
    db  0, 'nbh'                ; n/a       N       B       H
    db  'gy6', 0                ; G         Y       6       n/a
    db  0, 0, 'mj'              ; n/a       n/a     M       J
    db  'u78', 0                ; U         7       8       n/a
    db  0, ',ki'                ; n/a       ,       K       I eye
    db  'o09', 0                ; O oh      0 zero  9       n/a
    db  0, './l'                ; n/a       .       /       L
    db  ';p-', 0                ; ;         P       - dash  n/a
    db  0, 0, 0x27, 0           ; n/a       n/a     '       n/a
    db  '[=', 0, 0              ; [         =       n/a     n/a
    db  0x91, 0x9D, 0x0A, ']'   ; Caps      R-Shift Return  ]
    db  0, '\', 0, 0            ; n/a       \       n/a     n/a
    db  0, 0, 0, 0              ; n/a       n/a     n/a     n/a
    db  0, 0, 0x08, 0           ; n/a       n/a     Backsp  n/a
    db  0, 0, 0, 0              ; n/a       NUM 1   n/a     NUM 4
    db  0, 0, 0, 0              ; NUM 7     n/a     n/a     n/a
    db  0, 0, 0, 0              ; NUM 0 zero NUM .  NUM 2   NUM 5
    db  0, 0, 0x90, 0           ; NUM 6     NUM 8   Esc     NumLock
    db  0x8B, 0, 0, 0           ; F11       NUM +   NUM 3   NUM - dash
    db  0, 0, 0, 0              ; NUM *     NUM 9   ScrLock n/a
    db  0, 0, 0, 0x87           ; n/a       n/a     n/a     F7
SHIFT_TABLE:
    times 0x27  db 0
    db  '"'
    times 4 db 0
    db  '<_>?)!@#$%^&*('
    db  0
    db  ':'
    db  0
    db  '+'
    times 3 db 0
    db  'abcdefghijklmnopqrstuvwxyz{|}'
    times 2 db 0
    db  '~ABCDEFGHIJKLMNOPQRSTUVWXYZ'

section .bss
keycode:
.mod:                   ; Modifiers active
    resb    1
.key:                   ; Pressed key (non-modifier)
    resb    1           ; ASCII code:
                        ;   Letters     (lowercase, 0x61 to 0x7A)
                        ;   Numbers     (0x30 to 0x39, shift for !@#$%^&*())
                        ;   `-=[]\;',./ (0x27, 2C-2F, 3B, 3D, 5B-5D, 60)
                        ;               (shift for ~_+{}|:">?)
                        ;   Newline     (0x0A, return)
                        ;   Space       (0x20, space bar)
                        ;   Tab         (0x09, tab)
                        ;   Backspace   (0x08)
                        ; 0x81 to 0x8C  F1 to F12
                        ; 0             Unused
                        ; 0x90 to 0x9D  Esc to R-Shift
.state:                 ; Current state
    resb    1
