    ; Kernel 1
    bits    32

%include    "vga.hs"

section .text
    global  kmain       ; Make kmain visible

kmain:
    push    DWORD [promptlen]
    push    prompt
    call    puts

    jmp $

    ret

section .data
prompt:
    db  'ZerOS > '
promptlen:
    dd  $ - prompt
