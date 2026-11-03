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

TARGET_RECOVERY_DEVICE_DIRS += $(LOCAL_PATH)/recovery
PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keylayout/fingerprint.kl:$(TARGET_COPY_OUT_RECOVERY)/root/system/usr/keylayout/fingerprint.kl \
    $(LOCAL_PATH)/keylayout/touch_key.kl:$(TARGET_COPY_OUT_RECOVERY)/root/system/usr/keylayout/touch_key.kl
