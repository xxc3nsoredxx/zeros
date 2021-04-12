    ; Basic function test routines
    bits    32

%include "tests.hs"
%include "gdt.hs"
%include "misc.hs"
%include "panic.hs"
%include "sys.hs"

section .text
; NO_RET exception_test (u32 exception)
; Trigger an exception
; Uses the same selectors as the panic function
exception_test:
    ; Get index into jump table
    mov eax, [esp + 4]      ; Not [ebp + 8], no stack frame created
    jmp [.jump_table + eax*4]

    ; Test #UD
.ud:
    ud2

    ; Test #DF
.df:
    mov esp, 8              ; Set stack pointer to bad value
    push eax                ; push results in #SS being triggered. #SS pushes
                            ; an error code onto the stack. An invalid stack
                            ; triggers a second #SS. #SS is a contributory
                            ; exception, and two contributory exceptions
                            ; trigger a #DF.

    ; Test #NP, IDT selector
.np_idt:
    int 0x30

    ; Test #NP, GDT selector
.np_gdt:
    mov ax, GDT_NOT_PRESENT
    mov es, ax

    ; Test #SS, limit violation
.ss_limit:
    mov eax, ss:[0]

    ; Test #SS, bad selector
.ss_sel:
    mov ax, GDT_NOT_PRESENT
    mov ss, ax

    ; Test #GP, IDT selector
.gp_idt:
    int 0x31

    ; Test #GP, GDT selector
.gp_gdt:
    jmp GDT_DATA_INDEX:$

    ; Test #GP, general case
.gp_gen:
    db 0xf3, 0xf3, 0xf3, 0xf3   ; Instruction length over 15 B causes a
    db 0xf3, 0xf3, 0xf3, 0xf3   ; "general" #GP. This block is 15x rep nop.
    db 0xf3, 0xf3, 0xf3, 0xf3   ; Has to be written by hand because NASM
    db 0xf3, 0xf3, 0xf3         ; does _not_ want to assemble it. And for good
    nop                         ; reason lol ;)

.jump_table:
    dd  .ud
    dd  .df
    dd  .np_idt
    dd  .np_gdt
    dd  .ss_limit
    dd  .ss_sel
    dd  .gp_idt
    dd  .gp_gdt
    dd  .gp_gen

; void printf_test (void)
; Basic printf test
printf_test:
    ; Test just string
    push DWORD printf_test1_len
    push printf_test1
    call printf

    ; Test %x
    push 3735929054
    push DWORD printf_test2_len
    push printf_test2
    call printf

    ; Test %%
    push DWORD printf_test3_len
    push printf_test3
    call printf

    ; Test invalid format
    push DWORD printf_test4_len
    push printf_test4
    call printf

    ; Test incomplete format at the end of the string
    push DWORD printf_test5_len
    push printf_test5
    call printf

    ; Test %u
    push 0xdeadc0de
    push DWORD printf_test6_len
    push printf_test6
    call printf

    ; Test %u and %x
    push 0xdeadc0de
    push 3735929054
    push DWORD printf_test7_len
    push printf_test7
    call printf

    ; Test %s
    push DWORD printf_test9_len
    push printf_test9
    push DWORD printf_test8_len
    push printf_test8
    call printf

    ; Test %s with format in the printed string
    push DWORD printf_test3_len
    push printf_test3
    push DWORD printf_test10_len
    push printf_test10
    call printf

    ret

section .rodata
string printf_test1
    db  'Just a basic printf test', 0x0a
endstring

string printf_test2
    db  '3735929054 in hex: %x', 0x0a
endstring

string printf_test3
    db  'Use "%%%%" to print "%%"', 0x0a
endstring

string printf_test4
    db  'Contains "%%q", an invalid format ->%q<-', 0x0a
endstring

string printf_test5
    db  'Ends in incomplete format', 0x0a, '%'
endstring

string printf_test6
    db  '0xdeadc0de in (unsigned) decimal: %u', 0x0a
endstring

string printf_test7
    db  '0x%x (%%x) in (unsigned) decimal: %u (%%u)', 0x0a
endstring

string printf_test8
    db  'Test printing string: %s', 0x0a
endstring

string printf_test9
    db  'Printed with format :)'
endstring

string printf_test10
    db  'String with formats: %s'
endstring
