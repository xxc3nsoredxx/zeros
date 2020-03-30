%ifndef KB_HS_20200327_182505
%define KB_HS_20200327_182505

extern  kb_init         ; Keyboard initialization
extern  keycode         ; The most recent keypress

; PS/2 ports
%assign PS2_DATA 0x60   ; Data port (r/w)
%assign PS2_STAT 0x64   ; Status port (r)
%assign PS2_CMD  0x64   ; Command port (w)

; Commands
%assign PS2_DIS_1       0xAD    ; Disable port 1
%assign PS2_EN_1        0xAE    ; Enable port 1
%assign PS2_DIS_2       0xA7    ; Disable port 2
%assign PS2_EN_2        0xA8    ; Enable port 2
%assign PS2_READ_CONF   0x20    ; Read configuration byte
%assign PS2_WRITE_CONF  0x60    ; Write configuration byte

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

; Keycode modifiers
%assign KC_MOD_SHIFT    0x01
%assign KC_MOD_CAPS     0x02

%endif

; vim: filetype=asm:syntax=nasm:
