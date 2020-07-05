LINARO=gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf
wget https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-linux-gnueabihf/"$LINARO".tar.xz
tar -xf "$LINARO".tar.xz

CROSS_COMPILE=$PWD/"$LINARO"/bin/arm-linux-gnueabihf-

ROOTFS=debian-10.4-minimal-armel-2020-05-10
wget https://rcn-ee.com/rootfs/eewiki/minfs/"$ROOTFS".tar.xz

cd kmod; make; cd ..

DISKFILE=disk.img
fallocate -l 4G $DISKFILE
DEV=$(losetup -f --show $DISKFILE)

(
    echo n
	echo p
	echo 3
	echo
	echo +1M
	echo t
	echo a2
	echo n
	echo p
	echo 2
	echo
	echo +256M
	echo n
	echo p
	echo 1
	echo
	echo t
	echo 1
	echo b
	echo w
) | fdisk $DEV

partprobe $DEV
mkfs -t vfat "$DEV"p1
mkfs.ext4 "$DEV"p2

PRELOADER=preloader-mkpimage.bin
cp $PRELOADER "$DEV"p3

mkdir boot
mount "$DEV"p1 boot
UBOOT_IMG=u-boot.img
UBOOT_SCR=u-boot.scr
DEV_TREE=soc_system.dtb
FPGA_ROM=soc_system.rbf
KERNEL=zImage
cp UBOOT_IMG UBOOT_SCR DEV_TREE FPGA_ROM KERNEL boot && sync
unmount boot

mkdir rootfs
mount "$DEV"p2 rootfs
ROOTFS=debian.tar
tar -xf ROOTFS -C rootfs && sync

unmount rootfs
losetup -d $DEV
