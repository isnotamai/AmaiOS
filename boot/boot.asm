[BITS 16]           ; 16-bit real mode
[ORG 0x7C00]        ; BIOS loads bootloader at 0x7C00

start:
    ; Set up segment registers
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00  ; Stack grows downward from bootloader

    ; Print boot message
    mov si, msg_boot
    call print_string

    ; Load kernel from disk (sector 2 onward) into 0x1000:0x0000
    call load_kernel

    ; Jump to kernel
    jmp 0x0000:0x1000

; ── print_string ──────────────────────────────────────────────────────────────
; SI = pointer to null-terminated string
print_string:
    mov ah, 0x0E        ; BIOS teletype output
.loop:
    lodsb               ; Load byte from [SI] into AL, advance SI
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

; ── load_kernel ───────────────────────────────────────────────────────────────
; Reads sectors 2..17 (16 sectors = 8 KB) into memory at 0x1000
load_kernel:
    mov ah, 0x02        ; BIOS read sectors
    mov al, 16          ; Number of sectors to read
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start at sector 2 (sector 1 = bootloader)
    mov dh, 0           ; Head 0
    mov dl, 0x80        ; First hard disk (use 0x00 for floppy)
    mov bx, 0x1000      ; Destination offset
    int 0x13
    jc disk_error       ; Carry flag set = error
    ret

disk_error:
    mov si, msg_disk_err
    call print_string
    hlt

; ── Data ──────────────────────────────────────────────────────────────────────
msg_boot     db "AmaiOS Booting...", 0x0D, 0x0A, 0
msg_disk_err db "Disk read error!", 0x0D, 0x0A, 0

; ── Boot sector padding & signature ───────────────────────────────────────────
times 510 - ($ - $$) db 0  ; Pad to 510 bytes
dw 0xAA55                   ; Boot signature (BIOS checks for this)
