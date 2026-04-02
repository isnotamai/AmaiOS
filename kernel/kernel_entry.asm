[BITS 32]           ; We enter 32-bit protected mode here

[EXTERN kernel_main] ; Defined in kernel.c

global _start

_start:
    call kernel_main
    hlt             ; Should never reach here
