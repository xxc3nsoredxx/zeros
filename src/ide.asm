    ; IDE drivers
    bits 32

%include "ide.hs"
%include "misc.hs"
%include "sys.hs"

section .text
; u32 drive_identify (void)
; Read the IDENTIFY data from the selected drive.
; Return:
;   0 on success
;   1 on failure
drive_identify:
    push ebp
    mov ebp, esp

    mov al, 0               ; The following registers need to all be set to 0
    mov dx, ATA_REG_PRIM_SECT_COUNT
    out dx, al
    mov dx, ATA_REG_PRIM_LBA_LO
    out dx, al
    mov dx, ATA_REG_PRIM_LBA_MID
    out dx, al
    mov dx, ATA_REG_PRIM_LBA_HI
    out dx, al

    mov al, ATA_CMD_IDENTIFY    ; Send the IDENTIFY command
    mov dx, ATA_REG_PRIM_COMMAND
    out dx, al

    mov dx, ATA_REG_PRIM_STATUS ; If status is 0, drive doesn't exist
    in  al, dx
    cmp al, 0
    jz  .drive_not_found

    mov dx, ATA_REG_PRIM_STATUS ; Poll the status register until BSY clears
.poll_bsy:
    in  al, dx
    test al, ATA_STATUS_BSY
    jnz .poll_bsy

    mov dx, ATA_REG_PRIM_LBA_MID    ; If LBA_mid/hi are non-zer, drive not ATA
    in  al, dx
    cmp al, 0
    jnz .drive_not_ata
    mov dx, ATA_REG_PRIM_LBA_HI
    in  al, dx
    cmp al, 0
    jnz .drive_not_ata

    mov dx, ATA_REG_PRIM_ALT_STATUS ; Poll until DRQ or ERR set
.poll_drq_err:
    in  al, dx
    test al, ATA_STATUS_ERR | ATA_STATUS_DRQ
    jz  .poll_drq_err

    test al, ATA_STATUS_ERR ; IDENTIFY data ready if ERR clear
    jnz .identify_error

    mov ecx, 0              ; Read 256 * 16 bits of IDENTIFY data
    mov dx, ATA_REG_PRIM_DATA
.id_read:
    in  ax, dx
    mov [id_data + ecx*2], ax
    inc ecx
    cmp ecx, 256
    jnz .id_read

    mov eax, 0              ; IDENTIFY completed successfully
    jmp .done

.drive_not_found:
    push DWORD drive_not_found_len
    push drive_not_found
    call puts
    mov eax, 1
    jmp .done

.drive_not_ata:
    push DWORD drive_not_ata_len
    push drive_not_ata
    call puts
    mov eax, 1
    jmp .done

.identify_error:
    push DWORD identify_error_len
    push identify_error
    call puts
    mov eax, 1
    jmp .done

.done:
    mov esp, ebp
    pop ebp
    ret

; void drive_interrupts (u32 enable)
; Enable or disable sending interrupts on the selected drive. Do nothing if
; invalid option given
; Valid options:
;   ATA_NIEN_ENABLE
;   ATA_NIEN_DISABLE
drive_interrupts:
    push ebp
    mov ebp, esp

    mov edx, [ebp + 8]
    cmp edx, ATA_NIEN_ENABLE
    jz  .valid
    cmp edx, ATA_NIEN_DISABLE
    jnz .done

.valid:
    mov al, dl
    mov dx, ATA_REG_PRIM_CONTROL
    out dx, al

.done:
    mov esp, ebp
    pop ebp
    ret 4

; void drive_select (u32 drive)
; Select the given drive on the primary bus. Defaults to master if invalid drive
; given.
; Valid options:
;   ATA_DRV_MASTER
;   ATA_DRV_SLAVE
drive_select:
    push ebp
    mov ebp, esp

    ; Use full registers here to be able to test for garbage values that just
    ; happen to look correct in the low byte
    mov edx, [ebp + 8]
    cmp edx, ATA_DRV_MASTER
    jz  .valid
    cmp edx, ATA_DRV_SLAVE
    jz  .valid
    mov edx, ATA_DRV_MASTER

.valid:
    mov al, ATA_DRIVE_HEAD_CONST
    or  al, dl
    mov dx, ATA_REG_PRIM_DRIVE_HEAD
    out dx, al

    ; Reading I/O port 15 times give ~420ns delay, allowing the drive time to
    ; respond to the select
    mov dx, ATA_REG_PRIM_ALT_STATUS
    mov ecx, 15
.delay:
    in al, dx
    loop .delay

    mov esp, ebp
    pop ebp
    ret 4

; u32 ide_init (void)
; Select master drive on primary bus, read IDENTIFY data to verify it exists,
; and disable interrupts on it.
; Return:
;   0 on success
;   1 on failure
; Only called in kernel0
ide_init:
    push ebp
    mov ebp, esp

    push DWORD ATA_DRV_MASTER
    call drive_select

    call drive_identify
    test eax, eax
    jnz .done

    push DWORD ATA_NIEN_DISABLE
    call drive_interrupts

    mov eax, 0

.done:
    mov esp, ebp
    pop ebp
    ret

; u32 read_sector (u32 sector)
; Read the given sector off the disk. For now, only supports master.
; Return:
;   0 on success
;   1 on failure
read_sector:
    push ebp
    mov ebp, esp

    mov edx, [ebp + 8]      ; Get bits 24-27 of sector number
    shr edx, 24
    and edx, 0x0f

    mov al, dl              ; Set master in LBA mode
    or  al, ATA_DRV_MASTER | ATA_LBA_YES
    mov dx, ATA_REG_PRIM_DRIVE_HEAD
    out dx, al

    mov al, 0               ; Write NULL to Features Register to waste time
    mov dx, ATA_REG_PRIM_FEATURES
    out dx, al

    mov al, 1               ; Read single sector
    mov dx, ATA_REG_PRIM_SECT_COUNT
    out dx, al

    mov eax, [ebp + 8]      ; Set up the rest of the LBA number registers
    mov dx, ATA_REG_PRIM_LBA_LO
    out dx, al
    shr eax, 8
    mov dx, ATA_REG_PRIM_LBA_MID
    out dx, al
    shr eax, 8
    mov dx, ATA_REG_PRIM_LBA_HI
    out dx, al

    mov al, ATA_CMD_READ_SECTORS    ; Send the READ SECTORS command
    mov dx, ATA_REG_PRIM_COMMAND
    out dx, al

    mov dx, ATA_REG_PRIM_STATUS ; Poll until BSY clear and DRQ set
.poll_data:
    in  al, dx
    test al, ATA_STATUS_ERR | ATA_STATUS_DF ; Failed if ERR or DF set
    jnz .read_sector_failed
    and al, ATA_STATUS_DRQ | ATA_STATUS_BSY
    cmp al, ATA_STATUS_DRQ
    jnz .poll_data

    mov ecx, 0              ; Read 256 * 16 bits of sector data
    mov dx, ATA_REG_PRIM_DATA
.sector_read:
    in  ax, dx
    mov [sector + ecx*2], ax
    inc ecx
    cmp ecx, 256
    jnz .sector_read

    mov eax, 0              ; READ SECTOR completed successfully
    jmp .done

.read_sector_failed:
    push DWORD read_sector_failed_len
    push read_sector_failed
    call puts
    mov eax, 1

.done:
    mov esp, ebp
    pop ebp
    ret 4

section .rodata
string drive_not_found
    db  'Selected drive not found!', 0x0a
endstring
string drive_not_ata
    db  'Selected drive not ATA!', 0x0a
endstring
string identify_error
    db  'Selected drive IDENTIFY error!', 0x0a
endstring
string ide_init_failed
    db  'Drive initialization failed!', 0x0a
endstring
string read_sector_failed
    db  'READ SECTOR failed', 0x0a
endstring

section .bss
id_data:
    resw 256

sector:
    resb 512
