    ; Basic function test routines
    bits    32

%include "tests.hs"
%include "sys.hs"

section .text
; void printf_test (void)
; Basic printf test
printf_test:
    ; Test just string
    push DWORD [printf_test1_len]
    push printf_test1
    call printf

    ; Test %x
    push 305441741
    push DWORD [printf_test2_len]
    push printf_test2
    call printf

    ; Test %%
    push DWORD [printf_test3_len]
    push printf_test3
    call printf

    ; Test invalid format
    push DWORD [printf_test4_len]
    push printf_test4
    call printf

    ; Test incomplete format at the end of the string
    push DWORD [printf_test5_len]
    push printf_test5
    call printf

    ret

section .rodata
printf_test1:
    db 'Just a basic printf test', 0x0a
printf_test1_len:
    dd $ - printf_test1
printf_test2:
    db '305441741 in hex: %x', 0x0a
printf_test2_len:
    dd $ - printf_test2
printf_test3:
    db 'Use "%%%%" to print "%%"', 0x0a
printf_test3_len:
    dd $ - printf_test3
printf_test4:
    db 'Contains "%%q", an invalid format ->%q<-', 0x0a
printf_test4_len:
    dd $ - printf_test4
printf_test5:
    db 'Ends in incomplete format', 0x0a, '%'
printf_test5_len:
    dd $ - printf_test5
