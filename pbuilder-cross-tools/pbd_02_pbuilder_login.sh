#!/bin/bash

AS_ROOT=0

while getopts hsr opt
do
    echo  "Opt: $opt"
    case $opt in
	h)
	    echo "pbd_02_pbuilder_login.sh [-h] [-s] [-r]"
	    echo "    -h: Shows this help screen"
	    echo "    -s: saves changes after exiting pbuilder environment"
	    echo "    -r: login as root. If not passed, login is done as configured user"
	    echo
	    exit 0
            ;;
	s)
	    CMD_OPTIONS="--save-after-login"
            ;;
	r)
	    echo "running as root ..."
	    AS_ROOT=1
	    ;;
    esac
done

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
echo "login user id: ${PBD_LOGIN_USER}"
echo

echo "su -w debian_chroot - ${PBD_LOGIN_USER}" > /tmp/login.sh
chmod a+x /tmp/login.sh

if [ $AS_ROOT -ne 1 ]; then
    echo "Logging in into  pbuilder environment as root ..."
    sudo pbuilder execute --configfile ${PBUILDER_CONFIG_FILE} ${CMD_OPTIONS} /tmp/login.sh
else
    echo "Logging in into  pbuilder environment as user ${PBD_LOGIN_USER} ..."
    sudo pbuilder login --configfile ${PBUILDER_CONFIG_FILE} ${CMD_OPTIONS}
fi
