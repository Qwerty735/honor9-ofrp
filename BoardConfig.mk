#
# Copyright (C) 2026 The OrangeFox Recovery Project
# SPDX-License-Identifier: Apache-2.0
#
# Based on Iceows android_device_huawei_stanford (Lineage 20) and
# Iceows/hisi-oss hi3660-common: Honor 9 (STF), Kirin 960, EMUI 9.1 / LeaOS.
#

DEVICE_PATH := device/huawei/stanford

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a73

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a73

ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

# Bootloader / platform
TARGET_BOOTLOADER_BOARD_NAME := hi3660
TARGET_NO_BOOTLOADER := true
TARGET_BOARD_PLATFORM := hi3660

# Kernel (stock recovery_ramdisk has kernel_size=0; kernel lives in the kernel partition)
BOARD_KERNEL_BASE := 0x00078000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_IMAGE_NAME := Image.gz
BOARD_BOOT_HEADER_VERSION := 0
BOARD_KERNEL_CMDLINE := loglevel=4 initcall_debug=n page_tracker=on slub_min_objects=16 unmovable_isolate1=2:192M,3:224M,4:256M printktimer=0xfff0a000,0x534,0x538
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
# Honor 9 keeps the dynamic-partition (super) metadata on the "system"
# partition; TWRP resolves it through ro.boot.super_partition, so without this
# all logical partitions (system/vendor/product/...) get dropped at boot.
BOARD_KERNEL_CMDLINE += androidboot.super_partition=system
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_KERNEL_TAGS_OFFSET := 0x07988000
BOARD_RAMDISK_OFFSET := 0x07b88000
BOARD_SECOND_OFFSET := 0x00e88000
BOARD_MKBOOTIMG_ARGS := --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --second_offset $(BOARD_SECOND_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

# Android 10+ dropped BOARD_CUSTOM_BOOTIMG_MK, so use the supported flag to
# build recovery without a kernel at all (mkbootimg gets no --kernel).
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
# Still needed so nothing tries to compile a kernel from source.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/dummykernel

# Display
TARGET_SCREEN_DENSITY := 420
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 1920

# Filesystems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor

# Partitions (from Iceows hi3660-common)
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 25165824
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432
BOARD_RECVENDORIMAGE_PARTITION_SIZE := 16777216
BOARD_CACHEIMAGE_PARTITION_SIZE := 134217728
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4

# Dynamic partitions (LeaOS / Iceows converted layout)
BOARD_SUPER_PARTITION_SIZE := 6299844608
BOARD_SUPER_PARTITION_GROUPS := huawei_dynamic_partitions
BOARD_HUAWEI_DYNAMIC_PARTITIONS_PARTITION_LIST := odm product system system_ext vendor
BOARD_HUAWEI_DYNAMIC_PARTITIONS_SIZE := 6295650304
BOARD_USES_METADATA_PARTITION := true
TW_INCLUDE_LOGICAL := system system_ext vendor product odm

# Recovery
BOARD_HAS_NO_SELECT_BUTTON := true
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_USES_FULL_RECOVERY_IMAGE := false
TARGET_RECOVERY_PIXEL_FORMAT := RGB565
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab
RECOVERY_SDCARD_ON_DATA := true

# Decryption
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 1
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 16.1.0
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)

# TWRP
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := true
TW_DEFAULT_LANGUAGE := en
TW_USE_TOOLBOX := true
TW_INCLUDE_NTFS_3G := true
TW_INCLUDE_FUSE_EXFAT := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_FASTBOOTD := true
TW_EXCLUDE_APEX := true
TW_EXCLUDE_TWRPAPP := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
# NOTE: TW_EXCLUDE_MTP must stay unset. OrangeFox 12.1's partitionmanager.cpp
# uses AID_MEDIA_RW but only gets <private/android_filesystem_config.h>
# transitively through the MTP headers, so excluding MTP breaks the build.
TW_NO_HAPTICS := true
TW_NO_SCREEN_BLANK := true
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd_backlight0/brightness
TW_MAX_BRIGHTNESS := 7992
TW_DEFAULT_BRIGHTNESS := 1573
TW_CUSTOM_BATTERY_PATH := /sys/class/power_supply/Battery
# %d is required: TWRP does sprintf(lun_file, CUSTOM_LUN_FILE, index).
TARGET_USE_CUSTOM_LUN_FILE_PATH := /config/usb_gadget/g1/functions/mass_storage.0/lun.%d/file
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
TW_DEVICE_VERSION := Honor9-STF
ALLOW_MISSING_DEPENDENCIES := true
SELINUX_IGNORE_NEVERALLOWS := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_DUP_RULES := true
