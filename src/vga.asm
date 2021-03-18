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

; void update_cursor (void)
; Moves the text mode cursor to the current position on screen
update_cursor:
    ; Set the high byte first
    mov dx, VGA_CRTC_ADDR
    mov al, VGA_CRTC_CURS_LOC_HI
    out dx, al

    ; Get the position (in VRAM)
    call getpos
    ; Divide by 2 to get position on screen
    shr eax, 1
    ; Save a backup copy
    mov ecx, eax
    ; Extract and send the high byte
    shr eax, 8
    mov dx, VGA_CRTC_DATA
    out dx, al

    ; Send the low byte
    mov dx, VGA_CRTC_ADDR
    mov al, VGA_CRTC_CURS_LOC_LO
    out dx, al
    ; Restore from backup and send
    mov eax, ecx
    mov dx, VGA_CRTC_DATA
    out dx, al
    ret

; void vga_init (void)
; Initializes the screen:
;   - Set the VGA I/O addresses to use 0x3dX
;   - Set the cursor (block) (not yet)
; Only called in kernel0
vga_init:
    ; Set the I/O addresses to 0x3dX
    mov dx, VGA_MISC_OUT_R
    in  al, dx
    or  al, VGA_MISC_OUT_IOAS
    mov dx, VGA_MISC_OUT_W
    out dx, al
    ret

    ; Get the max scan line (ie, font height) into cl
    ; mov dx, VGA_CRTC_ADDR
    ; mov al, VGA_CRTC_MAX_SCAN
    ; out dx, al
    ; mov dx, VGA_CRTC_DATA
    ; in  al, dx
    ; and al, VGA_CRTC_MAX_SCAN_MSL
    ; mov cl, al

    ; Set start of cursor to top (ie, scan line 0)
    ; Cursor Start has an additional field, Cursor Disable, bit 5. This can
    ; safely be ignored and set to 0 (ie, cursor enabled).
    ; mov dx, VGA_CRTC_ADDR
    ; mov al, VGA_CRTC_CURS_START
    ; out dx, al
    ; mov dx, VGA_CRTC_DATA
    ; xor al, al
    ; out dx, al

    ; Set end of cursor to bottom (ie, max scan line)
    ; Cursor End has an additional field, Cursor Skew, bits 5-6. This can
    ; safely be ignored and set to 0 (ie, no skew).
    ; mov dx, VGA_CRTC_ADDR
    ; mov al, VGA_CRTC_CURS_END
    ; out dx, al
    ; mov dx, VGA_CRTC_DATA
    ; mov al, cl
    ; out dx, al
    ; ret

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
