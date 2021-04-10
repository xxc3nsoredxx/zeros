    ; Kernel 1
    bits    32

%include "panic.hs"
%include "sys.hs"
%include "tests.hs"
%include "vga.hs"

section .text
    global  kmain           ; Make kmain visible

kmain:
    call clear              ; Clear sets bg/fg colors in each cell

    ; Tests
    call printf_test

    push DWORD GP_GEN_PANIC
    call exception_test

.prompt_loop:
    push DWORD [prompt_len] ; Show prompt
    push prompt
    call puts

    push DWORD [input_len]  ; Get input
    push input_buf
    call getsn
    push eax                ; Save read count

    mov eax, 0x0d           ; Go to new line
    push eax
    call putch
    mov eax, 0x0a
    push eax
    call putch

    push input_buf          ; Print input
    call puts               ; The length is alread at the top of the stack

    jmp .prompt_loop        ; Loop

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
    resb 100
input_buf_end:
    resb 1
