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
