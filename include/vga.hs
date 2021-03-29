%ifndef VGA_HS_20200312_234110
%define VGA_HS_20200312_234110

; Screen control functions
extern getpos
extern scroll
extern update_cursor
extern vga_init

; Screen parameters (ro)
extern ROWS
extern COLS
extern COLOR

; Screen parameters (rw)
extern curx
extern cury

; VGA registers
%assign VGA_CRTC_ADDR   0x03d4
%assign VGA_CRTC_DATA   0x03d5
%assign VGA_MISC_OUT_R  0x03cc
%assign VGA_MISC_OUT_W  0x03c2

; VGA CRT Controller Resgisters
%assign VGA_CRTC_MAX_SCAN       0x09
%assign VGA_CRTC_CURS_START     0x0a
%assign VGA_CRTC_CURS_END       0x0b
%assign VGA_CRTC_CURS_LOC_HI    0x0e
%assign VGA_CRTC_CURS_LOC_LO    0x0f

; VGA CRTC Maximum Scan Line Register
%assign VGA_CRTC_MAX_SCAN_MSL   0x1f    ; Mask out the max sl field

; VGA Miscellaneous Output Register
%assign VGA_MISC_OUT_IOAS   0x01    ; I/O address select (0x3bX/0x3dX)

%endif

; vim: filetype=asm:syntax=nasm:
