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

    ; Send IDENTIFY to master drive on primary bus
    mov al, 0xa0            ; Select master drive
    mov dx, 0x01f6          ; Primary bus drive select register
    out dx, al

    mov ecx, 15             ; Reading I/O port 15 times = ~420ns delay
.select_loop:               ; Allows drive time to respond to select
    mov dx, 0x03f6          ; Alternate status register
    in  al, dx
    dec ecx
    jnz .select_loop

    mov al, 0x10            ; nIEN (bit 1), set to disable interrupts
    mov dx, 0x03f6          ; Device control register
    out dx, al

    mov al, 0               ; Set the following to 0
    mov dx, 0x01f2          ; Sector count register
    out dx, al
    mov dx, 0x01f3          ; LBA_lo register
    out dx, al
    mov dx, 0x01f4          ; LBA_mid register
    out dx, al
    mov dx, 0x01f5          ; LBA_hi register
    out dx, al
    mov al, 0xec            ; IDENTIFY
    mov dx, 0x01f7          ; Command register
    out dx, al

    mov dx, 0x01f7          ; Status register
    in  al, dx
    cmp al, 0x00            ; If 0, drive doesn't exist
    jnz .drive_exists
    push DWORD primary_master_not_exist_len
    push primary_master_not_exist
    call puts
    jmp .prompt_loop

.drive_exists:
    push DWORD primary_master_exist_len
    push primary_master_exist
    call puts

.poll_busy_select:
    mov dx, 0x01f7          ; Status register
    in  al, dx
    test al, 0x80           ; Poll until BSY (bit 7) clears
    jnz .poll_busy_select

    mov dx, 0x01f4          ; LBA_mid register
    in  al, dx
    test al, al             ; If non-zero, not ATA
    jnz .drive_not_ata
    mov dx, 0x01f5          ; LBA_hi register
    in  al, dx
    test al, al             ; If non-zero, not ATA
    jnz .drive_not_ata

    push DWORD is_ata_len
    push is_ata
    call puts

.poll_drq_err:
    mov dx, 0x01f7          ; Status register
    in  al, dx
    test al, 0x09           ; Poll until DRQ (bit 3) or ERR (bit 0) are set
    jz  .poll_drq_err

    test al, 0x01           ; If ERR (bit 0) clear, data ready
    jnz .id_failed

    push DWORD id_data_ready_len
    push id_data_ready
    call puts

    push DWORD read_id_data_len
    push read_id_data
    call puts

    mov ecx, 0              ; Read 256 * 16 bits of IDENTIFY data
.read_id_data:
    mov dx, 0x1f0           ; Data register
    in  ax, dx
    mov [id_data + ecx*2], ax   ; Save IDENTIFY data
    inc ecx
    cmp ecx, 256
    jnz .read_id_data

    push DWORD done_len
    push done
    call puts

    push DWORD is_fixed_len
    push is_fixed
    call puts

    test DWORD [id_data], 0x0040    ; uint16_t 0 bit 6 set = is fixed
    jnz .yes_fixed
    push DWORD no_len
    push no
    call puts
    jmp .prompt_loop

.yes_fixed:
    push DWORD yes_len
    push yes
    call puts

    mov eax, [id_data + 60*2]   ; uint16_t 60 and 61 (as uint32_t) is the total
    push eax                    ; number of 28 bit addressable sectors
    push DWORD total_28_bit_sectors_len
    push total_28_bit_sectors
    call printf

    push DWORD has_lba48_len
    push has_lba48
    call puts

    test WORD [id_data + 83*2], 0x0400  ; uint16_t 83 bit 10 set = has LBA48
    jnz .yes_lba48
    push DWORD no_len
    push no
    call puts
    jmp .prompt_loop

.yes_lba48:
    push DWORD yes_len
    push yes
    call puts

    mov eax, [id_data + 100*2]  ; uint16_t 100 to 103 (as uint64_t) is the total
    push eax                    ; number of 48 bit addressable sectors
    mov eax, [id_data + 102*2]
    push eax
    push DWORD total_48_bit_sectors_len
    push total_48_bit_sectors
    call printf

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

.drive_not_ata:
    push DWORD not_ata_len
    push not_ata
    call puts
    jmp .prompt_loop

.id_failed:
    push DWORD id_failed_len
    push id_failed
    call puts
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
string primary_master_not_exist
    db  'Primary master drive does not exist', 0x0a
endstring
string primary_master_exist
    db  'Primary master drive exists', 0x0a
endstring
string not_ata
    db  'Drive not ATA', 0x0a
endstring
string is_ata
    db  'Drive is ATA', 0x0a
endstring
string id_data_ready
    db  'IDENTIFY data ready', 0x0a
endstring
string id_failed
    db  'IDENTIFY failed', 0x0a
endstring
string read_id_data
    db  'Reading IDENTIFY data... '
endstring
string is_fixed
    db  'Is fixed drive: '
endstring
string total_28_bit_sectors
    db  'Total 28 bit addressable sectors: %x', 0x0a
endstring
string has_lba48
    db  'Drive has LBA48 support: '
endstring
string total_48_bit_sectors
    db  'Total 48 bit addressable sectors: %x %x', 0x0a
endstring
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
string yes
    db  'YES', 0x0a
endstring
string no
    db  'NO', 0x0a
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

id_data:
    resw 256

sector:
    resb 512
