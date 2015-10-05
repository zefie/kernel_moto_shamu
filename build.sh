#!/bin/bash

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j10"
KERNEL="zImage-dtb"
DEFCONFIG="benzo_defconfig"

# Kernel Details
BC="benzoCore"
VER="M2"
BC_VER=$BC-$VER

# Vars
export USE_CCACHE=1
export LOCALVERSION=-`echo $VER`
export ARCH=arm
export SUBARCH=arm
export KBUILD_BUILD_USER=xanaxdroid
export KBUILD_BUILD_HOST=benzo
CROSS_COMPILE=../arm-eabi-6.0/bin/arm-eabi-

if [ "$USE_CCACHE" = 1 ]; then
   export CROSS_COMPILE="ccache $CROSS_COMPILE"
else
   export CROSS_COMPILE="$CROSS_COMPILE"
fi

# Paths
KERNEL_DIR=`pwd`
REPACK_DIR="$KERNEL_DIR/zip/bCzip"
ZIP_MOVE="$KERNEL_DIR/zip/"
ZIMAGE_DIR="$KERNEL_DIR/arch/arm/boot"

# Functions
function clean_all {
		rm -rf $REPACK_DIR/kernel/zImage
		rm -rf $ZIMAGE_DIR/$KERNEL
		make clean && make mrproper
}

function make_kernel {
		make $DEFCONFIG
		make $THREAD
		cp -vr $ZIMAGE_DIR/$KERNEL ${KERNEL_DIR}/zip/bCzip/kernel/zImage
}

function make_zip {
		cd $REPACK_DIR
		zip -9 -r `echo $BC_VER`.zip .
		mv  `echo $BC_VER`.zip $ZIP_MOVE
		cd $KERNEL_DIR
}

DATE_START=$(date +"%s")

echo -e "${green}"
echo "benzoCore Kernel Creation Script:"
echo

echo "---------------"
echo "Kernel Version:"
echo "---------------"

echo -e "${red}"; echo -e "${blink_red}"; echo "$BC_VER"; echo -e "${restore}";

echo -e "${green}"
echo "-----------------"
echo "Making benzoCore Kernel:"
echo "-----------------"
echo -e "${restore}"

while read -p "Please choose your option: [1]clean-build / [2]dirty-build / [3]abort " cchoice
do
case "$cchoice" in
	1 )
		echo -e "${green}"
		echo
		echo "[..........Cleaning up..........]"
		echo
		echo -e "${restore}"
		clean_all
		echo -e "${green}"
		echo
		echo "[....Building `echo $BC_VER`....]"
		echo
		echo -e "${restore}"
		make_kernel
		echo -e "${green}"
		echo
		echo "[....Make `echo $BC_VER`.zip....]"
		echo
		echo -e "${restore}"
		make_zip
		echo -e "${green}"
		echo
		echo "[.....Moving `echo $BC_VER`.....]"
		echo -e "${restore}"
		break
		;;
	2 )
		echo -e "${green}"
		echo
		echo "[....Building `echo $BC_VER`....]"
		echo
		echo -e "${restore}"
		make_kernel
		echo -e "${green}"
		echo
		echo "[....Make `echo $BC_VER`.zip....]"
		echo
		echo -e "${restore}"
		make_zip
		echo -e "${green}"
		echo
		echo "[.....Moving `echo $BC_VER`.....]"
		echo -e "${restore}"
		break
		;;
	3 )
		break
		;;
	* )
		echo -e "${red}"
		echo
		echo "Invalid try again!"
		echo
		echo -e "${restore}"
		;;
esac
done

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo

