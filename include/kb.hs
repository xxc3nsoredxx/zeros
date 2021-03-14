%ifndef KB_HS_20200327_182505
%define KB_HS_20200327_182505

extern  kb_init             ; Keyboard initialization
extern  keycode.mod         ; The most recent keypress (modifier byte)
extern  keycode.key         ; The most recent keypress (value byte)
extern  keycode.state       ; The most recent keypress (state of scan code parse)
extern  SC2_BASIC           ; Keymap for scan code 2 basic keys
extern  SHIFT_TABLE         ; Characters when shift applied

; PS/2 I/O ports
%assign PS2_DATA    0x60    ; Data port (r/w)
%assign PS2_STAT    0x64    ; Status port (r)
%assign PS2_CMD     0x64    ; Command port (w)

; Keyboard I/O ports
%assign KB_CMD      0x60    ; Keyboard command port (r/w)

; Commands
%assign PS2_DIS_1       0xAD    ; Disable port 1
%assign PS2_EN_1        0xAE    ; Enable port 1
%assign PS2_DIS_2       0xA7    ; Disable port 2
%assign PS2_EN_2        0xA8    ; Enable port 2
%assign PS2_READ_CONF   0x20    ; Read configuration byte
%assign PS2_WRITE_CONF  0x60    ; Write configuration byte

; Keyboard response
%assign KB_ACK      0xFA    ; Keyboard ACK

; Status byte flags bits
; 7:    Parity error: 0 (no error), 1 (error)
; 6:    Timeout error: 0 (no error), 1 (error)
; 4-5:  Chipset specific
; 3:    Command/data: 0 (data written is for device), 1 (data is for controller)
; 2:    System flag: cleared on reset, set by firmware after POST
; 1:    Input buffer status: 0 (empty), 1 (full)
; 0:    Output buffer status: 0 (empty), 1 (full)
%assign PS2_STAT_OUTPUT 0b00000001
%assign PS2_STAT_INPUT  0b00000010

; PS/2 Configuration mask bits
; 7:    Zero
; 6:    Port 1 translation: 0 (disabled), 1 (enabled)
; 5:    Port 2 clock: 0 (enabled), 1 (disabled)
; 4:    Port 1 clock: 0 (enabled), 1 (disabled)
; 3:    Zero
; 2:    System flag: 0 (POST success), 1 (OS shouldn't be running)
; 1:    Port 2 interrupt: 0 (disabled), 1 (enabled)
; 0:    Port 1 interrupt: 0 (disabled), 1 (enabled)
%assign PS2_CONF_MASK   0b00110100
%assign PS2_CONF_MASK2  0b00000011

; Keyboard leds
%assign KB_LED_CMD  0xED        ; Command for LED control
%assign KB_LED_OFF  0           ; All off
%assign KB_LED_SL   0b00000001  ; Scroll lock
%assign KB_LED_NL   0b00000010  ; Num lock
%assign KB_LED_CL   0b00000100  ; Caps lock

; Keycode modifiers
; Bits:
;   3-7:    Unused
;   2:      Read:   0 (unread), 1 (read)
;   1:      Caps:   0 (inactive), 1 (active)
;   0:      Shift:  0 (inactive), 1 (active)
%assign KC_MOD_SHIFT    0b00000001
%assign KC_MOD_CAPS     0b00000010
%assign KC_MOD_READ     0b00000100

; Keycode state
; 0x00: Waiting for new scan code
; 0x10: Read 0xE0
; 0x2n: Read 0xE0 12 (print screen, n bytes left)
; 0x30: Read 0xF0 (key released)
; 0x40: Read 0xE0 F0 (E0 key released)
; 0x5n: Read 0xE0 F0 7C (print screen rel, n bytes left)
; 0x6n: Read 0xE1 (pause, n bytes left)
%assign KC_STATE_WAIT   0x00
%assign KC_STATE_E0     0x10
%assign KC_STATE_PS     0x20
%assign KC_STATE_REL    0x30
%assign KC_STATE_E0_REL 0x40
%assign KC_STATE_PS_REL 0x50
%assign KC_STATE_PAUSE  0x60

%endif

; vim: filetype=asm:syntax=nasm:
