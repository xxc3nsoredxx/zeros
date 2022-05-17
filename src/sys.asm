    ; ZerOS system calls
    bits    32

%include "sys.hs"
%include "kb.hs"
%include "vga.hs"

section .text
;;;;;;;;;;;
;; INPUT ;;
;;;;;;;;;;;

; u32 getsn (char *buffer, u32 count)
; Read a single line or count characters from the keyboard into buffer,
; whichever comes first. The terminating newline (if any) is included.
; Return number of characters read.
getsn:
    push ebp
    mov ebp, esp
    push edi

    mov edi, [ebp + 8]      ; Buffer to read in to
    xor ecx, ecx
    cmp ecx, [ebp + 12]     ; Test if count of 0
    jz .done                ; 0, don't read anything

.loop:
    mov al, [keycode.mod]   ; Test if key already read
    and al, KC_MOD_READ
    jnz .loop
    movzx eax, BYTE [keycode.key]
    cmp al, 0               ; Test for null key
    jz  .loop
    cmp al, 8               ; Test for backspace
    jz  .backspace
    stosb                   ; Save the character in the buffer
    cmp al, 0x0a            ; Test for return key
    jnz .print
    mov al, [keycode.mod]   ; Set the read bit
    or  al, KC_MOD_READ
    mov [keycode.mod], al
    inc ecx
    jmp .done               ; EOL

.backspace:
    cmp ecx, 0              ; Do nothing if no characters in buffer
    jnz .not_empty
    mov al, [keycode.mod]   ; Set the read bit
    or  al, KC_MOD_READ
    mov [keycode.mod], al
    jmp .loop
.not_empty:
    sub ecx, 2              ; Decrement counter (2x, so net -1)
    dec edi                 ; Delete last character in buffer
    mov BYTE [edi], 0
.print:
    push ecx                ; Save counter
    push eax                ; Otherwise, print key
    call putch
    pop ecx                 ; Restore counter
    mov al, [keycode.mod]   ; Set the read bit
    or  al, KC_MOD_READ
    mov [keycode.mod], al

    inc ecx                 ; Get a new character
    cmp ecx, [ebp + 12]
    jnz .loop

.done:
    mov eax, ecx            ; Number of characters read

    pop edi
    mov esp, ebp
    pop ebp
    ret 8

;;;;;;;;;;;;;;;;;;;
;; MISCELLANEOUS ;;
;;;;;;;;;;;;;;;;;;;

; void clear (void)
; Clears the screen and moves cursor to top left
clear:
    push ebp
    mov ebp, esp
    push edi
    push esi
    push es

    mov ax, gs              ; Set es to point to VRAM
    mov es, ax

    mov al, [color]         ; Write the color attribute into the blanks
    mov BYTE [.blanks + 1], al
    mov BYTE [.blanks + 3], al
    mov esi, .blanks        ; Write ' ' on all locations 2 chars at a time
    mov edi, 0
    movzx eax, BYTE [ROWS]
    mul BYTE [COLS]
    shr eax, 1
    mov ecx, eax
.loop:
    movsd
    sub esi, 4
    loop .loop

    mov BYTE [curx], 0      ; Move the cursor
    mov BYTE [cury], 0
    call update_cursor

    pop es
    pop esi
    pop edi
    mov esp, ebp
    pop ebp
    ret
.blanks:
    dd  0x00200020

; u32,u32 stoi (char *str, u32 len)
; Convert a string into an int (base 10). Stops parsing after len chars, 10
; digits, or when the first non-digit char is reached, whichever happens first.
; TODO: negative numbers
; Return:
;   The converted number and 0 on success
;   0,1 on failure
stoi:
    push ebp
    mov ebp, esp
    push esi

    mov esi, [ebp + 8]      ; Save the source string
    cmp DWORD [ebp + 12], 0 ; Error if length 0
    jz  .error

    mov ecx, 10             ; Use the given length if it's < 10
    cmp DWORD [ebp + 12], 10
    cmovl ecx, [ebp + 12]

    mov eax, 0
.loop:
    mov edx, 10             ; Shift digits to the left and check for overflow
    mul edx
    jo  .error

    mov dl, [esi]
    cmp dl, 0x30            ; Test for valid chars
    jl  .error
    cmp dl, 0x39
    jg  .error

    sub dl, 0x30            ; Un-ASCII and check for overflow
    add eax, edx            ; Rest of edx guaranteed zero due to above mul
    jo  .error

    inc esi                 ; Next char
    loop .loop

    mov edx, 0
    jmp .done

.error:
    mov eax, 0
    mov edx, 1
.done:
    pop esi
    mov esp, ebp
    pop ebp
    ret 8
.is_neg:
    dd  0

; u32 streq (char *str1, char *str2, u32 max_len)
; Compare strings str1 and str2 for equality, stopping after max_len bytes have
; been checked.
; Return:
;   0 if equal
;   1 if inequal
streq:
    push ebp
    mov ebp, esp
    push esi
    push edi

    mov eax, 1              ; Assume inequal
    mov edx, 0
    mov esi, [ebp + 8]
    mov edi, [ebp + 12]
    mov ecx, [ebp + 16]
    repe cmpsb
    cmovz eax, edx          ; Set only if all bytes in both strings equal

    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret 12

;;;;;;;;;;;;
;; OUTPUT ;;
;;;;;;;;;;;;

; void printf (char *fmt, u32 fmt_len, ...)
; Print a formatted string of length fmt_len to the screen
; Fun fact:
;   This has been ranked as The World's Best (TM) printf implementation!
;   (cert. pend.)
; %s: prints a string
;     requires 2 arguments: pointer to string, length of string
; %u: prints a u32 as unsigned decimal
; %x: prints a u32 as hex
; %%: prints a '%'
printf:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ebx

    ; Length 0, print nothing
    mov ecx, [ebp + 12]
    cmp ecx, 0
    jz  .done

    ; Use esi to store the string (segment) start
    mov esi, [ebp + 8]
    ; Use edi to store the end of the format string
    lea edi, [esi + ecx]
    ; Use ecx to store the count of current letters to print
    xor ecx, ecx
    ; Use ebx to store the number of parameters on the stack
    xor ebx, ebx

.loop:
    ; Test formats
    cmp BYTE [esi + ecx], '%'
    jnz .skip
    ; Assume ecx gets clobbered, make a backup so we can return
    push ecx
    ; Print string up to, but not including, the format
    push ecx
    push esi
    call puts

    ; Return to the format (+1 to skip the %)
    pop ecx
    lea esi, [esi + ecx + 1]
    ; Test for end-of-string (incomplete format)
    cmp esi, edi
    jz  .done

.s:
    ; Test for %s
    cmp BYTE [esi], 's'
    jnz .u
    ; Print the string
    ; Contents in stack are: first pointer, then length
    mov ecx, [ebp + ebx*4 + 20] ; Get the length of the string
    push ecx
    mov ecx, [ebp + ebx*4 + 16] ; Get the pointer to the string
    push ecx
    call puts
    ; Track nymber of format arguments on the stack
    add ebx, 2
    jmp .next

.u:
    ; Test for %u
    cmp BYTE [esi], 'u'
    jnz .x
    ; Print the number given on the stack (in unsigned decimal)
    mov ecx, [ebp + ebx*4 + 16]
    push ecx
    call putintu
    ; Track number of format arguments on the stack
    inc ebx
    jmp .next

.x:
    ; Test for %x
    cmp BYTE [esi], 'x'
    jnz .percent
    ; Print the number given on the stack (in hex)
    mov ecx, [ebp + ebx*4 + 16]
    push ecx
    call putintx
    ; Track number of format arguments on the stack
    inc ebx
    jmp .next

.percent:
    ; Test for %%
    cmp BYTE [esi], '%'
    jnz .next               ; Do nothing on invalid format
    ; Print a single '%'
    push '%'
    call putch
    ; Fall through to .next

.next:
    ; Test for end-of-string
    inc esi
    cmp esi, edi
    jz  .done
    ; New string segment
    xor ecx, ecx
    jmp .loop

.skip:
    ; Not a format
    inc ecx
    ; Test for end-of-string
    lea edx, [esi + ecx]
    cmp edx, edi
    jnz .loop
    ; If end-of-string, print what is left
    push ecx
    push esi
    call puts

.done:
    ; Remove any args
    ; Replace last one with return address
    mov eax, [ebp + 4]
    mov [ebp + ebx*4 + 12], eax
    ; Replace second to last one with ebp (and fix ebp)
    mov eax, [ebp]
    lea ebp, [ebp + ebx*4 + 8]
    mov [ebp], eax

    pop ebx
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret

; void putch (char c)
; Prints a single character on the screem
putch:
    push ebp
    mov ebp, esp
    push ebx

    mov bl, [ebp + 8]       ; Build the letter+attribute into BX
    mov bh, [color]
    cmp bl, 0x08            ; Test backspace
    jz  .bs
    cmp bl, 0x0D            ; Test carriage return
    jz  .cr
    cmp bl, 0x0A            ; Test newline
    jz  .nl
    call getpos
    mov WORD [gs:eax], bx   ; Write to screen
    inc BYTE [curx]
    mov bl, [COLS]          ; Test word wrap
    cmp [curx], bl
    jz  .wrap
    jmp .done

.bs:                        ; Handle backspace
    cmp BYTE [curx], 0      ; Test if cursor goes up a line
    jz  .go_up
    dec BYTE [curx]         ; Stays on same line
    jmp .print_bs
.go_up:
    cmp BYTE [cury], 0      ; Test if at top left corner
    jz  .done
    dec BYTE [cury]         ; Move to end of previous line
    mov al, [COLS]
    dec al
    mov [curx], al
.print_bs:
    mov bl, 0x20            ; Write a blank to screen
    call getpos
    mov WORD [gs:eax], bx
    jmp .done

.cr:                        ; Handle carriage return
    mov BYTE [curx], 0
    jmp .done
.nl:                        ; Handle newline
    inc BYTE [cury]
    jmp .testscroll

.wrap:                      ; Handle word wrap
    inc BYTE [cury]
    mov BYTE [curx], 0
.testscroll:
    mov bl, [ROWS]          ; Test scroll
    cmp [cury], bl
    jnz .done
    call scroll

.done:
    call update_cursor
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4

; void putintu (u32 num)
; Print num as unsigned decimal
putintu:
    push ebp
    mov ebp, esp
    push edi

    ; Go backwards
    std
    ; Start at the end of the string
    lea edi, [.str + 9]
    ; Prepare for division
    xor edx, edx
    mov eax, [ebp + 8]
    mov ecx, 10

.loop:
    div ecx
    ; Move the digit into place
    xchg eax, edx
    add al, '0'
    stosb
    xchg eax, edx
    ; If quot is 0, done
    ; Note: if the number to print is 0, the zero digit just got saved
    xor edx, edx
    cmp eax, 0
    jnz .loop

    ; Restore forwards direction
    cld
    ; Get length of string
    inc edi
    lea ecx, [.str + 10]
    sub ecx, edi
    ; Print
    push ecx
    push edi
    call puts

    pop edi
    mov esp, ebp
    pop ebp
    ret 4
.str:                       ; Buffer to build the string into
    times 10 db 0

; void putintx (u32 num)
; Print num as hex
putintx:
    push ebp
    mov ebp, esp
    push esi
    push edi

    ; Loop through the number 1 nybble at a time
    mov eax, [ebp + 8]
    mov ecx, 8
.loop:
    ; Extract a nybble
    mov edx, eax
    and edx, 0x0f
    shr eax, 4

    ; Copy the value
    lea esi, [.xlate + edx]
    lea edi, [.str + ecx - 1]
    movsb

    dec ecx
    jnz .loop

    ; Print the number
    push 8
    push .str
    call puts

    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret 4
.str:                       ; Buffer to build the string into
    times 8 db 0
.xlate:                     ; Table to translate 0-15 to 0-f
    db  '0123456789abcdef'

; void puts (char *str, u32 len)
; Print a string of length len on the screen
puts:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    push esi
    push es

    mov ax, gs
    mov es, ax

    mov ecx, [ebp + 12]     ; Length of the string
    cmp ecx, 0
    jz  .done               ; Skip all if zero length
    mov esi, [ebp + 8]      ; Address of the first character
    call getpos             ; Get the current pos
    mov edi, eax
    movzx ebx, BYTE [color]

.print:
    cmp BYTE [esi], 0x0A    ; Line feed
    je  .lf
    cmp BYTE [esi], 0x0D    ; Carriage return
    je  .cr
    movsb                   ; Regular char
    mov BYTE [gs:edi], bl   ; Color
    inc edi
    movzx eax, BYTE [curx]
    inc eax
    cmp al, BYTE [COLS]     ; Test for word wrap
    jne .nowrap
    mov BYTE [curx], 0
    movzx eax, BYTE [cury]
    inc eax
    cmp al, BYTE [ROWS]     ; Test for wrap scroll
    jne .nowrapscroll
    push ecx
    call scroll
    pop ecx
    call getpos
    mov edi, eax
    loop .print
    jmp .done
.nowrap:
    mov [curx], al
    loop .print
    jmp .done
.nowrapscroll:
    mov [cury], al
    loop .print
    jmp .done
.lf:
.cr:
    mov BYTE [curx], 0      ; Go to start of line
    movzx eax, BYTE [cury]  ; Go down a line
    inc eax
    cmp al, [ROWS]
    jne .noscroll
    push ecx
    call scroll
    pop ecx
    jmp .skip
.noscroll:
    mov [cury], al
.skip:
    call getpos
    mov edi, eax
    inc esi
    loop .print_jmp
.done:
    call update_cursor
    pop es
    pop esi
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 8
.print_jmp:
    jmp .print
