#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "pbd_04_add_packages_from_pbuilder_results_dir.sh [--help]"
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
echo "local repository dir: ${LOCAL_REPO_DIR}"
echo "local repository dist: ${LOCAL_REPO_DIST}"

source ${PBUILDER_CONFIG_FILE}

if [ "${BUILDRESULT}" == "" ]; then
    echo "No build result dir configured in ${PBUILDER_CONFIG_FILE}. Using pbuilders default location."
    BUILDRESULT=/var/cache/pbuilder/result
fi

echo "pbuilder result dir: ${BUILDRESULT}"
echo

echo "Adding packages found in pbuilder results dir to local repository ..."
ls ${BUILDRESULT}/*.changes | xargs -L 1 reprepro -b ${LOCAL_REPO_DIR} include ${LOCAL_REPO_DIST}
