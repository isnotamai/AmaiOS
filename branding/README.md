# AmaiOS Branding Assets

Place your custom assets here. The build script will automatically pick them up if present.

| File            | Format   | Recommended Size | Description                          |
|-----------------|----------|------------------|--------------------------------------|
| `wallpaper.jpg` | JPEG     | 3840×2160 (4K)   | Default desktop wallpaper            |
| `logo.png`      | PNG      | 256×256          | Distro logo (used by fastfetch, etc) |

## Notes

- `wallpaper.jpg` is installed to `/usr/share/wallpapers/AmaiOS/` and set as the KDE Plasma default.
- `logo.png` is installed to `/usr/share/pixmaps/amaios-logo.png`.
- If either file is missing, the build continues with defaults.
