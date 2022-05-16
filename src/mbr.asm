    ; MBR driver
    bits 32

%include "mbr.hs"
%include "ide.hs"

section .text
; u32,u32 find_partition (u32 type)
; Find the first partition of the given type.
; Return:
;   Starting LBA and sector count of the partition on success
;   0,0 on failure
find_partition:
    push ebp
    mov ebp, esp

    call read_mbr
    test eax, eax
    jnz .not_found

    mov al, [mbr + mbr_t.p1_type]
    cmp al, [ebp + 8]
    jnz .test_p2
    mov eax, [mbr + mbr_t.p1_lba]
    mov edx, [mbr + mbr_t.p1_sectors]
    jmp .done

.test_p2:
    mov al, [mbr + mbr_t.p2_type]
    cmp al, [ebp + 8]
    jnz .test_p3
    mov eax, [mbr + mbr_t.p2_lba]
    mov edx, [mbr + mbr_t.p2_sectors]
    jmp .done

.test_p3:
    mov al, [mbr + mbr_t.p3_type]
    cmp al, [ebp + 8]
    jnz .test_p4
    mov eax, [mbr + mbr_t.p3_lba]
    mov edx, [mbr + mbr_t.p3_sectors]
    jmp .done

.test_p4:
    mov al, [mbr + mbr_t.p4_type]
    cmp al, [ebp + 8]
    jnz .not_found
    mov eax, [mbr + mbr_t.p4_lba]
    mov edx, [mbr + mbr_t.p4_sectors]
    jmp .done

.not_found:
    mov eax, 0
    mov edx, 0

.done:
    mov esp, ebp
    pop ebp
    ret

; u32 read_mbr (void)
; Reads the partition table.
; Return:
;   0 on success
;   1 on failure
read_mbr:
    push ebp
    mov ebp, esp

    mov eax, 0                          ; Skip if MBR already read
    mov ax, [mbr + mbr_t.boot_magic]    ; Use a fancy trick to set eax to 0 if
    sub ax, MBR_BOOT_MAGIC              ; it is read
    jz  .done

    push DWORD 1
    push DWORD 0
    push mbr
    call read_sector
    test eax, eax
    jnz .error

    mov eax, 0
    jmp .done

.error:
    mov eax, 1
.done:
    mov esp, ebp
    pop ebp
    ret

section .bss
mbr:
    resb 512
