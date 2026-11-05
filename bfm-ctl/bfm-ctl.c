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
 * Disables the HiSilicon boot fail monitor (BFM). The stock Huawei init and
 * recovery keep talking to /dev/hw_bfm and the bootloader records boot
 * attempts in the bootfail_info partition; a userspace that never reports a
 * successful boot can make the bootloader (or the BFM timer) reboot the
 * device. LineageOS ships this helper for hi3660/hi6250/hi970 and starts it
 * from init with flag 0, so recovery does the same.
 *
 * init sends service stdout to /dev/null, so the results are written straight
 * to the kernel log. They end up in dmesg/pstore and therefore survive the
 * bootloop, which tells us whether BFM was actually the thing rebooting us.
 */

#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define BFMR_DEVICE "/dev/hw_bfm"

#define BFMR_IOCTL_BASE 'B'
#define BFMR_ENABLE_CTRL _IOW(BFMR_IOCTL_BASE, 10, int)

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

int main() {
    int enable = 0;
    int fd, ret;

    klog("bfm-ctl: starting, uid=%d\n", getuid());

    if ((fd = open(BFMR_DEVICE, O_RDONLY)) == -1) {
        klog("bfm-ctl: unable to open " BFMR_DEVICE ": %s\n", strerror(errno));
        return -1;
    }
    klog("bfm-ctl: opened " BFMR_DEVICE "\n");

    ret = ioctl(fd, BFMR_ENABLE_CTRL, &enable);
    if (ret != 0) {
        klog("bfm-ctl: BFMR_ENABLE_CTRL(0) failed: %s\n", strerror(errno));
        close(fd);
        return -1;
    }
    klog("bfm-ctl: BFM disabled (ioctl returned %d)\n", ret);
    close(fd);
    return 0;
}
