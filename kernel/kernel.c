/*
 * AmaiOS - Kernel entry point
 * Runs in 32-bit protected mode after the bootloader hands off control.
 */

/* VGA text-mode buffer: 80 columns x 25 rows, each cell is 2 bytes (char + color) */
#define VGA_ADDRESS  0xB8000
#define VGA_COLS     80
#define VGA_ROWS     25

/* Color byte: high nibble = background, low nibble = foreground */
#define COLOR_WHITE_ON_BLACK  0x0F
#define COLOR_CYAN_ON_BLACK   0x0B

static unsigned short *vga = (unsigned short *)VGA_ADDRESS;
static int cursor_col = 0;
static int cursor_row = 0;

/* ── VGA helpers ─────────────────────────────────────────────────────────── */

static void vga_clear(void)
{
    for (int i = 0; i < VGA_ROWS * VGA_COLS; i++)
        vga[i] = (unsigned short)(COLOR_WHITE_ON_BLACK << 8) | ' ';
    cursor_col = 0;
    cursor_row = 0;
}

static void vga_putchar(char c, unsigned char color)
{
    if (c == '\n') {
        cursor_col = 0;
        cursor_row++;
        return;
    }

    if (cursor_col >= VGA_COLS) {
        cursor_col = 0;
        cursor_row++;
    }

    if (cursor_row >= VGA_ROWS) {
        /* Scroll up by one row */
        for (int r = 0; r < VGA_ROWS - 1; r++)
            for (int col = 0; col < VGA_COLS; col++)
                vga[r * VGA_COLS + col] = vga[(r + 1) * VGA_COLS + col];
        /* Clear last row */
        for (int col = 0; col < VGA_COLS; col++)
            vga[(VGA_ROWS - 1) * VGA_COLS + col] = (unsigned short)(color << 8) | ' ';
        cursor_row = VGA_ROWS - 1;
    }

    vga[cursor_row * VGA_COLS + cursor_col] = (unsigned short)(color << 8) | (unsigned char)c;
    cursor_col++;
}

static void print(const char *str, unsigned char color)
{
    for (; *str; str++)
        vga_putchar(*str, color);
}

/* ── Kernel main ─────────────────────────────────────────────────────────── */

void kernel_main(void)
{
    vga_clear();

    print("  ___                _    ___  ____  \n", COLOR_CYAN_ON_BLACK);
    print(" / _ \\  _ __  ___  (_)  / _ \\/ ___| \n", COLOR_CYAN_ON_BLACK);
    print("| | | || '__|/ _ \\ | | | | | \\___ \\ \n", COLOR_CYAN_ON_BLACK);
    print("| |_| || |  |  __/ | | | |_| |___) |\n", COLOR_CYAN_ON_BLACK);
    print(" \\___/ |_|   \\___| |_|  \\___/|____/ \n", COLOR_CYAN_ON_BLACK);
    print("\n", COLOR_WHITE_ON_BLACK);
    print("  Welcome to AmaiOS v0.1\n", COLOR_WHITE_ON_BLACK);
    print("  Kernel loaded successfully.\n", COLOR_WHITE_ON_BLACK);
    print("\n", COLOR_WHITE_ON_BLACK);
    print("> ", COLOR_WHITE_ON_BLACK);

    /* Halt — no scheduler yet */
    for (;;)
        __asm__ volatile("hlt");
}
