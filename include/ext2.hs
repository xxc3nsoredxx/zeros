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

; An Ext2 inode
struc ext2_inode_t
    .i_mode:                ; File mode (type and access rights)
        resw    1
    .i_uid:                 ; Owner UID
        resw    1
    .i_size:                ; Rev 0:
        resd    1           ;   signed 32 bit file size in bytes
                            ; Rev 1+ (only for regular files):
                            ;   lower 32 bits of file size
                            ;   upper 32 bits in i_dir_acl
    .i_atime:               ; UNIX time when the inode was last accessed
        resd    1
    .i_ctime:               ; UNIX time when the inode was created
        resd    1
    .i_mtime:               ; UNIX time when the inode was last modified
        resd    1
    .i_dtime:               ; UNIX time when the indoe was deleted
        resd    1
    .i_gid:                 ; GID of groups with access
        resw    1
    .i_links_count:         ; Number of (hard) links to this inode
        resw    1
    .i_blocks:              ; Total number of 512 byte blocks reserved for
        resd    1           ; the data (even if unused)
                            ; max index in i_block array =
                            ;   i_blocks / (2 << s_log_block_size)
    .i_flags:               ; Defines behavior for accessing data from the inode
        resd    1
    .i_osd1:                ; OS dependant value
        resd    1
    .i_block:               ; List of blocks containing data
        resd    15          ; Index 0-11: direct blocks
                            ;   - these blocks have the data directly
                            ; Index 12: indirect block
                            ;   - this block points to a block containing a list
                            ;     of additional direct blocks
                            ; Index 13: double-indirect block
                            ;   - this block points to a block containing a list
                            ;     of additional indirect blocks
                            ; Index 14: triple-indirect block
                            ;   - this block points to a block containing a list
                            ;     of additional double-indirect blocks
                            ; Original Ext2 implementation terminated the array
                            ; as soon as a 0 was found. Sparse files allow some
                            ; blocks to be allocated while others aren't, and a
                            ; 0 is used to indicate no-yet-allocated blocks.
    .i_generation:          ; File version (used by NFS)
        resd    1
    .i_file_acl:            ; Block number with extended attributes
        resd    1           ; Always 0 in rev 0
    .i_dir_acl:             ; Always 0 in rev 0, contains high 32 bits of 64 bit
        resd    1           ; file size for regular fles in rev 1. Always set to
                            ; 0 by Linux for non-regular files. Could be
                            ; directory attribute block too, in theory.
    .i_faddr:               ; Location of the file fragment
        resd    1           ; Unsupported in Linux and GNU HURD, always set to 0
                            ; Marked obsolete in Ext4
    .i_osd2:                ; OS dependant structure (96 bits)
        resb    12          ; TODO: ignore for now
endstruc

; File formats
%assign EXT2_S_IFSOCK   0xc000  ; Socket
%assign EXT2_S_IFLNK    0xa000  ; Symlink
%assign EXT2_S_IFREG    0x8000  ; Regular file
%assign EXT2_S_IFBLK    0x6000  ; Block device
%assign EXT2_S_IFDIR    0x4000  ; Directory
%assign EXT2_S_IFCHR    0x2000  ; Character device
%assign EXT2_S_IFIFO    0x1000  ; FIFO (pipe)

; Override bits
%assign EXT2_S_ISUID    0x0800  ; Set UID
%assign EXT2_S_ISGID    0x0400  ; Set GID
%assign EXT2_S_ISVTX    0x0200  ; Sticky bit

; Access rights
%assign EXT2_S_IRUSR    0x0100  ; User read
%assign EXT2_S_IWUSR    0x0080  ; User write
%assign EXT2_S_IXUSR    0x0040  ; User execute
%assign EXT2_S_IRGRP    0x0020  ; Group read
%assign EXT2_S_IWGRP    0x0010  ; Group write
%assign EXT2_S_IXGRP    0x0008  ; Group execute
%assign EXT2_S_IROTH    0x0004  ; Other read
%assign EXT2_S_IWOTH    0x0002  ; Other write
%assign EXT2_S_IXOTH    0x0001  ; Other execute

; Data access behavior flags
%assign EXT2_SECRM_FL       0x00000001  ; Secure delete
%assign EXT2_UNRM_FL        0x00000002  ; Record for undelete
%assign EXT2_COMPR_FL       0x00000004  ; Compressed file
%assign EXT2_SYNC_FL        0x00000008  ; Synchronous updates
%assign EXT2_IMMUTABLE_FL   0x00000010  ; Immutable file
%assign EXT2_APPEND_FL      0x00000020  ; Append only
%assign EXT2_NODUMP_FL      0x00000040  ; Don't dump/delete
%assign EXT2_NOATIME_FL     0x00000080  ; Don't update atime
; Begin compression behavior flags
%assign EXT2_DIRTY_FL       0x00000100  ; Dirty (modified)
%assign EXT2_COMPRBLK_FL    0x00000200  ; Compressed blocks
%assign EXT2_NOCOMPR_FL     0x00000400  ; Access raw compressed data
%assign EXT2_ECOMPR_FL      0x00000800  ; Compression error
; End compression behavior flags
%assign EXT2_BTREE_FL           0x00001000  ; B-tree format directory
%assign EXT2_INDEX_FL           0x00001000  ; Hash indexed directory (same?)
%assign EXT2_IMAGIC_FL          0x00002000  ; AFS directory
%assign EXT2_JOURNAL_DATA_FL    0x00004000  ; Journal file data
%assign EXT2_RESERVED_FL        0x80000000  ; Reserved for Ext2 library

; Reserved inodes (rev 0)
%assign EXT2_BAD_INO            1   ; Bad blocks inode
%assign EXT2_ROOT_INO           2   ; Root directory inode
%assign EXT2_ACL_IDX_INO        3   ; ACL index inode (deprecated?)
%assign EXT2_ACL_DATA_INO       4   ; ACL data inode (deprecated?)
%assign EXT2_BOOT_LOADER_INFO   5   ; Bootloader inode
%assign EXT2_UNDEL_DIR_INO      6   ; Undelete directory inode

%endif
; vim: filetype=asm:syntax=nasm:
