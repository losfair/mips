SECTIONS
{
    . = 0x3000;
    .text : { *(.text) }
    . = 0x4000;
    .data : { *(.data) }
    .bss : { *(.bss) }
    /DISCARD/ : { *(.*) }
}