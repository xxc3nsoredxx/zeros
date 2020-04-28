    ; Kernel 1
    bits    32

%include    "kb.hs"
%include    "vga.hs"

section .text
    global  kmain       ; Make kmain visible

kmain:
prompt_loop:
    push    DWORD [prompt_len]
    push    prompt
    call    puts

    mov ecx, [input_len]    ; Prompt for only enough to fill input buffer
.loop:
    mov al, [keycode.mod]   ; Test if key already read
    and al, KC_MOD_READ
    jnz .loop
    movzx   eax, BYTE [keycode.key] ; Test for null key
    cmp al, 0
    jz  .loop
    cmp al, 0x0A        ; Test for return key
    jnz .print
    mov al, [keycode.mod]   ; Set the read bit
    or  al, KC_MOD_READ
    mov [keycode.mod], al
    jmp .done           ; Get new line
.print:
    push    eax         ; Otherwise print key
    call    putch
    mov al, [keycode.mod]   ; Set the read bit
    or  al, KC_MOD_READ
    mov [keycode.mod], al
    loop    .loop       ; Get new character
.done:

    mov eax, 0x0D       ; Go to new line
    push    eax
    call    putch
    mov eax, 0x0A
    push    eax
    call    putch

    jmp prompt_loop

    ret

section .data
prompt:
    db  'ZerOS > '
prompt_len:
    dd  $ - prompt
input_len:
    dd  input_buf_end - input_buf

section .bss
input_buf:
    resb    10
input_buf_end:
    resb    1
