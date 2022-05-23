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

    ;call ext2_info

.prompt_loop:
    push DWORD prompt_len   ; Show prompt
    push prompt
    call puts

    push DWORD [input_len]  ; Get input
    push input_buf
    call getsn
    mov [input_read_len], eax   ; Save read count

    mov eax, 0x0d           ; Go to new line
    push eax
    call putch
    mov eax, 0x0a
    push eax
    call putch

    push DWORD command_cat_len  ; Test for the "cat" command
    push command_cat
    push input_buf
    call streq
    test eax, eax
    jnz .no_cat

    cmp BYTE [input_buf + command_cat_len], 0x20    ; Test for space
    jnz .no_cat

    mov eax, [input_read_len]
    sub eax, command_cat_len + 2    ; Get the length of the number
    push eax
    push input_buf + command_cat_len + 1    ; Start of number
    call stoi
    cmp edx, 1
    jz  .no_cat

    push eax
    call print_file

    jmp .prompt_loop

.no_cat:
    push DWORD command_inode_len   ; Test for the "inode" command
    push command_inode
    push input_buf
    call streq
    test eax, eax
    jnz .no_inode

    cmp BYTE [input_buf + command_inode_len], 0x20  ; Test for space
    jnz .no_inode

    mov eax, [input_read_len]
    sub eax, command_inode_len + 2  ; Get the length of the (hopefully) number
                                    ; -2 for ' ' and terminating newline
    push eax
    push input_buf + command_inode_len + 1  ; Start of (hopefully) number
    call stoi
    cmp edx, 1
    jz  .no_inode           ; Failed to turn input into number ;(

    push eax
    call print_inode

    jmp .prompt_loop

.no_inode:
    push DWORD command_sector_len   ; Test for the "sector" command
    push command_sector
    push input_buf
    call streq
    test eax, eax
    jnz .no_sector

    push DWORD 1
    push DWORD 0
    push sector
    call read_sector
    test eax, eax
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
    push DWORD [input_read_len] ; Print the input
    push input_buf
    call puts

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

string command_cat
    db  'cat'
endstring
string command_inode
    db  'inode'
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
input_read_len:
    resd 1

sector:
    resb 512
