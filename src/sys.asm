    ; ZerOS system calls
    bits    32

%include "sys.hs"
%include "kb.hs"
%include "vga.hs"

section .text
;;;;;;;;;;;
;; INPUT ;;
;;;;;;;;;;;

; u32 getsn (char *buffer, u32 count)
; Read a single line or count characters from the keyboard into buffer,
; whichever comes first. The terminating newline (if any) is included.
; Return number of characters read.
getsn:
    push ebp
    mov ebp, esp
    push edi

    mov edi, [ebp + 8]      ; Buffer to read in to
    mov ecx, [ebp + 12]     ; Count to read
    cmp ecx, 0
    jz .done                ; 0, don't read anything

.loop:
    mov al, [keycode.mod]   ; Test if key already read
    and al, KC_MOD_READ
    jnz .loop
    movzx eax, BYTE [keycode.key]   ; Test for null key
    cmp al, 0
    jz  .loop
    stosb                   ; Save the character in the buffer
    cmp al, 0x0a            ; Test for return key
    jnz .print
    mov al, [keycode.mod]   ; Set the read bit
    or  al, KC_MOD_READ
    mov [keycode.mod], al
    dec ecx
    jmp .done               ; EOL

.print:
    push ecx                ; Save counter
    push eax                ; Otherwise, print key
    call putch
    pop ecx                 ; Restore counter
    mov al, [keycode.mod]   ; Set the read bit
    or  al, KC_MOD_READ
    mov [keycode.mod], al

    dec ecx                 ; Get a new character
    cmp ecx, 0
    jnz .loop

.done:
    mov eax, [ebp + 12]     ; Get number of characters read
    sub eax, ecx

    pop edi
    mov esp, ebp
    pop ebp
    ret 8

;;;;;;;;;;;;
;; OUTPUT ;;
;;;;;;;;;;;;

; void putch (char c)
; Prints a single character on the screem
putch:
    push ebp
    mov ebp, esp
    push ebx

    mov bl, [ebp + 8]       ; Build the letter+attribute into BX
    cmp bl, 0x0D            ; Test carriage return
    jz  .cr
    cmp bl, 0x0A            ; Test newline
    jz  .nl
    mov bh, [COLOR]
    push eax
    call getpos
    mov WORD [gs:eax], bx   ; Write to screen
    pop eax
    inc BYTE [curx]
    mov bl, [COLS]          ; Test word wrap
    cmp [curx], bl
    jz  .wrap
    jmp .done
.cr:                        ; Handle carriage return
    mov BYTE [curx], 0
    jmp .done
.nl:                        ; Handle newline
    inc BYTE [cury]
    jmp .testscroll
.wrap:                      ; Handle word wrap
    inc BYTE [cury]
    mov BYTE [curx], 0
.testscroll:
    mov bl, [ROWS]          ; Test scroll
    cmp [cury], bl
    jnz .done
    call scroll
.done:
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4

; void puts (char *str, int len)
; Print a string of length len on the screen
puts:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    push esi
    push es

    mov ax, gs
    mov es, ax

    mov ecx, [ebp + 12]     ; Length of the string
    cmp ecx, 0
    jz  .done               ; Skip all if zero length
    mov esi, [ebp + 8]      ; Address of the first character
    call getpos             ; Get the current pos
    mov edi, eax
    movzx ebx, BYTE [COLOR]

.print:
    cmp BYTE [esi], 0x0A    ; Line feed
    je  .lf
    cmp BYTE [esi], 0x0D    ; Carriage return
    je  .cr
    movsb                   ; Regular char
    mov BYTE [gs:edi], bl   ; Color
    inc edi
    movzx eax, BYTE [curx]
    inc eax
    cmp al, BYTE [COLS]     ; Test for word wrap
    jne .nowrap
    mov BYTE [curx], 0
    movzx eax, BYTE [cury]
    inc eax
    cmp al, BYTE [ROWS]     ; Test for wrap scroll
    jne .nowrapscroll
    push ecx
    call scroll
    pop ecx
    call getpos
    mov edi, eax
    loop .print
    jmp .done
.nowrap:
    mov [curx], al
    loop .print
    jmp .done
.nowrapscroll:
    mov [cury], al
    loop .print
    jmp .done
.lf:
.cr:
    mov BYTE [curx], 0      ; Go to start of line
    movzx eax, BYTE [cury]  ; Go down a line
    inc eax
    cmp al, [ROWS]
    jne .noscroll
    push ecx
    call scroll
    pop ecx
    jmp .skip
.noscroll:
    mov [cury], al
.skip:
    call getpos
    mov edi, eax
    inc esi
    loop .print_jmp
.done:
    pop es
    pop esi
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 8
.print_jmp:
    jmp .print
