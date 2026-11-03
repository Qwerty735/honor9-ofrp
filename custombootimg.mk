#
# Huawei recovery_ramdisk: ANDROID! header v0, kernel_size=0, gzip ramdisk.
# Flash the result to recovery_ramdisk:
#   fastboot flash recovery_ramdisk recovery.img
#

$(INSTALLED_RECOVERYIMAGE_TARGET): $(MKBOOTIMG) $(recovery_ramdisk) $(MKBOOTFS) $(MINIGZIP)
	@echo ----- Removing modprobe symlink -----
	rm -f $(TARGET_RECOVERY_ROOT_OUT)/sbin/modprobe
	@echo ----- Compressing recovery ramdisk ------
	$(hide) $(MKBOOTFS) -d $(TARGET_OUT) $(TARGET_RECOVERY_ROOT_OUT) | $(MINIGZIP) > $(recovery_ramdisk)
	@echo ----- Making Huawei recovery_ramdisk image ------
	$(MKBOOTIMG) \
		--kernel /dev/null \
		--ramdisk $(recovery_ramdisk) \
		--cmdline "buildvariant=$(TARGET_BUILD_VARIANT)" \
		--base $(BOARD_KERNEL_BASE) \
		--pagesize $(BOARD_KERNEL_PAGESIZE) \
		--kernel_offset $(BOARD_KERNEL_OFFSET) \
		--ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
		--tags_offset $(BOARD_KERNEL_TAGS_OFFSET) \
		--second_offset $(BOARD_SECOND_OFFSET) \
		--header_version 0 \
		--output $@
	@echo ----- Made recovery image -------- $@
	$(hide) $(call assert-max-image-size,$@,$(BOARD_RECOVERYIMAGE_PARTITION_SIZE),raw)
