#!/system/bin/sh
set -eu

if [ -n "${TERMUX_VERSION:-}" ]; then
  unset LD_PRELOAD
fi

XSU_BIN="${XSU_BIN:-/product/bin/xsu}"
ROOT_TMP="${ROOT_TMP:-/dev/roottmp}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/sdcard/Download/ds-keypad-root}"
MAGISK_TAR_PATH="${MAGISK_TAR_PATH:-$DOWNLOAD_DIR/magisk29.tgz}"
SLOT_SUFFIX="$(getprop ro.boot.slot_suffix)"
INIT_BOOT="/dev/block/by-name/init_boot${SLOT_SUFFIX}"
BACKUP_DIR="/sdcard/magisk_backup_$(date +%Y%m%d_%H%M%S)"
AUTO_REBOOT="${AUTO_REBOOT:-0}"

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    sh -c "$1"
  else
    "$XSU_BIN" sh -c "$1"
  fi
}

echo "DS Keypad root installer"
echo "init_boot: $INIT_BOOT"
echo "magisk package: $MAGISK_TAR_PATH"

if [ "$(id -u)" -ne 0 ] && [ ! -x "$XSU_BIN" ]; then
  echo "ERROR: $XSU_BIN not found. This installer needs xsu or an existing root shell."
  exit 1
fi

if [ ! -f "$MAGISK_TAR_PATH" ]; then
  echo "ERROR: $MAGISK_TAR_PATH not found."
  echo "Run install.sh first, or set MAGISK_TAR_PATH=/path/to/magisk29.tgz."
  exit 1
fi

echo "[1/8] preparing temp dir"
run_root "rm -rf '$ROOT_TMP' && mkdir -p '$ROOT_TMP'"

echo "[2/8] copying magisk package"
run_root "cp '$MAGISK_TAR_PATH' '$ROOT_TMP/magisk.tar.gz'"

echo "[3/8] extracting package"
run_root "tar -xzf '$ROOT_TMP/magisk.tar.gz' -C '$ROOT_TMP'"

MAGISK_DIR="$ROOT_TMP/magisk"
MAGISK_BIN="$MAGISK_DIR/magisk"
PATCH_SCRIPT="$MAGISK_DIR/boot_patch.sh"
PATCHED_BOOT="$MAGISK_DIR/new-boot.img"

echo "[4/8] validating extracted files"
run_root "chmod +x -R '$ROOT_TMP'"
run_root "test -f '$MAGISK_BIN' && test -f '$PATCH_SCRIPT'"

echo "[5/8] backing up current init_boot"
run_root "mkdir -p '$BACKUP_DIR'"
run_root "gzip -c '$INIT_BOOT' > '$BACKUP_DIR/init_boot.img.gz'"
run_root "cp '$BACKUP_DIR/init_boot.img.gz' /sdcard/init_boot.img.gz"

echo "[6/8] patching init_boot"
run_root "cd '$MAGISK_DIR' && sh '$PATCH_SCRIPT' '$INIT_BOOT'"

echo "[7/8] validating patched image"
run_root "test -f '$PATCHED_BOOT'"

echo "[8/8] flashing patched image"
run_root "dd if='$PATCHED_BOOT' of='$INIT_BOOT'"

run_root "rm -rf '$ROOT_TMP'"

echo "Root installation finished."
echo "Backup saved at: $BACKUP_DIR/init_boot.img.gz"
echo "Latest backup copy: /sdcard/init_boot.img.gz"

if [ "$AUTO_REBOOT" = "1" ]; then
  echo "Rebooting now."
  run_root "reboot"
else
  echo "Reboot manually after reviewing the log."
fi
