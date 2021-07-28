# ZerOS Memory Layout

## General structure
```
Physical Address               Virtual Address
0x00000000  +-------------------+
            |        ...        |
0x000b8000  +-------------------+ 
            |       VRAM        |
0x000c8000  +-------------------+
            |        ...        |
0x00100000  +-------------------+
            |       Stack       |
0x00900000  +-------------------+
            |     #DF Stack     |
0x00901000  +-------------------+
            |        ...        |
            +-------------------+
            | Multiboot Header  |
0x00a00000  +-------------------+   0x00000000
            |        GDT        |
            +-------------------+
            |        IDT        |
            +-------------------+
            |        ...        |
            +-------------------+
            |        TSS        |
0x00a01000  +-------------------+   0x00001000
            |     Code/Data     |
            +-------------------+
            |        ...        |
0xffffffff  +-------------------+   0xff5fffff
```
* VGA memory
  * Begins (physical address): `0x000b8000`
  * Ends (physical address): `0x000c8000`
  * Size: 64 KiB
* Main stack
  * Begins (physical address): `0x00100000` (1 MiB)
    * Top of stack
  * Ends (physical address): `0x00900000` (9 MiB)
    * Bottom of stack
  * Size: 8 MiB
* Double Fault handler stack
  * Begins (physical address): `0x00900000` (9 MiB)
    * Bottom of stack
  * Ends (physical address): `0x00901000` (+4 KiB)
    * Top of stack
  * Size: 4 KiB
* Multiboot header
  * Begins: ???
  * Ends (physical address): `0x00a00000` (10 MiB)
  * Ends (virtual address): `0x00000000` (origin)
  * Size: ???
* GDT
  * Begins (physical address): `0x00a00000` (10 MiB)
  * Begins (virtual address): `0x00000000` (origin)
  * Ends: ???
  * Size: N entries * 8 bytes per entry + 6 byte descriptor
* IDT
  * Begins: end of GDT, aligned to 16 bytes
  * Ends: ???
  * Size: 2 KiB + 6 byte descriptor
    * 256 entries * 8 bytes per entry
* TSS
  * Begins: ???
  * Ends (physical address): `0x00a01000`
  * Ends (virtual address): `0x00001000` (4 KiB)
  * Size: N descriptors * 0x70 (112) bytes per descriptor
    * Each descriptor is 0x68 (104) bytes padded to 16 byte alignment
* Code/Data
  * Begins (physical address): `0x00a01000`
  * Begins (virtual address): `0x00001000` (4 KiB)
  * Ends (basically): after 4 GiB
