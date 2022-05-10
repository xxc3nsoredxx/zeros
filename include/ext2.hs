%ifndef EXT2_HS_20220508_203530
%define EXT2_HS_20220508_203530

; Documented with the help of "The Second Extended File System" by Dave Poirier
; Version: May 8th, 2019
; See: https://www.nongnu.org/ext2-doc/

extern ext2_info
extern read_superblock

; The Ext2 superblock
; All types are little-endian ints unless otherwise stated
; 1024 bytes long
struc ext2_sb_t
    .s_inodes_count:        ; Total number of inodes
        resd    1
    .s_blocks_count:        ; Total number of blocks
        resd    1
    .s_r_blocks_count:      ; Number of reserved blocks (for superuser)
        resd    1
    .s_free_blocks_count:   ; Number of unallocated blocks
        resd    1
    .s_free_inodes_count:   ; Number of unallocated inodes
        resd    1
    .s_first_data_block:    ; The first data block
        resd    1           ; Always 0 for filesystems with block size >1KiB,
                            ; and always 1 for block size 1 KiB. Superblock is
                            ; always at the 1024th byte on the disk.
    .s_log_block_size:      ; The (log of the) block size
        resd    1           ; block size = 1024 << s_log_block_size
    .s_log_frag_size:       ; The (log of the) fragment size
        resd    1           ; frag size = 1024 << s_log_frag_size
    .s_blocks_per_group:    ; Number of blocks per group
        resd    1
    .s_frags_per_group:     ; Number of fragments per group
        resd    1
    .s_inodes_per_group:    ; Number of inodes per group
        resd    1
    .s_mtime:               ; UNIX time of last mount
        resd    1
    .s_wtime:               ; UNIX time of last write
        resd    1
    .s_mnt_count:           ; Number of mounts since last fsck
        resw    1
    .s_max_mnt_count:       ; Maximum number of mounts until fsck is needed
        resw    1
    .s_magic:               ; Ext2 magic number
        resw    1           ; Always 0xef53
    .s_state:               ; Current filesystem state
        resw    1           ; Set to ERROR when mounted, set to VALID when
                            ; unmounted cleanly
    .s_errors:              ; What to do if error is detected
        resw    1           ; CONTINUE - continue as normal
                            ; RO - remount read only
                            ; PANIC - kernel panic
    .s_minor_rev_level:     ; Minor revision level
        resw    1
    .s_lastcheck:           ; UNIX time of last fsck
        resd    1
    .s_checkinterval:       ; Maximum UNIX time interval between fsck
        resd    1
    .s_creator_os:          ; OS that created the filesystem
        resd    1           ; See below
    .s_rev_level:           ; Revision level
        resd    1           ; GOOD_OLD - revision 0
                            ; DYNAMIC - variable inode sizes, extended
                            ; attributes, etc
    .s_def_resuid:          ; Default user ID for reserved blocks
        resw    1
    .s_def_resgid:          ; Default group ID for reserved blocks
        resw    1
    ; Everything after is only used if rev > 0
    .s_first_ino:           ; First usable inode for normal files
        resd    1           ; Always 11 is rev0, can be any in rev1
    .s_inode_size:          ; Size of the inode struct
        resw    1           ; Always 128 in rev0, must be power of 2 and less
                            ; than or equal to block size in rev1
    .s_block_group_nr:      ; Block group containing this superblock
        resw    1
    .s_feature_compat:      ; Bitmask of compatible features
        resd    1           ; Optional, no damage if not supported
    .s_feature_incompat:    ; Bitmask of incompatible features
        resd    1           ; Must not mount if any of the listed features are
                            ; not supported. See below
    .s_feature_ro_compat:   ; Bitmask of read only features
        resd    1           ; Must mount read only if any not supported
    .s_uuid:                ; Unique volume ID
        resd    4
    .s_volume_name:         ; Volume name
        resb    16          ; NULL terminated ISO-Latin-1 charset
    .s_last_mounted:        ; Path the filesystem was last mounted at
        resb    64          ; NULL terminated ISO-Latin-1 charset
    .s_algo_bitmap:         ; Compression methods used
        resd    1           ; See below
    .s_prealloc_blocks:     ; Number of blocks to try to pre-allocate when
        resb    1           ; creating regular file
    .s_prealloc_dir_blocks: ; Number of blocks to try to pre-allocate when
        resb    1           ; creating a directory
        alignb  4           ; Align so s_journal_uuid is at offset 208
    .s_journal_uuid:        ; UUID of the journal superblock
        resb    16
    .s_journal_inum:        ; Inode of the journal file
        resd    1
    .s_journal_dev:         ; Device number of the journal file
        resd    1
    .s_last_orphan:         ; Inode number pointing to first inode in a list of
        resd    1           ; inodes to delete
    .s_hash_seed:           ; Array of seeds used for hash in directory indexing
        resd    4
    .s_def_hash_version:    ; Default hash version for directory indexing
        resb    1
        alignb  4           ; Reserved for future expansion
    .s_default_mount_options:   ; Default mount options for filesystem
        resd    1
    .s_first_meta_bg:       ; Block group ID of the first meta block group
        resd    1
        alignb  1024        ; Reserved for future expansion
endstruc

%assign EXT2_SUPER_MAGIC 0xef53

%assign EXT2_VALID_FS   1
%assign EXT2_ERROR_FS   2

%assign EXT2_ERRORS_CONTINUE    1
%assign EXT2_ERRORS_RO          2
%assign EXT2_ERRORS_PANIC       3

%assign EXT2_OS_LINUX   0
%assign EXT2_OS_HURD    1
%assign EXT2_OS_MASIX   2
%assign EXT2_OS_FREEBSD 3
%assign EXT2_OS_LITES   4   ; BSD-Lite derivatives

%assign EXT2_GOOD_OLD_REV   0
%assign EXT2_DYNAMIC_REV    1

%assign EXT2_FEATURE_INCOMPAT_COMPRESSION   0x00000001
%assign EXT2_FEATURE_INCOMPAT_FILETYPE      0x00000002
%assign EXT2_FEATURE_INCOMPAT_RECOVER       0x00000004
%assign EXT2_FEATURE_INCOMPAT_JOURNAL_DEV   0x00000008
%assign EXT2_FEATURE_INCOMPAT_META_BG       0x00000010

%assign EXT2_FEATURE_RO_COMPAT_SPARSE_SUPER 0x00000001
%assign EXT2_FEATURE_RO_COMPAT_LARGE_FILE   0x00000002
%assign EXT2_FEATURE_RO_COMPAT_BTREE_DIR    0x00000004

%assign EXT2_LZV1_ALG   0x00000001
%assign EXT2_LZRW3A_ALG 0x00000002
%assign EXT2_GZIP_ALG   0x00000004
%assign EXT2_BZIP2_ALG  0x00000008
%assign EXT2_LZO_ALG    0x00000010

%endif
; vim: filetype=asm:syntax=nasm:
