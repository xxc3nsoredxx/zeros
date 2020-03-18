    ; Kernel 1
    bits    32

%include    "vga.hs"

section .text
    global  kmain   ; Make kmain visible

kmain:
    push    DWORD [msglen]
    push    msg
    call    puts

    push    DWORD [msg2len]
    push    msg2
    call    puts

    push    DWORD [msg3len]
    push    msg3
    call    puts

    jmp $

section .data
msg:
    db  'Hello', 0x0A, 0x0D
msglen:
    dd  $ - msg
msg2:
    db  'World'
    times 2 db 0x0A, 0x0D
    times 3 db  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', 0x0A, 0x0D
    times 5 db  0x0A, 0x0D
    db  'HHHHHHH', 0x0A, 'IIIIIIIIIIIII'
    times 10    db 0x0A, 0x0D
    times 5 db  'NNNNNNNNNNNNNNNNNNNNNNNNN', 0x0A, 0x0D
msg2len:
    dd  $ - msg2
msg3:
    times 400   db '0123456789'
    db  'Test'
msg3len:
    dd  $ - msg3
