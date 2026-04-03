#!/usr/bin/env bash
# Runs inside the chroot environment.
# Installs packages and applies system-level customizations.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export HOME=/root
export LC_ALL=C

echo "[chroot] Updating package lists..."
apt-get update -q

# ── Remove packages ───────────────────────────────────────────────────────────
echo "[chroot] Removing unwanted packages..."
REMOVE=(
    # Remove if you don't need them; comment out to keep
    # "aisleriot"      # card games
    # "gnome-mahjongg"
)
if [[ ${#REMOVE[@]} -gt 0 ]]; then
    apt-get remove -y --purge "${REMOVE[@]}" 2>/dev/null || true
fi

# ── Install packages ──────────────────────────────────────────────────────────
echo "[chroot] Installing packages from config..."
if [[ -f /tmp/packages.list ]]; then
    mapfile -t PACKAGES < /tmp/packages.list
    # Filter out blank lines and comments
    INSTALL=()
    for pkg in "${PACKAGES[@]}"; do
        [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
        INSTALL+=("$pkg")
    done
    if [[ ${#INSTALL[@]} -gt 0 ]]; then
        apt-get install -y "${INSTALL[@]}"
    fi
fi

# ── Set hostname ──────────────────────────────────────────────────────────────
echo "[chroot] Setting hostname..."
echo "amaios" > /etc/hostname
sed -i 's/kubuntu/amaios/g' /etc/hosts 2>/dev/null || true

# ── Set default locale & timezone ────────────────────────────────────────────
echo "[chroot] Setting locale and timezone..."
locale-gen zh_TW.UTF-8 en_US.UTF-8
update-locale LANG=zh_TW.UTF-8

# ── Cleanup ───────────────────────────────────────────────────────────────────
echo "[chroot] Cleaning up..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -f /tmp/packages.list

echo "[chroot] Done."
