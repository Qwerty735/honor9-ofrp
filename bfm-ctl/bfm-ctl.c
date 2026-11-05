/*
 * Copyright (C) 2018 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Talks to the HiSilicon boot fail monitor (BFM) from recovery.
 *
 * Stock EMUI userspace reports its boot progress to /dev/hw_bfm: the stock
 * init calls bfmr_set_boot_stage() and finally marks the boot as successful.
 * TWRP/OrangeFox does neither, so the device stays in "boot not finished"
 * state for the whole recovery session.  On Kirin 960 a boot that is still
 * unfinished after ~60 seconds is treated as a boot failure by the platform
 * (BFM_BOOT_SUCCESS_TIME_IN_KENREL is 60s, and the BFM timer/ATF watchdog
 * eventually kicks in), which looks exactly like "splash, hang 60s, reboot".
 *
 * What we do, in this order (the driver rejects everything after the monitor
 * has been disabled, so the order matters):
 *
 *   1. read the timer state, its timeout and the current boot stage,
 *   2. report STAGE_BOOT_SUCCESS (0x7FFFFFFF) - this stops the boot timer,
 *      notifies BFR and lets the platform record a successful boot,
 *   3. disable the monitor completely with BFMR_ENABLE_CTRL(0).
 *
 * Every step is written to /dev/kmsg: init sends service stdout to /dev/null,
 * but kmsg ends up in dmesg/pstore and survives the next reboot.
 */

#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <sys/types.h>
#include <unistd.h>

#define BFMR_DEVICE "/dev/hw_bfm"
#define BFMR_SYSFS_DEV "/sys/class/misc/hw_bfm/dev"

#define BFMR_IOCTL_BASE 'B'
#define BFMR_GET_TIMER_STATUS _IOR(BFMR_IOCTL_BASE, 1, int)
#define BFMR_GET_TIMER_TIMEOUT_VALUE _IOR(BFMR_IOCTL_BASE, 4, int)
#define BFMR_GET_BOOT_STAGE _IOR(BFMR_IOCTL_BASE, 6, int)
#define BFMR_SET_BOOT_STAGE _IOW(BFMR_IOCTL_BASE, 7, int)
#define BFMR_ENABLE_CTRL _IOW(BFMR_IOCTL_BASE, 10, int)

/* include/chipset_common/bfmr/public/bfmr_public.h */
#define STAGE_BOOT_SUCCESS 0x7FFFFFFF

static void klog(const char *fmt, ...) {
    char buf[512];
    va_list ap;
    int fd, len;

    va_start(ap, fmt);
    len = vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    if (len <= 0) return;
    if (len > (int)sizeof(buf) - 1) len = sizeof(buf) - 1;

    fd = open("/dev/kmsg", O_WRONLY);
    if (fd < 0) return;
    write(fd, buf, len);
    close(fd);
}

/* Kernel ueventd should create the node, but Huawei's own init creates it by
 * hand from sysfs, so do the same if it is missing. */
static void ensure_device_node(void) {
    char buf[64];
    int fd, len, major, minor;

    if (access(BFMR_DEVICE, F_OK) == 0) return;

    fd = open(BFMR_SYSFS_DEV, O_RDONLY);
    if (fd < 0) {
        klog("bfm-ctl: no %s (%s) and %s missing, BFM driver not present\n",
             BFMR_DEVICE, strerror(errno), BFMR_SYSFS_DEV);
        return;
    }
    len = read(fd, buf, sizeof(buf) - 1);
    close(fd);
    if (len <= 0) {
        klog("bfm-ctl: cannot read %s\n", BFMR_SYSFS_DEV);
        return;
    }
    buf[len] = '\0';
    if (sscanf(buf, "%d:%d", &major, &minor) != 2) {
        klog("bfm-ctl: unexpected %s content '%s'\n", BFMR_SYSFS_DEV, buf);
        return;
    }
    if (mknod(BFMR_DEVICE, S_IFCHR | 0600, makedev(major, minor)) != 0) {
        klog("bfm-ctl: mknod %s (%d:%d) failed: %s\n", BFMR_DEVICE, major,
             minor, strerror(errno));
        return;
    }
    klog("bfm-ctl: created %s (%d:%d)\n", BFMR_DEVICE, major, minor);
}

static int do_ioctl(int fd, unsigned long cmd, int *value, const char *name) {
    int ret = ioctl(fd, cmd, value);
    if (ret != 0) {
        klog("bfm-ctl: %s failed: %s\n", name, strerror(errno));
        return -1;
    }
    klog("bfm-ctl: %s -> 0x%08x (%d)\n", name, (unsigned)*value, *value);
    return 0;
}

int main(void) {
    int fd, ret = 0;
    int value = 0;

    klog("bfm-ctl: starting, uid=%d\n", getuid());

    ensure_device_node();

    if ((fd = open(BFMR_DEVICE, O_RDWR)) == -1) {
        klog("bfm-ctl: unable to open " BFMR_DEVICE ": %s\n", strerror(errno));
        return -1;
    }
    klog("bfm-ctl: opened " BFMR_DEVICE "\n");

    /* Report state before touching anything. The driver refuses all ioctls
     * once the monitor has been disabled, so these must come first. */
    do_ioctl(fd, BFMR_GET_TIMER_STATUS, &value, "BFMR_GET_TIMER_STATUS");
    value = 0;
    do_ioctl(fd, BFMR_GET_TIMER_TIMEOUT_VALUE, &value,
             "BFMR_GET_TIMER_TIMEOUT_VALUE(ms)");
    value = 0;
    do_ioctl(fd, BFMR_GET_BOOT_STAGE, &value, "BFMR_GET_BOOT_STAGE");

    /* This is what stock init does when the boot has finished. */
    value = STAGE_BOOT_SUCCESS;
    if (do_ioctl(fd, BFMR_SET_BOOT_STAGE, &value,
                 "BFMR_SET_BOOT_STAGE(STAGE_BOOT_SUCCESS)") != 0) {
        ret = -1;
    }

    /* Then stop the monitor itself. */
    value = 0;
    if (do_ioctl(fd, BFMR_ENABLE_CTRL, &value, "BFMR_ENABLE_CTRL(0)") != 0) {
        ret = -1;
    }

    close(fd);

    if (ret == 0) {
        klog("bfm-ctl: boot reported successful, BFM disabled\n");
    } else {
        klog("bfm-ctl: finished with errors\n");
    }
    return ret;
}
