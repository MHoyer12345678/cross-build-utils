#!/bin/bash

# ------------------------------------------------------- command line parsing --------------------------------------------
while getopts :ha: opt
do
    case $opt in
	h)
	    echo "knl_05-pack-kernel.sh [--help] [<destination path>]"
	    echo "    <destination path>: Path to the base path of the kernel package the kernel stuff is copied to"
	    echo "    --help,-h: Shows this help screen"
	    echo
	    exit 0
            ;;
	\?)
	    echo "Invalid options passed. Try -h to get help"
	    exit 1
	    ;;
    esac
done

shift "$((OPTIND-1))"

if [ "$1" != "" ]; then
    KNL_PKG_BASE_DIR_OVER=$1
fi

# path to created kernel image in linux tree 
KNL_IMAGE_PATH="arch/arm/boot/zImage"

# path to created dtbs in linux tree
KNL_DTBS_DIR="arch/arm/boot/dts"

# name of destination kernel image (image on sd card or where ever). Source image is renamed
# to this name while copied to the kernel package.
# use "kernel.img" for pi 1, zero, zero w
# use "kernel7.img" for pi 2,3,3+
# use "kernel7l.img" for pi 4
KNL_IMAGE_NAME_DST="kernel.img"

# the base dir of the kernel package everything is packed into
KNL_PKG_BASE_DIR="./kpkg"


# ------------------------------------------------------- sourcing configuration file ---------------------------------------
if [ "${KNL_SCRIPTS_CONF_FILE}" == "" ]; then
    KNL_SCRIPTS_CONF_FILE="./cross-kernel-tools.conf"
    echo "Variable KNL_SCRIPTS_CONF_FILE not set. Expecting to find: ${KNL_SCRIPTS_CONF_FILE}"
fi

echo "Using script configuration file: ${KNL_SCRIPTS_CONF_FILE}"
echo

source ${KNL_SCRIPTS_CONF_FILE} || exit 1

echo "Configuration:"
echo "--------------"
echo "Local kernel source tree path: ${KNL_LOCAL_SRC_PATH}"
if [ "${KNL_PKG_BASE_DIR_OVER}" != "" ]; then
    KNL_PKG_BASE_DIR=${KNL_PKG_BASE_DIR_OVER}
    echo "Kernel package base dir: ${KNL_PKG_BASE_DIR} (overwritten by cmd line option)"
else
    echo "Kernel package base dir: ${KNL_PKG_BASE_DIR}"
fi
echo "Kernel image source path: ${KNL_IMAGE_PATH}"
echo "Kernel device tree source dir: ${KNL_DTBS_DIR}"
echo "Kernel image destination name: ${KNL_IMAGE_NAME_DST}"


echo

# ------------------------------------------------------- executing commands --------------------------------------------
IMG_DIR="${KNL_PKG_BASE_DIR}/image"
DTBS_DIR="${KNL_PKG_BASE_DIR}/dtbs"
MODULES_TGZ="${KNL_PKG_BASE_DIR}/modules.tgz"

echo "Packing kernel stuff together ..."

if [ -d ${KNL_PKG_BASE_DIR} ]; then
   echo "Package $KNL_PKG_BASE_DIR} directory exists. Removing it in 5 secs. Press ctrl+c to abort."
   sleep 5
   rm -r ${KNL_PKG_BASE_DIR}
fi

echo "Creating kernel package directory ..."
mkdir -p ${KNL_PKG_BASE_DIR} || exit 1

echo "Copying image into package ..."
mkdir -p ${IMG_DIR} || exit 1
cp "${KNL_LOCAL_SRC_PATH}/${KNL_IMAGE_PATH}" "${IMG_DIR}/${KNL_IMAGE_NAME_DST}" || exit 1

echo "Copying dtbs into package ..."

mkdir -p "${DTBS_DIR}" || exit 1
cp ${KNL_LOCAL_SRC_PATH}/${KNL_DTBS_DIR}/*.dtb* ${DTBS_DIR} || exit 1

if [ -d ${KNL_LOCAL_SRC_PATH}/${KNL_DTBS_DIR}/overlays ]; then
    mkdir -p "${DTBS_DIR}/overlays" || exit 1
    cp ${KNL_LOCAL_SRC_PATH}/${KNL_DTBS_DIR}/overlays/*.dtb* ${DTBS_DIR}/overlays || exit 1
fi

echo "Copying modules into package ..."
dir=$PWD

cd ${KNL_LOCAL_SRC_PATH}
make INSTALL_MOD_PATH=${KNL_PKG_BASE_DIR} modules_install || exit 1
cd $dir

tar -C ${KNL_PKG_BASE_DIR}/lib/modules -czf ${MODULES_TGZ} . || exit 1
rm -r "${KNL_PKG_BASE_DIR}/lib"

echo "DONE!"
