ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 16K
}

SECTIONS
{
    .text :
    {
        KEEP(*(.text.start))
        *(.text*)
        *(.rodata*)
    } > RAM

    .data :
    {
        *(.data*)
    } > RAM

    .bss (NOLOAD) :
    {
        *(.bss*)
        *(COMMON)
    } > RAM

    . = ALIGN(16);
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
