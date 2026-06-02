# Ensure LD_PRELOAD is unset in termux environment
if [ -n "$TERMUX_VERSION" ]; then
    unset LD_PRELOAD
fi

export XSU_PREFIX=/product/bin/xsu

# Check if run as root
if [ "$(id -u)" -eq 0 ]; then
    echo "Running as root, no xsu prefix needed."
    unset XSU_PREFIX
fi

BASE_URL="https://linyoujie.github.io/DSKeypad/root"

# Create temp folders
$XSU_PREFIX rm -rf /dev/roottmp/
$XSU_PREFIX mkdir -p /dev/roottmp/

# Download modules
$XSU_PREFIX curl -L "$BASE_URL/magisk29.tgz" -o /dev/roottmp/magisk.tar.gz || \
$XSU_PREFIX wget -O /dev/roottmp/magisk.tar.gz "$BASE_URL/magisk29.tgz"

# Decompress
$XSU_PREFIX tar -xvzf /dev/roottmp/magisk.tar.gz -C /dev/roottmp/

# Ensure eXecute permission
$XSU_PREFIX chmod +x -R /dev/roottmp/

# Backup current boot image
$XSU_PREFIX gzip -k -c /dev/block/by-name/init_boot$(getprop ro.boot.slot_suffix) > /sdcard/boot.img.xz
$XSU_PREFIX mkdir -p /data/magisk_backup_$(cat $(/dev/roottmp/magisk/magisk --path)/.magisk/config | grep SHA1 | cut -d '=' -f 2)
$XSU_PREFIX mv /sdcard/boot.img.xz /data/magisk_backup_$(cat $(/dev/roottmp/magisk/magisk --path)/.magisk/config | grep SHA1 | cut -d '=' -f 2)/boot.img.gz
$XSU_PREFIX chmod -R 755 /data/magisk_backup_$(cat $(/dev/roottmp/magisk/magisk --path)/.magisk/config | grep SHA1 | cut -d '=' -f 2)
$XSU_PREFIX chown -R root.root /data/magisk_backup_$(cat $(/dev/roottmp/magisk/magisk --path)/.magisk/config | grep SHA1 | cut -d '=' -f 2)

# Patch boot image
$XSU_PREFIX cd /dev/roottmp/magisk && sh /dev/roottmp/magisk/boot_patch.sh /dev/block/by-name/init_boot$(getprop ro.boot.slot_suffix)

# Flash patched boot image
$XSU_PREFIX dd if=/dev/roottmp/magisk/new-boot.img of=/dev/block/by-name/init_boot$(getprop ro.boot.slot_suffix)

# Clean up
$XSU_PREFIX rm -rf /dev/roottmp/

echo Installation Finished. System Will Reboot In 5 seconds.

LEFT=5
while [ $LEFT -gt 0 ]; do
    echo "$LEFT..."
    sleep 1
    LEFT=$((LEFT - 1))
done
echo "Rebooting now."
$XSU_PREFIX reboot