#!/bin/bash


# ------------------------------------------------------- command line parsing --------------------------------------------
while getopts :ha:c: opt
do
    case $opt in
	h)
	    echo "knl_02-prepare-conf.sh [--help] [-a <arch>] [-c <compiler prefix>] [<kernel defconfig>]"
	    echo "    -a <arch>: overrides architecture used to compile the kernel (ARCH=<arch>)"
	    echo "    -c <compiler prefix>: overrides compiler prefix defining the cross compiler"
	    echo "    	 	   	    set used to compile the kernel (CROSS_COMPILE=<compiler_prefix>)"
	    echo "    <kernel defconfig>: if passed uses this kernel defconfig instead of the one defined in the conf file" 
	    echo "    --help,-h: Shows this help screen"
	    echo
	    exit 0
            ;;
	a)
	    KNL_ARCH_OVER=${OPTARG}
            ;;
	c)
	    KNL_CROSS_COMPILE_OVER=${OPTARG}
	    ;;
	\?)
	    echo "Invalid options passed. Try -h to get help"
	    exit 1
	    ;;
    esac
done

shift "$((OPTIND-1))"

if [ "$1" != "" ]; then
    KNL_DEF_CONFIG_OVER=$1
fi

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
echo "host packages required: ${KNL_REQUIRED_HOST_PACKAGES}"
echo "Local kernel source tree path: ${KNL_LOCAL_SRC_PATH}"

if [ "${KNL_ARCH_OVER}" != "" ]; then
    KNL_ARCH=${KNL_ARCH_OVER}
    echo "Architecture (ARCH=): ${KNL_ARCH} (overwritten by cmd line option)"
else
    echo "Architecture (ARCH=): ${KNL_ARCH}"
fi

if [ "${KNL_CROSS_COMPILE_OVER}" != "" ]; then
    KNL_CROSS_COMPILE=${KNL_CROSS_COMPILE_OVER}
    echo "Compiler prefix (CROSS_COMPILE=): ${KNL_CROSS_COMPILE} (overwritten by cmd line option)"
else
    echo "Compiler prefix (CROSS_COMPILE=): ${KNL_CROSS_COMPILE}"
fi

if [ "${KNL_DEF_CONFIG_OVER}" != "" ]; then
    KNL_DEF_CONFIG=${KNL_DEF_CONFIG_OVER}
    echo "Kernel defconfig: ${KNL_DEF_CONFIG} (overwritten by cmd line option)"
else
    echo "Kernel defconfig: ${KNL_DEF_CONFIG}"
fi
echo


# ------------------------------------------------------- executing commands --------------------------------------------
echo "Checking for required packages ..."
dpkg -s ${KNL_REQUIRED_HOST_PACKAGES} &> /dev/null

if [ $? -ne 0 ]; then
    echo "Packages missing. Ensure following packages are installed in the system: ${KNL_REQUIRED_HOST_PACKAGES}"
    exit
fi


echo "Setting kernel config ..."

cd ${KNL_LOCAL_SRC_PATH}
make ARCH=${KNL_ARCH} CROSS_COMPILE=${KNL_CROSS_COMPILE} ${KNL_DEF_CONFIG}

echo "DONE"
