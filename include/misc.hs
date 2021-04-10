%ifndef MISC_HS_20210410_123510
%define MISC_HS_20210410_123510
    ; Miscellaneous helper macros

; Begin a string definition
; Args:
;   1: string name
; Error if used before endstring macro has been called
%imacro string 1
%ifctx str
    %error "`string` called before ending a previous `string`"
%else
    %push str
    %define %$strname %1
    %$strname:
%endif
%endmacro

; End a string definition
; Defines the appropriate [string name]_len
; Error if used without corresponding string macro
%imacro endstring 0
%ifctx str
    %{$strname}_len:   equ $ - %$strname
    %pop str
%else
    %error "expected `string` before `endstring`"
%endif
%endmacro

%endif ; MISC_HS_20210410_123510
; vim: filetype=asm:syntax=nasm:
