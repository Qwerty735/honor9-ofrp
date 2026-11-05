#!/system/bin/sh
#
# Honor 9 (stanford) recovery diagnostics.
#
# The device bootloops roughly a minute after the OrangeFox splash is drawn,
# which is too early for a normal TWRP log to be saved. This loop keeps a
# dmesg/logcat/recovery.log snapshot on the cache partition, on the microSD
# card and in the kernel log (Huawei's BFM saves dmesg to pstore, so the data
# can be read from the stock ROM after a failed boot).
#
# Run by init as:  /system/bin/sh /system/bin/logdump.sh
#

OUT=/tmp/logdump.txt
SUM=/tmp/logdump-summary.txt
CACHE_LOG=/cache/logdump.txt
CACHE_SUM=/cache/logdump-summary.txt
CACHE_REC=/cache/recovery-last.log
CACHE_PSTORE=/cache/pstore-last.txt

CACHE_MOUNTED=0
SD_MOUNTED=0
BL=/sys/class/leds/lcd_backlight0/brightness
KMSG=/dev/kmsg

# Lines worth reading when the device reboots before anything can be pulled.
# Kept separate from the full dump so the interesting part fits in a chat
# message.
FILTER='critical|powerctl|exited|crash|reboot|Reboot|rebooting|on-failure|FATAL|fatal|watchdog|ueventd|charger|keystore|boot_completed|coldboot|cold_boot|Service '

kmsg() {
    [ -w "$KMSG" ] || return 0
    echo "OFRP-DIAG: $*" > "$KMSG" 2>/dev/null
}

# Visible "userspace is alive" signal. The first blink happens very early,
# before the panel is usually powered up, so it may not be visible; the one
# that matters is issued as soon as TWRP creates /tmp/recovery.log.
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

# Mirror the summary and TWRP's own log into the kernel log, but only when
# they changed, so the ring buffer does not get flooded.
emit_kmsg() {
    [ -w "$KMSG" ] || return 0
    if ! cmp -s "$SUM" /tmp/logdump-summary.prev 2>/dev/null; then
        cp "$SUM" /tmp/logdump-summary.prev 2>/dev/null
        kmsg "tick $i summary begins"
        tail -n 50 "$SUM" 2>/dev/null | while IFS= read -r l; do
            kmsg "$l"
        done
        kmsg "tick $i summary ends"
    fi
    if [ -s /tmp/recovery.log ] && ! cmp -s /tmp/recovery.log /tmp/recovery-prev.log 2>/dev/null; then
        cp /tmp/recovery.log /tmp/recovery-prev.log 2>/dev/null
        kmsg "tick $i recovery.log tail begins"
        tail -n 80 /tmp/recovery.log 2>/dev/null | while IFS= read -r l; do
            kmsg "$l"
        done
        kmsg "tick $i recovery.log tail ends"
    fi
}

echo "logdump: started $(date)" > "$OUT"
# dmesg still shows "avc: denied ... permissive=0" at ~60 s, so the bootloader
# is not applying androidboot.selinux=permissive. Force it from here, before
# anything else: an enforcing recovery policy is a plausible reason for
# ueventd to die repeatedly (and init reboots when that happens).
setenforce 0 2>/dev/null
kmsg "logdump script started, uptime=$(cat /proc/uptime) enforce=$(cat /sys/fs/selinux/enforce 2>/dev/null)"
blink
dump_pstore

i=0
BLINKED_LOG=0
while true; do
    i=$((i + 1))
    {
        echo "===== tick $i $(date) uptime=$(cat /proc/uptime) ====="
        echo "----- dmesg -----"
        dmesg
        echo "----- logcat (all buffers) -----"
        logcat -b all -d -v threadtime 2>/dev/null
        echo "----- init service state -----"
        getprop | grep -E '^\[(init\.svc|sys\.boot_completed|ro\.cold_boot_done|ro\.hardware|sys\.usb)'
        echo "----- ps -----"
        ps -A 2>/dev/null
        echo "----- mounts -----"
        cat /proc/mounts
        echo "----- by-name -----"
        ls -l /dev/block/by-name 2>/dev/null
        echo "----- hw_bfm -----"
        ls -l /dev/hw_bfm 2>/dev/null
        echo "----- selinux -----"
        cat /sys/fs/selinux/enforce 2>/dev/null
        echo "----- backlight -----"
        ls -l /sys/class/leds 2>/dev/null
    } > "$OUT" 2>&1

    # Small, pasteable digest: service states plus every line that can explain
    # a reboot. Our own markers and the AVC flood are removed (the latter is
    # summarised separately). No tick number or uptime here, otherwise the
    # digest would "change" on every pass and flood /dev/kmsg.
    {
        echo "----- summary -----"
        echo "----- init service state -----"
        getprop | grep -E '^\[(init\.svc|sys\.boot_completed|ro\.cold_boot_done|ro\.hardware|sys\.usb)'
        echo "----- reboot-related lines -----"
        grep -Ei "$FILTER" "$OUT" 2>/dev/null | grep -v 'OFRP-DIAG:' | grep -v 'avc: denied'
        echo "----- avc denials (unique) -----"
        grep 'avc: denied' "$OUT" 2>/dev/null | sed 's/.*avc: denied/avc: denied/' \
            | sort -u | head -n 20
    } > "$SUM"
    emit_kmsg

    # Visible confirmation once TWRP itself is running.
    if [ "$BLINKED_LOG" = "0" ] && [ -s /tmp/recovery.log ]; then
        BLINKED_LOG=1
        kmsg "recovery.log exists (size $(wc -c < /tmp/recovery.log)) - blinking"
        blink
    fi

    # Keep SELinux permissive for the whole session, whatever TWRP does.
    [ "$(cat /sys/fs/selinux/enforce 2>/dev/null)" = "1" ] && setenforce 0 2>/dev/null

    if mount_cache; then
        cp "$OUT" "$CACHE_LOG" 2>/dev/null
        cp "$SUM" "$CACHE_SUM" 2>/dev/null
        # TWRP's own log is the only place that shows *which* userspace code
        # asked for a reboot (e.g. via sys.powerctl), so keep its last state.
        cp /tmp/recovery.log "$CACHE_REC" 2>/dev/null
        sync
    fi
    if mount_sd; then
        cp "$OUT" /external_sd/logdump.txt 2>/dev/null
        cp "$SUM" /external_sd/logdump-summary.txt 2>/dev/null
        cp /tmp/recovery.log /external_sd/recovery-last.log 2>/dev/null
        cp "$CACHE_PSTORE" /external_sd/pstore-last.txt 2>/dev/null
        sync
    fi
    sleep 3
done
