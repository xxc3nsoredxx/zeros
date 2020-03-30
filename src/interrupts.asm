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

    xor eax, eax
    mov al, PIC_EOI
    out PIC_M_CMD, al

    in  al, PS2_DATA    ; Get the scancode
    mov bl, [keycode.state] ; Get the current state
    cmp bl, KC_STATE_WAIT   ; New key
    jz  .new
    cmp bl, KC_STATE_E0 ; E0 key
    jz  .e0
    cmp bl, KC_STATE_PS + 2 ; Print screen, 2 bytes left
    jz  .ps2
    cmp bl, KC_STATE_PS + 1 ; Print screen, 1 byte left
    jz  .ps1
    cmp bl, KC_STATE_REL    ; Key released
    jz  .rel
    cmp bl, KC_STATE_E0_REL ; E0 key released
    jz  .e0_rel
    cmp bl, KC_STATE_PS_REL + 3 ; Print screen released, 3 bytes left
    jz  .ps_rel3
    cmp bl, KC_STATE_PS_REL + 2 ; Print screen released, 2 bytes left
    jz  .ps_rel2
    cmp bl, KC_STATE_PS_REL + 1 ; Print screen released, 1 byte left
    jz  .ps_rel1
    cmp bl, KC_STATE_PAUSE + 7  ; Pause, 7 bytes left
    jz  .pause7
    cmp bl, KC_STATE_PAUSE + 6  ; Pause, 6 bytes left
    jz  .pause6
    cmp bl, KC_STATE_PAUSE + 5  ; Pause, 5 bytes left
    jz  .pause5
    cmp bl, KC_STATE_PAUSE + 4  ; Pause, 4 bytes left
    jz  .pause4
    cmp bl, KC_STATE_PAUSE + 3  ; Pause, 3 bytes left
    jz  .pause3
    cmp bl, KC_STATE_PAUSE + 2  ; Pause, 2 bytes left
    jz  .pause2
    cmp bl, KC_STATE_PAUSE + 1  ; Pause, 1 bytes left
    jz  .pause1

.new:                   ; Handle new key
    cmp al, 0xE0        ; New E0 key
    jz  .new_e0
    cmp al, 0xF0        ; New released key
    jz  .new_rel
    cmp al, 0xE1        ; New pause key
    jz  .new_pause
    lea eax, [SC2_BASIC + eax]  ; New basic key
    mov al, [eax]
    push    eax
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
    dec BYTE [keycode.state]
    jmp .done

.ps1:                   ; Handle print screen, 1 byte left
    mov BYTE [keycode.state], KC_STATE_WAIT
    jmp .done

.rel:                   ; Handle released key
    mov BYTE [keycode.state], KC_STATE_WAIT
    jmp .done

.e0_rel:                ; Handle relaeased E0 key
    cmp al, 0x7C        ; Print screen released
    jz  .new_ps_rel
    mov BYTE [keycode.state], KC_STATE_WAIT
    jmp .done
.new_ps_rel:            ; Set print screen released 3 bytes left state
    mov BYTE [keycode.state], KC_STATE_PS_REL + 3
    jmp .done

.ps_rel3:               ; Handle released print screen, 3 bytes left
    dec BYTE [keycode.state]
    jmp .done

.ps_rel2:               ; Handle released print screen, 2 bytes left
    dec BYTE [keycode.state]
    jmp .done

.ps_rel1:               ; Handle released print screen, 1 byte left
    mov BYTE [keycode.state], KC_STATE_WAIT
    jmp .done

.pause7:                ; Handle pause key, 7 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause6:                ; Handle pause key, 6 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause5:                ; Handle pause key, 5 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause4:                ; Handle pause key, 4 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause3:                ; Handle pause key, 3 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause2:                ; Handle pause key, 2 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause1:                ; Handle pause key, 1 byte left
    mov BYTE [keycode.state], KC_STATE_WAIT
    jmp .done

.done:
    popa
    iret
