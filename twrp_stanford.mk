#
# Copyright (C) 2026 The OrangeFox Recovery Project
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, device/huawei/stanford/device.mk)

PRODUCT_DEVICE := stanford
PRODUCT_NAME := twrp_stanford
PRODUCT_BRAND := HONOR
PRODUCT_MODEL := STF-L09
PRODUCT_MANUFACTURER := HUAWEI
PRODUCT_GMS_CLIENTID_BASE := android-huawei
