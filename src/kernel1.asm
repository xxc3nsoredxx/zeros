    ; Kernel 1
    bits    32

%include "sys.hs"

section .text
    global  kmain           ; Make kmain visible

kmain:
.prompt_loop:
    push DWORD [prompt_len] ; Show prompt
    push prompt
    call puts

    push DWORD [input_len]  ; Get input
    push input_buf
    call getsn
    push eax                ; Save read count

    mov eax, 0x0D           ; Go to new line
    push eax
    call putch
    mov eax, 0x0A
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
    resb 25
input_buf_end:
    resb 1
