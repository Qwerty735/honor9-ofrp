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
 */

#include <fcntl.h>
#include <stdio.h>
#include <sys/ioctl.h>

#define BFMR_DEVICE "/dev/hw_bfm"

#define BFMR_IOCTL_BASE 'B'
#define BFMR_ENABLE_CTRL _IOW(BFMR_IOCTL_BASE, 10, int)

int main() {
    int enable = 0;
    int fd;

    if ((fd = open(BFMR_DEVICE, O_RDONLY)) == -1) {
        puts("Unable to open " BFMR_DEVICE "!");
        return -1;
    }

    if (ioctl(fd, BFMR_ENABLE_CTRL, &enable) != 0) {
        puts("BFMR_ENABLE_CTRL ioctl failed!");
        return -1;
    }

    puts("BFM disabled");
    return 0;
}
