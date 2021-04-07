    ; Interrupt handlers
    bits    32

%include "idt.hs"
%include "kb.hs"
%include "sys.hs"
%include "vga.hs"

section .text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; P-Mode exception handlers ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Invalid Opcode Exception
; Class: fault
; Error code: no
ud_int:
    ; Disable cursor
    ; Set bit 5 of Cursor Start to disable the dursor
    mov dx, VGA_CRTC_ADDR
    mov al, VGA_CRTC_CURS_START
    out dx, al
    mov dx, VGA_CRTC_DATA
    mov al, 0x10
    out dx, al

    ; Set the color scheme
    mov al, [PANIC_COLOR]
    mov [color], al
    call clear

    ; Print #UD panic message
    push DWORD [panic_ud_int_len]
    push panic_ud_int
    call printf
    hlt

; Double Fault Exception
; Class: abort
; Error code: 0
df_int:
    ; Disable cursor
    ; Set bit 5 of Cursor Start to disable the dursor
    jmp $
    mov dx, VGA_CRTC_ADDR
    mov al, VGA_CRTC_CURS_START
    out dx, al
    mov dx, VGA_CRTC_DATA
    mov al, 0x10
    out dx, al

    ; Set the color scheme
    mov al, [PANIC_COLOR]
    mov [color], al
    call clear

    ; Print #DF panic message
    push DWORD [panic_df_int_len]
    push panic_df_int
    call printf
    hlt

; Segment Not Present
; Class: fault
; Error code: yes
np_int:
    ; Disable cursor
    ; Set bit 5 of Cursor Start to disable the dursor
    mov dx, VGA_CRTC_ADDR
    mov al, VGA_CRTC_CURS_START
    out dx, al
    mov dx, VGA_CRTC_DATA
    mov al, 0x10
    out dx, al

    ; Set the color scheme
    mov al, [PANIC_COLOR]
    mov [color], al
    call clear

    ; Get the error code
    ; Top 16 bits are reserved
    pop eax

    ; Test if selector is for IDT or GDT/LDT
    ; bit 1 set: IDT
    ; bit 1 clear: GDT/LDT
    bt  ax, 1
    jnc .gdt_ldt
    ; Print IDT panic message
    ; Push IDT selector
    shr eax, 3
    push eax
    push DWORD [panic_np_int_len]
    push panic_np_int
    call printf
    hlt

.gdt_ldt:
    ; Test if selector is for GDT or LDT
    ; bit 2 set: LDT
    ; bit 2 clear: GDT
    bt  ax, 2
    jnc .gdt
    ; TODO: Implement LDT code
    hlt

.gdt:
    ; Print GDT panic message
    ; Push GDT slector
    and ax, 0xfff4
    push eax
    push DWORD [panic_np_gdt_len]
    push panic_np_gdt
    call printf
    hlt

;;;;;;;;;;;;;;;;;;
;; PIC handlers ;;
;;;;;;;;;;;;;;;;;;

; PIC master null handler
master_null:
    pusha
    mov al, PIC_EOI         ; Send EOI to PIC
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

    in  al, PS2_DATA        ; Get the scancode
    mov bl, [keycode.state] ; Get the current state
    cmp bl, KC_STATE_WAIT   ; New key
    jz  .new
    cmp bl, KC_STATE_E0     ; E0 key
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

.new:                       ; Handle new key
    cmp al, 0xE0            ; New E0 key
    jz  .new_e0
    cmp al, 0xF0            ; New released key
    jz  .new_rel
    cmp al, 0xE1            ; New pause key
    jz  .new_pause
    movzx eax, BYTE [SC2_BASIC + eax]   ; New basic key
    cmp al, 0x0A            ; Handle return
    jz  .save_key
    cmp al, 0x91            ; Handle caps lock
    jz  .caps
    cmp al, 0x92            ; Handle shift
    jz  .shift
    cmp al, 0x9D
    jz  .shift
    mov bl, [keycode.mod]   ; If caps, do uppercase
    and bl, KC_MOD_CAPS
    jz  .nocaps
    cmp al, 'a'             ; Test if letter
    jb  .nocaps
    cmp al, 'z'
    ja  .nocaps
    movzx eax, BYTE [SHIFT_TABLE + eax]
.nocaps:
    mov bl, [keycode.mod]   ; Test for shift
    and bl, KC_MOD_SHIFT
    jz  .noshift
    movzx eax, BYTE [SHIFT_TABLE + eax]
.noshift:
.save_key:
    mov [keycode.key], al   ; Save the key's value
    mov al, KC_MOD_READ     ; Ensure read bit is unset
    not al
    and [keycode.mod], al
    jmp .done
.caps:
    mov al, [keycode.mod]   ; Toggle caps lock flag
    xor al, KC_MOD_CAPS
    mov [keycode.mod], al
    jmp .done
.shift:
    mov al, [keycode.mod]   ; Set shift flag
    or  al, KC_MOD_SHIFT
    mov [keycode.mod], al
    jmp .done
.new_e0:                    ; Set E0 state
    mov BYTE [keycode.state], KC_STATE_E0
    jmp .done
.new_rel:                   ; Set release state
    mov BYTE [keycode.state], KC_STATE_REL
    jmp .done
.new_pause:                 ; Set pause state, 7 bytes left
    mov BYTE [keycode.state], KC_STATE_PAUSE + 7
    jmp .done

.e0:                        ; Handle new E0 keys
    cmp al, 0x12            ; New print screen key
    jz  .new_ps
    cmp al, 0xF0            ; E0 key released
    jz  .new_e0_rel
    mov BYTE [keycode.state], KC_STATE_WAIT ; Basic E0 key (currently ignored)
    jmp .done
.new_ps:                    ; Set print screen 2 bytes left state
    mov BYTE [keycode.state], KC_STATE_PS + 2
    jmp .done
.new_e0_rel:                ; Set E0 released state
    mov BYTE [keycode.state], KC_STATE_E0_REL
    jmp .done

.ps2:                       ; Handle print screen, 2 bytes left
    dec BYTE [keycode.state]
    jmp .done

.ps1:                       ; Handle print screen, 1 byte left
    mov BYTE [keycode.state], KC_STATE_WAIT
    jmp .done

.rel:                       ; Handle released key
    mov al, [SC2_BASIC + eax]   ; Get basic key
    cmp al, 0x92            ; Handle shift
    jz  .shift_rel
    cmp al, 0x9D
    jz  .shift_rel
    mov BYTE [keycode.state], KC_STATE_WAIT
    jmp .done
.shift_rel:                 ; Handle released shift
    mov al, [keycode.mod]   ; Clear shift flag
    and al, ~KC_MOD_SHIFT
    mov [keycode.mod], al
    mov BYTE [keycode.state], KC_STATE_WAIT
    jmp .done

.e0_rel:                    ; Handle relaeased E0 key
    cmp al, 0x7C            ; Print screen released
    jz  .new_ps_rel
    mov BYTE [keycode.state], KC_STATE_WAIT
    jmp .done
.new_ps_rel:                ; Set print screen released 3 bytes left state
    mov BYTE [keycode.state], KC_STATE_PS_REL + 3
    jmp .done

.ps_rel3:                   ; Handle released print screen, 3 bytes left
    dec BYTE [keycode.state]
    jmp .done

.ps_rel2:                   ; Handle released print screen, 2 bytes left
    dec BYTE [keycode.state]
    jmp .done

.ps_rel1:                   ; Handle released print screen, 1 byte left
    mov BYTE [keycode.state], KC_STATE_WAIT
    jmp .done

.pause7:                    ; Handle pause key, 7 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause6:                    ; Handle pause key, 6 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause5:                    ; Handle pause key, 5 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause4:                    ; Handle pause key, 4 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause3:                    ; Handle pause key, 3 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause2:                    ; Handle pause key, 2 bytes left
    dec BYTE [keycode.state]
    jmp .done

.pause1:                    ; Handle pause key, 1 byte left
    mov BYTE [keycode.state], KC_STATE_WAIT
    jmp .done

.done:
    popa
    iret

section .rodata
PANIC_COLOR:
    db  VGA_BG_WHITE | VGA_FG_L_RED

panic_ud_int:
    db  'PANIC: INVALID OR UNDEFINED OPCODE', 0x0a
    db  '   EIP:    %x', 0x0a
    db  '    CS:    %x', 0x0a
    db  'EFLAGS:    %x'
panic_ud_int_len:
    dd  $ - panic_ud_int
panic_df_int:
    db  'PANIC: !!! DOUBLE FAULT !!!'
panic_df_int_len:
    dd  $ - panic_df_int
panic_np_int:
    db  'PANIC: UNHANDLEABLE INTERRUPT', 0x0a
    db  'Missing gate: %u', 0x0a
    db  '   EIP:    %x', 0x0a
    db  '    CS:    %x', 0x0a
    db  'EFLAGS:    %x'
panic_np_int_len:
    dd  $ - panic_np_int
panic_np_gdt:
    db  'PANIC: ATTEMPTTED LOAD OF INVALID SEGMENT', 0x0a
    db  'Bad selector: %u', 0x0a
    db  '   EIP:    %x', 0x0a
    db  '    CS:    %x', 0x0a
    db  'EFLAGS:    %x'
panic_np_gdt_len:
    dd  $ - panic_np_gdt
