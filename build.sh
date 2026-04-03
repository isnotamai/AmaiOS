#!/usr/bin/env bash
# AmaiOS Build Script
# Base: Kubuntu 24.04 LTS (KDE Plasma)
#
# Requirements (WSL2 Ubuntu):
#   sudo apt-get install xorriso squashfs-tools wget mtools
#
# Usage:
#   sudo bash build.sh

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
# You can override the ISO path:  sudo bash build.sh /path/to/kubuntu.iso
OUTPUT_ISO="AmaiOS-0.1-amd64.iso"

# Try these point releases in order until one downloads successfully
CANDIDATE_VERSIONS=("24.04.2" "24.04.3" "24.04.4" "24.04.1")
BASE_ISO_URL=""
BASE_ISO_NAME=""

WORK_DIR="$(pwd)/work"
ISO_DIR="$WORK_DIR/iso"
SQUASH_DIR="$WORK_DIR/squashfs"

# ── Helpers ───────────────────────────────────────────────────────────────────
info()  { echo -e "\033[1;34m[*]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[+]\033[0m $*"; }
error() { echo -e "\033[1;31m[!]\033[0m $*" >&2; exit 1; }

cleanup() {
    info "Cleaning up mounts..."
    for mnt in dev/pts dev run proc sys; do
        mountpoint -q "$SQUASH_DIR/$mnt" 2>/dev/null && umount "$SQUASH_DIR/$mnt" || true
    done
}
trap cleanup EXIT

# ── Checks ────────────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Run as root: sudo bash build.sh"

for cmd in xorriso unsquashfs mksquashfs wget; do
    command -v "$cmd" &>/dev/null || error "Missing: $cmd  →  sudo apt-get install xorriso squashfs-tools wget mtools"
done

# ── Step 1: Find / download base ISO ─────────────────────────────────────────
info "[1/6] Checking base ISO..."

# If user passed an ISO path as argument, use it directly
if [[ -n "${1:-}" && -f "$1" ]]; then
    BASE_ISO_NAME="$1"
    ok "Using provided ISO: $BASE_ISO_NAME"
else
    # Check if any kubuntu iso already exists locally
    LOCAL_ISO=$(ls kubuntu-24.04*-desktop-amd64.iso 2>/dev/null | head -1 || true)
    if [[ -n "$LOCAL_ISO" ]]; then
        BASE_ISO_NAME="$LOCAL_ISO"
        ok "Found local ISO: $BASE_ISO_NAME"
    else
        # Try each candidate version
        info "No local ISO found. Searching for latest Kubuntu 24.04..."
        for VER in "${CANDIDATE_VERSIONS[@]}"; do
            CANDIDATE_NAME="kubuntu-${VER}-desktop-amd64.iso"
            CANDIDATE_URL="https://cdimage.ubuntu.com/kubuntu/releases/${VER}/release/${CANDIDATE_NAME}"
            info "Trying $CANDIDATE_URL ..."
            if wget --spider "$CANDIDATE_URL" 2>/dev/null; then
                BASE_ISO_NAME="$CANDIDATE_NAME"
                BASE_ISO_URL="$CANDIDATE_URL"
                break
            fi
        done

        if [[ -z "$BASE_ISO_URL" ]]; then
            error "Could not find a Kubuntu 24.04 ISO to download.
  Please download it manually from https://kubuntu.org/getkubuntu/
  and place it in this directory, then re-run:  sudo bash build.sh"
        fi

        info "Downloading $BASE_ISO_NAME (~4 GB)..."
        wget -c "$BASE_ISO_URL" -O "$BASE_ISO_NAME"
    fi
fi
# Sanity check: ISO should be at least 2 GB
ISO_SIZE=$(stat -c%s "$BASE_ISO_NAME" 2>/dev/null || echo 0)
[[ "$ISO_SIZE" -lt 2000000000 ]] && error "ISO file is too small (${ISO_SIZE} bytes). Download may have failed. Delete it and retry."
ok "Base ISO ready: $BASE_ISO_NAME ($(( ISO_SIZE / 1024 / 1024 )) MB)"

# ── Step 2: Extract ISO ───────────────────────────────────────────────────────
info "[2/6] Extracting ISO contents..."
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR"
xorriso -osirrox on -indev "$BASE_ISO_NAME" -extract / "$ISO_DIR"
chmod -R u+w "$ISO_DIR"
ok "ISO extracted to $ISO_DIR"

# ── Step 3: Extract squashfs filesystem ───────────────────────────────────────
info "[3/6] Extracting root filesystem (this may take a while)..."
rm -rf "$SQUASH_DIR"
unsquashfs -d "$SQUASH_DIR" "$ISO_DIR/casper/filesystem.squashfs"
ok "Filesystem extracted to $SQUASH_DIR"

# ── Step 4: Chroot customization ──────────────────────────────────────────────
info "[4/6] Entering chroot for customization..."

cp /etc/resolv.conf "$SQUASH_DIR/etc/resolv.conf"
mount --bind /dev     "$SQUASH_DIR/dev"
mount --bind /dev/pts "$SQUASH_DIR/dev/pts"
mount --bind /run     "$SQUASH_DIR/run"
mount -t proc  proc   "$SQUASH_DIR/proc"
mount -t sysfs sysfs  "$SQUASH_DIR/sys"

cp scripts/chroot.sh "$SQUASH_DIR/tmp/chroot.sh"
cp config/packages.list "$SQUASH_DIR/tmp/packages.list"
chmod +x "$SQUASH_DIR/tmp/chroot.sh"
chroot "$SQUASH_DIR" /bin/bash /tmp/chroot.sh
rm -f "$SQUASH_DIR/tmp/chroot.sh" "$SQUASH_DIR/tmp/packages.list" "$SQUASH_DIR/etc/resolv.conf"

# Unmount immediately after chroot — must happen before mksquashfs
info "Unmounting chroot filesystems..."
for mnt in dev/pts dev run proc sys; do
    mountpoint -q "$SQUASH_DIR/$mnt" 2>/dev/null && umount "$SQUASH_DIR/$mnt" || true
done

ok "Chroot customization complete"

# ── Step 5: Apply branding ────────────────────────────────────────────────────
info "[5/6] Applying AmaiOS branding..."

cp config/os-release "$SQUASH_DIR/etc/os-release"

# Copy wallpaper if provided
if [[ -f branding/wallpaper.jpg ]]; then
    cp branding/wallpaper.jpg "$SQUASH_DIR/usr/share/wallpapers/AmaiOS.jpg"
fi

# Update ISO label file
sed -i 's/Kubuntu/AmaiOS/g' "$ISO_DIR/README.diskdefines" 2>/dev/null || true
ok "Branding applied"

# ── Step 6: Repack ISO ────────────────────────────────────────────────────────
info "[6/6] Repacking ISO..."

# Regenerate squashfs
rm -f "$ISO_DIR/casper/filesystem.squashfs"
mksquashfs "$SQUASH_DIR" "$ISO_DIR/casper/filesystem.squashfs" \
    -comp gzip -noappend -no-progress -processors 4 \
    -wildcards \
    -e "proc/*" -e "sys/*" -e "dev/*" -e "run/*" -e "tmp/*"
printf "%s" "$(du -sx --block-size=1 "$SQUASH_DIR" | cut -f1)" \
    > "$ISO_DIR/casper/filesystem.size"

# Regenerate md5sums
pushd "$ISO_DIR" > /dev/null
find . -type f ! -name 'md5sum.txt' | sort | xargs md5sum > md5sum.txt
popd > /dev/null

# Extract boot files from original ISO (not included in the extracted contents)
info "Extracting boot sectors from original ISO..."
dd if="$BASE_ISO_NAME" bs=1 count=432 of="$WORK_DIR/boot_hybrid.img" 2>/dev/null
EFI_OFFSET=$(fdisk -l "$BASE_ISO_NAME" | grep "EFI System" | awk '{print $2}')
EFI_SIZE=$(fdisk -l "$BASE_ISO_NAME" | grep "EFI System" | awk '{print $4}')
dd if="$BASE_ISO_NAME" bs=512 skip="$EFI_OFFSET" count="$EFI_SIZE" of="$WORK_DIR/efi.img" 2>/dev/null

# Build final ISO (BIOS + EFI hybrid)
xorriso -as mkisofs \
    -r -V "AmaiOS_0.1" \
    -o "$OUTPUT_ISO" \
    --grub2-mbr "$WORK_DIR/boot_hybrid.img" \
    -partition_offset 16 \
    --mbr-force-bootable \
    -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b \
        "$WORK_DIR/efi.img" \
    -appended_part_as_gpt \
    -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    -c '/boot/boot.cat' \
    -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
    -eltorito-alt-boot \
    -e '--interval:appended_partition_2:::' \
    -no-emul-boot \
    "$ISO_DIR"

ok "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "Build complete!  →  $OUTPUT_ISO"
ok "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
