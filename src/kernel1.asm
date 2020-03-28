    ; Kernel 1
    bits    32

%include    "vga.hs"

section .text
    global  kmain       ; Make kmain visible

kmain:
    push    DWORD [msglen]
    push    msg
    call    puts

    jmp $

    ret

section .data
msg:
    times 400   db '0123456789'
    db  'Test'
msglen:
    dd  $ - msg
