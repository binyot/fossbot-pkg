# fossbot-pkg

This is a complete fossbot package repo

# How to

## Get cross-compiler

Download latest [Linaro GCC](https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-linux-gnueabihf/)

Example:
```
LINARO=gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf
wget https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-linux-gnueabihf/"$LINARO".tar.xz
tar -xf "$LINARO".tar.xz

export CROSS_COMPILE=$PWD/"$LINARO"/bin/arm-linux-gnueabihf-
```

## Get rootfs

Get any debian-based built for arm half-precision target.

[For example, here](https://rcn-ee.com/rootfs/eewiki/minfs/)

## Build disk image

```shell
# Create file
DISKFILE=disk.img
fallocate -l 4G $DISKFILE
DEV=$(losetup -f --show $DISKFILE)

# Partition
fdisk $DEV
# in fdisk:
	n
	p
	3
	<Return>
	+1M
	t
	a2
	n
	p
	2
	<Return>
	+256M
	n
	p
	1
	<Return>
	<Return>
	t
	1
	b
	w
	
# partition table should look like this:
# Device       Boot  Start     End Sectors  # Size Id Type
# /dev/loop0p1      528384 8388607 7860224  # 3.8G  b W95 FAT32
# /dev/loop0p2        4096  528383  524288  # 256M 83 Linux
# /dev/loop0p3        2048    4095    2048    # 1M a2 unknown

partprobe $DEV

# Format
mkfs -t vfat "$DEV"p1
mkfs.ext4 "$DEV"p2

# Copy preloader
PRELOADER=preloader-mkpimage.bin
cp $PRELOADER "$DEV"p3

# Copy fpga rom, device treem kernel and boot stuff
mkdir boot
mount "$DEV"p1 boot
UBOOT_IMG=u-boot.img
UBOOT_SCR=u-boot.scr
DEV_TREE=soc_system.dtb
FPGA_ROM=soc_system.rbf
KERNEL=zImage
cp UBOOT_IMG UBOOT_SCR DEV_TREE FPGA_ROM KERNEL boot && sync
unmount boot

# Copy rootfs
mkdir rootfs
mount "$DEV"p2 rootfs
ROOTFS=debian.tar
tar -xf ROOTFS -C rootfs && sync
unmount rootfs

losetup -d $DEV
```
