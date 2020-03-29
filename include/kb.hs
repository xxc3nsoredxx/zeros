%ifndef KB_HS_20200327_182505
%define KB_HS_20200327_182505

extern  keycode         ; The most recent keypress

; PS/2 ports
%assign KB_DATA 0x60    ; Data port (r/w)
%assign KB_STAT 0x64    ; Status port (r)
%assign KB_CMD  0x64    ; Command port (w)

; Status byte flags (bits)
; 7:    Parity error: 0 (no error), 1 (error)
; 6:    Timeout error: 0 (no error), 1 (error)
; 4-5:  Chipset specific
; 3:    Command/data: 0 (data written is for device), 1 (data is for controller)
; 2:    System flag: cleared on reset, set by firmware after POST
; 1:    Input buffer status: 0 (empty), 1 (full)
; 0:    Output buffer status: 0 (empty), 1 (full)
%assign KB_STAT_OUTPUT  0b00000001

; Keycode modifiers
%assign KC_MOD_SHIFT    0x01
%assign KC_MOD_CAPS     0x02

%endif

; vim: filetype=asm:syntax=nasm:
