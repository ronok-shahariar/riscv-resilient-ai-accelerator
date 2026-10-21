ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 16K
}

SECTIONS
{
    . = 0x00000000;
    .text : AT(0x00000000)
    {
        *(.text.init)
        *(.text)
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
    _stack_top = ORIGIN(RAM) + LENGTH(RAM) - 16;
}
