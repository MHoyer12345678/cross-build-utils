#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "pbd_02_pbuilder_login.sh [--help] [--save]"
    echo "    --help,-h: Shows this help screen"
    echo "    --save: saves changes after exiting pbuilder environment"
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
echo
echo "Loging in into  pbuilder environment ..."

if [ "$1" == "--save" ]; then
    CMD_OPTIONS="--save-after-login"
fi
    
sudo pbuilder login --configfile ${PBUILDER_CONFIG_FILE} ${CMD_OPTIONS}
