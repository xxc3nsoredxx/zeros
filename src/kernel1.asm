    ; Kernel 1
    bits 32

%assign VGA_BASE 0x000B8000 ; Base address for video memory
%assign ROWS 25             ; Number of rows on screen
%assign COLS 80             ; Number of cols
%assign COLOR 0x0A          ; Light green on black

section .text
    global  kmain   ; Make kmain visible

kmain:
    mov eax, VGA_BASE   ; EAX holds the pointer in video memory
    mov ecx, msg        ; ECX holds the pointer in string
.print:
    cmp BYTE [ecx], 0   ; While not at end of string
    jz .done
    cmp BYTE [ecx], 0x0A    ; Linefeed
    jz .lf
    cmp BYTE [ecx], 0x0D    ; Carriage return
    jz .cr
    mov bl, BYTE [ecx]  ; Regular char
    mov [eax], bl
    mov [eax + 1], BYTE COLOR
    add eax, 2
    inc ecx
    jmp .print
.lf:
    add eax, COLS       ; Move to same position on next line
    add eax, COLS
    inc ecx
    jmp .print
.cr:
    sub eax, VGA_BASE   ; Move to beginning of line
    cdq
    mov ebx, COLS
    add ebx, ebx
    div ebx
    mul ebx
    add eax, VGA_BASE
    inc ecx
    jmp .print
.done:
    jmp $               ; Loop self
section .data
msg:    db 'Hello', 0x0D, 0x0A, 0x00
