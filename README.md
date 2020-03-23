# fossbot-pkg

This is a complete fossbot package repo

# How to

## Use git submodules

https://git-scm.com/book/en/v2/Git-Tools-Submodules

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

## Build kernel

Patch kernel with [this](https://git.kernel.org/pub/scm/linux/kernel/git/linusw/linux-pinctrl.git) or use pre-patched kernel from [here](https://gitlab.com/GuzTech/linux_socfpga).

Create default configuration, then run ```make ARCH=arm menuconfig```

In ```General setup``` uncheck ```Automatically append version information to the version string``` for convenience. In ```Enable the block layer``` check ```Support for large (2TB+) block devices and files```. If you want to use bluetooth, check all bluetooth-related options (you will probably need to check ```HID drivers``` and enable ```User-space I/O driver support for HID subsystem```.

Example ```.config``` can be found in ```/kernel```

Run ```make ARCH=arm LOCALVERSION= zImage``` to build kernel.

## Build kernel modules

This will produce kernel object file(s) that can be ```insmod```ed:

```shell
cd kmod
# Change KDIR path to match your kernel root directory in Makefile, then run
make
```

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

# At this point you can copy anything you need, for example scripts and built kernel modules

unmount rootfs

losetup -d $DEV
```

## Configure system

You may want to first configure SSH and network for convenience.

Assuming Debian 10:

Copy or clone contents of this repo, for example to ```/root```.

### In ```/etc/systemd/system/```:

In ```dbus-org.bluez.service``` add ```--compat``` to ```ExecStart``` arguments.

Add ```reset-usb.service``` with the following content and modified paths if needed:

```
[Unit]
Description=Reset USB service
Before=bluetooth.service

[Service]
ExecStart=/root/scripts/reset-usb.sh

[Install]
WantedBy=multi-user.target
```

Add ```rfcomm-server.service``` with the following content and modified paths if needed:

```
[Unit]
Description=RFCOMM Server Setup
After=bluetooth.service
Requires=bluetooth.service

[Service]
ExecStart=/root/scripts/rfcomm-server.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Execute

```
systemctl enable reset-usb.service
systemctl enable rfcomm-server.service
```

### Kernel modules

You may want to load kernel modules on boot. A simple way to do this is to create a file ```yourmodule.conf``` in ```/lib/modprobe.d``` with the following content: ```install yourmodule insmod /path/to/yourmodule.ko```.
