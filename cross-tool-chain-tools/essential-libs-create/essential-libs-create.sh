#!/bin/bash

RASP_LIBS_DIR="./raspbian-libs"
CROSS_LIBS_DIR="./cross-libs"

TMP_DIR_BASE=/tmp/essential-libs-create
TMP_DIR_RASP="${TMP_DIR_BASE}/rasp"
TMP_DIR_CROSS_DEB="${TMP_DIR_BASE}/cross-deb"
TMP_DIR_CROSS_NEW="${TMP_DIR_BASE}/cross-new"

#getting absolute pathes
CALLED_DIR=$PWD
RASP_LIBS_DIR="${CALLED_DIR}/${RASP_LIBS_DIR}"
CROSS_LIBS_DIR="${CALLED_DIR}/${CROSS_LIBS_DIR}"

function destroy_tmp_dirs () {
   rm -rf ${TMP_DIR_BASE}
}

function create_tmp_dirs () {
    #creating tmp dir
    echo "Creating tmp dir"
    #create dir to unpack
    destroy_tmp_dirs
    mkdir ${TMP_DIR_BASE}
}

function prepare_tmp_dir_for_package () {
    #preparing tmp dir 
    echo "Preparing tmp dir"
    rm -rf ${TMP_DIR_BASE}/*
    mkdir ${TMP_DIR_RASP}
    mkdir ${TMP_DIR_CROSS_DEB}
    mkdir ${TMP_DIR_CROSS_NEW}
}


#---------------- libgcc-10-dev-armhf-cross ----------------------------------------------
#- use content and structure from src lib w/o modification
#- use control file from debian package
#- no replacement of version. Debian cross versions are already extended by crossX. There is no need to add +rpil.
#  Dependencies partly refer to exact versions. So keeping version is much more easy from that end as well. 
function create_libgcc-10-dev-cross () {
    cd ${CALLED_DIR}
    
    PKG_NAME="libgcc-10-dev"
    PKG_NAME_CROSS="${PKG_NAME}-armhf-cross"

    echo "Creating ${PKG_NAME_CROSS} from ${PKG_NAME} ..."

    prepare_tmp_dir_for_package

    #download and extract control from debian package
    echo "Downloading debian package to extract control file"
    cd  ${TMP_DIR_CROSS_DEB}
    apt-get download ${PKG_NAME_CROSS} || exit 1
    ar x *.deb || exit 1
    tar xf control.tar.xz || exit 1
    PACK_FN=$(ls *.deb)

    #unpacking rasp version of package
    echo "Repacking raspbian file"
    cd ${TMP_DIR_RASP}
    RASP_FN=$(ls ${RASP_LIBS_DIR}/${PKG_NAME}_*.deb)
    echo "Unpacking raspbian file: ${RASP_FN}"
    ar xf ${RASP_FN} || exit 1
    mkdir control-tmp
    cd control-tmp
    tar xf ../control.tar.* || exit 1

    #replaceing control file
    echo "Replacing control file"
    cp  ${TMP_DIR_CROSS_DEB}/control . || exit 1

    #repacking into new cross package
    echo "Repacking package into: ${PACK_FN}"
    tar -caf ../control.tar.* . || exit 1
    cd ..
    ar r ${PACK_FN} debian-binary control.tar.* data.tar.* || exit 1

    #cp into results dir
    echo "Copying package into results dir"
    cp ${PACK_FN} ${CROSS_LIBS_DIR}/ || exit 1
}

#---------------- set of libs being created using dpkg-cross ----------------------------------------------
#- convert rasp version w dpkg-cross -a armhf -M -b <<rasp_lib.deb>>
#- use control file from debian package
#- no replacement of version. Debian cross versions are already extended by crossX. There is no need to add +rpil.
#  Dependencies partly refer to exact versions. So keeping version is much more easy from that end as well. 
function create_cross-lib-w-dpkg-cross () { # $1 = package name
    PKG_NAME=$1
    PKG_NAME_CROSS="${PKG_NAME}-armhf-cross"

    cd ${CALLED_DIR}
    
    echo "Creating ${PKG_NAME_CROSS} from ${PKG_NAME} ..."

    prepare_tmp_dir_for_package

    #download and extract control from debian package
    echo "Downloading debian package to extract control file"
    cd  ${TMP_DIR_CROSS_DEB}
    apt-get download ${PKG_NAME_CROSS} || exit 1
    ar x *.deb || exit 1
    tar xf control.tar.xz || exit 1
    PACK_FN=$(ls *.deb)

    #creating cross package from raspbian package
    echo "Creating cross package using dpkg-cross"
    cd ${TMP_DIR_CROSS_NEW}
    RASP_FN=$(ls ${RASP_LIBS_DIR}/${PKG_NAME}_*.deb)
    dpkg-cross -a armhf -M -b ${RASP_FN} || exit 1
    
    #unpacking converted package to replace control file and to rename
    echo "Repacking cross package to replace control file and to rename to ${PACK_FN}"

    CROSS_FN_TMP=$(ls *.deb)
    echo "Unpacking cross package: ${CROSS_FN_TMP}"
    ar xf ${CROSS_FN_TMP} || exit 1
    mkdir control-tmp
    cd control-tmp
    tar xf ../control.tar.* || exit 1

    #replaceing control file
    echo "Replacing control file"
    cp  ${TMP_DIR_CROSS_DEB}/control . || exit 1

    #repacking into new cross package
    echo "Repacking package into: ${PACK_FN}"
    tar -caf ../control.tar.* . || exit 1
    cd ..
    ar r ${PACK_FN} debian-binary control.tar.* data.tar.* || exit 1

    #cp into results dir
    echo "Copying package into results dir"
    cp ${PACK_FN} ${CROSS_LIBS_DIR}/ || exit 1
}

#---------------- linux-libc-dev ----------------------------------------------------
#- use original from debian (no binaries inside)
function create_linux-libc-dev () {
    PKG_NAME="linux-libc-dev"
    PKG_NAME_CROSS="${PKG_NAME}-armhf-cross"

    cd ${CALLED_DIR}
    
    echo "Creating ${PKG_NAME_CROSS} from ${PKG_NAME} ..."
    prepare_tmp_dir_for_package

    #download debian package
    echo "Downloading debian package to extract control file"
    cd  ${TMP_DIR_CROSS_DEB}
    apt-get download ${PKG_NAME_CROSS} || exit 1

    #cp into results dir
    echo "Copying package into results dir"
    cp *.deb ${CROSS_LIBS_DIR}/ || exit 1
}

#---------------- libstdc++-10-dev ----------------------------------------------------
#- download and unpack debian version
#- unpack raspbian package
#- cp <raspbian pkg>/usr/lib/gcc/arm-linux-gnueabihf/10/* <debian pkg>/usr/lib/gcc-cross/arm-linux-gnueabihf/10/
#- pack and use debian package
function create_libstdcpp-10-dev () {
    PKG_NAME="libstdc++-10-dev"
    PKG_NAME_CROSS="${PKG_NAME}-armhf-cross"

    cd ${CALLED_DIR}
    
    echo "Creating ${PKG_NAME_CROSS} from ${PKG_NAME} ..."
    prepare_tmp_dir_for_package

    #download and unpack debian package
    echo "Downloading and extracting debian package"
    cd  ${TMP_DIR_CROSS_DEB}
    mkdir rfs
    apt-get download ${PKG_NAME_CROSS} || exit 1    
    PACK_FN=$(ls *.deb)
    ar x *.deb || exit 1
    cd rfs
    tar xf ../data.tar.xz || exit 1

    #unpacking rasp version of package
    echo "Unpacking raspbian package"
    cd ${TMP_DIR_RASP}
    RASP_FN=$(ls ${RASP_LIBS_DIR}/${PKG_NAME}_*.deb)
    echo "Unpacking raspbian file: ${RASP_FN}"
    ar xf ${RASP_FN} || exit 1
    mkdir rfs
    cd rfs
    tar xf ../data.tar.* || exit 1

    #copying binaries from raspbian package to debian package
    echo "Copying bin files from raspbian package to debian package"
    SRC_DIR=${TMP_DIR_RASP}/rfs/usr/lib/gcc/arm-linux-gnueabihf/10
    DST_DIR=${TMP_DIR_CROSS_DEB}/rfs/usr/lib/gcc-cross/arm-linux-gnueabihf/10
    cp -P $SRC_DIR/* $DST_DIR || exit 1

    #repacking debian package
    echo "Creating new debian package again"
    cd  ${TMP_DIR_CROSS_DEB}/rfs
    tar caf ../data.tar.xz .
    cd ..
    ar r ${PACK_FN} debian-binary control.tar.* data.tar.* || exit 1    
    
    #cp into results dir
    echo "Copying package into results dir"
    cp *.deb ${CROSS_LIBS_DIR}/ || exit 1
}


# create tmp dirs
create_tmp_dirs

# create libgcc-10-dev
create_libgcc-10-dev-cross

#create libs compatible to dpkg-cross
DPKG_CROSS_LIBS="libc6-dev libstdc++6 libc6 libubsan1 libasan6 libatomic1 libgomp1 libgcc-s1"
echo "Creating ${DPKG_CROSS_LIBS} using dpkg-cross ..."

for pkg_name in ${DPKG_CROSS_LIBS}; do
    create_cross-lib-w-dpkg-cross ${pkg_name}
done

#create linux-libc-dev-armhf-cross
create_linux-libc-dev

#create libstdc++-10-dev-armhf-cross
create_libstdcpp-10-dev

# remove tmp dirs
destroy_tmp_dirs

echo "Done"




