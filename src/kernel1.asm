    ; Kernel 1
    bits    32

%include "misc.hs"
%include "panic.hs"
%include "sys.hs"
%include "tests.hs"
%include "vga.hs"

section .text
    global  kmain           ; Make kmain visible

kmain:
    call clear              ; Clear sets bg/fg colors in each cell

    ; Tests
    call printf_test

    ; TODO: THIS SHIT BROKEN BRUH
    ;push DWORD TS_PANIC
    ;call exception_test

    ; Setup to read a sector
    mov dx, 0x01f6              ; Drive / head register
    mov al, 0xe0                ; bits 0 to 3 - bits 24 to 27 of block number
                                ;               0000
                                ; bit 4 - DRV, drive number (0 for master)
                                ; bit 5 - always 1
                                ; bit 6 - LBA, choose LBA/CHS (1 for LBA)
                                ; bit 7 - always 1
    out dx, al

    mov al, 0x00                ; NULL just to waste time
    mov dx, 0x01f1              ; Features register
    out dx, al

    mov dx, 0x01f2              ; Sector count register
    mov al, 1
    out dx, al

    mov dx, 0x01f3              ; LBA_lo register
    mov al, 0
    out dx, al
    mov dx, 0x01f4              ; LBA_mid register
    out dx, al
    mov dx, 0x01f5              ; LBA_hi register
    out dx, al

    mov dx, 0x01f7              ; Command register
    mov al, 0x20                ; READ SECTORS command
    out dx, al

.poll_data:
    mov dx, 0x01f7          ; Status register
    in  al, dx
    test al, 0x21           ; Failed if ERR (bit 0) or DF (bit 5) is set
    jnz .read_sector_failed
    and al, 0x88            ; Poll until BSY (bit 7) clears and DRQ (bit 3) sets
    cmp al, 0x08
    jnz .poll_data

    push DWORD read_sector_len
    push read_sector
    call puts

    mov dx, 0x01f0          ; Data register
    mov ecx, 0
.data_loop:
    in  ax, dx
    mov [sector + ecx*2], ax
    inc ecx
    cmp ecx, 256
    jnz .data_loop

    push DWORD done_len
    push done
    call puts

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
    ;mov ax, [sector + ecx*2 + 2]
    ;shl eax, 16
    ;mov ax, [sector + ecx*2]
    push eax
    call putintx
    ;push DWORD sector_data_len
    ;push sector_data
    ;call printf

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

.read_sector_failed:
    push DWORD read_sector_failed_len
    push read_sector_failed
    call puts
    jmp .prompt_loop

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

    push input_buf          ; Print input
    call puts               ; The length is alread at the top of the stack

    jmp .prompt_loop        ; Loop

    ret

section .rodata
string read_sector_failed
    db  'READ SECTOR command failed!'
endstring
string read_sector
    db  'Reading sector... '
endstring
string sector_print
    db  'Sector 0: ', 0x0a
endstring
string sector_data
    db  '%x '
endstring

string done
    db  'DONE', 0x0a
endstring

string prompt
    db  'ZerOS > '
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
