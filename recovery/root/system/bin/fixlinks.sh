#!/system/bin/sh
# Honor 9 (stanford / hi3660) block device fixups.
#
# Huawei exposes the partitions as /dev/block/platform/<controller>/by-name/*,
# while Android 12 based recoveries address them as /dev/block/by-name/* and
# Huawei's own tools use /dev/block/bootdevice/*. Map all three to the same
# directory. The stock EMUI 9 firmware also labels partitions with an "_a"
# suffix even though the Honor 9 has no real A/B slots.
#
# Run by init as:  /system/bin/sh /system/bin/fixlinks.sh

P=
for c in ff3b0000.ufs hi_mci.0 hi_mci.1; do
    if [ -d "/dev/block/platform/$c/by-name" ]; then
        P="/dev/block/platform/$c"
        break
    fi
done

if [ -n "$P" ]; then
    echo "fixlinks: using $P"
    ln -sfn "$P" /dev/block/bootdevice
    if [ ! -e /dev/block/by-name ] && [ ! -L /dev/block/by-name ]; then
        ln -sfn "$P/by-name" /dev/block/by-name
    fi
else
    echo "fixlinks: no Huawei by-name directory found"
    ls -l /dev/block/platform 2>/dev/null
fi

for f in /dev/block/by-name/*_a; do
    [ -e "$f" ] || continue
    ln -sf "$f" "${f%??}"
done

# TWRP expects the boot ramdisk as "ramdisk"; Huawei names it "kernel".
if [ -e /dev/block/by-name/kernel ]; then
    ln -sf /dev/block/by-name/kernel /dev/block/by-name/ramdisk
fi

sync
