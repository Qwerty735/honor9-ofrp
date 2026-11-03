#
# Copyright (C) 2026 The OrangeFox Recovery Project
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/huawei/stanford

PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_SHIPPING_API_LEVEL := 28

PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.0-impl-mock \
    android.hardware.fastboot@1.0-impl-mock.recovery \
    fastbootd

PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# NOTE: TARGET_RECOVERY_DEVICE_DIRS is a dead variable in AOSP 12.1 (build only
# copies TARGET_PRIVATE_RES_DIRS), so files under recovery/root have to be
# installed explicitly. Anything added there must be listed below.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keylayout/fingerprint.kl:$(TARGET_COPY_OUT_RECOVERY)/root/system/usr/keylayout/fingerprint.kl \
    $(LOCAL_PATH)/keylayout/touch_key.kl:$(TARGET_COPY_OUT_RECOVERY)/root/system/usr/keylayout/touch_key.kl \
    $(LOCAL_PATH)/recovery/root/init.recovery.hi3660.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.hi3660.rc \
    $(LOCAL_PATH)/recovery/root/system/etc/twrp.flags:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/twrp.flags
