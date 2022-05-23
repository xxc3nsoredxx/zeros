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

; u32 print_file (u32 inode)
; Prints the contents of the file referenced by the given inode.
; TODO: indirect blocks
; Return:
;   0 on success
;   1 on failure
;   2 on deleted file
print_file:
    push ebp
    mov ebp, esp
    push ebx

    push DWORD [ebp + 8]    ; Read the inode
    call read_inode
    test eax, eax
    jnz .error

    mov ax, [temp_inode + ext2_inode_t.i_mode]  ; Test for non-file
    and ax, EXT2_S_IFREG
    jz  .error
    cmp DWORD [temp_inode + ext2_inode_t.i_ctime], 0    ; Test for nonexistent
    jz  .error                                          ; file (TODO: bitmap)
    cmp DWORD [temp_inode + ext2_inode_t.i_dtime], 0    ; Test for deleted file
    jnz .deleted
    cmp DWORD [temp_inode + ext2_inode_t.i_size], 0 ; Test for 0 length file
    jz  .done

    mov ebx, 0              ; Track which block we're currently on
    mov ecx, [temp_inode + ext2_inode_t.i_size] ; Track how much left to print
.block_loop:                ; Print the file
    ; Test if no more blocks (hit a block number 0)
    cmp DWORD [temp_inode + ext2_inode_t.i_block + ebx*4], 0
    jz  .block_loop_done

    push ecx
    push DWORD [temp_inode + ext2_inode_t.i_block + ebx*4]
    call read_block
    test eax, eax
    jnz .error
    pop ecx

    mov edx, [block_size]   ; Print an entire block if >1024 bytes left
    cmp ecx, [block_size]
    cmovl edx, ecx
    sub ecx, edx            ; Remove that from the amount left

    push ecx
    push edx                ; Finally print lmao
    push temp_block
    call puts
    pop ecx

    inc ebx
    test ecx, ecx
    jnz .block_loop

.block_loop_done:
    mov eax, 0
    jmp .done

.error:
    push DWORD print_bad_file_len
    push print_bad_file
    call puts
    mov eax, 1
    jmp .done
.deleted:
    push DWORD print_deleted_file_len
    push print_deleted_file
    call puts
    mov eax, 2
.done:
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4

; void print_inode (u32 inode)
; Prints the information from the given inode.
print_inode:
    push ebp
    mov ebp, esp
    push edi

    push DWORD [ebp + 8]    ; Read the inode
    call read_inode
    test eax, eax
    jnz .error

    mov eax, 0              ; eax is nice to clear since the top half isn't
                            ; used much, but the bottom half is

    mov ecx, 15             ; Print all direct, indirect, 2x, 3x blocks
.block_loop:
    ; The printf call needs them pushed last -> first
    push DWORD [temp_inode + ext2_inode_t.i_block + ecx*4 - 4]
    loop .block_loop

    push DWORD [temp_inode + ext2_inode_t.i_flags]
    push DWORD [temp_inode + ext2_inode_t.i_blocks]
    mov ax, [temp_inode + ext2_inode_t.i_links_count]
    push eax
    mov ax, [temp_inode + ext2_inode_t.i_gid]
    push eax
    push DWORD [temp_inode + ext2_inode_t.i_dtime]
    push DWORD [temp_inode + ext2_inode_t.i_mtime]
    push DWORD [temp_inode + ext2_inode_t.i_ctime]
    push DWORD [temp_inode + ext2_inode_t.i_atime]
    push DWORD [temp_inode + ext2_inode_t.i_size]
    mov ax, [temp_inode + ext2_inode_t.i_uid]
    push eax

    ; Figure out the file mode and type
    mov ecx, 0
    mov edi, .mode_string

    ; User mode
    mov cx, [temp_inode + ext2_inode_t.i_mode]
    test cx, EXT2_S_IRUSR
    cmovnz ax, [.mode_bits + 2] ; 'r'
    cmovz ax, [.mode_bits + 1]  ; '-'
    stosb
    test cx, EXT2_S_IWUSR
    cmovnz ax, [.mode_bits + 3] ; 'w'
    cmovz ax, [.mode_bits + 1]  ; '-'
    stosb
    and cx, EXT2_S_ISUID | EXT2_S_IXUSR
    cmovz ax, [.mode_bits + 1]  ; '-'
    cmp cx, EXT2_S_ISUID | EXT2_S_IXUSR
    cmovz ax, [.mode_bits + 5]  ; 's'
    cmp cx, EXT2_S_ISUID
    cmovz ax, [.mode_bits + 6]  ; 'S'
    cmp cx, EXT2_S_IXUSR
    cmovz ax, [.mode_bits + 4]  ; 'x'
    stosb

    ; Group mode
    inc edi
    mov cx, [temp_inode + ext2_inode_t.i_mode]
    test cx, EXT2_S_IRGRP
    cmovnz ax, [.mode_bits + 2] ; 'r'
    cmovz ax, [.mode_bits + 1]  ; '-'
    stosb
    test cx, EXT2_S_IWGRP
    cmovnz ax, [.mode_bits + 3] ; 'w'
    cmovz ax, [.mode_bits + 1]  ; '-'
    stosb
    and cx, EXT2_S_ISGID | EXT2_S_IXGRP
    cmovz ax, [.mode_bits + 1]  ; '-'
    cmp cx, EXT2_S_ISGID | EXT2_S_IXGRP
    cmovz ax, [.mode_bits + 5]  ; 's'
    cmp cx, EXT2_S_ISGID
    cmovz ax, [.mode_bits + 6]  ; 'S'
    cmp cx, EXT2_S_IXGRP
    cmovz ax, [.mode_bits + 4]  ; 'x'
    stosb

    ; Other mode
    inc edi
    mov cx, [temp_inode + ext2_inode_t.i_mode]
    test cx, EXT2_S_IROTH
    cmovnz ax, [.mode_bits + 2] ; 'r'
    cmovz ax, [.mode_bits + 1]  ; '-'
    stosb
    test cx, EXT2_S_IWOTH
    cmovnz ax, [.mode_bits + 3] ; 'w'
    cmovz ax, [.mode_bits + 1]  ; '-'
    stosb
    and cx, EXT2_S_ISVTX | EXT2_S_IXOTH
    cmovz ax, [.mode_bits + 1]  ; '-'
    cmp cx, EXT2_S_ISVTX | EXT2_S_IXOTH
    cmovz ax, [.mode_bits + 7]  ; 't'
    cmp cx, EXT2_S_ISVTX
    cmovz ax, [.mode_bits + 8]  ; 'T'
    cmp cx, EXT2_S_IXOTH
    cmovz ax, [.mode_bits + 4]  ; 'x'
    stosb

    push DWORD .mode_string_len
    push .mode_string

    ; Type
    mov eax, 0
    mov ax, [temp_inode + ext2_inode_t.i_mode]
    shr eax, 12             ; Move the most significant nybble to the bottom
    push DWORD [.type_lengths + eax*4]
    push DWORD [.type_strings + eax*4]

    push DWORD [ebp + 8]    ; Inode number
    push DWORD inode_fmt_len
    push inode_fmt
    call printf

    jmp .done

.error:
    push DWORD [ebp + 8]
    push DWORD invalid_inode_len
    push invalid_inode
    call printf
.done:
    pop edi
    mov esp, ebp
    pop ebp
    ret 4
string .mode_string
    db '--- --- ---'        ; u/g/o rwx (including setuid/setgid/sticky)
endstring
.mode_bits:
    db ' -rwxsStT'          ; Extra space at the start because the smallest unit
                            ; for CMOVcc is WORD
.type_strings:
    dd 0
    dd fifo_type
    dd char_type
    dd 0
    dd dir_type
    dd 0
    dd block_type
    dd 0
    dd file_type
    dd 0
    dd symlink_type
    dd 0
    dd socket_type
    dd 0
    dd 0
    dd 0
.type_lengths:
    dd 0
    dd fifo_type_len
    dd char_type_len
    dd 0
    dd dir_type_len
    dd 0
    dd block_type_len
    dd 0
    dd file_type_len
    dd 0
    dd symlink_type_len
    dd 0
    dd socket_type_len
    dd 0
    dd 0
    dd 0

; u32 read_block (u32 block)
; Read the given Ext2 block into temporary storage. Assumes blocks are 1024
; bytes long (for now).
; Return:
;   0 on success
;   1 on failure
read_block:
    push ebp
    mov ebp, esp

    push DWORD 1
    call get_partition      ; Assume we're the first (and only) partition
    test eax, eax
    jz  .error

    mov ecx, [ebp + 8]      ; Convert block into sector offset
    shl ecx, 1
    cmp ecx, edx            ; Verify the sector resides in the partition
    jge .error              ; Multiplying by 2 ensures the sector offset is even
                            ; and the last even sector offset less than the
                            ; partition length begins the last block

    add eax, ecx            ; Read the block
    push DWORD 2
    push eax
    push temp_block
    call read_sector
    test eax, eax
    jnz .error
    jmp .done

.error:
    mov eax, 1
.done:
    mov esp, ebp
    pop ebp
    ret 4

; u32 read_group_descriptor (u32 group)
; Reads the block group descriptor for the given group
; Return:
;   0 on success
;   1 on failure
read_group_descriptor:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov edx, 0              ; Get the number of descriptors per block
    mov eax, [block_size]
    mov ecx, ext2_bg_t_size
    div ecx

    mov edx, 0              ; Find the block containing the descriptor
    mov ecx, [ebp + 8]
    xchg eax, ecx
    div ecx                 ; eax = table-local block offset
                            ; edx = block-local descriptor offset
    push edx                ; Save the offset

    mov ebx, eax            ; Adjust the block number to make it absolute. It's
    mov edx, 0              ; always the block after the superblock, so the one
    mov eax, 2048           ; that starts 2048 bytes in.
    div DWORD [block_size]
    add eax, ebx

    push eax
    call read_block
    test eax, eax
    jnz .error

    pop eax                 ; Convert the descriptor offset into byte offset
    mov ecx, ext2_bg_t_size
    mul ecx

    lea esi, [temp_block + eax] ; Copy the group descriptor
    mov edi, temp_desc
    mov ecx, ext2_bg_t_size
    rep movsb

    mov eax, 0
    jmp .done

.error:
    mov eax, 1
.done:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4

; u32 read_inode (u32 inode)
; Reads the given inode
; Return:
;   0 on success
;   1 on failure
read_inode:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    push DWORD [ebp + 8]    ; Locate the inode
    call find_inode
    cmp eax, -1
    jz  .error

    mov ebx, edx            ; Save the group-local inode index
    push eax                ; Read the approriate group descriptor
    call read_group_descriptor
    test eax, eax
    jnz .error

    mov edx, 0              ; Get the number of inodes per block
    mov eax, [block_size]
    mov ecx, 0
    mov cx, [superblock + ext2_sb_t.s_inode_size]
    div ecx

    mov edx, 0              ; Find the block containing the inode
    xchg eax, ebx
    div ebx                 ; eax = table-local block offset
                            ; edx = block-local inode offset
    add eax, [temp_desc + ext2_bg_t.bg_inode_table] ; Make block number absolute

    push edx                ; Save the offset
    push eax
    call read_block
    test eax, eax
    jnz .error

    pop eax                 ; Convert the inode offset into byte offset
    mov ecx, 0
    mov cx, [superblock + ext2_sb_t.s_inode_size]
    mul ecx

    lea esi, [temp_block + eax] ; Copy the inode
    mov edi, temp_inode
    mov ecx, 0
    mov cx, [superblock + ext2_sb_t.s_inode_size]
    rep movsb

    mov eax, 0
    jmp .done

.error:
    mov eax, 1
.done:
    pop edi
    pop esi
    pop ebx
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
    mov [sb_sector], eax    ; Save the sector for future
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
string print_bad_file
    db  'Error: bad file', 0x0a
endstring
string print_deleted_file
    db  'Error: deleted file', 0x0a
endstring
string inode_fmt
    db  'Inode %u', 0x0a
    db  '  Type:   %s', 0x0a
    db  '  Mode:   %s', 0x0a
    db  '  UID:    %u', 0x0a
    db  '  Size:   %u bytes', 0x0a
    db  '  Atime:  %u', 0x0a
    db  '  Ctime:  %u', 0x0a
    db  '  Mtime:  %u', 0x0a
    db  '  Dtime:  %u', 0x0a
    db  '  GID:    %u', 0x0a
    db  '  Links:  %u', 0x0a
    db  '  Blocks: %u', 0x0a
    db  '  Flags:  %x', 0x0a
    db  '  Direct blocks:', 0x0a
    db  '    %u %u %u %u', 0x0a
    db  '    %u %u %u %u', 0x0a
    db  '    %u %u %u %u', 0x0a
    db  '  Indirect block:', 0x0a
    db  '    %u', 0x0a
    db  '  2x indirect block:', 0x0a
    db  '    %u', 0x0a
    db  '  3x indirect block:', 0x0a
    db  '    %u', 0x0a
endstring
string fifo_type
    db  'fifo'
endstring
string char_type
    db  'character device'
endstring
string dir_type
    db  'directory'
endstring
string block_type
    db  'block device'
endstring
string file_type
    db  'file'
endstring
string symlink_type
    db  'symlink'
endstring
string socket_type
    db  'socket'
endstring
string invalid_inode
    db  'Invalid inode: %u', 0x0a
endstring

section .bss
sb_sector:                  ; The sector on the disk containing the superblock
    resd 1
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
temp_desc:                  ; Temporary storage for a block group descriptor
    resb 32
temp_inode:                 ; Temporary storage for an inode, currently assumes
    resb 128                ; they're 128 bytes (and not something weird)
temp_block:                 ; Temporary storage for an Ext2 block, currently
    resb 1024               ; assumes 1024 byte blocks
