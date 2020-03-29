    ; Keyboard utilities
    bits    32

%include    "kb.hs"

section .bss
keycode:
.modifier:              ; Modifiers active
    resb    1           ; Bits:
                        ;   7:  Unused
                        ;   6:  Unused
                        ;   5:  Unused
                        ;   4:  Unused
                        ;   3:  Unused
                        ;   2:  Unused
                        ;   1:  Caps:   0 (inactive), 1 (active)
                        ;   0:  Shift:  0 (inactive), 1 (active)
.key:                   ; Pressed key (non-modifier)
    resb    1           ; ASCII code:
                        ;   Letters     (lowercase, 0x61 to 0x7A)
                        ;   Numbers     (0x30 to 0x39, shift for !@#$%^&*())
                        ;   `-=[]\;',./ (0x27, 2C-2F, 3B, 3D, 5B-5D, 60)
                        ;               (shift for ~_+{}|:">?)
                        ;   Newline     (0x0A, return)
                        ;   Space       (0x20, space bar)
                        ;   Backspace   (0x08)
