    ; Kernel 1
    bits    32

%include "ext2.hs"
%include "ide.hs"
%include "misc.hs"
%include "panic.hs"
%include "sys.hs"
%include "tests.hs"

section .text
    global  kmain           ; Make kmain visible

kmain:
    call clear              ; Clear sets bg/fg colors in each cell

    ; Tests
    ;call printf_test

    ; TODO: THIS SHIT BROKEN BRUH
    ;push DWORD TS_PANIC
    ;call exception_test

    call ext2_info

.prompt_loop:
    push DWORD prompt_len   ; Show prompt
    push prompt
    call puts

    push DWORD [input_len]  ; Get input
    push input_buf
    call getsn
    push eax                ; Save read count

    mov eax, 0x0d           ; Go to new line
    push eax
    call putch
    mov eax, 0x0a
    push eax
    call putch

    push DWORD command_sector_len   ; Test for the "sector" command
    push command_sector
    push input_buf
    call streq
    jnz .no_sector

    push DWORD 1
    push DWORD 0
    push sector
    call read_sector
    jnz .no_sector

    push DWORD sector_print_len
    push sector_print
    call puts

    mov ebx, 0              ; ebx isn't clobbered by functions
.print_sector:              ; Print the sector
    mov al, [sector + ebx]
    shl eax, 8
    mov al, [sector + ebx + 1]
    shl eax, 8
    mov al, [sector + ebx + 2]
    shl eax, 8
    mov al, [sector + ebx + 3]
    push eax
    call putintx

    add ebx, 4

    test ebx, 0x1f          ; New line after 8 groups of 4 bytes, test mod 32
    jnz .print_space
    push 0x0d
    push 0x0a
    call putch
    call putch
    jmp .loop_next

.print_space:
    push ' '
    call putch

.loop_next:
    cmp ebx, 512
    jnz .print_sector
    jmp .prompt_loop

.no_sector:
    push input_buf          ; Print input
    call puts               ; The length is alread at the top of the stack

    jmp .prompt_loop        ; Loop

    ret

section .rodata
string sector_print
    db  'Sector 0: ', 0x0a
endstring
string sector_data
    db  '%x '
endstring

string prompt
    db  'ZerOS > '
endstring

string command_sector
    db  'sector'
endstring

section .data
input_len:
    dd  input_buf_end - input_buf

section .bss
input_buf:
    resb 100
input_buf_end:
    resb 1

sector:
    resb 512
