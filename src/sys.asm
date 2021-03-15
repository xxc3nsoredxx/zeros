    ; ZerOS system calls
    bits    32

%include "sys.hs"
%include "kb.hs"
%include "vga.hs"

section .text
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
