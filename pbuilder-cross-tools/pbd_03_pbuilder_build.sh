#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "pbd_03_pbuilder_build.sh [--help] [<arch>] <dsc file>"
    echo "    <dsc file>: dsc file of the debian source package to build"
    echo "    <arch>: architecture to build the package for (overrides the one defined in the config file)"
    echo "    --help,-h: Shows this help screen"
    echo
    exit 0
fi

if [ "${PBD_SCRIPTS_CONF_FILE}" == "" ]; then
    PBD_SCRIPTS_CONF_FILE="./pbuilder-cross-tools.conf"
    echo "Variable PBD_SCRIPTS_CONF_FILE not set. Expecting to find: ${PBD_SCRIPTS_CONF_FILE}"
fi

echo "Using script configuration file: ${PBD_SCRIPTS_CONF_FILE}"
echo

source ${PBD_SCRIPTS_CONF_FILE} || exit 1

echo "Configuration:"
echo "--------------"
echo "pbuilder configuration file: ${PBUILDER_CONFIG_FILE}"
echo "cross build target architecture: ${CROSS_BUILD_ARCH}"
echo
echo "Building binary packages from source package:  ..."

if [ $# -eq 0 ]; then
    echo "Component missing. Pass a dsc file."
    echo "pbd_03_pbuilder_build.sh [<arch>] <dsc file>"
    exit 1
fi

if [ $# -ge 2 ]; then
    CROSS_BUILD_ARCH=$1
    echo "Overriding cross build target with:  ${CROSS_BUILD_ARCH}"
    DSC_FILE=$2
else
    DSC_FILE=$1    
fi


echo "Building component ${DSC_FILE} for architecture ${CROSS_BUILD_ARCH} ..." 
sudo pbuilder build --configfile ${PBUILDER_CONFIG_FILE} --host-arch ${CROSS_BUILD_ARCH} ${DSC_FILE}
