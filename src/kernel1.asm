    ; Kernel 1
    bits    32

%include    "vga.hs"

section .text
    global  kmain       ; Make kmain visible

kmain:
    push    DWORD [msglen]
    push    msg
    call    puts

    push    0x0D
    call    putch
    push    0x0A
    call    putch

    %rep    200
    push    'A'
    call    putch
    %endrep

    jmp $

    ret

section .data
msg:
    times 400   db '0123456789'
    db  'Test'
msglen:
    dd  $ - msg
