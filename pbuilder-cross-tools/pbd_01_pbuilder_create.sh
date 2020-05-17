#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "pbd_01_pbuilder_create.sh [--help]"
    echo "    --help,-h: Shows this help screen"
    echo
    exit 0
fi

if [ "${SCRIPT_CONF_FILE}" == "" ]; then
    SCRIPT_CONF_FILE="./pbuilder-cross-tools.conf"
    echo "Variable SCRIPT_CONF_FILE not set. Expecting to find: ${SCRIPT_CONF_FILE}"
fi

echo "Using script configuration file: ${SCRIPT_CONF_FILE}"
echo

source ${SCRIPT_CONF_FILE} || exit 1

echo "Configuration:"
echo "--------------"
echo "pbuilder configuration file: ${PBUILDER_CONFIG_FILE}"
echo "cross build target architecture: ${CROSS_BUILD_ARCH}"
echo "Additional packages to install: ${ADDITIONAL_PACKAGES}"
echo
echo "Starting to create pbuilder environment in 5 secs ..."

sleep 5

sudo pbuilder create --configfile "${PBUILDER_CONFIG_FILE}" --host-arch "${CROSS_BUILD_ARCH}" --extrapackages "${ADDITIONAL_PACKAGES}"
