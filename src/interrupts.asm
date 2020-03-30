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
; TODO: Finish handling all the keys
;   Basic keys
;   E0 keys
;   Print screen
;   Pause
kb_int:
    pusha

    in  al, PS2_DATA    ; Get the scancode
    mov cl, [keycode.state] ; Get the current state
    cmp cl, KC_STATE_WAIT   ; New key
    jz  .new
    cmp cl, KC_STATE_E0 ; E0 key
    jz  .e0
    cmp cl, KC_STATE_PS + 2 ; Print screen, 2 bytes left
    jz  .ps2
    cmp cl, KC_STATE_PS + 1 ; Print screen, 1 byte left
    jz  .ps1
    cmp cl, KC_STATE_REL    ; Key released
    jz  .rel
    cmp cl, KC_STATE_E0_REL ; E0 key released
    jz  .e0_rel
    cmp cl, KC_STATE_PS_REL + 3 ; Print screen released, 3 bytes left
    jz  .ps_rel3
    cmp cl, KC_STATE_PS_REL + 2 ; Print screen released, 2 bytes left
    jz  .ps_rel2
    cmp cl, KC_STATE_PS_REL + 1 ; Print screen released, 1 byte left
    jz  .ps_rel1
    cmp cl, KC_STATE_PAUSE + 7  ; Pause, 7 bytes left
    jz  .pause7
    cmp cl, KC_STATE_PAUSE + 6  ; Pause, 6 bytes left
    jz  .pause6
    cmp cl, KC_STATE_PAUSE + 5  ; Pause, 5 bytes left
    jz  .pause5
    cmp cl, KC_STATE_PAUSE + 4  ; Pause, 4 bytes left
    jz  .pause4
    cmp cl, KC_STATE_PAUSE + 3  ; Pause, 3 bytes left
    jz  .pause3
    cmp cl, KC_STATE_PAUSE + 2  ; Pause, 2 bytes left
    jz  .pause2
    cmp cl, KC_STATE_PAUSE + 1  ; Pause, 1 bytes left
    jz  .pause1

.new:                   ; Handle new key
    cmp al, 0xE0        ; New E0 key
    jz  .new_e0
    cmp al, 0xF0        ; New released key
    jz  .new_rel
    cmp al, 0xE1        ; New pause key
    jz  .new_pause
    add al, 0x20        ; New basic key
    push    ax
    call    putch
    jmp .done
.new_e0:                ; Set E0 state
    mov BYTE [keycode.state], KC_STATE_E0
    jmp .done
.new_rel:               ; Set release state
    mov BYTE [keycode.state], KC_STATE_REL
    jmp .done
.new_pause:             ; Set pause state, 7 bytes left
    mov BYTE [keycode.state], KC_STATE_PAUSE + 7
    jmp .done

.e0:                    ; Handle new E0 keys
    cmp al, 0x12        ; New print screen key
    jz  .new_ps
    cmp al, 0xF0        ; E0 key released
    jz  .new_e0_rel
    mov BYTE [keycode.state], KC_STATE_WAIT ; Basic E0 key (currently ignored)
    jmp .done
.new_ps:                ; Set print screen 2 bytes left state
    mov BYTE [keycode.state], KC_STATE_PS + 2
    jmp .done
.new_e0_rel:            ; Set E0 released state
    mov BYTE [keycode.state], KC_STATE_E0_REL
    jmp .done

.ps2:                   ; Handle print screen, 2 bytes left

.ps1:                   ; Handle print screen, 1 byte left

.rel:                   ; Handle released key

.e0_rel:                ; Handle relaeased E0 key

.ps_rel3:               ; Handle released print screen, 3 bytes left

.ps_rel2:               ; Handle released print screen, 2 bytes left

.ps_rel1:               ; Handle released print screen, 1 byte left

.pause7:                ; Handle pause key, 7 bytes left

.pause6:                ; Handle pause key, 6 bytes left

.pause5:                ; Handle pause key, 5 bytes left

.pause4:                ; Handle pause key, 4 bytes left

.pause3:                ; Handle pause key, 3 bytes left

.pause2:                ; Handle pause key, 2 bytes left

.pause1:                ; Handle pause key, 1 byte left

.done:
    mov al, PIC_EOI
    out PIC_M_CMD, al

    popa
    iret
