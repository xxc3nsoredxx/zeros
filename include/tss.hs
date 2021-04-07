%ifndef TSS_H_20210406_175625
%define TSS_H_20210406_175625

; Layout of a task-state segment
struc tss_t
    .backlink:              ; TSS selector of previous task
        resw    1
        alignb  4           ; Reserved - set to 0
    .esp0:                  ; Ring 0 esp
        resd    1
    .ss0:                   ; Ring 0 stack selector
        resw    1
        alignb  4           ; Reserved - set to 0
    .esp1:                  ; Ring 1 esp
        resd    1
    .ss1:                   ; Ring 1 stack selector
        resw    1
        alignb  4           ; Reserved - set to 0
    .esp2:                  ; Ring 2 esp
        resd    1
    .ss2:                   ; Ring 2 stack selector
        resw    1
        alignb  4           ; Reserved - set to 0
    .cr3:                   ; Contents of the respective registers
        resd    1
    .eip:
        resd    1
    .eflags:
        resd    1
    .eax:
        resd    1
    .ecx:
        resd    1
    .edx:
        resd    1
    .ebx:
        resd    1
    .esp:
        resd    1
    .ebp:
        resd    1
    .esi:
        resd    1
    .edi:
        resd    1
    .es:
        resw    1
        alignb  4           ; Reserved - set to 0
    .cs:
        resw    1
        alignb  4           ; Reserved - set to 0
    .ss:
        resw    1
        alignb  4           ; Reserved - set to 0
    .ds:
        resw    1
        alignb  4           ; Reserved - set to 0
    .fs:
        resw    1
        alignb  4           ; Reserved - set to 0
    .gs:
        resw    1
        alignb  4           ; Reserved - set to 0
    .ldt:                   ; LDT selector
        resw    1
        alignb  4           ; Reserved - set to 0
    .trap:                  ; Debug trap flag
        resb    1           ; Only bit 0
        alignb  2           ; Reserved - set to 0
    .io_map:                ; I/O map base address
        resw    1
endstruc

%endif ; TSS_H_20210406_175625
; vim: filetype=asm:syntax=nasm:
