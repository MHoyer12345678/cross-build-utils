#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "pbd_01_pbuilder_create.sh [--help]"
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
echo "Additional packages to install: ${ADDITIONAL_PACKAGES}"
echo "Non root user name: ${PBD_LOGIN_USER}"
echo "Non root user id: ${PBD_LOGIN_USER_UID}"
echo "Non root user group: ${PBD_LOGIN_USER_GROUP}"
echo "Non root user gid: ${PBD_LOGIN_USER_GID}"
echo
echo "Starting to create pbuilder environment in 5 secs ..."

sleep 5

sudo pbuilder create --configfile "${PBUILDER_CONFIG_FILE}" --host-arch "${CROSS_BUILD_ARCH}" --extrapackages "${ADDITIONAL_PACKAGES}" || exit 1

echo "Creating user and group for logging in as non root user ..."

echo "groupadd -g ${PBD_LOGIN_USER_GID} ${PBD_LOGIN_USER_GROUP}" > /tmp/create-user.sh || exit 1
echo "useradd -u ${PBD_LOGIN_USER_UID} -g ${PBD_LOGIN_USER_GID} -s /bin/bash ${PBD_LOGIN_USER}" >> /tmp/create-user.sh || exit 1
chmod a+x /tmp/create-user.sh || exit 1

sudo pbuilder execute --configfile "${PBUILDER_CONFIG_FILE}" --save-after-login /tmp/create-user.sh || exit 1
