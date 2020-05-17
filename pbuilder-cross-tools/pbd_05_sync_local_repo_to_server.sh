#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "pbd_05_sync_local_repo_to_server.sh [--help]"
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
echo "local repository path: ${LOCAL_REPO_DIR}"
echo "remote repository server: ${REMOTE_SERVER}"
echo "remote repository path: ${REMOTE_SRV_REPO_PATH}"
echo 

echo "Syncing repo from ${LOCAL_REPO_PATH} to server ${SERVER} ..."

echo "Creating an archive of the local repository ..."
cd ${LOCAL_REPO_DIR} || exit 1
tar -czf /tmp/repo.tgz . || exit 1

echo "Copying package to server ..."
scp /tmp/repo.tgz "${REMOTE_REPO_USER}@${REMOTE_SERVER}:/tmp" || exit 1

echo "Deleting old repo from server ..."
ssh "${REMOTE_REPO_USER}@${REMOTE_SERVER}" rm -r "${REMOTE_SRV_REPO_PATH}/*"

echo "Unpacking new repo ..."
ssh "${REMOTE_REPO_USER}@${REMOTE_SERVER}" tar -C ${REMOTE_SRV_REPO_PATH} -xf /tmp/repo.tgz || exit 1

echo "Done!"
