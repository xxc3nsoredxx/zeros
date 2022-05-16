    ; Ext2 drivers
    bits 32

%include "ext2.hs"
%include "ide.hs"
%include "mbr.hs"
%include "misc.hs"
%include "sys.hs"

; void ext2_info (void)
; Prints some info about the filesystem from the superblock
ext2_info:
    push ebp
    mov ebp, esp

    call read_superblock
    test eax, eax
    jnz .error

    push DWORD [superblock + ext2_sb_t.s_free_inodes_count]
    push DWORD [superblock + ext2_sb_t.s_free_blocks_count]
    push DWORD [superblock + ext2_sb_t.s_inodes_count]
    push DWORD [superblock + ext2_sb_t.s_blocks_count]
    push DWORD [inodes_per_group]
    push DWORD [blocks_per_group]
    push DWORD [bg_count]
    push DWORD [block_size]
    push DWORD ext2_info_fmt_len
    push ext2_info_fmt
    call printf

    jmp .done

.error:
    push DWORD info_failed_len
    push info_failed
    call puts

.done:
    mov esp, ebp
    pop ebp
    ret

; u32,u32 find_inode (u32 inode)
; Find the given inode
; Return:
;   Block group and local inode index on success
;   -1,-1 on failure
find_inode:
    push ebp
    mov ebp, esp

    ; Check that the superblock is read, and read it if needed
    mov eax, [superblock + ext2_sb_t.s_inodes_count]
    test eax, eax
    jnz .sb_is_read
    call read_superblock
    test eax, eax
    jnz .error

.sb_is_read:
    mov eax, [ebp + 8]      ; Check bounds
    test eax, eax
    jz  .error              ; No inode 0
    cmp eax, [superblock + ext2_sb_t.s_inodes_count]
    jg  .error              ; Past inode max

    ; block group = (inode - 1) / inodes per group
    ; local index = (inode - 1) % inodes per group
    mov edx, 0
    dec eax
    div DWORD [inodes_per_group]

    jmp .done

.error:
    mov eax, -1
    mov edx, -1
.done:
    mov esp, ebp
    pop ebp
    ret 4

; u32 read_superblock (void)
; Reads the superblock from the current disk.
; Return:
;   0 on success
;   1 on failure
read_superblock:
    push ebp
    mov ebp, esp

    push DWORD MBR_TYPE_LINUX
    call find_partition
    test eax, eax           ; Test for the 0,0 error condition
    jz  .error

    add eax, 2              ; Move to the 3rd sector of the partition
    push DWORD 2
    push eax
    push superblock
    call read_sector
    test eax, eax           ; Test if reading sectors failed
    jnz .error

    mov eax, 1024           ; Compute the block size
    mov ecx, [superblock + ext2_sb_t.s_log_block_size]
    shl eax, cl
    mov [block_size], eax

    ; Save the number of blocks and inodes per group for easier access
    mov eax, [superblock + ext2_sb_t.s_blocks_per_group]
    mov [blocks_per_group], eax
    mov eax, [superblock + ext2_sb_t.s_inodes_per_group]
    mov [inodes_per_group], eax

    ; Compute the number of block groups
    ; ceil(number of blocks / blocks per group)
    mov edx, 0
    mov eax, [superblock + ext2_sb_t.s_blocks_count]
    div DWORD [blocks_per_group]
    test edx, edx
    jz .block_no_round
    inc eax
.block_no_round:
    push eax                ; Save intermediate result

    ; Compute the number of block groups
    ; ceil(number of inodes / inodes per group)
    mov edx, 0
    mov eax, [superblock + ext2_sb_t.s_inodes_count]
    div DWORD [inodes_per_group]
    test edx, edx
    jz .inode_no_round
    inc eax

.inode_no_round:
    pop edx                 ; Test if the results match
    cmp eax, edx
    jnz .error              ; Results don't match, read failed
    mov [bg_count], eax     ; Else, save result


    mov eax, 0
    jmp .done

.error:
    mov eax, 1
.done:
    mov esp, ebp
    pop ebp
    ret

section .rodata
string ext2_info_fmt
    db  'Ext2 Info:', 0x0a
    db  '   Block size:         %u', 0x0a
    db  '   Block groups:       %u', 0x0a
    db  '   Blocks per group:   %u', 0x0a
    db  '   Inodes per group:   %u', 0x0a
    db  '   Total blocks:       %u', 0x0a
    db  '   Total inodes:       %u', 0x0a
    db  '   Free blocks:        %u', 0x0a
    db  '   Free inodes:        %u', 0x0a
endstring
string info_failed
    db  'Failed to get Ext2 info!', 0x0a
endstring

section .bss
superblock:                 ; The Ext2 superblock
    resb 1024
block_size:                 ; Block size, calculated after reading the
    resd 1                  ; subperblock
blocks_per_group:           ; Blocks per group, saved after reading the
    resd 1                  ; superblock
inodes_per_group:           ; Inodes per group, saved after reading the
    resd 1                  ; superblock
bg_count:                   ; Number of block groups, calculated after reading
    resd 1                  ; the superblock
