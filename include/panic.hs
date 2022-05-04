%ifndef PANIC_H_20210408_220825
%define PANIC_H_20210408_220825

extern eflags_info
extern panic

; Panic info struct
struc panic_info_t
    .title:                 ; PANIC: [title]
        resd    1           ; char *
    .title_len:             ; Title length
        resd    1           ; u32
    .has_error:             ; Does stack contain error code
        resb    1           ; true/false
    .is_task:               ; Is the panic created by a task gate
        resb    1           ; true/false
        alignb  4
    .error_msg:             ; Message to print with error code
        resd    1           ; char *
    .error_msg_len:         ; Message length
        resd    1           ; u32
endstruc

; Panic selector
%assign UD_PANIC        0
%assign DF_PANIC        1
%assign TS_PANIC        2
%assign NP_IDT_PANIC    3
%assign NP_GDT_PANIC    4
%assign SS_LIMIT_PANIC  5
%assign SS_SEL_PANIC    6
%assign GP_IDT_PANIC    7
%assign GP_GDT_PANIC    8
%assign GP_GEN_PANIC    9

%endif ; PANIC_H_20210408_220825
; vim: filetype=asm:syntax=nasm:
