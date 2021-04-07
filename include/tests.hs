%ifndef TESTS_HS_20210330_210535
%define TESTS_HS_20210330_210535

extern exception_test
extern printf_test

; Exceptions
; Sorted by vector, then by sub-type (if one exists)
%assign UD_TEST     0
%assign DF_TEST     1
%assign NP_IDT_TEST 2
%assign NP_GDT_TEST 3

%endif ; TESTS_HS_20210330_210535
; vim: filetype=asm:syntax=nasm:
