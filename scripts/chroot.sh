#!/usr/bin/env bash
# Runs inside the chroot environment.
# Installs packages and applies system-level customizations.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export HOME=/root
export LC_ALL=C

# ── Fix /dev/null inside chroot ───────────────────────────────────────────────
# apt-key redirects stderr to /dev/null; if it's missing or wrong type, GPG
# verification fails with "cannot create /dev/null: Permission denied".
if [[ ! -c /dev/null ]]; then
    echo "[chroot] Recreating /dev/null as char device..."
    rm -f /dev/null
    mknod -m 0666 /dev/null c 1 3
fi
chmod 0666 /dev/null

# ── Enable universe & multiverse repos ───────────────────────────────────────
# Many packages (libreoffice, vlc, fcitx5, fonts…) live in universe/multiverse.
echo "[chroot] Enabling universe and multiverse repositories..."
# Ubuntu 24.04 uses the new DEB822 format (/etc/apt/sources.list.d/ubuntu.sources)
if [[ -f /etc/apt/sources.list.d/ubuntu.sources ]]; then
    sed -i 's/^Components: main$/Components: main restricted universe multiverse/' \
        /etc/apt/sources.list.d/ubuntu.sources
    echo "[chroot] Patched ubuntu.sources (DEB822 format)"
fi

# Legacy single-line format
if [[ -f /etc/apt/sources.list ]]; then
    sed -i \
        -e 's/^deb \(.*\) noble main$/deb \1 noble main restricted universe multiverse/' \
        -e 's/^deb \(.*\) noble-updates main$/deb \1 noble-updates main restricted universe multiverse/' \
        -e 's/^deb \(.*\) noble-security main$/deb \1 noble-security main restricted universe multiverse/' \
        /etc/apt/sources.list
    echo "[chroot] Patched sources.list"
fi

# Pre-accept Microsoft fonts EULA (needed by ttf-mscorefonts-installer)
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
    | debconf-set-selections 2>/dev/null || true

# ── Update package lists ──────────────────────────────────────────────────────
echo "[chroot] Updating package lists..."
apt-get update -q 2>&1 | grep -v "^W: " || true   # suppress warnings, not errors
# If GPG is still broken, retry without authentication (keys will be fixed by ubuntu-keyring)
if ! apt-get update -q 2>/dev/null; then
    echo "[chroot] Retrying apt-get update with relaxed GPG checks..."
    apt-get update -q \
        -o Acquire::AllowInsecureRepositories=true \
        -o APT::Get::AllowUnauthenticated=true 2>/dev/null || true
fi

# Ensure gpgv is installed so subsequent apt operations work correctly
apt-get install -y --no-install-recommends gpgv gnupg 2>/dev/null || true
apt-get update -q 2>/dev/null || true

# ── Remove packages ───────────────────────────────────────────────────────────
echo "[chroot] Removing unwanted packages..."
apt-get remove -y --purge kubuntu-default-settings 2>/dev/null || true

# ── Install packages ──────────────────────────────────────────────────────────
echo "[chroot] Installing packages from config..."
if [[ -f /tmp/packages.list ]]; then
    mapfile -t PACKAGES < /tmp/packages.list
    INSTALL=()
    for pkg in "${PACKAGES[@]}"; do
        [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
        INSTALL+=("$pkg")
    done

    if [[ ${#INSTALL[@]} -gt 0 ]]; then
        # Try installing all at once first (faster)
        if ! apt-get install -y "${INSTALL[@]}" 2>/dev/null; then
            echo "[chroot] Bulk install failed; installing packages one by one..."
            FAILED=()
            for pkg in "${INSTALL[@]}"; do
                if apt-get install -y "$pkg" 2>/dev/null; then
                    echo "[chroot]   OK: $pkg"
                else
                    echo "[chroot]   SKIP: $pkg (not available)"
                    FAILED+=("$pkg")
                fi
            done
            if [[ ${#FAILED[@]} -gt 0 ]]; then
                echo "[chroot] Skipped packages (not in repos): ${FAILED[*]}"
            fi
        fi
    fi
fi

# ── Set hostname ──────────────────────────────────────────────────────────────
echo "[chroot] Setting hostname..."
echo "amaios" > /etc/hostname
cat > /etc/hosts <<'EOF'
127.0.0.1   localhost
127.0.1.1   amaios
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# ── Set default locale & timezone ────────────────────────────────────────────
echo "[chroot] Setting locale and timezone..."
locale-gen zh_TW.UTF-8 en_US.UTF-8
update-locale LANG=zh_TW.UTF-8 LC_ALL=zh_TW.UTF-8

ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
echo "Asia/Taipei" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# ── GRUB branding ─────────────────────────────────────────────────────────────
echo "[chroot] Patching GRUB branding..."
if [[ -f /etc/default/grub ]]; then
    sed -i \
        -e 's/GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="AmaiOS"/' \
        -e 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' \
        /etc/default/grub

    # Set a nice GRUB background color (dark blue) if no image provided
    if ! grep -q "GRUB_COLOR_NORMAL" /etc/default/grub; then
        echo 'GRUB_COLOR_NORMAL="light-blue/black"' >> /etc/default/grub
        echo 'GRUB_COLOR_HIGHLIGHT="white/blue"'   >> /etc/default/grub
    fi

    update-grub 2>/dev/null || true
fi

# Patch grub menu entries to say AmaiOS
for f in /boot/grub/grub.cfg /boot/grub/grub-early.cfg; do
    [[ -f "$f" ]] && sed -i 's/Kubuntu/AmaiOS/g; s/Ubuntu/AmaiOS/g' "$f" || true
done

# ── Plymouth boot splash ──────────────────────────────────────────────────────
echo "[chroot] Configuring Plymouth theme..."
if command -v plymouth-set-default-theme &>/dev/null; then
    # Use 'bgrt' as a clean neutral theme if kubuntu-logo not available
    THEME="bgrt"
    for t in kubuntu-logo ubuntu-logo spinner; do
        if plymouth-set-default-theme --list 2>/dev/null | grep -q "^${t}$"; then
            THEME="$t"
            break
        fi
    done
    plymouth-set-default-theme -R "$THEME" 2>/dev/null || true
fi

# Patch Plymouth label if present
for f in /usr/share/plymouth/themes/*/plymouth-theme.conf \
         /usr/share/plymouth/themes/*/kubuntu-logo.plymouth; do
    [[ -f "$f" ]] && sed -i 's/Kubuntu/AmaiOS/g; s/Ubuntu/AmaiOS/g' "$f" || true
done

# ── Calamares installer branding ─────────────────────────────────────────────
echo "[chroot] Installing AmaiOS Calamares branding..."

AMAIOS_BRANDING="/usr/share/calamares/branding/amaios"
mkdir -p "$AMAIOS_BRANDING"

# Copy pre-built branding files (placed here by build.sh before chroot)
if [[ -d /tmp/calamares-branding ]]; then
    cp -r /tmp/calamares-branding/. "$AMAIOS_BRANDING/"
    echo "[chroot] Custom branding files installed to $AMAIOS_BRANDING"
fi

# Copy logo from pixmaps if available (wallpaper/logo placed by build.sh)
if [[ -f /usr/share/pixmaps/amaios-logo.png ]]; then
    cp /usr/share/pixmaps/amaios-logo.png "$AMAIOS_BRANDING/logo.png"
fi

# Tell Calamares to use the amaios branding
CALAMARES_SETTINGS="/etc/calamares/settings.conf"
if [[ -f "$CALAMARES_SETTINGS" ]]; then
    sed -i 's/branding: .*/branding: amaios/' "$CALAMARES_SETTINGS"
    echo "[chroot] Calamares settings.conf updated: branding → amaios"
else
    # Kubuntu may store settings.conf elsewhere; search for it
    for f in /usr/share/calamares/settings.conf \
              /usr/lib/calamares/settings.conf; do
        if [[ -f "$f" ]]; then
            sed -i 's/branding: .*/branding: amaios/' "$f"
            echo "[chroot] Patched: $f"
        fi
    done
fi

# Patch Calamares locale module defaults
for f in /etc/calamares/modules/locale.conf \
         /usr/share/calamares/modules/locale.conf; do
    if [[ -f "$f" ]]; then
        sed -i \
            -e 's/region:.*/region: Asia/' \
            -e 's/zone:.*/zone: Taipei/' \
            "$f" 2>/dev/null || true
        echo "[chroot] Locale defaults set in $f"
    fi
done

# Patch any remaining Kubuntu references in other Calamares configs
find /usr/share/calamares /etc/calamares -type f \( -name "*.conf" -o -name "*.desc" \) \
    -exec sed -i 's/Kubuntu/AmaiOS/g; s/kubuntu/amaios/g' {} \; 2>/dev/null || true

# ── KDE Plasma defaults (applied to /etc/skel so new users get them) ─────────
echo "[chroot] Configuring KDE Plasma defaults..."
SKEL_KDE="/etc/skel/.config"
mkdir -p "$SKEL_KDE"

# Set locale for KDE
cat > "$SKEL_KDE/plasma-localerc" <<'EOF'
[Formats]
LANG=zh_TW.UTF-8

[Translations]
LANGUAGE=zh_TW
EOF

# Set a clean KDE look-and-feel
cat > "$SKEL_KDE/kdeglobals" <<'EOF'
[General]
XftAntialias=true
XftHintStyle=hintmedium
XftSubPixel=rgb

[KDE]
SingleClick=false
AnimationDurationFactor=0.5
EOF

# Plasma workspace defaults
cat > "$SKEL_KDE/kscreenlockerrc" <<'EOF'
[Daemon]
Autolock=true
LockOnResume=true
Timeout=10
EOF

# Taskbar: show battery, clock, network
mkdir -p "$SKEL_KDE/plasma-org.kde.plasma.desktop-appletsrc.d"

# Fcitx5 autostart
SKEL_AUTOSTART="/etc/skel/.config/autostart"
mkdir -p "$SKEL_AUTOSTART"
cat > "$SKEL_AUTOSTART/fcitx5.desktop" <<'EOF'
[Desktop Entry]
Name=Fcitx5
GenericName=Input Method
Exec=fcitx5
Icon=fcitx5
Terminal=false
Type=Application
Categories=System;Utility;
X-GNOME-Autostart-Phase=Applications
X-GNOME-AutoRestart=false
X-GNOME-Autostart-Notify=false
X-KDE-autostart-after=panel
EOF

# ── Live environment setup ────────────────────────────────────────────────────
echo "[chroot] Setting up live environment..."

# Set default keyboard layout for live session
if [[ -f /etc/default/keyboard ]]; then
    sed -i \
        -e 's/XKBLAYOUT=.*/XKBLAYOUT="us"/' \
        -e 's/XKBVARIANT=.*/XKBVARIANT=""/' \
        /etc/default/keyboard
fi

# Ensure casper (live session) sets the right username
if [[ -f /etc/casper.conf ]]; then
    sed -i \
        -e 's/^export USERNAME=.*/export USERNAME="amaios"/' \
        -e 's/^export FLAVOUR=.*/export FLAVOUR="AmaiOS"/' \
        /etc/casper.conf
else
    cat > /etc/casper.conf <<'EOF'
export USERNAME="amaios"
export HOSTNAME="amaios"
export FLAVOUR="AmaiOS"
EOF
fi

# ── Cleanup ───────────────────────────────────────────────────────────────────
echo "[chroot] Cleaning up..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -f /tmp/packages.list

echo "[chroot] Done."
