#
# OrangeFox build variables for Honor 9 (stanford / STF-L09)
# FOX_* flags must live in a shell script, not BoardConfig.mk
#

FDEVICE="stanford"

fox_get_target_device() {
    if echo "$BASH_SOURCE" | grep -q "/$FDEVICE/"; then
        FOX_BUILD_DEVICE="$FDEVICE"
    elif echo "${BASH_SOURCE[0]}" | grep -q "/$FDEVICE/"; then
        FOX_BUILD_DEVICE="$FDEVICE"
    elif echo "$0" | grep -q "$FDEVICE"; then
        FOX_BUILD_DEVICE="$FDEVICE"
    fi
}

if [ -z "$1" ] && [ -z "$FOX_BUILD_DEVICE" ]; then
    fox_get_target_device
fi

if [ "$1" = "$FDEVICE" ] || [ "$FOX_BUILD_DEVICE" = "$FDEVICE" ]; then
    export FOX_BUILD_DEVICE="$FDEVICE"
    export FOX_VARIANT="Huawei"
    export FOX_MAINTAINER_PATCH_VERSION="1"
    export OF_MAINTAINER="Qwerty735"
    export FOX_BUILD_TYPE="Official"
    export FOX_VANILLA_BUILD=1
    export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1
    export OF_FORCE_PREBUILT_KERNEL=1
    export OF_NO_TREBLE_COMPATIBILITY_CHECK=1
    export OF_DONT_PATCH_ENCRYPTED_DEVICE=1
    export OF_NO_REFLASH_CURRENT_ORANGEFOX=1
    export OF_PATCH_AVB20=0
    export OF_USE_MAGISKBOOT=1
    export OF_USE_MAGISKBOOT_FOR_ALL_PATCHES=1
    export OF_DEFAULT_KEYMASTER_VERSION=3.0
    export OF_SCREEN_H=1920
    export OF_STATUS_H=80
    export OF_STATUS_INDENT_LEFT=48
    export OF_STATUS_INDENT_RIGHT=48
    export OF_CLOCK_POS=1
    export OF_ALLOW_DISABLE_NAVBAR=1
    export OF_HIDE_NOTCH=0
    export FOX_DELETE_AROMAFM=1
    export FOX_USE_BASH_SHELL=1
    export FOX_ASH_IS_BASH=1
    export FOX_USE_TAR_BINARY=1
    export FOX_USE_SED_BINARY=1
    export FOX_USE_XZ_UTILS=1
    export FOX_USE_NANO_EDITOR=1
    export FOX_REPLACE_BUSYBOX_PS=1
    export FOX_REPLACE_TOOLBOX_GETPROP=1
    export FOX_RECOVERY_INSTALL_PARTITION="/dev/block/by-name/recovery_ramdisk"
    export FOX_RECOVERY_SYSTEM_PARTITION="/dev/block/mapper/system"
    export FOX_RECOVERY_VENDOR_PARTITION="/dev/block/mapper/vendor"
    export OF_FL_PATH1="/sys/class/leds/torch"
    export LC_ALL="C"
    export ALLOW_MISSING_DEPENDENCIES=true
    export OF_DISABLE_EXTRA_ABOUT_PAGE=0
else
    if [ -z "$FOX_BUILD_DEVICE" ] && [ -z "$BASH_SOURCE" ]; then
        echo "I: vendorsetup.sh for $FDEVICE requires bash"
    fi
fi
