#!/system/bin/sh
set -eu

if [ -n "${TERMUX_VERSION:-}" ]; then
  unset LD_PRELOAD
fi

ROOT_BASE_URL="${ROOT_BASE_URL:-https://linyoujie.github.io/DSKeypad/root}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/sdcard/Download/ds-keypad-root}"
FLASH_ROOT="${FLASH_ROOT:-0}"
INSTALL_MAGISK_APP="${INSTALL_MAGISK_APP:-1}"
AUTO_REBOOT="${AUTO_REBOOT:-0}"

fetch() {
  url="$1"
  out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fL "$url" -o "$out"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$out" "$url"
  else
    echo "ERROR: curl or wget is required."
    exit 1
  fi
}

echo "DS Keypad remote root package installer"
echo "Source: $ROOT_BASE_URL"
echo "Target: $DOWNLOAD_DIR"

mkdir -p "$DOWNLOAD_DIR"

for name in SHA256SUMS install.sh magisk29.tgz Magisk-v29.0.apk root-install.sh; do
  echo "Downloading $name"
  fetch "$ROOT_BASE_URL/$name" "$DOWNLOAD_DIR/$name"
done

chmod 755 "$DOWNLOAD_DIR/root-install.sh"

if command -v sha256sum >/dev/null 2>&1; then
  echo "Verifying SHA256"
  (cd "$DOWNLOAD_DIR" && sha256sum -c SHA256SUMS)
else
  echo "sha256sum not found; skipping checksum verification."
fi

if [ "$INSTALL_MAGISK_APP" = "1" ]; then
  echo "Installing Magisk app"
  pm install -r "$DOWNLOAD_DIR/Magisk-v29.0.apk" || true
fi

echo "Downloaded root files to $DOWNLOAD_DIR"

if [ "$FLASH_ROOT" = "1" ]; then
  echo "FLASH_ROOT=1, running root installer."
  AUTO_REBOOT="$AUTO_REBOOT" DOWNLOAD_DIR="$DOWNLOAD_DIR" sh "$DOWNLOAD_DIR/root-install.sh"
else
  echo "Root flashing was not run."
  echo "To flash root after reviewing files:"
  echo "  FLASH_ROOT=1 AUTO_REBOOT=1 sh '$DOWNLOAD_DIR/install.sh'"
  echo "Or:"
  echo "  AUTO_REBOOT=1 sh '$DOWNLOAD_DIR/root-install.sh'"
fi
