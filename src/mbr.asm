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
    push DWORD 1
    call get_partition
    jmp .done

.test_p2:
    mov al, [mbr + mbr_t.p2_type]
    cmp al, [ebp + 8]
    jnz .test_p3
    push DWORD 2
    call get_partition
    jmp .done

.test_p3:
    mov al, [mbr + mbr_t.p3_type]
    cmp al, [ebp + 8]
    jnz .test_p4
    push DWORD 3
    call get_partition
    jmp .done

.test_p4:
    mov al, [mbr + mbr_t.p4_type]
    cmp al, [ebp + 8]
    jnz .not_found
    push DWORD 4
    call get_partition
    jmp .done

.not_found:
    mov eax, 0
    mov edx, 0

.done:
    mov esp, ebp
    pop ebp
    ret 4

; u32,u32 get_partition (u32 partition)
; Gets the bounds of the given partition number
; Return:
;   Starting LBA and sector count of the partition on success
;   0,0 on failure
get_partition:
    push ebp
    mov ebp, esp

    cmp DWORD [ebp + 8], 1  ; Validate 1 <= sector number <= 4
    jl  .error
    cmp DWORD [ebp + 8], 4
    jg  .error

    call read_mbr
    test eax, eax
    jnz .error

    mov ecx, [ebp + 8]      ; Copy the bounds
    mov eax, [.part_start + ecx*4]
    mov eax, [eax]
    mov edx, [.part_length + ecx*4]
    mov edx, [edx]
    jmp .done

.error:
    mov eax, 0
    mov edx, 0
.done:
    mov esp, ebp
    pop ebp
    ret 4
; Both of these have an extra entry at the front for easier indexing
; The entries themselves are pointers, so they need to be dereferenced
.part_start:                ; Lookup table for partition start sectors
    dd 0
    dd mbr + mbr_t.p1_lba
    dd mbr + mbr_t.p2_lba
    dd mbr + mbr_t.p3_lba
    dd mbr + mbr_t.p4_lba
.part_length:               ; Lookup table for partition sector counts
    dd 0
    dd mbr + mbr_t.p1_sectors
    dd mbr + mbr_t.p2_sectors
    dd mbr + mbr_t.p3_sectors
    dd mbr + mbr_t.p4_sectors

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
