#!/system/bin/sh
# Honor 9 (stanford / hi3660) block device fixups.
#
# Android 12's ueventd creates /dev/block/by-name only for controllers listed
# in ro.boot.boot_devices, and on this bootloader that property is not reliable,
# while Huawei's own trees use /dev/block/platform/<controller>/by-name (and
# their tools use /dev/block/bootdevice). Build all three views here.
#
# The second half does not depend on ueventd at all: it walks the kernel's
# PARTNAME uevents and creates the by-name links itself. That keeps recovery
# usable even if /system/bin/ueventd is crash-looping, which would otherwise
# leave the whole recovery without any named partition.
#
# Run by init as:  /system/bin/sh /system/bin/fixlinks.sh

log() {
    echo "fixlinks: $*"
    echo "OFRP-DIAG: fixlinks: $*" > /dev/kmsg 2>/dev/null
}

mkdir -p /dev/block 2>/dev/null

P=
for c in ff3b0000.ufs hi_mci.0 hi_mci.1; do
    if [ -d "/dev/block/platform/$c/by-name" ]; then
        P="/dev/block/platform/$c"
        break
    fi
done

if [ -n "$P" ]; then
    log "using $P"
    ln -sfn "$P" /dev/block/bootdevice
    if [ ! -e /dev/block/by-name ] && [ ! -L /dev/block/by-name ]; then
        ln -sfn "$P/by-name" /dev/block/by-name
    fi
else
    log "no Huawei by-name directory"
fi

# Make sure the layout exists even without ueventd.
[ -d /dev/block/by-name ] || mkdir -p /dev/block/by-name 2>/dev/null
[ -e /dev/block/bootdevice ] || ln -sfn /dev/block /dev/block/bootdevice 2>/dev/null

# Huawei labels some partitions with a bogus "_a"/"_b" suffix even though the
# Honor 9 has no A/B slots; TWRP and the fstab use the bare name.
mkdir -p /dev/block/by-name 2>/dev/null
for d in /sys/class/block/*; do
    name=${d##*/}
    pn=
    while IFS= read -r line; do
        case "$line" in
            PARTNAME=*) pn=${line#PARTNAME=} ;;
        esac
    done < "$d/uevent" 2>/dev/null
    [ -n "$pn" ] || continue
    case "$pn" in
        *_a|*_b) pn=${pn%??} ;;
    esac
    if [ ! -e "/dev/block/by-name/$pn" ]; then
        ln -sfn "/dev/block/$name" "/dev/block/by-name/$pn" 2>/dev/null
    fi
done

# Anything ueventd did create with the suffix gets a bare alias too.
for f in /dev/block/by-name/*_a /dev/block/by-name/*_b; do
    [ -e "$f" ] || continue
    ln -sf "$f" "${f%??}" 2>/dev/null
done

# TWRP expects the boot ramdisk as "ramdisk"; Huawei names it "kernel".
if [ -e /dev/block/by-name/kernel ] && [ ! -e /dev/block/by-name/ramdisk ]; then
    ln -sf /dev/block/by-name/kernel /dev/block/by-name/ramdisk
fi

# Huawei tools look for /dev/block/bootdevice/by-name even when bootdevice
# itself is a symlink to the platform controller.
if [ ! -e /dev/block/bootdevice/by-name ]; then
    ln -sfn /dev/block/by-name /dev/block/bootdevice/by-name 2>/dev/null
fi

log "by-name: $(ls /dev/block/by-name 2>/dev/null | tr '\n' ' ')"
sync
