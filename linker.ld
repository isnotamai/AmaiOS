ENTRY(_start)

SECTIONS {
    . = 0x1000;         /* Kernel is loaded at 0x1000 by the bootloader */

    .text : {
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
        *(COMMON)
    }
}
