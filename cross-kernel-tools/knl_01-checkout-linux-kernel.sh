#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "knl_01-checkout-linux-kernel.sh [--help]"
    echo "    --help,-h: Shows this help screen"
    echo
    exit 0
fi

if [ "${KNL_SCRIPTS_CONF_FILE}" == "" ]; then
    KNL_SCRIPTS_CONF_FILE="./cross-kernel-tools.conf"
    echo "Variable KNL_SCRIPTS_CONF_FILE not set. Expecting to find: ${KNL_SCRIPTS_CONF_FILE}"
fi

echo "Using script configuration file: ${KNL_SCRIPTS_CONF_FILE}"
echo

source ${KNL_SCRIPTS_CONF_FILE} || exit 1

echo "Configuration:"
echo "--------------"
echo "kernel source git: ${KNL_SOURCE_GIT_URL}"
echo "host packages required: ${KNL_REQUIRED_HOST_PACKAGES}"
echo "Local kernel source tree path: ${KNL_LOCAL_SRC_PATH}"
echo
echo "Checking out kernel from git now ..."

echo "Checking for required packages ..."
dpkg -s ${KNL_REQUIRED_HOST_PACKAGES} &> /dev/null

if [ $? -ne 0 ]; then
    echo "Packages missing. Ensure following packages are installed in the system: ${KNL_REQUIRED_HOST_PACKAGES}"
    exit
fi


echo "Checking out kernel ..."
mkdir -p  ${KNL_LOCAL_SRC_PATH}"
cd ${KNL_LOCAL_SRC_PATH}"
git clone --depth=1 ${KNL_SOURCE_GIT_URL}

echo "DONE!"
