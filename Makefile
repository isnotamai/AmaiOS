# AmaiOS Build System

ASM    = nasm
CC     = gcc
LD     = ld

CFLAGS = -m32 -ffreestanding -fno-pie -fno-stack-protector -nostdlib -O2
LDFLAGS = -m elf_i386 -T linker.ld --oformat binary

BUILD  = build

.PHONY: all clean run

all: $(BUILD)/amaios.img

# ── Bootloader ────────────────────────────────────────────────────────────────
$(BUILD)/boot.bin: boot/boot.asm | $(BUILD)
	$(ASM) -f bin $< -o $@

# ── Kernel ────────────────────────────────────────────────────────────────────
$(BUILD)/kernel_entry.o: kernel/kernel_entry.asm | $(BUILD)
	$(ASM) -f elf32 $< -o $@

$(BUILD)/kernel.o: kernel/kernel.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/kernel.bin: $(BUILD)/kernel_entry.o $(BUILD)/kernel.o
	$(LD) $(LDFLAGS) -o $@ $^

# ── Disk image ────────────────────────────────────────────────────────────────
# Combine bootloader + kernel into a single disk image
$(BUILD)/amaios.img: $(BUILD)/boot.bin $(BUILD)/kernel.bin
	cat $^ > $@

# ── Helpers ───────────────────────────────────────────────────────────────────
$(BUILD):
	mkdir -p $(BUILD)

run: $(BUILD)/amaios.img
	qemu-system-i386 -drive format=raw,file=$<

clean:
	rm -rf $(BUILD)
