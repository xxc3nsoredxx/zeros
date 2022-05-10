%ifndef IDE_HS_20220507_202820
%define IDE_HS_20220507_202820

extern drive_identify
extern drive_interrupts
extern drive_select
extern ide_init
extern read_sector

; ATA I/O registers
%assign ATA_REG_PRIM_DATA       0x01f0
%assign ATA_REG_PRIM_FEATURES   0x01f1
%assign ATA_REG_PRIM_SECT_COUNT 0x01f2
%assign ATA_REG_PRIM_LBA_LO     0x01f3
%assign ATA_REG_PRIM_LBA_MID    0x01f4
%assign ATA_REG_PRIM_LBA_HI     0x01f5
%assign ATA_REG_PRIM_DRIVE_HEAD 0x01f6
%assign ATA_REG_PRIM_COMMAND    0x01f7
%assign ATA_REG_PRIM_STATUS     0x01f7

; ATA Control registers
%assign ATA_REG_PRIM_ALT_STATUS 0x03f6
%assign ATA_REG_PRIM_CONTROL    0x03f6

; ATA commands
%assign ATA_CMD_READ_SECTORS    0x20
%assign ATA_CMD_IDENTIFY        0xec

; Drive / Head Register
; bit 0-3:  CHS - bits 0-3 of head
;           LBA - bits 24-27 of block number
; bit 4:    DRV - select drive number, master (0)/slave (1)
; bit 5:    Always set
; bit 6:    LBA - select addressing mode, CHS (0)/LBA (1)
; bit 7:    Always set
%assign ATA_DRIVE_HEAD_CONST 0xa0
%assign ATA_DRV_MASTER  0x00
%assign ATA_DRV_SLAVE   0x10
%assign ATA_LBA_NO      0x00
%assign ATA_LBA_YES     0x40

; Status Register
; bit 0:    ERR - indicates error (clear with new command or reset)
; bit 1:    Always clear
; bit 2:    Always clear
; bit 3:    DRQ - set when ready to send/receive PIO data
; bit 4:    SRV - overlapped mode service request
; bit 5:    DF  - drive fault (no ERR set!!!)
; bit 6:    RDY - clear when drive spun down or after error, otherwise set
; bit 7:    BSY - indicates drive preparing to send/receive data
%assign ATA_STATUS_ERR  0x01
%assign ATA_STATUS_DRQ  0x08
%assign ATA_STATUS_DF   0x20
%assign ATA_STATUS_BSY  0x80

; Device Control Register
; bit 0:    Always clear
; bit 1:    nIEN - enable (0) / disable (1) interrupts
; bit 2:    SRST - set, wait 5us, clear to do a software reset on all ATA drives
;           on a given bus
; bit 3-6:  Always clear (reserved)
; bit 7:    Set to read the high order byte of the last LBA48 value sent to I/O
;           port
%assign ATA_NIEN_ENABLE     0x00
%assign ATA_NIEN_DISABLE    0x02

%endif
; vim: filetype=asm:syntax=nasm:
