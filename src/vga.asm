    ; VGA/Screen related functions and constants
    bits    32

%include "vga.hs"

section .text
; void clear (void)
; Clears the screen and moves cursor to top left
clear:
    push ebp
    mov ebp, esp
    push edi
    push esi
    push es

    mov ax, gs              ; Set es to point to VRAM
    mov es, ax

    mov esi, .blanks        ; Write ' ' on all locations 2 chars at a time
    mov edi, 0
    movzx eax, BYTE [ROWS]
    mul BYTE [COLS]
    shr ecx, 1
    mov ecx, eax
.loop:
    movsd
    sub esi, 4
    loop .loop

    mov BYTE [curx], 0
    mov BYTE [cury], 0

    pop es
    pop esi
    pop edi
    mov esp, ebp
    pop ebp
    ret
.blanks:
    dd  0x200A200A

; u32 getpos (void)
; Returns the current x/y pos as address in VRAM
getpos:
    push ebp
    mov ebp, esp
    push ebx

    movzx eax, BYTE [cury]
    movzx ebx, BYTE [curx]
    mul BYTE [COLS]
    add eax, ebx
    add eax, eax

    pop ebx
    mov esp, ebp
    pop ebp
    ret

; void scroll (void)
; Scroll the screen 1 line and move cursor to bottom left
scroll:
    push ebp
    mov ebp, esp
    push edi
    push esi
    push es

    mov ax, gs
    mov es, ax

    mov edi, 0              ; Start of first row
    mov esi, 0              ; Start of second row
    movzx eax, BYTE [COLS]
    add eax, eax
    add esi, eax
    movzx ecx, BYTE [ROWS]  ; Total chars for all but one row
    dec ecx
    movzx eax, BYTE [COLS]
    mul ecx
    mov ecx, eax
    gs rep movsw            ; Move everything one row up

    add eax, eax            ; Start of last row
    movzx ecx, BYTE [COLS]
.loop:
    dec ecx
    mov WORD [gs:eax + 2 * ecx], 0x0A20
    inc ecx
    loop .loop

    mov BYTE [curx], 0      ; Save ROWS - 1, 0 as the pos
    movzx eax, BYTE [ROWS]
    dec eax
    mov BYTE [cury], al

    pop es
    pop esi
    pop edi
    mov esp, ebp
    pop ebp
    ret

section .data
curx:                       ; Current cursor x
    db  0
cury:                       ; Current cursor y
    db  0

section .rodata
ROWS:                       ; Number of rows on screen
    db  25
COLS:                       ; Number of cols
    db  80
COLOR:                      ; Light green on black
    db  0x0A
