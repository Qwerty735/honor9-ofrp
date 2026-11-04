# OrangeFox 12.1 device tree — Honor 9 (stanford / STF)

Converted from [Iceows/android_device_huawei_stanford](https://github.com/Iceows/android_device_huawei_stanford) (Lineage 20 / LeaOS) into a standalone recovery tree for **OrangeFox fox_12.1**.

| | |
|---|---|
| Device | Honor 9 |
| Codename | `stanford` |
| Model | STF-L09 |
| SoC | Kirin 960 (`hi3660`) |
| Layout | A-only, Huawei `recovery_ramdisk` (no kernel in recovery.img) |
| ROM target | Iceows LeaOS-style dynamic partitions |

Huawei puts the kernel in the `kernel` partition. The recovery image is header v0 with `kernel_size=0` and a gzip ramdisk. Flash it to `recovery_ramdisk`, not `recovery`.

The header must match the stock EMUI `recovery_ramdisk` (verified against a stock dump):

| field | value |
|---|---|
| `kernel_addr` | `0x10008000` |
| `ramdisk_addr` | `0x11000000` |
| `second_addr` | `0x10f00000` (`0` is accepted, `second_size=0`) |
| `tags_addr` | `0x10000100` |
| `page_size` | `2048` |
| `header_version` | `0` |
| `os_version` | `0x12000137` (Android 9.0.0, patch 2019-07) |
| `cmdline` | `... androidboot.selinux=permissive androidboot.super_partition=system buildvariant=user` |

`BOARD_KERNEL_BASE := 0x10000000` plus offsets `0x8000` / `0x01000000` / `0x00f00000` / `0x00000100`.
Note that AOSP 12.1's `recoveryimage` target passes neither `--kernel` nor `--cmdline`
to `mkbootimg`, so the cmdline has to be added through `BOARD_MKBOOTIMG_ARGS`.
The CI job asserts all of the above.

`BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true` is what makes `mkbootimg` skip `--kernel`
entirely. The old `BOARD_CUSTOM_BOOTIMG_MK` hook used by Android 9 trees no longer exists in
AOSP 12.1, so `custombootimg.mk` was dropped; `prebuilt/dummykernel` stays only to keep the
build system from trying to compile a kernel from source.

## fox_12.1 notes

* `recovery/root` is **not** copied automatically. `TARGET_RECOVERY_DEVICE_DIRS` is dead in
  AOSP 12.1, so every file in that directory has to be installed through `PRODUCT_COPY_FILES`
  in `device.mk`.
* USB uses configfs (`sys.usb.configfs=1`, controller `ff100000.dwc3`). OrangeFox's own
  `init.rc` creates the gadget for adb/fastboot/sideload only; `recovery/root/init.recovery.hi3660.rc`
  adds Huawei's `mtp.gs0` (`/dev/mtp_usb`) and `mass_storage.0` functions, the `mtp,adb` /
  `mass_storage,adb` triggers and the `port_mode` writes the Huawei USB switch needs.
* TWRP resolves dynamic partitions through `ro.boot.super_partition`. On the Honor 9 the
  super metadata lives on the `system` partition, hence
  `androidboot.super_partition=system` in `BOARD_KERNEL_CMDLINE`.

## Sync fox_12.1 (Linux)

```bash
mkdir -p ~/OrangeFox_sync && cd ~/OrangeFox_sync
git clone https://gitlab.com/OrangeFox/sync.git
cd sync
./orangefox_sync.sh --branch 12.1 --path ~/fox_12.1
```

Place this tree at `~/fox_12.1/device/huawei/stanford`.

## Build

```bash
cd ~/fox_12.1
export ALLOW_MISSING_DEPENDENCIES=true
export LC_ALL=C
export FOX_BUILD_DEVICE=stanford
source build/envsetup.sh
lunch twrp_stanford-eng
mka adbd recoveryimage -j$(nproc)
```

Output: `out/target/product/stanford/OrangeFox-unofficial-stanford.img` (and a zip if packaging succeeds).

## Flash (unlocked bootloader)

```bash
fastboot flash recovery_ramdisk recovery.img
fastboot reboot recovery
```

Optional vendor ramdisk is **not** required for this tree; stock `recovery_vendor` can stay.

Windows cannot compile AOSP/OFRP. Use Linux, WSL2 with ~50GB+ free, or the GitHub Actions workflow in `.github/workflows/build-ofrp.yml`.
