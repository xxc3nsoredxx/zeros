%ifndef VGA_HS_20200312_234110
%define VGA_HS_20200312_234110

; Screen control functions
extern clear
extern getpos
extern scroll

; Screen parameters (ro)
extern ROWS
extern COLS
extern COLOR

; Screen parameters (rw)
extern curx
extern cury

%endif

; vim: filetype=asm:syntax=nasm:
