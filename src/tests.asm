    ; Basic function test routines
    bits    32

%include "tests.hs"
%include "gdt.hs"
%include "sys.hs"

section .text
; NO_RET exception_test (u32 exception)
; Trigger an exception
exception_test:
    ; Get index into jump table
    mov eax, [esp + 4]      ; Not [ebp + 8], no stack frame created
    jmp [.jump_table + eax*4]

    ; Test #UD
.ud:
    ud2

    ; Test #NP, IDT selector
.np_idt:
    int 0x30

    ; Test #NP, GDT selector
.np_gdt:
    mov ax, GDT_NOT_PRESENT
    mov es, ax

.jump_table:
    dd  .ud
    dd  .np_idt
    dd  .np_gdt

; void printf_test (void)
; Basic printf test
printf_test:
    ; Test just string
    push DWORD [printf_test1_len]
    push printf_test1
    call printf

    ; Test %x
    push 3735929054
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

    ; Test %u
    push 0xdeadc0de
    push DWORD [printf_test6_len]
    push printf_test6
    call printf

    ; Test %u and %x
    push 0xdeadc0de
    push 3735929054
    push DWORD [printf_test7_len]
    push printf_test7
    call printf

    ret

section .rodata
printf_test1:
    db  'Just a basic printf test', 0x0a
printf_test1_len:
    dd  $ - printf_test1
printf_test2:
    db  '3735929054 in hex: %x', 0x0a
printf_test2_len:
    dd  $ - printf_test2
printf_test3:
    db  'Use "%%%%" to print "%%"', 0x0a
printf_test3_len:
    dd  $ - printf_test3
printf_test4:
    db  'Contains "%%q", an invalid format ->%q<-', 0x0a
printf_test4_len:
    dd  $ - printf_test4
printf_test5:
    db  'Ends in incomplete format', 0x0a, '%'
printf_test5_len:
    dd  $ - printf_test5
printf_test6:
    db  '0xdeadc0de in (unsigned) decimal: %u', 0x0a
printf_test6_len:
    dd  $ - printf_test6
printf_test7:
    db  '0x%x (%%x) in (unsigned) decimal: %u (%%u)', 0x0a
printf_test7_len:
    dd  $ - printf_test7
