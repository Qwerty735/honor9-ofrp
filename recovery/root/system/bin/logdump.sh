#!/system/bin/sh
#
# Honor 9 (stanford) recovery diagnostics.
#
# The device bootloops roughly a minute after the OrangeFox splash is drawn,
# which is too early for a normal TWRP log to be saved.  This loop keeps a
# dmesg/logcat snapshot on the cache partition (and in /tmp, readable over
# adb) so the reason for the reboot survives it.
#
# Run by init as:  /system/bin/sh /system/bin/logdump.sh
#

OUT=/tmp/logdump.txt
CACHE_LOG=/cache/logdump.txt
CACHE_PSTORE=/cache/pstore-last.txt

CACHE_MOUNTED=0
SD_MOUNTED=0
BL=/sys/class/leds/lcd_backlight0/brightness

# Visible "userspace is alive" signal: three quick backlight blinks right
# before recovery starts. If the splash shows up but never blinks, init never
# reached this point and the problem is earlier than userspace.
blink() {
    [ -w "$BL" ] || return 0
    for _ in 1 2 3; do
        echo 0 > "$BL" 2>/dev/null
        sleep 0.25
        echo 1573 > "$BL" 2>/dev/null
        sleep 0.25
    done
}

mount_cache() {
    [ "$CACHE_MOUNTED" = "1" ] && return 0
    grep -q " /cache " /proc/mounts && CACHE_MOUNTED=1 && return 0
    mkdir -p /cache 2>/dev/null
    for dev in /dev/block/by-name/cache /dev/block/bootdevice/by-name/cache; do
        if mount -t ext4 -o rw "$dev" /cache 2>/dev/null; then
            CACHE_MOUNTED=1
            return 0
        fi
    done
    return 1
}

# A working microSD is the only log sink that survives a bootloop without adb.
mount_sd() {
    [ "$SD_MOUNTED" = "1" ] && return 0
    grep -q " /external_sd " /proc/mounts && SD_MOUNTED=1 && return 0
    mkdir -p /external_sd 2>/dev/null
    for dev in /dev/block/mmcblk1p1 /dev/block/mmcblk1; do
        for fs in vfat exfat ext4; do
            if mount -t "$fs" -o rw "$dev" /external_sd 2>/dev/null; then
                SD_MOUNTED=1
                return 0
            fi
        done
    done
    return 1
}

dump_pstore() {
    mount_cache || return 0
    {
        echo "===== pstore at $(date) ====="
        for f in /sys/fs/pstore/console-ramoops* /sys/fs/pstore/dmesg-ramoops*; do
            [ -f "$f" ] || continue
            echo "----- $f -----"
            cat "$f"
        done
    } > "$CACHE_PSTORE" 2>&1
    sync
}

echo "logdump: started $(date)" > "$OUT"
blink
dump_pstore

i=0
while true; do
    i=$((i + 1))
    {
        echo "===== tick $i $(date) ====="
        echo "----- dmesg -----"
        dmesg
        echo "----- logcat -----"
        logcat -d -v threadtime -t 500 2>/dev/null
        echo "----- mounts -----"
        cat /proc/mounts
        echo "----- by-name -----"
        ls -l /dev/block/by-name 2>/dev/null
    } > "$OUT" 2>&1

    if mount_cache; then
        cp "$OUT" "$CACHE_LOG" 2>/dev/null
        sync
    fi
    if mount_sd; then
        cp "$OUT" /external_sd/logdump.txt 2>/dev/null
        cp "$CACHE_PSTORE" /external_sd/pstore-last.txt 2>/dev/null
        sync
    fi
    sleep 5
done
