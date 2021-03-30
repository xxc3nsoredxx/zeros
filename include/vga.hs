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
extern DEF_COLOR

; Screen parameters (rw)
extern curx
extern cury
extern color

; VGA foreground colors
%assign VGA_FG_BLACK        0x00
%assign VGA_FG_BLUE         0x01
%assign VGA_FG_GREEN        0x02
%assign VGA_FG_CYAN         0x03
%assign VGA_FG_RED          0x04
%assign VGA_FG_MAGENTA      0x05
%assign VGA_FG_BROWN        0x06
%assign VGA_FG_L_GRAY       0x07
%assign VGA_FG_D_GRAY       0x08
%assign VGA_FG_L_BLUE       0x09
%assign VGA_FG_L_GREEN      0x0a
%assign VGA_FG_L_CYAN       0x0b
%assign VGA_FG_L_RED        0x0c
%assign VGA_FG_L_MAGENTA    0x0d
%assign VGA_FG_YELLOW       0x0e
%assign VGA_FG_WHITE        0x0f

; VGA background colors
%assign VGA_BG_BLACK        0x00
%assign VGA_BG_BLUE         0x10
%assign VGA_BG_GREEN        0x20
%assign VGA_BG_CYAN         0x30
%assign VGA_BG_RED          0x40
%assign VGA_BG_MAGENTA      0x50
%assign VGA_BG_BROWN        0x60
%assign VGA_BG_L_GRAY       0x70
%assign VGA_BG_D_GRAY       0x80
%assign VGA_BG_L_BLUE       0x90
%assign VGA_BG_L_GREEN      0xa0
%assign VGA_BG_L_CYAN       0xb0
%assign VGA_BG_L_RED        0xc0
%assign VGA_BG_L_MAGENTA    0xd0
%assign VGA_BG_YELLOW       0xe0
%assign VGA_BG_WHITE        0xf0

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
