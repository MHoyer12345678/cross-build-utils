#!/bin/bash


# ------------------------------------------------------- command line parsing --------------------------------------------
while getopts :ha:c: opt
do
    case $opt in
	h)
	    echo "knl_04-make-all.sh [--help] [-a <arch>] [-c <compiler prefix>] [<make targets>]"
	    echo "    -a <arch>: overrides architecture used to compile the kernel (ARCH=<arch>)"
	    echo "    -c <compiler prefix>: overrides compiler prefix defining the cross compiler"
	    echo "    	 	   	    set used to compile the kernel (CROSS_COMPILE=<compiler_prefix>)"
	    echo "     <make targets>: if passed build these make targets instead of the ones defined in the conf file"
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
    KNL_MAKE_TARGETS_OVER=$1
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

if [ "${KNL_MAKE_TARGETS_OVER}" != "" ]; then
    KNL_MAKE_TARGETS=${KNL_MAKE_TARGETS_OVER}
    echo "Make targets to build (passed after make): ${KNL_MAKE_TARGETS} (overwritten by cmd line option)"
else
    echo "Make targets to build (passed after make): ${KNL_MAKE_TARGETS}"
fi

echo

# ------------------------------------------------------- executing commands --------------------------------------------
echo "Checking for required packages ..."
dpkg -s ${KNL_REQUIRED_HOST_PACKAGES} &> /dev/null

if [ $? -ne 0 ]; then
    echo "Packages missing. Ensure following packages are installed in the system: ${KNL_REQUIRED_HOST_PACKAGES}"
    exit
fi


echo "Building kernel, modules, ..."
cd ${KNL_LOCAL_SRC_PATH}
make ARCH=${KNL_ARCH} CROSS_COMPILE=${KNL_CROSS_COMPILE} -j8 ${KNL_MAKE_TARGETS}

echo "DONE"
