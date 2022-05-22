%ifndef MBR_HS_20220509_214705
%define MBR_HS_20220509_214705

extern find_partition
extern get_partition
extern read_mbr

struc mbr_t
    .bootstrap:             ; Bootstrap code block, plus the optional ID and
        resb    446         ; reserved fields
    ; Partition 1
    .p1_attr:               ; Partition attributes
        resb    1
    .p1_chs_start:          ; CHS of partition start
        resb    3
    .p1_type:               ; Partition type
        resb    1
    .p1_chs_end:            ; CHS of partition end
        resb    3
    .p1_lba:                ; LBA of partition start
        resd    1
    .p1_sectors:            ; Number of sectors in partition
        resd    1
    ; Partition 2
    .p2_attr:
        resb    1
    .p2_chs_start:
        resb    3
    .p2_type:
        resb    1
    .p2_chs_end:
        resb    3
    .p2_lba:
        resd    1
    .p2_sectors:
        resd    1
    ; Partition 3
    .p3_attr:
        resb    1
    .p3_chs_start:
        resb    3
    .p3_type:
        resb    1
    .p3_chs_end:
        resb    3
    .p3_lba:
        resd    1
    .p3_sectors:
        resd    1
    ; Partition 4
    .p4_attr:
        resb    1
    .p4_chs_start:
        resb    3
    .p4_type:
        resb    1
    .p4_chs_end:
        resb    3
    .p4_lba:
        resd    1
    .p4_sectors:
        resd    1
    .boot_magic:            ; End of sector
        resw    1
endstruc

%assign MBR_TYPE_LINUX 0x83
%assign MBR_BOOT_MAGIC 0xaa55

%endif
; vim: filetype=asm:syntax=nasm:
